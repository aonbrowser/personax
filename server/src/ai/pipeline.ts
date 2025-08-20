import fs from 'node:fs';
import path from 'node:path';
import { retryEnforceLanguage, detectLanguageWithMini } from './providers/openai.js';
import { pool } from '../db/pool.js';
import { UsageTracker } from '../services/usage-tracker.js';

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
      // Create new analysis record
      const { rows } = await pool.query(
        `INSERT INTO analysis_results (user_id, analysis_type, status, s0_data, s1_data, created_at)
         VALUES ($1, 'self', 'processing', $2, $3, NOW())
         RETURNING id`,
        [userId, payload.s0 || {}, payload.s1 || {}]
      );
      currentAnalysisId = rows[0].id;
    }
  
  // Load the new unified S1 prompt
  const sys = loadPrompt('s1.md');
  
  // Extract S0 and S1 data from payload
  const s0Data = payload.s0 || {};
  const s1Responses = payload.s1 || {};
  const s0Items = payload.s0Items || [];
  const s1Items = payload.s1Items || [];
  const responseTime = payload.responseTime;
  
  // Determine target language: S0.S0_LANG ?? userLang
  const targetLang = s0Data.S0_LANG || s0Data.lang || userLang;
  
  // If items not provided, fetch from database and merge with responses
  let finalS0Items = s0Items;
  let finalS1Items = s1Items;
  
  if (finalS0Items.length === 0) {
    // Fetch S0 items from database
    const { rows: s0ItemRows } = await pool.query(
      `SELECT id, form, section, subscale, text_tr as text, type, options_tr as options, 
              reverse_scored, scoring_key, weight, notes
       FROM items WHERE form = 'S0_profile' ORDER BY display_order, id`
    );
    
    finalS0Items = s0ItemRows.map(item => ({
      id: item.id,
      text: item.text,
      section: item.section,
      subscale: item.subscale,
      type: item.type,
      response_value: s0Data[item.id],
      response_label: s0Data[item.id]?.toString() || '',
      weight: item.weight || 1,
      note: item.notes || 'context'
    }));
  }
  
  if (finalS1Items.length === 0) {
    // Fetch S1 items from database
    const { rows: s1ItemRows } = await pool.query(
      `SELECT id, form, section, subscale, text_tr as text, type, options_tr as options, 
              reverse_scored, scoring_key, weight, notes
       FROM items WHERE form = 'S1_self' ORDER BY display_order, id`
    );
    
    finalS1Items = s1ItemRows.map(item => {
      const responseValue = s1Responses[item.id];
      let responseLabel = '';
      
      // Convert response value to label based on type
      if (item.type === 'Likert5' && typeof responseValue === 'number') {
        const labels = ['Strongly Disagree', 'Disagree', 'Neutral', 'Agree', 'Strongly Agree'];
        responseLabel = labels[responseValue - 1] || responseValue.toString();
      } else if (item.type === 'Likert7' && typeof responseValue === 'number') {
        responseLabel = responseValue.toString();
      } else if (item.type === 'ForcedChoice2') {
        responseLabel = responseValue === 'A' ? 'Option A' : 'Option B';
      } else {
        responseLabel = responseValue?.toString() || '';
      }
      
      return {
        id: item.id,
        text: item.text,
        section: item.section,
        subscale: item.subscale,
        type: item.type,
        options: item.options?.split('|') || [],
        reverse_scored: item.reverse_scored,
        response_value: responseValue,
        response_label: responseLabel,
        weight: item.weight || 1,
        scoring_key: item.scoring_key ? JSON.parse(item.scoring_key) : {},
        facet: item.notes
      };
    });
  }
  
  // Prepare the data blocks for the prompt
  const s0Block = `<S0>\n${JSON.stringify(s0Data, null, 2)}\n</S0>`;
  const s0ItemsBlock = `<S0_ITEMS>\n${JSON.stringify(finalS0Items, null, 2)}\n</S0_ITEMS>`;
  const s1ItemsBlock = `<S1_ITEMS>\n${JSON.stringify(finalS1Items, null, 2)}\n</S1_ITEMS>`;
  
  // Optional: Calculate scores server-side if needed (for backward compatibility)
  let s1ScoresBlock = '';
  // Commenting out server-side scoring as AI will handle it
  // const s1Scores = await S1Scorer.calculateScores(s1Responses, responseTime);
  // s1ScoresBlock = `<S1_SCORES>\n${JSON.stringify(s1Scores, null, 2)}\n</S1_SCORES>\n\n`;
  
  const reporterMetaBlock = `<REPORTER_META>\n${JSON.stringify({
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
  
  // Optional: Include raw responses for context
  const rawResponsesBlock = '';
  
  // Combine prompt with data
  const fullInput = `${s0Block}\n\n${s1ScoresBlock}${s0ItemsBlock}\n\n${s1ItemsBlock}\n\n${reporterMetaBlock}${rawResponsesBlock ? '\n\n' + rawResponsesBlock : ''}`;
  
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
