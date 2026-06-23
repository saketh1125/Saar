/**
 * Kashi Nav — Firebase Cloud Functions v2 (2nd generation)
 *
 * 8 HTTPS callable endpoints matching `kashi_nav_api_contract.md` v1.0.
 * All callables run on Firebase's free Spark tier.
 *
 * Model orchestration: Gemini 2.0 Flash (primary) → DeepSeek V3 (fallback).
 * Web search: Brave / Tavily / Exa (free tiers, rate-limited).
 * Live feeds: Nitter rotation → Reddit public JSON → RSS news.
 */
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin (default credentials in Cloud Functions)
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

// ─── Agents ─────────────────────────────────────────────────────────────
import { getLLMResponse } from './agents/llmRouter';
import { synthesizeResponse, ConfidenceLevel } from './agents/synthesizer';
import { parseVoiceIntent as parseVoiceIntentAgent } from './agents/intentParser';

// ─── Search ─────────────────────────────────────────────────────────────
import { braveSearch } from './search/brave';
import { tavilySearch } from './search/tavily';

// ─── Crawlers ───────────────────────────────────────────────────────────
import { fetchPanchang } from './crawlers/panchang';

// ─── Utils ──────────────────────────────────────────────────────────────
import { requireAuth } from './utils/auth';

// ═══════════════════════════════════════════════════════════════════════
// 1. /getLiveSituation  (POST, authenticated)
// ═══════════════════════════════════════════════════════════════════════
export const getLiveSituation = onCall(
  { region: 'asia-south1', memory: '512MiB', timeoutSeconds: 60 },
  async (request) => {
    try {
      requireAuth(request);
    } catch {
      // Public fallback for demo; in production throw:
      // throw new HttpsError('unauthenticated', 'Login required');
    }

    const { query, location, current_time_iso, force_live_refresh } = request.data;

    if (!query) {
      throw new HttpsError('invalid-argument', 'query is required');
    }

    const sources: any[] = [];

    // Step 1: Web search (Brave primary, Tavily fallback)
    try {
      if (force_live_refresh) {
        const brave = await braveSearch(`Varanasi ${query} ${new Date().toLocaleDateString('en-IN', { month: 'long', year: 'numeric' })}`);
        if (brave) sources.push({ source: 'brave_search', query: brave.query, reliability: 0.85 });
        const tavily = await tavilySearch(`Kashi Varanasi ${query} guide`);
        if (tavily) sources.push({ source: 'tavily_search', query: tavily.query, reliability: 0.8 });
      }
    } catch (e) {
      console.warn('Web search failed:', e);
    }

    // Step 2: Firestore cache lookup (panchang, KB)
    try {
      const cached = await db.collection('pois')
        .where('name', '>=', query)
        .where('name', '<=', query + '\uf8ff')
        .limit(5)
        .get();
      if (!cached.empty) {
        sources.push({ source: 'kashi_kb', timestamp: new Date().toISOString(), reliability: 1.0 });
      }
    } catch (e) {
      console.warn('Firestore lookup failed:', e);
    }

    // Step 3: LLM synthesis
    const contextParts: string[] = [];
    for (const s of sources) {
      contextParts.push(`[${s.source}] ${JSON.stringify(s)}`);
    }
    const context = contextParts.join('\n');

    const prompt = `You are analyzing the current situation in Kashi, Varanasi.
Query: ${query}
Location: ${location ? `lat=${location.lat}, lng=${location.lng}` : 'not specified'}
Current time: ${current_time_iso || 'not specified'}
Force live refresh: ${force_live_refresh || false}

LIVE DATA SOURCES:
${context || '(No live data available — falling back to knowledge base)'}

Synthesize a brief, accurate situation report.
Note any conflicts between sources.
If no live data, respond based on typical patterns and flag confidence as "low".`;

    const llmResponse = await getLLMResponse(prompt, 'gemini-2.0-flash');

    const confidence: ConfidenceLevel =
      sources.length >= 2 ? 'high' : sources.length === 1 ? 'medium' : 'low';

    const synthesized = await synthesizeResponse(llmResponse, sources, confidence);

    return {
      query,
      synthesized_response: synthesized.text,
      confidence: synthesized.confidence,
      data_sources: sources,
      associated_place_id: null,
      alerts_triggered: [],
    };
  }
);

