import fetch from 'node-fetch';

const REQUESTY_API_KEY = 'sk-w83qN+huRlKEt1oXAMGYl4zbxmDIVdTX1gQLaJjeGd42YogK8CgGNM2od6gKe4O1jRG/xTUHEmF7oYtAJIP398jzQyqQDC5YCPzBGXYcmgw=';
const REQUESTY_API_URL = 'https://router.requesty.ai/v1/chat/completions';

export async function chatCompletionGemini(messages: Array<{role:'system'|'user'|'assistant', content:string}>) {
  try {
    console.log('Gemini 2.5 Pro Request - Message count:', messages.length);
    console.log('Using Requesty.ai router');
    
    // Enhance system message for better Gemini understanding
    const enhancedMessages = messages.map(msg => {
      if (msg.role === 'system') {
        return {
          role: 'system' as const,
          content: `IMPORTANT: You must follow these instructions exactly and generate a response based on the input data provided. Do NOT repeat these instructions in your response.

${msg.content}

Remember: Generate the actual analysis report, not the instructions themselves.`
        };
      }
      return msg;
    });
    
    const startTime = Date.now();
    
    const response = await fetch(REQUESTY_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${REQUESTY_API_KEY}`
      },
      body: JSON.stringify({
        model: 'google/gemini-2.5-pro',
        messages: enhancedMessages,
        temperature: 0.7,
        max_tokens: 16384,
        stream: false
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Requesty API Error:', response.status, errorText);
      throw new Error(`Requesty API error: ${response.status} - ${errorText}`);
    }

    const data = await response.json() as any;
    const duration = Date.now() - startTime;
    console.log(`Gemini 2.5 Pro Response received in ${duration}ms`);

    // Extract content from response
    const content = data.choices?.[0]?.message?.content || '';
    
    if (!content) {
      console.error('No content in Gemini response:', data);
      throw new Error('No content in Gemini response');
    }

    return {
      content,
      model: data.model || 'google/gemini-2.5-pro',
      usage: data.usage
    };
  } catch (error) {
    console.error('Gemini API Error:', error);
    throw error;
  }
}

// Fallback to GPT-5 if Gemini fails
export async function chatCompletionWithFallback(
  messages: Array<{role:'system'|'user'|'assistant', content:string}>,
  preferGemini: boolean = true
) {
  if (preferGemini) {
    try {
      console.log('Attempting Gemini 2.5 Pro...');
      return await chatCompletionGemini(messages);
    } catch (error) {
      console.log('Gemini failed, falling back to GPT-5...');
      // Import GPT-5 function dynamically to avoid circular dependency
      const { chatCompletionHigh } = await import('./openai.js');
      return await chatCompletionHigh(messages);
    }
  } else {
    const { chatCompletionHigh } = await import('./openai.js');
    return await chatCompletionHigh(messages);
  }
}