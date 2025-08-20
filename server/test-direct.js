import OpenAI from 'openai';
import dotenv from 'dotenv';
dotenv.config();

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function testDirect() {
  console.log('Testing GPT-5 with direct simple message...');
  
  try {
    console.log('Sending request...');
    const startTime = Date.now();
    
    const res = await openai.responses.create({
      model: 'gpt-5',
      input: 'Say: "Hi, I am Claude Code GPT-5 integration. Everything is working perfectly!"',
      instructions: 'You are a helpful assistant. Simply respond to the user request.',
      reasoning: { effort: 'low' },
      text: { verbosity: 'low' },
      max_output_tokens: 100
    });
    
    const duration = Date.now() - startTime;
    console.log(`Response received in ${duration}ms`);
    
    console.log('Output text:', res.output_text);
    console.log('Usage:', res.usage);
    
    if (!res.output_text) {
      console.log('\nFull response for debugging:', JSON.stringify(res, null, 2));
    }
    
  } catch (error) {
    console.log('Error:', error.message);
  }
}

testDirect();