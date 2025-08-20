import OpenAI from 'openai';
import dotenv from 'dotenv';
dotenv.config();

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function testNoReasoning() {
  console.log('Testing GPT-5 without reasoning parameter...');
  
  try {
    console.log('Sending request without reasoning parameter...');
    const startTime = Date.now();
    
    const res = await openai.responses.create({
      model: 'gpt-5',
      input: 'Say: "Hi, I am GPT-5. Everything is working!"',
      instructions: 'Respond directly to the user.',
      // No reasoning parameter
      text: { verbosity: 'high' },
      max_output_tokens: 500
    });
    
    const duration = Date.now() - startTime;
    console.log(`Response received in ${duration}ms`);
    
    console.log('Output text:', res.output_text);
    console.log('\nOutput array:');
    if (res.output && Array.isArray(res.output)) {
      res.output.forEach((item, idx) => {
        console.log(`Item ${idx}:`, item);
        if (item.type === 'message' && item.content) {
          console.log('  Message content:', item.content);
        }
      });
    }
    
    console.log('\nUsage:', res.usage);
    
  } catch (error) {
    console.log('Error:', error.message);
  }
}

testNoReasoning();