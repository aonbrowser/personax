import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  Alert,
  ActivityIndicator,
  Platform,
} from 'react-native';
import Markdown from 'react-native-markdown-display';
import { API_URL } from '../config';

// Conditional imports for web platform
let jsPDF: any = null;

if (Platform.OS === 'web') {
  try {
    const jsPDFModule = require('jspdf');
    jsPDF = jsPDFModule.jsPDF || jsPDFModule.default || jsPDFModule;
    
    // Import the autoTable plugin for better text handling
    require('jspdf-autotable');
    
    console.log('PDF library loaded successfully');
  } catch (e) {
    console.error('Error loading PDF library:', e);
  }
}

interface AnalysisResultScreenProps {
  navigation: any;
  route: {
    params: {
      analysisId?: string;
      analysisData?: any;
      markdown?: string;
      blocks?: any[];
    };
  };
}

export default function AnalysisResultScreen({ navigation, route }: AnalysisResultScreenProps) {
  const [analysisData, setAnalysisData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [markdown, setMarkdown] = useState('');
  const [blocks, setBlocks] = useState<any[]>([]);
  const scrollViewRef = useRef<ScrollView>(null);
  const [showScrollTop, setShowScrollTop] = useState(false);

  useEffect(() => {
    if (route.params?.analysisData || route.params?.markdown) {
      setAnalysisData(route.params.analysisData);
      setMarkdown(route.params.markdown || '');
      setBlocks(route.params.blocks || []);
      setLoading(false);
    } else if (route.params?.analysisId) {
      fetchAnalysis(route.params.analysisId);
    } else {
      setLoading(false);
    }
  }, [route.params]);

  const fetchAnalysis = async (analysisId: string) => {
    try {
      const response = await fetch(`${API_URL}/v1/user/analyses/${analysisId}`, {
        headers: {
          'x-user-email': 'test@test.com',
        },
      });
      const data = await response.json();
      setAnalysisData(data);
      setMarkdown(data.result_markdown || '');
      setBlocks(data.result_blocks || []);
    } catch (error) {
      console.error('Error fetching analysis:', error);
      Alert.alert('Hata', 'Analiz yüklenemedi');
    } finally {
      setLoading(false);
    }
  };
  
  const handleDownloadPDF = async () => {
    console.log('PDF Download button clicked');
    console.log('Platform:', Platform.OS);
    console.log('jsPDF available:', !!jsPDF);
    
    if (Platform.OS === 'web') {
      try {
        // Check if library is available
        if (!jsPDF) {
          console.error('PDF library not loaded');
          Alert.alert('Hata', 'PDF kütüphanesi yüklenemedi. Sayfayı yenileyin.');
          return;
        }
        
        console.log('Creating PDF with selectable text...');
        
        // Create PDF instance
        let pdf;
        if (typeof jsPDF === 'function') {
          pdf = new jsPDF({
            orientation: 'portrait',
            unit: 'mm',
            format: 'a4',
          });
        } else if (jsPDF && jsPDF.jsPDF) {
          pdf = new jsPDF.jsPDF({
            orientation: 'portrait',
            unit: 'mm',
            format: 'a4',
          });
        } else {
          throw new Error('jsPDF not properly loaded');
        }
        
        // Set font
        pdf.setFont('helvetica');
        
        // Add header with gradient background (as rectangle)
        pdf.setFillColor(102, 126, 234); // Purple color
        pdf.rect(0, 0, 210, 40, 'F');
        
        // Add header text
        pdf.setTextColor(255, 255, 255);
        pdf.setFontSize(24);
        pdf.text('Cogni Coach', 105, 15, { align: 'center' });
        pdf.setFontSize(16);
        pdf.text('Kişisel Analiz Raporu', 105, 25, { align: 'center' });
        pdf.setFontSize(12);
        pdf.text(new Date().toLocaleDateString('tr-TR', { 
          year: 'numeric', 
          month: 'long', 
          day: 'numeric' 
        }), 105, 33, { align: 'center' });
        
        // Reset text color for content
        pdf.setTextColor(0, 0, 0);
        
        // Process markdown content into text
        let yPosition = 50;
        const pageHeight = pdf.internal.pageSize.height;
        const pageWidth = pdf.internal.pageSize.width;
        const marginLeft = 20;
        const marginRight = 20;
        const contentWidth = pageWidth - marginLeft - marginRight;
        
        // Parse markdown into structured content
        const lines = markdown.split('\n');
        
        for (const line of lines) {
          // Check if we need a new page
          if (yPosition > pageHeight - 30) {
            pdf.addPage();
            yPosition = 20;
          }
          
          // Process different markdown elements
          if (line.startsWith('# ')) {
            // H1
            pdf.setFontSize(18);
            pdf.setFont('helvetica', 'bold');
            const text = line.substring(2).trim();
            const splitText = pdf.splitTextToSize(text, contentWidth);
            pdf.text(splitText, marginLeft, yPosition);
            yPosition += splitText.length * 8;
          } else if (line.startsWith('## ')) {
            // H2
            pdf.setFontSize(16);
            pdf.setFont('helvetica', 'bold');
            const text = line.substring(3).trim();
            const splitText = pdf.splitTextToSize(text, contentWidth);
            pdf.text(splitText, marginLeft, yPosition);
            yPosition += splitText.length * 7;
          } else if (line.startsWith('### ')) {
            // H3
            pdf.setFontSize(14);
            pdf.setFont('helvetica', 'bold');
            const text = line.substring(4).trim();
            const splitText = pdf.splitTextToSize(text, contentWidth);
            pdf.text(splitText, marginLeft, yPosition);
            yPosition += splitText.length * 6;
          } else if (line.startsWith('- ')) {
            // Bullet point
            pdf.setFontSize(12);
            pdf.setFont('helvetica', 'normal');
            const text = '• ' + line.substring(2).trim();
            const splitText = pdf.splitTextToSize(text, contentWidth - 5);
            pdf.text(splitText, marginLeft + 5, yPosition);
            yPosition += splitText.length * 5;
          } else if (line.trim() !== '') {
            // Regular paragraph
            pdf.setFontSize(12);
            pdf.setFont('helvetica', 'normal');
            // Remove bold markdown markers
            const text = line.replace(/\*\*(.*?)\*\*/g, '$1').trim();
            const splitText = pdf.splitTextToSize(text, contentWidth);
            pdf.text(splitText, marginLeft, yPosition);
            yPosition += splitText.length * 5;
          } else {
            // Empty line - add spacing
            yPosition += 3;
          }
        }
        
        // Add footer on last page
        pdf.setFontSize(10);
        pdf.setTextColor(108, 117, 125);
        pdf.text(`© ${new Date().getFullYear()} Cogni Coach - Tüm hakları saklıdır.`, 105, pageHeight - 15, { align: 'center' });
        pdf.text('Bu rapor kişisel kullanım içindir.', 105, pageHeight - 10, { align: 'center' });
        
        // Save the PDF
        const fileName = `Cogni_Coach_Analiz_${new Date().toISOString().split('T')[0]}.pdf`;
        pdf.save(fileName);
        
        console.log('PDF created successfully with selectable text');
        
      } catch (error: any) {
        console.error('PDF generation error:', error);
        Alert.alert('Hata', `PDF oluşturulurken bir hata oluştu: ${error.message}`);
      }
    } else {
      Alert.alert('PDF İndirme', 'PDF indirme özelliği mobil cihazlarda henüz mevcut değil.');
    }
  };

  const handleAskCoach = () => {
    navigation.navigate('Coach', {
      analysisData: analysisData,
      context: markdown,
    });
  };

  const handleDeleteAnalysis = async () => {
    if (!route.params?.analysisId) return;
    
    Alert.alert(
      'Analizi Sil',
      'Bu analizi silmek istediğinizden emin misiniz?',
      [
        { text: 'İptal', style: 'cancel' },
        {
          text: 'Sil',
          style: 'destructive',
          onPress: async () => {
            try {
              const response = await fetch(`${API_URL}/v1/user/analyses/${route.params.analysisId}`, {
                method: 'DELETE',
                headers: {
                  'x-user-email': 'test@test.com',
                },
              });
              
              if (response.ok) {
                Alert.alert('Başarılı', 'Analiz silindi');
                navigation.goBack();
              } else {
                Alert.alert('Hata', 'Analiz silinemedi');
              }
            } catch (error) {
              console.error('Error deleting analysis:', error);
              Alert.alert('Hata', 'Analiz silinirken bir hata oluştu');
            }
          },
        },
      ],
    );
  };

  const scrollToTop = () => {
    scrollViewRef.current?.scrollTo({ y: 0, animated: true });
  };

  const handleScroll = (event: any) => {
    const offsetY = event.nativeEvent.contentOffset.y;
    setShowScrollTop(offsetY > 300);
  };

  const parseMarkdownIntoBlocks = (markdown: string) => {
    if (!markdown) return [];
    
    const blocks = [];
    const lines = markdown.split('\n');
    let currentBlock: any = null;
    
    for (const line of lines) {
      if (line.startsWith('# ')) {
        if (currentBlock) blocks.push(currentBlock);
        currentBlock = { type: 'h1', content: line.substring(2).trim(), children: [] };
      } else if (line.startsWith('## ')) {
        if (currentBlock) blocks.push(currentBlock);
        currentBlock = { type: 'h2', content: line.substring(3).trim(), children: [] };
      } else if (line.startsWith('### ')) {
        if (currentBlock && currentBlock.type !== 'h2') {
          blocks.push(currentBlock);
          currentBlock = null;
        }
        const h3Block = { type: 'h3', content: line.substring(4).trim() };
        if (currentBlock && currentBlock.type === 'h2') {
          currentBlock.children.push(h3Block);
        } else {
          blocks.push(h3Block);
        }
      } else if (line.startsWith('- ')) {
        const listItem = { type: 'li', content: line.substring(2).trim() };
        if (currentBlock && (currentBlock.type === 'h2' || currentBlock.type === 'h3')) {
          currentBlock.children.push(listItem);
        } else {
          blocks.push(listItem);
        }
      } else if (line.trim() !== '') {
        const paragraph = { type: 'p', content: line.trim() };
        if (currentBlock && (currentBlock.type === 'h2' || currentBlock.type === 'h3')) {
          currentBlock.children.push(paragraph);
        } else {
          blocks.push(paragraph);
        }
      }
    }
    
    if (currentBlock) blocks.push(currentBlock);
    return blocks;
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="rgb(96, 187, 202)" />
          <Text style={styles.loadingText}>Analiz yükleniyor...</Text>
        </View>
      </SafeAreaView>
    );
  }

  if (!markdown && !blocks.length) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backButton}>
            <Text style={styles.backArrow}>←</Text>
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Analiz Sonucu</Text>
          <View style={styles.headerSpacer} />
        </View>
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyText}>Analiz verisi bulunamadı</Text>
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
        <Text style={styles.headerTitle}>Analiz Sonucu</Text>
        <TouchableOpacity onPress={handleDeleteAnalysis} style={styles.deleteButton}>
          <Text style={styles.deleteIcon}>🗑</Text>
        </TouchableOpacity>
      </View>

      <ScrollView 
        ref={scrollViewRef}
        style={styles.content} 
        contentContainerStyle={styles.contentContainer}
        onScroll={handleScroll}
        scrollEventThrottle={16}>
        <View style={styles.actionButtonsContainer}>
          <TouchableOpacity style={styles.actionButton} onPress={handleDownloadPDF}>
            <Text style={styles.actionButtonIcon}>📄</Text>
            <Text style={styles.actionButtonText}>PDF Olarak İndir</Text>
          </TouchableOpacity>
          
          <TouchableOpacity style={styles.actionButton} onPress={handleAskCoach}>
            <Text style={styles.actionButtonIcon}>💬</Text>
            <Text style={styles.actionButtonText}>Koça Sor</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.markdownContainer}>
          <Markdown style={markdownStyles}>
            {markdown}
          </Markdown>
        </View>
      </ScrollView>

      {showScrollTop && (
        <TouchableOpacity 
          style={styles.scrollTopButton}
          onPress={scrollToTop}
          activeOpacity={0.8}>
          <Text style={styles.scrollTopIcon}>↑</Text>
        </TouchableOpacity>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  // ... (keeping the same styles as before)
  container: {
    flex: 1,
    backgroundColor: '#F7F9FC',
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
  deleteButton: {
    width: 40,
    height: 40,
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 3,
    backgroundColor: '#F8FAFC',
  },
  deleteIcon: {
    fontSize: 18,
    color: '#6B7280',
  },
  content: {
    flex: 1,
  },
  contentContainer: {
    paddingHorizontal: 16,
    paddingBottom: 50,
  },
  actionButtonsContainer: {
    flexDirection: 'row',
    gap: 12,
    marginVertical: 16,
  },
  actionButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    gap: 8,
  },
  actionButtonIcon: {
    fontSize: 20,
  },
  actionButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1E293B',
  },
  markdownContainer: {
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    padding: 20,
    marginBottom: 20,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 20,
    fontSize: 16,
    color: '#64748B',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyText: {
    fontSize: 16,
    color: '#64748B',
  },
  scrollTopButton: {
    position: 'absolute',
    bottom: 30,
    right: 20,
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: 'rgb(96, 187, 202)',
    justifyContent: 'center',
    alignItems: 'center',
    ...Platform.select({
      web: {
        boxShadow: '0 2px 8px rgba(0,0,0,0.15)',
      },
      default: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.25,
        shadowRadius: 3.84,
        elevation: 5,
      }
    }),
  },
  scrollTopIcon: {
    fontSize: 24,
    color: '#FFFFFF',
    fontWeight: 'bold',
  },
});

const markdownStyles = StyleSheet.create({
  body: {
    fontSize: 16,
    lineHeight: 32,
    color: 'rgb(0, 0, 0)',
  },
  heading1: {
    fontSize: 28,
    fontWeight: 'bold',
    color: 'rgb(0, 0, 0)',
    marginVertical: 16,
    lineHeight: 14,
  },
  heading2: {
    fontSize: 24,
    fontWeight: 'bold',
    color: 'rgb(0, 0, 0)',
    marginVertical: 14,
    lineHeight: 14,
  },
  heading3: {
    fontSize: 20,
    fontWeight: 'bold',
    color: 'rgb(0, 0, 0)',
    marginVertical: 12,
    lineHeight: 14,
  },
  paragraph: {
    fontSize: 16,
    lineHeight: 38,
    color: 'rgb(0, 0, 0)',
    marginVertical: 8,
  },
  strong: {
    fontWeight: 'bold',
    color: 'rgb(0, 0, 0)',
  },
  em: {
    fontStyle: 'italic',
  },
});