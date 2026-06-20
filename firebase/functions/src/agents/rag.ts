/**
 * RAG (Retrieval-Augmented Generation) Agent — combines knowledge base + live search results.
 *
 * Pipeline:
 * 1. Query → embed (Gemini text-embedding-004)
 * 2. Embedding → pgvector similarity search
 * 3. Top-K chunks → context for LLM
 * 4. LLM synthesizes answer with citations
 */
import { GoogleGenerativeAI } from '@google/generative-ai';
import { queryEmbeddings, insertEmbedding } from '../store/pgvector';

const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';

interface RAGResult {
  answer: string;
  sources: Array<{
    chunkId: string;
    text: string;
    similarity: number;
  }>;
}

/**
 * Generate an embedding for the query using Gemini.
 */
async function embedQuery(query: string): Promise<number[]> {
  const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
  const model = genAI.getGenerativeModel({ model: 'text-embedding-004' });
  const result = await model.embedContent(query);
  return result.embedding.values;
}

/**
 * RAG query: retrieve relevant chunks and synthesize an answer.
 */
export async function ragQuery(
  query: string,
  topK: number = 5
): Promise<RAGResult> {
  // Step 1: Embed the query
  const queryEmbedding = await embedQuery(query);

  // Step 2: Similarity search in pgvector
  const chunks = await queryEmbeddings(queryEmbedding, topK);

  if (chunks.length === 0) {
    return {
      answer: 'No relevant information found in the knowledge base.',
      sources: [],
    };
  }

  // Step 3: Build context from retrieved chunks
  const context = chunks
    .map((c, i) => `[${i + 1}] ${c.text}`)
    .join('\n\n');

  // Step 4: Synthesize answer with LLM
  const prompt = `You are a knowledgeable guide for Kashi (Varanasi), India.
Answer the user's question based ONLY on the provided context.
If the context doesn't contain enough information, say so and suggest what the user might need to verify locally.

CONTEXT:
${context}

USER QUESTION:
${query}

Provide a concise, accurate answer (2-4 sentences). Cite sources as [1], [2], etc.`;

  const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
  const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });
  const result = await model.generateContent(prompt);
  const answer = result.response.text();

  return {
    answer,
    sources: chunks.map((c) => ({
      chunkId: c.id,
      text: c.text,
      similarity: c.similarity,
    })),
  };
}

/**
 * Add a new chunk to the knowledge base (embed + store in pgvector).
 */
export async function addToKnowledgeBase(
  text: string,
  metadata: Record<string, any> = {}
): Promise<void> {
  const embedding = await embedQuery(text);
  await insertEmbedding(text, embedding, metadata);
}
