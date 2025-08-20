import { chatCompletionHigh } from './dist/ai/providers/openai.js';

async function test() {
  console.log('Testing GPT-5 backend integration...');
  
  const messages = [
    { role: 'system', content: 'You are a helpful assistant.' },
    { role: 'user', content: 'Say: "GPT-5 is working perfectly!"' }
  ];
  
  try {
    const result = await chatCompletionHigh(messages);
    console.log('\nSuccess!');
    console.log('Content:', result.content);
    console.log('Token usage:', result.tokenUsage);
  } catch (error) {
    console.error('Error:', error.message);
  }
}

test();