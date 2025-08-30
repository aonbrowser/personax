import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { API_URL } from '../config';

interface SubscriptionScreenProps {
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

interface PlanOption {
  id: string;
  name: string;
  price: number;
  credits: number;
  features: string[];
  stripe_price_id?: string;
  status?: string;
}


export default function SubscriptionScreen({ navigation, route }: SubscriptionScreenProps) {
  const { userEmail } = route.params;
  const [subscriptions, setSubscriptions] = useState<Subscription[]>([]);
  const [availablePlans, setAvailablePlans] = useState<PlanOption[]>([]);
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState(false);

  useEffect(() => {
    Promise.all([loadSubscriptions(), loadAvailablePlans()]);
  }, []);

  const loadSubscriptions = async () => {
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
      }
    } catch (error) {
      console.error('Error loading subscriptions:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadAvailablePlans = async () => {
    try {
      const response = await fetch(`${API_URL}/v1/subscription-plans`);
      if (response.ok) {
        const data = await response.json();
        setAvailablePlans(data.plans || []);
      }
    } catch (error) {
      console.error('Error loading plans:', error);
    }
  };

  const handleCancelSubscription = (subscriptionId: string) => {
    console.log('Cancel subscription called with ID:', subscriptionId);
    
    // Web'de Alert çalışmıyorsa confirm kullan
    if (typeof window !== 'undefined') {
      const confirmed = window.confirm(
        'Bu aboneliği iptal etmek istediğinizden emin misiniz? İptal edildiğinde, mevcut döneminiz sonuna kadar kullanabilirsiniz.'
      );
      if (confirmed) {
        cancelSubscription(subscriptionId);
      }
    } else {
      Alert.alert(
        'Aboneliği İptal Et',
        'Bu aboneliği iptal etmek istediğinizden emin misiniz? İptal edildiğinde, mevcut döneminiz sonuna kadar kullanabilirsiniz.',
        [
          { text: 'Vazgeç', style: 'cancel' },
          {
            text: 'İptal Et',
            style: 'destructive',
            onPress: () => cancelSubscription(subscriptionId),
          },
        ]
      );
    }
  };

  const cancelSubscription = async (subscriptionId: string) => {
    setProcessing(true);
    try {
      const response = await fetch(`${API_URL}/v1/payment/subscriptions/${subscriptionId}/cancel`, {
        method: 'POST',
        headers: {
          'x-user-email': userEmail,
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        if (typeof window !== 'undefined') {
          window.alert('Aboneliğiniz iptal edildi. Mevcut dönem sonuna kadar tüm özelliklerden yararlanmaya devam edebilirsiniz.');
        } else {
          Alert.alert(
            'Başarılı', 
            'Aboneliğiniz iptal edildi. Mevcut dönem sonuna kadar tüm özelliklerden yararlanmaya devam edebilirsiniz.'
          );
        }
        await loadSubscriptions();
      } else {
        const errorData = await response.json();
        if (typeof window !== 'undefined') {
          window.alert(errorData.error || 'Abonelik iptal edilemedi.');
        } else {
          Alert.alert('Hata', errorData.error || 'Abonelik iptal edilemedi.');
        }
      }
    } catch (error) {
      console.error('Error canceling subscription:', error);
      if (typeof window !== 'undefined') {
        window.alert('Bir hata oluştu.');
      } else {
        Alert.alert('Hata', 'Bir hata oluştu.');
      }
    } finally {
      setProcessing(false);
    }
  };

  const handleSubscribeToPlan = (planId: string) => {
    // Check if user already has this plan
    const hasActivePlan = subscriptions.some(
      sub => sub.plan_id === planId && sub.status === 'active'
    );

    if (hasActivePlan) {
      Alert.alert('Bilgi', 'Bu pakete zaten sahipsiniz.');
      return;
    }

    // Navigate to payment screen
    navigation.navigate('PaymentCheck', {
      serviceType: 'subscription',
      planId: planId,
      userEmail: userEmail,
    });
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
    const plan = availablePlans.find(p => p.id === planId);
    return plan?.name || planId;
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return '#10B981';
      case 'expired': return '#EF4444';
      case 'cancelled': return '#F59E0B';
      default: return '#6B7280';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'active': return 'Aktif';
      case 'expired': return 'Süresi Dolmuş';
      case 'cancelled': return 'İptal Edildi';
      default: return status;
    }
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backButton}>
            <Text style={styles.backArrow}>←</Text>
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Aboneliklerim</Text>
          <View style={styles.headerSpacer} />
        </View>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="rgb(66, 153, 225)" />
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backButton}>
          <Text style={styles.backArrow}>←</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Aboneliklerim</Text>
        <View style={styles.headerSpacer} />
      </View>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Active Subscriptions */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Aktif Aboneliklerim</Text>
          {subscriptions.filter(sub => sub.status === 'active' || sub.status === 'cancelled').length > 0 ? (
            subscriptions
              .filter(sub => sub.status === 'active' || sub.status === 'cancelled')
              .map((sub, index) => (
                <View key={sub.id || index} style={styles.subscriptionCard}>
                  <View style={styles.subscriptionHeader}>
                    <Text style={styles.subscriptionName}>
                      {getPlanName(sub.plan_id)}
                      {sub.is_primary && (
                        <Text style={styles.primaryBadge}> (Birincil)</Text>
                      )}
                    </Text>
                    <View style={[styles.statusBadge, { backgroundColor: getStatusColor(sub.status) }]}>
                      <Text style={styles.statusText}>{getStatusText(sub.status)}</Text>
                    </View>
                  </View>

                  <View style={styles.subscriptionDates}>
                    <Text style={styles.dateText}>
                      Başlangıç: {formatDate(sub.start_date)}
                    </Text>
                    <Text style={styles.dateText}>
                      Bitiş: {formatDate(sub.end_date)}
                    </Text>
                  </View>

                  {sub.status === 'active' ? (
                    <TouchableOpacity
                      style={styles.cancelButton}
                      onPress={() => handleCancelSubscription(sub.id)}
                      disabled={processing}
                    >
                      <Text style={styles.cancelButtonText}>Aboneliği İptal Et</Text>
                    </TouchableOpacity>
                  ) : (
                    <View style={styles.cancelledInfo}>
                      <Text style={styles.cancelledInfoText}>
                        Bu abonelik iptal edildi. {formatDate(sub.end_date)} tarihine kadar kullanabilirsiniz.
                      </Text>
                    </View>
                  )}
                </View>
              ))
          ) : (
            <View style={styles.noSubscriptionBox}>
              <Text style={styles.noSubscriptionText}>Aktif aboneliğiniz bulunmamaktadır</Text>
            </View>
          )}
        </View>

        {/* Available Plans */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Kullanılabilir Paketler</Text>
          {availablePlans.length > 0 ? (
            availablePlans.map(plan => {
            const hasActivePlan = subscriptions.some(
              sub => sub.plan_id === plan.id && sub.status === 'active'
            );

            return (
              <View key={plan.id} style={styles.planCard}>
                <View style={styles.planHeader}>
                  <Text style={styles.planName}>{plan.name}</Text>
                  <Text style={styles.planPrice}>
                    {plan.price === 0 ? 'Ücretsiz' : `$${plan.price}/ay`}
                  </Text>
                </View>

                <View style={styles.planFeatures}>
                  {(() => {
                    const features = [];
                    // Only use the features from API, don't duplicate
                    if (plan.features && Array.isArray(plan.features)) {
                      features.push(...plan.features);
                    } else if (plan.features && typeof plan.features === 'string') {
                      try {
                        const parsed = JSON.parse(plan.features);
                        features.push(...parsed);
                      } catch {}
                    }
                    return features.map((feature, index) => (
                      <View key={index} style={styles.featureRow}>
                        <Text style={styles.featureCheck}>✓</Text>
                        <Text style={styles.featureText}>{feature}</Text>
                      </View>
                    ));
                  })()}
                </View>

                <TouchableOpacity
                  style={[
                    styles.subscribeButton,
                    (hasActivePlan || plan.id === 'free') && styles.subscribeButtonDisabled,
                  ]}
                  onPress={() => handleSubscribeToPlan(plan.id)}
                  disabled={hasActivePlan || processing || plan.id === 'free'}
                >
                  <Text
                    style={[
                      styles.subscribeButtonText,
                      (hasActivePlan || plan.id === 'free') && styles.subscribeButtonTextDisabled,
                    ]}
                  >
                    {hasActivePlan ? 'Sahipsiniz' : plan.id === 'free' ? 'Ücretsiz' : 'Satın Al'}
                  </Text>
                </TouchableOpacity>
              </View>
            );
          })
          ) : (
            <View style={styles.noSubscriptionBox}>
              <Text style={styles.noSubscriptionText}>Yükleniyor...</Text>
            </View>
          )}
        </View>

        {/* Info Box */}
        <View style={styles.infoBox}>
          <Text style={styles.infoIcon}>ℹ️</Text>
          <Text style={styles.infoText}>
            Aynı anda birden fazla pakete sahip olabilirsiniz. Kullanılan krediler, bitiş tarihi en yakın olan paketten düşülür.
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
  subscriptionCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
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
  statusBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 3,
  },
  statusText: {
    fontSize: 12,
    fontWeight: '500',
    color: '#FFFFFF',
  },
  subscriptionDates: {
    marginBottom: 12,
  },
  dateText: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 4,
  },
  cancelButton: {
    backgroundColor: '#FEE2E2',
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderRadius: 3,
    alignItems: 'center',
  },
  cancelButtonText: {
    color: '#DC2626',
    fontWeight: '600',
    fontSize: 14,
  },
  cancelledInfo: {
    backgroundColor: '#FEF3C7',
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderRadius: 3,
  },
  cancelledInfoText: {
    color: '#92400E',
    fontSize: 13,
    lineHeight: 18,
  },
  noSubscriptionBox: {
    backgroundColor: '#F3F4F6',
    padding: 20,
    borderRadius: 3,
    alignItems: 'center',
  },
  noSubscriptionText: {
    fontSize: 14,
    color: '#6B7280',
  },
  planCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  planHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  planName: {
    fontSize: 18,
    fontWeight: '600',
    color: '#000',
  },
  planPrice: {
    fontSize: 20,
    fontWeight: '700',
    color: 'rgb(66, 153, 225)',
  },
  planFeatures: {
    marginBottom: 16,
  },
  featureRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  featureCheck: {
    fontSize: 16,
    color: '#10B981',
    marginRight: 8,
  },
  featureText: {
    fontSize: 14,
    color: '#4B5563',
  },
  subscribeButton: {
    backgroundColor: 'rgb(66, 153, 225)',
    paddingVertical: 12,
    borderRadius: 3,
    alignItems: 'center',
  },
  subscribeButtonDisabled: {
    backgroundColor: '#E5E7EB',
  },
  subscribeButtonText: {
    color: '#FFFFFF',
    fontWeight: '600',
    fontSize: 16,
  },
  subscribeButtonTextDisabled: {
    color: '#9CA3AF',
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