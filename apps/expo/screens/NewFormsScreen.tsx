import React, { useState, useEffect, useRef, useCallback } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ScrollView,
  StyleSheet,
  SafeAreaView,
  Alert,
  Platform,
  AsyncStorage,
  KeyboardAvoidingView,
  ActivityIndicator,
  Image,
} from 'react-native';
import DraggableRanking from '../components/DraggableRanking';

import { API_URL } from '../config';

interface FormItem {
  id: string;
  text_tr: string;
  type: string;
  section: string;
  options_tr?: string;
  display_order?: number;
  subscale?: string;
  conditional_on?: string;
}

interface FormAnswers {
  [key: string]: any;
}

// Cache buster: Updated at 2024-01-20 15:45
export default function NewFormsScreen({ navigation, route, activeRecordingType, setActiveRecordingType, stopAnyActiveRecording }: any) {
  // Debug route params
  console.log('=== NewFormsScreen Route Params ===');
  console.log('All route params:', route?.params);
  console.log('editMode from params:', route?.params?.editMode);
  console.log('analysisId from params:', route?.params?.analysisId);
  console.log('userEmail from params:', route?.params?.userEmail);
  
  // Check for edit mode params
  const editMode = route?.params?.editMode || false;
  const existingForm1Data = route?.params?.existingForm1Data || {};
  const existingForm2Data = route?.params?.existingForm2Data || {};
  const existingForm3Data = route?.params?.existingForm3Data || {};
  const analysisId = route?.params?.analysisId;
  const userEmail = route?.params?.userEmail;
  const [isLoadingResponses, setIsLoadingResponses] = useState(false);

  const [currentForm, setCurrentForm] = useState(1); // 1, 2, or 3
  const [items, setItems] = useState<FormItem[]>([]);
  const [answers, setAnswers] = useState<FormAnswers>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [isRecording, setIsRecording] = useState<string | null>(null);
  const [showMissingStep, setShowMissingStep] = useState(false);
  const [missingItems, setMissingItems] = useState<FormItem[]>([]);
  const recognitionRef = useRef<any>(null);
  const textInputRefs = useRef<{ [key: string]: TextInput | null }>({});
  const answersRef = useRef<FormAnswers>({});
  const currentFormRef = useRef<number>(1);
  
  // Web Speech API support check
  const speechRecognitionAvailable = Platform.OS === 'web' && 
    typeof window !== 'undefined' && 
    ('webkitSpeechRecognition' in window || 'SpeechRecognition' in window);
    
  // Keep refs in sync with state
  useEffect(() => {
    answersRef.current = answers;
  }, [answers]);
  
  useEffect(() => {
    currentFormRef.current = currentForm;
  }, [currentForm]);

  const formNames = {
    1: 'Form1_Tanisalim',
    2: 'Form2_Kisilik', 
    3: 'Form3_Davranis'
  };

  const formTitles = {
    1: 'Tanışalım',
    2: 'Kişilik & Mizaç',
    3: 'Davranış & Anlatı'
  };


  // Add global click handler to stop recording when clicking outside
  useEffect(() => {
    if (Platform.OS === 'web' && isRecording) {
      const handleGlobalClick = (event: MouseEvent) => {
        const target = event.target as HTMLElement;
        
        // Check if click is on a mic button, text input, or their children
        const isMicButton = target.closest('[data-mic-button]');
        const isTextInput = target.closest('[data-text-input]');
        
        // If clicking outside mic button and text input, stop recording
        if (!isMicButton && !isTextInput) {
          stopSpeechRecognition();
        }
      };
      
      // Add listener with a small delay to avoid immediate triggering
      const timeoutId = setTimeout(() => {
        document.addEventListener('click', handleGlobalClick);
      }, 100);
      
      return () => {
        clearTimeout(timeoutId);
        document.removeEventListener('click', handleGlobalClick);
      };
    }
  }, [isRecording]);

  useEffect(() => {
    console.log('=== NewFormsScreen useEffect ===');
    console.log('EditMode:', editMode);
    console.log('AnalysisId:', analysisId);
    console.log('UserEmail:', userEmail);
    
    // If in edit mode with analysisId, fetch saved responses from database
    if (editMode && analysisId) {
      console.log('Edit mode: Loading analysis responses for ID:', analysisId);
      loadAnalysisResponses();
    } else if (editMode && (existingForm1Data || existingForm2Data || existingForm3Data)) {
      console.log('Calling loadExistingData...');
      loadExistingData();
    } else {
      // Otherwise check if there are saved answers and resume from last incomplete form
      console.log('Checking saved progress...');
      checkSavedProgress();
    }
    
    // Add beforeunload listener for web to save on page refresh/close
    if (Platform.OS === 'web') {
      const handleBeforeUnload = () => {
        // Save current answers using refs to get latest values
        const storageKey = `form${currentFormRef.current}_answers`;
        const currentAnswers = answersRef.current;
        if (Object.keys(currentAnswers).length > 0) {
          localStorage.setItem(storageKey, JSON.stringify(currentAnswers));
          console.log(`Saved ${Object.keys(currentAnswers).length} answers for form ${currentFormRef.current} on page unload`);
        }
      };
      
      window.addEventListener('beforeunload', handleBeforeUnload);
      
      return () => {
        window.removeEventListener('beforeunload', handleBeforeUnload);
      };
    }
  }, []);

  useEffect(() => {
    const loadData = async () => {
      await loadFormItems();
      // Always load answers for the current form
      await loadAnswers();
    };
    loadData();
  }, [currentForm]);

  const loadAnalysisResponses = async () => {
    if (!analysisId) return;
    
    setIsLoadingResponses(true);
    try {
      console.log('Fetching analysis responses for ID:', analysisId);
      const response = await fetch(
        `${API_URL}/v1/analyses/${analysisId}/responses`,
        {
          headers: {
            'x-user-email': userEmail,
          },
        }
      );
      
      if (!response.ok) {
        throw new Error('Failed to load analysis responses');
      }
      
      const data = await response.json();
      console.log('Loaded analysis responses:', data);
      
      // Save the loaded responses to storage
      if (data.form1Data && Object.keys(data.form1Data).length > 0) {
        console.log('Loading Form 1:', Object.keys(data.form1Data).length, 'responses');
        await saveAnswersToStorage(1, data.form1Data);
      }
      if (data.form2Data && Object.keys(data.form2Data).length > 0) {
        console.log('Loading Form 2:', Object.keys(data.form2Data).length, 'responses');
        await saveAnswersToStorage(2, data.form2Data);
      }
      if (data.form3Data && Object.keys(data.form3Data).length > 0) {
        console.log('Loading Form 3:', Object.keys(data.form3Data).length, 'responses');
        await saveAnswersToStorage(3, data.form3Data);
      }
      
      // Start from form 1 for editing
      setCurrentForm(1);
      // Load form 1 answers
      if (data.form1Data && Object.keys(data.form1Data).length > 0) {
        setAnswers(data.form1Data);
      } else if (data.form2Data && Object.keys(data.form2Data).length > 0) {
        // If no form 1 data, start with form 2
        setCurrentForm(2);
        setAnswers(data.form2Data);
      } else if (data.form3Data && Object.keys(data.form3Data).length > 0) {
        // If only form 3 data, start with form 3
        setCurrentForm(3);
        setAnswers(data.form3Data);
      }
      
      console.log('Successfully loaded responses from analysis', analysisId);
    } catch (error) {
      console.error('Error loading analysis responses:', error);
      Alert.alert('Hata', 'Cevaplar yüklenirken bir hata oluştu');
    } finally {
      setIsLoadingResponses(false);
    }
  };
  
  const loadExistingData = async () => {
    try {
      // Load existing form data for editing
      if (existingForm1Data && Object.keys(existingForm1Data).length > 0) {
        setAnswers(existingForm1Data);
        await saveAnswersToStorage(1, existingForm1Data);
      }
      if (existingForm2Data && Object.keys(existingForm2Data).length > 0) {
        await saveAnswersToStorage(2, existingForm2Data);
      }
      if (existingForm3Data && Object.keys(existingForm3Data).length > 0) {
        await saveAnswersToStorage(3, existingForm3Data);
      }
      
      // Determine which form to start with
      if (Object.keys(existingForm1Data).length === 0) {
        setCurrentForm(1);
      } else if (Object.keys(existingForm2Data).length === 0) {
        setCurrentForm(2);
      } else if (Object.keys(existingForm3Data).length === 0) {
        setCurrentForm(3);
      } else {
        // All forms have data, start from form 1 for editing
        setCurrentForm(1);
      }
    } catch (error) {
      console.error('Error loading existing data:', error);
    }
  };

  const saveAnswersToStorage = async (formNumber: number, formAnswers: FormAnswers) => {
    const key = `form${formNumber}_answers`;
    if (Platform.OS === 'web') {
      localStorage.setItem(key, JSON.stringify(formAnswers));
    } else {
      await AsyncStorage.setItem(key, JSON.stringify(formAnswers));
    }
  };

  const checkSavedProgress = async () => {
    try {
      // Check all three forms for saved answers
      let lastIncompleteForm = 1;
      let hasAnyAnswers = false;
      
      for (let formNum = 1; formNum <= 3; formNum++) {
        const storageKey = `form${formNum}_answers`;
        let saved = null;
        
        if (Platform.OS === 'web') {
          saved = localStorage.getItem(storageKey);
        } else {
          saved = await AsyncStorage.getItem(storageKey);
        }
        
        if (saved) {
          const savedAnswers = JSON.parse(saved);
          const answerCount = Object.keys(savedAnswers).length;
          
          if (answerCount > 0) {
            hasAnyAnswers = true;
            lastIncompleteForm = formNum;
            
            // Check if this form is complete
            const formName = formNames[formNum as keyof typeof formNames];
            const response = await fetch(`${API_URL}/v1/items/by-form?form=${formName}`, {
              headers: {
                'x-user-lang': 'tr',
                'x-user-id': 'test-user',
              },
            });
            
            const data = await response.json();
            const requiredItems = data.items?.filter((item: FormItem) => 
              item.type !== 'OpenText' || !item.id.includes('STORY')
            ) || [];
            
            const unansweredRequired = requiredItems.filter((item: FormItem) => 
              !savedAnswers[item.id]
            );
            
            // If this form has unanswered questions, stop here
            if (unansweredRequired.length > 0) {
              break;
            }
          }
        }
      }
      
      // If user has started filling forms, ask if they want to continue
      if (hasAnyAnswers && lastIncompleteForm > 1) {
        Alert.alert(
          'Devam Eden Form Bulundu',
          `Form ${lastIncompleteForm} üzerinde kayıtlı cevaplarınız var. Kaldığınız yerden devam etmek ister misiniz?`,
          [
            {
              text: 'Baştan Başla',
              style: 'destructive',
              onPress: async () => {
                // Clear all saved answers
                for (let i = 1; i <= 3; i++) {
                  const key = `form${i}_answers`;
                  if (Platform.OS === 'web') {
                    localStorage.removeItem(key);
                  } else {
                    await AsyncStorage.removeItem(key);
                  }
                }
                setCurrentForm(1);
              }
            },
            {
              text: 'Devam Et',
              onPress: () => setCurrentForm(lastIncompleteForm)
            }
          ]
        );
      }
    } catch (error) {
      console.error('Error checking saved progress:', error);
    }
  };

  const loadFormItems = async () => {
    setLoading(true);
    try {
      const formName = formNames[currentForm as keyof typeof formNames];
      const response = await fetch(`${API_URL}/v1/items/by-form?form=${formName}`, {
        headers: {
          'x-user-lang': 'tr',
          'x-user-id': 'test-user',
        },
      });
      
      const data = await response.json();
      if (data.items && data.items.length > 0) {
        const sortedItems = data.items.sort((a: FormItem, b: FormItem) => 
          (a.display_order || 0) - (b.display_order || 0)
        );
        setItems(sortedItems);
      }
      setLoading(false);
    } catch (error) {
      console.error('Error loading items:', error);
      Alert.alert('Hata', 'Sorular yüklenirken bir hata oluştu');
      setLoading(false);
    }
  };

  const loadAnswers = async () => {
    console.log('=== LOADING ANSWERS FOR FORM', currentForm, '===');
    try {
      const storageKey = `form${currentForm}_answers`;
      console.log(`=== LOADING ANSWERS FOR ${storageKey} ===`);
      let saved = null;
      
      // IMPORTANT: Form answers should ALWAYS persist between sessions
      // They are only cleared when:
      // 1. User logs out
      // 2. User switches to a different account
      // They should NEVER be cleared after completing an analysis
      
      if (Platform.OS === 'web') {
        saved = localStorage.getItem(storageKey);
        // Also log all form data in localStorage for debugging
        console.log('All form data in localStorage:');
        console.log('form1_answers:', localStorage.getItem('form1_answers') ? 'EXISTS' : 'NOT FOUND');
        console.log('form2_answers:', localStorage.getItem('form2_answers') ? 'EXISTS' : 'NOT FOUND');
        console.log('form3_answers:', localStorage.getItem('form3_answers') ? 'EXISTS' : 'NOT FOUND');
      } else {
        saved = await AsyncStorage.getItem(storageKey);
      }
      
      if (saved) {
        const parsedAnswers = JSON.parse(saved);
        console.log(`Found ${Object.keys(parsedAnswers).length} saved answers for form ${currentForm}`);
        console.log('Saved answers keys:', Object.keys(parsedAnswers));
        console.log('Sample values:', {
          firstKey: Object.keys(parsedAnswers)[0],
          firstValue: parsedAnswers[Object.keys(parsedAnswers)[0]]
        });
        setAnswers(parsedAnswers);
      } else {
        console.log(`NO SAVED ANSWERS found for form ${currentForm}`);
        setAnswers({});
      }
    } catch (error) {
      console.error('Error loading answers:', error);
    }
  };

  // Check if an item should be shown based on conditional logic
  const shouldShowItem = (item: FormItem): boolean => {
    if (!item.conditional_on) return true;
    
    // Special handling for NOT conditions
    if (item.conditional_on.includes('!=')) {
      const [condId, condValue] = item.conditional_on.split('!=');
      const parentAnswer = answers[condId];
      
      if (parentAnswer === undefined || parentAnswer === null || parentAnswer === '') {
        return false; // Hide if no answer yet
      }
      
      const parentItem = items.find(i => i.id === condId);
      if (parentItem && parentItem.type === 'SingleChoice' && parentItem.options_tr) {
        const options = parentItem.options_tr.split('|');
        const answerIndex = typeof parentAnswer === 'string' ? parseInt(parentAnswer) : parentAnswer;
        const selectedOption = options[answerIndex]?.trim();
        
        return selectedOption !== condValue; // Show if NOT equal to condValue
      }
      
      return parentAnswer !== condValue;
    }
    
    // Regular equality check
    const [condId, condValue] = item.conditional_on.split('=');
    const parentAnswer = answers[condId];
    
    // For SingleChoice items, we need to check the selected option text
    const parentItem = items.find(i => i.id === condId);
    if (parentItem && parentItem.type === 'SingleChoice' && parentItem.options_tr) {
      const options = parentItem.options_tr.split('|');
      const answerIndex = typeof parentAnswer === 'string' ? parseInt(parentAnswer) : parentAnswer;
      const selectedOption = options[answerIndex]?.trim();
      return selectedOption === condValue;
    }
    
    return parentAnswer === condValue;
  };

  const saveAnswers = async () => {
    try {
      const storageKey = `form${currentForm}_answers`;
      const answersString = JSON.stringify(answers);
      
      if (Platform.OS === 'web') {
        localStorage.setItem(storageKey, answersString);
      } else {
        await AsyncStorage.setItem(storageKey, answersString);
      }
    } catch (error) {
      console.error('Error saving answers:', error);
    }
  };

  const handleAnswer = async (itemId: string, value: any) => {
    let newAnswers = { ...answers, [itemId]: value };
    
    // Check if any conditional items should be cleared
    // If this answer affects conditional items, clear them if condition is not met
    const dependentItems = items.filter(item => {
      if (!item.conditional_on) return false;
      const condId = item.conditional_on.includes('!=') 
        ? item.conditional_on.split('!=')[0]
        : item.conditional_on.split('=')[0];
      return condId === itemId;
    });
    
    dependentItems.forEach(depItem => {
      // Need to check with the new answer value
      const parentItem = items.find(i => i.id === itemId);
      let shouldShow = true;
      
      if (depItem.conditional_on?.includes('!=')) {
        const [condId, condValue] = depItem.conditional_on.split('!=');
        if (parentItem && parentItem.type === 'SingleChoice' && parentItem.options_tr) {
          const options = parentItem.options_tr.split('|');
          const valueIndex = typeof value === 'string' ? parseInt(value) : value;
          const selectedOption = options[valueIndex]?.trim();
          shouldShow = selectedOption !== condValue;
          
          // Check dependency
        }
      }
      
      // If condition is not met, clear the dependent answer
      if (!shouldShow && newAnswers[depItem.id]) {
        delete newAnswers[depItem.id];
      }
    });
    
    setAnswers(newAnswers);
    
    // Auto-save to localStorage/AsyncStorage
    try {
      const storageKey = `form${currentForm}_answers`;
      const answersString = JSON.stringify(newAnswers);
      
      if (Platform.OS === 'web') {
        localStorage.setItem(storageKey, answersString);
      } else {
        await AsyncStorage.setItem(storageKey, answersString);
      }
    } catch (error) {
      console.error('Error auto-saving answer:', error);
    }
  };

  // Speech-to-Text functions
  const startSpeechRecognition = useCallback((itemId: string) => {
    // Stop any other active recording first
    if (activeRecordingType && activeRecordingType !== `form-${itemId}`) {
      stopAnyActiveRecording?.();
    }
    
    if (!speechRecognitionAvailable) {
      Alert.alert('Uyarı', 'Ses tanıma özelliği bu tarayıcıda desteklenmiyor');
      return;
    }

    // Focus the text input first
    if (textInputRefs.current[itemId]) {
      textInputRefs.current[itemId]?.focus();
    }

    const SpeechRecognition = (window as any).webkitSpeechRecognition || (window as any).SpeechRecognition;
    const recognition = new SpeechRecognition();
    
    // Force Turkish language for speech recognition
    const userLang = 'tr'; // Always use Turkish
    
    // Language mapping for speech recognition
    const speechLangMap: { [key: string]: string } = {
      'tr': 'tr-TR',      // Turkish
      'en': 'en-US',      // English  
      'ar': 'ar-SA',      // Arabic
      'es': 'es-ES',      // Spanish
      'ru': 'ru-RU',      // Russian
      'de': 'de-DE',      // German
      'fr': 'fr-FR',      // French
      'it': 'it-IT',      // Italian
      'pt': 'pt-BR',      // Portuguese
      'nl': 'nl-NL',      // Dutch
      'zh': 'zh-CN',      // Chinese (Simplified)
      'zh-TW': 'zh-TW',   // Chinese (Traditional)
      'ja': 'ja-JP',      // Japanese
      'ko': 'ko-KR',      // Korean
      'hi': 'hi-IN',      // Hindi
    };
    
    recognition.lang = speechLangMap[userLang] || 'tr-TR';
    console.log('Speech recognition language set to:', recognition.lang);
    
    recognition.continuous = true; // Keep listening until user stops
    recognition.interimResults = false; // Only get final results
    recognition.maxAlternatives = 1;

    recognition.onstart = () => {
      setIsRecording(itemId);
      setActiveRecordingType?.(`form-${itemId}`);
      console.log('Speech recognition started for:', itemId);
    };

    recognition.onresult = (event: any) => {
      // Get only the latest result to avoid duplicates
      const lastResultIndex = event.results.length - 1;
      const transcript = event.results[lastResultIndex][0].transcript;
      
      // Get current text from ref to ensure latest value
      const currentText = answersRef.current[itemId] || '';
      
      // Add space if there's existing text
      const newText = currentText ? currentText + ' ' + transcript : transcript;
      handleAnswer(itemId, newText.trim());
      
      // Keep focus on the input
      if (textInputRefs.current[itemId]) {
        textInputRefs.current[itemId]?.focus();
      }
    };

    recognition.onerror = (event: any) => {
      console.error('Speech recognition error:', event.error);
      
      if (event.error === 'no-speech') {
        console.log('No speech detected, continuing...');
      } else if (event.error === 'not-allowed') {
        Alert.alert('Mikrofon İzni', 'Lütfen tarayıcı ayarlarından mikrofon iznini verin.');
        setIsRecording(null);
      } else {
        Alert.alert('Ses Tanıma Hatası', 'Hata: ' + event.error);
        setIsRecording(null);
      }
    };

    recognition.onend = () => {
      console.log('Speech recognition ended for:', itemId);
      // Check if we're still supposed to be recording
      setTimeout(() => {
        if (isRecording === itemId) {
          console.log('Restarting speech recognition for:', itemId);
          try {
            const newRecognition = new (window.webkitSpeechRecognition || window.SpeechRecognition)();
            newRecognition.lang = recognition.lang;
            newRecognition.continuous = true;
            newRecognition.interimResults = false;
            newRecognition.maxAlternatives = 1;
            
            newRecognition.onresult = recognition.onresult;
            newRecognition.onerror = recognition.onerror;
            newRecognition.onend = recognition.onend;
            newRecognition.onstart = recognition.onstart;
            
            recognitionRef.current = newRecognition;
            newRecognition.start();
          } catch (e) {
            console.log('Could not restart:', e);
          }
        }
      }, 100);
    };

    recognitionRef.current = recognition;
    recognition.start();
  }, [answers]);

  const stopSpeechRecognition = () => {
    setIsRecording(null); // Set this first to prevent restart
    setActiveRecordingType?.(null);
    if (recognitionRef.current) {
      try {
        recognitionRef.current.stop();
        recognitionRef.current.onend = null; // Remove onend handler to prevent restart
      } catch (e) {
        console.log('Error stopping recognition:', e);
      }
      recognitionRef.current = null;
    }
  };

  const renderQuestionText = (text: string, isMissingItem: boolean = false, questionNumber?: number) => {
    const textStyle = isMissingItem ? styles.missingItemText : styles.questionText;
    
    // Check if text contains EN ÇOK or EN AZ
    if (text.includes('EN ÇOK')) {
      const parts = text.split('EN ÇOK');
      return (
        <Text style={textStyle}>
          {parts[0]}
          <Text style={styles.highlightGreen}>EN ÇOK</Text>
          {parts[1]}
        </Text>
      );
    } else if (text.includes('EN AZ')) {
      const parts = text.split('EN AZ');
      return (
        <Text style={textStyle}>
          {parts[0]}
          <Text style={styles.highlightRed}>EN AZ</Text>
          {parts[1]}
        </Text>
      );
    }
    
    // Add question number if provided
    if (questionNumber) {
      return (
        <Text style={textStyle}>
          <Text style={styles.questionNumber}>{questionNumber}. </Text>
          {text}
        </Text>
      );
    }
    
    return <Text style={textStyle}>{text}</Text>;
  };

  const renderDISCQuestion = (discNumber: string, options: string[]) => {
    const mostKey = `F3_DISC_${discNumber}_MOST`;
    const leastKey = `F3_DISC_${discNumber}_LEAST`;
    const mostValue = answers[mostKey] || '';
    const leastValue = answers[leastKey] || '';
    
    return (
      <View style={styles.discContainer}>
        <View style={styles.discColumn}>
          <Text style={styles.discHeaderMost}>EN ÇOK</Text>
          <View style={styles.discOptions}>
            {options.map((option, index) => {
              const isSelected = mostValue === String(index);
              return (
                <TouchableOpacity
                  key={`most-${index}`}
                  style={[styles.discButton, isSelected && styles.discButtonSelectedMost]}
                  onPress={() => {
                    // Clear if same option selected in LEAST
                    if (leastValue === String(index)) {
                      handleAnswer(leastKey, '');
                    }
                    handleAnswer(mostKey, String(index));
                  }}
                >
                  <Text style={[styles.discButtonText, isSelected && styles.discButtonTextSelected]}>
                    {option}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        </View>
        
        <View style={styles.discDivider} />
        
        <View style={styles.discColumn}>
          <Text style={styles.discHeaderLeast}>EN AZ</Text>
          <View style={styles.discOptions}>
            {options.map((option, index) => {
              const isSelected = leastValue === String(index);
              return (
                <TouchableOpacity
                  key={`least-${index}`}
                  style={[styles.discButton, isSelected && styles.discButtonSelectedLeast]}
                  onPress={() => {
                    // Clear if same option selected in MOST
                    if (mostValue === String(index)) {
                      handleAnswer(mostKey, '');
                    }
                    handleAnswer(leastKey, String(index));
                  }}
                >
                  <Text style={[styles.discButtonText, isSelected && styles.discButtonTextSelected]}>
                    {option}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        </View>
      </View>
    );
  };

  const renderInput = (item: FormItem) => {
    const value = answers[item.id] || '';

    switch (item.type) {
      case 'Number':
        return (
          <TextInput
            style={styles.textInput}
            value={String(value)}
            onChangeText={(text) => handleAnswer(item.id, text)}
            keyboardType="numeric"
            placeholder="Sayı giriniz"
            placeholderTextColor="#94A3B8"
          />
        );

      case 'OpenText':
        return (
          <View style={styles.openTextContainer}>
            <View style={styles.textInputWrapper}>
              <TextInput
                ref={(ref) => { textInputRefs.current[item.id] = ref; }}
                style={[styles.textInput, styles.multilineInput, speechRecognitionAvailable && styles.textInputWithMic]}
                value={value}
                onChangeText={(text) => handleAnswer(item.id, text)}
                multiline
                numberOfLines={4}
                placeholder="Cevabınızı yazın..."
                placeholderTextColor="#94A3B8"
                {...(Platform.OS === 'web' ? { 'data-text-input': true } : {})}
              />
              {speechRecognitionAvailable && (
                <TouchableOpacity
                  style={[styles.micButtonInline, isRecording === item.id && styles.micButtonInlineActive]}
                  {...(Platform.OS === 'web' ? { 'data-mic-button': true } : {})}
                  onPress={() => {
                    if (isRecording === item.id) {
                      stopSpeechRecognition();
                    } else {
                      startSpeechRecognition(item.id);
                    }
                  }}
                >
                  {isRecording === item.id ? (
                    <Text style={styles.micIcon}>🔴</Text>
                  ) : (
                    <Image 
                      source={require('../assets/images/mic.png')} 
                      style={styles.micImageIcon}
                      resizeMode="contain"
                    />
                  )}
                </TouchableOpacity>
              )}
            </View>
          </View>
        );

      case 'SingleChoice':
        const options = item.options_tr?.split('|') || [];
        return (
          <View style={styles.choiceContainer}>
            {options.map((option, index) => {
              const isSelected = value === String(index);
              return (
                <TouchableOpacity
                  key={index}
                  style={[styles.choiceButton, isSelected && styles.choiceButtonSelected]}
                  onPress={() => handleAnswer(item.id, String(index))}
                >
                  <Text style={[styles.choiceText, isSelected && styles.choiceTextSelected]}>
                    {option}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        );

      case 'MultiSelect3':
        const multiOptions = item.options_tr?.split('|') || [];
        const selectedValues = value ? (Array.isArray(value) ? value : [value]) : [];
        
        return (
          <View style={styles.choiceContainer}>
            {multiOptions.map((option, index) => {
              const isSelected = selectedValues.includes(String(index));
              
              return (
                <TouchableOpacity
                  key={index}
                  style={[styles.choiceButton, isSelected && styles.choiceButtonSelected]}
                  onPress={() => {
                    let newValues = [...selectedValues];
                    if (isSelected) {
                      newValues = newValues.filter(v => v !== String(index));
                    } else {
                      if (newValues.length < 3) {
                        newValues.push(String(index));
                      } else {
                        Alert.alert('Uyarı', 'En fazla 3 seçim yapabilirsiniz');
                        return;
                      }
                    }
                    handleAnswer(item.id, newValues);
                  }}
                >
                  <Text style={[styles.choiceText, isSelected && styles.choiceTextSelected]}>
                    {option}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        );

      case 'MultiSelect4':
        const multi4Options = item.options_tr?.split('|') || [];
        const selected4Values = value ? (Array.isArray(value) ? value : [value]) : [];
        
        return (
          <View style={styles.choiceContainer}>
            {multi4Options.map((option, index) => {
              const isSelected = selected4Values.includes(String(index));
              
              return (
                <TouchableOpacity
                  key={index}
                  style={[styles.choiceButton, isSelected && styles.choiceButtonSelected]}
                  onPress={() => {
                    let newValues = [...selected4Values];
                    if (isSelected) {
                      newValues = newValues.filter(v => v !== String(index));
                    } else {
                      if (newValues.length < 4) {
                        newValues.push(String(index));
                      } else {
                        Alert.alert('Uyarı', 'En fazla 4 seçim yapabilirsiniz');
                        return;
                      }
                    }
                    handleAnswer(item.id, newValues);
                  }}
                >
                  <Text style={[styles.choiceText, isSelected && styles.choiceTextSelected]}>
                    {option}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        );

      case 'Likert5':
        return (
          <View style={styles.likertContainer}>
            <Text style={styles.likertLabel}>1: Hiç Katılmıyorum - 5: Tamamen Katılıyorum</Text>
            <View style={styles.likertOptions}>
              {[1, 2, 3, 4, 5].map((num) => {
                const isSelected = value === num;
                return (
                  <TouchableOpacity
                    key={num}
                    style={[styles.likertOption, isSelected && styles.likertOptionSelected]}
                    onPress={() => handleAnswer(item.id, num)}
                  >
                    <Text style={[styles.likertText, isSelected && styles.likertTextSelected]}>
                      {num}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          </View>
        );

      case 'MultipleChoice':
        if (!item.options_tr) {
          return (
            <View style={styles.errorContainer}>
              <Text style={styles.errorText}>Seçenekler yükleniyor...</Text>
            </View>
          );
        }
        const multiChoiceOptions = item.options_tr.split('|').map(opt => opt.trim());
        const selectedOptions = Array.isArray(value) ? value : [];
        const maxSelections = (item.id === 'F3_SABOTAGE_PATTERNS' || item.id === 'F3_COPING_MECHANISMS') ? 4 : 999;
        const isLastOptionExclusive = item.id === 'F3_COPING_MECHANISMS' || item.id === 'F3_SABOTAGE_PATTERNS'; // For "none of the above" logic
        
        return (
          <View style={styles.multipleChoiceContainer}>
            {multiChoiceOptions.map((option, index) => {
              const isSelected = selectedOptions.includes(index);
              const isLastOption = index === multiChoiceOptions.length - 1;
              
              return (
                <TouchableOpacity
                  key={index}
                  style={[styles.multipleChoiceOption, isSelected && styles.multipleChoiceOptionSelected]}
                  onPress={() => {
                    let newSelections = [...selectedOptions];
                    
                    if (isLastOptionExclusive && isLastOption) {
                      // If selecting "none of the above", clear all others
                      newSelections = isSelected ? [] : [index];
                    } else if (isLastOptionExclusive && selectedOptions.includes(multiChoiceOptions.length - 1)) {
                      // If "none of the above" is selected, replace it with this option
                      newSelections = [index];
                    } else if (isSelected) {
                      // Deselect if already selected
                      newSelections = newSelections.filter(i => i !== index);
                    } else if (newSelections.length < maxSelections) {
                      // Add if under max limit
                      newSelections.push(index);
                    } else {
                      // Max reached, show alert
                      Alert.alert('Limit', `En fazla ${maxSelections} seçim yapabilirsiniz.`);
                    }
                    
                    handleAnswer(item.id, newSelections);
                  }}
                >
                  <Text style={[styles.multipleChoiceText, isSelected && styles.multipleChoiceTextSelected]}>
                    {option}
                  </Text>
                </TouchableOpacity>
              );
            })}
            {(item.id === 'F3_SABOTAGE_PATTERNS' || item.id === 'F3_COPING_MECHANISMS') && (
              <Text style={styles.selectionHint}>
                (En fazla 4 seçim yapabilirsiniz. Son seçenek diğerlerini iptal eder.)
              </Text>
            )}
          </View>
        );

      case 'Scale5':
        return (
          <View style={styles.likertContainer}>
            <View style={styles.likertOptions}>
              {[1, 2, 3, 4, 5].map((num) => {
                const isSelected = value === num;
                return (
                  <TouchableOpacity
                    key={num}
                    style={[styles.likertOption, isSelected && styles.likertOptionSelected]}
                    onPress={() => handleAnswer(item.id, num)}
                  >
                    <Text style={[styles.likertText, isSelected && styles.likertTextSelected]}>
                      {num}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          </View>
        );

      case 'Scale10':
        // Check if this item has custom options
        const hasCustomOptions = item.options_tr && item.options_tr.includes(' - ');
        
        if (hasCustomOptions) {
          // Render as vertical list with descriptions
          const options = item.options_tr.split('|');
          return (
            <View style={styles.verticalOptionsContainer}>
              {options.map((option: string, index: number) => {
                let optionValue: number;
                let optionText: string;
                
                // Parse the option (could be "1 - Description" or just "1")
                if (option.includes(' - ')) {
                  const parts = option.split(' - ');
                  optionValue = parseInt(parts[0]);
                  optionText = option;
                } else {
                  // For simple numbers without description
                  optionValue = parseInt(option);
                  optionText = option;
                }
                
                const isSelected = value === optionValue;
                
                return (
                  <TouchableOpacity
                    key={index}
                    style={[styles.verticalOption, isSelected && styles.verticalOptionSelected]}
                    onPress={() => handleAnswer(item.id, optionValue)}
                  >
                    <Text style={[styles.verticalOptionText, isSelected && styles.verticalOptionTextSelected]}>
                      {optionText}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          );
        } else {
          // Original grid layout for questions without custom options
          return (
            <View style={styles.scaleContainer}>
              <View style={styles.scaleGrid}>
                {/* First row: 1-5 */}
                <View style={styles.scaleRow}>
                  {[1, 2, 3, 4, 5].map((num) => {
                    const isSelected = value === num;
                    return (
                      <TouchableOpacity
                        key={num}
                        style={[styles.scaleOption, isSelected && styles.scaleOptionSelected]}
                        onPress={() => handleAnswer(item.id, num)}
                      >
                        <Text style={[styles.scaleText, isSelected && styles.scaleTextSelected]}>
                          {num}
                        </Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>
                {/* Second row: 6-10 */}
                <View style={styles.scaleRow}>
                  {[6, 7, 8, 9, 10].map((num) => {
                    const isSelected = value === num;
                    return (
                      <TouchableOpacity
                        key={num}
                        style={[styles.scaleOption, isSelected && styles.scaleOptionSelected]}
                        onPress={() => handleAnswer(item.id, num)}
                      >
                        <Text style={[styles.scaleText, isSelected && styles.scaleTextSelected]}>
                          {num}
                        </Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>
              </View>
            </View>
          );
        }

      case 'Likert6':
        return (
          <View style={styles.likertContainer}>
            <Text style={styles.likertLabel}>1: Kesinlikle Katılmıyorum - 5: Kesinlikle Katılıyorum</Text>
            <View style={styles.likertOptions}>
              {[1, 2, 3, 4, 5, '?'].map((num) => {
                const isSelected = value === num;
                return (
                  <TouchableOpacity
                    key={num}
                    style={[styles.likertOption, isSelected && styles.likertOptionSelected]}
                    onPress={() => handleAnswer(item.id, num)}
                  >
                    <Text style={[styles.likertText, isSelected && styles.likertTextSelected]}>
                      {num}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          </View>
        );

      case 'Ranking':
        const rankingValues = [
          { key: 'achievement', label: 'Başarı', desc: 'Yetkinliğini göstermek ve sosyal onay almak.' },
          { key: 'power', label: 'Güç', desc: 'Sosyal statüye, insanlara ve kaynaklara hükmetmek.' },
          { key: 'stimulation', label: 'Heyecan', desc: 'Hayatta yenilik, macera ve zorluklar aramak.' },
          { key: 'self_direction', label: 'Özyönelim', desc: 'Düşünce ve eylemde bağımsız olmak, keşfetmek, yaratmak.' },
          { key: 'benevolence', label: 'İyilikseverlik', desc: 'Yakın çevrendeki insanların iyiliğini korumak ve artırmak.' },
          { key: 'universalism', label: 'Evrenselcilik', desc: 'Tüm insanlar ve doğa için anlayış, hoşgörü ve koruma.' },
          { key: 'security', label: 'Güvenlik', desc: 'Toplumun, ilişkilerin ve kendinin güvenliğini, uyumunu ve istikrarını sağlamak.' },
          { key: 'tradition', label: 'Gelenek', desc: 'Kültürel veya dini geleneklere, fikirlere saygı duymak ve bağlı kalmak.' },
          { key: 'conformity', label: 'Uyum', desc: 'Başkalarını rahatsız edebilecek veya onlara zarar verebilecek eylemlerden ve dürtülerden kaçınmak.' },
          { key: 'hedonism', label: 'Hazcılık', desc: 'Kişisel zevk ve duyusal tatmin arayışı.' }
        ];
        
        // Parse current ranking (stored as array of keys)
        const currentRanking = Array.isArray(value) ? value : [];
        
        return (
          <DraggableRanking
            values={rankingValues}
            currentRanking={currentRanking}
            onRankingChange={(newRanking) => handleAnswer(item.id, newRanking)}
          />
        );

      default:
        return null;
    }
  };

  const handleNext = async () => {
    // Check required fields (OpenText story questions are optional)
    const requiredItems = items.filter(item => {
      // Skip conditional items that shouldn't be shown
      if (!shouldShowItem(item)) return false;
      // Skip optional open text story items
      return !(item.type === 'OpenText' && item.id.includes('STORY'));
    });
    
    const unansweredRequired = requiredItems.filter(item => {
      const answer = answers[item.id];
      // Check for empty answers
      if (answer === undefined || answer === null || answer === '') return true;
      // For multi-select, check if array is empty
      if (Array.isArray(answer) && answer.length === 0) return true;
      // For ranking, check if not fully ranked
      if (item.type === 'Ranking' && (!Array.isArray(answer) || answer.length !== 10)) return true;
      return false;
    });
    
    if (unansweredRequired.length > 0) {
      // Show missing items step instead of alert
      console.log('Missing items found:', unansweredRequired.length);
      setMissingItems(unansweredRequired);
      setShowMissingStep(true);
      return;
    }
    
    setSaving(true);
    await saveAnswers();
    
    if (currentForm < 3) {
      // Move to next form - useEffect will handle loading new answers
      setCurrentForm(currentForm + 1);
    } else {
      // All forms completed, prepare for analysis
      await prepareAnalysisData();
    }
    setSaving(false);
  };

  const prepareAnalysisData = async () => {
    console.log('Preparing analysis data...');
    
    // Save current form's answers first (Form 3)
    await saveAnswers();
    
    // Gather all form answers
    let form1Answers = {};
    let form2Answers = {};
    let form3Answers = {};
    
    try {
      if (Platform.OS === 'web') {
        const f1 = localStorage.getItem('form1_answers');
        const f2 = localStorage.getItem('form2_answers');
        const f3 = localStorage.getItem('form3_answers');
        
        form1Answers = f1 ? JSON.parse(f1) : {};
        form2Answers = f2 ? JSON.parse(f2) : {};
        form3Answers = f3 ? JSON.parse(f3) : {};
      } else {
        const f1 = await AsyncStorage.getItem('form1_answers');
        const f2 = await AsyncStorage.getItem('form2_answers');
        const f3 = await AsyncStorage.getItem('form3_answers');
        
        form1Answers = f1 ? JSON.parse(f1) : {};
        form2Answers = f2 ? JSON.parse(f2) : {};
        form3Answers = f3 ? JSON.parse(f3) : {};
      }
      
      console.log('=== FORM DATA LOADED FOR ANALYSIS ===');
      console.log('Form1 answers:', Object.keys(form1Answers).length, 'items');
      console.log('Form2 answers:', Object.keys(form2Answers).length, 'items');
      console.log('Form3 answers:', Object.keys(form3Answers).length, 'items');
      
      if (form1Answers && Object.keys(form1Answers).length > 0) {
        console.log('Form1 sample data:', Object.keys(form1Answers).slice(0, 5));
      }
      if (form2Answers && Object.keys(form2Answers).length > 0) {
        console.log('Form2 sample data:', Object.keys(form2Answers).slice(0, 5));
      }
      if (form3Answers && Object.keys(form3Answers).length > 0) {
        console.log('Form3 sample data:', Object.keys(form3Answers).slice(0, 5));
      }
    } catch (error) {
      console.error('Error loading form data:', error);
    }
    
    // For web, directly navigate or use confirm dialog
    if (Platform.OS === 'web') {
      // Directly navigate to payment check
      console.log('=== NAVIGATING TO PAYMENTCHECK ===');
      console.log('User email from route params:', route?.params?.userEmail);
      console.log('Passing form1Data:', Object.keys(form1Answers).length, 'items');
      console.log('Passing form2Data:', Object.keys(form2Answers).length, 'items');
      console.log('Passing form3Data:', Object.keys(form3Answers).length, 'items');
      
      console.log('Navigation object:', navigation);
      console.log('Navigation.navigate type:', typeof navigation?.navigate);
      
      if (navigation && navigation.navigate) {
        console.log('Calling navigation.navigate with PaymentCheck');
        navigation.navigate('PaymentCheck', {
          form1Data: form1Answers,
          form2Data: form2Answers,
          form3Data: form3Answers,
          editMode: editMode,
          analysisId: analysisId,
          userEmail: userEmail
        });
        console.log('navigation.navigate called successfully');
      } else {
        console.error('Navigation or navigate function not available!');
        console.error('Navigation object:', navigation);
      }
    } else {
      Alert.alert(
        '✅ Tüm Formlar Tamamlandı',
        'Kişilik analiziniz hazır. Sonuçları görmek ister misiniz?',
        [
          { 
            text: 'Daha Sonra',
            style: 'cancel'
          },
          { 
            text: 'Analizi Gör', 
            onPress: () => navigation.navigate('PaymentCheck', {
              form1Data: form1Answers,
              form2Data: form2Answers,
              form3Data: form3Answers,
              editMode: editMode,
              analysisId: analysisId,
              userEmail: userEmail
            })
          }
        ]
      );
    }
  };

  const handleBack = async () => {
    // Save current form answers before going back
    setSaving(true);
    await saveAnswers();
    setSaving(false);
    
    if (currentForm > 1) {
      // Don't clear answers immediately - let useEffect handle loading
      setCurrentForm(currentForm - 1);
    } else {
      navigation.goBack();
    }
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        {/* Header */}
        <View style={styles.headerContainer}>
          <View style={styles.headerContent}>
            <View style={styles.headerLeft}>
              <TouchableOpacity
                style={styles.headerBackButton}
                onPress={() => navigation.goBack()}
              >
                <Text style={styles.headerBackText}>←</Text>
              </TouchableOpacity>
            </View>
            
            <View style={styles.headerTitleContainer}>
              <Text style={styles.headerTitle}>Kişilik Analizi</Text>
              <Text style={styles.headerSubtitle}>Form yükleniyor...</Text>
            </View>
            
            <View style={styles.headerRight}>
              <View style={styles.progressInfo}>
                <View style={styles.progressBadge}>
                  <Text style={styles.progressText}>
                    {currentForm}/3
                  </Text>
                </View>
              </View>
            </View>
          </View>
        </View>
        
        <View style={[styles.centerContent, styles.webContainer]}>
          <ActivityIndicator size="large" color="rgb(96, 187, 202)" />
          <Text style={styles.loadingText}>Yükleniyor...</Text>
        </View>
      </SafeAreaView>
    );
  }

  // Show missing items step if needed
  if (showMissingStep && missingItems.length > 0) {
    return (
      <SafeAreaView style={styles.container}>
        {/* Header */}
        <View style={styles.headerContainer}>
          <View style={styles.headerContent}>
            <View style={styles.headerLeft}>
              <TouchableOpacity
                style={styles.headerBackButton}
                onPress={() => setShowMissingStep(false)}
              >
                <Text style={styles.headerBackText}>←</Text>
              </TouchableOpacity>
            </View>
            
            <View style={styles.headerTitleContainer}>
              <Text style={styles.headerTitle}>Eksik Sorular</Text>
              <Text style={styles.headerSubtitle}>
                {missingItems.length} zorunlu soru cevaplanmadı
              </Text>
            </View>
            
            <View style={styles.headerRight}>
              <View style={styles.progressInfo}>
                <View style={[styles.progressBadge, { backgroundColor: '#EF4444' }]}>
                  <Text style={styles.progressText}>
                    {missingItems.length} Eksik
                  </Text>
                </View>
              </View>
            </View>
          </View>
        </View>
        
        <ScrollView style={styles.scrollView}>
          <View style={[styles.formContent, styles.webContainer]}>
            <View style={styles.missingHeader}>
              <Text style={styles.missingTitle}>
                ⚠️ Lütfen aşağıdaki zorunlu soruları cevaplayın
              </Text>
              <Text style={styles.missingSubtitle}>
                {currentForm === 3 ? 'Analizi tamamlamak' : `Form ${currentForm + 1}'e geçmek`} için tüm zorunlu sorular cevaplanmalıdır.
              </Text>
            </View>
            
            {missingItems.filter(item => shouldShowItem(item)).map((item, index) => (
              <View key={item.id} style={styles.missingItemContainer}>
                <View style={styles.missingItemHeader}>
                  <Text style={styles.missingItemNumber}>
                    {index + 1}. Eksik Soru
                  </Text>
                  {item.section && (
                    <Text style={styles.missingItemSection}>
                      {item.section}
                    </Text>
                  )}
                </View>
                <View style={styles.missingItemTextContainer}>
                  {renderQuestionText(item.text_tr, true)}
                </View>
                {renderInput(item)}
              </View>
            ))}
            
            <View style={styles.missingFooter}>
              <TouchableOpacity
                style={styles.completeMissingButton}
                onPress={() => {
                  // Check if all missing items are now answered
                  const stillMissing = missingItems.filter(item => {
                    // Skip conditional items that shouldn't be shown
                    if (!shouldShowItem(item)) return false;
                    
                    const answer = answers[item.id];
                    if (answer === undefined || answer === null || answer === '') return true;
                    if (Array.isArray(answer) && answer.length === 0) return true;
                    if (item.type === 'Ranking' && (!Array.isArray(answer) || answer.length !== 10)) return true;
                    return false;
                  });
                  
                  if (stillMissing.length > 0) {
                    Alert.alert('Uyarı', `Hala ${stillMissing.length} eksik soru var.`);
                  } else {
                    setShowMissingStep(false);
                    handleNext();
                  }
                }}
              >
                <Text style={styles.completeMissingButtonText}>
                  Tüm Soruları Cevapladım
                </Text>
              </TouchableOpacity>
              
              <TouchableOpacity
                style={styles.backToFormButton}
                onPress={() => setShowMissingStep(false)}
              >
                <Text style={styles.backToFormButtonText}>
                  Forma Geri Dön
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </ScrollView>
      </SafeAreaView>
    );
  }

  // Group items by section
  const sections = [...new Set(items.map(item => item.section))];

  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.headerContainer}>
        <View style={styles.headerContent}>
          <View style={styles.headerLeft}>
            <TouchableOpacity
              style={styles.headerBackButton}
              onPress={handleBack}
            >
              <Text style={styles.headerBackText}>←</Text>
            </TouchableOpacity>
          </View>
          
          <View style={styles.headerTitleContainer}>
            <View style={styles.titleWithIcon}>
              <Image 
                source={require('../assets/cogni-coach-icon.png')} 
                style={styles.headerIcon}
                resizeMode="contain"
              />
              <Text style={styles.headerTitle}>
                {formTitles[currentForm as keyof typeof formTitles]}
              </Text>
            </View>
            <Text style={styles.headerSubtitle}>
              Kendi Analizim
            </Text>
          </View>
          
          <View style={styles.headerRight}>
            <View style={styles.progressInfo}>
              <View style={styles.progressBadge}>
                <Text style={styles.progressText}>
                  {currentForm}/3
                </Text>
              </View>
              {Object.keys(answers).length > 0 && (
                <Text style={styles.savedIndicator}>
                  💾 {Object.keys(answers).length} cevap
                </Text>
              )}
            </View>
          </View>
        </View>
      </View>

      <KeyboardAvoidingView 
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={[styles.container, styles.webContainer]}
      >
        <ScrollView contentContainerStyle={styles.scrollContent}>
          {sections.map(section => {
            // Calculate starting question number for this section
            let sectionStartNumber = 1;
            const sectionsBeforeThis = sections.slice(0, sections.indexOf(section));
            
            sectionsBeforeThis.forEach(prevSection => {
              const sectionItems = items.filter(item => item.section === prevSection);
              // Count DISC pairs as single questions in Form3
              if (currentForm === 3) {
                const discPairs = sectionItems.filter(item => item.id.includes('F3_DISC_') && item.id.includes('_MOST')).length;
                const regularItems = sectionItems.filter(item => !item.id.includes('F3_DISC_')).length;
                sectionStartNumber += discPairs + regularItems;
              } else {
                sectionStartNumber += sectionItems.length;
              }
            });
            
            return (
            <View key={section}>
              <View style={styles.sectionDivider}>
                <Text style={styles.sectionDividerText}>{section}</Text>
              </View>
              {items
                .filter(item => item.section === section && shouldShowItem(item))
                .map((item, index) => {
                  // Calculate question number within the form
                  let questionNumber = sectionStartNumber;
                  
                  // Add count of items before this one in the same section
                  const itemsBeforeInSection = items.filter(i => i.section === section).slice(0, index);
                  
                  if (currentForm === 3) {
                    // For Form3, count DISC pairs as single questions
                    const discPairsBefore = itemsBeforeInSection.filter(i => i.id.includes('F3_DISC_') && i.id.includes('_MOST')).length;
                    const regularItemsBefore = itemsBeforeInSection.filter(i => !i.id.includes('F3_DISC_')).length;
                    questionNumber += discPairsBefore + regularItemsBefore;
                  } else {
                    questionNumber += index;
                  }
                  
                  // Check if this is a DISC question pair
                  if (item.id.includes('F3_DISC_') && item.id.includes('_MOST')) {
                    const discNumber = item.id.match(/F3_DISC_(\d+)_MOST/)?.[1];
                    if (discNumber) {
                      const options = item.options_tr?.split('|') || [];
                      return (
                        <View key={item.id} style={styles.itemContainer}>
                          {renderQuestionText('Size en çok ve en az uyan kelimeleri seçin', false, questionNumber)}
                          {renderDISCQuestion(discNumber, options)}
                        </View>
                      );
                    }
                  }
                  
                  // Skip LEAST questions as they're handled with MOST
                  if (item.id.includes('F3_DISC_') && item.id.includes('_LEAST')) {
                    return null;
                  }
                  
                  return (
                  <View key={item.id} style={styles.itemContainer}>
                    {renderQuestionText(item.text_tr, false, questionNumber)}
                    {renderInput(item)}
                  </View>
                );
                })}
            </View>
            );
          })}

        </ScrollView>
      </KeyboardAvoidingView>
      
      {/* Fixed Bottom Navigation */}
      <View style={styles.bottomNavContainer}>
        <View style={styles.bottomNavContent}>
          <TouchableOpacity
            style={[styles.navButton, styles.backButton]}
            onPress={handleBack}
          >
            <Text style={styles.navButtonText}>
              {currentForm === 1 ? 'İptal' : 'Geri'}
            </Text>
          </TouchableOpacity>
          
          <TouchableOpacity
            style={[styles.navButton, styles.nextButton]}
            onPress={handleNext}
            disabled={saving}
          >
            <Text style={[styles.navButtonText, styles.nextButtonText]}>
              {saving ? 'Kaydediliyor...' : currentForm === 3 ? 'Tamamla' : 'İleri'}
            </Text>
          </TouchableOpacity>
        </View>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8F9FA',
  },
  webContainer: {
    ...Platform.select({
      web: {
        maxWidth: 999,
        width: '100%',
        marginHorizontal: 'auto',
        alignSelf: 'center',
      },
      default: {}
    })
  },
  headerContainer: {
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
    ...Platform.select({
      web: {
        position: 'sticky',
        top: 0,
        zIndex: 100,
      },
      default: {}
    })
  },
  headerContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 8,
    ...Platform.select({
      web: {
        maxWidth: 990,
        width: '100%',
        marginHorizontal: 'auto',
      },
      default: {}
    })
  },
  headerLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  headerBackButton: {
    padding: 8,
    marginRight: 12,
  },
  headerBackText: {
    fontSize: 20,
    color: 'rgb(45, 55, 72)',
  },
  headerTitleContainer: {
    flex: 2,
    alignItems: 'center',
  },
  titleWithIcon: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  headerIcon: {
    width: 24,
    height: 24,
    marginRight: 8,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: 'rgb(45, 55, 72)',
  },
  headerSubtitle: {
    fontSize: 12,
    color: '#64748B',
    marginTop: 2,
  },
  headerRight: {
    flex: 1,
    alignItems: 'flex-end',
  },
  progressInfo: {
    alignItems: 'flex-end',
    gap: 4,
  },
  progressBadge: {
    backgroundColor: 'rgb(45, 55, 72)',
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 3,
  },
  progressText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '600',
  },
  savedIndicator: {
    fontSize: 11,
    color: '#64748B',
  },
  scrollContent: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    ...Platform.select({
      web: {
        maxWidth: 990,
        width: '100%',
        marginHorizontal: 'auto',
      },
      default: {}
    })
  },
  centerContent: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    fontSize: 18,
    color: '#64748B',
    marginTop: 16,
  },
  sectionDivider: {
    backgroundColor: 'rgb(45, 55, 72)',
    paddingVertical: 6,
    paddingHorizontal: 12,
    marginBottom: 8,
    marginTop: 4,
    borderRadius: 3,
  },
  sectionDividerText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
  },
  itemContainer: {
    marginBottom: 47,
    backgroundColor: '#FFFFFF',
    padding: 12,
    borderRadius: 3,
    ...Platform.select({
      web: {
        boxShadow: '0 1px 2px rgba(0, 0, 0, 0.05)',
      },
      default: {
        shadowColor: '#000',
        shadowOffset: {
          width: 0,
          height: 1,
        },
        shadowOpacity: 0.05,
        shadowRadius: 2,
        elevation: 1,
      },
    }),
  },
  questionText: {
    fontSize: 16,
    color: 'rgb(0, 0, 0)',
    marginBottom: 12,
    lineHeight: 24,
    fontWeight: '500',
  },
  highlightGreen: {
    color: '#10B981',
    fontWeight: '700',
    fontSize: 17,
  },
  highlightRed: {
    color: '#EF4444',
    fontWeight: '700',
    fontSize: 17,
  },
  textInput: {
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    padding: 12,
    fontSize: 14,
    backgroundColor: 'rgb(244, 244, 244)',
    color: 'rgb(0, 0, 0)',
  },
  multilineInput: {
    minHeight: 100,
    textAlignVertical: 'top',
  },
  openTextContainer: {
    width: '100%',
  },
  textInputWrapper: {
    position: 'relative',
    width: '100%',
  },
  textInputWithMic: {
    paddingRight: 50,
  },
  micButtonInline: {
    position: 'absolute',
    right: 8,
    bottom: 8,
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
  },
  micButtonInlineActive: {
    // No background for active state
  },
  micIcon: {
    fontSize: 18,
  },
  micImageIcon: {
    width: 20,
    height: 20,
  },
  micButton: {
    backgroundColor: '#E5E7EB',
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderRadius: 3,
    alignItems: 'center',
  },
  micButtonActive: {
    backgroundColor: 'rgb(239, 68, 68)',
  },
  micButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: 'rgb(45, 55, 72)',
  },
  choiceContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  choiceButton: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    backgroundColor: '#FFFFFF',
    flexShrink: 1,
    minWidth: 0,
  },
  choiceButtonSelected: {
    backgroundColor: 'rgb(96, 187, 202)',
    borderColor: 'rgb(96, 187, 202)',
  },
  choiceText: {
    fontSize: 14,
    color: 'rgb(0, 0, 0)',
    lineHeight: 20,
    textAlign: 'center',
  },
  choiceTextSelected: {
    color: '#FFFFFF',
  },
  likertContainer: {
    gap: 12,
  },
  likertLabel: {
    fontSize: 12,
    color: '#64748B',
    textAlign: 'center',
  },
  likertOptions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 8,
  },
  likertOption: {
    flex: 1,
    paddingVertical: 10,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
  },
  likertOptionSelected: {
    backgroundColor: 'rgb(96, 187, 202)',
    borderColor: 'rgb(96, 187, 202)',
  },
  likertText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'rgb(0, 0, 0)',
  },
  likertTextSelected: {
    color: '#FFFFFF',
  },
  scaleContainer: {
    gap: 12,
  },
  scaleGrid: {
    gap: 8,
  },
  scaleRow: {
    flexDirection: 'row',
    gap: 8,
    justifyContent: 'space-between',
  },
  scaleOptions: {
    flexDirection: 'row',
    gap: 8,
    paddingVertical: 4,
  },
  scaleOption: {
    flex: 1,
    minWidth: 44,
    height: 44,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FFFFFF',
  },
  scaleOptionSelected: {
    backgroundColor: 'rgb(96, 187, 202)',
    borderColor: 'rgb(96, 187, 202)',
  },
  scaleText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'rgb(0, 0, 0)',
  },
  scaleTextSelected: {
    color: '#FFFFFF',
  },
  verticalOptionsContainer: {
    gap: 8,
  },
  verticalOption: {
    padding: 14,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    marginBottom: 8,
  },
  verticalOptionSelected: {
    backgroundColor: 'rgb(96, 187, 202)',
    borderColor: 'rgb(96, 187, 202)',
  },
  verticalOptionText: {
    fontSize: 14,
    color: 'rgb(0, 0, 0)',
    lineHeight: 20,
  },
  verticalOptionTextSelected: {
    color: '#FFFFFF',
    fontWeight: '600',
  },
  rankingContainer: {
    gap: 16,
  },
  rankingColumns: {
    ...Platform.select({
      web: {
        flexDirection: 'row',
      },
      default: {
        flexDirection: 'column',
      }
    }),
    gap: 16,
  },
  rankingLeftColumn: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    padding: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  rankingRightColumn: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    padding: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  rankingColumnTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: 'rgb(45, 55, 72)',
    marginBottom: 12,
    textAlign: 'center',
  },
  rankingScrollArea: {
    // Removed maxHeight to allow full content display
  },
  rankingValuesContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  rankingSlotsContainer: {
    // Container for ranking slots
  },
  rankingEmptyMessage: {
    color: '#64748B',
    fontSize: 14,
    fontStyle: 'italic',
    textAlign: 'center',
    paddingVertical: 20,
  },
  rankingValueButton: {
    backgroundColor: 'rgb(96, 187, 202)',
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 3,
    minWidth: 100,
    cursor: Platform.OS === 'web' ? 'grab' : 'default',
  },
  draggableItem: {
    ...Platform.select({
      web: {
        cursor: 'grab',
        userSelect: 'none',
      },
      default: {}
    })
  },
  rankingValueLabel: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '500',
    textAlign: 'center',
  },
  rankingSlot: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
    minHeight: 40,
  },
  rankingSlotNumber: {
    width: 30,
    fontSize: 14,
    fontWeight: '600',
    color: '#64748B',
  },
  rankingSlotContent: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: 'rgb(244, 244, 244)',
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 3,
    borderWidth: 1,
    borderColor: 'rgb(96, 187, 202)',
    ...Platform.select({
      web: {
        cursor: 'move',
      },
      default: {}
    })
  },
  rankingSlotLabel: {
    flex: 1,
    fontSize: 14,
    color: 'rgb(0, 0, 0)',
    fontWeight: '500',
  },
  rankingSlotActions: {
    flexDirection: 'row',
    gap: 4,
  },
  rankingMoveButton: {
    width: 28,
    height: 28,
    backgroundColor: '#E5E7EB',
    borderRadius: 3,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rankingMoveText: {
    fontSize: 16,
    fontWeight: 'bold',
    color: 'rgb(45, 55, 72)',
  },
  rankingRemoveButton: {
    width: 28,
    height: 28,
    backgroundColor: 'rgb(239, 68, 68)',
    borderRadius: 3,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rankingRemoveText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  rankingEmptySlot: {
    flex: 1,
    height: 40,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderStyle: 'dashed',
    borderRadius: 3,
    backgroundColor: '#F8F9FA',
  },
  rankingDescriptions: {
    backgroundColor: '#F8F9FA',
    padding: 16,
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  rankingDescTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: 'rgb(45, 55, 72)',
    marginBottom: 12,
  },
  rankingDescItem: {
    fontSize: 12,
    color: '#64748B',
    marginBottom: 6,
    lineHeight: 18,
  },
  rankingDescBold: {
    fontWeight: '600',
    color: 'rgb(45, 55, 72)',
  },
  multipleChoiceContainer: {
    gap: 12,
  },
  multipleChoiceOption: {
    padding: 12,
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  multipleChoiceOptionSelected: {
    backgroundColor: 'rgb(96, 187, 202)',
    borderColor: 'rgb(96, 187, 202)',
  },
  multipleChoiceText: {
    fontSize: 14,
    color: 'rgb(0, 0, 0)',
    lineHeight: 20,
  },
  multipleChoiceTextSelected: {
    color: '#FFFFFF',
  },
  selectionHint: {
    fontSize: 12,
    color: '#718096',
    fontStyle: 'italic',
    marginTop: 8,
    fontWeight: '500',
  },
  errorContainer: {
    padding: 12,
    backgroundColor: '#FEF2F2',
    borderRadius: 3,
  },
  errorText: {
    color: '#DC2626',
    fontSize: 14,
  },
  bottomNavContainer: {
    backgroundColor: '#FFFFFF',
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
    ...Platform.select({
      web: {
        position: 'sticky',
        bottom: 0,
        zIndex: 100,
      },
      default: {}
    })
  },
  bottomNavContent: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    padding: 20,
    gap: 16,
    ...Platform.select({
      web: {
        maxWidth: 990,
        width: '100%',
        marginHorizontal: 'auto',
      },
      default: {}
    })
  },
  navigationButtons: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 8,
    marginBottom: 0,
    gap: 8,
  },
  navButton: {
    flex: 1,
    paddingVertical: 8,
    borderRadius: 3,
    alignItems: 'center',
  },
  backButton: {
    backgroundColor: '#E5E7EB',
  },
  nextButton: {
    backgroundColor: 'rgb(45, 55, 72)',
  },
  navButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: 'rgb(45, 55, 72)',
  },
  nextButtonText: {
    color: '#FFFFFF',
  },
  // Missing items step styles
  missingHeader: {
    backgroundColor: '#FEF2F2',
    padding: 20,
    borderRadius: 3,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#FCA5A5',
  },
  missingTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#DC2626',
    marginBottom: 8,
  },
  missingSubtitle: {
    fontSize: 14,
    color: '#7F1D1D',
    lineHeight: 20,
  },
  missingItemContainer: {
    backgroundColor: '#FFFFFF',
    padding: 16,
    borderRadius: 3,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  missingItemHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  missingItemNumber: {
    fontSize: 14,
    fontWeight: '600',
    color: '#EF4444',
  },
  missingItemSection: {
    fontSize: 12,
    color: '#64748B',
    backgroundColor: '#F1F5F9',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 3,
  },
  missingItemTextContainer: {
    marginBottom: 16,
  },
  missingItemText: {
    fontSize: 14,
    color: 'rgb(45, 55, 72)',
    marginBottom: 16,
    lineHeight: 20,
  },
  missingFooter: {
    marginTop: 24,
    paddingTop: 24,
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
  },
  completeMissingButton: {
    backgroundColor: 'rgb(96, 187, 202)',
    paddingVertical: 14,
    paddingHorizontal: 24,
    borderRadius: 3,
    alignItems: 'center',
    marginBottom: 12,
  },
  completeMissingButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  // Question numbering
  questionNumber: {
    fontWeight: '700',
    color: 'rgb(96, 187, 202)',
    fontSize: 16,
  },
  // DISC styles
  discContainer: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginTop: 16,
    gap: 16,
  },
  discColumn: {
    flex: 1,
  },
  discHeaderMost: {
    fontSize: 16,
    fontWeight: '700',
    color: '#16A34A',
    textAlign: 'center',
    marginBottom: 12,
  },
  discHeaderLeast: {
    fontSize: 16,
    fontWeight: '700',
    color: '#DC2626',
    textAlign: 'center',
    marginBottom: 12,
  },
  discDivider: {
    width: 1,
    backgroundColor: '#E5E7EB',
    alignSelf: 'stretch',
    marginHorizontal: 8,
  },
  discOptions: {
    gap: 8,
  },
  discButton: {
    paddingVertical: 10,
    paddingHorizontal: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    backgroundColor: '#FFFFFF',
    alignItems: 'center',
  },
  discButtonSelectedMost: {
    backgroundColor: '#DCFCE7',
    borderColor: '#16A34A',
  },
  discButtonSelectedLeast: {
    backgroundColor: '#FEE2E2',
    borderColor: '#DC2626',
  },
  discButtonText: {
    fontSize: 14,
    color: 'rgb(45, 55, 72)',
  },
  discButtonTextSelected: {
    fontWeight: '600',
  },
  backToFormButton: {
    backgroundColor: '#FFFFFF',
    paddingVertical: 14,
    paddingHorizontal: 24,
    borderRadius: 3,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  backToFormButtonText: {
    color: 'rgb(45, 55, 72)',
    fontSize: 16,
    fontWeight: '500',
  },
});