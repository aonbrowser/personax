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
  TextInput,
} from 'react-native';
import InAppPurchaseService from '../services/InAppPurchaseService';

import { API_URL } from '../config';

interface PaymentCheckScreenProps {
  navigation: any;
  route: {
    params: {
      serviceType: 'self_analysis' | 'other_analysis' | 'relationship_analysis' | 'coaching';
      userEmail?: string;
      formData?: any;
      form1Data?: any;
      form2Data?: any;
      form3Data?: any;
      onComplete: (result: any) => void;
    };
  };
}

export default function PaymentCheckScreen({ navigation, route }: PaymentCheckScreenProps) {
  const { serviceType, formData, form1Data, form2Data, form3Data, onComplete, userEmail: routeEmail, editMode, analysisId } = route.params;
  const [loading, setLoading] = useState(true);
  const [isProcessing, setIsProcessing] = useState(false);
  const [hasCredit, setHasCredit] = useState(false);
  const [subscriptions, setSubscriptions] = useState<any[]>([]);
  const [pricingOptions, setPricingOptions] = useState<any>(null);
  const [selectedOption, setSelectedOption] = useState<string>('');
  const [couponCode, setCouponCode] = useState<string>('');
  const [appliedCoupon, setAppliedCoupon] = useState<any>(null);
  const [checkingCoupon, setCheckingCoupon] = useState(false);
  const [storedFormData] = useState(() => {
    console.log('=== INITIALIZING STORED FORM DATA ===');
    console.log('form1Data from params:', form1Data);
    console.log('form2Data from params:', form2Data);
    console.log('form3Data from params:', form3Data);
    
    // Check if we have new form structure (form1Data, form2Data, form3Data)
    if (form1Data || form2Data || form3Data) {
      const combinedData = {
        form1: form1Data || {},
        form2: form2Data || {},
        form3: form3Data || {}
      };
      console.log('=== NEW FORM DATA STRUCTURE ===');
      console.log('Form1 count:', Object.keys(combinedData.form1).length);
      console.log('Form2 count:', Object.keys(combinedData.form2).length);
      console.log('Form3 count:', Object.keys(combinedData.form3).length);
      
      // Store in localStorage for persistence
      if (Platform.OS === 'web') {
        localStorage.setItem('pending_analysis_data', JSON.stringify(combinedData));
      }
      return combinedData;
    }
    
    // Try to get from localStorage first (for web)
    if (Platform.OS === 'web') {
      const savedData = localStorage.getItem('pending_analysis_data');
      if (savedData) {
        try {
          const parsed = JSON.parse(savedData);
          console.log('=== LOADED FROM LOCALSTORAGE ===');
          console.log('Data structure:', Object.keys(parsed));
          // Clear after reading to avoid reuse
          localStorage.removeItem('pending_analysis_data');
          return parsed;
        } catch (e) {
          console.error('Error parsing localStorage data:', e);
        }
      }
    }
    
    // Fallback to old formData structure
    console.log('WARNING: No data in localStorage, checking route params');
    return formData || {};
  });
  const userEmail = routeEmail || 'test@test.com'; // Use email from route params

  // LOG: Check what formData we received
  console.log('=== PAYMENTCHECK RECEIVED ===');
  console.log('User Email:', userEmail);
  console.log('ServiceType:', serviceType);
  console.log('StoredFormData exists:', !!storedFormData);
  console.log('StoredFormData keys:', Object.keys(storedFormData));
  if (storedFormData && Object.keys(storedFormData).length > 0) {
    console.log('FormData s0 keys:', storedFormData.s0 ? Object.keys(storedFormData.s0).length + ' keys' : 'NO S0');
    console.log('FormData s1 keys:', storedFormData.s1 ? Object.keys(storedFormData.s1).length + ' keys' : 'NO S1');
    console.log('Form1 keys:', storedFormData.form1 ? Object.keys(storedFormData.form1).length + ' keys' : 'NO Form1');
    console.log('Form2 keys:', storedFormData.form2 ? Object.keys(storedFormData.form2).length + ' keys' : 'NO Form2');
    console.log('Form3 keys:', storedFormData.form3 ? Object.keys(storedFormData.form3).length + ' keys' : 'NO Form3');
  } else {
    console.log('WARNING: StoredFormData is empty!');
  }
  console.log('=============================');

  useEffect(() => {
    console.log('PaymentCheckScreen mounted');
    console.log('Route params in useEffect:', route.params);
    console.log('StoredFormData in useEffect:', storedFormData ? Object.keys(storedFormData) : 'null');
    
    // DO NOT navigate automatically - let checkUserLimits handle navigation
    // Check user limits and start analysis
    checkUserLimits();
    
    // Initialize In-App Purchases for mobile platforms
    if (Platform.OS !== 'web') {
      initializeIAP();
    }
    
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
    console.log('=== CHECKING USER LIMITS ===');
    console.log('User Email:', userEmail);
    console.log('Service Type:', serviceType);
    console.log('API URL:', `${API_URL}/v1/payment/check-limits?service_type=${serviceType}`);
    
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
      
      console.log('Limits Response Status:', limitsResponse.status);
      const limitsData = await limitsResponse.json();
      console.log('Limits Data:', JSON.stringify(limitsData, null, 2));
      console.log('Has Credit:', limitsData.hasCredit);
      console.log('Available Subscription:', limitsData.availableSubscription);

      setHasCredit(limitsData.hasCredit);
      setSubscriptions(limitsData.subscriptions || []);

      // If no credit, get pricing options
      if (!limitsData.hasCredit) {
        console.log('❌ USER HAS NO CREDIT!');
        console.log('Checked email:', userEmail);
        console.log('Response from backend:', limitsData);
        console.log('Fetching pricing options...');
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
        console.log('Pricing options received:', JSON.stringify(optionsData, null, 2));
        console.log('Available plans count:', optionsData?.availablePlans?.length);
        console.log('Available plans:', optionsData?.availablePlans);
        console.log('PAYG option:', optionsData?.paygOption);
        
        // Always set the pricing options
        setPricingOptions(optionsData);
        console.log('Pricing options state set to:', optionsData);
      } else {
        // Has credit, proceed with analysis
        console.log('✅ USER HAS CREDIT!');
        console.log('Available subscription:', limitsData.availableSubscription);
        console.log('Calling proceedWithAnalysis...');
        setHasCredit(true);
        proceedWithAnalysis(limitsData.availableSubscription?.id);
      }
    } catch (error) {
      console.error('Error checking limits:', error);
      Alert.alert('Hata', 'Limit kontrolü sırasında hata oluştu');
      setLoading(false); // Make sure loading is set to false even on error
    }
  };

  const proceedWithAnalysis = (subscriptionId?: string) => {
    // Use storedFormData from state to avoid closure issues
    const analysisData = storedFormData;
    
    if (!analysisData) {
      console.error('ERROR: No formData available for analysis!');
      console.error('storedFormData:', storedFormData);
      console.error('route.params.formData:', route.params.formData);
      Alert.alert('Hata', 'Form verileri bulunamadı. Lütfen formu tekrar doldurun.');
      return;
    }
    
    // Validate data before proceeding - Check for new form structure
    if (analysisData.form1 || analysisData.form2 || analysisData.form3) {
      // New form structure - validate form data
      const form1Count = analysisData.form1 ? Object.keys(analysisData.form1).length : 0;
      const form2Count = analysisData.form2 ? Object.keys(analysisData.form2).length : 0;
      const form3Count = analysisData.form3 ? Object.keys(analysisData.form3).length : 0;
      
      console.log('=== FORM DATA VALIDATION ===');
      console.log(`Form1 (Tanışalım): ${form1Count} cevap / 13 soru`);
      console.log(`Form2 (Kişilik): ${form2Count} cevap / 31 soru`);
      console.log(`Form3 (Davranış): ${form3Count} cevap / 40 soru`);
      console.log(`Toplam: ${form1Count + form2Count + form3Count} cevap / 84 soru`);
      
      if (form1Count === 0 && form2Count === 0 && form3Count === 0) {
        console.error('ERROR: All forms are empty!');
        Alert.alert('Hata', 'Form verileri boş. Lütfen en az bir formu doldurun.');
        return;
      }
      
      // At least one form should have data
      if (form1Count < 5) {
        console.warn('WARNING: Form1 has less than 5 responses:', form1Count);
        Alert.alert('Uyarı', 'Form 1 (Tanışalım) formunda eksik bilgiler var. Devam etmek istiyor musunuz?', [
          { text: 'Hayır', style: 'cancel' },
          { text: 'Evet', onPress: () => continueWithAnalysis(analysisData, subscriptionId) }
        ]);
        return;
      }
    } else {
      // Old S0/S1 structure - validate
      const s0Count = analysisData.s0 ? Object.keys(analysisData.s0).length : 0;
      const s1Count = analysisData.s1 ? Object.keys(analysisData.s1).length : 0;
      
      console.log('=== S0/S1 DATA VALIDATION ===');
      console.log('S0 responses:', s0Count);
      console.log('S1 responses:', s1Count);
      
      if (s0Count === 0 && s1Count === 0) {
        console.error('ERROR: Both S0 and S1 are empty!');
        Alert.alert('Hata', 'Form verileri boş. Lütfen formları doldurun.');
        return;
      }
    }
    
    // Continue with analysis
    continueWithAnalysis(analysisData, subscriptionId);
  };
  
  const continueWithAnalysis = (analysisData: any, subscriptionId?: string) => {
    console.log('=== continueWithAnalysis called ===');
    console.log('editMode:', editMode);
    console.log('analysisId:', analysisId);
    console.log('typeof editMode:', typeof editMode);
    console.log('typeof analysisId:', typeof analysisId);
    
    // Process Form3 DISC questions - combine MOST and LEAST into single answers
    let processedData = { ...analysisData };
    if (processedData.form3) {
      const processedForm3 = { ...processedData.form3 };
      
      // Find and combine DISC questions (F3_DISC_01 to F3_DISC_10)
      for (let i = 1; i <= 10; i++) {
        const discNum = i.toString().padStart(2, '0');
        const mostKey = `F3_DISC_${discNum}_MOST`;
        const leastKey = `F3_DISC_${discNum}_LEAST`;
        
        if (processedForm3[mostKey] || processedForm3[leastKey]) {
          // Combine into single answer object
          const combinedKey = `F3_DISC_${discNum}`;
          processedForm3[combinedKey] = {
            most: processedForm3[mostKey] || null,
            least: processedForm3[leastKey] || null
          };
          
          // Remove individual MOST/LEAST entries
          delete processedForm3[mostKey];
          delete processedForm3[leastKey];
          
          console.log(`Combined DISC ${i}: most=${processedForm3[combinedKey].most}, least=${processedForm3[combinedKey].least}`);
        }
      }
      
      // Update processedData with processed Form3
      processedData = {
        ...processedData,
        form3: processedForm3
      };
      
      console.log('Form3 after DISC processing:', Object.keys(processedForm3).length, 'items');
    }
    
    // If in edit mode, pass the analysisId to the API
    const requestData = {
      ...processedData,
      ...(editMode && analysisId ? { analysisId, updateExisting: true } : {})
    };
    
    // Navigate IMMEDIATELY
    console.log('NAVIGATING TO MyAnalyses NOW!');
    console.log('Edit mode:', editMode, 'Analysis ID:', analysisId);
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
      
      // LOG: Print the actual data being sent
      console.log('=== SENDING TO API ===');
      console.log('Endpoint:', `${API_URL}/v1${analysisEndpoint}`);
      
      // Check which format we're using
      if (analysisData.form1 || analysisData.form2 || analysisData.form3) {
        // New form structure
        console.log('Using NEW FORM STRUCTURE');
        console.log('Form1 keys:', analysisData.form1 ? Object.keys(analysisData.form1).length : 0);
        console.log('Form2 keys:', analysisData.form2 ? Object.keys(analysisData.form2).length : 0);
        console.log('Form3 keys:', analysisData.form3 ? Object.keys(analysisData.form3).length : 0);
        
        if (analysisData.form1) {
          console.log('Form1 sample values:', {
            age: analysisData.form1.F1_AGE,
            gender: analysisData.form1.F1_GENDER,
            relationship: analysisData.form1.F1_RELATIONSHIP
          });
        }
        
        // Log first 3 keys of each form to verify data
        if (analysisData.form1) {
          console.log('Form1 first 3 keys:', Object.keys(analysisData.form1).slice(0, 3));
        }
        if (analysisData.form2) {
          console.log('Form2 first 3 keys:', Object.keys(analysisData.form2).slice(0, 3));
        }
        if (analysisData.form3) {
          console.log('Form3 first 3 keys:', Object.keys(analysisData.form3).slice(0, 3));
          // Check for combined DISC questions
          const discKeys = Object.keys(analysisData.form3).filter(k => k.startsWith('F3_DISC_') && !k.includes('MOST') && !k.includes('LEAST'));
          if (discKeys.length > 0) {
            console.log('Combined DISC questions found:', discKeys.length);
            console.log('Sample DISC:', analysisData.form3[discKeys[0]]);
          }
        }
      } else {
        // Old S0/S1 structure
        console.log('Using OLD S0/S1 STRUCTURE');
        console.log('S0 data keys:', analysisData.s0 ? Object.keys(analysisData.s0) : 'No S0 data');
        console.log('S1 data keys:', analysisData.s1 ? Object.keys(analysisData.s1) : 'No S1 data');
        if (analysisData.s0) {
          console.log('Sample S0 values:', {
            age: analysisData.s0.S0_AGE,
            gender: analysisData.s0.S0_GENDER,
            lifeGoal: analysisData.s0.S0_LIFE_GOAL,
            happyMemory: analysisData.s0.S0_HAPPY_MEMORY
          });
        }
      }
      
      console.log('Full data being sent (first 500 chars):', JSON.stringify(requestData).substring(0, 500));
      console.log('Edit mode in request:', editMode);
      console.log('Analysis ID in request:', analysisId);
      console.log('Update existing flag:', requestData.updateExisting);
      console.log('Analysis ID in requestData:', requestData.analysisId);
      console.log('======================');
      
      // Set processing state before sending analysis
      setIsProcessing(true);
      setLoading(true);
      
      fetch(`${API_URL}/v1${analysisEndpoint}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-user-email': userEmail,
          'x-user-lang': 'tr',
          'x-user-id': userEmail,
        },
        body: JSON.stringify(requestData),
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

  const handleApplyCoupon = async () => {
    if (!couponCode.trim()) {
      Alert.alert('Hata', 'Lütfen bir kupon kodu girin');
      return;
    }

    setCheckingCoupon(true);
    try {
      const response = await fetch(`${API_URL}/v1/payment/validate-coupon`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-user-email': userEmail,
        },
        body: JSON.stringify({ 
          couponCode: couponCode.trim(),
          serviceType 
        }),
      });

      const data = await response.json();
      
      if (response.ok && data.valid) {
        setAppliedCoupon(data.coupon);
        Alert.alert('Başarılı', data.message || 'Kupon kodu uygulandı!');
        
        // If coupon provides free access, proceed with analysis
        if (data.coupon.type === 'free_subscription' || data.coupon.provides_credits) {
          // Wait a moment for the backend to process the subscription
          setTimeout(async () => {
            // Re-check limits to see if user now has credits
            const limitsResponse = await fetch(
              `${API_URL}/v1/payment/check-limits?service_type=${serviceType}`,
              {
                headers: {
                  'x-user-email': userEmail,
                },
              }
            );
            const limitsData = await limitsResponse.json();
            
            if (limitsData.hasCredit) {
              // User now has credit, proceed with analysis
              console.log('User now has credit after coupon, proceeding with analysis');
              setHasCredit(true);
              proceedWithAnalysis(limitsData.availableSubscription?.id);
            } else {
              // Still no credit, just refresh the limits
              checkUserLimits();
            }
          }, 1500);
        }
      } else {
        Alert.alert('Hata', data.message || 'Geçersiz kupon kodu');
        setAppliedCoupon(null);
      }
    } catch (error) {
      console.error('Coupon validation error:', error);
      Alert.alert('Hata', 'Kupon kodu kontrol edilemedi');
    } finally {
      setCheckingCoupon(false);
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
          <ActivityIndicator size="large" color="rgb(96, 187, 202)" />
          <Text style={styles.loadingText}>
            {isProcessing 
              ? "Verdiğiniz bilgiler doğrultusunda özel eğitilmiş yapay zekamız, ileri psikometrik teknikler kullanarak kişisel analizinizi hazırlıyor..."
              : "Kontrol ediliyor..."
            }
          </Text>
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
        {/* Coupon Code Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Kupon Kodu</Text>
          <Text style={styles.sectionSubtitle}>
            Kupon kodunuz varsa aşağıya girin
          </Text>
          <View style={styles.couponContainer}>
            <TextInput
              style={styles.couponInput}
              placeholder="Kupon kodunu girin"
              value={couponCode}
              onChangeText={setCouponCode}
              autoCapitalize="characters"
              editable={!appliedCoupon}
            />
            <TouchableOpacity
              style={[styles.couponButton, appliedCoupon && styles.couponButtonDisabled]}
              onPress={handleApplyCoupon}
              disabled={checkingCoupon || appliedCoupon}
            >
              {checkingCoupon ? (
                <ActivityIndicator size="small" color="#FFFFFF" />
              ) : (
                <Text style={styles.couponButtonText}>
                  {appliedCoupon ? 'Uygulandı ✓' : 'Uygula'}
                </Text>
              )}
            </TouchableOpacity>
          </View>
          {appliedCoupon && (
            <View style={styles.couponSuccessBox}>
              <Text style={styles.couponSuccessText}>
                ✓ {appliedCoupon.description || 'Kupon başarıyla uygulandı'}
              </Text>
            </View>
          )}
        </View>

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
          ) : pricingOptions ? (
            <Text style={styles.noPlansText}>Uygun paket bulunamadı</Text>
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
    marginTop: 20,
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
    paddingHorizontal: 30,
    lineHeight: 24,
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
    borderColor: 'rgb(96, 187, 202)',
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
    color: 'rgb(96, 187, 202)',
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
    backgroundColor: 'rgb(96, 187, 202)',
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
  couponContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 10,
  },
  couponInput: {
    flex: 1,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    padding: 12,
    fontSize: 14,
    backgroundColor: '#FFFFFF',
    marginRight: 10,
  },
  couponButton: {
    backgroundColor: 'rgb(96, 187, 202)',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 3,
    minWidth: 100,
    alignItems: 'center',
  },
  couponButtonDisabled: {
    backgroundColor: '#94A3B8',
  },
  couponButtonText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
  },
  couponSuccessBox: {
    backgroundColor: '#D1FAE5',
    padding: 12,
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#34D399',
  },
  couponSuccessText: {
    color: '#047857',
    fontSize: 14,
    fontWeight: '500',
  },
});