/**
 * LLM Router — Gemini 2.0 Flash (primary) → DeepSeek V3 (fallback).
 *
 * Routes prompts to the configured model with retry logic.
 * API keys are read from environment variables (set via `firebase functions:config:set`).
 */
import { GoogleGenerativeAI } from '@google/generative-ai';
import OpenAI from 'openai';

export type LLMModel = 'gemini-2.0-flash' | 'deepseek-v3';

const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const DEEPSEEK_API_KEY = process.env.DEEPSEEK_API_KEY || '';

// Initialize clients lazily
let geminiClient: GoogleGenerativeAI | null = null;
let deepseekClient: OpenAI | null = null;

function getGeminiClient(): GoogleGenerativeAI {
  if (!geminiClient) {
    geminiClient = new GoogleGenerativeAI(GEMINI_API_KEY);
  }
  return geminiClient;
}

function getDeepseekClient(): OpenAI {
  if (!deepseekClient) {
    deepseekClient = new OpenAI({
      apiKey: DEEPSEEK_API_KEY,
      baseURL: 'https://api.deepseek.com/v1',
    });
  }
  return deepseekClient;
}

/**
 * Get an LLM response from the specified model.
 * Falls back to DeepSeek if Gemini fails.
 */
export async function getLLMResponse(
  prompt: string,
  model: LLMModel = 'gemini-2.0-flash'
): Promise<string> {
  // Try primary model
  try {
    if (model === 'gemini-2.0-flash') {
      const genAI = getGeminiClient();
      const geminiModel = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });
      const result = await geminiModel.generateContent(prompt);
      const response = result.response;
      return response.text();
    } else {
      const client = getDeepseekClient();
      const completion = await client.chat.completions.create({
        model: 'deepseek-chat',
        messages: [{ role: 'user', content: prompt }],
        max_tokens: 2048,
      });
      return completion.choices[0].message.content || '';
    }
  } catch (e) {
    console.warn(`Primary model (${model}) failed:`, e);
    // Fallback to the other model
    try {
      if (model === 'gemini-2.0-flash') {
        const client = getDeepseekClient();
        const completion = await client.chat.completions.create({
          model: 'deepseek-chat',
          messages: [{ role: 'user', content: prompt }],
          max_tokens: 2048,
        });
        return completion.choices[0].message.content || '';
      } else {
        const genAI = getGeminiClient();
        const geminiModel = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });
        const result = await geminiModel.generateContent(prompt);
        return result.response.text();
      }
    } catch (fallbackError) {
      console.error('Both models failed:', fallbackError);
      return 'Unable to generate response at this time.';
    }
  }
}
