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
  }, []);

  useEffect(() => {
    loadAnalyses();
  }, [userEmail]);
  
  // Auto-refresh for processing analyses
  useEffect(() => {
    const hasProcessing = analyses.some(a => a.status === 'processing');
    
    if (hasProcessing) {
      const interval = setInterval(() => {
        loadAnalyses();
      }, 3000); // Check every 3 seconds
      
      return () => clearInterval(interval);
    }
  }, [analyses]);

  const loadUserEmail = () => {
    if (Platform.OS === 'web') {
      const email = localStorage.getItem('userEmail');
      if (email) setUserEmail(email);
    }
  };

  const loadAnalyses = async () => {
    return new Promise((resolve) => {
      const xhr = new XMLHttpRequest();
      xhr.open('GET', `${API_URL}/v1/user/analyses`);
      xhr.setRequestHeader('x-user-email', userEmail);
      
      xhr.onload = () => {
        try {
          if (xhr.status === 200) {
            const data = JSON.parse(xhr.responseText);
            setAnalyses(data.analyses || []);
          }
        } catch (error) {
          console.error('Error parsing analyses:', error);
        } finally {
          setLoading(false);
          setRefreshing(false);
          resolve(undefined);
        }
      };
      
      xhr.onerror = () => {
        console.error('XHR Error');
        setLoading(false);
        setRefreshing(false);
        resolve(undefined);
      };
      
      xhr.send();
    });
  };

  const onRefresh = () => {
    setRefreshing(true);
    loadAnalyses();
  };

  const deleteAnalysis = async (analysis: AnalysisResult) => {
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
            onPress: () => performDelete(analysis),
          },
        ]
      );
      return;
    }
    
    await performDelete(analysis);
  };

  const performDelete = async (analysis: AnalysisResult) => {
    try {
      const response = await fetch(`${API_URL}/v1/user/analyses/${analysis.id}`, {
        method: 'DELETE',
        headers: {
          'x-user-email': userEmail,
        },
      });
      
      if (response.ok) {
        loadAnalyses();
      }
    } catch (error) {
      console.error('Error deleting analysis:', error);
    }
  };

  const retryAnalysis = async (analysis: AnalysisResult) => {
    try {
      const response = await fetch(`${API_URL}/v1/analyze/retry`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-user-email': userEmail,
        },
        body: JSON.stringify({ analysisId: analysis.id }),
      });
      
      if (response.ok) {
        loadAnalyses();
      }
    } catch (error) {
      console.error('Error retrying analysis:', error);
    }
  };

  const viewAnalysis = (analysis: AnalysisResult) => {
    console.log('Viewing analysis:', analysis.id);
    console.log('Result markdown exists:', !!analysis.result_markdown);
    console.log('Result markdown length:', analysis.result_markdown?.length || 0);
    
    if (!analysis.result_markdown) {
      Alert.alert('Hata', 'Analiz sonucu henüz hazır değil. Lütfen birkaç saniye bekleyin.');
      return;
    }
    
    navigation.navigate('AnalysisResult', { 
      markdown: analysis.result_markdown,
      analysisType: analysis.analysis_type
    });
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);
    
    if (minutes < 1) return 'Şimdi';
    if (minutes < 60) return `${minutes} dakika önce`;
    if (hours < 24) return `${hours} saat önce`;
    if (days < 7) return `${days} gün önce`;
    
    return date.toLocaleDateString('tr-TR', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const getAnalysisTypeLabel = (type: string) => {
    switch (type) {
      case 'self': return 'Kişisel Analiz';
      case 'other': return 'Başkası Analizi';
      case 'dyad': return 'İlişki Analizi';
      default: return type;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return '#10B981';
      case 'processing': return '#3B82F6';
      case 'error': return '#EF4444';
      default: return '#6B7280';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'completed': return 'Tamamlandı';
      case 'processing': return 'İşleniyor...';
      case 'error': return 'Hata';
      default: return status;
    }
  };

  if (loading) {
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
        <TouchableOpacity 
          style={styles.backButton}
          onPress={() => navigation.goBack()}
        >
          <Text style={styles.backButtonText}>← </Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Analizlerim</Text>
        <View style={{ width: 40 }} />
      </View>

      {analyses.some(a => a.analysis_type === 'self') && (
        <TouchableOpacity
          style={styles.mainEditButton}
          onPress={() => navigation.navigate('NewForms', { editMode: true })}
        >
          <Text style={styles.mainEditButtonText}>Cevapları Düzenle</Text>
        </TouchableOpacity>
      )}
      
      <ScrollView 
        style={styles.scrollView}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            colors={['#4299E1']}
          />
        }
      >
        {analyses.length === 0 ? (
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyText}>Henüz analiz bulunmuyor</Text>
            <TouchableOpacity
              style={styles.newAnalysisButton}
              onPress={() => navigation.navigate('Forms')}
            >
              <Text style={styles.newAnalysisButtonText}>Yeni Analiz Başlat</Text>
            </TouchableOpacity>
          </View>
        ) : (
          analyses.map((analysis) => (
            <View key={analysis.id} style={styles.analysisCard}>
              <View style={styles.cardHeader}>
                <Text style={styles.analysisType}>
                  {getAnalysisTypeLabel(analysis.analysis_type)}
                </Text>
                <View style={styles.statusContainer}>
                  <Text style={[styles.statusIcon, { color: getStatusColor(analysis.status) }]}>
                    {analysis.status === 'completed' ? '✓ ' : analysis.status === 'error' ? '✕ ' : '⟳ '}
                  </Text>
                  <Text style={[styles.statusText, { color: getStatusColor(analysis.status) }]}>
                    {getStatusText(analysis.status)}
                  </Text>
                </View>
              </View>
              
              <Text style={styles.dateText}>{formatDate(analysis.created_at)}</Text>
              
              {analysis.status === 'error' && (
                <View style={styles.errorContainer}>
                  <Text style={styles.errorText}>
                    {analysis.error_message || 'Analiz sırasında bir hata oluştu'}
                  </Text>
                </View>
              )}
              
              <View style={styles.cardActions}>
                <View style={styles.leftActions}>
                  {analysis.status === 'completed' && (
                    <TouchableOpacity
                      style={styles.smallViewButton}
                      onPress={() => viewAnalysis(analysis)}
                    >
                      <Text style={styles.smallViewButtonText}>Görüntüle</Text>
                    </TouchableOpacity>
                  )}
                  
                  {analysis.status === 'error' && (
                    <TouchableOpacity
                      style={styles.smallRetryButton}
                      onPress={() => retryAnalysis(analysis)}
                    >
                      <Text style={styles.smallRetryButtonText}>Tekrar Dene</Text>
                    </TouchableOpacity>
                  )}
                </View>
                
                <TouchableOpacity
                  style={styles.smallDeleteButton}
                  onPress={() => deleteAnalysis(analysis)}
                >
                  <Text style={styles.smallDeleteButtonText}>Sil</Text>
                </TouchableOpacity>
              </View>
            </View>
          ))
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F9FAFB',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 12,
    fontSize: 16,
    color: '#6B7280',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 16,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: '600',
    color: '#111827',
    flex: 1,
    textAlign: 'center',
  },
  backButton: {
    width: 40,
    height: 40,
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 20,
  },
  backButtonText: {
    fontSize: 24,
    color: '#4299E1',
    fontWeight: 'bold',
  },
  mainEditButton: {
    backgroundColor: '#10B981',
    paddingVertical: 14,
    paddingHorizontal: 20,
    marginHorizontal: 20,
    marginTop: 16,
    marginBottom: 8,
    borderRadius: 3,
    alignItems: 'center',
    alignSelf: 'center',
  },
  mainEditButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  scrollView: {
    flex: 1,
    padding: 20,
  },
  emptyContainer: {
    alignItems: 'center',
    paddingVertical: 60,
  },
  emptyText: {
    fontSize: 16,
    color: '#6B7280',
    marginBottom: 20,
  },
  newAnalysisButton: {
    paddingVertical: 12,
    paddingHorizontal: 24,
    backgroundColor: '#4299E1',
    borderRadius: 3,
  },
  newAnalysisButtonText: {
    fontSize: 16,
    color: '#FFFFFF',
    fontWeight: '500',
  },
  analysisCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  analysisType: {
    fontSize: 16,
    fontWeight: '600',
    color: '#111827',
  },
  statusContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  statusIcon: {
    fontSize: 14,
    fontWeight: 'bold',
  },
  statusText: {
    fontSize: 13,
    fontWeight: '500',
  },
  dateText: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 12,
  },
  errorContainer: {
    backgroundColor: '#FEE2E2',
    padding: 12,
    borderRadius: 3,
    marginBottom: 12,
  },
  errorText: {
    fontSize: 14,
    color: '#991B1B',
  },
  cardActions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 8,
  },
  leftActions: {
    flexDirection: 'row',
    gap: 8,
    alignItems: 'center',
  },
  smallViewButton: {
    paddingVertical: 6,
    paddingHorizontal: 12,
    backgroundColor: '#4299E1',
    borderRadius: 3,
  },
  smallViewButtonText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '500',
  },
  smallRetryButton: {
    paddingVertical: 6,
    paddingHorizontal: 12,
    backgroundColor: '#F59E0B',
    borderRadius: 3,
  },
  smallRetryButtonText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '500',
  },
  smallDeleteButton: {
    paddingVertical: 6,
    paddingHorizontal: 12,
    backgroundColor: '#EF4444',
    borderRadius: 3,
  },
  smallDeleteButtonText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '500',
  },
});