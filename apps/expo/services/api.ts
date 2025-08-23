// API Configuration
// Dynamically determine API URL based on environment

const getApiUrl = () => {
  if (typeof window !== 'undefined') {
    // Browser environment
    const hostname = window.location.hostname;
    
    // If accessing from personax.app domain, use relative API path
    if (hostname === 'personax.app' || hostname === 'www.personax.app') {
      return '/api';
    }
    
    // If accessing from IP or other domain, use that
    if (hostname && hostname !== 'localhost') {
      // Use same protocol and hostname with port 8080
      return `${window.location.protocol}//${hostname}:8080`;
    }
  }
  
  // Default to localhost for development
  return 'http://localhost:8080';
};

export const API_URL = getApiUrl();

// Helper function to make API calls with proper base URL
export const apiCall = async (endpoint: string, options?: RequestInit) => {
  const url = `${API_URL}${endpoint}`;
  return fetch(url, options);
};

// Export for use in components
export default API_URL;