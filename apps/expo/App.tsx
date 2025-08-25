import React, { useState, useEffect, useRef } from 'react';
import { 
  Text, 
  View, 
  TextInput, 
  TouchableOpacity, 
  ScrollView, 
  Alert,
  StyleSheet,
  SafeAreaView,
  Platform,
  Button,
  Image
} from 'react-native';
import * as Localization from 'expo-localization';
import * as AuthSession from 'expo-auth-session';
import * as WebBrowser from 'expo-web-browser';

// Config
import { API_URL } from './config';

// Images
// Profile image removed - using user initial instead
const analysisImage = require('./assets/images/analysis.png');
const newPersonAnalysisImage = require('./assets/images/new-person-analysis.png');
const cogniCoachLogo = require('./assets/images/cogni-coach-logo.png');
const cogniCoachIcon = require('./assets/images/cogni-coach-icon.png');
const micIcon = require('./assets/images/mic.png');

// Screens
import NewFormsScreen from './screens/NewFormsScreen';
import PaymentCheckScreen from './screens/PaymentCheckScreen';
import MyAnalysesScreen from './screens/MyAnalysesScreen';
import AnalysisResultScreen from './screens/AnalysisResultScreen';
import NewPersonAnalysisScreen from './screens/NewPersonAnalysisScreen';
import AccountInfoScreen from './screens/AccountInfoScreen';

// Services

// For mobile OAuth
if (Platform.OS !== 'web') {
  WebBrowser.maybeCompleteAuthSession();
}

