/**
 * Reddit Crawler — fetches recent posts from r/varanasi and related subreddits.
 *
 * Uses Reddit's public JSON API (no auth required for read-only).
 * Rate limit: 60 requests/minute.
 */
import axios from 'axios';

const REDDIT_BASE = 'https://www.reddit.com';

interface RedditPost {
  title: string;
  text: string;
  author: string;
  url: string;
  timestamp: number;
  score: number;
  subreddit: string;
}

/**
 * Fetch recent posts from Varanasi-related subreddits.
 */
export async function fetchReddit(query: string): Promise<RedditPost[]> {
  const subreddits = ['varanasi', 'IndiaTravel', 'backpacking'];
  const posts: RedditPost[] = [];

  for (const sub of subreddits) {
    try {
      const url = `${REDDIT_BASE}/r/${sub}/search.json?q=${encodeURIComponent(query)}&restrict_sr=on&sort=new&t=week`;
      const response = await axios.get(url, {
        timeout: 5000,
        headers: {
          'User-Agent': 'KashiNav/1.0 (by /u/kashinav)',
        },
      });

      const data = response.data?.data?.children || [];
      for (const child of data.slice(0, 5)) {
        const post = child.data;
        posts.push({
          title: post.title,
          text: post.selftext || post.title,
          author: post.author,
          url: `https://reddit.com${post.permalink}`,
          timestamp: post.created_utc,
          score: post.score,
          subreddit: post.subreddit,
        });
      }
    } catch (e) {
      console.warn(`Reddit r/${sub} fetch failed:`, e);
    }
  }

  return posts.slice(0, 15);
}
