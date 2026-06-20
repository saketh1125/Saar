/**
 * RSS Feed Crawler — fetches recent articles from Varanasi news sources.
 *
 * Sources:
 * - Dainik Jagran Varanasi
 * - Hindustan Varanasi
 * - Patrika Varanasi
 * - Times of India Varanasi
 */
import axios from 'axios';
import * as cheerio from 'cheerio';

interface RSSItem {
  title: string;
  description: string;
  url: string;
  pubDate: string;
  source: string;
}

const RSS_FEEDS = [
  { name: 'Dainik Jagran Varanasi', url: 'https://www.jagran.com/rss/varanasi.xml' },
  { name: 'Hindustan Varanasi', url: 'https://www.livehindustan.com/rss/varanasi.xml' },
  { name: 'Patrika Varanasi', url: 'https://www.patrika.com/rss/varanasi.xml' },
  { name: 'TOI Varanasi', url: 'https://timesofindia.indiatimes.com/rssfeedstopstories.cms' },
];

/**
 * Fetch recent articles from Varanasi news RSS feeds.
 */
export async function fetchRSS(query: string): Promise<RSSItem[]> {
  const items: RSSItem[] = [];

  for (const feed of RSS_FEEDS) {
    try {
      const response = await axios.get(feed.url, {
        timeout: 5000,
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; KashiNavBot/1.0)',
        },
      });

      const $ = cheerio.load(response.data, { xmlMode: true });
      $('item').each((_, element) => {
        const title = $(element).find('title').text().trim();
        const description = $(element).find('description').text().trim();
        const link = $(element).find('link').text().trim();
        const pubDate = $(element).find('pubDate').text().trim();

        // Filter by query relevance (simple keyword match)
        const lowerTitle = title.toLowerCase();
        const lowerQuery = query.toLowerCase();
        if (lowerTitle.includes(lowerQuery) || lowerQuery.split(' ').some((w) => lowerTitle.includes(w))) {
          items.push({
            title,
            description,
            url: link,
            pubDate,
            source: feed.name,
          });
        }
      });
    } catch (e) {
      console.warn(`RSS feed ${feed.name} failed:`, e);
    }
  }

  return items.slice(0, 20);
}
