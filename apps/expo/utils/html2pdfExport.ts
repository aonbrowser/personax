import html2pdf from 'html2pdf.js';

export async function exportToPDF(markdown: string, filename?: string): Promise<boolean> {
  try {
    // Convert markdown to HTML with proper styling
    const htmlContent = `
      <!DOCTYPE html>
      <html lang="tr">
      <head>
        <meta charset="UTF-8">
        <style>
          @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
          
          * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
          }
          
          body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #2d3748;
            padding: 40px;
            max-width: 800px;
            margin: 0 auto;
          }
          
          .header {
            text-align: center;
            margin-bottom: 40px;
            padding-bottom: 30px;
            border-bottom: 3px solid #60BBCA;
          }
          
          .logo-container {
            margin-bottom: 20px;
          }
          
          .logo {
            font-size: 32px;
            font-weight: 700;
            color: #60BBCA;
            letter-spacing: -0.5px;
          }
          
          .report-title {
            font-size: 24px;
            font-weight: 600;
            color: #1a202c;
            margin-bottom: 10px;
          }
          
          .report-date {
            font-size: 14px;
            color: #718096;
          }
          
          .content {
            margin-top: 30px;
          }
          
          h1 {
            font-size: 24px;
            font-weight: 700;
            color: #1a202c;
            margin: 30px 0 15px 0;
            padding-bottom: 10px;
            border-bottom: 2px solid #e2e8f0;
          }
          
          h2 {
            font-size: 20px;
            font-weight: 600;
            color: #2d3748;
            margin: 25px 0 12px 0;
          }
          
          h3 {
            font-size: 16px;
            font-weight: 600;
            color: #4a5568;
            margin: 20px 0 10px 0;
          }
          
          p {
            font-size: 14px;
            line-height: 1.8;
            color: #4a5568;
            margin-bottom: 12px;
            text-align: justify;
          }
          
          ul, ol {
            margin: 12px 0;
            padding-left: 25px;
          }
          
          li {
            font-size: 14px;
            line-height: 1.8;
            color: #4a5568;
            margin-bottom: 8px;
          }
          
          strong {
            font-weight: 600;
            color: #2d3748;
          }
          
          em {
            font-style: italic;
            color: #4a5568;
          }
          
          blockquote {
            border-left: 4px solid #60BBCA;
            padding-left: 20px;
            margin: 20px 0;
            font-style: italic;
            color: #4a5568;
          }
          
          .section {
            background: #f7fafc;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
            border: 1px solid #e2e8f0;
          }
          
          .highlight {
            background: linear-gradient(120deg, #fff3cd 0%, #fff3cd 100%);
            background-repeat: no-repeat;
            background-size: 100% 40%;
            background-position: 0 60%;
            padding: 2px 4px;
          }
          
          .footer {
            margin-top: 50px;
            padding-top: 20px;
            border-top: 2px solid #e2e8f0;
            text-align: center;
            color: #718096;
            font-size: 12px;
          }
          
          .page-break {
            page-break-before: always;
          }
        </style>
      </head>
      <body>
        <div class="header">
          <div class="logo-container">
            <div class="logo">Cogni Coach</div>
          </div>
          <div class="report-title">Kişisel Analiz Raporu</div>
          <div class="report-date">${new Date().toLocaleDateString('tr-TR', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            weekday: 'long'
          })}</div>
        </div>
        
        <div class="content">
          ${convertMarkdownToHTML(markdown)}
        </div>
        
        <div class="footer">
          <p>© ${new Date().getFullYear()} Cogni Coach - Tüm hakları saklıdır</p>
          <p>Bu rapor kişisel kullanım içindir ve gizlilik esaslarına tabidir.</p>
        </div>
      </body>
      </html>
    `;

    // Configure html2pdf options
    const opt = {
      margin: [10, 10, 10, 10],
      filename: filename || `Cogni_Coach_Analiz_${new Date().toISOString().split('T')[0]}.pdf`,
      image: { type: 'jpeg', quality: 0.98 },
      html2canvas: { 
        scale: 2,
        useCORS: true,
        letterRendering: true,
        logging: false
      },
      jsPDF: { 
        unit: 'mm', 
        format: 'a4', 
        orientation: 'portrait',
        compress: true
      },
      pagebreak: { 
        mode: ['avoid-all', 'css', 'legacy'],
        before: '.page-break'
      }
    };

    // Generate and download PDF
    await html2pdf().set(opt).from(htmlContent).save();
    
    return true;
  } catch (error) {
    console.error('PDF export error:', error);
    return false;
  }
}

function convertMarkdownToHTML(markdown: string): string {
  if (!markdown) return '';
  
  let html = markdown
    // Headers
    .replace(/^### (.*?)$/gm, '<h3>$1</h3>')
    .replace(/^## (.*?)$/gm, '<h2>$1</h2>')
    .replace(/^# (.*?)$/gm, '<h1>$1</h1>')
    
    // Bold and italic
    .replace(/\*\*\*(.*?)\*\*\*/g, '<strong><em>$1</em></strong>')
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.*?)\*/g, '<em>$1</em>')
    
    // Lists
    .replace(/^\* (.*?)$/gm, '<li>$1</li>')
    .replace(/^\- (.*?)$/gm, '<li>$1</li>')
    .replace(/^\d+\. (.*?)$/gm, '<li>$1</li>')
    
    // Group list items
    .replace(/(<li>.*?<\/li>\n?)+/g, (match) => {
      const isOrdered = match.includes('1.');
      return isOrdered ? `<ol>${match}</ol>` : `<ul>${match}</ul>`;
    })
    
    // Blockquotes
    .replace(/^> (.*?)$/gm, '<blockquote>$1</blockquote>')
    
    // Line breaks and paragraphs
    .replace(/\n\n/g, '</p><p>')
    .replace(/\n/g, '<br>')
    
    // Wrap in paragraphs
    .replace(/^([^<])/gm, '<p>$1')
    .replace(/([^>])$/gm, '$1</p>')
    
    // Clean up empty paragraphs
    .replace(/<p><\/p>/g, '')
    .replace(/<p>(<h[123]>)/g, '$1')
    .replace(/(<\/h[123]>)<\/p>/g, '$1')
    .replace(/<p>(<ul>|<ol>)/g, '$1')
    .replace(/(<\/ul>|<\/ol>)<\/p>/g, '$1')
    .replace(/<p>(<blockquote>)/g, '$1')
    .replace(/(<\/blockquote>)<\/p>/g, '$1');
  
  // Wrap sections with special classes for better styling
  html = html.replace(/(<h2>.*?<\/h2>)([\s\S]*?)(?=<h2>|$)/g, (match, heading, content) => {
    return `<div class="section">${heading}${content}</div>`;
  });
  
  return html;
}