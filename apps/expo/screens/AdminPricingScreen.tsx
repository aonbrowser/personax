import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  SafeAreaView,
  TouchableOpacity,
  TextInput,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { API_URL } from '../config';

interface AdminPricingScreenProps {
  navigation: any;
}

interface SubscriptionPlan {
  id: string;
  name: string;
  total_analysis_credits: number;
  coaching_tokens_limit: number;
  price_usd: number;
  is_active: boolean;
  self_analysis_limit?: number;
  self_reanalysis_limit?: number;
  other_analysis_limit?: number;
  relationship_analysis_limit?: number;
}

export default function AdminPricingScreen({ navigation }: AdminPricingScreenProps) {
  const [plans, setPlans] = useState<SubscriptionPlan[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingPlan, setEditingPlan] = useState<string | null>(null);
  const [editedValues, setEditedValues] = useState<any>({});

  useEffect(() => {
    loadPlans();
  }, []);

  const loadPlans = async () => {
    try {
      const response = await fetch(`${API_URL}/v1/admin/pricing/plans`, {
        headers: {
          'x-admin-key': 'admin-secret-key-2025',
        },
      });

      if (response.ok) {
        const data = await response.json();
        setPlans(data.plans || []);
      } else {
        throw new Error('Failed to fetch plans');
      }
    } catch (error) {
      console.error('Error loading plans:', error);
      Alert.alert('Hata', 'Planlar yüklenemedi');
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (planId: string) => {
    const plan = plans.find(p => p.id === planId);
    if (plan) {
      setEditingPlan(planId);
      setEditedValues({
        price_usd: plan.price_usd.toString(),
        total_analysis_credits: plan.total_analysis_credits.toString(),
        coaching_tokens_limit: plan.coaching_tokens_limit.toString(),
      });
    }
  };

  const handleSave = async (planId: string) => {
    try {
      const response = await fetch(`${API_URL}/v1/admin/pricing/plans/${planId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'x-admin-key': 'admin-secret-key-2025',
        },
        body: JSON.stringify({
          price_usd: parseFloat(editedValues.price_usd),
          total_analysis_credits: parseInt(editedValues.total_analysis_credits),
          coaching_tokens_limit: parseInt(editedValues.coaching_tokens_limit),
        }),
      });

      if (response.ok) {
        Alert.alert('Başarılı', 'Plan güncellendi.');
        await loadPlans();
        setEditingPlan(null);
      } else {
        throw new Error('Failed to update plan');
      }
    } catch (error) {
      console.error('Error updating plan:', error);
      Alert.alert('Hata', 'Plan güncellenemedi.');
    }
  };

  const handleCancel = () => {
    setEditingPlan(null);
    setEditedValues({});
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backButton}>
            <Text style={styles.backArrow}>←</Text>
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Admin Panel - Fiyatlandırma</Text>
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
        <Text style={styles.headerTitle}>Admin Panel - Fiyatlandırma</Text>
        <View style={styles.headerSpacer} />
      </View>

      <ScrollView style={styles.content}>
        <Text style={styles.sectionTitle}>Abonelik Planları</Text>
        
        {plans.map(plan => (
          <View key={plan.id} style={styles.planCard}>
            <View style={styles.planHeader}>
              <Text style={styles.planName}>{plan.name} Paket</Text>
              {editingPlan !== plan.id ? (
                <TouchableOpacity 
                  style={styles.editButton}
                  onPress={() => handleEdit(plan.id)}
                >
                  <Text style={styles.editButtonText}>Düzenle</Text>
                </TouchableOpacity>
              ) : (
                <View style={styles.actionButtons}>
                  <TouchableOpacity 
                    style={styles.saveButton}
                    onPress={() => handleSave(plan.id)}
                  >
                    <Text style={styles.saveButtonText}>Kaydet</Text>
                  </TouchableOpacity>
                  <TouchableOpacity 
                    style={styles.cancelButton}
                    onPress={handleCancel}
                  >
                    <Text style={styles.cancelButtonText}>İptal</Text>
                  </TouchableOpacity>
                </View>
              )}
            </View>

            <View style={styles.planDetails}>
              <View style={styles.detailRow}>
                <Text style={styles.detailLabel}>Fiyat (USD):</Text>
                {editingPlan === plan.id ? (
                  <TextInput
                    style={styles.input}
                    value={editedValues.price_usd}
                    onChangeText={(text) => setEditedValues({...editedValues, price_usd: text})}
                    keyboardType="numeric"
                  />
                ) : (
                  <Text style={styles.detailValue}>${plan.price_usd}</Text>
                )}
              </View>

              <View style={styles.detailRow}>
                <Text style={styles.detailLabel}>Toplam Analiz Kredisi:</Text>
                {editingPlan === plan.id ? (
                  <TextInput
                    style={styles.input}
                    value={editedValues.total_analysis_credits}
                    onChangeText={(text) => setEditedValues({...editedValues, total_analysis_credits: text})}
                    keyboardType="numeric"
                  />
                ) : (
                  <Text style={styles.detailValue}>{plan.total_analysis_credits}</Text>
                )}
              </View>

              <View style={styles.detailRow}>
                <Text style={styles.detailLabel}>Koçluk Token:</Text>
                {editingPlan === plan.id ? (
                  <TextInput
                    style={styles.input}
                    value={editedValues.coaching_tokens_limit}
                    onChangeText={(text) => setEditedValues({...editedValues, coaching_tokens_limit: text})}
                    keyboardType="numeric"
                  />
                ) : (
                  <Text style={styles.detailValue}>{plan.coaching_tokens_limit}</Text>
                )}
              </View>
            </View>
          </View>
        ))}

        <View style={styles.infoBox}>
          <Text style={styles.infoText}>
            Not: Bu panel sadece yöneticiler için görünür. Logo'ya 3 kez tıklayarak erişim sağlanır.
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
  sectionTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#000',
    marginBottom: 20,
  },
  planCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    padding: 20,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  planHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
  },
  planName: {
    fontSize: 18,
    fontWeight: '600',
    color: '#000',
  },
  editButton: {
    backgroundColor: 'rgb(66, 153, 225)',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 3,
  },
  editButtonText: {
    color: '#FFFFFF',
    fontWeight: '600',
    fontSize: 14,
  },
  actionButtons: {
    flexDirection: 'row',
    gap: 10,
  },
  saveButton: {
    backgroundColor: '#10B981',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 3,
  },
  saveButtonText: {
    color: '#FFFFFF',
    fontWeight: '600',
    fontSize: 14,
  },
  cancelButton: {
    backgroundColor: '#EF4444',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 3,
  },
  cancelButtonText: {
    color: '#FFFFFF',
    fontWeight: '600',
    fontSize: 14,
  },
  planDetails: {
    gap: 12,
  },
  detailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  detailLabel: {
    fontSize: 14,
    color: '#6B7280',
  },
  detailValue: {
    fontSize: 14,
    fontWeight: '600',
    color: '#000',
  },
  input: {
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    paddingHorizontal: 10,
    paddingVertical: 5,
    fontSize: 14,
    width: 100,
    textAlign: 'right',
  },
  infoBox: {
    backgroundColor: '#EFF6FF',
    padding: 16,
    borderRadius: 3,
    marginTop: 20,
  },
  infoText: {
    fontSize: 14,
    color: '#1E40AF',
    lineHeight: 20,
  },
});