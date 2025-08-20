import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  StyleSheet,
  SafeAreaView,
  ActivityIndicator,
  Alert,
  Platform,
} from 'react-native';
import InAppPurchaseService from '../services/InAppPurchaseService';

const API_URL = 'http://localhost:8080';

interface PaymentCheckScreenProps {
  navigation: any;
  route: {
    params: {
      serviceType: 'self_analysis' | 'other_analysis' | 'relationship_analysis' | 'coaching';
      formData: any;
      onComplete: (result: any) => void;
    };
  };
}

export default function PaymentCheckScreen({ navigation, route }: PaymentCheckScreenProps) {
  const { serviceType, formData, onComplete } = route.params;
  const [loading, setLoading] = useState(true);
  const [hasCredit, setHasCredit] = useState(false);
  const [subscriptions, setSubscriptions] = useState<any[]>([]);
  const [pricingOptions, setPricingOptions] = useState<any>(null);
  const [selectedOption, setSelectedOption] = useState<string>('');
  const userEmail = 'test@test.com'; // Get from auth context in real app

  useEffect(() => {
    console.log('PaymentCheckScreen mounted - NAVIGATING IMMEDIATELY');
    
    // IMMEDIATELY navigate to MyAnalyses - DO NOT WAIT
    navigation.navigate('MyAnalyses');
    
    // Then do everything else in background
    setTimeout(() => {
      checkUserLimits();
      
      // Initialize In-App Purchases for mobile platforms
      if (Platform.OS !== 'web') {
        initializeIAP();
      }
    }, 200);
    
    return () => {
      // Cleanup IAP on unmount
      if (Platform.OS !== 'web') {
        InAppPurchaseService.cleanup();
      }
    };
  }, []);
  
  useEffect(() => {
    console.log('pricingOptions state updated:', pricingOptions);
  }, [pricingOptions]);

  const initializeIAP = async () => {
    try {
      await InAppPurchaseService.initConnection();
      console.log('IAP initialized successfully');
    } catch (error) {
      console.error('Failed to initialize IAP:', error);
    }
  };

  const checkUserLimits = async () => {
    setLoading(true);
    try {
      // Check user's limits
      const limitsResponse = await fetch(
        `${API_URL}/v1/payment/check-limits?service_type=${serviceType}`,
        {
          headers: {
            'x-user-email': userEmail,
          },
        }
      );
      const limitsData = await limitsResponse.json();

      setHasCredit(limitsData.hasCredit);
      setSubscriptions(limitsData.subscriptions || []);

      // If no credit, get pricing options
      if (!limitsData.hasCredit) {
        console.log('User has no credit, fetching pricing options...');
        const optionsResponse = await fetch(
          `${API_URL}/v1/payment/pricing-options?service_type=${serviceType}`,
          {
            headers: {
              'x-user-email': userEmail,
            },
          }
        );
        
        if (!optionsResponse.ok) {
          console.error('Failed to fetch pricing options:', optionsResponse.status);
          throw new Error('Failed to fetch pricing options');
        }
        
        const optionsData = await optionsResponse.json();
        console.log('Pricing options received:', optionsData); // Debug log
        console.log('Available plans:', optionsData?.availablePlans); // Debug log
        console.log('PAYG option:', optionsData?.paygOption); // Debug log
        
        // Verify data is correct before setting
        if (optionsData && optionsData.availablePlans) {
          console.log('Setting pricing options with', optionsData.availablePlans.length, 'plans');
          setPricingOptions(optionsData);
        } else {
          console.error('Invalid pricing options data:', optionsData);
          setPricingOptions(optionsData); // Still set it for debugging
        }
      } else {
        // Has credit, proceed with analysis
        console.log('User has credit, calling proceedWithAnalysis');
        setHasCredit(true);
        proceedWithAnalysis(limitsData.availableSubscription?.id);
      }
    } catch (error) {
      console.error('Error checking limits:', error);
      Alert.alert('Hata', 'Limit kontrolü sırasında hata oluştu');
    } finally {
      setLoading(false);
    }
  };

  const proceedWithAnalysis = (subscriptionId?: string) => {
    // Navigate IMMEDIATELY
    console.log('NAVIGATING TO MyAnalyses NOW!');
    navigation.navigate('MyAnalyses');
    console.log('Navigation called, should have navigated');
    
    // Then start the analysis in background
    setTimeout(() => {
      // Use credits if subscription exists
      if (subscriptionId) {
        fetch(`${API_URL}/v1/payment/use-credits`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-user-email': userEmail,
          },
          body: JSON.stringify({
            serviceType,
            subscriptionId,
          }),
        }).catch(error => console.error('Credit usage error:', error));
      }

      // Call the analysis API in background
      const analysisEndpoint = getAnalysisEndpoint();
      fetch(`${API_URL}/v1${analysisEndpoint}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-user-email': userEmail,
          'x-user-lang': 'tr',
          'x-user-id': userEmail,
        },
        body: JSON.stringify(formData),
      }).then(response => {
        if (response.ok && onComplete) {
          response.json().then(result => {
            onComplete(result);
          });
        }
      }).catch(error => {
        console.error('Analysis error:', error);
      });
    }, 100); // Small delay to ensure navigation happens first
  };

  const getAnalysisEndpoint = () => {
    switch (serviceType) {
      case 'self_analysis':
        return '/analyze/self';
      case 'other_analysis':
        return '/analyze/other';
      case 'relationship_analysis':
        return '/analyze/dyad';
      case 'coaching':
        return '/coach';
      default:
        return '/analyze/self';
    }
  };

  const handlePurchaseSubscription = async (planId: string) => {
    setLoading(true);
    try {
      if (Platform.OS === 'web') {
        // Web: Direct API call (can integrate with Stripe later)
        const response = await fetch(`${API_URL}/v1/payment/purchase-subscription`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-user-email': userEmail,
          },
          body: JSON.stringify({ planId }),
        });

        if (response.ok) {
          Alert.alert('Başarılı', 'Abonelik satın alındı', [
            {
              text: 'Tamam',
              onPress: () => checkUserLimits(), // Re-check limits
            },
          ]);
        } else {
          throw new Error('Purchase failed');
        }
      } else {
        // Mobile: Use In-App Purchase
        const productId = Platform.OS === 'ios' 
          ? `com.personax.${planId}.monthly`
          : `${planId}_monthly`;
        
        const purchase = await InAppPurchaseService.purchaseSubscription(productId);
        
        if (purchase) {
          Alert.alert('Başarılı', 'Abonelik satın alındı', [
            {
              text: 'Tamam',
              onPress: () => checkUserLimits(),
            },
          ]);
        }
      }
    } catch (error) {
      console.error('Error purchasing subscription:', error);
      Alert.alert('Hata', 'Satın alma işlemi başarısız oldu');
    } finally {
      setLoading(false);
    }
  };

  const handlePurchasePayg = async () => {
    setLoading(true);
    try {
      if (Platform.OS === 'web') {
        // Web: Direct API call
        const response = await fetch(`${API_URL}/v1/payment/purchase-payg`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-user-email': userEmail,
          },
          body: JSON.stringify({
            serviceType: pricingOptions?.paygOption?.service_type,
            quantity: 1,
          }),
        });

        if (response.ok) {
          Alert.alert('Başarılı', 'Tek seferlik ödeme alındı', [
            {
              text: 'Tamam',
              onPress: () => proceedWithAnalysis(), // Proceed without subscription
            },
          ]);
        } else {
          throw new Error('Purchase failed');
        }
      } else {
        // Mobile: Use In-App Purchase for one-time payment
        const serviceTypeMap: any = {
          'self_analysis': Platform.OS === 'ios' ? 'com.personax.self.analysis' : 'self_analysis',
          'other_analysis': Platform.OS === 'ios' ? 'com.personax.other.analysis' : 'other_analysis',
          'relationship_analysis': Platform.OS === 'ios' ? 'com.personax.relationship.analysis' : 'relationship_analysis'
        };
        
        const productId = serviceTypeMap[pricingOptions?.paygOption?.service_type];
        
        if (productId) {
          const purchase = await InAppPurchaseService.purchaseProduct(productId);
          
          if (purchase) {
            Alert.alert('Başarılı', 'Tek seferlik ödeme alındı', [
              {
                text: 'Tamam',
                onPress: () => proceedWithAnalysis(),
              },
            ]);
          }
        }
      }
    } catch (error) {
      console.error('Error purchasing PAYG:', error);
      Alert.alert('Hata', 'Satın alma işlemi başarısız oldu');
    } finally {
      setLoading(false);
    }
  };

  const getServiceName = () => {
    switch (serviceType) {
      case 'self_analysis':
        return 'Kendi Analizim';
      case 'other_analysis':
        return 'Başka Kişi Analizi';
      case 'relationship_analysis':
        return 'İlişki Analizi';
      case 'coaching':
        return 'Koçluk Hizmeti';
      default:
        return 'Analiz';
    }
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="rgb(66, 153, 225)" />
          <Text style={styles.loadingText}>Kontrol ediliyor...</Text>
        </View>
      </SafeAreaView>
    );
  }

  // Don't show separate processing screen, navigation happens automatically

  // Show pricing options
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backButton}>
          <Text style={styles.backArrow}>←</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Ödeme Seçenekleri</Text>
        <View style={styles.headerSpacer} />
      </View>

      <ScrollView style={styles.content}>
        {/* Subscription Plans */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Abonelik Paketleri</Text>
          <Text style={styles.sectionSubtitle}>
            Aylık abonelik alarak daha uygun fiyatlarla analiz yapabilirsiniz
          </Text>

          {pricingOptions && pricingOptions.availablePlans && pricingOptions.availablePlans.length > 0 ? (
            pricingOptions.availablePlans.map((plan: any) => (
            <TouchableOpacity
              key={plan.id}
              style={[
                styles.optionCard,
                selectedOption === plan.id && styles.optionCardSelected,
              ]}
              onPress={() => setSelectedOption(plan.id)}
            >
              <View style={styles.optionHeader}>
                <Text style={styles.optionTitle}>{plan.name}</Text>
                <Text style={styles.optionPrice}>${plan.price_usd}/ay</Text>
              </View>
              <View style={styles.optionFeatures}>
                <Text style={styles.featureItem}>
                  ✓ Kendi Analizim (Dahil)
                </Text>
                <Text style={styles.featureItem}>
                  ✓ {plan.self_reanalysis_limit} Tekrar Analiz
                </Text>
                <Text style={styles.featureItem}>
                  ✓ {plan.other_analysis_limit} Başka Kişi Analizi
                </Text>
                <Text style={styles.featureItem}>
                  ✓ {plan.relationship_analysis_limit} İlişki Analizi
                </Text>
                <Text style={styles.featureItem}>
                  ✓ {plan.coaching_tokens_limit / 1000}K Coaching Token
                </Text>
              </View>
              {selectedOption === plan.id && (
                <TouchableOpacity
                  style={styles.selectButton}
                  onPress={() => handlePurchaseSubscription(plan.id)}
                >
                  <Text style={styles.selectButtonText}>Bu Paketi Seç</Text>
                </TouchableOpacity>
              )}
            </TouchableOpacity>
          ))
          ) : (
            <Text style={styles.noPlansText}>Yükleniyor...</Text>
          )}
        </View>

        {/* PAYG Option */}
        {pricingOptions?.paygOption && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Tek Seferlik Ödeme</Text>
            <Text style={styles.sectionSubtitle}>
              Sadece şu anki analiz için ödeme yapın
            </Text>

            <TouchableOpacity
              style={[
                styles.optionCard,
                selectedOption === 'payg' && styles.optionCardSelected,
              ]}
              onPress={() => setSelectedOption('payg')}
            >
              <View style={styles.optionHeader}>
                <Text style={styles.optionTitle}>{getServiceName()}</Text>
                <Text style={styles.optionPrice}>
                  ${pricingOptions.paygOption.price_usd}
                </Text>
              </View>
              <Text style={styles.paygDescription}>
                Sadece bu analiz için tek seferlik ödeme
              </Text>
              {selectedOption === 'payg' && (
                <TouchableOpacity
                  style={styles.selectButton}
                  onPress={handlePurchasePayg}
                >
                  <Text style={styles.selectButtonText}>Tek Seferlik Öde</Text>
                </TouchableOpacity>
              )}
            </TouchableOpacity>
          </View>
        )}

        {/* Current Subscriptions Info */}
        {subscriptions.length > 0 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Mevcut Abonelikleriniz</Text>
            {subscriptions.map((sub: any, index: number) => (
              <View key={sub.id} style={styles.subscriptionInfo}>
                <Text style={styles.subscriptionName}>
                  {sub.name} - Bitiş: {new Date(sub.end_date).toLocaleDateString('tr-TR')}
                </Text>
                <Text style={styles.subscriptionCredits}>
                  Kalan: {JSON.stringify(sub.credits_remaining)}
                </Text>
              </View>
            ))}
          </View>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F7F9FC',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 10,
    fontSize: 16,
    color: '#666',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 20,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  backButton: {
    width: 40,
    height: 40,
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 3,
    backgroundColor: '#F8FAFC',
  },
  backArrow: {
    fontSize: 20,
    color: '#1E293B',
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#1E293B',
    flex: 1,
    textAlign: 'center',
  },
  headerSpacer: {
    width: 40,
  },
  content: {
    flex: 1,
  },
  infoSection: {
    margin: 20,
    padding: 20,
    backgroundColor: '#FEF3C7',
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#FCD34D',
  },
  infoTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#92400E',
    marginBottom: 10,
  },
  infoText: {
    fontSize: 14,
    color: '#78350F',
    marginBottom: 5,
  },
  section: {
    margin: 20,
    marginTop: 0,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: 'rgb(45, 55, 72)',
    marginBottom: 5,
  },
  sectionSubtitle: {
    fontSize: 14,
    color: '#64748B',
    marginBottom: 15,
  },
  optionCard: {
    backgroundColor: '#FFFFFF',
    padding: 20,
    borderRadius: 3,
    marginBottom: 15,
    borderWidth: 2,
    borderColor: '#E5E7EB',
  },
  optionCardSelected: {
    borderColor: 'rgb(66, 153, 225)',
    backgroundColor: '#EFF6FF',
  },
  optionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 15,
  },
  optionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1E293B',
  },
  optionPrice: {
    fontSize: 20,
    fontWeight: '700',
    color: 'rgb(66, 153, 225)',
  },
  optionFeatures: {
    marginBottom: 15,
  },
  featureItem: {
    fontSize: 14,
    color: '#475569',
    marginBottom: 5,
  },
  paygDescription: {
    fontSize: 14,
    color: '#64748B',
    marginBottom: 15,
  },
  selectButton: {
    backgroundColor: 'rgb(66, 153, 225)',
    padding: 15,
    borderRadius: 3,
    alignItems: 'center',
  },
  selectButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  subscriptionInfo: {
    backgroundColor: '#F8FAFC',
    padding: 15,
    borderRadius: 3,
    marginBottom: 10,
  },
  subscriptionName: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1E293B',
    marginBottom: 5,
  },
  subscriptionCredits: {
    fontSize: 12,
    color: '#64748B',
  },
  noPlansText: {
    fontSize: 14,
    color: '#64748B',
    textAlign: 'center',
    padding: 20,
  },
});