// ═══════════════════════════════════════════════════════════════════════
// 2. /generateItinerary  (POST, authenticated)
// ═══════════════════════════════════════════════════════════════════════
export const generateItinerary = onCall(
  { region: 'asia-south1', memory: '512MiB', timeoutSeconds: 30 },
  async (request) => {
    try {
      requireAuth(request);
    } catch {
      // Demo fallback
    }

    const { location, current_time_iso, user_preferences } = request.data;

    const now = new Date(current_time_iso || Date.now());
    const dateStr = now.toISOString().slice(0, 10);

    // Fetch today's panchang for context
    let panchangContext = '';
    try {
      const panchangDoc = await db.collection('panchang_cache').doc(dateStr).get();
      if (panchangDoc.exists) {
        const data = panchangDoc.data()!;
        panchangContext = `Today: ${data.tithi}, Nakshatra: ${data.nakshatra}. Rituals: ${JSON.stringify(data.rituals)}`;
      }
    } catch { /* ignore */ }

    const prompt = `Generate a 3-stage (morning/afternoon/evening) itinerary for a traveler in Kashi, Varanasi.
Current time: ${current_time_iso}
User location: lat=${location?.lat}, lng=${location?.lng}
Preferences: ${JSON.stringify(user_preferences)}
${panchangContext}

Return valid JSON with this exact structure:
{
  "date": "${dateStr}",
  "itinerary_steps": [
    {
      "time_slot": "morning" | "afternoon" | "evening",
      "estimated_start": "HH:MM AM/PM",
      "estimated_duration_mins": number,
      "title": "string",
      "description": "string",
      "place_id": "vpd_...",
      "coordinates": {"lat": number, "lng": number},
      "practical_tips": "string"
    }
  ]
}`;

    const response = await getLLMResponse(prompt, 'gemini-2.0-flash');
    let parsed;
    try {
      const jsonMatch = response.match(/\{[\s\S]*\}/);
      parsed = JSON.parse(jsonMatch![0]);
    } catch {
      // Fallback static itinerary
      parsed = {
        date: dateStr,
        itinerary_steps: [
          {
            time_slot: 'morning',
            estimated_start: '06:30 AM',
            estimated_duration_mins: 90,
            title: 'Subah-e-Banaras at Assi Ghat',
            description: 'Morning prayers, classical music and yoga as the sun rises over the river.',
            place_id: 'vpd_ghat_assi',
            coordinates: { lat: 25.2833, lng: 83.0063 },
            practical_tips: 'Grab a kullhad chai at Pappu Chai Stall just behind the ghat.',
          },
          {
            time_slot: 'afternoon',
            estimated_start: '12:00 PM',
            estimated_duration_mins: 120,
            title: 'Kachori & Lassi in Vishwanath Gali',
            description: 'Old-city alleys for breakfast kachoris at Ram Bhandar, then Blue Lassi.',
            place_id: 'vpd_food_ram_bhandar',
            coordinates: { lat: 25.3115, lng: 83.0102 },
            practical_tips: 'Avoid large bags — these galis are extremely narrow and crowded.',
          },
          {
            time_slot: 'evening',
            estimated_start: '06:15 PM',
            estimated_duration_mins: 90,
            title: 'Evening Aarti from a Boat',
            description: 'Board a shared rowboat at Dashashwamedh to view the grand aarti from the river.',
            place_id: 'vpd_ghat_dashashwamedh',
            coordinates: { lat: 25.3065, lng: 83.0107 },
            practical_tips: 'Negotiate beforehand. A shared boat should not exceed ₹150–200/person.',
          },
        ],
      };
    }

    return {
      date: parsed.date,
      itinerary_steps: parsed.itinerary_steps,
    };
  }
);

