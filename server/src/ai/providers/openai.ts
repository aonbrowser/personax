import OpenAI from 'openai';
import { ENV } from '../../config/env.js';
import { chatCompletionGemini } from './requesty.js';

export const openai = new OpenAI({ 
  apiKey: ENV.OPENAI_API_KEY 
});

// Set to true to use Gemini, false to use GPT-5
const USE_GEMINI = true;

export async function chatCompletionHigh(messages: Array<{role:'system'|'user'|'assistant', content:string}>) {
  try {
    // Use Gemini if enabled
    if (USE_GEMINI) {
      console.log('Using Gemini 2.5 Pro via Requesty.ai');
      const result = await chatCompletionGemini(messages);
      return {
        content: result.content,
        tokenUsage: result.usage ? {
          inputTokens: result.usage.prompt_tokens || 0,
          outputTokens: result.usage.completion_tokens || 0,
          totalTokens: result.usage.total_tokens || 0,
          modelName: 'gemini-2.5-pro'
        } : null
      };
    }
    
    // Original GPT-5 code (preserved)
    // Extract system message for instructions
    const systemMsg = messages.find(m => m.role === 'system');
    const instructions = systemMsg ? systemMsg.content : "You are a helpful assistant.";
    
    // Convert messages to input format for GPT-5
    const input = messages
      .filter(m => m.role !== 'system')
      .map(m => {
        if (m.role === 'user') return `User: ${m.content}`;
        if (m.role === 'assistant') return `Assistant: ${m.content}`;
        return m.content;
      }).join('\n\n');
    
    console.log('GPT-5 Request - Input length:', input.length);
    console.log('API Key available:', !!ENV.OPENAI_API_KEY);
    
    // Use OpenAI responses.create API directly
    const startTime = Date.now();
    const result = await openai.responses.create({
      model: "gpt-5",
      input,
      instructions,
      text: { verbosity: "high" },
      max_output_tokens: 16384  // Increased for more detailed analysis
    });

    const duration = Date.now() - startTime;
    console.log(`GPT-5 Response received in ${duration}ms`);

    // Extract content using the recommended approach
    let content = result.output_text || '';

    // If output_text is empty, try detailed extraction
    if (!content && result.output) {
      result.output.forEach((o) => {
        if (o.content) {
          o.content.forEach((c) => {
            if (c.type === "output_text") {
              content = c.text || '';
            }
          });
        }
      });
    }

    if (!content) {
      console.error('GPT-5 Response has no content. Full response:', JSON.stringify(result, null, 2));
    }

    const tokenUsage = result?.usage ? {
      inputTokens: result.usage.input_tokens,
      outputTokens: result.usage.output_tokens,
      totalTokens: result.usage.total_tokens,
      modelName: 'gpt-5'
    } : null;

    return { content, tokenUsage };
  } catch (error) {
    console.error('GPT-5 API error:', error);
    console.error('Error details:', error.response?.data || error.message);
    throw error;
  }
}

export async function detectLanguageWithMini(text: string, expectedLang: string) {
  try {
    const instructions = `You are a strict language detector. Output exactly one word: MATCH if the provided text is in ${expectedLang} (allow proper nouns), else MISMATCH:<iso_or_name>.`;
    const input = text.slice(0, 2000);
    
    // Use main openai client for language detection
    const result = await openai.responses.create({
      model: "gpt-5",
      input,
      instructions,
      reasoning: { effort: "high" },
      text: { verbosity: "medium" },
      max_output_tokens: 100  // Increased for better detection
    });

    let out = result.output_text || '';

    // If output_text is empty, try detailed extraction
    if (!out && result.output) {
      result.output.forEach((o) => {
        if (o.content) {
          o.content.forEach((c) => {
            if (c.type === "output_text") {
              out = c.text || '';
            }
          });
        }
      });
    }

    out = out.trim();

    const tokenUsage = result?.usage ? {
      inputTokens: result.usage.input_tokens,
      outputTokens: result.usage.output_tokens,
      totalTokens: result.usage.total_tokens,
      modelName: 'gpt-5'
    } : null;

    if (out.startsWith('MATCH')) return { ok: true, detected: expectedLang, tokenUsage };
    if (out.startsWith('MISMATCH:')) return { ok: false, detected: out.split(':',2)[1] || 'unknown', tokenUsage };
    return { ok: text.length>0, detected: expectedLang, tokenUsage };
  } catch (error) {
    console.error('GPT-5 language detection error:', error.message);
    // If API key error or GPT-5 fails, skip language detection
    return { ok: true, detected: expectedLang, tokenUsage: null };
  }
}

export async function retryEnforceLanguage(messages: Array<{role:'system'|'user'|'assistant', content:string}>, userLang: string, maxTries=2) {
  let result = await chatCompletionHigh(messages);
  let content = result.content;
  
  // Skip language check if LANG_CHECK is false
  if (!ENV.LANG_CHECK) {
    console.log('Language check disabled (LANG_CHECK=false)');
    return { 
      content, 
      ok: true, 
      detected: userLang, 
      tokenUsage: result.tokenUsage 
    };
  }
  
  let check = await detectLanguageWithMini(content, userLang);
  let tries = 0;
  
  // Accumulate token usage
  let totalTokenUsage = {
    inputTokens: (result.tokenUsage?.inputTokens || 0) + (check.tokenUsage?.inputTokens || 0),
    outputTokens: (result.tokenUsage?.outputTokens || 0) + (check.tokenUsage?.outputTokens || 0),
    totalTokens: (result.tokenUsage?.totalTokens || 0) + (check.tokenUsage?.totalTokens || 0),
    modelName: result.tokenUsage?.modelName || 'unknown'
  };
  
  while (!check.ok && tries < maxTries) {
    const feedback = `Bu çıktı kullanıcının dili (${userLang}) ile eşleşmiyor. Lütfen **aynı içeriği**, yalnızca ${userLang} dilinde üret.`;
    const newMsgs = [...messages, { role:'assistant', content }, { role:'user', content: feedback }];
    result = await chatCompletionHigh(newMsgs);
    content = result.content;
    check = await detectLanguageWithMini(content, userLang);
    
    // Add retry token usage
    totalTokenUsage.inputTokens += (result.tokenUsage?.inputTokens || 0) + (check.tokenUsage?.inputTokens || 0);
    totalTokenUsage.outputTokens += (result.tokenUsage?.outputTokens || 0) + (check.tokenUsage?.outputTokens || 0);
    totalTokenUsage.totalTokens += (result.tokenUsage?.totalTokens || 0) + (check.tokenUsage?.totalTokens || 0);
    
    tries++;
  }
  return { content, ok: check.ok, detected: check.detected, tokenUsage: totalTokenUsage };
}
