/**
 * Environment configuration
 * All environment variables should be accessed through this file
 */

const HOST:string = 'localhost';
const PORT:string = '10002';
const LOG_LEVEL:string = 'info';

class OpenRouterConfig {
  static readonly BASE_URL = 'https://openrouter.ai/api/v1';
  static readonly API_KEY = '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';
  static readonly MODEL = 'z-ai/glm-4.5-air:free';
  static readonly APP_NAME = 'A2UI Restaurant Agent';
  static readonly REFERER = 'A2UI.org';
};

const OPENAI_API_KEY = '';
const OPENAI_BASE_URL = 'https://api.openai.com/v1';
const OPENAI_MODEL = '';

const GEMINI_API_KEY = '';
const LITELLM_MODEL = '';
const GOOGLE_GENAI_USE_VERTEXAI = 'FALSE';

// Server Configuration
export const SERVER_CONFIG = {
  host: HOST,
  port: parseInt(PORT, 10),
} as const;

// Logging Configuration

export const LOG_CONFIG = {
  level: (LOG_LEVEL).toLowerCase() as 'debug' | 'info' | 'warn' | 'error',
} as const;

// LLM Provider Configuration
export const LLM_CONFIG = {
  // OpenRouter
  openrouter: {
    apiKey: OpenRouterConfig.API_KEY,
    baseURL: OpenRouterConfig.BASE_URL,
    model: OpenRouterConfig.MODEL,
    appName: OpenRouterConfig.APP_NAME,
    referer: OpenRouterConfig.REFERER,
  },
  // OpenAI
  openai: {
    apiKey: OPENAI_API_KEY,
    baseUrl: OPENAI_BASE_URL,
    model: OPENAI_MODEL,
  },
  // Gemini
  gemini: {
    apiKey: GEMINI_API_KEY,
  },
  // LiteLLM (for backward compatibility)
  litellm: {
    model: LITELLM_MODEL,
  },
  // Vertex AI
  vertexAi: {
    enabled: GOOGLE_GENAI_USE_VERTEXAI.toUpperCase() === 'TRUE',
  },
} as const;

/**
 * Get the active LLM provider configuration
 * Priority: OpenRouter > OpenAI > Gemini
 */
export function getActiveLLMProvider() {
  if (LLM_CONFIG.openrouter.apiKey && String(LLM_CONFIG.openrouter.apiKey).trim()) {
    return {
      name: 'openrouter' as const,
      apiKey: LLM_CONFIG.openrouter.apiKey,
      baseUrl: 'https://openrouter.ai/api/v1',
      defaultModel: LLM_CONFIG.openrouter.model,
      headers: {
        'HTTP-Referer': LLM_CONFIG.openrouter.referer,
        'X-Title': LLM_CONFIG.openrouter.appName,
      },
    };
  }

  if (LLM_CONFIG.openai.apiKey && String(LLM_CONFIG.openai.apiKey).trim()) {
    return {
      name: 'openai' as const,
      apiKey: LLM_CONFIG.openai.apiKey,
      baseUrl: LLM_CONFIG.openai.baseUrl,
      defaultModel: 'gpt-4o',
      headers: undefined,
    };
  }

  if (LLM_CONFIG.gemini.apiKey && String(LLM_CONFIG.gemini.apiKey).trim()) {
    return {
      name: 'gemini' as const,
      apiKey: LLM_CONFIG.gemini.apiKey,
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai/',
      defaultModel: 'gemini-2.0-flash-exp',
      headers: undefined,
    };
  }

  return null;
}

/**
 * Get the model to use
 * Priority: explicit model config > default from active provider
 */
export function getModelName(): string {
  const activeProvider = getActiveLLMProvider();
  
  // Check for explicitly configured models
  if (LLM_CONFIG.openai.model) return LLM_CONFIG.openai.model;
  if (LLM_CONFIG.litellm.model) return LLM_CONFIG.litellm.model;
  if (LLM_CONFIG.openrouter.model) return LLM_CONFIG.openrouter.model;
  
  // Fall back to provider default
  return activeProvider?.defaultModel || 'gpt-4o';
}

/**
 * Check if any LLM provider is configured
 */
export function hasLLMProvider(): boolean {
  if (LLM_CONFIG.vertexAi.enabled) return true;
  return getActiveLLMProvider() !== null;
}

/**
 * Get error message for missing API key
 */
export function getLLMConfigErrorMessage(): string {
  return `No LLM API key found. Please set one of the following environment variables:
  - OPENROUTER_API_KEY (recommended - get from https://openrouter.ai/keys)
  - OPENAI_API_KEY
  - GEMINI_API_KEY
  - Or set GOOGLE_GENAI_USE_VERTEXAI=TRUE for Vertex AI`;
}

export const baseUrl = `http://${HOST}:${PORT}`;