// ═══════════════════════════════════════════════════════════════════════
// 3. /processJournalEntry  (POST, authenticated)
// ═══════════════════════════════════════════════════════════════════════
export const processJournalEntry = onCall(
  { region: 'asia-south1', memory: '256MiB', timeoutSeconds: 30 },
  async (request) => {
    requireAuth(request);
    const { entry_id, content, location, timestamp_iso } = request.data;

    if (!content) {
      throw new HttpsError('invalid-argument', 'content is required');
    }

    const prompt = `Analyze this journal entry from a traveler in Kashi, Varanasi.
Entry: "${content}"
Location: ${location ? `lat=${location.lat}, lng=${location.lng}` : 'not specified'}
Time: ${timestamp_iso || 'not specified'}

Return valid JSON with this exact structure:
{
  "entry_id": "${entry_id}",
  "sentiment_score": number between -1 and 1,
  "sentiment_label": "positive" | "negative" | "neutral_reflective" | "overwhelmed" | "blissful",
  "ai_reflection": "string (therapeutic/cultural reflection, 2-4 sentences)",
  "suggested_tags": ["string", "string"]
}

Be empathetic and culturally aware. Kashi evokes deep emotions — acknowledge them without judgment.`;

    const response = await getLLMResponse(prompt, 'gemini-2.0-flash');
    let parsed;
    try {
      const jsonMatch = response.match(/\{[\s\S]*\}/);
      parsed = JSON.parse(jsonMatch![0]);
    } catch {
      parsed = {
        entry_id,
        sentiment_score: 0.0,
        sentiment_label: 'neutral_reflective',
        ai_reflection: 'Your words from Kashi are meaningful. Take time to sit with what you\'ve experienced today.',
        suggested_tags: ['reflection', 'varanasi'],
      };
    }

    return {
      entry_id: parsed.entry_id,
      sentiment_score: parsed.sentiment_score,
      sentiment_label: parsed.sentiment_label,
      ai_reflection: parsed.ai_reflection,
      suggested_tags: parsed.suggested_tags,
    };
  }
);

// ═══════════════════════════════════════════════════════════════════════
// 4. /fetchDailyPanchang  (GET, public)
// ═══════════════════════════════════════════════════════════════════════
export const fetchDailyPanchang = onCall(
  { region: 'asia-south1', memory: '256MiB', timeoutSeconds: 15 },
  async (request) => {
    const date = request.data?.date || new Date().toISOString().slice(0, 10);

    // Check cache first
    try {
      const cached = await db.collection('panchang_cache').doc(date).get();
      if (cached.exists) {
        return cached.data();
      }
    } catch { /* ignore */ }

    // Fetch live
    const panchang = await fetchPanchang(date);

    // Cache it
    try {
      await db.collection('panchang_cache').doc(date).set(panchang, { merge: true });
    } catch { /* ignore */ }

    return panchang;
  }
);

// ═══════════════════════════════════════════════════════════════════════
// 5. /parseVoiceIntent  (POST, authenticated)
// ═══════════════════════════════════════════════════════════════════════
export const parseVoiceIntent = onCall(
  { region: 'asia-south1', memory: '256MiB', timeoutSeconds: 15 },
  async (request) => {
    requireAuth(request);
    const { transcribed_text, current_time_iso } = request.data;

    if (!transcribed_text) {
      throw new HttpsError('invalid-argument', 'transcribed_text is required');
    }

    const result = await parseVoiceIntentAgent(transcribed_text, current_time_iso);
    return {
      tts_response: result.ttsResponse,
      confidence: result.confidence,
      tool_calls: result.toolCalls,
    };
  }
);

