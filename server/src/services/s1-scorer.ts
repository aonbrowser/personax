import { pool } from '../db/pool';

interface S1Responses {
  [key: string]: string | number;
}

interface S1Scores {
  bigfive: {
    E: number;  // Extraversion
    A: number;  // Agreeableness
    C: number;  // Conscientiousness
    N: number;  // Neuroticism
    O: number;  // Openness
  };
  mbti_axes: {
    E: number;  // Probability of E (vs I)
    S: number;  // Probability of S (vs N)
    T: number;  // Probability of T (vs F)
    J: number;  // Probability of J (vs P)
  };
  attachment: {
    anx: number;  // Attachment anxiety
    avo: number;  // Attachment avoidance
  };
  conflict_style: {
    compete: number;
    collab: number;
    comprom: number;
    avoid: number;
    accom: number;
  };
  disc: {
    D: number;  // Dominance
    I: number;  // Influence
    S: number;  // Steadiness
    C: number;  // Compliance
  };
  emotion_reg: {
    reappraise: number;
    suppress: number;
  };
  quality: {
    consistency: number;
    speed_ok: boolean;
    imc_passed: boolean;
  };
  confidence: number;
  notes?: string;
}

export class S1Scorer {
  /**
   * Calculate S1 scores from raw responses
   */
  static async calculateScores(responses: S1Responses, responseTime?: number): Promise<S1Scores> {
    // Initialize scores
    const scores: S1Scores = {
      bigfive: { E: 0, A: 0, C: 0, N: 0, O: 0 },
      mbti_axes: { E: 0.5, S: 0.5, T: 0.5, J: 0.5 },
      attachment: { anx: 0, avo: 0 },
      conflict_style: { compete: 0, collab: 0, comprom: 0, avoid: 0, accom: 0 },
      disc: { D: 0, I: 0, S: 0, C: 0 },
      emotion_reg: { reappraise: 0, suppress: 0 },
      quality: { 
        consistency: 100, 
        speed_ok: !responseTime || responseTime > 120, // More than 2 minutes
        imc_passed: true 
      },
      confidence: 85
    };

    // Get all S1 items for scoring
    const { rows: items } = await pool.query(
      `SELECT id, section, subscale, reverse_scored, scoring_key 
       FROM items 
       WHERE form = 'S1_self'`
    );

    // Score BigFive items (Likert5 scale: 1-5)
    const bigFiveItems = items.filter(item => item.section === 'BigFive');
    const bigFiveScores: Record<string, number[]> = { E: [], A: [], C: [], N: [], O: [] };
    
    bigFiveItems.forEach(item => {
      const response = responses[item.id];
      if (typeof response === 'number' && response >= 1 && response <= 5) {
        const score = item.reverse_scored ? (6 - response) : response;
        const dimension = item.subscale || item.scoring_key;
        if (dimension && bigFiveScores[dimension]) {
          bigFiveScores[dimension].push(score);
        }
      }
    });

    // Calculate average for each BigFive dimension and convert to 0-100
    Object.keys(bigFiveScores).forEach(dim => {
      const dimScores = bigFiveScores[dim];
      if (dimScores.length > 0) {
        const avg = dimScores.reduce((a, b) => a + b, 0) / dimScores.length;
        scores.bigfive[dim as keyof typeof scores.bigfive] = Math.round(((avg - 1) / 4) * 100);
      }
    });

    // Score MBTI items (Binary choices mapped to axes)
    const mbtiItems = items.filter(item => item.section === 'MBTI');
    const mbtiScores: Record<string, number[]> = { E: [], S: [], T: [], J: [] };
    
    mbtiItems.forEach(item => {
      const response = responses[item.id];
      if (typeof response === 'string') {
        // Response should be 'A' or 'B'
        const scoreMapping = item.scoring_key ? JSON.parse(item.scoring_key) : {};
        const dimension = item.subscale;
        if (dimension && mbtiScores[dimension]) {
          // A=1 means first option indicates the dimension, B=0 means second option
          const score = response === 'A' ? scoreMapping.A || 1 : scoreMapping.B || 0;
          mbtiScores[dimension].push(score);
        }
      }
    });

    // Calculate probabilities for MBTI axes
    Object.keys(mbtiScores).forEach(dim => {
      const dimScores = mbtiScores[dim];
      if (dimScores.length > 0) {
        const probability = dimScores.reduce((a, b) => a + b, 0) / dimScores.length;
        scores.mbti_axes[dim as keyof typeof scores.mbti_axes] = Math.round(probability * 100) / 100;
      }
    });

    // Score Attachment items
    const attachmentItems = items.filter(item => item.section === 'Attachment');
    const attachmentScores: Record<string, number[]> = { anx: [], avo: [] };
    
    attachmentItems.forEach(item => {
      const response = responses[item.id];
      if (typeof response === 'number' && response >= 1 && response <= 7) {
        const score = item.reverse_scored ? (8 - response) : response;
        const dimension = item.subscale === 'Anxiety' ? 'anx' : 'avo';
        attachmentScores[dimension].push(score);
      }
    });

    // Calculate attachment scores (1-7 scale to 0-100)
    Object.keys(attachmentScores).forEach(dim => {
      const dimScores = attachmentScores[dim];
      if (dimScores.length > 0) {
        const avg = dimScores.reduce((a, b) => a + b, 0) / dimScores.length;
        scores.attachment[dim as keyof typeof scores.attachment] = Math.round(((avg - 1) / 6) * 100);
      }
    });

    // Score Conflict items
    const conflictItems = items.filter(item => item.section === 'Conflict');
    const conflictScores: Record<string, number[]> = { 
      compete: [], collab: [], comprom: [], avoid: [], accom: [] 
    };
    
    conflictItems.forEach(item => {
      const response = responses[item.id];
      if (typeof response === 'string') {
        // For scenario-based conflict questions
        const scoring = item.scoring_key ? JSON.parse(item.scoring_key) : {};
        const selectedStyle = scoring[response];
        if (selectedStyle && conflictScores[selectedStyle]) {
          conflictScores[selectedStyle].push(1);
        }
      }
    });

    // Calculate conflict style preferences (count-based)
    const totalConflictResponses = Object.values(conflictScores).reduce((sum, arr) => sum + arr.length, 0);
    if (totalConflictResponses > 0) {
      Object.keys(conflictScores).forEach(style => {
        const count = conflictScores[style].length;
        scores.conflict_style[style as keyof typeof scores.conflict_style] = 
          Math.round((count / totalConflictResponses) * 100);
      });
    }

    // Score DISC items (simplified - would need proper DISC scoring algorithm)
    const discItems = items.filter(item => item.section === 'DISC');
    const discScores: Record<string, number[]> = { D: [], I: [], S: [], C: [] };
    
    discItems.forEach(item => {
      const response = responses[item.id];
      if (typeof response === 'number' && response >= 1 && response <= 5) {
        const dimension = item.subscale;
        if (dimension && discScores[dimension]) {
          const score = item.reverse_scored ? (6 - response) : response;
          discScores[dimension].push(score);
        }
      }
    });

    // Calculate DISC scores
    Object.keys(discScores).forEach(dim => {
      const dimScores = discScores[dim];
      if (dimScores.length > 0) {
        const avg = dimScores.reduce((a, b) => a + b, 0) / dimScores.length;
        scores.disc[dim as keyof typeof scores.disc] = Math.round(((avg - 1) / 4) * 100);
      }
    });

    // Check validity items (IMC = Instructed Response Check)
    const validityItems = items.filter(item => item.section === 'Validity');
    let imcPassed = true;
    
    validityItems.forEach(item => {
      const response = responses[item.id];
      const expectedResponse = item.scoring_key;
      if (expectedResponse && response !== expectedResponse) {
        imcPassed = false;
        scores.quality.consistency -= 20; // Reduce consistency score
      }
    });
    
    scores.quality.imc_passed = imcPassed;

    // Calculate overall confidence based on response patterns
    let confidence = 85;
    
    // Check for response completeness
    const expectedResponses = items.length;
    const actualResponses = Object.keys(responses).filter(key => 
      items.some(item => item.id === key)
    ).length;
    const completeness = actualResponses / expectedResponses;
    
    if (completeness < 0.9) confidence -= 20;
    else if (completeness < 0.95) confidence -= 10;
    
    // Check for speeding (if response time provided)
    if (responseTime && responseTime < 120) {
      scores.quality.speed_ok = false;
      confidence -= 15;
    }
    
    // IMC failure reduces confidence
    if (!imcPassed) confidence -= 25;
    
    scores.confidence = Math.max(0, Math.min(100, confidence));

    // Add notes if there are quality issues
    const notes: string[] = [];
    if (!scores.quality.speed_ok) notes.push('Response time too fast');
    if (!scores.quality.imc_passed) notes.push('Failed attention checks');
    if (completeness < 0.95) notes.push(`Only ${Math.round(completeness * 100)}% complete`);
    
    if (notes.length > 0) {
      scores.notes = notes.join('; ');
    }

    return scores;
  }

  /**
   * Format scores for inclusion in prompt
   */
  static formatForPrompt(scores: S1Scores): string {
    return JSON.stringify(scores, null, 2);
  }
}