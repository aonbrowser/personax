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

const API_URL = 'http://localhost:8080';

interface FormItem {
  id: string;
  text_tr: string;
  type: string;
  section: string;
  options_tr?: string;
  display_order?: number;
  subscale?: string;
}

interface FormAnswers {
  [key: string]: any;
}

// Cache buster: Updated at 2024-01-20 15:45
export default function NewFormsScreen({ navigation, route }: any) {
  // Check for edit mode params
  const editMode = route?.params?.editMode || false;
  const existingForm1Data = route?.params?.existingForm1Data || {};
  const existingForm2Data = route?.params?.existingForm2Data || {};
  const existingForm3Data = route?.params?.existingForm3Data || {};
  const analysisId = route?.params?.analysisId;

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


  useEffect(() => {
    // If in edit mode, load existing data
    if (editMode && (existingForm1Data || existingForm2Data || existingForm3Data)) {
      loadExistingData();
    } else {
      // Otherwise check if there are saved answers and resume from last incomplete form
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
      await loadAnswers();
    };
    loadData();
  }, [currentForm]);

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
    try {
      const storageKey = `form${currentForm}_answers`;
      console.log(`Loading answers for ${storageKey}`);
      let saved = null;
      
      if (Platform.OS === 'web') {
        saved = localStorage.getItem(storageKey);
      } else {
        saved = await AsyncStorage.getItem(storageKey);
      }
      
      if (saved) {
        const parsedAnswers = JSON.parse(saved);
        console.log(`Found ${Object.keys(parsedAnswers).length} saved answers for form ${currentForm}`);
        setAnswers(parsedAnswers);
      } else {
        console.log(`No saved answers found for form ${currentForm}`);
        setAnswers({});
      }
    } catch (error) {
      console.error('Error loading answers:', error);
    }
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
    const newAnswers = { ...answers, [itemId]: value };
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
    
    recognition.lang = 'tr-TR';
    recognition.continuous = true; // Changed to true for better experience
    recognition.interimResults = true;
    recognition.maxAlternatives = 1;

    let finalTranscript = answers[itemId] || '';
    let interimTranscript = '';

    recognition.onstart = () => {
      setIsRecording(itemId);
      console.log('Speech recognition started for:', itemId);
    };

    recognition.onresult = (event: any) => {
      interimTranscript = '';
      
      for (let i = event.resultIndex; i < event.results.length; ++i) {
        if (event.results[i].isFinal) {
          finalTranscript += event.results[i][0].transcript + ' ';
        } else {
          interimTranscript += event.results[i][0].transcript;
        }
      }
      
      const combinedTranscript = finalTranscript + interimTranscript;
      handleAnswer(itemId, combinedTranscript.trim());
      
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
      console.log('Speech recognition ended');
      // Don't set isRecording to null here, let stopSpeechRecognition handle it
    };

    recognitionRef.current = recognition;
    recognition.start();
  }, [answers]);

  const stopSpeechRecognition = () => {
    if (recognitionRef.current) {
      recognitionRef.current.stop();
      setIsRecording(null);
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
            <TextInput
              ref={(ref) => { textInputRefs.current[item.id] = ref; }}
              style={[styles.textInput, styles.multilineInput]}
              value={value}
              onChangeText={(text) => handleAnswer(item.id, text)}
              multiline
              numberOfLines={4}
              placeholder="Cevabınızı yazın..."
              placeholderTextColor="#94A3B8"
            />
            {speechRecognitionAvailable && (
              <TouchableOpacity
                style={[styles.micButton, isRecording === item.id && styles.micButtonActive]}
                onPress={() => {
                  if (isRecording === item.id) {
                    stopSpeechRecognition();
                  } else {
                    startSpeechRecognition(item.id);
                  }
                }}
              >
                <Text style={styles.micButtonText}>
                  {isRecording === item.id ? '🔴 Durdurmak için tıkla' : '🎤 Konuşarak yanıtla'}
                </Text>
              </TouchableOpacity>
            )}
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
        return (
          <View style={styles.multipleChoiceContainer}>
            {multiChoiceOptions.map((option, index) => {
              const optionKey = String.fromCharCode(65 + index); // A, B, C, D, E
              const isSelected = value === optionKey;
              return (
                <TouchableOpacity
                  key={index}
                  style={[styles.multipleChoiceOption, isSelected && styles.multipleChoiceOptionSelected]}
                  onPress={() => handleAnswer(item.id, optionKey)}
                >
                  <Text style={[styles.multipleChoiceText, isSelected && styles.multipleChoiceTextSelected]}>
                    {option}
                  </Text>
                </TouchableOpacity>
              );
            })}
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
    const requiredItems = items.filter(item => 
      !(item.type === 'OpenText' && item.id.includes('STORY'))
    );
    
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
      
      console.log('Form data loaded:', {
        form1: Object.keys(form1Answers).length,
        form2: Object.keys(form2Answers).length,
        form3: Object.keys(form3Answers).length
      });
    } catch (error) {
      console.error('Error loading form data:', error);
    }
    
    // For web, directly navigate or use confirm dialog
    if (Platform.OS === 'web') {
      // Directly navigate to payment check
      console.log('Navigating to PaymentCheck with data...');
      navigation.navigate('PaymentCheck', {
        form1Data: form1Answers,
        form2Data: form2Answers,
        form3Data: form3Answers
      });
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
              form3Data: form3Answers
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
            
            {missingItems.map((item, index) => (
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
                .filter(item => item.section === section)
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
    gap: 12,
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