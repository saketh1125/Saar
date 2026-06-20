/**
 * Tavily Search API client — free tier: 1000 searches/month.
 *
 * API key is read from environment variable TAVILY_API_KEY.
 * Tavily is optimized for AI agents and returns clean, structured results.
 */
import axios from 'axios';

const TAVILY_API_KEY = process.env.TAVILY_API_KEY || '';
const TAVILY_BASE_URL = 'https://api.tavily.com/search';

interface TavilySearchResult {
  query: string;
  results: Array<{
    title: string;
    url: string;
    content: string;
    score: number;
  }>;
}

/**
 * Search the web using Tavily API (AI-optimized search).
 * Returns top 5 results with title, URL, content, and relevance score.
 */
export async function tavilySearch(query: string): Promise<TavilySearchResult | null> {
  if (!TAVILY_API_KEY) {
    console.warn('TAVILY_API_KEY not configured');
    return null;
  }

  try {
    const response = await axios.post(
      TAVILY_BASE_URL,
      {
        api_key: TAVILY_API_KEY,
        query,
        search_depth: 'basic',
        include_answer: false,
        max_results: 5,
      },
      {
        headers: {
          'Content-Type': 'application/json',
        },
        timeout: 5000,
      }
    );

    const results = response.data.results || [];
    return {
      query,
      results: results.map((r: any) => ({
        title: r.title,
        url: r.url,
        content: r.content,
        score: r.score,
      })),
    };
  } catch (e) {
    console.warn('Tavily search failed:', e);
    return null;
  }
}
