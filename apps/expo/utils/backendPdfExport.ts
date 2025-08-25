import { Alert } from 'react-native';

const API_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:8080/v1';

export async function generatePDFFromBackend(markdown: string, filename?: string): Promise<boolean> {
  try {
    const response = await fetch(`${API_URL}/generate-pdf`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ markdown }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'PDF generation failed');
    }

    const result = await response.json();

    if (result.success && result.pdf) {
      // Convert base64 to blob and download
      const base64Data = result.pdf;
      const binaryString = atob(base64Data);
      const bytes = new Uint8Array(binaryString.length);
      
      for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
      }
      
      const blob = new Blob([bytes], { type: 'application/pdf' });
      const url = URL.createObjectURL(blob);
      
      // Create download link
      const link = document.createElement('a');
      link.href = url;
      link.download = filename || result.filename || `Cogni_Coach_Analiz_${new Date().toISOString().split('T')[0]}.pdf`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      
      // Clean up
      setTimeout(() => URL.revokeObjectURL(url), 100);
      
      return true;
    } else {
      throw new Error('PDF generation failed - no data received');
    }
  } catch (error) {
    console.error('PDF export error:', error);
    Alert.alert(
      'PDF Oluşturma Hatası',
      error instanceof Error ? error.message : 'PDF oluşturulurken bir hata oluştu'
    );
    return false;
  }
}