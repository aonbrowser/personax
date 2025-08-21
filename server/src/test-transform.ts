import { processPayloadSimple } from './ai/simple-pipeline.js';

// Test data that simulates what frontend sends
const testPayload = {
  s0: {
    "S0_AGE": 28,
    "S0_GENDER": "Erkek",
    "S0_LIFE_GOAL": "Kendi işimi kurmak ve finansal özgürlüğe ulaşmak",
    "S0_HAPPY_MEMORY": "Üniversiteden mezun olduğum gün",
    "S0_TOP_STRENGTHS": "Analitik düşünme, problem çözme, hızlı öğrenme",
    "S0_TOP_CHALLENGES": "İş-yaşam dengesi, stres yönetimi"
  },
  s1: {
    "S1_BIG5_001": 4,
    "S1_BIG5_002": 5,
    "S1_BIG5_003": 3,
    "S1_DISC_001": "A",
    "S1_DISC_002": "B",
    "S1_MBTI_001": 2,
    "S1_MBTI_002": 4
  }
};

// Also test with s0Items/s1Items format
const testPayloadItems = {
  s0Items: [
    { id: "S0_AGE", type: "Number", response: 28 },
    { id: "S0_GENDER", type: "SingleChoice", response: "Erkek" },
    { id: "S0_LIFE_GOAL", type: "OpenText", response: "Kendi işimi kurmak ve finansal özgürlüğe ulaşmak" },
    { id: "S0_HAPPY_MEMORY", type: "OpenText", response: "Üniversiteden mezun olduğum gün" },
    { id: "S0_TOP_STRENGTHS", type: "OpenText", response: "Analitik düşünme, problem çözme, hızlı öğrenme" },
    { id: "S0_TOP_CHALLENGES", type: "OpenText", response: "İş-yaşam dengesi, stres yönetimi" }
  ],
  s1Items: [
    { id: "S1_BIG5_001", type: "Likert5", response: 4 },
    { id: "S1_BIG5_002", type: "Likert5", response: 5 },
    { id: "S1_BIG5_003", type: "Likert5", response: 3 },
    { id: "S1_DISC_001", type: "ForcedChoice2", response: "A" },
    { id: "S1_DISC_002", type: "ForcedChoice2", response: "B" },
    { id: "S1_MBTI_001", type: "MultiChoice4", response: 2 },
    { id: "S1_MBTI_002", type: "MultiChoice4", response: 4 }
  ]
};

console.log('=== Testing Simple Pipeline ===\n');

console.log('Test 1: Old format (s0/s1)');
console.log('Input:', JSON.stringify(testPayload, null, 2));
const result1 = processPayloadSimple(testPayload);
console.log('\nOutput demographics:', result1.demographics);
console.log('S0 items with values:', result1.s0Items.filter(i => i.response_value).length);
console.log('S1 items with values:', result1.s1Items.filter(i => i.response_value).length);

console.log('\n---\n');

console.log('Test 2: New format (s0Items/s1Items)');
console.log('Input:', JSON.stringify(testPayloadItems, null, 2));
const result2 = processPayloadSimple(testPayloadItems);
console.log('\nOutput demographics:', result2.demographics);
console.log('S0 items with values:', result2.s0Items.filter(i => i.response_value).length);
console.log('S1 items with values:', result2.s1Items.filter(i => i.response_value).length);
console.log('\nSample S0 items:', result2.s0Items.slice(0, 2));
console.log('\nSample S1 items:', result2.s1Items.slice(0, 2));