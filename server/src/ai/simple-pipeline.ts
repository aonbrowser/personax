// Ultra simple pipeline - just process what frontend sends
export function processPayloadSimple(payload: any) {
  // Handle both new format (s0Items/s1Items) and old format (s0/s1)
  const s0Items = payload.s0Items || [];
  const s1Items = payload.s1Items || [];
  const s0Direct = payload.s0 || {};
  const s1Direct = payload.s1 || {};
  
  // Extract all responses into simple objects
  const s0Responses = {};
  const s1Responses = {};
  
  // First, add any direct s0/s1 data
  Object.assign(s0Responses, s0Direct);
  Object.assign(s1Responses, s1Direct);
  
  // Then override with s0Items/s1Items if present
  s0Items.forEach(item => {
    if (item.response !== undefined && item.response !== null && item.response !== '') {
      s0Responses[item.id] = item.response;
    }
  });
  
  s1Items.forEach(item => {
    if (item.response !== undefined && item.response !== null && item.response !== '') {
      s1Responses[item.id] = item.response;
    }
  });
  
  // Build complete items with responses
  const finalS0 = s0Items.length > 0 ? s0Items.map(item => ({
    ...item,
    response_value: item.response !== undefined ? item.response : s0Responses[item.id],
    response_label: String(item.response !== undefined ? item.response : (s0Responses[item.id] || ''))
  })) : Object.keys(s0Responses).map(id => ({
    id,
    response_value: s0Responses[id],
    response_label: String(s0Responses[id] || '')
  }));
  
  const finalS1 = s1Items.length > 0 ? s1Items.map(item => {
    let label = '';
    const value = item.response !== undefined ? item.response : s1Responses[item.id];
    
    if (value !== undefined && value !== null) {
      if (item.type === 'Likert5' && typeof value === 'number') {
        const labels = ['Kesinlikle Katılmıyorum', 'Katılmıyorum', 'Kararsızım', 'Katılıyorum', 'Kesinlikle Katılıyorum'];
        label = labels[value - 1] || String(value);
      } else if (item.type === 'ForcedChoice2') {
        label = value === 'A' ? 'Option A' : 'Option B';  
      } else if ((item.type === 'MultiChoice4' || item.type === 'MultiChoice5') && typeof value === 'number') {
        label = `Option ${value + 1}`;
      } else {
        label = String(value);
      }
    }
    
    return {
      ...item,
      response_value: value,
      response_label: label
    };
  }) : Object.keys(s1Responses).map(id => ({
    id,
    response_value: s1Responses[id],
    response_label: String(s1Responses[id] || '')
  }));
  
  // Extract key demographics - check various possible field names
  const age = s0Responses['S0_AGE'] || s0Responses['age'] || s0Direct['S0_AGE'] || s0Direct['age'] || null;
  const gender = s0Responses['S0_GENDER'] || s0Responses['gender'] || s0Direct['S0_GENDER'] || s0Direct['gender'] || null;
  const lifeGoal = s0Responses['S0_LIFE_GOAL'] || s0Responses['life_goal'] || null;
  const challenges = s0Responses['S0_TOP_CHALLENGES'] || s0Responses['challenges'] || null;
  
  console.log('[SIMPLE] Debug - All S0 keys:', Object.keys(s0Responses));
  console.log('[SIMPLE] Debug - Sample S0 values:', Object.entries(s0Responses).slice(0, 5));
  console.log('[SIMPLE] Extracted data:');
  console.log('- Age:', age);
  console.log('- Gender:', gender);
  console.log('- Life Goal:', lifeGoal?.substring ? lifeGoal.substring(0, 50) : lifeGoal);
  console.log('- Total S0 responses:', Object.keys(s0Responses).length);
  console.log('- Total S1 responses:', Object.keys(s1Responses).length);
  
  return {
    s0Items: finalS0,
    s1Items: finalS1,
    demographics: { age, gender },
    s0Responses,
    s1Responses
  };
}