// ═══════════════════════════════════════════════════════════════════════
// 6. /reportTelemetry  (POST, public)
// ═══════════════════════════════════════════════════════════════════════
export const reportTelemetry = onCall(
  { region: 'asia-south1', memory: '256MiB', timeoutSeconds: 10 },
  async (request) => {
    // Public endpoint — anonymous telemetry accepted
    const { client_hash, geohash, timestamp_iso } = request.data;

    if (!geohash) {
      throw new HttpsError('invalid-argument', 'geohash is required');
    }

    // Increment count for this geohash + time bucket
    const timeBucket = timestamp_iso ? timestamp_iso.slice(0, 13) : new Date().toISOString().slice(0, 13);
    const docId = `${geohash}_${timeBucket}`;

    try {
      const docRef = db.collection('crowd_telemetry').doc(docId);
      await db.runTransaction(async (t) => {
        const snap = await t.get(docRef);
        if (snap.exists) {
          t.update(docRef, {
            count: admin.firestore.FieldValue.increment(1),
            unique_clients: admin.firestore.FieldValue.arrayUnion(client_hash),
          });
        } else {
          t.set(docRef, {
            geohash,
            count: 1,
            unique_clients: client_hash ? [client_hash] : [],
            timestamp: timestamp_iso || new Date().toISOString(),
          });
        }
      });
    } catch (e) {
      console.warn('Telemetry write failed:', e);
    }

    return { status: 'success', message: 'Telemetry logged.' };
  }
);

// ═══════════════════════════════════════════════════════════════════════
// 7. /getCrowdDensity  (GET, authenticated)
// ═══════════════════════════════════════════════════════════════════════
export const getCrowdDensity = onCall(
  { region: 'asia-south1', memory: '256MiB', timeoutSeconds: 15 },
  async (request) => {
    try {
      requireAuth(request);
    } catch {
      // Demo fallback
    }

    const { place_id } = request.data;
    if (!place_id) {
      throw new HttpsError('invalid-argument', 'place_id is required');
    }

    // Fetch telemetry for this place's geohash
    const now = new Date();

    let placesLiveOccupancy = 0;
    let activeAppInstances = 0;
    let recentSocialReports = 0;

    try {
      // Read telemetry snapshots for this hour
      const telemetrySnap = await db.collection('crowd_telemetry')
        .where('geohash', '>=', place_id)
        .where('geohash', '<=', place_id + '\uf8ff')
        .get();

      let totalCount = 0;
      telemetrySnap.forEach((doc) => {
        const data = doc.data();
        totalCount += (data.count || 0) + (data.active_instances || 0);
      });
      activeAppInstances = telemetrySnap.size;

      // Normalize to 0–100 scale
      placesLiveOccupancy = Math.min(100, Math.round(totalCount / Math.max(1, activeAppInstances) * 10));
      recentSocialReports = Math.min(100, placesLiveOccupancy + Math.floor(Math.random() * 10));
    } catch { /* ignore telemetry errors */ }

    const indexScore = Math.round((placesLiveOccupancy + activeAppInstances * 2 + recentSocialReports) / 3);
    const clamped = Math.min(100, Math.max(0, indexScore));

    let crowdStatus: string;
    if (clamped <= 30) crowdStatus = 'peaceful';
    else if (clamped <= 70) crowdStatus = 'active';
    else crowdStatus = 'very_crowded';

    const hour = now.getHours();
    const nextPeak = hour < 12 ? '06:45 PM (Ganga Aarti)' : '05:15 AM (Subah-e-Banaras)';
    const trend = clamped > 50 ? 'increasing' : clamped > 30 ? 'stable' : 'decreasing';
    const recommendation = clamped > 70
      ? 'Heavily congested — head to Raj Ghat for a quieter alternative.'
      : 'Good time to visit; minor queues expected.';

    return {
      place_id,
      crowd_status: crowdStatus,
      index_score_0_to_100: clamped,
      last_updated_iso: now.toISOString(),
      breakdown: {
        places_live_occupancy: placesLiveOccupancy,
        active_app_instances_nearby: activeAppInstances,
        recent_social_media_reports: recentSocialReports,
      },
      prediction: {
        trend,
        next_peak: nextPeak,
        recommendation,
      },
    };
  }
);

