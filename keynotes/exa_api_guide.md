# Exa API Setup Guide

## Configuration

| Setting | Value |
|---------|-------|
| Coding Tool | Other |
| Integration | JavaScript |
| Use Case | Web search tool |
| Search Type | Auto - Balanced relevance and speed (default) |
| Content | Highlights |

## API Key Setup

### .env File

```env
EXA_API_KEY=your_api_key_here
```

### Usage in Code

```javascript
import Exa from "exa-js";

const exa = new Exa(process.env.EXA_API_KEY);
```

## Quick Start (JavaScript)

```bash
npm install exa-js@2.14.0
```

```javascript
import Exa from "exa-js";

const exa = new Exa("YOUR_API_KEY");

const results = await exa.search("recent product announcements from developer tools companies", {
  "type": "auto",
  "numResults": 10,
  "contents": {
    "highlights": true
  }
});

results.results.forEach(result => {
  console.log(result.title, result.url);
});
```

## Search Patterns

### 1. Raw retrieval for your own agent

Use when your app should inspect `results` directly, pass `highlights` into your own LLM, or expose Exa as a tool inside an existing agent loop.

```json
{
  "query": "recent product announcements from developer tools companies",
  "type": "auto",
  "numResults": 10,
  "contents": {
    "highlights": true
  }
}
```

### 2. Synthesized search when you need grounded output

Use when Exa should synthesize a grounded answer or structured payload. `systemPrompt` sets behavior and source preferences; `outputSchema` sets the shape of `output.content`.

```json
{
  "query": "recent product announcements from developer tools companies",
  "type": "deep",
  "systemPrompt": "Prefer official sources, collapse duplicate reporting, and keep the output grounded.",
  "outputSchema": {
    "type": "object",
    "properties": {
      "summary": {
        "type": "string",
        "description": "A grounded summary of the most important findings"
      }
    },
    "required": [
      "summary"
    ]
  },
  "contents": {
    "highlights": true
  }
}
```

## Search Type Reference

| Type | Best For | Approx Latency | Depth |
|------|----------|----------------|-------|
| `auto` | Most queries — balanced relevance and speed | ~1 second | Smart |
| `fast` | Latency-sensitive queries that still need good relevance | ~450 ms | Basic |
| `instant` | Chat, voice, autocomplete, quick lookups | ~250 ms | Basic |
| `deep-lite` | Cheaper synthesis when full deep search is overkill | 4 seconds | Deep |
| `deep` | Research, enrichment, thorough results | 4-15 seconds | Deep |
| `deep-reasoning` | Complex research, multi-step reasoning, hard synthesis tasks | 12-40 seconds | Deepest |

**Tip:** `type="auto"` works well for most queries. `outputSchema` works on every search type, so you can request structured, grounded output regardless of which type you pick.

## Content Configuration

| Mode | Config | Best For |
|------|--------|----------|
| Highlights | `"highlights": true` | Token-efficient excerpts |
| Text | `"text": {"maxCharacters": 20000}` | Full content extraction, RAG |
| Summary | `"summary": {"query": "your question"}` or `"summary": true` | LLM-written summary per result |

### Tuning Knobs

- **`highlights`** — pass `true` to return query-relevant highlights for each result.
- **`summary`** — pass `true` for a generic summary, or `{"query": "..."}` to bias toward a specific question.
- **`text.verbosity`** — `"compact" | "full"` (default `"compact"`). Compact returns only main content, excluding navbars, banners, footers.
- **`text.includeHtmlTags`** — boolean (default `false`). When `true`, preserves HTML structure.
- **`text.maxCharacters`** — hard cap on extracted text length. Always set this to control token cost.

**Token usage:** `text: true` with no cap can blow up context. Prefer `highlights: true` for most agent workflows.

## Domain Filtering (Optional)

Usually not needed — Exa's neural search finds relevant results without domain restrictions.

```json
{
  "includeDomains": ["arxiv.org", "github.com"],
  "excludeDomains": ["pinterest.com"]
}
```

## Content Freshness (maxAgeHours)

| Value | Behavior | Best For |
|-------|----------|----------|
| 24 | Use cache if less than 24 hours old, otherwise livecrawl | Daily-fresh content |
| 1 | Use cache if less than 1 hour old, otherwise livecrawl | Near real-time data |
| 0 | Always livecrawl (ignore cache entirely) | Real-time data |
| -1 | Never livecrawl (cache only) | Maximum speed, historical/static content |
| *(omit)* | Default behavior | **Recommended** |

## Common Parameter Mistakes

- `useAutoprompt` → **deprecated**, remove it entirely
- `includeUrls` / `excludeUrls` → **do not exist**. Use `includeDomains` / `excludeDomains`
- `text`, `summary`, `highlights` at the top level of `/search` → **must be nested** inside `contents`
- `numSentences`, `highlightsPerUrl` → **deprecated** highlights params. Use `highlights: true` instead
- `tokensNum` → **does not exist**. Use `contents.text.maxCharacters`
- `livecrawl: "always"` → **deprecated**. Use `contents.maxAgeHours: 0` instead

## Troubleshooting

**Results not relevant?**
1. Try `type: "auto"` — most balanced option
2. Try `type: "deep"` — runs multiple query variations
3. Refine query — use singular form, be specific

**Results too slow?**
1. Use `type: "fast"` or `type: "instant"`
2. Reduce `numResults`
3. Skip contents if you only need URLs

**No results?**
1. Remove filters (date, domain restrictions)
2. Simplify query
3. Try `type: "auto"` — has fallback mechanisms

## Resources

- Docs: https://docs.exa.ai
- Dashboard: https://dashboard.exa.ai
- API Status: https://status.exa.ai
