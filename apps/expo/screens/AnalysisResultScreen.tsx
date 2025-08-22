import React, { useState, useRef } from 'react';
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

// Conditional imports for web platform
let jsPDF: any = null;
let html2canvas: any = null;

if (Platform.OS === 'web') {
  try {
    const jsPDFModule = require('jspdf');
    jsPDF = jsPDFModule.jsPDF || jsPDFModule.default || jsPDFModule;
    
    const html2canvasModule = require('html2canvas');
    html2canvas = html2canvasModule.default || html2canvasModule;
    
    console.log('PDF libraries loaded successfully');
  } catch (e) {
    console.error('Error loading PDF libraries:', e);
  }
}

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
    console.log('Platform:', Platform.OS);
    console.log('jsPDF available:', !!jsPDF);
    console.log('html2canvas available:', !!html2canvas);
    
    if (Platform.OS === 'web') {
      try {
        // Check if libraries are available
        if (!jsPDF || !html2canvas) {
          console.error('PDF libraries not loaded:', { jsPDF: !!jsPDF, html2canvas: !!html2canvas });
          Alert.alert('Hata', 'PDF kütüphaneleri yüklenemedi. Sayfayı yenileyin.');
          return;
        }
        
        console.log('Creating PDF...');
        
        // Create a temporary div to render markdown as HTML
        const tempDiv = document.createElement('div');
        tempDiv.style.position = 'absolute';
        tempDiv.style.left = '-9999px';
        tempDiv.style.width = '800px'; // Optimal width for A4 format
        tempDiv.style.padding = '40px';
        tempDiv.style.backgroundColor = 'white';
        tempDiv.style.fontFamily = 'system-ui, -apple-system, sans-serif';
        document.body.appendChild(tempDiv);
        
        // Convert markdown to HTML with styling
        const htmlContent = convertMarkdownToHTML(markdown);
        tempDiv.innerHTML = `
          <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; color: #333; line-height: 1.6;">
            <div style="text-align: center; margin-bottom: 50px; padding: 30px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 10px;">
              <h1 style="color: #FFFFFF; font-size: 32px; margin-bottom: 10px; font-weight: 700; text-shadow: 2px 2px 4px rgba(0,0,0,0.1);">Cogni Coach</h1>
              <h2 style="color: #FFFFFF; font-size: 22px; font-weight: 400; margin-bottom: 10px; opacity: 0.95;">Kişisel Analiz Raporu</h2>
              <p style="color: #FFFFFF; font-size: 16px; opacity: 0.9;">${new Date().toLocaleDateString('tr-TR', { 
                year: 'numeric', 
                month: 'long', 
                day: 'numeric' 
              })}</p>
            </div>
            <div style="padding: 0 20px;">
              ${htmlContent}
            </div>
            <div style="margin-top: 50px; padding: 20px; text-align: center; border-top: 2px solid #e9ecef;">
              <p style="color: #6c757d; font-size: 14px; margin: 0;">© ${new Date().getFullYear()} Cogni Coach - Tüm hakları saklıdır.</p>
              <p style="color: #6c757d; font-size: 12px; margin-top: 5px;">Bu rapor kişisel kullanım içindir.</p>
            </div>
          </div>
        `;
        
        // Generate PDF from the HTML with balanced quality/size settings
        const canvas = await html2canvas(tempDiv, {
          scale: 2.5, // Balanced between quality and file size
          useCORS: true,
          logging: false,
          letterRendering: true,
          allowTaint: false,
          backgroundColor: '#ffffff',
          imageTimeout: 0,
          removeContainer: false,
        });
        
        // Use PNG for better text quality
        const imgData = canvas.toDataURL('image/png'); // PNG for crisp text
        
        // Create PDF instance - handle different jsPDF versions
        let pdf;
        if (typeof jsPDF === 'function') {
          pdf = new jsPDF({
            orientation: 'portrait',
            unit: 'mm',
            format: 'a4',
            compress: true, // Enable PDF compression
          });
        } else if (jsPDF && jsPDF.jsPDF) {
          pdf = new jsPDF.jsPDF({
            orientation: 'portrait',
            unit: 'mm',
            format: 'a4',
            compress: true, // Enable PDF compression
          });
        } else {
          throw new Error('jsPDF not properly loaded');
        }
        
        const pdfWidth = pdf.internal.pageSize.getWidth();
        const pdfHeight = pdf.internal.pageSize.getHeight();
        const imgWidth = canvas.width;
        const imgHeight = canvas.height;
        
        // Calculate dimensions for A4 page
        const pageWidth = pdfWidth - 20; // 10mm margins on each side
        const pageHeight = pdfHeight - 20; // 10mm margins on top and bottom
        
        // Calculate scale to fit width
        const scale = pageWidth / (imgWidth * 0.264583); // Convert pixels to mm (96 DPI)
        
        // Calculate scaled dimensions
        const scaledWidth = imgWidth * 0.264583 * scale;
        const scaledHeight = imgHeight * 0.264583 * scale;
        
        // Add pages as needed
        let currentY = 10;
        const pageHeightInPixels = pageHeight / (0.264583 * scale);
        const totalPages = Math.ceil(imgHeight / pageHeightInPixels);
        
        for (let i = 0; i < totalPages; i++) {
          if (i > 0) {
            pdf.addPage();
          }
          
          const sourceY = i * pageHeightInPixels;
          const sourceHeight = Math.min(pageHeightInPixels, imgHeight - sourceY);
          const destHeight = sourceHeight * 0.264583 * scale;
          
          // Create a temporary canvas for this page section
          const pageCanvas = document.createElement('canvas');
          pageCanvas.width = imgWidth;
          pageCanvas.height = sourceHeight;
          const pageCtx = pageCanvas.getContext('2d');
          
          if (pageCtx) {
            pageCtx.drawImage(canvas, 0, -sourceY);
            const pageImgData = pageCanvas.toDataURL('image/png'); // PNG for better quality
            pdf.addImage(pageImgData, 'PNG', 10, 10, scaledWidth, destHeight, undefined, 'MEDIUM'); // Better compression balance
          }
        }
        
        // Save the PDF
        const fileName = `Cogni_Coach_Analiz_${new Date().toISOString().split('T')[0]}.pdf`;
        pdf.save(fileName);
        
        // Clean up
        document.body.removeChild(tempDiv);
        
      } catch (error: any) {
        console.error('PDF generation error:', error);
        console.error('Error details:', error.message, error.stack);
        Alert.alert('Hata', `PDF oluşturulurken bir hata oluştu: ${error.message}`);
      }
    } else {
      Alert.alert('PDF İndirme', 'PDF indirme özelliği mobil cihazlarda henüz mevcut değil.');
    }
  };
  
  const convertMarkdownToHTML = (markdown: string) => {
    if (!markdown) return '';
    
    // Parse blocks and convert to HTML
    const blocks = parseMarkdownIntoBlocks(markdown);
    
    return blocks.map((block, index) => {
      let html = block.content;
      
      // Process line by line for better control
      const lines = html.split('\n');
      const processedLines = [];
      let inList = false;
      let listItems = [];
      
      for (const line of lines) {
        // Check if this is a list item
        if (line.match(/^[-*] /) || line.match(/^\d+\. /)) {
          const listContent = line.replace(/^[-*] /, '').replace(/^\d+\. /, '');
          listItems.push(`<li style="margin: 8px 0; line-height: 1.8; font-size: 15px; color: #333;">${processInlineFormatting(listContent)}</li>`);
          inList = true;
        } else {
          // If we were in a list, close it
          if (inList && listItems.length > 0) {
            processedLines.push(`<ul style="margin: 15px 0; padding-left: 30px; list-style-type: disc;">${listItems.join('')}</ul>`);
            listItems = [];
            inList = false;
          }
          
          // Process headers
          if (line.match(/^###\s/)) {
            const content = line.replace(/^###\s/, '');
            processedLines.push(`<h3 style="font-size: 18px; color: #1E293B; margin: 20px 0 10px 0; font-weight: 700; line-height: 1.4;">${processInlineFormatting(content)}</h3>`);
          } else if (line.match(/^##\s/)) {
            const content = line.replace(/^##\s/, '');
            processedLines.push(`<h2 style="font-size: 22px; color: #1E293B; margin: 30px 0 15px 0; font-weight: 700; line-height: 1.3;">${processInlineFormatting(content)}</h2>`);
          } else if (line.match(/^#\s/)) {
            const content = line.replace(/^#\s/, '');
            processedLines.push(`<h1 style="font-size: 26px; color: #1E293B; margin: 35px 0 20px 0; font-weight: 700; line-height: 1.2;">${processInlineFormatting(content)}</h1>`);
          } else if (line.trim()) {
            // Regular paragraph
            processedLines.push(`<p style="font-size: 15px; line-height: 1.8; color: #333; margin: 12px 0; text-align: justify;">${processInlineFormatting(line)}</p>`);
          }
        }
      }
      
      // Close any remaining list
      if (inList && listItems.length > 0) {
        processedLines.push(`<ul style="margin: 15px 0; padding-left: 30px; list-style-type: disc;">${listItems.join('')}</ul>`);
      }
      
      const blockStyle = index === 0 
        ? "margin-bottom: 30px; padding: 25px; background-color: #f8f9fa; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.05);"
        : "margin-bottom: 30px; padding: 25px; background-color: #f8f9fa; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.05);";
      
      return `<div style="${blockStyle}">${processedLines.join('')}</div>`;
    }).join('');
  };
  
  // Helper function to process inline formatting
  const processInlineFormatting = (text: string): string => {
    return text
      // Bold and italic
      .replace(/\*\*\*(.*?)\*\*\*/g, '<strong style="font-weight: 700;"><em style="font-style: italic;">$1</em></strong>')
      .replace(/\*\*(.*?)\*\*/g, '<strong style="font-weight: 700; color: #000;">$1</strong>')
      .replace(/\*(.*?)\*/g, '<em style="font-style: italic;">$1</em>')
      // Code inline
      .replace(/`(.*?)`/g, '<code style="background-color: #e9ecef; padding: 2px 6px; border-radius: 3px; font-family: monospace; font-size: 14px;">$1</code>');
  };
  
  const handleAskCoach = () => {
    navigation.navigate('Home', { 
      openCoach: true,
      analysisContext: {
        type: analysisType,
        markdown: markdown
      }
    });
  };

  if (!markdown) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backButton}>
            <Text style={styles.backArrow}>←</Text>
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Analiz Raporu</Text>
          <View style={styles.headerSpacer} />
        </View>
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>Analiz sonucu bulunamadı</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.webWrapper}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backButton}>
          <Text style={styles.backArrow}>←</Text>
        </TouchableOpacity>
        <View style={styles.headerTitleContainer}>
          <Image 
            source={require('../assets/cogni-coach-icon.png')} 
            style={styles.headerIcon}
            resizeMode="contain"
          />
          <Text style={styles.headerTitle}>Analiz Raporu</Text>
        </View>
        <View style={styles.headerSpacer} />
      </View>
      
      <View style={{ flex: 1 }}>
        <ScrollView 
          ref={scrollViewRef}
          style={styles.scrollView} 
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
          
          {blocks.map((block, index) => (
            <View key={block.id} style={[styles.markdownContainer, index > 0 && styles.blockSpacing]}>
              <Markdown style={markdownStyles}>
                {block.content}
              </Markdown>
            </View>
          ))}
        </ScrollView>
        
        {(Platform.OS !== 'web' || showScrollTop) && (
          <TouchableOpacity 
            style={styles.mobileScrollButton}
            onPress={scrollToTop}
            activeOpacity={0.8}
          >
            <Text style={styles.scrollToTopIcon}>↑</Text>
          </TouchableOpacity>
        )}
      </View>
      </View>
    </SafeAreaView>
  );
}

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
  bullet_list: {
    marginVertical: 8,
  },
  ordered_list: {
    marginVertical: 8,
  },
  list_item: {
    flexDirection: 'row',
    marginVertical: 4,
  },
  bullet_list_icon: {
    fontSize: 16,
    lineHeight: 32,
    marginRight: 8,
  },
  ordered_list_icon: {
    fontSize: 16,
    lineHeight: 32,
    marginRight: 8,
  },
  code_inline: {
    backgroundColor: '#F7FAFC',
    borderColor: '#E2E8F0',
    borderWidth: 1,
    borderRadius: 3,
    paddingHorizontal: 4,
    paddingVertical: 2,
    fontFamily: 'monospace',
    fontSize: 14,
  },
  code_block: {
    backgroundColor: '#F7FAFC',
    borderColor: '#E2E8F0',
    borderWidth: 1,
    borderRadius: 3,
    padding: 12,
    marginVertical: 8,
    fontFamily: 'monospace',
    fontSize: 14,
  },
  blockquote: {
    borderLeftWidth: 4,
    borderLeftColor: '#4299E1',
    paddingLeft: 16,
    marginVertical: 8,
    fontStyle: 'italic',
  },
  hr: {
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
    marginVertical: 16,
  },
  table: {
    borderWidth: 1,
    borderColor: '#E2E8F0',
    marginVertical: 8,
  },
  tr: {
    flexDirection: 'column',
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
  },
  td: {
    padding: 8,
    fontSize: 16,
    lineHeight: 24,
  },
});

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F7FAFC',
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
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 24,
    paddingTop: 4,
    paddingBottom: 2,
    backgroundColor: '#FFFFFF',
  },
  backButton: {
    padding: 8,
  },
  backArrow: {
    fontSize: 24,
    color: '#2D3748',
  },
  headerTitleContainer: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerIcon: {
    width: 20,
    height: 20,
    marginRight: 6,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1E293B',
  },
  headerSpacer: {
    width: 40,
  },
  scrollView: {
    flex: 1,
  },
  contentContainer: {
    padding: 14,
  },
  markdownContainer: {
    backgroundColor: 'rgb(247, 247, 247)',
    borderRadius: 3,
    padding: 14,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
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
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    elevation: 8,
  },
  scrollToTopIcon: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
});