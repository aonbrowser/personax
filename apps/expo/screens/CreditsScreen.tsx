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
      self_analysis: 0,
      self_reanalysis: 0,
      other_analysis: 0,
      relationship_analysis: 0,
      coaching_tokens: 0,
    };

    subscriptions
      .filter(sub => sub.status === 'active')
      .forEach(sub => {
        if (sub.credits_remaining) {
          totals.self_analysis += sub.credits_remaining.self_analysis || 0;
          totals.self_reanalysis += sub.credits_remaining.self_reanalysis || 0;
          totals.other_analysis += sub.credits_remaining.other_analysis || 0;
          totals.relationship_analysis += sub.credits_remaining.relationship_analysis || 0;
          totals.coaching_tokens += sub.credits_remaining.coaching_tokens || 0;
        }
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
                    <Text style={styles.creditValue}>{totalCredits.self_analysis}</Text>
                  </View>
                </View>

                <View style={styles.creditItem}>
                  <View style={styles.creditIconContainer}>
                    <Text style={styles.creditIcon}>🔄</Text>
                  </View>
                  <View style={styles.creditInfo}>
                    <Text style={styles.creditLabel}>Analiz Güncelleme</Text>
                    <Text style={styles.creditValue}>{totalCredits.self_reanalysis}</Text>
                  </View>
                </View>

                <View style={styles.creditItem}>
                  <View style={styles.creditIconContainer}>
                    <Text style={styles.creditIcon}>👥</Text>
                  </View>
                  <View style={styles.creditInfo}>
                    <Text style={styles.creditLabel}>Kişi Analizi</Text>
                    <Text style={styles.creditValue}>{totalCredits.other_analysis}</Text>
                  </View>
                </View>

                <View style={styles.creditItem}>
                  <View style={styles.creditIconContainer}>
                    <Text style={styles.creditIcon}>💑</Text>
                  </View>
                  <View style={styles.creditInfo}>
                    <Text style={styles.creditLabel}>İlişki Analizi</Text>
                    <Text style={styles.creditValue}>{totalCredits.relationship_analysis}</Text>
                  </View>
                </View>

                <View style={styles.creditItem}>
                  <View style={styles.creditIconContainer}>
                    <Text style={styles.creditIcon}>🎯</Text>
                  </View>
                  <View style={styles.creditInfo}>
                    <Text style={styles.creditLabel}>Koçluk Token</Text>
                    <Text style={styles.creditValue}>
                      {(totalCredits.coaching_tokens / 1000000).toFixed(1)}M
                    </Text>
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
                    {sub.credits_remaining.self_analysis !== undefined && (
                      <View style={styles.creditsRow}>
                        <Text style={styles.creditsLabel}>Kendi Analizi:</Text>
                        <Text style={styles.creditsValue}>{sub.credits_remaining.self_analysis}</Text>
                      </View>
                    )}
                    {sub.credits_remaining.self_reanalysis !== undefined && (
                      <View style={styles.creditsRow}>
                        <Text style={styles.creditsLabel}>Analiz Güncelleme:</Text>
                        <Text style={styles.creditsValue}>{sub.credits_remaining.self_reanalysis}</Text>
                      </View>
                    )}
                    {sub.credits_remaining.other_analysis !== undefined && (
                      <View style={styles.creditsRow}>
                        <Text style={styles.creditsLabel}>Kişi Analizi:</Text>
                        <Text style={styles.creditsValue}>{sub.credits_remaining.other_analysis}</Text>
                      </View>
                    )}
                    {sub.credits_remaining.relationship_analysis !== undefined && (
                      <View style={styles.creditsRow}>
                        <Text style={styles.creditsLabel}>İlişki Analizi:</Text>
                        <Text style={styles.creditsValue}>{sub.credits_remaining.relationship_analysis}</Text>
                      </View>
                    )}
                    {sub.credits_remaining.coaching_tokens !== undefined && (
                      <View style={styles.creditsRow}>
                        <Text style={styles.creditsLabel}>Koçluk Token:</Text>
                        <Text style={styles.creditsValue}>
                          {(sub.credits_remaining.coaching_tokens / 1000000).toFixed(1)}M
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
  },
  creditValue: {
    fontSize: 20,
    fontWeight: '700',
    color: 'rgb(66, 153, 225)',
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