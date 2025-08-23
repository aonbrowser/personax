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
} from 'react-native';
import Markdown from 'react-native-markdown-display';
import { downloadPDF } from '../utils/pdfGenerator';

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
    };
  };
}

export default function AnalysisResultScreen({ navigation, route }: AnalysisResultScreenProps) {
  // Support both old format (result.markdown) and new format (direct markdown)
  const markdown = route.params?.result?.markdown || route.params?.markdown;
  const analysisType = route.params?.analysisType || 'self';
  const scrollViewRef = useRef<ScrollView>(null);
  const [showScrollTop, setShowScrollTop] = useState(false);
  
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
        const success = await downloadPDF(markdown);
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
  
  const handleCopyToClipboard = () => {
    if (Platform.OS === 'web') {
      navigator.clipboard.writeText(markdown).then(() => {
        Alert.alert('Başarılı', 'Analiz metni panoya kopyalandı!');
      }).catch(() => {
        Alert.alert('Hata', 'Metin kopyalanamadı.');
      });
    } else {
      Alert.alert('Bilgi', 'Bu özellik sadece web versiyonunda kullanılabilir.');
    }
  };
  
  const handlePrint = () => {
    if (Platform.OS === 'web') {
      // Create a print-friendly version
      const printWindow = window.open('', '_blank');
      if (printWindow) {
        const htmlContent = `
          <!DOCTYPE html>
          <html lang="tr">
          <head>
            <meta charset="UTF-8">
            <title>Cogni Coach - Analiz Raporu</title>
            <style>
              @page {
                size: A4;
                margin: 15mm;
              }
              body {
                font-family: Arial, sans-serif;
                font-size: 11pt;
                line-height: 1.6;
                color: #000;
                max-width: 210mm;
                margin: 0 auto;
                padding: 20px;
              }
              .header {
                text-align: center;
                margin-bottom: 30px;
                padding-bottom: 20px;
                border-bottom: 2px solid #e5e7eb;
              }
              .header h1 {
                color: #60BBCA;
                font-size: 24pt;
                margin: 0 0 10px 0;
              }
              .header h2 {
                color: #2d3748;
                font-size: 18pt;
                margin: 0 0 10px 0;
              }
              .header .date {
                color: #718096;
                font-size: 10pt;
              }
              h1 {
                font-size: 18pt;
                color: #1a202c;
                margin-top: 20pt;
                margin-bottom: 10pt;
                page-break-after: avoid;
              }
              h2 {
                font-size: 14pt;
                color: #2d3748;
                margin-top: 16pt;
                margin-bottom: 8pt;
                page-break-after: avoid;
              }
              h3 {
                font-size: 12pt;
                color: #4a5568;
                margin-top: 12pt;
                margin-bottom: 6pt;
                page-break-after: avoid;
              }
              p {
                margin: 8pt 0;
                text-align: justify;
                orphans: 3;
                widows: 3;
                page-break-inside: avoid;
              }
              ul, ol {
                margin: 8pt 0;
                padding-left: 20pt;
                page-break-inside: avoid;
              }
              li {
                margin: 4pt 0;
                page-break-inside: avoid;
              }
              strong {
                font-weight: bold;
                color: #1a202c;
              }
              .footer {
                margin-top: 40px;
                padding-top: 20px;
                border-top: 1px solid #e5e7eb;
                text-align: center;
                color: #718096;
                font-size: 9pt;
              }
              @media print {
                .no-print {
                  display: none !important;
                }
              }
            </style>
          </head>
          <body>
            <div class="header">
              <h1>Cogni Coach</h1>
              <h2>Kişisel Analiz Raporu</h2>
              <div class="date">${new Date().toLocaleDateString('tr-TR', {
                year: 'numeric',
                month: 'long',
                day: 'numeric'
              })}</div>
            </div>
            <div class="content">
              ${markdown
                .replace(/^# (.*?)$/gm, '<h1>$1</h1>')
                .replace(/^## (.*?)$/gm, '<h2>$1</h2>')
                .replace(/^### (.*?)$/gm, '<h3>$1</h3>')
                .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
                .replace(/\*(.*?)\*/g, '<em>$1</em>')
                .replace(/^\- (.*?)$/gm, '<li>$1</li>')
                .replace(/(<li>.*?<\/li>\n?)+/g, '<ul>$&</ul>')
                .replace(/\n\n/g, '</p><p>')
                .replace(/^([^<])/gm, '<p>$1')
                .replace(/([^>])$/gm, '$1</p>')
                .replace(/<p><\/p>/g, '')
                .replace(/<p>(<h[123]>)/g, '$1')
                .replace(/(<\/h[123]>)<\/p>/g, '$1')
              }
            </div>
            <div class="footer">
              <p>© ${new Date().getFullYear()} Cogni Coach - Tüm hakları saklıdır.</p>
              <p>Bu rapor kişisel kullanım içindir.</p>
            </div>
            <script>
              window.onload = function() {
                window.print();
                window.onafterprint = function() {
                  window.close();
                };
              };
            </script>
          </body>
          </html>
        `;
        
        printWindow.document.write(htmlContent);
        printWindow.document.close();
      }
    } else {
      Alert.alert('Bilgi', 'Yazdırma özelliği sadece web versiyonunda kullanılabilir.');
    }
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
      
      <View style={{ flex: 1 }}>
        {Platform.OS === 'web' && (
          <View style={styles.actionButtonsContainer}>
            <TouchableOpacity 
              style={styles.actionButton} 
              onPress={handleDownloadPDF}
            >
              <Text style={styles.actionButtonIcon}>📄</Text>
              <Text style={styles.actionButtonText}>PDF İndir</Text>
            </TouchableOpacity>
            
            <TouchableOpacity 
              style={styles.actionButton} 
              onPress={handleCopyToClipboard}
            >
              <Text style={styles.actionButtonIcon}>📋</Text>
              <Text style={styles.actionButtonText}>Metni Kopyala</Text>
            </TouchableOpacity>
            
            <TouchableOpacity 
              style={styles.actionButton} 
              onPress={handlePrint}
            >
              <Text style={styles.actionButtonIcon}>🖨️</Text>
              <Text style={styles.actionButtonText}>Yazdır</Text>
            </TouchableOpacity>
          </View>
        )}
        
        <ScrollView 
          ref={scrollViewRef}
          style={styles.scrollView}
          showsVerticalScrollIndicator={false}
          onScroll={handleScroll}
          scrollEventThrottle={16}
          contentContainerStyle={styles.scrollContent}
        >
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
      </View>
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
    marginBottom: 16,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    paddingVertical: 10,
    paddingHorizontal: 16,
    marginBottom: 8,
  },
  actionButtonIcon: {
    fontSize: 18,
    marginRight: 8,
  },
  actionButtonText: {
    fontSize: 14,
    fontWeight: '500',
    color: '#1E293B',
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
});