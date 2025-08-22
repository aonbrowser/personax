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
  Modal,
  Image,
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
  const [deleteModalVisible, setDeleteModalVisible] = useState(false);
  const [analysisToDelete, setAnalysisToDelete] = useState<AnalysisResult | null>(null);

  useEffect(() => {
    loadUserEmail();
  }, []);

  useEffect(() => {
    if (userEmail) {
      console.log('Loading analyses for user:', userEmail);
      loadAnalyses();
      
      // Also load after a short delay to catch newly created analyses
      setTimeout(() => {
        loadAnalyses();
      }, 1000);
    }
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

  const deleteAnalysis = (analysis: AnalysisResult) => {
    setAnalysisToDelete(analysis);
    setDeleteModalVisible(true);
  };

  const confirmDelete = async () => {
    if (analysisToDelete) {
      await performDelete(analysisToDelete);
      setDeleteModalVisible(false);
      setAnalysisToDelete(null);
    }
  };

  const cancelDelete = () => {
    setDeleteModalVisible(false);
    setAnalysisToDelete(null);
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
      case 'completed': return '#16A34A';
      case 'processing': return '#64748B';
      case 'error': return '#DC2626';
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
          <ActivityIndicator size="large" color="rgb(96, 187, 202)" />
          <Text style={styles.loadingText}>Analizler yükleniyor...</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.webWrapper}>
      <Modal
        animationType="fade"
        transparent={true}
        visible={deleteModalVisible}
        onRequestClose={cancelDelete}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>Analizi Sil</Text>
            <Text style={styles.modalText}>
              Bu analizi silmek istediğinizden emin misiniz?
            </Text>
            <View style={styles.modalButtons}>
              <TouchableOpacity 
                style={[styles.modalButton, styles.cancelButton]}
                onPress={cancelDelete}
              >
                <Text style={styles.cancelButtonText}>İptal</Text>
              </TouchableOpacity>
              <TouchableOpacity 
                style={[styles.modalButton, styles.modalDeleteButton]}
                onPress={confirmDelete}
              >
                <Text style={styles.modalDeleteButtonText}>Sil</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      <View style={styles.header}>
        <TouchableOpacity 
          style={styles.backButton}
          onPress={() => navigation.goBack()}
        >
          <Text style={styles.backButtonText}>← </Text>
        </TouchableOpacity>
        <View style={styles.headerTitleContainer}>
          <Image 
            source={require('../assets/cogni-coach-icon.png')} 
            style={styles.headerIcon}
            resizeMode="contain"
          />
          <Text style={styles.headerTitle}>Tüm Analizlerim</Text>
        </View>
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
            colors={['rgb(96, 187, 202)']}
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
                <View style={styles.titleRow}>
                  <TouchableOpacity
                    onPress={() => analysis.status === 'completed' ? viewAnalysis(analysis) : null}
                    disabled={analysis.status !== 'completed'}
                  >
                    <Text style={[styles.analysisType, analysis.status === 'completed' && styles.clickableTitle]}>
                      {getAnalysisTypeLabel(analysis.analysis_type)}
                    </Text>
                  </TouchableOpacity>
                  <Text style={styles.dateText}> • {formatDate(analysis.created_at)}</Text>
                </View>
                <View style={styles.statusRow}>
                  <View style={styles.statusContainer}>
                    <Text style={[styles.statusIcon, { color: getStatusColor(analysis.status) }]}>
                      {analysis.status === 'completed' ? '✓ ' : analysis.status === 'error' ? '✕ ' : '⟳ '}
                    </Text>
                    <Text style={[styles.statusText, { color: getStatusColor(analysis.status) }]}>
                      {getStatusText(analysis.status)}
                    </Text>
                  </View>
                  <TouchableOpacity
                    style={styles.deleteButton}
                    onPress={() => deleteAnalysis(analysis)}
                  >
                    <Text style={styles.deleteIconText}>🗑</Text>
                  </TouchableOpacity>
                </View>
              </View>

              {analysis.status === 'processing' && (
                <View style={styles.processingContainer}>
                  <View style={styles.processingHeader}>
                    <ActivityIndicator size="small" color="#64748B" style={styles.processingSpinner} />
                    <Text style={styles.processingTitle}>Analiziniz İşleniyor</Text>
                  </View>
                  <Text style={styles.processingText}>
                    Gönderdiğiniz form özel eğitilmiş, yüksek seviye reasoning yapan yapay zeka tarafından detaylı inceleniyor. 
                    Anlatılarınız ve verdiğiniz cevaplar arasındaki bağlantılar analiz ediliyor ve en önde gelen psikometrik tekniklerle değerlendiriliyor.
                  </Text>
                  <Text style={styles.processingTime}>Lütfen bekleyin (2-4 dk)</Text>
                </View>
              )}
              
              {analysis.status === 'error' && (
                <View style={styles.errorContainer}>
                  <Text style={styles.errorText}>
                    {analysis.error_message || 'Analiz sırasında bir hata oluştu'}
                  </Text>
                </View>
              )}
            </View>
          ))
        )}
      </ScrollView>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  webWrapper: Platform.select({
    web: {
      maxWidth: 999,
      width: '100%',
      alignSelf: 'center',
      flex: 1,
    },
    default: {
      flex: 1,
    },
  }),
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
    paddingVertical: 10,
    backgroundColor: '#FFFFFF',
  },
  headerTitleContainer: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerIcon: {
    width: 24,
    height: 24,
    marginRight: 8,
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: '#1E293B',
  },
  backButton: {
    width: 40,
    height: 40,
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 3,
  },
  backButtonText: {
    fontSize: 24,
    color: '#1E293B',
    fontWeight: 'bold',
  },
  mainEditButton: {
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E5E7EB',
    paddingVertical: 10,
    paddingHorizontal: 16,
    marginHorizontal: 16,
    marginTop: 16,
    marginBottom: 8,
    borderRadius: 3,
    alignItems: 'center',
    alignSelf: 'center',
  },
  mainEditButtonText: {
    color: '#1E293B',
    fontSize: 14,
    fontWeight: '500',
  },
  scrollView: {
    flex: 1,
    paddingHorizontal: 16,
    paddingVertical: 16,
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
    paddingVertical: 10,
    paddingHorizontal: 16,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 3,
  },
  newAnalysisButtonText: {
    fontSize: 14,
    color: '#1E293B',
    fontWeight: '500',
  },
  analysisCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    paddingHorizontal: 16,
    paddingVertical: 12,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
    minHeight: 24,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  analysisType: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1E293B',
  },
  clickableTitle: {
    color: 'rgb(96, 187, 202)',
  },
  statusRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    position: 'relative',
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
  deleteButton: {
    padding: 4,
    marginLeft: 8,
    backgroundColor: 'transparent',
  },
  deleteIcon: {
    width: 16,
    height: 16,
  },
  deleteIconText: {
    fontSize: 18,
    color: '#6B7280',
  },
  dateText: {
    fontSize: 12,
    color: '#94A3B8',
    marginLeft: 4,
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
  processingContainer: {
    marginTop: 12,
    padding: 12,
    backgroundColor: '#F8FAFC',
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  processingHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  processingSpinner: {
    marginRight: 8,
  },
  processingTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1E293B',
  },
  processingText: {
    fontSize: 13,
    lineHeight: 18,
    color: '#64748B',
    marginBottom: 8,
  },
  processingTime: {
    fontSize: 12,
    color: '#94A3B8',
    fontWeight: '500',
    fontStyle: 'italic',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    padding: 24,
    width: '90%',
    maxWidth: 400,
    alignItems: 'center',
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1E293B',
    marginBottom: 12,
  },
  modalText: {
    fontSize: 14,
    color: '#64748B',
    textAlign: 'center',
    marginBottom: 24,
  },
  modalButtons: {
    flexDirection: 'row',
    gap: 12,
  },
  modalButton: {
    paddingVertical: 10,
    paddingHorizontal: 24,
    borderRadius: 3,
    minWidth: 100,
    alignItems: 'center',
  },
  cancelButton: {
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  cancelButtonText: {
    color: '#64748B',
    fontSize: 14,
    fontWeight: '500',
  },
  modalDeleteButton: {
    backgroundColor: '#DC2626',
  },
  modalDeleteButtonText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '500',
  },
});