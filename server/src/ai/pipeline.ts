import fs from 'node:fs';
import path from 'node:path';
import { retryEnforceLanguage, detectLanguageWithMini } from './providers/openai.js';
import { pool } from '../db/pool.js';
import { UsageTracker } from '../services/usage-tracker.js';
import { processPayloadSimple } from './simple-pipeline.js';

function loadPrompt(file:string) {
  const p = path.resolve(process.cwd(), 'src', 'prompts', file);
  return fs.readFileSync(p, 'utf8');
}

async function logLanguageIncident(params: {
  user_id: string; report_type:'self'|'other'|'dyad'|'coach';
  user_language: string; detected_language: string; content_preview: string;
}) {
  await pool.query(
    `INSERT INTO language_incidents (user_id, report_type, user_language, detected_language, content_preview)
     VALUES ($1,$2,$3,$4,$5)`,
    [params.user_id, params.report_type, params.user_language, params.detected_language, params.content_preview.slice(0,500)]
  );
}

type Msg = { role:'system'|'user'|'assistant', content:string };

export async function runSelfAnalysis(payload:any, userLang:string, userId:string, targetId:string = 'self', analysisId?: string) {
  let currentAnalysisId = analysisId;
  
  try {
    // Check usage limits before running
    const limitCheck = await UsageTracker.checkLimits(userId, 'self_analysis');
    if (!limitCheck.allowed) {
      // Update analysis as error if exists
      if (currentAnalysisId) {
        await pool.query(
          `UPDATE analysis_results 
           SET status = 'error', 
               error_message = $1 
           WHERE id = $2`,
          [limitCheck.reason, currentAnalysisId]
        );
      }
      
      return { 
        markdown: `## Limit Aşıldı\n\n${limitCheck.reason}\n\nDaha fazla analiz için abonelik planınızı yükseltebilir veya kullandığın kadar öde sistemimizi kullanabilirsiniz.`,
        language_ok: true,
        detected: userLang,
        banner: limitCheck.reason,
        limitExceeded: true
      };
    }

    // Check if this is a reanalysis
    const isReanalysis = await UsageTracker.isReanalysis(userId, 'self_analysis', targetId);
    
    // Create or update analysis record
    if (!currentAnalysisId) {
      // Check if new form structure or old S0/S1 structure
      if (payload.form1 || payload.form2 || payload.form3) {
        // NEW FORM STRUCTURE - Store form data separately
        console.log('[PIPELINE] Storing new form data in analysis_results');
        const { rows } = await pool.query(
          `INSERT INTO analysis_results (user_id, analysis_type, status, form1_data, form2_data, form3_data, created_at)
           VALUES ($1, 'self', 'processing', $2, $3, $4, NOW())
           RETURNING id`,
          [userId, payload.form1 || {}, payload.form2 || {}, payload.form3 || {}]
        );
        currentAnalysisId = rows[0].id;
      } else {
        // OLD S0/S1 STRUCTURE
        const s0DataForStorage = {};
        const s1DataForStorage = {};
        
        // If s0Items provided, extract responses
        if (payload.s0Items && payload.s0Items.length > 0) {
          payload.s0Items.forEach(item => {
            if (item.response !== undefined) {
              s0DataForStorage[item.id] = item.response;
            }
          });
        } else {
          // Fallback to old format
          Object.assign(s0DataForStorage, payload.s0 || {});
        }
        
        // If s1Items provided, extract responses
        if (payload.s1Items && payload.s1Items.length > 0) {
          payload.s1Items.forEach(item => {
            if (item.response !== undefined) {
              s1DataForStorage[item.id] = item.response;
            }
          });
        } else {
          // Fallback to old format
          Object.assign(s1DataForStorage, payload.s1 || {});
        }
        
        // Create new analysis record with extracted data
        const { rows } = await pool.query(
          `INSERT INTO analysis_results (user_id, analysis_type, status, s0_data, s1_data, created_at)
           VALUES ($1, 'self', 'processing', $2, $3, NOW())
           RETURNING id`,
          [userId, s0DataForStorage, s1DataForStorage]
        );
        currentAnalysisId = rows[0].id;
      }
    }
  
  // Load the new unified S1 prompt
  const sys = loadPrompt('s1.md');
  
  // Use simple processor
  const processed = processPayloadSimple(payload);
  
  // Handle new form structure
  let finalS0Items, finalS1Items;
  if (processed.form1Items && processed.form2Items && processed.form3Items) {
    // New structure - Fetch item details from database and merge with responses
    console.log('[PIPELINE] Using new form structure');
    
    // Get all form item IDs
    const form1Ids = processed.form1Items.map(item => item.id);
    const form2Ids = processed.form2Items.map(item => item.id);
    const form3Ids = processed.form3Items.map(item => item.id);
    const allIds = [...form1Ids, ...form2Ids, ...form3Ids];
    
    // Fetch item details from database
    const { rows: itemDetails } = await pool.query(
      `SELECT id, text_tr, type, options_tr, subscale, reverse_scored, test_type, section 
       FROM items 
       WHERE id = ANY($1)`,
      [allIds]
    );
    
    // Create a map for quick lookup
    const itemMap = new Map(itemDetails.map(item => [item.id, item]));
    
    // Merge form1 items with details
    finalS0Items = processed.form1Items.map(respItem => {
      const details = itemMap.get(respItem.id) || {};
      return {
        ...details,
        ...respItem,
        response_value: respItem.response_value,
        response_label: String(respItem.response_value || '')
      };
    });
    
    // Merge form2 and form3 items with details
    const form2WithDetails = processed.form2Items.map(respItem => {
      const details = itemMap.get(respItem.id) || {};
      return {
        ...details,
        ...respItem,
        response_value: respItem.response_value,
        response_label: String(respItem.response_value || '')
      };
    });
    
    const form3WithDetails = processed.form3Items.map(respItem => {
      const details = itemMap.get(respItem.id) || {};
      return {
        ...details,
        ...respItem,
        response_value: respItem.response_value,
        response_label: String(respItem.response_value || '')
      };
    });
    
    finalS1Items = [...form2WithDetails, ...form3WithDetails];
    
    console.log('[PIPELINE] Form items with details:');
    console.log('- Form1 (S0) items:', finalS0Items.length);
    console.log('- Form2+3 (S1) items:', finalS1Items.length);
  } else {
    // Old structure fallback
    console.log('[PIPELINE] Using old S0/S1 structure');
    finalS0Items = processed.s0Items;
    finalS1Items = processed.s1Items;
  }
  
  const { age, gender } = processed.demographics;
  
  // Determine target language
  const targetLang = userLang;
  
  // Prepare the data blocks for the prompt
  // REMOVED s0Block - it was redundant since s0ItemsBlock already contains all responses
  const s0ItemsBlock = `<S0_ITEMS>\n${JSON.stringify(finalS0Items, null, 2)}\n</S0_ITEMS>`;
  const s1ItemsBlock = `<S1_ITEMS>\n${JSON.stringify(finalS1Items, null, 2)}\n</S1_ITEMS>`;
  
  // Demographics already extracted by processor
  const locale = targetLang;
  
  // Debug logging
  console.log('[PIPELINE] Final data check:');
  console.log('- Demographics:', { age, gender, locale });
  console.log('- S0 items with responses:', finalS0Items.filter(i => i.response_value).length);
  console.log('- S1 items with responses:', finalS1Items.filter(i => i.response_value).length);
  
  const reporterMetaBlock = `<REPORTER_META>\n${JSON.stringify({
    demographics: {
      age: age,
      gender: gender,
      locale: locale
    },
    focus_areas: ['self_growth', 'relationships', 'work'],
    target_lang: targetLang,
    render_options: { 
      allow_lists: true, 
      allow_tables: true, 
      allow_ascii_charts: true,
      per_item_review: 'full',
      items_per_table: 20,
      include_s0_item_review: true
    }
  }, null, 2)}\n</REPORTER_META>`;
  
  // Combine prompt with data (removed s0Block as it was redundant)
  const fullInput = `${s0ItemsBlock}\n\n${s1ItemsBlock}\n\n${reporterMetaBlock}`;
  
  const messages: Msg[] = [ 
    { role:'system', content: sys }, 
    { role:'user', content: fullInput } 
  ];
  
  const { content, ok, detected, tokenUsage } = await retryEnforceLanguage(messages, targetLang, 2);
  
  // Check for LANG_MISMATCH marker in the response
  let finalContent = content;
  let languageOk = ok;
  
  if (content.startsWith('[[LANG_MISMATCH]]')) {
    // Remove the marker and retry with enforcement
    finalContent = content.replace('[[LANG_MISMATCH]]', '').trim();
    const langCheck = await detectLanguageWithMini(finalContent, targetLang);
    languageOk = langCheck.ok;
    
    if (!languageOk) {
      // Log the mismatch
      await logLanguageIncident({ 
        user_id: userId, 
        report_type: 'self', 
        user_language: targetLang, 
        detected_language: langCheck.detected, 
        content_preview: finalContent.slice(0, 400) 
      });
    }
  }
  
  // Track usage
  await UsageTracker.trackUsage({
    userId,
    serviceType: 'self_analysis',
    targetId,
    isReanalysis,
    tokenUsage,
    subscriptionId: limitCheck.subscription?.id
  });
  
  // Extract notes-for-lifecoaching from the response
  let lifecoachingNotes = null;
  let cleanedContent = finalContent;
  
  // Look for the notes-for-lifecoaching section
  const notesMatch = finalContent.match(/### 13\) notes-for-lifecoaching:[\s\S]*?```jsonc?\n([\s\S]*?)\n```/i);
  if (notesMatch) {
    try {
      lifecoachingNotes = JSON.parse(notesMatch[1]);
      // Store in database for later use
      await pool.query(
        `INSERT INTO user_lifecoaching_notes (user_id, notes, created_at)
         VALUES ($1, $2, NOW())
         ON CONFLICT (user_id) 
         DO UPDATE SET notes = $2, updated_at = NOW()`,
        [userId, lifecoachingNotes]
      );
      
      // Remove the notes section from user-visible content
      cleanedContent = finalContent.replace(/### 13\) notes-for-lifecoaching:[\s\S]*?```jsonc?\n[\s\S]*?\n```/i, '');
    } catch (error) {
      console.error('Error parsing lifecoaching notes:', error);
    }
  }
  
  // Update analysis record with result
  if (currentAnalysisId) {
    await pool.query(
      `UPDATE analysis_results 
       SET status = 'completed', 
           result_markdown = $1, 
           lifecoaching_notes = $2,
           completed_at = NOW(),
           metadata = $3
       WHERE id = $4`,
      [
        cleanedContent,
        lifecoachingNotes,
        { language: targetLang, language_ok: languageOk },
        currentAnalysisId
      ]
    );
  }
  
    const banner = languageOk ? null : "Bu rapor sizin dilinizde değil gibi görünüyor. Sistem yöneticilerimiz durumdan haberdar edildi. En yakın zamanda kendi dilinizde rapor vereceğiz.";
    return { 
      markdown: cleanedContent, 
      language_ok: languageOk, 
      detected: languageOk ? targetLang : detected,
      banner,
      lifecoachingNotes, // Include in response but frontend won't display it
      analysisId: currentAnalysisId
    };
  } catch (error) {
    console.error('Analysis error:', error);
    
    // Update analysis record with error
    if (currentAnalysisId) {
      await pool.query(
        `UPDATE analysis_results 
         SET status = 'error', 
             error_message = $1 
         WHERE id = $2`,
        [error.message || 'Analysis failed', currentAnalysisId]
      );
    }
    
    throw error;
  }
}

export async function runOtherAnalysis(payload:any, userLang:string, userId:string, targetId:string) {
  // Check usage limits before running
  const limitCheck = await UsageTracker.checkLimits(userId, 'other_analysis');
  if (!limitCheck.allowed) {
    return { 
      markdown: `## Limit Aşıldı\n\n${limitCheck.reason}\n\nDaha fazla analiz için abonelik planınızı yükseltebilir veya kullandığın kadar öde sistemimizi kullanabilirsiniz.`,
      language_ok: true,
      detected: userLang,
      banner: limitCheck.reason,
      limitExceeded: true
    };
  }

  // Check if this is a reanalysis
  const isReanalysis = await UsageTracker.isReanalysis(userId, 'other_analysis', targetId);
  
  const sys = loadPrompt('other.md');
  const messages: Msg[] = [ { role:'system', content: sys }, { role:'user', content: `INPUT JSON:\n${JSON.stringify(payload)}` } ];
  const { content, ok, detected, tokenUsage } = await retryEnforceLanguage(messages, userLang, 2);
  
  // Track usage
  await UsageTracker.trackUsage({
    userId,
    serviceType: 'other_analysis',
    targetId,
    isReanalysis,
    tokenUsage,
    subscriptionId: limitCheck.subscription?.id
  });
  
  if (!ok) await logLanguageIncident({ user_id:userId, report_type:'other', user_language:userLang, detected_language:detected, content_preview:content.slice(0,400) });
  const banner = ok ? null : "Bu rapor sizin dilinizde değil gibi görünüyor. Sistem yöneticilerimiz durumdan haberdar edildi. En yakın zamanda kendi dilinizde rapor vereceğiz.";
  return { markdown: content, language_ok: ok, detected, banner };
}

export async function runDyadReport(payload:any, userLang:string, userId:string, targetId:string) {
  // Check usage limits before running
  const limitCheck = await UsageTracker.checkLimits(userId, 'relationship_analysis');
  if (!limitCheck.allowed) {
    return { 
      markdown: `## Limit Aşıldı\n\n${limitCheck.reason}\n\nDaha fazla analiz için abonelik planınızı yükseltebilir veya kullandığın kadar öde sistemimizi kullanabilirsiniz.`,
      language_ok: true,
      detected: userLang,
      banner: limitCheck.reason,
      limitExceeded: true
    };
  }

  // Check if this is a reanalysis
  const isReanalysis = await UsageTracker.isReanalysis(userId, 'relationship_analysis', targetId);
  
  const sys = loadPrompt('dyad.md');
  const messages: Msg[] = [ { role:'system', content: sys }, { role:'user', content: `INPUT JSON:\n${JSON.stringify(payload)}` } ];
  const { content, ok, detected, tokenUsage } = await retryEnforceLanguage(messages, userLang, 2);
  
  // Track usage
  await UsageTracker.trackUsage({
    userId,
    serviceType: 'relationship_analysis',
    targetId,
    isReanalysis,
    tokenUsage,
    subscriptionId: limitCheck.subscription?.id
  });
  
  if (!ok) await logLanguageIncident({ user_id:userId, report_type:'dyad', user_language:userLang, detected_language:detected, content_preview:content.slice(0,400) });
  const banner = ok ? null : "Bu rapor sizin dilinizde değil gibi görünüyor. Sistem yöneticilerimiz durumdan haberdar edildi. En yakın zamanda kendi dilinizde rapor vereceğiz.";
  return { markdown: content, language_ok: ok, detected, banner };
}

export async function runCoach(payload:any, userLang:string, userId:string) {
  // Check usage limits before running
  const limitCheck = await UsageTracker.checkLimits(userId, 'coaching');
  if (!limitCheck.allowed) {
    return { 
      markdown: `## Limit Aşıldı\n\n${limitCheck.reason}\n\nDaha fazla coaching token satın almak için abonelik planınızı yükseltebilir veya token paketi satın alabilirsiniz.`,
      language_ok: true,
      detected: userLang,
      banner: limitCheck.reason,
      limitExceeded: true
    };
  }
  
  // Fetch user's lifecoaching notes from database
  let lifecoachingNotes = {};
  try {
    const { rows } = await pool.query(
      'SELECT notes FROM user_lifecoaching_notes WHERE user_id = $1',
      [userId]
    );
    if (rows.length > 0) {
      lifecoachingNotes = rows[0].notes;
    }
  } catch (error) {
    console.error('Error fetching lifecoaching notes:', error);
  }
  
  // Prepare the coaching prompt with context
  const sys = loadPrompt('coach.md');
  const targetLang = lifecoachingNotes.language || userLang;
  
  // Format the input with lifecoaching context
  const coachingInput = `<LIFECOACHING_NOTES>\n${JSON.stringify(lifecoachingNotes, null, 2)}\n</LIFECOACHING_NOTES>\n\n<USER_QUESTION>\n${payload.question || payload.situation || JSON.stringify(payload)}\n</USER_QUESTION>`;
  
  const messages: Msg[] = [ 
    { role:'system', content: sys.replace('{{target_lang}}', targetLang) }, 
    { role:'user', content: coachingInput } 
  ];
  
  const { content, ok, detected, tokenUsage } = await retryEnforceLanguage(messages, targetLang, 2);
  
  // Track usage (no targetId for coaching)
  await UsageTracker.trackUsage({
    userId,
    serviceType: 'coaching',
    targetId: undefined,
    isReanalysis: false,
    tokenUsage,
    subscriptionId: limitCheck.subscription?.id
  });
  
  if (!ok) await logLanguageIncident({ user_id:userId, report_type:'coach', user_language:userLang, detected_language:detected, content_preview:content.slice(0,400) });
  const banner = ok ? null : "Bu rapor sizin dilinizde değil gibi görünüyor. Sistem yöneticilerimiz durumdan haberdar edildi. En yakın zamanda kendi dilinizde rapor vereceğiz.";
  return { markdown: content, language_ok: ok, detected, banner };
}
