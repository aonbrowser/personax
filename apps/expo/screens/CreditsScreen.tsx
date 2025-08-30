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
  total_analysis_credits: number;
  credits_used: number;
  coaching_tokens_limit: number;
  coaching_tokens_used?: number;
}

interface MonthlyUsage {
  self_analysis_count?: number;
  self_reanalysis_count?: number;
  other_analysis_count?: number;
  relationship_analysis_count?: number;
  coaching_tokens_used?: number;
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
      case 'free':
        return 'Ücretsiz Paket';
      case 'standard':
        return 'Standart Paket';
      case 'extra':
        return 'Extra Paket';
      default:
        return planId;
    }
  };

  const getTotalCredits = () => {
    const totals = {
      analysis: { remaining: 0, total: 0, used: 0 },
      coaching_tokens: { remaining: 0, total: 0, used: 0 },
    };

    // Calculate totals from all non-expired subscriptions (active + cancelled)
    subscriptions
      .filter(sub => {
        // Include active and cancelled subscriptions that haven't expired yet
        const endDate = new Date(sub.end_date);
        const now = new Date();
        return (sub.status === 'active' || sub.status === 'cancelled') && endDate > now;
      })
      .forEach(sub => {
        // Calculate remaining analysis credits from credits_remaining
        const creditsRemaining = sub.credits_remaining || {};
        const analysisRemaining = (creditsRemaining.self_analysis || 0) + 
          (creditsRemaining.self_reanalysis || 0) + 
          (creditsRemaining.other_analysis || 0) + 
          (creditsRemaining.relationship_analysis || 0);
        
        // Only collect totals from subscription plans (ignore corrupt remaining data)
        totals.analysis.total += sub.total_analysis_credits || 0;
        totals.coaching_tokens.total += sub.coaching_tokens_limit || 0;
      });

    // Calculate used from monthly usage (real usage data)
    if (monthlyUsage) {
      totals.analysis.used = (monthlyUsage.self_analysis_count || 0) + 
        (monthlyUsage.self_reanalysis_count || 0) + 
        (monthlyUsage.other_analysis_count || 0) + 
        (monthlyUsage.relationship_analysis_count || 0);
      
      totals.coaching_tokens.used = monthlyUsage.coaching_tokens_used || 0;
    }

    // Calculate remaining = total - used (mathematically correct)
    totals.analysis.remaining = Math.max(0, totals.analysis.total - totals.analysis.used);
    totals.coaching_tokens.remaining = Math.max(0, totals.coaching_tokens.total - totals.coaching_tokens.used);

    console.log('DEBUG - Credit totals:', {
      analysis: totals.analysis,
      coaching_tokens: totals.coaching_tokens,
      monthlyUsage: monthlyUsage
    });

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
  const hasActiveSubscription = subscriptions.some(sub => {
    const endDate = new Date(sub.end_date);
    const now = new Date();
    return (sub.status === 'active' || sub.status === 'cancelled') && endDate > now;
  });

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
          <Text style={styles.sectionTitle}>Kredi Durumu</Text>
          
          {hasActiveSubscription ? (
            <>
              {/* Analysis Credits Table */}
              <View style={styles.creditTable}>
                <Text style={styles.creditTableTitle}>📊 Analiz Kredisi</Text>
                <View style={styles.creditTableHeader}>
                  <Text style={styles.creditTableHeaderCell}>Toplam</Text>
                  <Text style={styles.creditTableHeaderCell}>Harcanan</Text>
                  <Text style={styles.creditTableHeaderCell}>Kalan</Text>
                </View>
                <View style={styles.creditTableRow}>
                  <Text style={styles.creditTableCell}>{totalCredits.analysis.total}</Text>
                  <Text style={styles.creditTableCell}>{totalCredits.analysis.used}</Text>
                  <Text style={[styles.creditTableCell, styles.creditTableCellRemaining]}>{totalCredits.analysis.remaining}</Text>
                </View>
              </View>

              {/* Coaching Tokens Table */}
              <View style={styles.creditTable}>
                <Text style={styles.creditTableTitle}>🎯 Koçluk Token</Text>
                <View style={styles.creditTableHeader}>
                  <Text style={styles.creditTableHeaderCell}>Toplam</Text>
                  <Text style={styles.creditTableHeaderCell}>Harcanan</Text>
                  <Text style={styles.creditTableHeaderCell}>Kalan</Text>
                </View>
                <View style={styles.creditTableRow}>
                  <Text style={styles.creditTableCell}>{totalCredits.coaching_tokens.total.toLocaleString()}</Text>
                  <Text style={styles.creditTableCell}>{totalCredits.coaching_tokens.used.toLocaleString()}</Text>
                  <Text style={[styles.creditTableCell, styles.creditTableCellRemaining]}>{totalCredits.coaching_tokens.remaining.toLocaleString()}</Text>
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

        {/* Monthly Usage */}
        {monthlyUsage && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Bu Ay Kullanım</Text>
            <View style={styles.usageCard}>
              <View style={styles.usageGrid}>
                {(() => {
                  const totalAnalysisUsage = (monthlyUsage.self_analysis_count || 0) + 
                    (monthlyUsage.self_reanalysis_count || 0) + 
                    (monthlyUsage.other_analysis_count || 0) + 
                    (monthlyUsage.relationship_analysis_count || 0);
                  
                  return (
                    <>
                      {totalAnalysisUsage > 0 && (
                        <View style={styles.usageItem}>
                          <Text style={styles.usageCount}>{totalAnalysisUsage}</Text>
                          <Text style={styles.usageLabel}>Analiz Kredisi</Text>
                        </View>
                      )}
                      {(monthlyUsage.coaching_tokens_used || 0) > 0 && (
                        <View style={styles.usageItem}>
                          <Text style={styles.usageCount}>
                            {monthlyUsage.coaching_tokens_used}
                          </Text>
                          <Text style={styles.usageLabel}>Koçluk Token</Text>
                        </View>
                      )}
                    </>
                  );
                })()}
              </View>
              {(() => {
                const totalAnalysisUsage = (monthlyUsage.self_analysis_count || 0) + 
                  (monthlyUsage.self_reanalysis_count || 0) + 
                  (monthlyUsage.other_analysis_count || 0) + 
                  (monthlyUsage.relationship_analysis_count || 0);
                
                return (totalAnalysisUsage === 0 && (monthlyUsage.coaching_tokens_used || 0) === 0) && (
                  <Text style={styles.noUsageText}>Bu ay henüz kullanım yapmadınız</Text>
                );
              })()}
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
                    {sub.total_analysis_credits !== undefined && sub.total_analysis_credits > 0 && (
                      <View style={styles.creditsRow}>
                        <Text style={styles.creditsLabel}>Analiz Kredisi:</Text>
                        <Text style={styles.creditsDetailValue}>
                          {(sub.total_analysis_credits || 0) - (sub.credits_used || 0)}/{sub.total_analysis_credits}
                        </Text>
                      </View>
                    )}
                    {sub.coaching_tokens_limit !== undefined && sub.coaching_tokens_limit > 0 && (
                      <View style={styles.creditsRow}>
                        <Text style={styles.creditsLabel}>Koçluk Token:</Text>
                        <Text style={styles.creditsDetailValue}>
                          {(sub.coaching_tokens_limit || 0) - (sub.coaching_tokens_used || 0)}/{sub.coaching_tokens_limit}
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
  creditTable: {
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    overflow: 'hidden',
  },
  creditTableTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#000',
    padding: 12,
    backgroundColor: 'rgb(45, 55, 72)',
    color: '#FFFFFF',
  },
  creditTableHeader: {
    flexDirection: 'row',
    backgroundColor: 'rgb(244, 244, 244)',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  creditTableHeaderCell: {
    flex: 1,
    padding: 12,
    fontSize: 12,
    fontWeight: '600',
    color: '#6B7280',
    textAlign: 'center',
    textTransform: 'uppercase',
  },
  creditTableRow: {
    flexDirection: 'row',
    backgroundColor: '#FFFFFF',
  },
  creditTableCell: {
    flex: 1,
    padding: 12,
    fontSize: 14,
    color: '#000',
    textAlign: 'center',
    fontWeight: '500',
  },
  creditTableCellRemaining: {
    color: 'rgb(66, 153, 225)',
    fontWeight: '700',
  },
});