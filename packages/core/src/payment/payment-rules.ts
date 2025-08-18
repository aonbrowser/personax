// Single source of truth for pricing/rules
export const CURRENCY = 'USD' as const;
export const PRICE = {
  subscription: 19,
  selfAnalysis: 3,
  otherAnalysis: 3,
  relationshipAnalysis: 2,
  coachTrialDays: 3,
} as const;

export type Product = 'SELF'|'OTHER'|'REL'|'COACH';

export interface Usage {
  selfAnalysesUsed: number;
  otherAnalysesUsed: number;
  relationshipAnalysesUsed: number;
  coachDaysUsed: number; // rolling 30d suggested
}
export interface UserPlan { subscriptionActive: boolean; }
export interface EvalContext { plan: UserPlan; usage: Usage; }
export interface Decision {
  allowed: boolean;
  reason: 'free'|'quota_free'|'payment_required'|'subscribe_required';
  chargeUSD: number;
  message: string;
}

const SUBSCRIPTION_FREE = { otherAnalyses: 10, relationshipAnalyses: 10 } as const;

export function evaluatePayment(product: Product, ctx: EvalContext): Decision {
  const { plan, usage } = ctx;
  if (plan.subscriptionActive) {
    switch (product) {
      case 'SELF':  return { allowed: true, reason: 'free', chargeUSD: 0, message: 'Kendi Analizi abonelikte ücretsiz.' };
      case 'OTHER': return usage.otherAnalysesUsed < SUBSCRIPTION_FREE.otherAnalyses
        ? { allowed: true, reason: 'quota_free', chargeUSD: 0, message: 'Abonelik kotasından ücretsiz.' }
        : { allowed: true, reason: 'payment_required', chargeUSD: PRICE.otherAnalysis, message: 'Kota aşıldı; ek ücret.' };
      case 'REL':   return usage.relationshipAnalysesUsed < SUBSCRIPTION_FREE.relationshipAnalyses
        ? { allowed: true, reason: 'quota_free', chargeUSD: 0, message: 'Abonelik kotasından ücretsiz.' }
        : { allowed: true, reason: 'payment_required', chargeUSD: PRICE.relationshipAnalysis, message: 'Kota aşıldı; ek ücret.' };
      case 'COACH': return { allowed: true, reason: 'free', chargeUSD: 0, message: 'Koçluk abonelikte sınırsız.' };
    }
  } else {
    switch (product) {
      case 'SELF':  return { allowed: true, reason: 'payment_required', chargeUSD: PRICE.selfAnalysis, message: 'Kendi Analizi tekil satın alım.' };
      case 'OTHER': return { allowed: true, reason: 'payment_required', chargeUSD: PRICE.otherAnalysis, message: 'Başkasının Analizi tekil satın alım.' };
      case 'REL':   return { allowed: true, reason: 'payment_required', chargeUSD: PRICE.relationshipAnalysis, message: 'İlişki Analizi tekil satın alım.' };
      case 'COACH': return (usage.coachDaysUsed < PRICE.coachTrialDays)
        ? { allowed: true, reason: 'free', chargeUSD: 0, message: `Koçluk ${PRICE.coachTrialDays} gün ücretsiz.` }
        : { allowed: false, reason: 'subscribe_required', chargeUSD: 0, message: 'Koçluk için abonelik gerekir.' };
    }
  }
}
