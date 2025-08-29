import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  SafeAreaView,
  TouchableOpacity,
  ActivityIndicator,
  RefreshControl,
} from 'react-native';
import { API_URL } from '../config';

interface CreditsScreenProps {
  navigation: any;
  route: {
    params: {
      userEmail: string;
    };
  };
}

interface Subscription {
  id: string;
  plan_id: string;
  status: 'active' | 'expired' | 'cancelled';
  start_date: string;
  end_date: string;
  is_primary: boolean;
  credits_remaining: {
    self_analysis?: number;
    self_reanalysis?: number;
    other_analysis?: number;
    relationship_analysis?: number;
    coaching_tokens?: number;
  };
  // Initial limits from plan
  self_analysis_limit?: number;
  self_reanalysis_limit?: number;
  other_analysis_limit?: number;
  relationship_analysis_limit?: number;
  coaching_tokens_limit?: number;
}

interface MonthlyUsage {
  self_analysis_count: number;
  self_reanalysis_count: number;
  other_analysis_count: number;
  relationship_analysis_count: number;
  coaching_tokens_used: number;
}

export default function CreditsScreen({ navigation, route }: CreditsScreenProps) {
  const { userEmail } = route.params;
  const [subscriptions, setSubscriptions] = useState<Subscription[]>([]);
  const [monthlyUsage, setMonthlyUsage] = useState<MonthlyUsage | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    loadCreditsInfo();
  }, []);

  const loadCreditsInfo = async () => {
    try {
      const response = await fetch(
        `${API_URL}/v1/payment/check-limits?service_type=self_analysis`,
        {
          headers: {
            'x-user-email': userEmail,
          },
        }
      );

      if (response.ok) {
        const data = await response.json();
        setSubscriptions(data.subscriptions || []);
        setMonthlyUsage(data.monthlyUsage || null);
      }
    } catch (error) {
      console.error('Error loading credits info:', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const onRefresh = () => {
    setRefreshing(true);
    loadCreditsInfo();
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('tr-TR', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    });
  };

  const getPlanName = (planId: string) => {
    switch (planId) {
      case 'standard':
        return 'Standart Paket';
      case 'extra':
        return 'Ekstra Paket';
      default:
        return planId;
    }
  };

  const getTotalCredits = () => {
    const totals = {
      self_analysis: { remaining: 0, total: 0, used: 0 },
      self_reanalysis: { remaining: 0, total: 0, used: 0 },
      other_analysis: { remaining: 0, total: 0, used: 0 },
      relationship_analysis: { remaining: 0, total: 0, used: 0 },
      coaching_tokens: { remaining: 0, total: 0, used: 0 },
    };

    subscriptions
      .filter(sub => sub.status === 'active')
      .forEach(sub => {
        // Add remaining credits
        if (sub.credits_remaining) {
          totals.self_analysis.remaining += sub.credits_remaining.self_analysis || 0;
          totals.self_reanalysis.remaining += sub.credits_remaining.self_reanalysis || 0;
          totals.other_analysis.remaining += sub.credits_remaining.other_analysis || 0;
          totals.relationship_analysis.remaining += sub.credits_remaining.relationship_analysis || 0;
          totals.coaching_tokens.remaining += sub.credits_remaining.coaching_tokens || 0;
        }
        
        // Add total limits
        totals.self_analysis.total += sub.self_analysis_limit || 0;
        totals.self_reanalysis.total += sub.self_reanalysis_limit || 0;
        totals.other_analysis.total += sub.other_analysis_limit || 0;
        totals.relationship_analysis.total += sub.relationship_analysis_limit || 0;
        totals.coaching_tokens.total += sub.coaching_tokens_limit || 0;
      });

    // Calculate used credits
    totals.self_analysis.used = totals.self_analysis.total - totals.self_analysis.remaining;
    totals.self_reanalysis.used = totals.self_reanalysis.total - totals.self_reanalysis.remaining;
    totals.other_analysis.used = totals.other_analysis.total - totals.other_analysis.remaining;
    totals.relationship_analysis.used = totals.relationship_analysis.total - totals.relationship_analysis.remaining;
    totals.coaching_tokens.used = totals.coaching_tokens.total - totals.coaching_tokens.remaining;

    return totals;
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backButton}>
            <Text style={styles.backArrow}>←</Text>
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Kredilerim</Text>
          <View style={styles.headerSpacer} />
        </View>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="rgb(66, 153, 225)" />
        </View>
      </SafeAreaView>
    );
  }

  const totalCredits = getTotalCredits();
  const hasActiveSubscription = subscriptions.some(sub => sub.status === 'active');

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backButton}>
          <Text style={styles.backArrow}>←</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Kredilerim</Text>
        <View style={styles.headerSpacer} />
      </View>

      <ScrollView
        style={styles.content}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
      >
        {/* Total Credits Summary */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Toplam Kredilerim</Text>
          <View style={styles.totalCreditsCard}>
            {hasActiveSubscription ? (
              <>
                <View style={styles.creditItem}>
                  <View style={styles.creditIconContainer}>
                    <Text style={styles.creditIcon}>👤</Text>
                  </View>
                  <View style={styles.creditInfo}>
                    <Text style={styles.creditLabel}>Kendi Analizi</Text>
                    <View style={styles.creditValueContainer}>
                      <Text style={styles.creditValue}>{totalCredits.self_analysis.remaining}</Text>
                      <Text style={styles.creditDivider}>/</Text>
                      <Text style={styles.creditTotal}>{totalCredits.self_analysis.total}</Text>
                    </View>
                    <View style={styles.progressBar}>
                      <View 
                        style={[
                          styles.progressFill, 
                          { width: `${(totalCredits.self_analysis.remaining / totalCredits.self_analysis.total) * 100}%` }
                        ]} 
                      />
                    </View>
                  </View>
                </View>

                <View style={styles.creditItem}>
                  <View style={styles.creditIconContainer}>
                    <Text style={styles.creditIcon}>🔄</Text>
                  </View>
                  <View style={styles.creditInfo}>
                    <Text style={styles.creditLabel}>Analiz Güncelleme</Text>
                    <View style={styles.creditValueContainer}>
                      <Text style={styles.creditValue}>{totalCredits.self_reanalysis.remaining}</Text>
                      <Text style={styles.creditDivider}>/</Text>
                      <Text style={styles.creditTotal}>{totalCredits.self_reanalysis.total}</Text>
                    </View>
                    <View style={styles.progressBar}>
                      <View 
                        style={[
                          styles.progressFill, 
                          { width: `${(totalCredits.self_reanalysis.remaining / totalCredits.self_reanalysis.total) * 100}%` }
                        ]} 
                      />
                    </View>
                  </View>
                </View>

                <View style={styles.creditItem}>
                  <View style={styles.creditIconContainer}>
                    <Text style={styles.creditIcon}>👥</Text>
                  </View>
                  <View style={styles.creditInfo}>
                    <Text style={styles.creditLabel}>Kişi Analizi</Text>
                    <View style={styles.creditValueContainer}>
                      <Text style={styles.creditValue}>{totalCredits.other_analysis.remaining}</Text>
                      <Text style={styles.creditDivider}>/</Text>
                      <Text style={styles.creditTotal}>{totalCredits.other_analysis.total}</Text>
                    </View>
                    <View style={styles.progressBar}>
                      <View 
                        style={[
                          styles.progressFill, 
                          { width: `${(totalCredits.other_analysis.remaining / totalCredits.other_analysis.total) * 100}%` }
                        ]} 
                      />
                    </View>
                  </View>
                </View>

                <View style={styles.creditItem}>
                  <View style={styles.creditIconContainer}>
                    <Text style={styles.creditIcon}>💑</Text>
                  </View>
                  <View style={styles.creditInfo}>
                    <Text style={styles.creditLabel}>İlişki Analizi</Text>
                    <View style={styles.creditValueContainer}>
                      <Text style={styles.creditValue}>{totalCredits.relationship_analysis.remaining}</Text>
                      <Text style={styles.creditDivider}>/</Text>
                      <Text style={styles.creditTotal}>{totalCredits.relationship_analysis.total}</Text>
                    </View>
                    <View style={styles.progressBar}>
                      <View 
                        style={[
                          styles.progressFill, 
                          { width: `${(totalCredits.relationship_analysis.remaining / totalCredits.relationship_analysis.total) * 100}%` }
                        ]} 
                      />
                    </View>
                  </View>
                </View>

                <View style={styles.creditItem}>
                  <View style={styles.creditIconContainer}>
                    <Text style={styles.creditIcon}>🎯</Text>
                  </View>
                  <View style={styles.creditInfo}>
                    <Text style={styles.creditLabel}>Koçluk Token</Text>
                    <View style={styles.creditValueContainer}>
                      <Text style={styles.creditValue}>
                        {(totalCredits.coaching_tokens.remaining / 1000000).toFixed(1)}M
                      </Text>
                      <Text style={styles.creditDivider}>/</Text>
                      <Text style={styles.creditTotal}>
                        {(totalCredits.coaching_tokens.total / 1000000).toFixed(1)}M
                      </Text>
                    </View>
                    <View style={styles.progressBar}>
                      <View 
                        style={[
                          styles.progressFill, 
                          { width: `${(totalCredits.coaching_tokens.remaining / totalCredits.coaching_tokens.total) * 100}%` }
                        ]} 
                      />
                    </View>
                  </View>
                </View>
              </>
            ) : (
              <View style={styles.noCreditsBox}>
                <Text style={styles.noCreditsText}>Aktif aboneliğiniz bulunmamaktadır</Text>
                <TouchableOpacity
                  style={styles.subscribeButton}
                  onPress={() => navigation.navigate('Subscription', { userEmail })}
                >
                  <Text style={styles.subscribeButtonText}>Paketleri Görüntüle</Text>
                </TouchableOpacity>
              </View>
            )}
          </View>
        </View>

        {/* Monthly Usage */}
        {monthlyUsage && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Bu Ay Kullanım</Text>
            <View style={styles.usageCard}>
              <View style={styles.usageGrid}>
                {monthlyUsage.self_analysis_count > 0 && (
                  <View style={styles.usageItem}>
                    <Text style={styles.usageCount}>{monthlyUsage.self_analysis_count}</Text>
                    <Text style={styles.usageLabel}>Kendi Analizi</Text>
                  </View>
                )}
                {monthlyUsage.self_reanalysis_count > 0 && (
                  <View style={styles.usageItem}>
                    <Text style={styles.usageCount}>{monthlyUsage.self_reanalysis_count}</Text>
                    <Text style={styles.usageLabel}>Güncelleme</Text>
                  </View>
                )}
                {monthlyUsage.other_analysis_count > 0 && (
                  <View style={styles.usageItem}>
                    <Text style={styles.usageCount}>{monthlyUsage.other_analysis_count}</Text>
                    <Text style={styles.usageLabel}>Kişi Analizi</Text>
                  </View>
                )}
                {monthlyUsage.relationship_analysis_count > 0 && (
                  <View style={styles.usageItem}>
                    <Text style={styles.usageCount}>{monthlyUsage.relationship_analysis_count}</Text>
                    <Text style={styles.usageLabel}>İlişki Analizi</Text>
                  </View>
                )}
                {monthlyUsage.coaching_tokens_used > 0 && (
                  <View style={styles.usageItem}>
                    <Text style={styles.usageCount}>
                      {(monthlyUsage.coaching_tokens_used / 1000000).toFixed(1)}M
                    </Text>
                    <Text style={styles.usageLabel}>Koçluk Token</Text>
                  </View>
                )}
              </View>
              {Object.values(monthlyUsage).every(v => v === 0) && (
                <Text style={styles.noUsageText}>Bu ay henüz kullanım yapmadınız</Text>
              )}
            </View>
          </View>
        )}

        {/* Credit Details by Subscription */}
        {subscriptions.filter(sub => sub.status === 'active').length > 0 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Paket Detayları</Text>
            {subscriptions
              .filter(sub => sub.status === 'active')
              .sort((a, b) => new Date(a.end_date).getTime() - new Date(b.end_date).getTime())
              .map((sub, index) => (
                <View key={sub.id || index} style={styles.subscriptionDetailCard}>
                  <View style={styles.subscriptionDetailHeader}>
                    <Text style={styles.subscriptionDetailName}>{getPlanName(sub.plan_id)}</Text>
                    {index === 0 && (
                      <View style={styles.primaryBadge}>
                        <Text style={styles.primaryBadgeText}>İlk Kullanılacak</Text>
                      </View>
                    )}
                  </View>
                  <Text style={styles.expiryDate}>Bitiş: {formatDate(sub.end_date)}</Text>
                  
                  <View style={styles.creditsList}>
                    {sub.self_analysis_limit !== undefined && sub.self_analysis_limit > 0 && (
                      <View style={styles.creditsRow}>
                        <Text style={styles.creditsLabel}>Kendi Analizi:</Text>
                        <Text style={styles.creditsDetailValue}>
                          {sub.credits_remaining.self_analysis || 0}/{sub.self_analysis_limit}
                        </Text>
                      </View>
                    )}
                    {sub.self_reanalysis_limit !== undefined && sub.self_reanalysis_limit > 0 && (
                      <View style={styles.creditsRow}>
                        <Text style={styles.creditsLabel}>Analiz Güncelleme:</Text>
                        <Text style={styles.creditsDetailValue}>
                          {sub.credits_remaining.self_reanalysis || 0}/{sub.self_reanalysis_limit}
                        </Text>
                      </View>
                    )}
                    {sub.other_analysis_limit !== undefined && sub.other_analysis_limit > 0 && (
                      <View style={styles.creditsRow}>
                        <Text style={styles.creditsLabel}>Kişi Analizi:</Text>
                        <Text style={styles.creditsDetailValue}>
                          {sub.credits_remaining.other_analysis || 0}/{sub.other_analysis_limit}
                        </Text>
                      </View>
                    )}
                    {sub.relationship_analysis_limit !== undefined && sub.relationship_analysis_limit > 0 && (
                      <View style={styles.creditsRow}>
                        <Text style={styles.creditsLabel}>İlişki Analizi:</Text>
                        <Text style={styles.creditsDetailValue}>
                          {sub.credits_remaining.relationship_analysis || 0}/{sub.relationship_analysis_limit}
                        </Text>
                      </View>
                    )}
                    {sub.coaching_tokens_limit !== undefined && sub.coaching_tokens_limit > 0 && (
                      <View style={styles.creditsRow}>
                        <Text style={styles.creditsLabel}>Koçluk Token:</Text>
                        <Text style={styles.creditsDetailValue}>
                          {((sub.credits_remaining.coaching_tokens || 0) / 1000000).toFixed(1)}M/{(sub.coaching_tokens_limit / 1000000).toFixed(1)}M
                        </Text>
                      </View>
                    )}
                  </View>
                </View>
              ))}
          </View>
        )}

        {/* Info Box */}
        <View style={styles.infoBox}>
          <Text style={styles.infoIcon}>ℹ️</Text>
          <Text style={styles.infoText}>
            Birden fazla aboneliğiniz varsa, krediler bitiş tarihi en yakın olan paketten kullanılır. Bu sayede kredilerinizi en verimli şekilde kullanmış olursunuz.
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'rgb(244, 244, 244)',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingVertical: 15,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  backButton: {
    padding: 5,
  },
  backArrow: {
    fontSize: 24,
    color: '#000',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#000',
  },
  headerSpacer: {
    width: 34,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  content: {
    flex: 1,
    padding: 20,
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#000',
    marginBottom: 12,
  },
  totalCreditsCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    padding: 16,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  creditItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
  },
  creditIconContainer: {
    width: 40,
    height: 40,
    borderRadius: 3,
    backgroundColor: 'rgba(66, 153, 225, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  creditIcon: {
    fontSize: 20,
  },
  creditInfo: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  creditLabel: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 4,
  },
  creditValueContainer: {
    flexDirection: 'row',
    alignItems: 'baseline',
    marginBottom: 8,
  },
  creditValue: {
    fontSize: 24,
    fontWeight: '700',
    color: 'rgb(66, 153, 225)',
  },
  creditDivider: {
    fontSize: 18,
    color: '#9CA3AF',
    marginHorizontal: 4,
  },
  creditTotal: {
    fontSize: 18,
    fontWeight: '600',
    color: '#6B7280',
  },
  progressBar: {
    height: 6,
    backgroundColor: '#E5E7EB',
    borderRadius: 3,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: 'rgb(66, 153, 225)',
    borderRadius: 3,
  },
  noCreditsBox: {
    alignItems: 'center',
    paddingVertical: 24,
  },
  noCreditsText: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 16,
  },
  subscribeButton: {
    backgroundColor: 'rgb(66, 153, 225)',
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 3,
  },
  subscribeButtonText: {
    color: '#FFFFFF',
    fontWeight: '600',
    fontSize: 14,
  },
  usageCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    padding: 16,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  usageGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginHorizontal: -8,
  },
  usageItem: {
    width: '50%',
    paddingHorizontal: 8,
    marginBottom: 16,
    alignItems: 'center',
  },
  usageCount: {
    fontSize: 24,
    fontWeight: '700',
    color: '#000',
    marginBottom: 4,
  },
  usageLabel: {
    fontSize: 12,
    color: '#6B7280',
  },
  noUsageText: {
    fontSize: 13,
    color: '#9CA3AF',
    fontStyle: 'italic',
    textAlign: 'center',
  },
  subscriptionDetailCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  subscriptionDetailHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  subscriptionDetailName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#000',
  },
  primaryBadge: {
    backgroundColor: 'rgba(66, 153, 225, 0.1)',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 3,
  },
  primaryBadgeText: {
    fontSize: 10,
    fontWeight: '600',
    color: 'rgb(66, 153, 225)',
  },
  expiryDate: {
    fontSize: 12,
    color: '#6B7280',
    marginBottom: 12,
  },
  creditsList: {
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
    paddingTop: 12,
  },
  creditsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 6,
  },
  creditsLabel: {
    fontSize: 13,
    color: '#6B7280',
  },
  creditsValue: {
    fontSize: 13,
    fontWeight: '600',
    color: 'rgb(66, 153, 225)',
  },
  creditsDetailValue: {
    fontSize: 13,
    fontWeight: '600',
    color: 'rgb(66, 153, 225)',
  },
  infoBox: {
    flexDirection: 'row',
    backgroundColor: '#EFF6FF',
    padding: 16,
    borderRadius: 3,
    marginBottom: 20,
  },
  infoIcon: {
    fontSize: 16,
    marginRight: 8,
  },
  infoText: {
    flex: 1,
    fontSize: 14,
    color: '#1E40AF',
    lineHeight: 20,
  },
});