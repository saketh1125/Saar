/**
 * Panchang Crawler — fetches Hindu calendar data (tithi, nakshatra, rituals) for a given date.
 *
 * Primary source: Drik Panchang API (free, public).
 * Fallback: Static mock data based on typical patterns.
 */
interface PanchangRitual {
  name: string;
  location: string;
  time: string;
}

interface PanchangData {
  date: string;
  tithi: string;
  nakshatra: string;
  auspicious_timings: {
    abhijit_muhurta: string;
  };
  rituals: PanchangRitual[];
  astrological_warnings: {
    description: string;
  };
}

/**
 * Fetch Panchang data for a given date (YYYY-MM-DD).
 * Returns Hindu calendar info including tithi, nakshatra, rituals, and warnings.
 */
export async function fetchPanchang(date: string): Promise<PanchangData> {
  // Try to fetch from external API (placeholder — implement actual scraper)
  try {
    // Example: scrape Drik Panchang or similar free source
    // const response = await axios.get(`https://www.drikpanchang.com/hindu-calendar/panchang/?date=${date}`);
    // Parse HTML response with cheerio
  } catch (e) {
    console.warn('Panchang API fetch failed, using fallback:', e);
  }

  // Fallback: static mock data (replace with real scraper)
  return {
    date,
    tithi: 'Shukla Dwitiya',
    nakshatra: 'Ardra',
    auspicious_timings: {
      abhijit_muhurta: '11:45 AM - 12:35 PM',
    },
    rituals: [
      {
        name: 'Subah-e-Banaras Aarti',
        location: 'Assi Ghat',
        time: '05:15 AM',
      },
      {
        name: 'Ganga Aarti',
        location: 'Dashashwamedh Ghat',
        time: '06:45 PM',
      },
    ],
    astrological_warnings: {
      description: 'Rahu Kaal active between 03:00 PM and 04:30 PM. Typical time to avoid starting new major ventures.',
    },
  };
}
