import { PDFDocument, rgb } from 'pdf-lib';
import * as fontkit from '@pdf-lib/fontkit';

export async function generatePDF(markdown: string): Promise<Uint8Array> {
  try {
    // Create a new PDF document
    const pdfDoc = await PDFDocument.create();
    
    // Register fontkit to use custom fonts
    pdfDoc.registerFontkit(fontkit);
    
    // Load custom font files for Turkish support
    const fontUrl = '/assets/DejaVuSans.ttf';
    const boldFontUrl = '/assets/DejaVuSans-Bold.ttf';
    
    // Fetch font files
    const fontBytes = await fetch(fontUrl).then(res => res.arrayBuffer());
    const boldFontBytes = await fetch(boldFontUrl).then(res => res.arrayBuffer());
    
    // Embed custom fonts
    const customFont = await pdfDoc.embedFont(fontBytes);
    const customBoldFont = await pdfDoc.embedFont(boldFontBytes);
    
    // Define page dimensions
    const pageWidth = 595.28; // A4 width in points
    const pageHeight = 841.89; // A4 height in points
    const margin = 50;
    const lineHeight = 20;
    const fontSize = 11;
    const titleFontSize = 20;
    const headingFontSize = 14;
    
    // Add first page
    let page = pdfDoc.addPage([pageWidth, pageHeight]);
    let yPosition = pageHeight - margin;
    
    // Draw header
    const drawHeader = () => {
      // Title
      page.drawText('Cogni Coach', {
        x: pageWidth / 2 - 50,
        y: yPosition,
        size: titleFontSize,
        font: customBoldFont,
        color: rgb(0.376, 0.733, 0.792), // Cogni Coach color
      });
      yPosition -= 30;
      
      // Subtitle - Now with full Turkish support!
      page.drawText('Kişisel Analiz Raporu', {
        x: pageWidth / 2 - 80,
        y: yPosition,
        size: 16,
        font: customBoldFont,
        color: rgb(0.176, 0.216, 0.282),
      });
      yPosition -= 25;
      
      // Date
      const date = new Date().toLocaleDateString('tr-TR', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      });
      page.drawText(date, {
        x: pageWidth / 2 - 50,
        y: yPosition,
        size: 10,
        font: customFont,
        color: rgb(0.443, 0.502, 0.588),
      });
      yPosition -= 20;
      
      // Line separator
      page.drawLine({
        start: { x: margin, y: yPosition },
        end: { x: pageWidth - margin, y: yPosition },
        thickness: 1,
        color: rgb(0.886, 0.91, 0.941),
      });
      yPosition -= 30;
    };
    
    drawHeader();
    
    // Process markdown content
    const lines = markdown.split('\n');
    const maxWidth = pageWidth - (margin * 2);
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      
      // Check if we need a new page
      if (yPosition < margin + 50) {
        page = pdfDoc.addPage([pageWidth, pageHeight]);
        yPosition = pageHeight - margin;
      }
      
      // Remove markdown formatting for display (but keep Turkish chars!)
      let cleanLine = line
        .replace(/^#+\s/, '') // Remove heading markers
        .replace(/\*\*(.*?)\*\*/g, '$1') // Remove bold
        .replace(/\*(.*?)\*/g, '$1') // Remove italic
        .replace(/^\s*[-*]\s/, '• ') // Convert list items to bullets
        .trim();
      
      if (!cleanLine) {
        yPosition -= lineHeight / 2;
        continue;
      }
      
      // Determine text style based on markdown
      let currentFont = customFont;
      let currentFontSize = fontSize;
      let textColor = rgb(0.176, 0.216, 0.282);
      
      if (line.startsWith('#')) {
        const level = line.match(/^#+/)?.[0].length || 1;
        currentFont = customBoldFont;
        
        if (level === 1) {
          currentFontSize = 16;
          textColor = rgb(0.102, 0.125, 0.173);
          yPosition -= 10; // Extra space before h1
        } else if (level === 2) {
          currentFontSize = headingFontSize;
          textColor = rgb(0.176, 0.216, 0.282);
          yPosition -= 5; // Extra space before h2
        } else {
          currentFontSize = 12;
          textColor = rgb(0.29, 0.333, 0.408);
        }
      }
      
      // Word wrap text
      const words = cleanLine.split(' ');
      let currentLine = '';
      const lines: string[] = [];
      
      for (const word of words) {
        const testLine = currentLine ? `${currentLine} ${word}` : word;
        const width = currentFont.widthOfTextAtSize(testLine, currentFontSize);
        
        if (width > maxWidth && currentLine) {
          lines.push(currentLine);
          currentLine = word;
        } else {
          currentLine = testLine;
        }
      }
      if (currentLine) {
        lines.push(currentLine);
      }
      
      // Draw wrapped lines
      for (const wrappedLine of lines) {
        if (yPosition < margin + 20) {
          // Add new page
          page = pdfDoc.addPage([pageWidth, pageHeight]);
          yPosition = pageHeight - margin;
        }
        
        page.drawText(wrappedLine, {
          x: margin,
          y: yPosition,
          size: currentFontSize,
          font: currentFont,
          color: textColor,
        });
        
        yPosition -= lineHeight;
      }
      
      // Add extra space after headings
      if (line.startsWith('#')) {
        yPosition -= 5;
      }
    }
    
    // Add page numbers
    const pages = pdfDoc.getPages();
    const totalPages = pages.length;
    
    for (let i = 0; i < totalPages; i++) {
      const currentPage = pages[i];
      const pageNumber = `Sayfa ${i + 1} / ${totalPages}`;
      
      currentPage.drawText(pageNumber, {
        x: pageWidth / 2 - 30,
        y: 30,
        size: 9,
        font: customFont,
        color: rgb(0.443, 0.502, 0.588),
      });
      
      currentPage.drawText('© 2024 Cogni Coach', {
        x: pageWidth / 2 - 50,
        y: 15,
        size: 8,
        font: customFont,
        color: rgb(0.443, 0.502, 0.588),
      });
    }
    
    // Save the PDF
    const pdfBytes = await pdfDoc.save();
    return pdfBytes;
    
  } catch (error) {
    console.error('PDF generation error:', error);
    throw error;
  }
}

// Helper function to create and download PDF
export async function downloadPDF(markdown: string, filename?: string) {
  try {
    const pdfBytes = await generatePDF(markdown);
    
    // Create blob and download
    const blob = new Blob([pdfBytes], { type: 'application/pdf' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = filename || `Cogni_Coach_Analiz_${new Date().toISOString().split('T')[0]}.pdf`;
    link.click();
    
    // Clean up
    URL.revokeObjectURL(url);
    
    return true;
  } catch (error) {
    console.error('PDF download error:', error);
    return false;
  }
}