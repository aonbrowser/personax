import OpenAI from 'openai';
import dotenv from 'dotenv';
dotenv.config();

async function testGPT5Key() {
  console.log('Testing GPT-5 with API key...');
  console.log('API Key:', process.env.OPENAI_API_KEY?.slice(0, 20) + '...');
  
  // Test 1: Direct client creation
  console.log('\n1. Creating fresh client with timeout...');
  const client1 = new OpenAI({ 
    apiKey: process.env.OPENAI_API_KEY,
    timeout: 60000
  });
  
  try {
    const res1 = await client1.responses.create({
      model: 'gpt-5',
      input: 'Say hello',
      instructions: 'Respond to user',
      reasoning: { effort: 'low' },
      text: { verbosity: 'low' },
      max_output_tokens: 100
    });
    console.log('Success! Response:', res1.output_text);
  } catch (error) {
    console.log('Error:', error.message);
  }
  
  // Test 2: New client each time
  console.log('\n2. Creating another fresh client...');
  const client2 = new OpenAI({ 
    apiKey: process.env.OPENAI_API_KEY,
    timeout: 60000
  });
  
  try {
    const res2 = await client2.responses.create({
      model: 'gpt-5',
      input: 'Say world',
      instructions: 'Respond to user',
      reasoning: { effort: 'low' },
      text: { verbosity: 'low' },
      max_output_tokens: 100
    });
    console.log('Success! Response:', res2.output_text);
  } catch (error) {
    console.log('Error:', error.message);
  }
}

testGPT5Key();