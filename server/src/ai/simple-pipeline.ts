// Ultra simple pipeline - just process what frontend sends
export function processPayloadSimple(payload: any) {
  // Check for new form structure first (form1/form2/form3)
  if (payload.form1 || payload.form2 || payload.form3) {
    return processNewFormStructure(payload);
  }
  
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

function processNewFormStructure(payload: any) {
  const form1 = payload.form1 || {};
  const form2 = payload.form2 || {};
  const form3 = payload.form3 || {};
  
  // Process Form3 DISC questions if they're combined
  const processedForm3 = { ...form3 };
  
  // Convert form1 to item format
  const form1Items = Object.entries(form1).map(([id, response]) => {
    // For SingleChoice questions, store both index and label
    let responseLabel = String(response || '');
    
    // Special handling for known SingleChoice fields
    if (id === 'F1_GENDER' && typeof response === 'string') {
      const genderOptions = ['Erkek', 'Kadın', 'Belirtmek İstemiyorum', 'Diğer'];
      const index = parseInt(response);
      if (!isNaN(index) && genderOptions[index]) {
        responseLabel = genderOptions[index];
      }
    } else if (id === 'F1_RELATIONSHIP' && typeof response === 'string') {
      const relationOptions = ['Bekâr', 'İlişkisi var', 'Evli', 'Boşanmış', 'Diğer'];
      const index = parseInt(response);
      if (!isNaN(index) && relationOptions[index]) {
        responseLabel = relationOptions[index];
      }
    } else if (id === 'F1_EDUCATION' && typeof response === 'string') {
      const eduOptions = ['İlköğretim', 'Lise', 'Üniversite', 'Yüksek Lisans', 'Doktora'];
      const index = parseInt(response);
      if (!isNaN(index) && eduOptions[index]) {
        responseLabel = eduOptions[index];
      }
    } else if (id === 'F1_PHYSICAL_ACTIVITY' && typeof response === 'string') {
      const activityOptions = ['Hareketsiz', 'Düşük (Haftada 1-2 gün hafif egzersiz)', 'Orta (Haftada 3-4 gün)', 'Yüksek (Haftada 5+ gün)'];
      const index = parseInt(response);
      if (!isNaN(index) && activityOptions[index]) {
        responseLabel = activityOptions[index];
      }
    } else if (id === 'F1_FOCUS_AREAS' && Array.isArray(response)) {
      const focusOptions = ['Kariyer/İş', 'Aile', 'Romantik İlişki', 'Arkadaşlar/Sosyal Hayat', 'Kişisel Gelişim', 'Fiziksel Sağlık', 'Ruhsal Sağlık', 'Finansal Durum', 'Hobiler'];
      const selectedLabels = response.map(idx => {
        const index = parseInt(idx);
        return focusOptions[index] || idx;
      });
      responseLabel = selectedLabels.join(', ');
    }
    
    return {
      id,
      response_value: response,
      response_label: responseLabel
    };
  });
  
  // Convert form2 to item format
  const form2Items = Object.entries(form2).map(([id, response]) => {
    let responseLabel = String(response || '');
    
    // Handle MBTI SingleChoice questions
    if (id.startsWith('F2_MBTI_') && typeof response === 'string') {
      const index = parseInt(response);
      if (index === 0) {
        responseLabel = 'A';
      } else if (index === 1) {
        responseLabel = 'B';
      }
    } else if (id === 'F2_VALUES' && Array.isArray(response)) {
      // Convert English value names to Turkish
      const valueMap = {
        'achievement': 'Başarı',
        'power': 'Güç',
        'stimulation': 'Heyecan',
        'self_direction': 'Özyönelim',
        'benevolence': 'İyilikseverlik',
        'universalism': 'Evrenselcilik',
        'security': 'Güvenlik',
        'tradition': 'Gelenek',
        'conformity': 'Uyum',
        'hedonism': 'Hazcılık'
      };
      const turkishValues = response.map(val => valueMap[val] || val);
      responseLabel = turkishValues.join(', ');
    }
    
    return {
      id,
      response_value: response,
      response_label: responseLabel
    };
  });
  
  // Convert form3 to item format, handling DISC combined questions
  const form3Items = Object.entries(processedForm3).map(([id, response]) => {
    // Check if this is a combined DISC question
    if (id.startsWith('F3_DISC_') && typeof response === 'object' && response !== null && 'most' in response) {
      // Get DISC options for this question
      const discOptions = {
        'F3_DISC_01': ['Maceracı', 'Cana yakın', 'Uyumlu', 'Kültürlü'],
        'F3_DISC_02': ['Cesur', 'Neşeli', 'Güvenilir', 'Detaycı'],
        'F3_DISC_03': ['Sonuç odaklı', 'İkna edici', 'Barışçıl', 'Mükemmeliyetçi'],
        'F3_DISC_04': ['Baskın', 'İlham verici', 'Destekleyici', 'Dikkatli'],
        'F3_DISC_05': ['Kararlı', 'Coşkulu', 'Sakin', 'Analitik'],
        'F3_DISC_06': ['Doğrudan', 'Dışadönük', 'Sabırlı', 'Titiz'],
        'F3_DISC_07': ['Rekabetçi', 'Sosyal', 'Tutarlı', 'Sistematik'],
        'F3_DISC_08': ['Risk alan', 'İyimser', 'İşbirlikçi', 'Temkinli'],
        'F3_DISC_09': ['Bağımsız', 'Etkileşimci', 'Sadık', 'Kurallara bağlı'],
        'F3_DISC_10': ['Hızlı karar veren', 'İkna edici', 'Uzlaşmacı', 'Planlı']
      };
      
      const options = discOptions[id] || [];
      const mostIndex = parseInt(response.most);
      const leastIndex = parseInt(response.least);
      const mostLabel = options[mostIndex] || response.most;
      const leastLabel = options[leastIndex] || response.least;
      
      // Format combined DISC response
      return {
        id,
        response_value: response,
        response_label: `En çok: ${mostLabel}, En az: ${leastLabel}`,
        disc_most: response.most,
        disc_least: response.least
      };
    }
    
    return {
      id,
      response_value: response,
      response_label: String(response || '')
    };
  });
  
  // Extract demographics from form1
  const age = form1.F1_AGE || 'unknown';
  let gender = form1.F1_GENDER || 'unknown';
  
  // Convert gender index to label
  if (typeof gender === 'string' || typeof gender === 'number') {
    const genderOptions = ['Erkek', 'Kadın', 'Belirtmek İstemiyorum', 'Diğer'];
    const index = parseInt(String(gender));
    if (!isNaN(index) && genderOptions[index]) {
      gender = genderOptions[index];
    }
  }
  
  console.log('[SIMPLE] New form structure processed:');
  console.log('- Form1 items:', form1Items.length);
  console.log('- Form2 items:', form2Items.length);
  console.log('- Form3 items:', form3Items.length);
  console.log('- Demographics:', { age, gender });
  
  // Check for DISC combined questions
  const discQuestions = form3Items.filter(item => item.id.startsWith('F3_DISC_') && item.disc_most !== undefined);
  if (discQuestions.length > 0) {
    console.log('- DISC combined questions:', discQuestions.length);
    discQuestions.slice(0, 2).forEach(q => {
      console.log(`  ${q.id}: most=${q.disc_most}, least=${q.disc_least}`);
    });
  }
  
  return {
    form1Items,
    form2Items, 
    form3Items,
    demographics: { age, gender }
  };
}