/**
 * Brave Search API client — free tier: 2000 queries/month.
 *
 * API key is read from environment variable BRAVE_API_KEY.
 */
import axios from 'axios';

const BRAVE_API_KEY = process.env.BRAVE_API_KEY || '';
const BRAVE_BASE_URL = 'https://api.search.brave.com/res/v1/web/search';

interface BraveSearchResult {
  query: string;
  results: Array<{
    title: string;
    url: string;
    description: string;
  }>;
}

/**
 * Search the web using Brave Search API.
 * Returns top 5 results with title, URL, and description.
 */
export async function braveSearch(query: string): Promise<BraveSearchResult | null> {
  if (!BRAVE_API_KEY) {
    console.warn('BRAVE_API_KEY not configured');
    return null;
  }

  try {
    const response = await axios.get(BRAVE_BASE_URL, {
      params: {
        q: query,
        count: 5,
        search_lang: 'en',
        ui_lang: 'en-US',
      },
      headers: {
        'X-Subscription-Token': BRAVE_API_KEY,
        Accept: 'application/json',
      },
      timeout: 5000,
    });

    const results = response.data.web?.results || [];
    return {
      query,
      results: results.map((r: any) => ({
        title: r.title,
        url: r.url,
        description: r.description,
      })),
    };
  } catch (e) {
    console.warn('Brave search failed:', e);
    return null;
  }
}
