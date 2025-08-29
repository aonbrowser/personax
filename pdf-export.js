// PDF Export Helper
window.initPDFLibraries = function() {
  return new Promise((resolve, reject) => {
    // Check if libraries are already loaded
    if (window.jspdf && window.html2canvas) {
      resolve({ jsPDF: window.jspdf.jsPDF, html2canvas: window.html2canvas });
      return;
    }
    
    // Load jsPDF
    const jsPDFScript = document.createElement('script');
    jsPDFScript.src = 'https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js';
    
    // Load html2canvas
    const html2canvasScript = document.createElement('script');
    html2canvasScript.src = 'https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js';
    
    let loaded = 0;
    const checkLoaded = () => {
      loaded++;
      if (loaded === 2) {
        if (window.jspdf && window.html2canvas) {
          resolve({ jsPDF: window.jspdf.jsPDF, html2canvas: window.html2canvas });
        } else {
          reject(new Error('Libraries failed to load'));
        }
      }
    };
    
    jsPDFScript.onload = checkLoaded;
    html2canvasScript.onload = checkLoaded;
    
    jsPDFScript.onerror = () => reject(new Error('Failed to load jsPDF'));
    html2canvasScript.onerror = () => reject(new Error('Failed to load html2canvas'));
    
    document.head.appendChild(jsPDFScript);
    document.head.appendChild(html2canvasScript);
  });
};