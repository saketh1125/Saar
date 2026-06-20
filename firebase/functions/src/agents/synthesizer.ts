/**
 * Response Synthesizer — merges LLM output + search results + KB into final response.
 */

export type ConfidenceLevel = 'high' | 'medium' | 'low';

interface DataSource {
  source: string;
  query?: string;
  reliability?: number;
  timestamp?: string;
}

interface SynthesizedResponse {
  text: string;
  confidence: ConfidenceLevel;
}

/**
 * Synthesize the final response from LLM output and data sources.
 * Applies confidence labeling based on source count and reliability.
 */
export async function synthesizeResponse(
  llmText: string,
  sources: DataSource[],
  confidence: ConfidenceLevel
): Promise<SynthesizedResponse> {
  // If we have no sources, flag as low confidence
  if (sources.length === 0) {
    return {
      text: llmText + '\n\n_Based on typical patterns — verify locally._',
      confidence: 'low',
    };
  }

  // High confidence: 2+ sources with reliability >= 0.8
  const highReliability = sources.filter((s) => (s.reliability || 0) >= 0.8);
  if (highReliability.length >= 2) {
    return {
      text: llmText,
      confidence: 'high',
    };
  }

  // Medium confidence: at least 1 source
  return {
    text: llmText,
    confidence: confidence,
  };
}
