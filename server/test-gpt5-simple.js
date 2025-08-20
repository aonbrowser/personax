import OpenAI from 'openai';
import dotenv from 'dotenv';
dotenv.config();

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function testGPT5Simple() {
  console.log('Testing GPT-5 with simple question...');
  
  try {
    const res = await openai.responses.create({
      model: 'gpt-5',
      input: 'Hi, how are you?',
      instructions: 'You are a helpful assistant. Respond naturally to the user.',
      reasoning: { effort: 'low' },
      text: { verbosity: 'low' },
      max_output_tokens: 200
    });
    
    console.log('\n=== GPT-5 Response ===');
    console.log('Output text:', res.output_text);
    
    console.log('\n=== Output Array ===');
    if (res.output && Array.isArray(res.output)) {
      res.output.forEach((item, idx) => {
        console.log(`Item ${idx}:`, {
          type: item.type,
          id: item.id
        });
        if (item.content) {
          console.log('  Content:', item.content);
        }
      });
    }
    
    console.log('\n=== Usage ===');
    console.log('Total tokens:', res.usage?.total_tokens);
    console.log('Reasoning tokens:', res.usage?.output_tokens_details?.reasoning_tokens);
    console.log('Output tokens:', res.usage?.output_tokens);
    
  } catch (error) {
    console.log('Error:', error.message);
  }
}

testGPT5Simple();