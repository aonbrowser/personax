import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  SafeAreaView,
  TouchableOpacity,
  ActivityIndicator,
  Platform,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { API_URL } from '../config';

interface AccountInfoScreenProps {
  navigation: any;
  userEmail: string;
}

interface Subscription {
  id: string;
  plan_id: string;
  status: string;
  start_date: string;
  end_date: string;
  credits_remaining: {
    self_analysis?: number;
    self_reanalysis?: number;
    other_analysis?: number;
    relationship_analysis?: number;
    coaching_tokens?: number;
  };
  is_primary: boolean;
}

export default function AccountInfoScreen({ navigation, userEmail }: AccountInfoScreenProps) {
  const [loading, setLoading] = useState(true);
  const [subscriptions, setSubscriptions] = useState<Subscription[]>([]);
  const [monthlyUsage, setMonthlyUsage] = useState<any>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadAccountInfo();
  }, []);

  const loadAccountInfo = async () => {
    try {
      setLoading(true);
      setError(null);

      // Get user's subscription and credit info
      const response = await fetch(
        `${API_URL}/v1/payment/check-limits?service_type=self_analysis`,
        {
          headers: {
            'x-user-email': userEmail,
          },
        }
      );

      if (!response.ok) {
        throw new Error('Hesap bilgileri yüklenemedi');
      }

      const data = await response.json();
      setSubscriptions(data.subscriptions || []);
      setMonthlyUsage(data.monthlyUsage || {});
    } catch (error) {
      console.error('Error loading account info:', error);
      setError('Hesap bilgileri yüklenirken hata oluştu');
    } finally {
      setLoading(false);
    }
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
        return 'Extra Paket';
      default:
        return planId;
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'cancelled':
        return 'İptal Edildi';
      case 'expired':
        return 'Süresi Doldu';
      default:
        return status;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return '#10B981';
      case 'cancelled':
        return '#F59E0B';
      case 'expired':
        return '#EF4444';
      default:
        return '#6B7280';
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity 
          style={styles.backButton}
          onPress={() => navigation.goBack()}
        >
          <Ionicons name="arrow-back" size={24} color="#000" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Hesap Bilgilerim</Text>
        <View style={styles.headerSpacer} />
      </View>

      {loading ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="rgb(66, 153, 225)" />
          <Text style={styles.loadingText}>Yükleniyor...</Text>
        </View>
      ) : error ? (
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>{error}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={loadAccountInfo}>
            <Text style={styles.retryButtonText}>Tekrar Dene</Text>
          </TouchableOpacity>
        </View>
      ) : (
        <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
          {/* Email Section */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Hesap</Text>
            <View style={styles.infoBox}>
              <Text style={styles.label}>E-posta Adresi</Text>
              <Text style={styles.value}>{userEmail}</Text>
            </View>
          </View>

          {/* Quick Actions */}
          <View style={styles.section}>
            <TouchableOpacity 
              style={styles.menuItem}
              onPress={() => navigation.navigate('Subscription', { userEmail })}
            >
              <Text style={styles.menuItemIcon}>💎</Text>
              <Text style={styles.menuItemText}>Aboneliğim</Text>
              <Text style={styles.menuItemArrow}>›</Text>
            </TouchableOpacity>
            
            <TouchableOpacity 
              style={styles.menuItem}
              onPress={() => navigation.navigate('Credits', { userEmail })}
            >
              <Text style={styles.menuItemIcon}>🎯</Text>
              <Text style={styles.menuItemText}>Kredilerim</Text>
              <Text style={styles.menuItemArrow}>›</Text>
            </TouchableOpacity>
          </View>

          {/* Subscriptions Section */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Aboneliklerim</Text>
            {subscriptions.length > 0 ? (
              subscriptions.map((sub, index) => (
                <View key={sub.id || index} style={styles.subscriptionCard}>
                  <View style={styles.subscriptionHeader}>
                    <Text style={styles.subscriptionName}>
                      {getPlanName(sub.plan_id)}
                      {sub.is_primary && (
                        <Text style={styles.primaryBadge}> (Ana)</Text>
                      )}
                    </Text>
                    <View style={[styles.statusBadge, { backgroundColor: getStatusColor(sub.status) }]}>
                      <Text style={styles.statusText}>{getStatusText(sub.status)}</Text>
                    </View>
                  </View>
                  
                  <View style={styles.subscriptionDates}>
                    <Text style={styles.dateText}>
                      {formatDate(sub.start_date)} - {formatDate(sub.end_date)}
                    </Text>
                  </View>

                  <View style={styles.creditsContainer}>
                    <Text style={styles.creditsTitle}>Kalan Krediler:</Text>
                    
                    {sub.credits_remaining.self_analysis !== undefined && (
                      <View style={styles.creditRow}>
                        <Text style={styles.creditLabel}>Kendi Analizi:</Text>
                        <Text style={styles.creditValue}>{sub.credits_remaining.self_analysis}</Text>
                      </View>
                    )}
                    
                    {sub.credits_remaining.self_reanalysis !== undefined && (
                      <View style={styles.creditRow}>
                        <Text style={styles.creditLabel}>Kendi Analizi Güncelleme:</Text>
                        <Text style={styles.creditValue}>{sub.credits_remaining.self_reanalysis}</Text>
                      </View>
                    )}
                    
                    {sub.credits_remaining.other_analysis !== undefined && (
                      <View style={styles.creditRow}>
                        <Text style={styles.creditLabel}>Kişi Analizi:</Text>
                        <Text style={styles.creditValue}>{sub.credits_remaining.other_analysis}</Text>
                      </View>
                    )}
                    
                    {sub.credits_remaining.relationship_analysis !== undefined && (
                      <View style={styles.creditRow}>
                        <Text style={styles.creditLabel}>İlişki Analizi:</Text>
                        <Text style={styles.creditValue}>{sub.credits_remaining.relationship_analysis}</Text>
                      </View>
                    )}
                    
                    {sub.credits_remaining.coaching_tokens !== undefined && (
                      <View style={styles.creditRow}>
                        <Text style={styles.creditLabel}>Koçluk Token:</Text>
                        <Text style={styles.creditValue}>
                          {(sub.credits_remaining.coaching_tokens / 1000000).toFixed(0)}M
                        </Text>
                      </View>
                    )}
                  </View>
                </View>
              ))
            ) : (
              <View style={styles.noSubscriptionBox}>
                <Text style={styles.noSubscriptionText}>Aktif aboneliğiniz bulunmamaktadır</Text>
              </View>
            )}
          </View>

          {/* Monthly Usage Section */}
          {monthlyUsage && (
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>Bu Ay Kullanım</Text>
              <View style={styles.usageBox}>
                {monthlyUsage.self_analysis_count > 0 && (
                  <View style={styles.usageRow}>
                    <Text style={styles.usageLabel}>Kendi Analizi:</Text>
                    <Text style={styles.usageValue}>{monthlyUsage.self_analysis_count}</Text>
                  </View>
                )}
                {monthlyUsage.self_reanalysis_count > 0 && (
                  <View style={styles.usageRow}>
                    <Text style={styles.usageLabel}>Güncelleme:</Text>
                    <Text style={styles.usageValue}>{monthlyUsage.self_reanalysis_count}</Text>
                  </View>
                )}
                {monthlyUsage.other_analysis_count > 0 && (
                  <View style={styles.usageRow}>
                    <Text style={styles.usageLabel}>Kişi Analizi:</Text>
                    <Text style={styles.usageValue}>{monthlyUsage.other_analysis_count}</Text>
                  </View>
                )}
                {monthlyUsage.relationship_analysis_count > 0 && (
                  <View style={styles.usageRow}>
                    <Text style={styles.usageLabel}>İlişki Analizi:</Text>
                    <Text style={styles.usageValue}>{monthlyUsage.relationship_analysis_count}</Text>
                  </View>
                )}
                {monthlyUsage.coaching_tokens_used > 0 && (
                  <View style={styles.usageRow}>
                    <Text style={styles.usageLabel}>Koçluk Token:</Text>
                    <Text style={styles.usageValue}>
                      {(monthlyUsage.coaching_tokens_used / 1000000).toFixed(1)}M
                    </Text>
                  </View>
                )}
                {Object.values(monthlyUsage).every(v => v === 0) && (
                  <Text style={styles.noUsageText}>Bu ay henüz kullanım yapmadınız</Text>
                )}
              </View>
            </View>
          )}
        </ScrollView>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F9FAFB',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  backButton: {
    padding: 8,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#000',
  },
  headerSpacer: {
    width: 40,
  },
  content: {
    flex: 1,
    padding: 16,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 16,
    fontSize: 14,
    color: '#6B7280',
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 32,
  },
  errorText: {
    fontSize: 14,
    color: '#EF4444',
    textAlign: 'center',
    marginBottom: 16,
  },
  retryButton: {
    backgroundColor: 'rgb(66, 153, 225)',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 3,
  },
  retryButtonText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: 'rgb(45, 55, 72)',
    marginBottom: 12,
  },
  infoBox: {
    backgroundColor: '#FFFFFF',
    padding: 16,
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  label: {
    fontSize: 12,
    color: '#6B7280',
    marginBottom: 4,
  },
  value: {
    fontSize: 14,
    color: '#000',
    fontWeight: '500',
  },
  subscriptionCard: {
    backgroundColor: '#FFFFFF',
    padding: 16,
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    marginBottom: 12,
  },
  subscriptionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  subscriptionName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#000',
  },
  primaryBadge: {
    fontSize: 12,
    color: 'rgb(66, 153, 225)',
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    padding: 16,
    marginBottom: 12,
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  menuItemIcon: {
    fontSize: 20,
    marginRight: 12,
  },
  menuItemText: {
    flex: 1,
    fontSize: 16,
    fontWeight: '500',
    color: '#000',
  },
  menuItemArrow: {
    fontSize: 20,
    color: '#9CA3AF',
  },
  statusBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 3,
  },
  statusText: {
    fontSize: 12,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  subscriptionDates: {
    marginBottom: 12,
  },
  dateText: {
    fontSize: 12,
    color: '#6B7280',
  },
  creditsContainer: {
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
    paddingTop: 12,
  },
  creditsTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: 'rgb(45, 55, 72)',
    marginBottom: 8,
  },
  creditRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 6,
  },
  creditLabel: {
    fontSize: 13,
    color: '#6B7280',
  },
  creditValue: {
    fontSize: 13,
    fontWeight: '600',
    color: 'rgb(66, 153, 225)',
  },
  noSubscriptionBox: {
    backgroundColor: '#F3F4F6',
    padding: 24,
    borderRadius: 3,
    alignItems: 'center',
  },
  noSubscriptionText: {
    fontSize: 14,
    color: '#6B7280',
  },
  usageBox: {
    backgroundColor: '#FFFFFF',
    padding: 16,
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  usageRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  usageLabel: {
    fontSize: 13,
    color: '#6B7280',
  },
  usageValue: {
    fontSize: 13,
    fontWeight: '600',
    color: '#000',
  },
  noUsageText: {
    fontSize: 13,
    color: '#9CA3AF',
    fontStyle: 'italic',
    textAlign: 'center',
  },
});