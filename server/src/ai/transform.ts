// Simple data transformer - frontend to AI format
export function transformForAI(payload: any) {
  // Handle new form structure (form1/form2/form3)
  if (payload.form1 || payload.form2 || payload.form3) {
    const form1Items = payload.form1Items || [];
    const form2Items = payload.form2Items || [];
    const form3Items = payload.form3Items || [];
    
    return {
      form1Items: form1Items,
      form2Items: form2Items,
      form3Items: form3Items
    };
  }
  
  // OLD FORMAT - Keep for backwards compatibility
  const s0Items = payload.s0Items || [];
  const s0MbtiItems = payload.s0MbtiItems || [];
  const s1Items = payload.s1Items || [];
  
  // Transform S0 items
  const transformedS0 = s0Items.map(item => {
    const value = item.response ?? item.response_value ?? null;
    return {
      ...item,
      response_value: value,
      response_label: value !== null && value !== undefined ? String(value) : ''
    };
  });
  
  // Transform S0_MBTI items
  const transformedS0Mbti = s0MbtiItems.map(item => {
    const value = item.response ?? item.response_value ?? null;
    let label = '';
    
    if (value !== null && value !== undefined) {
      // For MBTI questions, value is an index (0 or 1)
      if (item.options_tr) {
        const options = item.options_tr.split('|');
        label = options[Number(value)] || String(value);
      } else {
        label = String(value);
      }
    }
    
    return {
      ...item,
      response_value: value,
      response_label: label
    };
  });
  
  // Transform S1 items  
  const transformedS1 = s1Items.map(item => {
    const value = item.response ?? item.response_value ?? null;
    let label = '';
    
    if (value !== null && value !== undefined) {
      if (item.type === 'Likert5' && typeof value === 'number') {
        const labels = ['Kesinlikle Katılmıyorum', 'Katılmıyorum', 'Kararsızım', 'Katılıyorum', 'Kesinlikle Katılıyorum'];
        label = labels[value - 1] || String(value);
      } else if (item.type === 'ForcedChoice2') {
        label = value === 'A' ? 'Option A' : 'Option B';
      } else if (item.type === 'MultiChoice4' && typeof value === 'number') {
        label = `Option ${value + 1}`;
      } else if (item.type === 'MultiChoice5' && typeof value === 'number') {
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
  });
  
  return {
    s0Items: transformedS0,
    s0MbtiItems: transformedS0Mbti,
    s1Items: transformedS1
  };
}