export type Domain = 'romantic'|'family'|'friend'|'work';
export interface MBTIProbs { E:number; S:number; T:number; J:number; } // 0..1
export interface Quality { consistency:number; speedQuality:number; axisMarginAvg:number; sampleSize:number; } // 0..1
export interface Attachment { anxiety:number; avoidance:number; } // 0..100
export interface Deltas { bigFiveDeltaMax:number; } // 0..100
export interface TriggerDecision { showS3:boolean; suggestS4:boolean; reasons:string[]; }

export const THRESHOLDS = {
  borderlineBand: [0.45,0.55] as const,
  deltaHigh: 25,
  qualityMin: 0.70,
  attachRisk: { anxiety: 65, avoidance: 65 },
} as const;

export function decideNext(domain: Domain, mbti: MBTIProbs, deltas:Deltas, q:Quality, att:Attachment): TriggerDecision {
  const reasons:string[] = [];
  const inBand = (p:number)=> p>=THRESHOLDS.borderlineBand[0] && p<=THRESHOLDS.borderlineBand[1];
  const borderlineCount = [mbti.E, mbti.S, mbti.T, mbti.J].filter(inBand).length;

  let showS3=false;
  if (borderlineCount >= 2) { showS3=true; reasons.push('MBTI eksenlerinde belirsizlik ≥2'); }
  if (deltas.bigFiveDeltaMax >= THRESHOLDS.deltaHigh) { showS3=true; reasons.push('Self–Other farkı yüksek'); }
  const qscore = 0.5*q.consistency + 0.2*q.speedQuality + 0.2*q.axisMarginAvg + 0.1*q.sampleSize;
  if (qscore < THRESHOLDS.qualityMin) { showS3=true; reasons.push('Güven endeksi düşük'); }
  if (att.anxiety >= THRESHOLDS.attachRisk.anxiety && att.avoidance >= THRESHOLDS.attachRisk.avoidance) {
    showS3=true; reasons.push('Bağlanma risk kombinasyonu'); 
  }

  let suggestS4=false;
  if (domain==='romantic') { suggestS4=true; reasons.push('Romantik ilişkide değer/sınır planı'); }
  else if (domain==='family') { suggestS4 = deltas.bigFiveDeltaMax>=15 || borderlineCount>=1; if (suggestS4) reasons.push('Aile bağlamında S4'); }
  else if (domain==='friend') { suggestS4 = deltas.bigFiveDeltaMax>=15; if (suggestS4) reasons.push('Arkadaşlıkta S4'); }
  else if (domain==='work') { suggestS4=true; reasons.push('İş bağlamında S4'); }

  return { showS3, suggestS4, reasons };
}
