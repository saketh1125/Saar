/**
 * CWC (Central Water Commission) Crawler — fetches flood gauge data for the Ganga at Varanasi.
 *
 * Source: Central Water Commission flood bulletin (public website).
 * Parses HTML to extract water level, danger level, and flood warnings.
 */
import axios from 'axios';
import * as cheerio from 'cheerio';

interface FloodBulletin {
  date: string;
  river: string;
  location: string;
  waterLevel: number; // meters
  dangerLevel: number; // meters
  warningLevel: number; // meters
  trend: 'rising' | 'falling' | 'stable';
  floodWarning: boolean;
  message: string;
}

/**
 * Fetch current flood bulletin for Ganga at Varanasi.
 */
export async function fetchFloodBulletin(): Promise<FloodBulletin | null> {
  try {
    // CWC flood bulletin URL (placeholder — actual URL may vary)
    const url = 'https://cwc.gov.in/flood-forecast-bulletin';
    const response = await axios.get(url, {
      timeout: 10000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; KashiNavBot/1.0)',
      },
    });

    const $ = cheerio.load(response.data);

    // Parse the bulletin table (structure may vary)
    let bulletin: FloodBulletin | null = null;
    $('table tr').each((_, row) => {
      const cells = $(row).find('td');
      if (cells.length >= 4) {
        const river = cells.eq(0).text().trim();
        const location = cells.eq(1).text().trim();
        if (river.toLowerCase().includes('ganga') && location.toLowerCase().includes('varanasi')) {
          const waterLevel = parseFloat(cells.eq(2).text().trim()) || 0;
          const dangerLevel = parseFloat(cells.eq(3).text().trim()) || 0;
          const warningLevel = dangerLevel - 1;

          bulletin = {
            date: new Date().toISOString().slice(0, 10),
            river: 'Ganga',
            location: 'Varanasi',
            waterLevel,
            dangerLevel,
            warningLevel,
            trend: waterLevel > warningLevel ? 'rising' : 'stable',
            floodWarning: waterLevel >= warningLevel,
            message: waterLevel >= dangerLevel
              ? 'FLOOD WARNING: Water level at or above danger level. Avoid riverfront areas.'
              : waterLevel >= warningLevel
              ? 'CAUTION: Water level rising. Monitor updates before visiting ghats.'
              : 'Normal: Water level within safe range.',
          };
        }
      }
    });

    return bulletin;
  } catch (e) {
    console.warn('CWC flood bulletin fetch failed:', e);
    return null;
  }
}
