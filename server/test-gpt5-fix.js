import OpenAI from 'openai';
import dotenv from 'dotenv';
dotenv.config();

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function testGPT5Variations() {
  console.log('Testing GPT-5 with different parameter combinations...\n');
  
  const tests = [
    {
      name: 'With store=false',
      params: {
        model: 'gpt-5',
        input: 'Say "Hello from GPT-5"',
        instructions: 'Respond to the user request',
        store: false,
        max_output_tokens: 100
      }
    },
    {
      name: 'With reasoning disabled',
      params: {
        model: 'gpt-5',
        input: 'Say "Hello from GPT-5"',
        instructions: 'Respond to the user request',
        reasoning: { effort: 'disabled' },
        max_output_tokens: 100
      }
    },
    {
      name: 'With output format',
      params: {
        model: 'gpt-5',
        input: 'Say "Hello from GPT-5"',
        instructions: 'Respond to the user request',
        text: { 
          verbosity: 'high',
          format: { type: 'text' }
        },
        max_output_tokens: 100
      }
    },
    {
      name: 'With temperature 0',
      params: {
        model: 'gpt-5',
        input: 'Say "Hello from GPT-5"',
        instructions: 'Respond to the user request',
        temperature: 0,
        reasoning: { effort: 'low' },
        max_output_tokens: 100
      }
    }
  ];
  
  for (const test of tests) {
    console.log(`\n=== Testing: ${test.name} ===`);
    try {
      const res = await openai.responses.create(test.params);
      
      console.log('Output text:', res.output_text || '(empty)');
      
      if (res.output && Array.isArray(res.output)) {
        console.log('Output array items:');
        res.output.forEach(item => {
          console.log(`  - Type: ${item.type}`);
          if (item.content) {
            console.log(`    Content:`, item.content);
          }
        });
      }
      
      console.log('Usage:', {
        reasoning: res.usage?.output_tokens_details?.reasoning_tokens,
        total: res.usage?.output_tokens
      });
      
      if (res.output_text) {
        console.log('✅ SUCCESS - Got output text!');
        break;
      }
    } catch (error) {
      console.log('Error:', error.message);
    }
  }
}

testGPT5Variations();