export default function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [currentScreen, setCurrentScreen] = useState('home');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [secretClicks, setSecretClicks] = useState(0);
  const [paymentParams, setPaymentParams] = useState<any>(null);
  const [analysisResultParams, setAnalysisResultParams] = useState<any>(null);
  const [editMode, setEditMode] = useState(false);
  const [editAnalysisId, setEditAnalysisId] = useState<string | null>(null);
  
  // Home screen states
  const [hasSelfAnalysis, setHasSelfAnalysis] = useState(false);
  const [personAnalyses, setPersonAnalyses] = useState<string[]>([]);
  const [personDrafts, setPersonDrafts] = useState<any[]>([]);
  const [showDraftMenu, setShowDraftMenu] = useState<string | null>(null);
  
  // Close draft menu when clicking outside
  useEffect(() => {
    if (showDraftMenu) {
      if (Platform.OS === 'web') {
        const handleClickOutside = (event: MouseEvent) => {
          const target = event.target as HTMLElement;
          // Check if click is outside menu and menu button
          if (!target.closest('[data-draft-menu]') && !target.closest('[data-draft-menu-button]')) {
            setShowDraftMenu(null);
          }
        };
        
        // Add listener with a small delay to avoid immediate triggering
        const timeoutId = setTimeout(() => {
          document.addEventListener('click', handleClickOutside);
        }, 100);
        
        return () => {
          clearTimeout(timeoutId);
          document.removeEventListener('click', handleClickOutside);
        };
      }
    }
  }, [showDraftMenu]);
  const [continueDraft, setContinueDraft] = useState<any>(null);
  const [relationAnalyses, setRelationAnalyses] = useState<string[]>([]);
  const [chatMessage, setChatMessage] = useState('');
  const [selectedLanguage, setSelectedLanguage] = useState('tr');
  const [showLanguageMenu, setShowLanguageMenu] = useState(false);
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const [isRecordingChat, setIsRecordingChat] = useState(false);
  const recognitionRef = useRef<any>(null);
  const [activeRecordingType, setActiveRecordingType] = useState<string | null>(null); // Track which recording is active


  // Global click handler to stop recording when clicking outside
  useEffect(() => {
    const handleGlobalClick = (event: MouseEvent) => {
      // Check if click is outside recording buttons and input areas
      const target = event.target as HTMLElement;
      
      // Don't stop if clicking on recording button itself or chat input
      const isRecordingButton = target.closest('[data-recording-button]');
      const isChatInput = target.closest('[data-chat-input]');
      const isFormInput = target.closest('[data-form-input]');
      
      if (!isRecordingButton && !isChatInput && !isFormInput && activeRecordingType) {
        console.log('Stopping recording due to outside click');
        stopAnyActiveRecording();
      }
    };

    if (Platform.OS === 'web') {
      document.addEventListener('click', handleGlobalClick);
      return () => {
        document.removeEventListener('click', handleGlobalClick);
      };
    }
  }, [activeRecordingType]);

  // Check for existing session on mount and handle URL routing
  useEffect(() => {
    checkAuthStatus();
    
    // Detect and set user language
    const detectAndSetLanguage = async () => {
      try {
        // Check for saved preference first (works on all platforms)
        let savedLang = null;
        
        if (Platform.OS === 'web' && typeof window !== 'undefined') {
          savedLang = localStorage.getItem('userLanguage');
        } else {
          // For mobile, use AsyncStorage
          try {
            const AsyncStorage = require('@react-native-async-storage/async-storage').default;
            savedLang = await AsyncStorage.getItem('userLanguage');
          } catch (e) {
            console.log('AsyncStorage not available');
          }
        }
        
        if (savedLang) {
          setSelectedLanguage(savedLang);
          return;
        }
        
        // Auto-detect device/browser language
        let detectedLangCode = 'en'; // Default fallback
        
        if (Platform.OS === 'web') {
          // Web: Use browser language
          const browserLang = navigator.language || (navigator as any).userLanguage || 'en';
          detectedLangCode = browserLang;
        } else {
          // Mobile: Use Expo Localization
          const locales = Localization.getLocales();
          if (locales && locales.length > 0) {
            detectedLangCode = locales[0].languageCode || 'en';
            console.log('Mobile device locale:', locales[0]);
          }
        }
        
        // Map language codes to our supported languages
        const langMap: { [key: string]: string } = {
          'tr': 'tr', 'tr-TR': 'tr',
          'en': 'en', 'en-US': 'en', 'en-GB': 'en',
          'ar': 'ar', 'ar-SA': 'ar', 'ar-AE': 'ar', 'ar-EG': 'ar',
          'es': 'es', 'es-ES': 'es', 'es-MX': 'es', 'es-AR': 'es',
          'ru': 'ru', 'ru-RU': 'ru',
          'de': 'de', 'de-DE': 'de', 'de-AT': 'de', 'de-CH': 'de',
          'fr': 'fr', 'fr-FR': 'fr', 'fr-CA': 'fr', 'fr-BE': 'fr',
          'it': 'it', 'it-IT': 'it',
          'pt': 'pt', 'pt-BR': 'pt', 'pt-PT': 'pt',
          'nl': 'nl', 'nl-NL': 'nl', 'nl-BE': 'nl',
          'zh': 'zh', 'zh-CN': 'zh', 'zh-Hans': 'zh',
          'zh-TW': 'zh-TW', 'zh-Hant': 'zh-TW', 'zh-HK': 'zh-TW',
          'ja': 'ja', 'ja-JP': 'ja',
          'ko': 'ko', 'ko-KR': 'ko',
          'hi': 'hi', 'hi-IN': 'hi',
        };
        
        // Extract the base language code
        const detectedLang = langMap[detectedLangCode] || langMap[detectedLangCode.split('-')[0]] || 'en';
        
        console.log('Device/Browser language detected:', detectedLangCode, '-> Using:', detectedLang);
        setSelectedLanguage(detectedLang);
        
        // Save the detected language
        if (Platform.OS === 'web' && typeof window !== 'undefined') {
          localStorage.setItem('userLanguage', detectedLang);
        } else {
          try {
            const AsyncStorage = require('@react-native-async-storage/async-storage').default;
            await AsyncStorage.setItem('userLanguage', detectedLang);
          } catch (e) {
            console.log('Could not save language preference');
          }
        }
      } catch (error) {
        console.error('Error detecting language:', error);
        setSelectedLanguage('en'); // Fallback to English
      }
    };
    
    detectAndSetLanguage();
    
    // Check URL for stargate route (using hash routing)
    if (Platform.OS === 'web') {
      const checkRoute = () => {
        const hash = window.location.hash;
        const path = window.location.pathname;
        
        console.log('Checking route:', { hash, path }); // Debug log
        
        // Check for Google OAuth callback
        if (hash.includes('access_token')) {
          handleGoogleCallback(hash);
          return;
        }
        
        // Check both hash and pathname
        if (hash === '#stargate' || hash === '#/stargate' || path === '/stargate') {
          console.log('Stargate route detected, switching to admin panel');
          setCurrentScreen('admin-pricing');
          // Update URL to use hash
          if (path === '/stargate') {
            window.history.replaceState({}, '', '/#stargate');
          }
        }
      };
      
      // Check initial route
      setTimeout(checkRoute, 100); // Small delay to ensure page is loaded
      
      // Listen for hashchange and popstate events
      window.addEventListener('hashchange', checkRoute);
      window.addEventListener('popstate', checkRoute);
      
      // Also check on interval for first 2 seconds (fallback)
      const intervalId = setInterval(checkRoute, 500);
      setTimeout(() => clearInterval(intervalId), 2000);
      
      return () => {
        window.removeEventListener('hashchange', checkRoute);
        window.removeEventListener('popstate', checkRoute);
      };
    }
  }, []);

  // Update page title and favicon based on current screen
  useEffect(() => {
    if (Platform.OS === 'web') {
      // Set favicon
      const setFavicon = () => {
        // Remove existing favicons
        const existingIcons = document.querySelectorAll("link[rel*='icon']");
        existingIcons.forEach(icon => icon.remove());
        
        // Add new favicon
        const link = document.createElement('link');
        link.type = 'image/png';
        link.rel = 'icon';
        link.href = '/favicon.png';
        document.head.appendChild(link);
        
        // Add apple touch icon
        const appleLink = document.createElement('link');
        appleLink.rel = 'apple-touch-icon';
        appleLink.href = '/favicon.png';
        document.head.appendChild(appleLink);
        
        // Add shortcut icon for older browsers
        const shortcutLink = document.createElement('link');
        shortcutLink.rel = 'shortcut icon';
        shortcutLink.href = '/favicon.png';
        document.head.appendChild(shortcutLink);
      };
      
      setFavicon();
      
      switch(currentScreen) {
        case 'home':
          document.title = 'Cogni Coach - Kişisel Gelişim Koçunuz';
          break;
        case 'login':
          document.title = 'Giriş Yap - Cogni Coach';
          break;
        case 'NewForms':
        case 'newforms':
          document.title = 'Kendi Analizim - Cogni Coach';
          break;
        case 'MyAnalyses':
          document.title = 'Tüm Analizlerim - Cogni Coach';
          break;
        case 'AnalysisResult':
          document.title = 'Analiz Raporu - Cogni Coach';
          break;
        case 'people':
          document.title = 'Kişi Analizleri - Cogni Coach';
          break;
        case 'reports':
          document.title = 'İlişki Analizleri - Cogni Coach';
          break;
        case 'admin-pricing':
          document.title = 'Admin Panel - Cogni Coach';
          break;
        default:
          document.title = 'Cogni Coach';
      }
    }
  }, [currentScreen]);
  
  // Check analyses for home screen - with better timing
  useEffect(() => {
    if (currentScreen === 'home' && isAuthenticated && email) {
      const checkAnalyses = async () => {
        try {
          // Use current email from state (which is the logged-in user's email)
          const userEmail = email;
          
          console.log('=== CHECKING ANALYSES FOR HOME SCREEN ===');
          console.log('User email:', userEmail);
          console.log('Is authenticated:', isAuthenticated);
          console.log('Current screen:', currentScreen);
          
          const response = await fetch(`${API_URL}/v1/user/analyses`, {
            headers: {
              'x-user-email': userEmail,
            },
          });
          
          if (response.ok) {
            const data = await response.json();
            console.log('=== ANALYSES DATA FROM SERVER ===');
            console.log('Total analyses:', data.analyses?.length || 0);
            console.log('Raw analyses:', data.analyses);
            
            const selfAnalyses = (data.analyses || []).filter(
              (a: any) => a.analysis_type === 'self' && a.status === 'completed'
            );
            console.log('Filtered self analyses:', selfAnalyses);
            console.log('Found self analyses count:', selfAnalyses.length);
            const hasAnalysis = selfAnalyses.length > 0;
            console.log('Setting hasSelfAnalysis to:', hasAnalysis);
            setHasSelfAnalysis(hasAnalysis);
            
            // Force re-render if user has analysis
            if (hasAnalysis) {
              console.log('USER HAS SELF ANALYSIS - Forcing state update');
              setTimeout(() => {
                setHasSelfAnalysis(true);
              }, 100);
            }
            
            // Get unique person analyses (excluding self)
            const persons = (data.analyses || [])
              .filter((a: any) => a.analysis_type === 'other')
              .map((a: any) => a.target_person)
              .filter((p: string, i: number, arr: string[]) => arr.indexOf(p) === i);
            setPersonAnalyses(persons);
          }
        } catch (error) {
          console.error('Error checking analyses:', error);
        }
        
        // Load drafts
        try {
          let draftsJson;
          if (Platform.OS === 'web') {
            draftsJson = localStorage.getItem('personAnalysisDrafts');
          } else {
            const AsyncStorage = require('@react-native-async-storage/async-storage').default;
            draftsJson = await AsyncStorage.getItem('personAnalysisDrafts');
          }
          const drafts = draftsJson ? JSON.parse(draftsJson) : [];
          setPersonDrafts(drafts.filter((d: any) => d.status === 'draft'));
        } catch (error) {
          console.error('Error loading drafts:', error);
        }
      };
      checkAnalyses();
      
      // Also check again after a delay to ensure state is properly set
      const timeoutId = setTimeout(() => {
        console.log('Re-checking analyses after delay...');
        checkAnalyses();
      }, 500);
      
      return () => clearTimeout(timeoutId);
    }
  }, [currentScreen, isAuthenticated, email]);

  const checkAuthStatus = async () => {
    try {
      if (Platform.OS === 'web' && typeof localStorage !== 'undefined') {
        const authData = localStorage.getItem('relateCoachAuth');
        if (authData) {
          const { expiresAt } = JSON.parse(authData);
          if (new Date().getTime() < expiresAt) {
            setIsAuthenticated(true);
            // Also load the email
            const savedEmail = localStorage.getItem('userEmail');
            if (savedEmail) {
              setEmail(savedEmail);
            }
          } else {
            localStorage.removeItem('relateCoachAuth');
          }
        }
      } else if (Platform.OS !== 'web') {
        // Native mobile app: Use AsyncStorage
        try {
          const AsyncStorage = require('@react-native-async-storage/async-storage').default;
          const authData = await AsyncStorage.getItem('relateCoachAuth');
          if (authData) {
            const { expiresAt } = JSON.parse(authData);
            if (new Date().getTime() < expiresAt) {
              setIsAuthenticated(true);
              // Also load the email
              const savedEmail = await AsyncStorage.getItem('userEmail');
              if (savedEmail) {
                setEmail(savedEmail);
              }
            } else {
              await AsyncStorage.removeItem('relateCoachAuth');
            }
          }
        } catch (e) {
          console.log('AsyncStorage not available');
        }
      }
    } catch (error) {
      console.error('Error checking auth status:', error);
    }
    setIsLoading(false);
  };

  const saveAuthSession = async () => {
    try {
      
      const oneYearFromNow = new Date();
      oneYearFromNow.setFullYear(oneYearFromNow.getFullYear() + 1);
      
      const authData = {
        email: email,
        expiresAt: oneYearFromNow.getTime(),
        timestamp: new Date().getTime()
      };
      
      if (Platform.OS === 'web' && typeof localStorage !== 'undefined') {
        localStorage.setItem('relateCoachAuth', JSON.stringify(authData));
        // Also save email separately for easy access
        localStorage.setItem('userEmail', email);
      } else if (Platform.OS !== 'web') {
        // Native mobile app: Use AsyncStorage
        try {
          const AsyncStorage = require('@react-native-async-storage/async-storage').default;
          await AsyncStorage.setItem('relateCoachAuth', JSON.stringify(authData));
          // Also save email separately for easy access
          await AsyncStorage.setItem('userEmail', email);
        } catch (e) {
          console.log('AsyncStorage not available');
        }
      }
    } catch (error) {
      console.error('Error saving auth session:', error);
    }
  };

  const handleLanguageChange = async (lang: string) => {
    setSelectedLanguage(lang);
    setShowLanguageMenu(false);
    
    // Save language preference
    if (Platform.OS === 'web' && typeof window !== 'undefined') {
      localStorage.setItem('userLanguage', lang);
    } else {
      // For mobile, use AsyncStorage
      try {
        const AsyncStorage = require('@react-native-async-storage/async-storage').default;
        await AsyncStorage.setItem('userLanguage', lang);
      } catch (e) {
        console.log('Could not save language preference');
      }
    }
  };

  const handleEmailSignIn = async () => {
    console.log('Login attempt with:', email, password);
    
    // Email validation
    if (!email || !password) {
      const message = 'Lütfen email ve şifre girin';
      if (Platform.OS === 'web') {
        alert(`Uyarı\n\n${message}`);
      } else {
        Alert.alert('Uyarı', message);
      }
      return;
    }
    
    // For demo purposes, accept any email/password
    if (email && password) {
      setIsAuthenticated(true);
      saveAuthSession();
      console.log('Login successful');
    } else {
      console.log('Invalid credentials, showing alert...');
      const message = 'Geçersiz email veya şifre';
      
      if (Platform.OS === 'web') {
        // Web'de alert() kullan
        alert(`Geçersiz Giriş Bilgileri\n\n${message}`);
      } else {
        // Mobile'da React Native Alert kullan
        Alert.alert(
          'Geçersiz Giriş Bilgileri', 
          message,
          [{ text: 'Tamam', style: 'default' }],
          { cancelable: true }
        );
      }
    }
  };

  const handleLogout = async () => {
    setIsAuthenticated(false);
    setCurrentScreen('home');
    setShowProfileMenu(false);
    setEmail('');
    setPassword('');
    
    // Only clear authentication data, NOT form answers
    if (Platform.OS === 'web') {
      // Clear authentication
      localStorage.removeItem('relateCoachAuth');
      localStorage.removeItem('userEmail');
      localStorage.removeItem('userPicture');
      
      // DO NOT clear form data - keep them for when user logs in again
      // localStorage.removeItem('form1_answers');  // COMMENTED OUT
      // localStorage.removeItem('form2_answers');  // COMMENTED OUT
      // localStorage.removeItem('form3_answers');  // COMMENTED OUT
      
      // Clear other temporary data
      localStorage.removeItem('pending_analysis_data');
      localStorage.removeItem('personAnalysisDrafts');
      localStorage.removeItem('analysisResults');
      
      console.log('✅ Logged out, form data preserved');
    } else {
      // Mobile: Use AsyncStorage
      try {
        const AsyncStorage = require('@react-native-async-storage/async-storage').default;
        await AsyncStorage.multiRemove([
          'relateCoachAuth',
          'userEmail',
          'userPicture',
          'form1_answers',
          'form2_answers',
          'form3_answers',
          'pending_analysis_data',
          'personAnalysisDrafts',
          'analysisResults'
        ]);
        console.log('✅ All user data cleared from AsyncStorage');
      } catch (error) {
        console.error('Error removing auth session:', error);
      }
    }
  };

  // Global function to stop any active recording
  const stopAnyActiveRecording = () => {
    if (recognitionRef.current) {
      try {
        recognitionRef.current.stop();
      } catch (e) {
        console.log('Recognition already stopped');
      }
      recognitionRef.current = null;
    }
    setIsRecordingChat(false);
    setActiveRecordingType(null);
  };

  // Speech recognition functions for chat
  const startChatRecognition = () => {
    // Security check: Don't allow voice input if self-analysis not completed
    if (!hasSelfAnalysis) {
      console.warn('Voice input blocked: Self-analysis not completed');
      Alert.alert('Uyarı', 'Cogni Coach ile konuşmak için önce kendi analizinizi tamamlamanız gerekiyor.');
      return;
    }
    
    // Stop any other active recording first
    if (activeRecordingType && activeRecordingType !== 'chat') {
      stopAnyActiveRecording();
    }

    if (typeof window !== 'undefined') {
      const SpeechRecognition = (window as any).webkitSpeechRecognition || (window as any).SpeechRecognition;
      if (SpeechRecognition) {
        const recognition = new SpeechRecognition();
        recognition.lang = 'tr-TR';
        recognition.continuous = true; // Keep listening continuously like in forms
        recognition.interimResults = false; // Only final results
        recognition.maxAlternatives = 1;
        
        recognition.onstart = () => {
          console.log('Chat voice recording started');
          setIsRecordingChat(true);
          setActiveRecordingType('chat');
        };
        
        recognition.onresult = (event: any) => {
          // Get all results from the current session
          let fullTranscript = '';
          for (let i = event.resultIndex; i < event.results.length; i++) {
            if (event.results[i].isFinal) {
              fullTranscript += event.results[i][0].transcript + ' ';
            }
          }
          
          if (fullTranscript) {
            setChatMessage(prevText => {
              // Add to existing text with a space
              return prevText ? prevText + ' ' + fullTranscript.trim() : fullTranscript.trim();
            });
          }
        };
        
        recognition.onerror = (event: any) => {
          console.error('Chat speech recognition error:', event.error);
          
          // Only stop on fatal errors
          if (event.error === 'no-speech' || event.error === 'audio-capture' || event.error === 'not-allowed') {
            setIsRecordingChat(false);
            setActiveRecordingType(null);
          } else if (event.error === 'aborted') {
            // Aborted means user stopped it or another recording started
            setIsRecordingChat(false);
            setActiveRecordingType(null);
          } else {
            // For network errors, try to restart
            setTimeout(() => {
              if (isRecordingChat && activeRecordingType === 'chat') {
                try {
                  recognition.start();
                } catch (e) {
                  console.log('Could not restart recognition');
                }
              }
            }, 100);
          }
        };
        
        recognition.onend = () => {
          console.log('Chat recognition ended, isRecordingChat:', isRecordingChat);
          // Don't auto-restart, user must manually stop
          if (activeRecordingType !== 'chat') {
            setIsRecordingChat(false);
          }
        };
        
        recognitionRef.current = recognition;
        
        try {
          recognition.start();
        } catch (e) {
          console.error('Could not start recognition:', e);
          setIsRecordingChat(false);
          setActiveRecordingType(null);
        }
      }
    }
  };

  const stopChatRecognition = () => {
    console.log('Stopping chat recognition');
    if (recognitionRef.current) {
      try {
        recognitionRef.current.stop();
      } catch (e) {
        console.log('Recognition already stopped');
      }
      recognitionRef.current = null;
    }
    setIsRecordingChat(false);
    setActiveRecordingType(null);
  };

  const handleAppleSignIn = () => {
    const message = 'Apple Sign In - Demo modunda kullanılamaz';
    if (Platform.OS === 'web') {
      alert(`Demo Mode\n\n${message}`);
    } else {
      Alert.alert('Demo Mode', message);
    }
  };

  const handleGoogleCallback = async (hash: string) => {
    try {
      // Hash'ten parametreleri çıkar
      const params = new URLSearchParams(hash.substring(1));
      const accessToken = params.get('access_token');
      const state = params.get('state');
      
      // State kontrolü (CSRF koruması)
      const savedState = sessionStorage.getItem('oauth_state');
      if (state && savedState && state !== savedState) {
        console.error('State mismatch - possible CSRF attack');
        Alert.alert('Güvenlik Hatası', 'Oturum açma işlemi güvenlik nedeniyle reddedildi.');
        return;
      }
      
      // State'i temizle
      sessionStorage.removeItem('oauth_state');
      
      if (accessToken) {
        // Google API'den kullanıcı bilgilerini al
        const response = await fetch('https://www.googleapis.com/oauth2/v2/userinfo', {
          headers: {
            'Authorization': `Bearer ${accessToken}`
          }
        });
        
        if (response.ok) {
          const userData = await response.json();
          console.log('Google user data:', userData);
          
          // Email'i kaydet ve login yap
          if (userData.email) {
            setEmail(userData.email);
            localStorage.setItem('userEmail', userData.email);
            localStorage.setItem('userName', userData.name || '');
            localStorage.setItem('userPicture', userData.picture || '');
            setIsAuthenticated(true);
            setCurrentScreen('home');
            
            if (Platform.OS !== 'web' && userData.email) {
            }
            
            // Save auth session for persistence
            await saveAuthSession();
            
            // URL'den token'ı temizle
            window.history.replaceState({}, '', '/');
          }
        }
      }
    } catch (error) {
      console.error('Error processing Google callback:', error);
    }
  };
  
  const handleGoogleSignIn = async () => {
    try {
      const clientId = '1081510942447-mpjnej5fbs9vn262m4sccp3lcufmr9du.apps.googleusercontent.com';
      
      if (Platform.OS === 'web') {
        // Web için - Safari ve diğer tarayıcılar için düzeltilmiş implementasyon
        const currentOrigin = window.location.origin;
        
        // Production'da https://personax.app kullan, localhost'ta http://localhost:8081
        let redirectUri = currentOrigin;
        if (currentOrigin.includes('localhost')) {
          redirectUri = 'http://localhost:8081';
        } else if (currentOrigin.includes('personax.app')) {
          // www prefix'i olmadan kullan
          redirectUri = 'https://personax.app';
        }
        
        const encodedRedirectUri = encodeURIComponent(redirectUri);
        const scope = encodeURIComponent('email profile openid');
        const responseType = 'token';
        const prompt = 'select_account'; // Her zaman hesap seçimi göster
        
        // State parametresi ekle (CSRF koruması için)
        const state = Math.random().toString(36).substring(7);
        sessionStorage.setItem('oauth_state', state);
        
        const authUrl = `https://accounts.google.com/o/oauth2/v2/auth?` +
          `client_id=${clientId}&` +
          `redirect_uri=${encodedRedirectUri}&` +
          `response_type=${responseType}&` +
          `scope=${scope}&` +
          `prompt=${prompt}&` +
          `state=${state}&` +
          `access_type=online`;
        
        console.log('Redirecting to Google OAuth:', authUrl);
        console.log('Current origin:', currentOrigin);
        console.log('Redirect URI:', redirectUri);
        
        // Google login sayfasına yönlendir
        window.location.href = authUrl;
      } else {
        // iOS ve Android için expo-auth-session kullan
        // iOS Safari için useProxy: false kullan
        const useProxy = Platform.OS === 'android'; // Sadece Android'de proxy kullan
        
        const redirectUri = AuthSession.makeRedirectUri({
          scheme: 'com.personax.app',
          useProxy: useProxy,
          preferLocalhost: false,
          path: 'redirect'
        });
        
        console.log('Mobile redirect URI:', redirectUri);
        console.log('Platform:', Platform.OS);
        console.log('Using proxy:', useProxy);
        
        const discovery = {
          authorizationEndpoint: 'https://accounts.google.com/o/oauth2/v2/auth',
          tokenEndpoint: 'https://oauth2.googleapis.com/token',
        };
        
        const request = new AuthSession.AuthRequest({
          clientId,
          scopes: ['openid', 'profile', 'email'],
          redirectUri,
          responseType: AuthSession.ResponseType.Token,
          prompt: AuthSession.Prompt.SelectAccount,
          usePKCE: false,
        });
        
        const result = await request.promptAsync(discovery);
        
        if (result.type === 'success' && result.params && result.params.access_token) {
          // Google API'den kullanıcı bilgilerini al
          const userInfoResponse = await fetch('https://www.googleapis.com/oauth2/v2/userinfo', {
            headers: {
              'Authorization': `Bearer ${result.params.access_token}`
            }
          });
          
          const userInfo = await userInfoResponse.json();
          console.log('Google user info:', userInfo);
          
          // Kullanıcı bilgilerini kaydet ve giriş yap
          setIsAuthenticated(true);
          setEmail(userInfo.email);
          setCurrentScreen('home');
          
          if (Platform.OS !== 'web') {
          }
          
          // Başarılı giriş mesajı
          Alert.alert('Başarılı', `Hoş geldiniz, ${userInfo.name || userInfo.email}!`);
        } else if (result.type === 'cancel') {
          console.log('Google sign-in cancelled');
        } else if (result.type === 'error') {
          console.error('Google sign-in error:', result.error);
          Alert.alert('Hata', 'Google ile giriş yapılamadı. Lütfen tekrar deneyin.');
        }
      }
    } catch (error) {
      console.error('Google sign in error:', error);
      const errorMessage = 'Google ile giriş yapılırken hata oluştu';
      if (Platform.OS === 'web') {
        alert(errorMessage);
      } else {
        Alert.alert('Hata', errorMessage);
      }
    }
  };

  const handleNewPersonAnalysis = () => {
    setContinueDraft(null); // Clear any draft data
    setCurrentScreen('newPersonAnalysis');
  };
  
  const handleSelfAnalysis = () => {
    // Yeni form ekranına yönlendir
    setCurrentScreen('NewForms');
  };
  
  const handleRelationshipAnalysis = () => {
    setCurrentScreen('s4form');
  };

  const RelationPicker = ({ onPick, selectedRelation }: any) => {
    const options = [
      { key:'mother', label:'Annem' }, 
      { key:'father', label:'Babam' }, 
      { key:'sibling', label:'Kardeşim' }, 
      { key:'relative', label:'Akraba' },
      { key:'best_friend', label:'Yakın Arkadaş' }, 
      { key:'friend', label:'Arkadaş' }, 
      { key:'roommate', label:'Ev Arkadaşı' }, 
      { key:'neighbor', label:'Komşu' },
      { key:'crush', label:'Hoşlandığım Kişi' }, 
      { key:'date', label:'Flört' }, 
      { key:'partner', label:'Sevgili/Partner' }, 
      { key:'fiance', label:'Nişanlı' }, 
      { key:'spouse', label:'Eş' },
      { key:'coworker', label:'İş Arkadaşı' }, 
      { key:'manager', label:'Yönetici' }, 
      { key:'direct_report', label:'Ekip Üyem' }, 
      { key:'client', label:'Müşteri' }, 
      { key:'vendor', label:'Tedarikçi' },
      { key:'mentor', label:'Mentor' }, 
      { key:'mentee', label:'Menti/Öğrenci' },
    ];
    
    return (
      <View style={styles.relationPickerContainer}>
        <Text style={styles.relationPickerTitle}>İlişki Türünü Seçin:</Text>
        <ScrollView style={styles.relationPickerScroll} showsVerticalScrollIndicator={false}>
          {options.map(o => (
            <TouchableOpacity 
              key={o.key} 
              onPress={() => onPick(o)} 
              style={[
                styles.relationOption,
                selectedRelation?.key === o.key && styles.relationOptionSelected
              ]}
            >
              <Text style={[
                styles.relationOptionText,
                selectedRelation?.key === o.key && styles.relationOptionTextSelected
              ]}>{o.label}</Text>
            </TouchableOpacity>
          ))}
        </ScrollView>
      </View>
    );
  };

  const LikertRow = ({ item, onChange, value, isHighlighted }: any) => {
    // Check if this is a Likert6 with "Bilmiyorum" option
    const isLikert6 = item.type === 'Likert6' || (item.options_tr && item.options_tr.includes('?: Bilmiyorum'));
    
    // For Likert scales, always use numbers
    let labels: string[] = [];
    let values: any[] = [];
    
    if (isLikert6) {
      // Likert6: 1-5 + "?" for "Bilmiyorum"
      labels = ['1', '2', '3', '4', '5', '?'];
      values = [1, 2, 3, 4, 5, '?'];
    } else {
      // Default Likert5: 1-5
      labels = ['1', '2', '3', '4', '5'];
      values = [1, 2, 3, 4, 5];
    }
    
    // Show scale explanation
    const scaleLabel = '1: Kesinlikle Katılmıyorum - 5: Kesinlikle Katılıyorum';
    
    return (
      <View style={[
        styles.questionContainer,
        isHighlighted && styles.questionContainerHighlighted
      ]}>
        <Text style={[
          styles.questionText,
          isHighlighted && styles.questionTextHighlighted
        ]}>
          {(item.text_tr || '').replace('[AD]', 'Kişi')}
        </Text>
        <Text style={styles.likertScaleLabel}>{scaleLabel}</Text>
        <View style={styles.likertOptions}>
          {labels.map((label: string, idx: number) => (
            <TouchableOpacity 
              key={idx} 
              onPress={() => onChange(values[idx])} 
              style={[
                styles.likertOption,
                value === values[idx] && styles.likertOptionSelected,
                isHighlighted && !value && styles.likertOptionHighlighted
              ]}
            >
              <Text style={[
                styles.likertOptionText,
                value === values[idx] && styles.likertOptionTextSelected
              ]}>{label}</Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>
    );
  };

  const MultiRow = ({ item, onChange, value }: any) => {
    const opts = (item.options_tr || '').split('|');
    return (
      <View style={styles.questionContainer}>
        <Text style={styles.questionText}>
          {(item.text_tr || '').replace('[AD]', 'Kişi')}
        </Text>
        <View style={styles.multiOptions}>
          {opts.map((opt: string, idx: number) => {
            // Check if this is the "?: Bilmiyorum" option
            const isDontKnow = opt.startsWith('?:');
            const optionValue = isDontKnow ? '?' : String.fromCharCode(65 + idx);
            const displayText = isDontKnow ? opt.substring(3).trim() : opt;
            
            return (
              <TouchableOpacity 
                key={idx} 
                onPress={() => onChange(optionValue)} 
                style={[
                  styles.multiOption,
                  value === optionValue && styles.multiOptionSelected
                ]}
              >
                <Text style={[
                  styles.multiOptionText,
                  value === optionValue && styles.multiOptionTextSelected
                ]}>{displayText}</Text>
              </TouchableOpacity>
            );
          })}
        </View>
      </View>
    );
  };

  const OpenTextRow = ({ item, onChange, value, isHighlighted }: any) => {
    return (
      <View style={[
        styles.questionContainer,
        isHighlighted && styles.questionContainerHighlighted
      ]}>
        <Text style={[
          styles.questionText,
          isHighlighted && styles.questionTextHighlighted
        ]}>
          {(item.text_tr || '').replace('[AD]', 'Kişi')}
        </Text>
        <TextInput
          style={[
            styles.openTextInput,
            isHighlighted && !value && styles.openTextInputHighlighted
          ]}
          value={value || ''}
          onChangeText={onChange}
          placeholder={item.options_tr || 'Cevabınızı yazınız...'}
          placeholderTextColor="rgb(0,0,0)"
          multiline
          numberOfLines={4}
        />
      </View>
    );
  };
  
  const ForcedRow = ({ item, onChange, value }: any) => {
    const opts = (item.options_tr || '').split('|');
    return (
      <View style={styles.questionContainer}>
        <Text style={styles.questionText}>
          {(item.text_tr || '').replace('[AD]', 'Kişi')}
        </Text>
        <View style={styles.forcedOptions}>
          {opts.map((opt: string, idx: number) => (
            <TouchableOpacity 
              key={idx} 
              onPress={() => onChange(idx === 0 ? 'A' : 'B')} 
              style={[
                styles.forcedOption,
                value === (idx === 0 ? 'A' : 'B') && styles.forcedOptionSelected
              ]}
            >
              <Text style={[
                styles.forcedOptionText,
                value === (idx === 0 ? 'A' : 'B') && styles.forcedOptionTextSelected
              ]}>{opt}</Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>
    );
  };





  // Show loading screen while checking auth
  if (isLoading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.loadingContainer}>
          <Text style={styles.logoLarge}>🧠</Text>
          <Text style={styles.appName}>Cogni Coach</Text>
          <Text style={styles.loadingText}>Yükleniyor...</Text>
        </View>
      </SafeAreaView>
    );
  }

  if (isAuthenticated) {
    if (currentScreen === 'people') {
      return <PeopleScreen />;
    }
    
    if (currentScreen === 'reports') {
      return <ReportsScreen />;
    }
    
    if (currentScreen === 'newPersonAnalysis') {
      return <NewPersonAnalysisScreen 
        onClose={() => {
          setContinueDraft(null);
          setCurrentScreen('home');
        }}
        userEmail={email}
        draftId={continueDraft?.id || null}
        draftData={continueDraft}
        activeRecordingType={activeRecordingType}
        setActiveRecordingType={setActiveRecordingType}
        stopAnyActiveRecording={stopAnyActiveRecording}
      />;
    }
    
    
    if (currentScreen === 'PaymentCheck') {
      console.log('=== RENDERING PAYMENTCHECKSCREEN ===');
      console.log('currentScreen is:', currentScreen);
      console.trace('PaymentCheckScreen render call stack');
      console.log('paymentParams exists:', !!paymentParams);
      if (paymentParams) {
        console.log('paymentParams keys:', Object.keys(paymentParams));
        console.log('paymentParams.form1Data exists:', !!paymentParams.form1Data);
        console.log('paymentParams.form2Data exists:', !!paymentParams.form2Data);
        console.log('paymentParams.form3Data exists:', !!paymentParams.form3Data);
      } else {
        console.log('paymentParams is null/undefined/false:', paymentParams);
      }
      
      return <PaymentCheckScreen 
        navigation={{ 
          navigate: (screen: string, params?: any) => {
            if (screen === 'PaymentCheck' && params) {
              setPaymentParams(params);
            }
            setCurrentScreen(screen);
          },
          goBack: () => setCurrentScreen('home')
        }}
        route={{
          params: {
            serviceType: 'self_analysis',
            userEmail: paymentParams?.userEmail || email,
            form1Data: paymentParams?.form1Data,
            form2Data: paymentParams?.form2Data,
            form3Data: paymentParams?.form3Data,
            formData: paymentParams?.formData || {},
            onComplete: (result: any) => {
              console.log('Analysis complete:', result);
              // Navigate to result screen or show result
            }
          }
        }}
      />;
    }
    
    if (currentScreen === 'AccountInfo') {
      return <AccountInfoScreen 
        navigation={{ 
          goBack: () => setCurrentScreen('home')
        }}
        userEmail={email}
      />;
    }
    
    if (currentScreen === 'MyAnalyses') {
      return <MyAnalysesScreen 
        navigation={{ 
          navigate: (screen: string, params?: any) => {
            if (screen === 'AnalysisResult') {
              setAnalysisResultParams(params);
              setCurrentScreen(screen);
            } else if (screen === 'NewForms') {
              // Navigate to new forms system
              setCurrentScreen('NewForms');
            } else if (screen === 'S0Form' && params?.editMode) {
              // Handle old edit mode navigation (for backward compatibility)
              setEditMode(true);
              setExistingS0Data(params.existingS0Data);
              setExistingS1Data(params.existingS1Data);
              setEditAnalysisId(params.analysisId);
              setCurrentScreen('s0profile');
            } else {
              setCurrentScreen(screen);
            }
          },
          goBack: () => setCurrentScreen('home')
        }}
        userEmail={email}
      />;
    }
    
    if (currentScreen === 'AnalysisResult') {
      return <AnalysisResultScreen 
        navigation={{ 
          navigate: (screen: string, params?: any) => {
            setCurrentScreen(screen);
          },
          goBack: () => setCurrentScreen('MyAnalyses')
        }}
        route={{ params: analysisResultParams }}
      />;
    }
    
    if (currentScreen === 'NewForms') {
      return <NewFormsScreen 
        navigation={{ 
          navigate: (screen: string, params?: any) => {
            console.log(`=== NEWFORMS NAVIGATION CALLED: screen="${screen}" ===`);
            
            if (screen === 'PaymentCheck') {
              // Store form data and navigate with email
              console.log('=== NAVIGATION FROM NEWFORMS TO PAYMENTCHECK ===');
              console.log('Received params:', params);
              console.log('form1Data exists:', !!params?.form1Data);
              console.log('form2Data exists:', !!params?.form2Data);
              console.log('form3Data exists:', !!params?.form3Data);
              
              if (params?.form1Data) {
                console.log('Form1 keys count:', Object.keys(params.form1Data).length);
                console.log('Form1 sample:', Object.keys(params.form1Data).slice(0, 3));
              }
              if (params?.form2Data) {
                console.log('Form2 keys count:', Object.keys(params.form2Data).length);
                console.log('Form2 sample:', Object.keys(params.form2Data).slice(0, 3));
              }
              if (params?.form3Data) {
                console.log('Form3 keys count:', Object.keys(params.form3Data).length);
                console.log('Form3 sample:', Object.keys(params.form3Data).slice(0, 3));
              }
              
              const paymentData = { ...params, userEmail: email };
              console.log('Setting paymentParams with:', Object.keys(paymentData));
              setPaymentParams(paymentData);
              setCurrentScreen(screen);
            } else if (screen === 'MyAnalyses') {
              setCurrentScreen(screen);
            } else {
              console.log(`Setting screen to: ${screen}`);
              setCurrentScreen(screen);
            }
          },
          goBack: () => setCurrentScreen('home')
        }}
        route={{ params: { userEmail: email } }}
        activeRecordingType={activeRecordingType}
        setActiveRecordingType={setActiveRecordingType}
        stopAnyActiveRecording={stopAnyActiveRecording}
      />;
    }
    
    // Home Screen
    return (
      <SafeAreaView style={styles.container}>
        <View style={[styles.screenContainer, styles.webContainer]}>
          {/* Header with Profile */}
          <View style={styles.homeHeader}>
            <TouchableOpacity 
              activeOpacity={1}
              onPress={() => {
                const newCount = secretClicks + 1;
                setSecretClicks(newCount);
                
                // Reset counter after 2 seconds
                setTimeout(() => setSecretClicks(0), 2000);
                
                // Open admin panel after 3 clicks
                if (newCount >= 3) {
                  setCurrentScreen('admin-pricing');
                  setSecretClicks(0);
                }
              }}
            >
              <Image 
                source={cogniCoachLogo} 
                style={styles.homeLogo}
                resizeMode="contain"
              />
            </TouchableOpacity>
            <View style={styles.headerRight}>
              <TouchableOpacity 
                style={styles.languageButton} 
                onPress={() => setShowLanguageMenu(!showLanguageMenu)}
              >
                <Text style={styles.languageButtonText}>🌐 {selectedLanguage.toUpperCase()}</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.profileButton} onPress={() => setShowProfileMenu(!showProfileMenu)}>
                <Text style={styles.profileInitial}>
                  {email ? email[0].toUpperCase() : 'U'}
                </Text>
              </TouchableOpacity>
            </View>
          </View>
          
          {/* Overlay to close menus when clicking outside */}
          {(showProfileMenu || showLanguageMenu) && (
            <TouchableOpacity 
              style={styles.menuOverlay} 
              activeOpacity={1}
              onPress={() => {
                setShowProfileMenu(false);
                setShowLanguageMenu(false);
              }}
            />
          )}
          
          {/* Profile Dropdown Menu */}
          {showProfileMenu && (
            <View style={styles.profileMenu}>
              <View style={styles.profileMenuHeader}>
                <Text style={styles.profileMenuEmail}>{email}</Text>
              </View>
              <TouchableOpacity 
                style={styles.profileMenuItem} 
                onPress={() => {
                  setShowProfileMenu(false);
                  setCurrentScreen('AccountInfo');
                }}
              >
                <Text style={styles.profileMenuItemText}>👤 Bilgilerim</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.profileMenuItem} onPress={handleLogout}>
                <Text style={styles.profileMenuItemText}>🚪 Çıkış Yap</Text>
              </TouchableOpacity>
            </View>
          )}
          
          {/* Language Dropdown Menu */}
          {showLanguageMenu && (
            <View style={styles.languageMenu}>
              <TouchableOpacity style={styles.languageOption} onPress={() => handleLanguageChange('tr')}>
                <Text style={styles.languageOptionText}>🇹🇷 Türkçe</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.languageOption} onPress={() => handleLanguageChange('en')}>
                <Text style={styles.languageOptionText}>🇬🇧 English</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.languageOption} onPress={() => handleLanguageChange('ar')}>
                <Text style={styles.languageOptionText}>🇸🇦 العربية</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.languageOption} onPress={() => handleLanguageChange('es')}>
                <Text style={styles.languageOptionText}>🇪🇸 Español</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.languageOption} onPress={() => handleLanguageChange('ru')}>
                <Text style={styles.languageOptionText}>🇷🇺 Русский</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.languageOption} onPress={() => handleLanguageChange('de')}>
                <Text style={styles.languageOptionText}>🇩🇪 Deutsch</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.languageOption} onPress={() => handleLanguageChange('fr')}>
                <Text style={styles.languageOptionText}>🇫🇷 Français</Text>
              </TouchableOpacity>
            </View>
          )}

          <ScrollView showsVerticalScrollIndicator={false} style={styles.content}>
            {/* AI Chat Window */}
            <View style={styles.aiChatWindow}>
              <View style={styles.aiChatInputContainer}>
                <TextInput
                  style={[styles.aiChatTextArea, !hasSelfAnalysis && styles.aiChatTextAreaDisabled]}
                  placeholder={!hasSelfAnalysis ? 
                    "Cogni Coach ile konuşmak için önce sizi tanımam lazım. Bunun için kendi analizinizi tamamlamanız gerekiyor. Alttaki Kendi Analizim butonuna tıklayın" : 
                    "Cogni Coach'a ne sormak ya da ne anlatmak istersin? Hadi laflayalım biraz..."}
                  placeholderTextColor="#9CA3AF"
                  multiline
                  numberOfLines={4}
                  value={chatMessage}
                  onChangeText={setChatMessage}
                  editable={hasSelfAnalysis}
                  {...(Platform.OS === 'web' ? { 'data-chat-input': true } : {})}
                />
                {hasSelfAnalysis && (
                  <TouchableOpacity 
                    style={[styles.micButtonChat, isRecordingChat && styles.micButtonChatActive]}
                    {...(Platform.OS === 'web' ? { 'data-recording-button': true } : {})}
                    onPress={(e) => {
                      if (Platform.OS === 'web') {
                        e.stopPropagation(); // Prevent triggering global click handler
                      }
                      if (isRecordingChat) {
                        stopChatRecognition();
                      } else {
                        startChatRecognition();
                      }
                    }}
                  >
                    {isRecordingChat ? (
                      <Text style={styles.micIconChat}>🔴</Text>
                    ) : (
                      <Image 
                        source={micIcon} 
                        style={styles.micImage}
                        resizeMode="contain"
                      />
                    )}
                  </TouchableOpacity>
                )}
                <TouchableOpacity 
                  style={[
                    styles.aiChatSendButton, 
                    (!hasSelfAnalysis || !chatMessage.trim()) ? styles.aiChatSendButtonDisabled : null
                  ]}
                  onPress={() => {
                    if (hasSelfAnalysis && chatMessage.trim()) {
                      // TODO: Send message to coach
                      setCurrentScreen('chat');
                      setChatMessage('');
                    }
                  }}
                  disabled={!hasSelfAnalysis || !chatMessage.trim()}
                >
                  <View style={styles.sendIconContainer}>
                    <Text style={styles.sendIcon}>↑</Text>
                  </View>
                </TouchableOpacity>
              </View>
            </View>
            
            {/* Kendi Analizim Button */}
            <View style={styles.sectionContainer}>
              <TouchableOpacity 
                style={styles.fullWidthButton}
                onPress={async () => {
                  console.log('=== KENDI ANALIZIM BUTTON CLICKED ===');
                  console.log('hasSelfAnalysis state:', hasSelfAnalysis);
                  console.log('Current email:', email);
                  
                  // Double-check by making a fresh API call
                  try {
                    const response = await fetch(`${API_URL}/v1/user/analyses`, {
                      headers: {
                        'x-user-email': email,
                      },
                    });
                    
                    if (response.ok) {
                      const data = await response.json();
                      const selfAnalyses = (data.analyses || []).filter(
                        (a: any) => a.analysis_type === 'self' && a.status === 'completed'
                      );
                      const hasAnalysisNow = selfAnalyses.length > 0;
                      
                      console.log('Fresh API check - Has self analysis:', hasAnalysisNow);
                      
                      if (hasAnalysisNow) {
                        console.log('User HAS self analysis, navigating to MyAnalyses');
                        setHasSelfAnalysis(true); // Update state
                        setCurrentScreen('MyAnalyses');
                      } else {
                        console.log('No self analysis found, starting new one');
                        handleSelfAnalysis();
                      }
                    } else {
                      // Fallback to state if API fails
                      if (hasSelfAnalysis) {
                        setCurrentScreen('MyAnalyses');
                      } else {
                        handleSelfAnalysis();
                      }
                    }
                  } catch (error) {
                    console.error('Error checking analyses:', error);
                    // Fallback to state if API fails
                    if (hasSelfAnalysis) {
                      setCurrentScreen('MyAnalyses');
                    } else {
                      handleSelfAnalysis();
                    }
                  }
                }}
              >
                <Text style={styles.fullWidthButtonText}>
                  {hasSelfAnalysis ? 'Kendi Analizim' : 'Kendi Analizimi Başlat'}
                </Text>
              </TouchableOpacity>
            </View>

            {/* Kişi Analizleri Section */}
            <View style={styles.sectionContainer}>
              <Text style={styles.sectionTitle}>Kişi Analizleri</Text>
              <View style={styles.analysisButtonsContainer}>
                <TouchableOpacity 
                  style={styles.analysisButton}
                  onPress={handleNewPersonAnalysis}
                >
                  <Text style={styles.analysisButtonText}>➕ Yeni Analiz</Text>
                </TouchableOpacity>
                
                {/* Show drafts first */}
                {personDrafts.map((draft) => (
                  <View key={draft.id} style={styles.draftContainer}>
                    <TouchableOpacity 
                      style={[styles.analysisButton, styles.draftButton]}
                      onPress={() => {
                        setContinueDraft(draft);
                        setCurrentScreen('newPersonAnalysis');
                      }}
                    >
                      <Text style={styles.draftBadge}>TASLAK</Text>
                      <Text style={styles.analysisButtonText}>{draft.personName}</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                      style={styles.draftMenuButton}
                      onPress={() => setShowDraftMenu(showDraftMenu === draft.id ? null : draft.id)}
                      {...(Platform.OS === 'web' ? { 'data-draft-menu-button': true } : {})}
                    >
                      <Text style={styles.draftMenuIcon}>⋮</Text>
                    </TouchableOpacity>
                    
                    {showDraftMenu === draft.id && (
                      <View 
                        style={styles.draftMenu}
                        {...(Platform.OS === 'web' ? { 'data-draft-menu': true } : {})}
                      >
                        <TouchableOpacity
                          style={styles.draftMenuItem}
                          onPress={() => {
                            setContinueDraft(draft);
                            setCurrentScreen('newPersonAnalysis');
                            setShowDraftMenu(null);
                          }}
                        >
                          <Text style={styles.draftMenuText}>Analize devam et</Text>
                        </TouchableOpacity>
                        <TouchableOpacity
                          style={styles.draftMenuItem}
                          onPress={async () => {
                            // Delete draft
                            try {
                              let draftsJson;
                              if (Platform.OS === 'web') {
                                draftsJson = localStorage.getItem('personAnalysisDrafts');
                              } else {
                                const AsyncStorage = require('@react-native-async-storage/async-storage').default;
                                draftsJson = await AsyncStorage.getItem('personAnalysisDrafts');
                              }
                              const drafts = draftsJson ? JSON.parse(draftsJson) : [];
                              const updatedDrafts = drafts.filter((d: any) => d.id !== draft.id);
                              
                              if (Platform.OS === 'web') {
                                localStorage.setItem('personAnalysisDrafts', JSON.stringify(updatedDrafts));
                              } else {
                                const AsyncStorage = require('@react-native-async-storage/async-storage').default;
                                await AsyncStorage.setItem('personAnalysisDrafts', JSON.stringify(updatedDrafts));
                              }
                              
                              setPersonDrafts(updatedDrafts.filter((d: any) => d.status === 'draft'));
                              setShowDraftMenu(null);
                            } catch (error) {
                              console.error('Error deleting draft:', error);
                            }
                          }}
                        >
                          <Text style={[styles.draftMenuText, { color: '#EF4444' }]}>Sil</Text>
                        </TouchableOpacity>
                      </View>
                    )}
                  </View>
                ))}
                
                {/* Show recent person analyses */}
                {personAnalyses.slice(0, 8 - personDrafts.length).map((person, index) => (
                  <TouchableOpacity 
                    key={`analysis-${index}`}
                    style={styles.analysisButton}
                    onPress={() => {
                      // Navigate to person's analysis
                      setCurrentScreen('MyAnalyses');
                    }}
                  >
                    <Text style={styles.analysisButtonText}>{person}</Text>
                  </TouchableOpacity>
                ))}
                
                {/* Show 'Tümü' button if there are more than 8 analyses */}
                {personAnalyses.length > 8 && (
                  <TouchableOpacity 
                    style={styles.analysisButton}
                    onPress={() => setCurrentScreen('MyAnalyses')}
                  >
                    <Text style={styles.analysisButtonText}>📋 Tümü</Text>
                  </TouchableOpacity>
                )}
              </View>
            </View>

            {/* İlişki Analizleri Section */}
            <View style={styles.sectionContainer}>
              <Text style={styles.sectionTitle}>İlişki Analizleri</Text>
              <View style={styles.analysisButtonsContainer}>
                <TouchableOpacity 
                  style={styles.analysisButton}
                  onPress={() => setCurrentScreen('reports')}
                >
                  <Text style={styles.analysisButtonText}>➕ Yeni Analiz</Text>
                </TouchableOpacity>
                
                {/* Show recent relation analyses */}
                {relationAnalyses.slice(0, 8).map((relation, index) => (
                  <TouchableOpacity 
                    key={index}
                    style={styles.analysisButton}
                    onPress={() => setCurrentScreen('reports')}
                  >
                    <Text style={styles.analysisButtonText}>{relation}</Text>
                  </TouchableOpacity>
                ))}
                
                {/* Show 'Tümü' button if there are more than 8 analyses */}
                {relationAnalyses.length > 8 && (
                  <TouchableOpacity 
                    style={styles.analysisButton}
                    onPress={() => setCurrentScreen('reports')}
                  >
                    <Text style={styles.analysisButtonText}>📋 Tümü</Text>
                  </TouchableOpacity>
                )}
              </View>
            </View>

            {/* Bottom Spacing */}
            <View style={styles.bottomSpacing} />
          </ScrollView>
        </View>
      </SafeAreaView>
    );
  }

  // Login Screen
  return (
    <SafeAreaView style={styles.container}>
      <ScrollView 
        contentContainerStyle={styles.authScrollContent}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.authContainer}>
          {/* Logo and Title */}
          <View style={styles.authHeader}>
            <Text style={styles.logoLarge}>🧠</Text>
            <Text style={styles.authTitle}>My Life Coach</Text>
            <Text style={styles.authSubtitle}>Kişilik ve İlişki Analizleri</Text>
          </View>

          {/* Login Form */}
          <View style={styles.formContainer}>
            <View style={styles.inputWrapper}>
              <Text style={styles.inputLabel}>Email</Text>
              <TextInput
                style={styles.input}
                placeholder="email@example.com"
                placeholderTextColor="#9CA3AF"
                value={email}
                onChangeText={setEmail}
                keyboardType="email-address"
                autoCapitalize="none"
                autoCorrect={false}
              />
            </View>

            <View style={styles.inputWrapper}>
              <Text style={styles.inputLabel}>Şifre</Text>
              <TextInput
                style={styles.input}
                placeholder="••••••••"
                placeholderTextColor="#9CA3AF"
                value={password}
                onChangeText={setPassword}
                secureTextEntry
                autoCapitalize="none"
                autoCorrect={false}
              />
            </View>

            <TouchableOpacity 
              style={styles.loginButton}
              onPress={handleEmailSignIn}
            >
              <Text style={styles.loginButtonText}>Giriş Yap</Text>
            </TouchableOpacity>

            {/* Divider */}
            <View style={styles.dividerContainer}>
              <View style={styles.divider} />
              <Text style={styles.dividerText}>veya</Text>
              <View style={styles.divider} />
            </View>

            {/* Social Login */}
            <View style={styles.socialButtons}>
              <TouchableOpacity 
                style={styles.googleButton}
                onPress={handleGoogleSignIn}
              >
                <View style={styles.googleIconContainer}>
                  <Image 
                    source={{ uri: 'https://developers.google.com/identity/images/g-logo.png' }}
                    style={styles.googleIcon}
                  />
                </View>
                <Text style={styles.googleButtonText}>Google ile giriş yap</Text>
              </TouchableOpacity>

              <TouchableOpacity 
                style={[styles.socialButton, styles.appleSocialButton]}
                onPress={handleAppleSignIn}
              >
                <Text style={styles.socialIcon}>🍎</Text>
                <Text style={[styles.socialButtonText, styles.appleText]}>
                  Apple ile devam et
                </Text>
              </TouchableOpacity>
            </View>

          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  webContainer: Platform.select({
    web: {
      maxWidth: 999,
      width: '100%',
      alignSelf: 'center',
    },
    default: {},
  }),
  screenContainer: {
    flex: 1,
    maxWidth: 990,
    width: '100%',
    alignSelf: 'center',
  },
  
  // Header Styles
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 24,
    paddingVertical: 8,  // 20px'ten 8px'e düşürüldü
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  homeHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 24,
    paddingVertical: 10,
    backgroundColor: '#FFFFFF',
  },
  backButtonContainer: {
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
    marginVertical: 8,  // Üst ve alt 8px margin
    textAlign: 'center',
  },
  headerSpacer: {
    width: 40,
  },
  welcomeText: {
    fontSize: 14,
    color: '#64748B',
    marginBottom: 4,
  },
  homeTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: '#1E293B',
  },
  homeLogo: {
    height: 40,
    width: 150,
  },
  headerTitleWithIcon: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerIcon: {
    width: 24,
    height: 24,
    marginRight: 8,
  },
  profileButton: {
    width: 48,
    height: 48,
    borderRadius: 24, // Make it circular
    backgroundColor: 'rgb(96, 187, 202)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  profileIcon: {
    fontSize: 24,
  },
  profileInitial: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  profileImage: {
    width: 40,
    height: 40,
    borderRadius: 3,
  },
  headerRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  languageButton: {
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: '#F1F5F9',
    borderRadius: 3,
  },
  languageButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1E293B',
  },
  languageMenu: {
    position: 'absolute',
    top: 70,
    right: 24,
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    ...Platform.select({
      web: {
        boxShadow: '0px 2px 4px rgba(0, 0, 0, 0.1)',
      },
      default: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
        elevation: 5,
      },
    }),
    zIndex: 1000,
    minWidth: 150,
  },
  languageOption: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  languageOptionText: {
    fontSize: 14,
    color: '#1E293B',
  },
  profileMenu: {
    position: 'absolute',
    top: 70,
    right: 24,
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    ...Platform.select({
      web: {
        boxShadow: '0px 2px 4px rgba(0, 0, 0, 0.1)',
      },
      default: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
        elevation: 5,
      },
    }),
    zIndex: 1000,
    minWidth: 200,
  },
  profileMenuHeader: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
    backgroundColor: '#F8FAFC',
  },
  profileMenuEmail: {
    fontSize: 13,
    color: '#64748B',
    fontWeight: '500',
  },
  profileMenuItem: {
    paddingHorizontal: 16,
    paddingVertical: 14,
    flexDirection: 'row',
    alignItems: 'center',
  },
  profileMenuItemText: {
    fontSize: 14,
    color: '#1E293B',
    fontWeight: '500',
  },
  menuOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    zIndex: 999,
  },

  // Content
  content: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },

  // AI Chat Window
  aiChatWindow: {
    marginHorizontal: 20,
    marginTop: 16,
    marginBottom: 12,
    alignItems: 'center',
  },
  aiChatInputContainer: {
    position: 'relative',
    width: '100%',
    maxWidth: 400,
  },
  aiChatTextArea: {
    width: '100%',
    height: 100,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    padding: 12,
    paddingRight: 50,
    fontSize: 14,
    color: '#1E293B',
    backgroundColor: '#FFFFFF',
    textAlignVertical: 'top',
  },
  aiChatTextAreaDisabled: {
    backgroundColor: '#FFFFFF',
    opacity: 0.9,
  },
  micButtonChat: {
    position: 'absolute',
    right: 55,
    bottom: 8,
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
  },
  micButtonChatActive: {
    // No background for active state
  },
  micIconChat: {
    fontSize: 18,
  },
  micImage: {
    width: 20,
    height: 20,
  },
  aiChatSendButton: {
    position: 'absolute',
    right: 8,
    bottom: 8,
    width: 32,
    height: 32,
    borderRadius: 3,
    backgroundColor: 'rgb(71, 73, 74)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  aiChatSendButtonDisabled: {
    backgroundColor: '#E5E7EB',
  },
  sendIconContainer: {
    width: 20,
    height: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
  sendIcon: {
    fontSize: 18,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  sendIconDisabled: {
    color: '#F8FAFC',
  },
  
  // Analysis Buttons
  analysisButtonsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginTop: 12,
  },
  analysisButton: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  analysisButtonText: {
    fontSize: 14,
    fontWeight: '500',
    color: '#1E293B',
  },
  draftContainer: {
    position: 'relative',
  },
  draftButton: {
    backgroundColor: '#FEF3C7',
    borderColor: '#FCD34D',
    paddingTop: 8,
  },
  draftBadge: {
    fontSize: 10,
    fontWeight: '600',
    color: '#92400E',
    marginBottom: 2,
  },
  draftMenuButton: {
    position: 'absolute',
    top: 0,
    right: 0,
    padding: 8,
    width: 32,
    height: 40,
    justifyContent: 'center',
    alignItems: 'center',
  },
  draftMenuIcon: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#374151',
  },
  draftMenu: {
    position: 'absolute',
    top: 40,
    right: 0,
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 5,
    zIndex: 1000,
    minWidth: 150,
  },
  draftMenuItem: {
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#F3F4F6',
  },
  draftMenuText: {
    fontSize: 14,
    color: '#374151',
  },
  fullWidthButton: {
    width: '100%',
    paddingHorizontal: 16,
    paddingVertical: 10,
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    alignItems: 'center',
  },
  fullWidthButtonText: {
    fontSize: 14,
    fontWeight: '500',
    color: '#1E293B',
  },
  
  // Stats
  statsContainer: {
    flexDirection: 'row',
    paddingHorizontal: 24,
    paddingVertical: 8,  // 20px'ten 8px'e düşürüldü
    backgroundColor: '#FFFFFF',
    gap: 12,
  },
  statCard: {
    flex: 1,
    backgroundColor: '#F8FAFC',
    padding: 16,
    borderRadius: 3,
    alignItems: 'center',
  },
  statNumber: {
    fontSize: 24,
    fontWeight: '700',
    color: '#1E293B',
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 12,
    color: '#64748B',
  },

  // Cards
  cardGrid: {
    flexDirection: 'row',
    paddingHorizontal: 24,
    paddingTop: 20,
    gap: 12,
  },
  actionCard: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    padding: 20,
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  fullWidthCard: {
    marginHorizontal: 24,
    marginTop: 20,
  },
  primaryCard: {
    backgroundColor: '#000000',  // Siyah
    borderColor: '#000000',
  },
  secondaryCard: {
    backgroundColor: '#FFFFFF',
  },
  cardIcon: {
    width: 48,
    height: 48,
    borderRadius: 3,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
  },
  iconText: {
    fontSize: 24,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1E293B',
    marginBottom: 4,
  },
  primaryCardTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  secondaryCardTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1E293B',
    marginBottom: 4,
  },
  cardDescription: {
    fontSize: 14,
    color: '#64748B',
    lineHeight: 20,
  },
  primaryCardDescription: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.9)',
    lineHeight: 20,
  },
  cardContent: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  cardArrow: {
    fontSize: 24,
    color: '#6366F1',
  },

  // Menu Grid
  menuGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
    marginTop: 12,
  },
  menuCard: {
    width: '31%',
    backgroundColor: '#FFFFFF',
    padding: 20,
    borderRadius: 3,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  menuIcon: {
    fontSize: 32,
    marginBottom: 8,
  },
  menuIconImage: {
    width: 48,
    height: 48,
    borderRadius: 3,
    marginBottom: 8,
  },
  menuTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1E293B',
    textAlign: 'center',
  },

  // Sections
  sectionContainer: {
    paddingHorizontal: 24,
    paddingTop: 32,
    paddingBottom: 16,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#1E293B',
    marginBottom: 4,
  },

  // Empty State
  emptyState: {
    backgroundColor: '#FFFFFF',
    padding: 32,
    borderRadius: 3,
    alignItems: 'center',
    marginTop: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  emptyIcon: {
    fontSize: 48,
    marginBottom: 16,
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1E293B',
    marginBottom: 8,
  },
  emptyDescription: {
    fontSize: 14,
    color: '#64748B',
    textAlign: 'center',
    lineHeight: 20,
  },

  // Auth Styles
  authScrollContent: {
    flexGrow: 1,
    justifyContent: 'center',
    paddingVertical: 40,
  },
  authContainer: {
    width: '100%',
    maxWidth: 400,
    alignSelf: 'center',
    paddingHorizontal: 24,
  },
  authHeader: {
    alignItems: 'center',
    marginBottom: 40,
  },
  logoLarge: {
    fontSize: 64,
    marginBottom: 16,
  },
  appName: {
    fontSize: 32,
    fontWeight: '700',
    color: '#1E293B',
    marginBottom: 8,
  },
  authTitle: {
    fontSize: 32,
    fontWeight: '700',
    color: '#1E293B',
    marginBottom: 8,
  },
  authSubtitle: {
    fontSize: 16,
    color: '#64748B',
  },
  formContainer: {
    backgroundColor: '#FFFFFF',
    padding: 24,
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  inputWrapper: {
    marginBottom: 20,
  },
  inputLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1E293B',
    marginBottom: 8,
  },
  input: {
    height: 48,
    backgroundColor: '#F8FAFC',
    borderRadius: 3,
    paddingHorizontal: 16,
    fontSize: 16,
    color: '#1E293B',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  loginButton: {
    height: 48,
    backgroundColor: '#000000',  // Siyah
    borderRadius: 3,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 8,
  },
  loginButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  dividerContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 24,
  },
  divider: {
    flex: 1,
    height: 1,
    backgroundColor: '#E2E8F0',
  },
  dividerText: {
    marginHorizontal: 16,
    color: '#94A3B8',
    fontSize: 14,
  },
  socialButtons: {
    gap: 12,
  },
  googleButton: {
    height: 48,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#DADCE0',
    paddingHorizontal: 12,
    ...Platform.select({
      web: {
        boxShadow: '0 1px 2px 0 rgba(60,64,67,0.3), 0 1px 3px 1px rgba(60,64,67,0.15)',
      },
      default: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 1 },
        shadowOpacity: 0.1,
        shadowRadius: 2,
        elevation: 2,
      }
    }),
  },
  googleIconContainer: {
    width: 20,
    height: 20,
    marginRight: 12,
  },
  googleIcon: {
    width: 20,
    height: 20,
  },
  googleButtonText: {
    fontSize: 14,
    fontWeight: '500',
    color: '#3C4043',
    fontFamily: Platform.select({ 
      web: '"Google Sans", Roboto, sans-serif',
      default: 'System'
    }),
  },
  socialButton: {
    height: 48,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    gap: 8,
  },
  appleSocialButton: {
    backgroundColor: '#000000',
    borderColor: '#000000',
  },
  socialIcon: {
    fontSize: 20,
  },
  socialButtonText: {
    fontSize: 16,
    fontWeight: '500',
    color: '#1E293B',
  },
  appleText: {
    color: '#FFFFFF',
  },
  demoNotice: {
    textAlign: 'center',
    color: '#94A3B8',
    fontSize: 13,
    marginTop: 20,
  },

  // Loading
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    fontSize: 16,
    color: '#64748B',
    marginTop: 12,
  },

  // Utility
  bottomSpacing: {
    height: 40,
  },
  
  // S2 Form Styles
  relationPickerContainer: {
    flex: 1,
    padding: 24,
  },
  relationPickerTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1E293B',
    marginBottom: 16,
  },
  relationPickerScroll: {
    flex: 1,
  },
  relationOption: {
    backgroundColor: '#FFFFFF',
    padding: 16,
    borderRadius: 3,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  relationOptionSelected: {
    backgroundColor: '#000000',  // Siyah
    borderColor: '#000000',
  },
  relationOptionText: {
    fontSize: 16,
    color: '#1E293B',
  },
  relationOptionTextSelected: {
    color: '#FFFFFF',
  },
  selectedRelationCard: {
    backgroundColor: '#FFFFFF',
    padding: 16,
    borderRadius: 3,
    marginBottom: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  selectedRelationLabel: {
    fontSize: 14,
    color: '#64748B',
  },
  selectedRelationText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1E293B',
    flex: 1,
    marginLeft: 8,
  },
  changeRelationButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    backgroundColor: '#F1F5F9',
    borderRadius: 3,
  },
  changeRelationButtonText: {
    fontSize: 14,
    color: '#6366F1',
    fontWeight: '500',
  },
  formContentContainer: {
    padding: 24,
    paddingBottom: 40,
  },
  questionContainer: {
    backgroundColor: 'rgb(45, 55, 72)',  // Koyu gri arka plan
    padding: 16,
    borderRadius: 3,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: 'rgb(45, 55, 72)',
  },
  questionText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',  // Beyaz metin (koyu arka plan için)
    marginBottom: 20,  // Spacing between question and options
    lineHeight: 24,
  },
  likertOptions: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    justifyContent: 'center',
  },
  likertScaleLabel: {
    fontSize: 12,
    color: '#64748B',
    textAlign: 'center',
    marginBottom: 12,
  },
  likertOption: {
    width: 48,
    height: 48,
    borderWidth: 1.5,
    borderColor: '#E5E7EB',
    borderRadius: 3,  // 3px köşe yuvarlatma
    backgroundColor: '#FFFFFF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  likertOptionSelected: {
    backgroundColor: 'rgb(96, 187, 202)',  // Cogni Coach icon rengi
    borderColor: 'rgb(96, 187, 202)',
  },
  likertOptionText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#64748B',
    textAlign: 'center',
  },
  likertOptionTextSelected: {
    color: '#FFFFFF',  // Beyaz yazı
  },
  multiOptions: {
    gap: 8,
  },
  multiOption: {
    paddingVertical: 14,
    paddingHorizontal: 18,
    borderWidth: 1.5,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    backgroundColor: '#FFFFFF',
    marginBottom: 10,
  },
  multiOptionSelected: {
    backgroundColor: 'rgb(96, 187, 202)',  // Cogni Coach icon rengi
    borderColor: 'rgb(96, 187, 202)',
  },
  multiOptionText: {
    fontSize: 14,
    color: '#1E293B',
    lineHeight: 20,
  },
  multiOptionTextSelected: {
    color: '#FFFFFF',  // Beyaz yazı
  },
  submitButton: {
    backgroundColor: 'rgb(45, 55, 72)',  // Koyu gri
    padding: 16,
    borderRadius: 3,
    alignItems: 'center',
    marginTop: 24,
  },
  submitButtonText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  
  // Forced Choice Styles
  forcedOptions: {
    flexDirection: 'row',
    gap: 12,
  },
  forcedOption: {
    flex: 1,
    paddingVertical: 14,
    paddingHorizontal: 12,
    borderWidth: 1.5,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    backgroundColor: '#FFFFFF',
    alignItems: 'center',
  },
  forcedOptionSelected: {
    backgroundColor: 'rgb(96, 187, 202)',  // Cogni Coach icon rengi
    borderColor: 'rgb(96, 187, 202)',
  },
  forcedOptionText: {
    fontSize: 14,
    color: '#1E293B',
    textAlign: 'center',
  },
  forcedOptionTextSelected: {
    color: '#FFFFFF',  // Beyaz yazı
  },
  
  // Domain Tabs
  domainTabs: {
    flexDirection: 'row',
    marginBottom: 20,
    backgroundColor: '#FFFFFF',
    padding: 4,
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  domainTab: {
    flex: 1,
    paddingVertical: 10,
    paddingHorizontal: 12,
    borderRadius: 3,
    alignItems: 'center',
  },
  domainTabActive: {
    backgroundColor: '#000000',  // Siyah
  },
  domainTabText: {
    fontSize: 14,
    fontWeight: '500',
    color: '#64748B',
  },
  domainTabTextActive: {
    color: '#FFFFFF',
  },
  
  // Info Card
  infoCard: {
    backgroundColor: '#F0F9FF',
    padding: 16,
    borderRadius: 3,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#BFDBFE',
  },
  infoText: {
    fontSize: 14,
    color: '#1E40AF',
    lineHeight: 20,
  },
  
  // Instructions Styles
  instructionsCard: {
    backgroundColor: '#FAFAFA',  // Açık gri arka plan
    padding: 20,
    borderRadius: 3,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#E5E7EB',  // Gri kenarlık
  },
  instructionsTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#374151',  // Koyu gri başlık
    marginBottom: 16,
  },
  instructionsContent: {
    marginBottom: 16,
  },
  instructionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  instructionLabel: {
    width: 32,
    height: 32,
    borderRadius: 3,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    textAlign: 'center',
    lineHeight: 30,
    fontSize: 16,
    fontWeight: '600',
    color: '#64748B',
    marginRight: 12,
  },
  instructionText: {
    fontSize: 14,
    color: '#64748B',
    flex: 1,
  },
  defaultOption: {
    color: '#6366F1',
    fontWeight: '600',
    borderColor: '#6366F1',
    backgroundColor: '#EEF2FF',
  },
  instructionNote: {
    fontSize: 13,
    color: '#DC2626',  // Kırmızı renk
    lineHeight: 20,
    backgroundColor: '#FFFFFF',  // Beyaz arka plan
    padding: 14,
    borderRadius: 3,
  },
  
  // Progress Styles
  progressContainer: {
    marginBottom: 20,
  },
  progressHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  progressText: {
    fontSize: 14,
    color: 'rgb(96, 187, 202)',  // Cogni Coach icon rengi
  },
  progressPercentage: {
    fontSize: 15,
    fontWeight: 'bold',
    color: '#000000',  // Siyah
  },
  progressBarBackground: {
    height: 10,  // Daha kalın
    backgroundColor: '#E5E7EB',
    borderRadius: 3,
    overflow: 'hidden',
  },
  progressBarFill: {
    height: '100%',
    backgroundColor: 'rgb(45, 55, 72)',  // Koyu gri
    borderRadius: 3,
  },
  
  // Open Text Input Styles
  openTextInput: {
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    padding: 12,
    fontSize: 14,
    minHeight: 100,
    textAlignVertical: 'top',
    backgroundColor: 'rgb(244,244,244)',
    color: 'rgb(0,0,0)',
    marginTop: 8,
  },
  openTextInputHighlighted: {
    borderColor: '#DC2626',
    borderWidth: 2,
  },
  
  // Section Styles
  sectionInfoCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    padding: 12,
    borderRadius: 3,
    marginBottom: 16,
    borderWidth: 2,
    borderColor: '#6366F1',
  },
  sectionIcon: {
    fontSize: 24,
    marginRight: 12,
  },
  sectionName: {
    fontSize: 16,
    fontWeight: '600',
  },
  sectionDivider: {
    paddingVertical: 12,
    paddingHorizontal: 16,
    marginVertical: 8,
    backgroundColor: 'rgb(45, 55, 72)',  // Koyu gri arka plan
    borderRadius: 3,
  },
  sectionDividerText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',  // Beyaz yazı
  },
  
  // Question Container
  questionsContainer: {
    marginBottom: 20,
  },
  
  // Form Footer
  formFooter: {
    marginTop: 20,
  },
  summaryCard: {
    backgroundColor: '#F0F9FF',
    padding: 16,
    borderRadius: 3,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#BFDBFE',
  },
  summaryTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1E40AF',
    marginBottom: 8,
  },
  summaryText: {
    fontSize: 14,
    color: '#3B82F6',
    lineHeight: 20,
  },
  completedText: {
    fontSize: 14,
    color: '#10B981',
    fontWeight: '600',
    marginTop: 8,
  },
  submitButtonDisabled: {
    opacity: 0.5,
  },
  
  // Relation Picker Enhancements
  relationPickerSubtitle: {
    fontSize: 14,
    color: '#64748B',
    marginBottom: 20,
    textAlign: 'center',
  },
  relationOptionContent: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  relationEmoji: {
    fontSize: 24,
    marginRight: 12,
  },
  
  // Name Input Styles
  nameInputContainer: {
    flex: 1,
    padding: 24,
    justifyContent: 'center',
  },
  nameInputHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 32,
  },
  nameInputEmoji: {
    fontSize: 48,
    marginRight: 16,
  },
  nameInputTitle: {
    fontSize: 24,
    fontWeight: '700',
    color: '#1E293B',
  },
  nameInputLabel: {
    fontSize: 16,
    color: '#64748B',
    marginBottom: 12,
    textAlign: 'center',
  },
  nameInput: {
    height: 56,
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    paddingHorizontal: 16,
    fontSize: 18,
    color: '#1E293B',
    borderWidth: 2,
    borderColor: '#6366F1',
    marginBottom: 24,
    textAlign: 'center',
  },
  nameInputButtons: {
    flexDirection: 'row',
    gap: 12,
  },
  nameInputButtonSecondary: {
    flex: 1,
    height: 48,
    backgroundColor: '#F1F5F9',
    borderRadius: 3,
    justifyContent: 'center',
    alignItems: 'center',
  },
  nameInputButtonSecondaryText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#64748B',
  },
  nameInputButton: {
    flex: 2,
    height: 48,
    backgroundColor: '#6366F1',
    borderRadius: 3,
    justifyContent: 'center',
    alignItems: 'center',
  },
  nameInputButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  
  // Person Info Card
  personInfoCard: {
    backgroundColor: '#FFFFFF',
    padding: 16,
    borderRadius: 3,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  personInfoHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  personInfoEmoji: {
    fontSize: 36,
    marginRight: 12,
  },
  personInfoDetails: {
    flex: 1,
  },
  personInfoName: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1E293B',
    marginBottom: 2,
  },
  personInfoRelation: {
    fontSize: 14,
    color: '#64748B',
  },
  changeButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    backgroundColor: '#F1F5F9',
    borderRadius: 3,
  },
  changeButtonText: {
    fontSize: 14,
    color: '#6366F1',
    fontWeight: '500',
  },
  
  // Filter styles for unanswered questions
  filterContainer: {
    backgroundColor: '#FEF3C7',
    padding: 12,
    marginHorizontal: 24,
    marginBottom: 16,
    borderRadius: 3,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  filterText: {
    fontSize: 14,
    color: '#92400E',
    fontWeight: '500',
    flex: 1,
  },
  filterButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    marginLeft: 12,
  },
  filterButtonText: {
    fontSize: 14,
    color: '#92400E',
    fontWeight: '600',
  },
  
  // Edit Profile Button
  editProfileButton: {
    marginHorizontal: 24,
    marginTop: 16,
    paddingVertical: 12,
    paddingHorizontal: 16,
    backgroundColor: '#F8FAFC',
    borderRadius: 3,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  editProfileButtonText: {
    fontSize: 14,
    color: '#64748B',
    fontWeight: '500',
  },
  
  // Highlighted question styles
  questionContainerHighlighted: {
    borderColor: '#EF4444',
    borderWidth: 2,
    backgroundColor: '#FEF2F2',
  },
  questionTextHighlighted: {
    color: '#991B1B',
    fontWeight: '600',
  },
  
  // Info message styles
  infoMessageCard: {
    backgroundColor: '#EFF6FF',
    padding: 16,
    marginHorizontal: 24,
    marginBottom: 16,
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#DBEAFE',
  },
  infoMessageText: {
    fontSize: 14,
    color: '#1E40AF',
    lineHeight: 20,
    textAlign: 'center',
  },
  
  // Action Button Styles (ince dikdörtgen)
  actionButtonsContainer: {
    paddingHorizontal: 24,
    paddingTop: 20,
    gap: 12,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    padding: 16,
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    marginBottom: 12,
  },
  primaryActionButton: {
    backgroundColor: '#000000',  // Siyah
    borderColor: '#000000',
  },
  actionButtonIcon: {
    fontSize: 24,
    marginRight: 16,
  },
  actionButtonIconImage: {
    width: 40,
    height: 40,
    borderRadius: 3,
    marginRight: 16,
  },
  actionButtonContent: {
    flex: 1,
  },
  actionButtonTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1E293B',
    marginBottom: 2,
  },
  primaryActionButtonTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 2,
  },
  actionButtonDescription: {
    fontSize: 14,
    color: '#64748B',
  },
  primaryActionButtonDescription: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.9)',
  },
});