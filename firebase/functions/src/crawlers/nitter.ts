/**
 * Nitter Crawler — scrapes X/Twitter via Nitter instances (multiple fallbacks).
 *
 * Nitter is a privacy-friendly Twitter frontend. Instances are unreliable,
 * so we rotate through a list and fall back to web search if all fail.
 */
import axios from 'axios';
import * as cheerio from 'cheerio';

const NITTER_INSTANCES = [
  'https://nitter.net',
  'https://nitter.privacydev.net',
  'https://nitter.poast.org',
  'https://nitter.1d4.us',
  'https://nitter.kavin.rocks',
];

interface NitterPost {
  author: string;
  text: string;
  timestamp: string;
  url: string;
}

/**
 * Fetch recent tweets about a query from Nitter.
 * Tries multiple instances; returns empty array if all fail.
 */
export async function fetchNitter(query: string): Promise<NitterPost[]> {
  for (const instance of NITTER_INSTANCES) {
    try {
      const url = `${instance}/search?q=${encodeURIComponent(query)}&f=tweets`;
      const response = await axios.get(url, {
        timeout: 5000,
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; KashiNavBot/1.0)',
        },
      });

      const $ = cheerio.load(response.data);
      const posts: NitterPost[] = [];

      $('.timeline-item').each((_, element) => {
        const author = $(element).find('.username').text().trim();
        const text = $(element).find('.tweet-content').text().trim();
        const timestamp = $(element).find('.tweet-date').attr('title') || '';
        const link = $(element).find('.tweet-link').attr('href') || '';

        if (author && text) {
          posts.push({
            author,
            text,
            timestamp,
            url: `${instance}${link}`,
          });
        }
      });

      if (posts.length > 0) {
        return posts.slice(0, 10);
      }
    } catch (e) {
      console.warn(`Nitter instance ${instance} failed:`, e);
      continue;
    }
  }

  console.warn('All Nitter instances failed for query:', query);
  return [];
}
