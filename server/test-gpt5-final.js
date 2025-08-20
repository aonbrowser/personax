import OpenAI from 'openai';
import dotenv from 'dotenv';
dotenv.config();

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function testGPT5() {
  console.log('Testing final GPT-5 implementation...');
  console.log('API Key exists:', !!process.env.OPENAI_API_KEY);
  
  try {
    console.log('\n1. Testing simple message...');
    const res1 = await openai.responses.create({
      model: 'gpt-5',
      input: 'Say "GPT-5 works!"',
      instructions: 'Respond to the user.',
      reasoning: { effort: 'low' },
      text: { verbosity: 'low' },
      max_output_tokens: 100
    });
    console.log('Response:', res1.output_text);
    
    console.log('\n2. Testing Turkish response...');
    const res2 = await openai.responses.create({
      model: 'gpt-5',
      input: 'Merhaba, nasılsın?',
      instructions: 'Türkçe olarak yanıt ver.',
      reasoning: { effort: 'low' },
      text: { verbosity: 'low' },
      max_output_tokens: 200
    });
    console.log('Response:', res2.output_text);
    
    console.log('\nSUCCESS - GPT-5 is working!');
    
  } catch (error) {
    console.error('Error:', error.message);
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    }
  }
}

testGPT5();