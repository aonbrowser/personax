import React, { useState, useRef, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  Alert,
  Platform,
  Image,
  ActivityIndicator,
} from 'react-native';
import Markdown from 'react-native-markdown-display';
import { generatePDFFromBackend } from '../utils/backendPdfExport';
import { API_URL } from '../config';

interface AnalysisResultScreenProps {
  navigation: any;
  route: {
    params: {
      result?: {
        markdown?: string;
        analysisId: string;
      };
      markdown?: string;
      analysisType?: string;
      analysisId?: string;
      userEmail?: string;
    };
  };
}

export default function AnalysisResultScreen({ navigation, route }: AnalysisResultScreenProps) {
  // Support both old format (result.markdown) and new format (direct markdown)
  const markdown = route.params?.result?.markdown || route.params?.markdown;
  const analysisType = route.params?.analysisType || 'self';
  const analysisId = route.params?.analysisId;
  const userEmail = route.params?.userEmail;
  const scrollViewRef = useRef<ScrollView>(null);
  const [showScrollTop, setShowScrollTop] = useState(false);
  const [userInfo, setUserInfo] = useState<any>(null);
  const [loadingUserInfo, setLoadingUserInfo] = useState(true);
  
  // Parse markdown into blocks by main headings (## )
  const parseMarkdownIntoBlocks = (text: string) => {
    if (!text) return [];
    
    // Split by ## headings (main sections)
    const sections = text.split(/(?=^## )/gm);
    
    return sections.filter(section => section.trim()).map((section, index) => ({
      id: `block-${index}`,
      content: section.trim()
    }));
  };
  
  const blocks = parseMarkdownIntoBlocks(markdown);
  
  // Fetch user info and form data when component mounts
  useEffect(() => {
    const fetchUserInfo = async () => {
      if (!analysisId || !userEmail) {
        console.log('No analysisId or userEmail, skipping user info fetch');
        setLoadingUserInfo(false);
        return;
      }
      
      try {
        const response = await fetch(`${API_URL}/v1/user/analyses/${analysisId}`, {
          headers: {
            'x-user-email': userEmail,
          },
        });
        
        if (response.ok) {
          const data = await response.json();
          const analysis = data.analysis;
          
          // Extract user info from form1_data
          if (analysis && analysis.form1_data) {
            const form1 = analysis.form1_data;
            const userDetails = {
              email: userEmail,
              age: form1.F1_AGE || 'Belirtilmemiş',
              gender: form1.F1_GENDER === '0' ? 'Erkek' : 
                      form1.F1_GENDER === '1' ? 'Kadın' : 
                      form1.F1_GENDER === '2' ? 'Diğer' : 'Belirtilmemiş',
              createdAt: analysis.created_at
            };
            setUserInfo(userDetails);
          }
        }
      } catch (error) {
        console.error('Error fetching user info:', error);
      }
      
      setLoadingUserInfo(false);
    };
    
    fetchUserInfo();
  }, [analysisId, userEmail]);
  
  const handleScroll = (event: any) => {
    const offsetY = event.nativeEvent.contentOffset.y;
    setShowScrollTop(offsetY > 100);
  };
  
  const scrollToTop = () => {
    scrollViewRef.current?.scrollTo({ y: 0, animated: true });
  };
  
  const handleDownloadPDF = async () => {
    console.log('PDF Download button clicked');
    
    if (Platform.OS === 'web') {
      try {
        const success = await generatePDFFromBackend(markdown);
        if (success) {
          Alert.alert('Başarılı', 'PDF başarıyla indirildi.');
        } else {
          Alert.alert('Hata', 'PDF oluşturulurken bir hata oluştu.');
        }
      } catch (error) {
        console.error('PDF creation error:', error);
        Alert.alert('Hata', 'PDF oluşturulurken bir hata oluştu.');
      }
    } else {
      Alert.alert('Bilgi', 'PDF indirme sadece web versiyonunda kullanılabilir.');
    }
  };
  
  const handleDiscussWithCoach = () => {
    // TODO: Navigate to coach discussion screen when implemented
    Alert.alert(
      'Cogni Coach', 
      'Coach tartışma özelliği yakında eklenecek!',
      [{ text: 'Tamam', style: 'default' }]
    );
    // Future implementation:
    // navigation.navigate('CoachChat', {
    //   analysisMarkdown: markdown,
    //   analysisType: analysisType
    // });
  };
  
  
  // Custom markdown styles
  const markdownStyles = {
    body: {
      fontSize: 14,
      color: '#4A5568',
      lineHeight: 22,
    },
    heading1: {
      fontSize: 22,
      fontWeight: '700',
      color: '#1A202C',
      marginTop: 16,
      marginBottom: 12,
    },
    heading2: {
      fontSize: 18,
      fontWeight: '600',
      color: '#2D3748',
      marginTop: 14,
      marginBottom: 10,
    },
    heading3: {
      fontSize: 16,
      fontWeight: '600',
      color: '#4A5568',
      marginTop: 12,
      marginBottom: 8,
    },
    paragraph: {
      fontSize: 14,
      color: '#4A5568',
      lineHeight: 22,
      marginBottom: 10,
    },
    strong: {
      fontWeight: '600',
      color: '#2D3748',
    },
    listItem: {
      fontSize: 14,
      color: '#4A5568',
      marginBottom: 4,
    },
    bullet_list: {
      marginLeft: 10,
    },
    ordered_list: {
      marginLeft: 10,
    },
  };
  
  if (!markdown) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>Analiz bulunamadı.</Text>
          <TouchableOpacity 
            style={styles.backButton} 
            onPress={() => navigation.goBack()}
          >
            <Text style={styles.backButtonText}>Geri Dön</Text>
          </TouchableOpacity>
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
        <View style={styles.headerTitleContainer}>
          <Image 
            source={require('../assets/images/cogni-coach-icon.png')} 
            style={styles.headerIcon}
            resizeMode="contain"
          />
          <Text style={styles.headerTitle}>Analiz Raporu</Text>
        </View>
        <View style={styles.headerSpacer} />
      </View>
      
      <ScrollView 
          ref={scrollViewRef}
          style={styles.scrollView}
          showsVerticalScrollIndicator={false}
          onScroll={handleScroll}
          scrollEventThrottle={16}
          contentContainerStyle={styles.scrollContent}
        >
          {/* User Info Header - Shows who this report belongs to */}
          {userInfo && (
            <View style={styles.userInfoContainer}>
              <Text style={styles.userInfoTitle}>📋 Rapor Bilgileri</Text>
              <View style={styles.userInfoContent}>
                <View style={styles.userInfoRow}>
                  <Text style={styles.userInfoLabel}>Email:</Text>
                  <Text style={styles.userInfoValue}>{userInfo.email}</Text>
                </View>
                <View style={styles.userInfoRow}>
                  <Text style={styles.userInfoLabel}>Yaş:</Text>
                  <Text style={styles.userInfoValue}>{userInfo.age}</Text>
                </View>
                <View style={styles.userInfoRow}>
                  <Text style={styles.userInfoLabel}>Cinsiyet:</Text>
                  <Text style={styles.userInfoValue}>{userInfo.gender}</Text>
                </View>
                <View style={styles.userInfoRow}>
                  <Text style={styles.userInfoLabel}>Oluşturulma:</Text>
                  <Text style={styles.userInfoValue}>
                    {userInfo.createdAt ? new Date(userInfo.createdAt).toLocaleString('tr-TR') : 'Bilinmiyor'}
                  </Text>
                </View>
              </View>
            </View>
          )}
          
          {/* Loading indicator for user info */}
          {loadingUserInfo && (
            <View style={styles.userInfoContainer}>
              <ActivityIndicator size="small" color="#4299E1" />
              <Text style={styles.loadingText}>Kullanıcı bilgileri yükleniyor...</Text>
            </View>
          )}
          
          {/* Action buttons inside scrollview so they scroll with content */}
          <View style={styles.actionButtonsContainer}>
            <TouchableOpacity 
              style={styles.actionButton} 
              onPress={handleDownloadPDF}
            >
              <View style={styles.buttonContent}>
                <Image 
                  source={require('../assets/images/pdf.png')} 
                  style={styles.pdfIcon}
                  resizeMode="contain"
                />
                <Text style={styles.actionButtonText}>PDF OLARAK İNDİR</Text>
              </View>
            </TouchableOpacity>
            
            <TouchableOpacity 
              style={[styles.actionButton, styles.coachButton]} 
              onPress={handleDiscussWithCoach}
            >
              <View style={styles.buttonContent}>
                <Text style={styles.actionButtonIcon}>💬</Text>
                <Text style={[styles.actionButtonText, styles.coachButtonText]}>Cogni Coach ile Tartış</Text>
              </View>
            </TouchableOpacity>
          </View>
          
          {blocks.map((block, index) => (
            <View key={block.id}>
              <View style={styles.markdownContainer}>
                <Markdown style={markdownStyles}>
                  {block.content}
                </Markdown>
              </View>
              {index < blocks.length - 1 && <View style={styles.blockSpacing} />}
            </View>
          ))}
        </ScrollView>
        
      {Platform.OS !== 'web' && showScrollTop && (
        <TouchableOpacity 
          style={styles.mobileScrollButton}
          onPress={scrollToTop}
        >
          <Text style={styles.scrollToTopIcon}>↑</Text>
        </TouchableOpacity>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8F9FA',
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
    ...Platform.select({
      web: {
        boxShadow: '0px 1px 3px rgba(0, 0, 0, 0.05)',
      },
      default: {
        elevation: 2,
      },
    }),
  },
  backButton: {
    padding: 8,
  },
  backArrow: {
    fontSize: 24,
    color: '#4A5568',
    fontWeight: '600',
  },
  headerTitleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
    justifyContent: 'center',
  },
  headerIcon: {
    width: 28,
    height: 28,
    marginRight: 8,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1E293B',
  },
  headerSpacer: {
    width: 40,
  },
  backButtonText: {
    color: '#4299E1',
    fontSize: 16,
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    padding: 16,
    paddingBottom: 40,
  },
  sectionContainer: {
    marginBottom: 12,
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  sectionHeader: {
    backgroundColor: 'rgb(45, 55, 72)',
    paddingVertical: 10,
    paddingHorizontal: 14,
  },
  sectionTitle: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  sectionContent: {
    padding: 14,
  },
  markdownContainer: {
    backgroundColor: 'rgb(247, 247, 247)',
    borderRadius: 3,
    padding: 14,
    ...Platform.select({
      web: {
        boxShadow: '0px 2px 4px rgba(0, 0, 0, 0.05)',
      },
      default: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.05,
        shadowRadius: 4,
        elevation: 2,
      },
    }),
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  errorText: {
    fontSize: 16,
    color: '#718096',
  },
  actionButtonsContainer: {
    flexDirection: 'column',
    marginBottom: 20,
    gap: 10,
    width: '100%',
  },
  actionButton: {
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    paddingVertical: 14,
    paddingHorizontal: 20,
    width: '100%',
    alignItems: 'center',
    justifyContent: 'center',
    ...Platform.select({
      web: {
        cursor: 'pointer',
        transition: 'all 0.2s ease',
      },
      default: {
        elevation: 1,
      },
    }),
  },
  buttonContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  coachButton: {
    backgroundColor: 'rgb(66, 153, 225)',
    borderColor: 'rgb(66, 153, 225)',
  },
  actionButtonIcon: {
    fontSize: 18,
    marginRight: 8,
  },
  pdfIcon: {
    width: 20,
    height: 20,
    marginRight: 8,
  },
  actionButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1E293B',
  },
  coachButtonText: {
    color: '#FFFFFF',
  },
  blockSpacing: {
    marginTop: 25,
  },
  mobileScrollButton: {
    position: 'absolute',
    bottom: 20,
    right: 20,
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: '#000000',
    justifyContent: 'center',
    alignItems: 'center',
    ...Platform.select({
      web: {
        boxShadow: '0px 2px 4px rgba(0, 0, 0, 0.25)',
      },
      default: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.25,
        shadowRadius: 4,
        elevation: 8,
      },
    }),
  },
  scrollToTopIcon: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  userInfoContainer: {
    backgroundColor: '#F0F9FF',
    borderRadius: 3,
    padding: 16,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#3B82F6',
  },
  userInfoTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1E40AF',
    marginBottom: 12,
  },
  userInfoContent: {
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    padding: 12,
  },
  userInfoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 6,
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  userInfoLabel: {
    fontSize: 14,
    color: '#6B7280',
    fontWeight: '500',
  },
  userInfoValue: {
    fontSize: 14,
    color: '#111827',
    fontWeight: '600',
  },
  loadingText: {
    fontSize: 14,
    color: '#6B7280',
    marginTop: 8,
    textAlign: 'center',
  },
});