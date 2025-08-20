import OpenAI from 'openai';
import dotenv from 'dotenv';
import fs from 'fs';
dotenv.config();

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function testAnalysis() {
  console.log('Testing GPT-5 analysis with s1 prompt...');
  
  // Load s1 prompt
  const promptContent = fs.readFileSync('./src/prompts/s1.md', 'utf8');
  
  // Minimal test data
  const s0Data = {
    S0_LANG: "tr",
    S0_NAME: "Test"
  };
  
  const s0Items = [
    {
      id: "S0_NAME",
      text: "Adınız",
      response_value: "Test",
      response_label: "Test"
    }
  ];
  
  const s1Items = [
    {
      id: "S1_Q1",
      text: "Test sorusu",
      section: "Personality",
      response_value: 3,
      response_label: "Neutral"
    }
  ];
  
  const input = `<S0>
${JSON.stringify(s0Data, null, 2)}
</S0>

<S0_ITEMS>
${JSON.stringify(s0Items, null, 2)}
</S0_ITEMS>

<S1_ITEMS>
${JSON.stringify(s1Items, null, 2)}
</S1_ITEMS>

<REPORTER_META>
${JSON.stringify({
  focus_areas: ['self_growth'],
  target_lang: 'tr',
  render_options: { 
    allow_lists: true, 
    allow_tables: true,
    per_item_review: 'minimal'
  }
}, null, 2)}
</REPORTER_META>`;
  
  try {
    console.log('Sending request...');
    const startTime = Date.now();
    
    const res = await openai.responses.create({
      model: 'gpt-5',
      input: `User: ${input}`,
      instructions: promptContent,
      reasoning: { effort: 'high' },
      text: { verbosity: 'high' },
      max_output_tokens: 4096
    });
    
    const duration = Date.now() - startTime;
    console.log(`Response received in ${duration}ms`);
    
    // Log the full response structure
    console.log('Full response structure:', JSON.stringify(res, null, 2));
    
    // Check output_text
    if (res.output_text) {
      console.log('\n=== OUTPUT TEXT ===');
      console.log(res.output_text);
    } else {
      console.log('\n!!! No output_text field found !!!');
    }
    
    // Check output array
    if (res.output && Array.isArray(res.output)) {
      console.log('\n=== OUTPUT ARRAY ===');
      res.output.forEach((item, idx) => {
        console.log(`\nOutput item ${idx}:`, item);
        if (item.type === 'message' && item.content) {
          item.content.forEach((c, cidx) => {
            console.log(`  Content ${cidx}:`, c);
          });
        }
      });
    }
    
  } catch (error) {
    console.log('Error occurred:', error.message);
    if (error.response?.data) {
      console.log('Error response:', error.response.data);
    }
  }
}

testAnalysis();