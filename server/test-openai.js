import OpenAI from 'openai';
import dotenv from 'dotenv';
dotenv.config();

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function testGPT5() {
  console.log('Testing GPT-5 with responses.create...');
  try {
    const res = await openai.responses.create({
      model: 'gpt-5',
      input: 'Say hello',
      reasoning: { effort: 'high' },
      text: { verbosity: 'high' }
    });
    console.log('Success:', res);
  } catch (error) {
    console.log('GPT-5 responses.create failed:', error.message);
  }

  console.log('\nTesting GPT-4 with chat.completions...');
  try {
    const res = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [{ role: 'user', content: 'Say hello' }],
      max_tokens: 50
    });
    console.log('Success:', res.choices[0].message.content);
  } catch (error) {
    console.log('GPT-4 failed:', error.message);
  }
}

testGPT5();