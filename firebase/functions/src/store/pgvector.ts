/**
 * Supabase pgvector client — stores and retrieves text embeddings for RAG.
 *
 * Free tier: 500MB storage, 2 projects.
 * Uses Supabase's pgvector extension for cosine similarity search.
 */
import axios from 'axios';

const SUPABASE_URL = process.env.SUPABASE_URL || '';
const SUPABASE_KEY = process.env.SUPABASE_KEY || '';

interface EmbeddingChunk {
  id: string;
  text: string;
  similarity: number;
  metadata: Record<string, any>;
}

/**
 * Query embeddings by cosine similarity.
 * Returns top-K most similar chunks.
 */
export async function queryEmbeddings(
  queryEmbedding: number[],
  topK: number = 5
): Promise<EmbeddingChunk[]> {
  if (!SUPABASE_URL || !SUPABASE_KEY) {
    console.warn('Supabase not configured');
    return [];
  }

  try {
    const response = await axios.post(
      `${SUPABASE_URL}/rest/v1/rpc/match_embeddings`,
      {
        query_embedding: queryEmbedding,
        match_threshold: 0.7,
        match_count: topK,
      },
      {
        headers: {
          apikey: SUPABASE_KEY,
          Authorization: `Bearer ${SUPABASE_KEY}`,
          'Content-Type': 'application/json',
        },
        timeout: 5000,
      }
    );

    return (response.data || []).map((row: any) => ({
      id: row.id,
      text: row.content,
      similarity: row.similarity,
      metadata: row.metadata || {},
    }));
  } catch (e) {
    console.error('Supabase query failed:', e);
    return [];
  }
}

/**
 * Insert a new embedding into the knowledge base.
 */
export async function insertEmbedding(
  text: string,
  embedding: number[],
  metadata: Record<string, any> = {}
): Promise<void> {
  if (!SUPABASE_URL || !SUPABASE_KEY) {
    console.warn('Supabase not configured');
    return;
  }

  try {
    await axios.post(
      `${SUPABASE_URL}/rest/v1/embeddings`,
      {
        content: text,
        embedding,
        metadata,
      },
      {
        headers: {
          apikey: SUPABASE_KEY,
          Authorization: `Bearer ${SUPABASE_KEY}`,
          'Content-Type': 'application/json',
          Prefer: 'return=minimal',
        },
        timeout: 5000,
      }
    );
  } catch (e) {
    console.error('Supabase insert failed:', e);
  }
}
