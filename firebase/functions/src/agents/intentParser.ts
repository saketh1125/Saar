/**
 * Intent Parser — parse natural language voice transcription into structured tool_calls JSON.
 *
 * Supports 7 tools:
 * - set_alarm: Schedule native Android alarm with optional music
 * - play_music: Play devotional music via Spotify/Apple/JioSaavn
 * - start_navigation: Navigate to a POI
 * - show_checklist: Show temple checklist for a place
 * - add_journal_entry: Create a journal entry
 * - toggle_tab: Switch to a different tab
 * - view_places: Show places by category
 */

export interface ToolCall {
  name: string;
  arguments: Record<string, any>;
}

export interface VoiceIntentResult {
  ttsResponse: string;
  confidence: number;
  toolCalls: ToolCall[];
}

/**
 * Parse voice transcription into structured tool calls.
 * Uses pattern matching + heuristics for common commands.
 */
export async function parseVoiceIntent(
  transcribedText: string,
  currentTimeIso?: string
): Promise<VoiceIntentResult> {
  const text = transcribedText.toLowerCase();
  const toolCalls: ToolCall[] = [];
  const responses: string[] = [];

  // Set alarm
  const alarmMatch = text.match(/(?:set|wake me up at)\s+(\d{1,2})[:\s]?(\d{2})?\s*(am|pm)?/i);
  if (alarmMatch) {
    const hour = parseInt(alarmMatch[1], 10);
    const minute = parseInt(alarmMatch[2] || '0', 10);
    const period = (alarmMatch[3] || '').toLowerCase();
    let time24 = hour;
    if (period === 'pm' && hour < 12) time24 += 12;
    if (period === 'am' && hour === 12) time24 = 0;
    const timeStr = `${time24.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`;

    const soundQuery = text.match(/(?:with|play)\s+(.+?)(?:\s+music|\s+stotra|\s+raga|$)/i);
    const sound = soundQuery ? soundQuery[1].trim() : 'morning flute';

    toolCalls.push({
      name: 'set_alarm',
      arguments: { time: timeStr, sound_query: sound, provider: 'spotify' },
    });
    responses.push(`Alarm set for ${timeStr} with ${sound}`);
  }

  // Play music
  if (text.match(/play|music|stotra|bhajan|raga/i) && !alarmMatch) {
    const query = text.replace(/play|music|for me/gi, '').trim();
    toolCalls.push({
      name: 'play_music',
      arguments: { sound_query: query || 'morning flute', provider: 'spotify' },
    });
    responses.push(`Playing ${query || 'morning flute'}`);
  }

  // Start navigation
  if (text.match(/navigate|directions?|route|take me to|how (?:do i|to) get to/i)) {
    const place = text.replace(/navigate|directions?|route|take me to|how (?:do i|to) get to/gi, '').trim();
    toolCalls.push({
      name: 'start_navigation',
      arguments: { destination_id: place, destination_name: place },
    });
    responses.push(`Navigating to ${place}`);
  }

  // Show checklist
  if (text.match(/checklist|what (?:do i|should i) (?:bring|carry|need)/i)) {
    const place = text.replace(/show|checklist|what (?:do i|should i) (?:bring|carry|need)|for|at/gi, '').trim();
    toolCalls.push({
      name: 'show_checklist',
      arguments: { place_id: place || 'vpd_temple_vishwanath' },
    });
    responses.push(`Loaded checklist for ${place || 'Kashi Vishwanath'}`);
  }

  // Add journal entry
  if (text.match(/journal|write down|remember|note/i)) {
    const content = text.replace(/journal|write down|remember|note|that/i, '').trim();
    toolCalls.push({
      name: 'add_journal_entry',
      arguments: { content },
    });
    responses.push('Added to journal');
  }

  // Toggle tab
  const tabMatch = text.match(/(?:open|show|switch to)\s+(map|today|brain|journal|tools)/i);
  if (tabMatch) {
    toolCalls.push({
      name: 'toggle_tab',
      arguments: { tab: tabMatch[1].toLowerCase() },
    });
    responses.push(`Opened ${tabMatch[1]} tab`);
  }

  // View places
  if (text.match(/show (?:me )?(?:all )?(temples|ghats|food|water|toilets|markets|places)/i)) {
    const categoryMatch = text.match(/(temples|ghats|food|water|toilets|markets|places)/i);
    const category = categoryMatch ? categoryMatch[1].toLowerCase() : 'places';
    toolCalls.push({
      name: 'view_places',
      arguments: { category },
    });
    responses.push(`Showing ${category}`);
  }

  // Default response if no tools matched
  if (toolCalls.length === 0) {
    return {
      ttsResponse: `I heard "${transcribedText}" — I can set alarms, play music, navigate, show checklists, add journal entries, or switch tabs.`,
      confidence: 0.5,
      toolCalls: [],
    };
  }

  const ttsResponse = responses.join('. ') + '.';
  const confidence = toolCalls.length > 0 ? 0.95 : 0.5;

  return { ttsResponse, confidence, toolCalls };
}
