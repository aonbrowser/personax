// Ultra simple pipeline - just process what frontend sends
export function processPayloadSimple(payload) {
    // Handle new form structure (form1/form2/form3)
    if (payload.form1 || payload.form2 || payload.form3) {
        const form1 = payload.form1 || {};
        const form2 = payload.form2 || {};
        const form3 = payload.form3 || {};
        
        // Extract demographics from Form1
        const demographics = {
            age: form1['F1_AGE'],
            gender: form1['F1_GENDER'],
            relationship_status: form1['F1_RELATIONSHIP'],
            education: form1['F1_EDUCATION'],
            occupation: form1['F1_OCCUPATION'],
            life_satisfaction: form1['F1_LIFE_SATISFACTION'],
            stress_level: form1['F1_STRESS_LEVEL']
        };
        
        console.log('[SIMPLE] New form structure detected');
        console.log('Form1 responses:', Object.keys(form1).length);
        console.log('Form2 responses:', Object.keys(form2).length);
        console.log('Form3 responses:', Object.keys(form3).length);
        console.log('Demographics:', demographics);
        console.log('Form1 sample entries:', Object.entries(form1).slice(0, 3));
        console.log('Form2 sample entries:', Object.entries(form2).slice(0, 3));
        console.log('Form3 sample entries:', Object.entries(form3).slice(0, 3));
        
        // Process form2 items and add ranking explanation for F2_VALUES
        const form2Items = Object.entries(form2).map(([id, value]) => {
            const item = { id, response_value: value };
            // Add explanation for ranking question
            if (id === 'F2_VALUES' && Array.isArray(value)) {
                item.ranking_note = 'Sıralama: 1=En önemli, 10=En az önemli';
                item.ranking_order = value.map((v, i) => `${i+1}. ${v}`);
            }
            return item;
        });
        
        return {
            form1Items: Object.entries(form1).map(([id, value]) => ({ id, response_value: value })),
            form2Items: form2Items,
            form3Items: Object.entries(form3).map(([id, value]) => ({ id, response_value: value })),
            demographics,
            form1Responses: form1,
            form2Responses: form2,
            form3Responses: form3
        };
    }
    
    // OLD FORMAT - Keep for backwards compatibility
    const s0Items = payload.s0Items || [];
    const s0MbtiItems = payload.s0MbtiItems || [];
    const s1Items = payload.s1Items || [];
    const s0Direct = payload.s0 || {};
    const s1Direct = payload.s1 || {};
    // Extract all responses into simple objects
    const s0Responses = {};
    const s0MbtiResponses = {};
    const s1Responses = {};
    // First, add any direct s0/s1 data
    Object.assign(s0Responses, s0Direct);
    Object.assign(s1Responses, s1Direct);
    // Then override with s0Items/s0MbtiItems/s1Items if present
    s0Items.forEach(item => {
        if (item.response !== undefined && item.response !== null && item.response !== '') {
            s0Responses[item.id] = item.response;
        }
    });
    s0MbtiItems.forEach(item => {
        if (item.response !== undefined && item.response !== null && item.response !== '') {
            s0MbtiResponses[item.id] = item.response;
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
    const finalS0Mbti = s0MbtiItems.length > 0 ? s0MbtiItems.map(item => {
        const value = item.response !== undefined ? item.response : s0MbtiResponses[item.id];
        let label = '';
        
        if (value !== undefined && value !== null) {
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
    }) : [];
    
    const finalS1 = s1Items.length > 0 ? s1Items.map(item => {
        let label = '';
        const value = item.response !== undefined ? item.response : s1Responses[item.id];
        if (value !== undefined && value !== null) {
            if (item.type === 'Likert5' && typeof value === 'number') {
                const labels = ['Kesinlikle Katılmıyorum', 'Katılmıyorum', 'Kararsızım', 'Katılıyorum', 'Kesinlikle Katılıyorum'];
                label = labels[value - 1] || String(value);
            }
            else if (item.type === 'ForcedChoice2') {
                label = value === 'A' ? 'Option A' : 'Option B';
            }
            else if ((item.type === 'MultiChoice4' || item.type === 'MultiChoice5') && typeof value === 'number') {
                label = `Option ${value + 1}`;
            }
            else {
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
        s0MbtiItems: finalS0Mbti,
        s1Items: finalS1,
        demographics: { age, gender },
        s0Responses,
        s0MbtiResponses,
        s1Responses
    };
}
