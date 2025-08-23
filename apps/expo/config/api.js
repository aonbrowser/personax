// API Configuration - Dynamic URL based on hostname
const getApiUrl = () => {
  if (typeof window !== 'undefined' && window.location) {
    const hostname = window.location.hostname;
    
    // Production - use relative paths
    if (hostname === 'personax.app' || hostname === 'www.personax.app') {
      return '';  // Empty string means use relative URLs
    }
    
    // Local IP access (for testing from other devices)
    if (hostname && hostname !== 'localhost') {
      return `http://${hostname}:8080`;
    }
  }
  
  // Local development
  return 'http://localhost:8080';
};

export const API_BASE_URL = getApiUrl();