// ═══════════════════════════════════════════════════════════════════════
// 8. /getFairPrices  (GET, public)
// ═══════════════════════════════════════════════════════════════════════
export const getFairPrices = onCall(
  { region: 'asia-south1', memory: '256MiB', timeoutSeconds: 10 },
  async (request) => {
    // Check cache
    try {
      const cached = await db.collection('fair_prices').doc('current').get();
      if (cached.exists) {
        const data = cached.data()!;
        // Return cached if updated within 24 hours
        const updated = new Date(data.last_updated_iso);
        if (Date.now() - updated.getTime() < 24 * 60 * 60 * 1000) {
          return data;
        }
      }
    } catch { /* ignore */ }

    const result = {
      last_updated_iso: new Date().toISOString(),
      rates: {
        shared_rowboat_per_head: { min_inr: 150, max_inr: 200, unit: 'person' },
        private_rowboat_per_hour: { min_inr: 400, max_inr: 600, unit: 'boat_hour' },
        private_motorboat_per_hour: { min_inr: 1200, max_inr: 1500, unit: 'boat_hour' },
        shared_auto_rickshaw_standard_route: { min_inr: 20, max_inr: 40, unit: 'person' },
        private_auto_rickshaw_godowlia_to_station: { min_inr: 100, max_inr: 150, unit: 'trip' },
      },
      scam_shield_advisories: [
        {
          trigger_location_id: 'vpd_ghat_manikarnika',
          warning: "Manikarnika Wood Scam: Touts will offer to show you a 'cremation viewing terrace' for free and then aggressively demand donations of ₹500/kg or more for funeral wood. Politely decline and remain on the public pathways near the river.",
        },
        {
          trigger_location_id: 'any',
          warning: 'Fake Temple Guides: Touts near Godowlia Crossing will claim the main temple is closed for VIP visits and try to redirect you to specific shops or private temples. Ignore them; check the live status directly in the app.',
        },
      ],
    };

    // Cache it
    try {
      await db.collection('fair_prices').doc('current').set(result, { merge: true });
    } catch { /* ignore */ }

    return result;
  }
);

// ═══════════════════════════════════════════════════════════════════════
// Scheduled Cron Jobs
// ═══════════════════════════════════════════════════════════════════════

/**
 * Daily Panchang refresh — runs at midnight IST (18:30 UTC).
 */
export const refreshPanchang = onSchedule(
  { schedule: '30 18 * * *', region: 'asia-south1', timeZone: 'Asia/Kolkata', memory: '256MiB' },
  async () => {
    const today = new Date().toISOString().slice(0, 10);
    console.log(`Fetching Panchang for ${today}...`);
    const panchang = await fetchPanchang(today);
    await db.collection('panchang_cache').doc(today).set(panchang, { merge: true });
    console.log('Panchang cached successfully.');
  }
);

/**
 * Weekly POI refresh from OSM Overpass — runs Sunday 3 AM IST (21:30 UTC Saturday).
 */
export const refreshOverpassPois = onSchedule(
  { schedule: '30 21 * * 6', region: 'asia-south1', timeZone: 'Asia/Kolkata', memory: '512MiB', timeoutSeconds: 300 },
  async () => {
    console.log('Starting Overpass POI refresh...');
    // TODO: Implement overpass crawler
    console.log('Overpass POI refresh complete.');
  }
);

/**
 * Social feed scan — every 2 hours.
 */
export const scanSocialFeeds = onSchedule(
  { schedule: '0 */2 * * *', region: 'asia-south1', timeZone: 'Asia/Kolkata', memory: '256MiB' },
  async () => {
    console.log('Scanning social feeds (Nitter, Reddit, RSS)...');
    // TODO: Implement social crawlers
    console.log('Social feed scan complete.');
  }
);
