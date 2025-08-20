import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  ActivityIndicator,
  Alert,
  Platform,
  RefreshControl,
} from 'react-native';

const API_URL = 'http://localhost:8080';

interface AnalysisResult {
  id: string;
  analysis_type: string;
  status: 'processing' | 'completed' | 'error';
  result_markdown?: string;
  error_message?: string;
  created_at: string;
  completed_at?: string;
  s0_data?: any;
  s1_data?: any;
}

export default function MyAnalysesScreen({ navigation }: any) {
  const [analyses, setAnalyses] = useState<AnalysisResult[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [userEmail, setUserEmail] = useState('test@test.com');

  useEffect(() => {
    loadUserEmail();
    loadAnalyses();
    
    // Auto-refresh after 1 second to catch newly submitted analyses
    const initialRefresh = setTimeout(() => {
      loadAnalyses(true);
    }, 1000);
    
    return () => {
      clearTimeout(initialRefresh);
    };
  }, []);

  // Separate effect for polling that depends on analyses state
  useEffect(() => {
    // Poll for updates every 2 seconds
    const interval = setInterval(() => {
      // Always check if there are processing analyses
      const hasProcessing = analyses.some(a => a.status === 'processing');
      
      if (hasProcessing) {
        console.log('Found processing analysis, refreshing...');
        loadAnalyses(true);
      } else {
        // Force re-render to update time display even without API call
        setAnalyses(prev => [...prev]);
      }
    }, 2000);
    
    return () => clearInterval(interval);
  }, [analyses]); // Now this effect re-runs when analyses changes

  const loadUserEmail = () => {
    try {
      if (Platform.OS === 'web') {
        const email = localStorage.getItem('userEmail');
        if (email) setUserEmail(email);
      }
    } catch (error) {
      console.error('Error loading user email:', error);
    }
  };

  const loadAnalyses = async (silent = false) => {
    if (!silent) setLoading(true);
    try {
      const response = await fetch(`${API_URL}/v1/user/analyses`, {
        headers: {
          'x-user-email': userEmail,
        },
      });

      if (response.ok) {
        const data = await response.json();
        setAnalyses(data.analyses || []);
      }
    } catch (error) {
      console.error('Error loading analyses:', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const deleteAnalysis = async (analysis: AnalysisResult) => {
    console.log('DELETE BUTTON CLICKED - Analysis object:', analysis);
    console.log('Analysis ID:', analysis.id);
    console.log('API_URL:', API_URL);
    console.log('User email:', userEmail);
    
    // Web'de Alert çalışmıyor, direkt confirm kullan
    if (Platform.OS === 'web') {
      const confirmed = window.confirm('Bu analizi silmek istediğinizden emin misiniz?');
      if (!confirmed) return;
    } else {
      Alert.alert(
        'Analizi Sil',
        'Bu analizi silmek istediğinizden emin misiniz?',
        [
          { text: 'İptal', style: 'cancel' },
          {
            text: 'Sil',
            style: 'destructive',
            onPress: async () => {
              await performDelete(analysis);
            },
          },
        ]
      );
      return;
    }
    
    await performDelete(analysis);
  };

  const performDelete = async (analysis: AnalysisResult) => {
    try {
      console.log('CONFIRMATION YES - Deleting analysis:', analysis.id, typeof analysis.id);
      console.log('User email:', userEmail);
      console.log('Full URL:', `${API_URL}/v1/user/analyses/${analysis.id}`);
      
      const response = await fetch(`${API_URL}/v1/user/analyses/${analysis.id}`, {
        method: 'DELETE',
        headers: {
          'x-user-email': userEmail,
        },
      });

      console.log('Delete response status:', response.status);
      const responseText = await response.text();
      console.log('Delete response text:', responseText);
      
      let responseData;
      try {
        responseData = JSON.parse(responseText);
      } catch (e) {
        responseData = { error: responseText };
      }
      console.log('Delete response data:', responseData);

      if (response.ok) {
        if (Platform.OS === 'web') {
          alert('Analiz silindi');
        } else {
          Alert.alert('Başarılı', 'Analiz silindi');
        }
        loadAnalyses();
      } else {
        const errorMsg = responseData?.error || `HTTP ${response.status}: ${responseText}`;
        if (Platform.OS === 'web') {
          alert('Hata: ' + errorMsg);
        } else {
          Alert.alert('Hata', errorMsg);
        }
      }
    } catch (error) {
      console.error('Error deleting analysis:', error);
      if (Platform.OS === 'web') {
        alert('Network error: ' + error.message);
      } else {
        Alert.alert('Hata', `Network error: ${error.message}`);
      }
    }
  };

  const retryAnalysis = async (analysis: AnalysisResult) => {
    // Web'de Alert çalışmıyor, direkt confirm kullan
    if (Platform.OS === 'web') {
      const confirmed = window.confirm('Bu analizi tekrar denemek istediğinizden emin misiniz?');
      if (!confirmed) return;
    } else {
      Alert.alert(
        'Analizi Tekrarla',
        'Bu analizi tekrar denemek istediğinizden emin misiniz?',
        [
          { text: 'İptal', style: 'cancel' },
          {
            text: 'Tekrarla',
            onPress: async () => {
              await performRetry(analysis);
            },
          },
        ]
      );
      return;
    }
    
    await performRetry(analysis);
  };

  const performRetry = async (analysis: AnalysisResult) => {
    try {
      const response = await fetch(`${API_URL}/v1/analyze/retry`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-user-email': userEmail,
        },
        body: JSON.stringify({
          analysisId: analysis.id,
        }),
      });

      if (response.ok) {
        if (Platform.OS === 'web') {
          alert('Analiz tekrar başlatıldı');
        } else {
          Alert.alert('Başarılı', 'Analiz tekrar başlatıldı');
        }
        loadAnalyses();
      } else {
        if (Platform.OS === 'web') {
          alert('Hata: Analiz tekrarlanamadı');
        } else {
          Alert.alert('Hata', 'Analiz tekrarlanamadı');
        }
      }
    } catch (error) {
      console.error('Error retrying analysis:', error);
      if (Platform.OS === 'web') {
        alert('Hata: Bir hata oluştu');
      } else {
        Alert.alert('Hata', 'Bir hata oluştu');
      }
    }
  };

  const viewAnalysis = (analysis: AnalysisResult) => {
    if (analysis.status === 'completed' && analysis.result_markdown) {
      navigation.navigate('AnalysisResult', {
        result: {
          markdown: analysis.result_markdown,
          analysisId: analysis.id,
        },
      });
    }
  };

  const getAnalysisTypeLabel = (type: string) => {
    switch (type) {
      case 'self':
        return 'Kendi Analizim';
      case 'other':
        return 'Başka Kişi Analizi';
      case 'dyad':
        return 'İlişki Analizi';
      case 'coach':
        return 'Koçluk';
      default:
        return type;
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'processing':
        return '⏳ İşleniyor...';
      case 'completed':
        return '✅ Tamamlandı';
      case 'error':
        return '❌ Hata';
      default:
        return status;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'processing':
        return '#F59E0B';
      case 'completed':
        return '#10B981';
      case 'error':
        return '#EF4444';
      default:
        return '#6B7280';
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return 'Şimdi';
    if (diffMins < 60) return `${diffMins} dakika önce`;
    if (diffHours < 24) return `${diffHours} saat önce`;
    if (diffDays < 7) return `${diffDays} gün önce`;
    
    return date.toLocaleDateString('tr-TR', {
      day: 'numeric',
      month: 'long',
      year: date.getFullYear() !== now.getFullYear() ? 'numeric' : undefined,
    });
  };

  if (loading && analyses.length === 0) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#4299E1" />
          <Text style={styles.loadingText}>Analizler yükleniyor...</Text>
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
        <Text style={styles.headerTitle}>Analizlerim</Text>
        <TouchableOpacity onPress={() => loadAnalyses()} style={styles.refreshButton}>
          <Text style={styles.refreshIcon}>🔄</Text>
        </TouchableOpacity>
      </View>

      <ScrollView
        style={styles.scrollView}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={() => {
            setRefreshing(true);
            loadAnalyses();
          }} />
        }
      >
        {analyses.length === 0 ? (
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyIcon}>📊</Text>
            <Text style={styles.emptyTitle}>Henüz analiz yok</Text>
            <Text style={styles.emptySubtitle}>
              İlk analizinizi yapmak için formları doldurun
            </Text>
            <TouchableOpacity
              style={styles.newAnalysisButton}
              onPress={() => navigation.navigate('Home')}
            >
              <Text style={styles.newAnalysisButtonText}>Yeni Analiz Başlat</Text>
            </TouchableOpacity>
          </View>
        ) : (
          <View style={styles.analysesList}>
            {analyses.map((analysis) => (
              <View
                key={analysis.id}
                style={[
                  styles.analysisCard,
                  analysis.status === 'processing' && styles.processingCard,
                ]}
              >
                <View style={styles.cardHeader}>
                  <View>
                    <Text style={styles.analysisType}>
                      {getAnalysisTypeLabel(analysis.analysis_type)}
                    </Text>
                    <Text style={styles.analysisDate}>
                      {formatDate(analysis.created_at)}
                    </Text>
                  </View>
                  <View style={styles.statusContainer}>
                    <Text style={[
                      styles.statusLabel,
                      { color: getStatusColor(analysis.status) }
                    ]}>
                      {getStatusLabel(analysis.status)}
                    </Text>
                  </View>
                </View>

                {analysis.status === 'processing' && (
                  <View style={styles.processingInfo}>
                    <View style={styles.processingContent}>
                      <ActivityIndicator size="small" color="#F59E0B" />
                      <Text style={styles.processingText}>
                        Analiziniz hazırlanıyor... Bu birkaç dakika sürebilir.
                      </Text>
                    </View>
                    <TouchableOpacity
                      style={styles.deleteSmallButton}
                      onPress={() => deleteAnalysis(analysis)}
                    >
                      <Text style={styles.deleteSmallButtonText}>🗑️</Text>
                    </TouchableOpacity>
                  </View>
                )}

                {analysis.status === 'error' && (
                  <View style={styles.errorInfo}>
                    <Text style={styles.errorText}>
                      {analysis.error_message || 'Analiz sırasında bir hata oluştu'}
                    </Text>
                    <View style={styles.errorActions}>
                      <TouchableOpacity
                        style={styles.retryButton}
                        onPress={() => retryAnalysis(analysis)}
                      >
                        <Text style={styles.retryButtonText}>Tekrar Dene</Text>
                      </TouchableOpacity>
                      <TouchableOpacity
                        style={styles.deleteSmallButton}
                        onPress={() => deleteAnalysis(analysis)}
                      >
                        <Text style={styles.deleteSmallButtonText}>🗑️ Sil</Text>
                      </TouchableOpacity>
                    </View>
                  </View>
                )}

                {analysis.status === 'completed' && (
                  <View style={styles.completedInfo}>
                    <TouchableOpacity
                      style={styles.viewButton}
                      onPress={() => viewAnalysis(analysis)}
                    >
                      <Text style={styles.viewButtonText}>Sonuçları Görüntüle →</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                      style={styles.deleteButton}
                      onPress={() => deleteAnalysis(analysis)}
                    >
                      <Text style={styles.deleteButtonText}>🗑️ Sil</Text>
                    </TouchableOpacity>
                  </View>
                )}
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
    backgroundColor: '#F7FAFC',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingVertical: 16,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
  },
  backButton: {
    padding: 8,
  },
  backArrow: {
    fontSize: 24,
    color: '#2D3748',
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#2D3748',
  },
  refreshButton: {
    padding: 8,
  },
  refreshIcon: {
    fontSize: 20,
  },
  scrollView: {
    flex: 1,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 12,
    fontSize: 16,
    color: '#718096',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 60,
    paddingHorizontal: 20,
  },
  emptyIcon: {
    fontSize: 48,
    marginBottom: 16,
  },
  emptyTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#2D3748',
    marginBottom: 8,
  },
  emptySubtitle: {
    fontSize: 14,
    color: '#718096',
    textAlign: 'center',
    marginBottom: 24,
  },
  newAnalysisButton: {
    backgroundColor: '#4299E1',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 8,
  },
  newAnalysisButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  analysesList: {
    padding: 20,
  },
  analysisCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  processingCard: {
    borderColor: '#FCD34D',
    borderWidth: 2,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 8,
  },
  analysisType: {
    fontSize: 16,
    fontWeight: '600',
    color: '#2D3748',
    marginBottom: 4,
  },
  analysisDate: {
    fontSize: 13,
    color: '#718096',
  },
  statusContainer: {
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 12,
    backgroundColor: '#F7FAFC',
  },
  statusLabel: {
    fontSize: 13,
    fontWeight: '600',
  },
  processingInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 8,
    padding: 12,
    backgroundColor: '#FEF3C7',
    borderRadius: 8,
  },
  processingContent: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  processingText: {
    marginLeft: 8,
    fontSize: 13,
    color: '#92400E',
    flex: 1,
  },
  errorInfo: {
    marginTop: 8,
    padding: 12,
    backgroundColor: '#FEE2E2',
    borderRadius: 8,
  },
  errorText: {
    fontSize: 13,
    color: '#991B1B',
    marginBottom: 8,
  },
  errorActions: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  retryButton: {
    backgroundColor: '#EF4444',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 6,
    flex: 1,
    marginRight: 8,
  },
  retryButtonText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '600',
    textAlign: 'center',
  },
  completedInfo: {
    marginTop: 8,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  viewButton: {
    flex: 1,
    paddingVertical: 8,
  },
  viewButtonText: {
    fontSize: 14,
    color: '#4299E1',
    fontWeight: '600',
  },
  deleteButton: {
    paddingVertical: 8,
    paddingHorizontal: 12,
    backgroundColor: '#FEE2E2',
    borderRadius: 6,
    marginLeft: 8,
  },
  deleteButtonText: {
    fontSize: 13,
    color: '#991B1B',
    fontWeight: '600',
  },
  deleteSmallButton: {
    paddingVertical: 6,
    paddingHorizontal: 8,
    backgroundColor: '#FEE2E2',
    borderRadius: 4,
  },
  deleteSmallButtonText: {
    fontSize: 12,
    color: '#991B1B',
    fontWeight: '600',
  },
});