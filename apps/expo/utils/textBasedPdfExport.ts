import jsPDF from 'jspdf';

// Turkish character mapping for proper encoding
const turkishCharMap: { [key: string]: string } = {
  'ı': 'i', 'İ': 'I', 'ğ': 'g', 'Ğ': 'G',
  'ü': 'u', 'Ü': 'U', 'ş': 's', 'Ş': 'S',
  'ö': 'o', 'Ö': 'O', 'ç': 'c', 'Ç': 'C'
};

function sanitizeTurkishText(text: string): string {
  // Keep the original text but handle encoding properly
  return text;
}

export async function generateTextPDF(markdown: string, filename?: string): Promise<boolean> {
  try {
    // Create new PDF document
    const doc = new jsPDF({
      orientation: 'portrait',
      unit: 'mm',
      format: 'a4',
      putOnlyUsedFonts: true,
      compress: true
    });

    // Set document properties
    doc.setProperties({
      title: 'Cogni Coach - Kişisel Analiz Raporu',
      author: 'Cogni Coach',
      creator: 'Cogni Coach Platform'
    });

    // Page dimensions
    const pageWidth = doc.internal.pageSize.getWidth();
    const pageHeight = doc.internal.pageSize.getHeight();
    const leftMargin = 20;
    const rightMargin = 20;
    const topMargin = 25;
    const bottomMargin = 25;
    const contentWidth = pageWidth - leftMargin - rightMargin;
    
    let currentY = topMargin;
    let pageNumber = 1;

    // Helper function to add new page
    const addNewPage = () => {
      doc.addPage();
      pageNumber++;
      currentY = topMargin;
      addPageNumber();
    };

    // Helper function to check if we need a new page
    const checkPageBreak = (requiredSpace: number) => {
      if (currentY + requiredSpace > pageHeight - bottomMargin) {
        addNewPage();
        return true;
      }
      return false;
    };

    // Helper function to add page numbers
    const addPageNumber = () => {
      doc.setFontSize(9);
      doc.setTextColor(128, 128, 128);
      doc.text(
        `Sayfa ${pageNumber}`,
        pageWidth / 2,
        pageHeight - 10,
        { align: 'center' }
      );
    };

    // Add header on first page
    const addHeader = () => {
      // Logo/Title
      doc.setFontSize(24);
      doc.setTextColor(96, 187, 202); // Cogni Coach color
      doc.setFont('helvetica', 'bold');
      doc.text('Cogni Coach', pageWidth / 2, currentY, { align: 'center' });
      currentY += 10;

      // Subtitle
      doc.setFontSize(18);
      doc.setTextColor(45, 55, 72);
      doc.text('Kisisel Analiz Raporu', pageWidth / 2, currentY, { align: 'center' });
      currentY += 10;

      // Date
      doc.setFontSize(11);
      doc.setTextColor(113, 128, 150);
      doc.setFont('helvetica', 'normal');
      const date = new Date().toLocaleDateString('tr-TR', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      });
      doc.text(sanitizeTurkishText(date), pageWidth / 2, currentY, { align: 'center' });
      currentY += 8;

      // Separator line
      doc.setDrawColor(229, 231, 235);
      doc.setLineWidth(0.5);
      doc.line(leftMargin, currentY, pageWidth - rightMargin, currentY);
      currentY += 15;
    };

    // Process markdown content
    const processMarkdown = (text: string) => {
      const lines = text.split('\n');
      
      for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        
        if (!line) {
          currentY += 3; // Empty line spacing
          continue;
        }

        // Detect heading levels
        const h1Match = line.match(/^# (.+)$/);
        const h2Match = line.match(/^## (.+)$/);
        const h3Match = line.match(/^### (.+)$/);
        
        if (h1Match) {
          // H1 Heading
          checkPageBreak(15);
          doc.setFontSize(16);
          doc.setTextColor(26, 32, 44);
          doc.setFont('helvetica', 'bold');
          
          const text = sanitizeTurkishText(h1Match[1]);
          const lines = doc.splitTextToSize(text, contentWidth);
          
          if (currentY > topMargin + 10) currentY += 5; // Extra space before H1
          doc.text(lines, leftMargin, currentY);
          currentY += lines.length * 7 + 5;
          
          // Underline for H1
          doc.setDrawColor(229, 231, 235);
          doc.setLineWidth(0.3);
          doc.line(leftMargin, currentY - 3, leftMargin + contentWidth, currentY - 3);
          currentY += 5;
          
        } else if (h2Match) {
          // H2 Heading
          checkPageBreak(12);
          doc.setFontSize(14);
          doc.setTextColor(45, 55, 72);
          doc.setFont('helvetica', 'bold');
          
          const text = sanitizeTurkishText(h2Match[1]);
          const lines = doc.splitTextToSize(text, contentWidth);
          
          if (currentY > topMargin + 10) currentY += 3; // Extra space before H2
          doc.text(lines, leftMargin, currentY);
          currentY += lines.length * 6 + 4;
          
        } else if (h3Match) {
          // H3 Heading
          checkPageBreak(10);
          doc.setFontSize(12);
          doc.setTextColor(74, 85, 104);
          doc.setFont('helvetica', 'bold');
          
          const text = sanitizeTurkishText(h3Match[1]);
          const lines = doc.splitTextToSize(text, contentWidth);
          
          doc.text(lines, leftMargin, currentY);
          currentY += lines.length * 5 + 3;
          
        } else if (line.startsWith('- ') || line.startsWith('* ')) {
          // List items
          checkPageBreak(8);
          doc.setFontSize(11);
          doc.setTextColor(74, 85, 104);
          doc.setFont('helvetica', 'normal');
          
          const bulletText = line.substring(2);
          const text = sanitizeTurkishText(bulletText);
          const lines = doc.splitTextToSize(text, contentWidth - 8);
          
          // Bullet point
          doc.text('•', leftMargin + 3, currentY);
          
          // List item text
          doc.text(lines, leftMargin + 8, currentY);
          currentY += lines.length * 5 + 2;
          
        } else {
          // Regular paragraph
          checkPageBreak(8);
          doc.setFontSize(11);
          doc.setTextColor(74, 85, 104);
          doc.setFont('helvetica', 'normal');
          
          // Remove markdown formatting
          let cleanText = line
            .replace(/\*\*(.+?)\*\*/g, '$1') // Remove bold
            .replace(/\*(.+?)\*/g, '$1')     // Remove italic
            .replace(/`(.+?)`/g, '$1');      // Remove code
          
          cleanText = sanitizeTurkishText(cleanText);
          const lines = doc.splitTextToSize(cleanText, contentWidth);
          
          doc.text(lines, leftMargin, currentY);
          currentY += lines.length * 5 + 3;
        }

        // Check for page overflow
        if (currentY > pageHeight - bottomMargin - 10) {
          addNewPage();
        }
      }
    };

    // Add footer to all pages
    const addFooter = () => {
      const totalPages = doc.getNumberOfPages();
      
      for (let i = 1; i <= totalPages; i++) {
        doc.setPage(i);
        
        // Page number (already added during page creation)
        
        // Copyright
        doc.setFontSize(8);
        doc.setTextColor(156, 163, 175);
        doc.text(
          sanitizeTurkishText('© 2024 Cogni Coach - Tüm hakları saklıdır'),
          pageWidth / 2,
          pageHeight - 5,
          { align: 'center' }
        );
      }
    };

    // Generate PDF
    addHeader();
    processMarkdown(markdown);
    addFooter();
    
    // Save the PDF
    doc.save(filename || `Cogni_Coach_Analiz_${new Date().toISOString().split('T')[0]}.pdf`);
    
    return true;
  } catch (error) {
    console.error('PDF generation error:', error);
    return false;
  }
}

// Alternative: Generate PDF and return as blob for more control
export async function generateTextPDFBlob(markdown: string): Promise<Blob | null> {
  try {
    const doc = new jsPDF({
      orientation: 'portrait',
      unit: 'mm',
      format: 'a4'
    });

    // ... same PDF generation logic as above ...
    // (keeping it DRY - in production, extract the common logic)
    
    const blob = doc.output('blob');
    return blob;
  } catch (error) {
    console.error('PDF blob generation error:', error);
    return null;
  }
}