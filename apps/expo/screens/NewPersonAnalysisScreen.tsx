import React, { useState, useEffect, useRef, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  TextInput,
  StyleSheet,
  Alert,
  ActivityIndicator,
  Platform,
  SafeAreaView,
  Image,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { API_URL } from '../config';
import AsyncStorage from '@react-native-async-storage/async-storage';

interface StepData {
  // Step 1 - Context
  personName?: string;
  personAge?: string;
  relationshipCategory?: string;
  relationshipDetail?: string;
  relationshipDepth?: number; // 1-5 scale
  analysisGoal?: string; // free text
  
  // Step 2 - Observer Big Five
  observerBigFive?: { [key: string]: number };
  
  // Step 3 - Structured Narrative
  strengths?: string;
  blindSpots?: string;
  stressBehavior?: string;
  growthAreas?: string;
  
  // Step 4 - Free Narrative
  freeNarrative?: string;
}

interface Draft {
  id: string;
  personName: string;
  createdAt: string;
  updatedAt: string;
  currentStep: number;
  stepData: StepData;
  status: 'draft' | 'completed';
}

const NewPersonAnalysisScreen = ({ 
  onClose, 
  userEmail,
  draftId = null,
  draftData = null,
  activeRecordingType,
  setActiveRecordingType,
  stopAnyActiveRecording
}: { 
  onClose: () => void; 
  userEmail: string;
  draftId?: string | null;
  draftData?: Draft | null;
  activeRecordingType?: string | null;
  setActiveRecordingType?: (type: string | null) => void;
  stopAnyActiveRecording?: () => void;
}) => {
  const [currentStep, setCurrentStep] = useState(1); // Always start from step 1
  const [stepData, setStepData] = useState<StepData>(() => {
    // Initialize with complete data structure
    const defaultData: StepData = {
      personName: '',
      personAge: '',
      relationshipCategory: '',
      relationshipDetail: '',
      relationshipDepth: undefined,
      analysisGoal: '',
      observerBigFive: {},
      strengths: '',
      blindSpots: '',
      stressBehavior: '',
      growthAreas: '',
      freeNarrative: '',
    };
    
    // Merge with draft data if available
    return draftData?.stepData ? { ...defaultData, ...draftData.stepData } : defaultData;
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [currentDraftId, setCurrentDraftId] = useState(draftId || null);
  const [isRecording, setIsRecording] = useState<string | null>(null);
  const recognitionRef = useRef<any>(null);
  const textInputRefs = useRef<{ [key: string]: TextInput | null }>({});
  
  // Web Speech API support check
  const speechRecognitionAvailable = Platform.OS === 'web' && 
    typeof window !== 'undefined' && 
    ('webkitSpeechRecognition' in window || 'SpeechRecognition' in window);
  
  // Refs to keep track of latest values
  const stepDataRef = React.useRef(stepData);
  const currentStepRef = React.useRef(currentStep);
  const currentDraftIdRef = React.useRef(currentDraftId);
  
  // Update refs when state changes
  React.useEffect(() => {
    stepDataRef.current = stepData;
  }, [stepData]);
  
  React.useEffect(() => {
    currentStepRef.current = currentStep;
  }, [currentStep]);
  
  React.useEffect(() => {
    currentDraftIdRef.current = currentDraftId;
  }, [currentDraftId]);
  
  // Log loaded draft data
  useEffect(() => {
    if (draftData) {
      console.log('Loaded draft data:', {
        personName: draftData.stepData?.personName,
        personAge: draftData.stepData?.personAge,
        relationshipDetail: draftData.stepData?.relationshipDetail,
        relationshipDepth: draftData.stepData?.relationshipDepth,
        relationshipCategory: draftData.stepData?.relationshipCategory,
        currentStep: draftData.currentStep,
        fullStepData: draftData.stepData
      });
      
      // Make sure stepData is properly initialized
      if (draftData.stepData) {
        setStepData(draftData.stepData);
      }
    }
  }, [draftData]);

  // Step 1 options
  const relationshipCategories = [
    { value: 'romantic', label: 'Romantik İlişki' },
    { value: 'family', label: 'Aile' },
    { value: 'friend', label: 'Arkadaş' },
    { value: 'colleague', label: 'İş Arkadaşı' },
    { value: 'other', label: 'Diğer' },
  ];


  // Observer Big Five questions with dimensions and reverse scoring
  const observerQuestions = {
    surface: [ // 1-2 depth: 10 questions
      { question: "Bu kişi genellikle konuşkan ve sohbeti seven biri midir?", dimension: "extraversion", reverse: false },
      { question: "Genellikle düzenli ve organize biri gibi mi görünür?", dimension: "conscientiousness", reverse: false },
      { question: "Başkalarına karşı genellikle nazik ve yardımsever midir?", dimension: "agreeableness", reverse: false },
      { question: "Kolayca strese girer veya kolayca keyfi kaçar mı?", dimension: "neuroticism", reverse: true },
      { question: "Yeni şeyler denemeye (yeni yemekler, yeni yerler) hevesli midir?", dimension: "openness", reverse: false },
      { question: "Sosyal ortamlarda genellikle sessiz veya geri planda mı kalır?", dimension: "extraversion", reverse: true },
      { question: "İşlerini veya sorumluluklarını erteleme eğilimi var mıdır?", dimension: "conscientiousness", reverse: true },
      { question: "Başkalarıyla kolayca tartışmaya girer veya inatlaşır mı?", dimension: "agreeableness", reverse: true },
      { question: "Genellikle sakin ve rahat bir tavrı mı vardır?", dimension: "neuroticism", reverse: false },
      { question: "Alışkanlıklarına ve rutinlerine sıkı sıkıya bağlı mıdır?", dimension: "openness", reverse: true },
    ],
    deep: [ // 3-5 depth: 20 questions (10 base + 10 additional)
      { question: "Bu kişi genellikle konuşkan ve sohbeti seven biri midir?", dimension: "extraversion", reverse: false },
      { question: "Genellikle düzenli ve organize biri gibi mi görünür?", dimension: "conscientiousness", reverse: false },
      { question: "Başkalarına karşı genellikle nazik ve yardımsever midir?", dimension: "agreeableness", reverse: false },
      { question: "Kolayca strese girer veya kolayca keyfi kaçar mı?", dimension: "neuroticism", reverse: true },
      { question: "Yeni şeyler denemeye (yeni yemekler, yeni yerler) hevesli midir?", dimension: "openness", reverse: false },
      { question: "Sosyal ortamlarda genellikle sessiz veya geri planda mı kalır?", dimension: "extraversion", reverse: true },
      { question: "İşlerini veya sorumluluklarını erteleme eğilimi var mıdır?", dimension: "conscientiousness", reverse: true },
      { question: "Başkalarıyla kolayca tartışmaya girer veya inatlaşır mı?", dimension: "agreeableness", reverse: true },
      { question: "Genellikle sakin ve rahat bir tavrı mı vardır?", dimension: "neuroticism", reverse: false },
      { question: "Alışkanlıklarına ve rutinlerine sıkı sıkıya bağlı mıdır?", dimension: "openness", reverse: true },
      { question: "Bir grubun içindeyken liderliği veya kontrolü ele alma eğilimi var mıdır?", dimension: "extraversion", reverse: false },
      { question: "Başladığı bir işi sonuna kadar titizlikle takip eder mi?", dimension: "conscientiousness", reverse: false },
      { question: "Başkalarının sorunlarıyla içtenlikle ilgilenir ve onlara zaman ayırır mı?", dimension: "agreeableness", reverse: false },
      { question: "Sık sık bir şeyler hakkında endişelendiğini veya kaygılandığını gözlemlediniz mi?", dimension: "neuroticism", reverse: true },
      { question: "Sanat, felsefe veya soyut fikirler hakkında konuşmaktan hoşlanır mı?", dimension: "openness", reverse: false },
      { question: "İlgi odağı olmaktan özellikle kaçınır mı?", dimension: "extraversion", reverse: true },
      { question: "Verdiği sözleri tutma veya planlarına sadık kalma konusunda ne kadar güvenilirdir?", dimension: "conscientiousness", reverse: false },
      { question: "Başkalarının hatalarına karşı kin tutar veya kolay affetmez mi?", dimension: "agreeableness", reverse: true },
      { question: "Ruh halinde ani ve belirgin dalgalanmalar yaşar mı?", dimension: "neuroticism", reverse: true },
      { question: "Hayal gücü geniş ve yaratıcı bir insan mıdır?", dimension: "openness", reverse: false },
    ]
  };

  const getQuestionCount = () => {
    // Based on relationship depth: 1-2 = 10 questions, 3-5 = 20 questions
    return (stepData.relationshipDepth || 1) <= 2 ? 10 : 20;
  };

  // Save draft to AsyncStorage
  const saveDraft = async () => {
    try {
      // Only save if person name exists
      if (!stepData.personName || stepData.personName.trim().length === 0) {
        return;
      }

      const drafts = await loadDrafts();
      
      // Make sure all fields are included in stepData
      const completeStepData = {
        personName: stepData.personName,
        personAge: stepData.personAge,
        relationshipCategory: stepData.relationshipCategory,
        relationshipDetail: stepData.relationshipDetail,
        relationshipDepth: stepData.relationshipDepth,
        analysisGoal: stepData.analysisGoal,
        observerBigFive: stepData.observerBigFive || {},
        strengths: stepData.strengths,
        blindSpots: stepData.blindSpots,
        stressBehavior: stepData.stressBehavior,
        growthAreas: stepData.growthAreas,
        freeNarrative: stepData.freeNarrative,
      };
      
      // Create or update draft
      const draftToSave: Draft = {
        id: currentDraftId || Date.now().toString(),
        personName: stepData.personName,
        createdAt: currentDraftId ? (drafts.find(d => d.id === currentDraftId)?.createdAt || new Date().toISOString()) : new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        currentStep,
        stepData: completeStepData,
        status: 'draft'
      };

      // Update or add draft
      const updatedDrafts = currentDraftId
        ? drafts.map(d => d.id === currentDraftId ? draftToSave : d)
        : [...drafts, draftToSave];

      // Save to storage
      if (Platform.OS === 'web') {
        localStorage.setItem('personAnalysisDrafts', JSON.stringify(updatedDrafts));
        // Verify what was saved
        const saved = localStorage.getItem('personAnalysisDrafts');
        const savedDrafts = saved ? JSON.parse(saved) : [];
        const savedDraft = savedDrafts.find((d: any) => d.id === draftToSave.id);
        console.log('Verified saved draft:', savedDraft);
      } else {
        await AsyncStorage.setItem('personAnalysisDrafts', JSON.stringify(updatedDrafts));
      }

      // Set draft ID for future saves
      if (!currentDraftId) {
        setCurrentDraftId(draftToSave.id);
      }
      
      console.log('Draft saved:', {
        id: draftToSave.id,
        personName: draftToSave.personName,
        personAge: completeStepData.personAge,
        relationshipDetail: completeStepData.relationshipDetail,
        relationshipDepth: completeStepData.relationshipDepth,
        relationshipCategory: completeStepData.relationshipCategory,
        currentStep: draftToSave.currentStep,
        fullData: completeStepData
      });
    } catch (error) {
      console.error('Error saving draft:', error);
    }
  };

  // Load all drafts
  const loadDrafts = async (): Promise<Draft[]> => {
    try {
      let draftsJson;
      if (Platform.OS === 'web') {
        draftsJson = localStorage.getItem('personAnalysisDrafts');
      } else {
        draftsJson = await AsyncStorage.getItem('personAnalysisDrafts');
      }
      const drafts = draftsJson ? JSON.parse(draftsJson) : [];
      
      // Log loaded drafts for debugging
      console.log('Loaded drafts from storage:', drafts.map(d => ({
        id: d.id,
        personName: d.personName,
        currentStep: d.currentStep,
        hasRelationshipDetail: !!d.stepData?.relationshipDetail,
        hasRelationshipDepth: d.stepData?.relationshipDepth !== undefined
      })));
      
      return drafts;
    } catch (error) {
      console.error('Error loading drafts:', error);
      return [];
    }
  };

  // Delete current draft
  const deleteDraft = async () => {
    if (!currentDraftId) return;
    
    try {
      const drafts = await loadDrafts();
      const updatedDrafts = drafts.filter(d => d.id !== currentDraftId);
      
      if (Platform.OS === 'web') {
        localStorage.setItem('personAnalysisDrafts', JSON.stringify(updatedDrafts));
      } else {
        await AsyncStorage.setItem('personAnalysisDrafts', JSON.stringify(updatedDrafts));
      }
    } catch (error) {
      console.error('Error deleting draft:', error);
    }
  };

  // Auto-save on data change
  useEffect(() => {
    const timeoutId = setTimeout(() => {
      saveDraft();
    }, 500); // Save after 0.5 second of inactivity

    return () => clearTimeout(timeoutId);
  }, [JSON.stringify(stepData), currentStep]);
  
  // Save on unmount
  useEffect(() => {
    return () => {
      // Save when component unmounts - use refs for latest values
      const currentStepData = stepDataRef.current;
      const currentStepValue = currentStepRef.current;
      const currentDraftIdValue = currentDraftIdRef.current;
      
      console.log('Unmount save - current values:', {
        relationshipDetail: currentStepData.relationshipDetail,
        relationshipDepth: currentStepData.relationshipDepth
      });
      
      const drafts = loadDrafts().then(drafts => {
        if (currentStepData.personName && currentStepData.personName.trim().length > 0) {
          // Make sure all fields are included
          const completeStepData = {
            personName: currentStepData.personName,
            personAge: currentStepData.personAge,
            relationshipCategory: currentStepData.relationshipCategory,
            relationshipDetail: currentStepData.relationshipDetail,
            relationshipDepth: currentStepData.relationshipDepth,
            analysisGoal: currentStepData.analysisGoal,
            observerBigFive: currentStepData.observerBigFive || {},
            strengths: currentStepData.strengths,
            blindSpots: currentStepData.blindSpots,
            stressBehavior: currentStepData.stressBehavior,
            growthAreas: currentStepData.growthAreas,
            freeNarrative: currentStepData.freeNarrative,
          };
          
          const draftToSave = {
            id: currentDraftIdValue || Date.now().toString(),
            personName: currentStepData.personName,
            createdAt: currentDraftIdValue ? (drafts.find(d => d.id === currentDraftIdValue)?.createdAt || new Date().toISOString()) : new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            currentStep: currentStepValue,
            stepData: completeStepData,
            status: 'draft' as const
          };

          const updatedDrafts = currentDraftIdValue
            ? drafts.map(d => d.id === currentDraftIdValue ? draftToSave : d)
            : [...drafts, draftToSave];

          if (Platform.OS === 'web') {
            localStorage.setItem('personAnalysisDrafts', JSON.stringify(updatedDrafts));
          }
        }
      });
    };
  }, []);

  // Speech-to-Text functions
  const startSpeechRecognition = useCallback((fieldId: string) => {
    // Stop any other active recording first
    if (activeRecordingType && activeRecordingType !== `person-analysis-${fieldId}`) {
      stopAnyActiveRecording?.();
    }
    
    if (!speechRecognitionAvailable) {
      Alert.alert('Uyarı', 'Ses tanıma özelliği bu tarayıcıda desteklenmiyor');
      return;
    }
    
    // Focus the text input first
    if (textInputRefs.current[fieldId]) {
      textInputRefs.current[fieldId]?.focus();
    }
    
    const SpeechRecognition = (window as any).webkitSpeechRecognition || (window as any).SpeechRecognition;
    const recognition = new SpeechRecognition();
    
    // Force Turkish language for speech recognition
    recognition.lang = 'tr-TR';
    recognition.continuous = true;
    recognition.interimResults = true;
    
    let finalTranscript = '';
    let lastUpdateTime = Date.now();
    
    recognition.onresult = (event: any) => {
      let interimTranscript = '';
      
      for (let i = event.resultIndex; i < event.results.length; i++) {
        const transcript = event.results[i][0].transcript;
        if (event.results[i].isFinal) {
          finalTranscript += transcript + ' ';
        } else {
          interimTranscript = transcript;
        }
      }
      
      const currentText = stepData[fieldId as keyof StepData] || '';
      const combinedText = currentText + finalTranscript + interimTranscript;
      
      setStepData(prev => ({
        ...prev,
        [fieldId]: combinedText.trim()
      }));
      
      // Update the input if it exists
      if (textInputRefs.current[fieldId]) {
        (textInputRefs.current[fieldId] as any).value = combinedText.trim();
        (textInputRefs.current[fieldId] as any).setNativeProps?.({ text: combinedText.trim() });
      }
      
      lastUpdateTime = Date.now();
      finalTranscript = '';
    };
    
    recognition.onerror = (event: any) => {
      console.error('Speech recognition error:', event.error);
      setIsRecording(null);
      setActiveRecordingType?.(null);
      
      if (event.error === 'no-speech') {
        Alert.alert('Uyarı', 'Ses algılanamadı. Lütfen tekrar deneyin.');
      } else if (event.error === 'not-allowed') {
        Alert.alert('Uyarı', 'Mikrofon izni gerekli. Lütfen tarayıcı ayarlarından mikrofon iznini verin.');
      }
    };
    
    recognition.onend = () => {
      if (isRecording === fieldId) {
        // Restart if still recording
        try {
          recognition.start();
        } catch (e) {
          console.log('Could not restart recognition:', e);
          setIsRecording(null);
          setActiveRecordingType?.(null);
        }
      }
    };
    
    setIsRecording(fieldId);
    setActiveRecordingType?.(`person-analysis-${fieldId}`);
    recognitionRef.current = recognition;
    recognition.start();
  }, [stepData, isRecording, activeRecordingType, setActiveRecordingType, stopAnyActiveRecording, speechRecognitionAvailable]);
  
  const stopSpeechRecognition = useCallback(() => {
    setIsRecording(null);
    setActiveRecordingType?.(null);
    if (recognitionRef.current) {
      try {
        recognitionRef.current.stop();
        recognitionRef.current.onend = null;
      } catch (e) {
        console.log('Error stopping recognition:', e);
      }
      recognitionRef.current = null;
    }
  }, [setActiveRecordingType]);
  
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
  }, [isRecording, stopSpeechRecognition]);

  const renderStep1 = () => (
    <ScrollView style={styles.formContainer} showsVerticalScrollIndicator={false}>
      <Text style={styles.stepTitle}>Adım 1: İlişki Bağlamı</Text>
      
      <View style={styles.questionBox}>
        <Text style={styles.sectionTitle}>Bu analize bir isim verin</Text>
        <TextInput
          style={styles.textInput}
          value={stepData.personName || ''}
          onChangeText={(text) => setStepData(prev => ({ ...prev, personName: text }))}
          placeholder="Annem, Derek, Jennifer v.s"
          placeholderTextColor="#9CA3AF"
        />
      </View>
      
      <View style={styles.questionBox}>
        <Text style={styles.sectionTitle}>Yaş</Text>
        <TextInput
          style={styles.textInput}
          value={stepData.personAge || ''}
          onChangeText={(text) => setStepData(prev => ({ ...prev, personAge: text }))}
          placeholder="Yaklaşık rakam giriniz"
          placeholderTextColor="#9CA3AF"
          keyboardType="numeric"
        />
      </View>
      
      <View style={styles.questionBox}>
        <Text style={styles.sectionTitle}>İlişki Kategorisi</Text>
        <View style={styles.optionsContainer}>
          {relationshipCategories.map((cat) => (
            <TouchableOpacity
              key={cat.value}
              style={[
                styles.optionButton,
                stepData.relationshipCategory === cat.value && styles.optionButtonSelected,
              ]}
              onPress={() => setStepData(prev => ({ ...prev, relationshipCategory: cat.value }))}
            >
              <Text
                style={[
                  styles.optionText,
                  stepData.relationshipCategory === cat.value && styles.optionTextSelected,
                ]}
              >
                {cat.label}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      <View style={styles.questionBox}>
        <Text style={styles.sectionTitle}>Bu kişi neyiniz oluyor?</Text>
        <TextInput
          style={styles.textInput}
          value={stepData.relationshipDetail || ''}
          onChangeText={(text) => {
            console.log('Setting relationshipDetail:', text);
            setStepData(prev => ({ ...prev, relationshipDetail: text }));
          }}
          placeholder="Örn: Annem, Eski sevgilim, İş arkadaşım, Kardeşim..."
          placeholderTextColor="#9CA3AF"
        />
      </View>

      <View style={styles.questionBox}>
        <Text style={styles.sectionTitle}>Bu kişiyi ne kadar iyi tanıyorsunuz?</Text>
        <View style={styles.likertContainer}>
          {[1, 2, 3, 4, 5].map((depth) => (
            <TouchableOpacity
              key={depth}
              style={[
                styles.likertOption,
                stepData.relationshipDepth === depth && styles.likertOptionSelected,
              ]}
              onPress={() => {
                console.log('Setting relationshipDepth:', depth);
                setStepData(prev => ({ ...prev, relationshipDepth: depth }));
              }}
            >
              <Text
                style={[
                  styles.likertText,
                  stepData.relationshipDepth === depth && styles.likertTextSelected,
                ]}
              >
                {depth}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
        <View style={styles.likertLabels}>
          <Text style={styles.likertLabel}>Çok Az</Text>
          <Text style={styles.likertLabel}>Çok İyi</Text>
        </View>
        <Text style={styles.questionCountInfo}>
          {stepData.relationshipDepth && 
            `(${getQuestionCount()} soru sorulacak)`
          }
        </Text>
      </View>

      <View style={styles.questionBox}>
        <Text style={styles.sectionTitle}>Analiz Amacı</Text>
        <Text style={styles.helperText}>Bu analizi neden yapıyorsunuz?</Text>
        <View style={styles.textAreaContainer}>
          <TextInput
            ref={(ref) => { textInputRefs.current['analysisGoal'] = ref; }}
            style={[styles.textArea, { minHeight: 80 }]}
            multiline
            numberOfLines={3}
            value={stepData.analysisGoal || ''}
            onChangeText={(text) => setStepData(prev => ({ ...prev, analysisGoal: text }))}
            placeholder="Örn: İlişkimizi daha iyi anlamak istiyorum, Son zamanlarda yaşadığımız sorunları çözmek için..."
            placeholderTextColor="#9CA3AF"
            {...(Platform.OS === 'web' ? { 'data-text-input': true } : {})}
          />
          {speechRecognitionAvailable && (
            <TouchableOpacity
              style={[styles.micButtonInline, isRecording === 'analysisGoal' && styles.micButtonInlineActive]}
              {...(Platform.OS === 'web' ? { 'data-mic-button': true } : {})}
              onPress={() => {
                if (isRecording === 'analysisGoal') {
                  stopSpeechRecognition();
                } else {
                  startSpeechRecognition('analysisGoal');
                }
              }}
            >
              {isRecording === 'analysisGoal' ? (
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
    </ScrollView>
  );

  const renderStep2 = () => {
    // Select questions based on relationship depth
    const questions = (stepData.relationshipDepth || 1) <= 2 
      ? observerQuestions.surface 
      : observerQuestions.deep;

    return (
      <ScrollView style={styles.formContainer} showsVerticalScrollIndicator={false}>
        <Text style={styles.stepTitle}>Adım 2: Kişilik Değerlendirmesi</Text>
        <Text style={styles.instructionText}>
          Bu kişiyi düşünerek aşağıdaki soruları değerlendirin (İsteğe bağlı)
        </Text>
        
        {questions.map((item, index) => (
          <View key={index} style={styles.questionBox}>
            <Text style={styles.questionText}>{item.question}</Text>
            <View style={styles.likertContainer}>
              {[1, 2, 3, 4, 5].map((value) => (
                <TouchableOpacity
                  key={value}
                  style={[
                    styles.likertOption,
                    stepData.observerBigFive?.[`q_${index}`] === value &&
                      styles.likertOptionSelected,
                  ]}
                  onPress={() =>
                    setStepData(prev => ({
                      ...prev,
                      observerBigFive: {
                        ...prev.observerBigFive,
                        [`q_${index}`]: value,
                        [`q_${index}_dimension`]: item.dimension,
                        [`q_${index}_reverse`]: item.reverse,
                      },
                    }))
                  }
                >
                  <Text
                    style={[
                      styles.likertText,
                      stepData.observerBigFive?.[`q_${index}`] === value &&
                        styles.likertTextSelected,
                    ]}
                  >
                    {value}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
            <View style={styles.likertLabels}>
              <Text style={styles.likertLabel}>Kesinlikle Hayır</Text>
              <Text style={styles.likertLabel}>Kesinlikle Evet</Text>
            </View>
          </View>
        ))}
      </ScrollView>
    );
  };

  const renderStep3 = () => (
    <ScrollView style={styles.formContainer} showsVerticalScrollIndicator={false}>
      <Text style={styles.stepTitle}>Adım 3: Yapılandırılmış Anlatı</Text>
      
      <View style={styles.questionBox}>
        <Text style={styles.inputLabel}>Bu kişinin güçlü yönleri nelerdir?</Text>
        <View style={styles.textAreaContainer}>
          <TextInput
            ref={(ref) => { textInputRefs.current['strengths'] = ref; }}
            style={styles.textArea}
            multiline
            numberOfLines={4}
            value={stepData.strengths || ''}
            onChangeText={(text) => setStepData(prev => ({ ...prev, strengths: text }))}
            placeholder="Örn: Problem çözme yeteneği, empati kurma..."
            placeholderTextColor="#9CA3AF"
            {...(Platform.OS === 'web' ? { 'data-text-input': true } : {})}
          />
          {speechRecognitionAvailable && (
            <TouchableOpacity
              style={[styles.micButtonInline, isRecording === 'strengths' && styles.micButtonInlineActive]}
              {...(Platform.OS === 'web' ? { 'data-mic-button': true } : {})}
              onPress={() => {
                if (isRecording === 'strengths') {
                  stopSpeechRecognition();
                } else {
                  startSpeechRecognition('strengths');
                }
              }}
            >
              {isRecording === 'strengths' ? (
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

      <View style={styles.questionBox}>
        <Text style={styles.inputLabel}>Kör noktaları veya gelişim alanları nelerdir?</Text>
        <View style={styles.textAreaContainer}>
          <TextInput
            ref={(ref) => { textInputRefs.current['blindSpots'] = ref; }}
            style={styles.textArea}
            multiline
            numberOfLines={4}
            value={stepData.blindSpots || ''}
            onChangeText={(text) => setStepData(prev => ({ ...prev, blindSpots: text }))}
            placeholder="Örn: Zaman yönetimi, duygularını ifade etme..."
            placeholderTextColor="#9CA3AF"
            {...(Platform.OS === 'web' ? { 'data-text-input': true } : {})}
          />
          {speechRecognitionAvailable && (
            <TouchableOpacity
              style={[styles.micButtonInline, isRecording === 'blindSpots' && styles.micButtonInlineActive]}
              {...(Platform.OS === 'web' ? { 'data-mic-button': true } : {})}
              onPress={() => {
                if (isRecording === 'blindSpots') {
                  stopSpeechRecognition();
                } else {
                  startSpeechRecognition('blindSpots');
                }
              }}
            >
              {isRecording === 'blindSpots' ? (
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

      <View style={styles.questionBox}>
        <Text style={styles.inputLabel}>Stres altındayken nasıl davranır?</Text>
        <View style={styles.textAreaContainer}>
          <TextInput
            ref={(ref) => { textInputRefs.current['stressBehavior'] = ref; }}
            style={styles.textArea}
            multiline
            numberOfLines={4}
            value={stepData.stressBehavior || ''}
            onChangeText={(text) => setStepData(prev => ({ ...prev, stressBehavior: text }))}
            placeholder="Örn: İçine kapanır, agresifleşir..."
            placeholderTextColor="#9CA3AF"
            {...(Platform.OS === 'web' ? { 'data-text-input': true } : {})}
          />
          {speechRecognitionAvailable && (
            <TouchableOpacity
              style={[styles.micButtonInline, isRecording === 'stressBehavior' && styles.micButtonInlineActive]}
              {...(Platform.OS === 'web' ? { 'data-mic-button': true } : {})}
              onPress={() => {
                if (isRecording === 'stressBehavior') {
                  stopSpeechRecognition();
                } else {
                  startSpeechRecognition('stressBehavior');
                }
              }}
            >
              {isRecording === 'stressBehavior' ? (
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

      <View style={styles.questionBox}>
        <Text style={styles.inputLabel}>Hangi alanlarda destek veya teşvik bekler?</Text>
        <View style={styles.textAreaContainer}>
          <TextInput
            ref={(ref) => { textInputRefs.current['growthAreas'] = ref; }}
            style={styles.textArea}
            multiline
            numberOfLines={4}
            value={stepData.growthAreas || ''}
            onChangeText={(text) => setStepData(prev => ({ ...prev, growthAreas: text }))}
            placeholder="Örn: Kariyer hedefleri, kişisel gelişim..."
            placeholderTextColor="#9CA3AF"
            {...(Platform.OS === 'web' ? { 'data-text-input': true } : {})}
          />
          {speechRecognitionAvailable && (
            <TouchableOpacity
              style={[styles.micButtonInline, isRecording === 'growthAreas' && styles.micButtonInlineActive]}
              {...(Platform.OS === 'web' ? { 'data-mic-button': true } : {})}
              onPress={() => {
                if (isRecording === 'growthAreas') {
                  stopSpeechRecognition();
                } else {
                  startSpeechRecognition('growthAreas');
                }
              }}
            >
              {isRecording === 'growthAreas' ? (
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
    </ScrollView>
  );

  const renderStep4 = () => (
    <ScrollView style={styles.formContainer} showsVerticalScrollIndicator={false}>
      <Text style={styles.stepTitle}>Adım 4: Serbest Anlatı</Text>
      
      <View style={styles.questionBox}>
        <Text style={styles.inputLabel}>
          Serbest Anlatı
        </Text>
        <Text style={styles.importantHelperText}>
          Bu kişiyle alakalı yaşadığınız veya yaşadığını bildiğiniz anılar, kendi gözlemleriniz vs. bol bol anlatın. Değerlendirmede önemli bir alan burası.
        </Text>
        <View style={styles.textAreaContainer}>
          <TextInput
            ref={(ref) => { textInputRefs.current['freeNarrative'] = ref; }}
            style={[styles.textArea, { minHeight: 200 }]}
            multiline
            numberOfLines={10}
            value={stepData.freeNarrative || ''}
            onChangeText={(text) => setStepData(prev => ({ ...prev, freeNarrative: text }))}
            placeholder=""
            placeholderTextColor="#9CA3AF"
            {...(Platform.OS === 'web' ? { 'data-text-input': true } : {})}
          />
          {speechRecognitionAvailable && (
            <TouchableOpacity
              style={[styles.micButtonInline, isRecording === 'freeNarrative' && styles.micButtonInlineActive]}
              {...(Platform.OS === 'web' ? { 'data-mic-button': true } : {})}
              onPress={() => {
                if (isRecording === 'freeNarrative') {
                  stopSpeechRecognition();
                } else {
                  startSpeechRecognition('freeNarrative');
                }
              }}
            >
              {isRecording === 'freeNarrative' ? (
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
    </ScrollView>
  );

  const handleStepChange = async (newStep: number) => {
    // Save current data before changing step
    await saveDraft();
    setCurrentStep(newStep);
  };

  const canProceedToNext = () => {
    switch (currentStep) {
      case 1:
        const hasName = stepData.personName && stepData.personName.trim().length > 0;
        const hasAge = stepData.personAge && stepData.personAge.trim().length > 0;
        const hasCategory = !!stepData.relationshipCategory;
        const hasDetail = stepData.relationshipDetail && stepData.relationshipDetail.trim().length > 0;
        const hasDepth = stepData.relationshipDepth !== undefined && 
                        stepData.relationshipDepth !== null && 
                        stepData.relationshipDepth >= 1 && 
                        stepData.relationshipDepth <= 5;
        const hasGoal = stepData.analysisGoal && stepData.analysisGoal.trim().length > 10;
        
        const validationResult = Boolean(
          hasName && hasAge && hasCategory && hasDetail && hasDepth && hasGoal
        );
        
        console.log('Step 1 validation:', {
          personName: hasName,
          personAge: hasAge, 
          relationshipCategory: hasCategory,
          relationshipDetail: hasDetail,
          relationshipDepth: hasDepth,
          relationshipDepthValue: stepData.relationshipDepth,
          analysisGoal: hasGoal,
          result: validationResult
        });
        
        return validationResult;
      case 2:
        // Step 2 is optional - always allow proceeding
        return true;
      case 3:
        return (
          stepData.strengths &&
          stepData.blindSpots &&
          stepData.stressBehavior &&
          stepData.growthAreas
        );
      case 4:
        return stepData.freeNarrative && stepData.freeNarrative.length > 20;
      default:
        return false;
    }
  };

  const handleSubmit = async () => {
    setIsSubmitting(true);
    
    // Save draft one more time before submitting
    await saveDraft();
    
    try {
      // First check subscription/payment status
      const checkResponse = await fetch(`${API_URL}/v1/user/check-credits`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-user-email': userEmail,
        },
        body: JSON.stringify({
          serviceType: 'other_analysis',
        }),
      });

      if (checkResponse.ok) {
        const checkData = await checkResponse.json();
        
        if (!checkData.hasCredits) {
          // Navigate to payment screen
          setIsSubmitting(false);
          Alert.alert(
            'Kredi Yetersiz',
            'Analiz için yeterli krediniz bulunmuyor. Ödeme sayfasına yönlendiriliyorsunuz.',
            [
              {
                text: 'Tamam',
                onPress: () => {
                  // Navigate to payment - you need to implement this navigation
                  console.log('Navigate to payment');
                }
              }
            ]
          );
          return;
        }
      }

      // Proceed with analysis
      console.log('Sending analysis request...');
      const response = await fetch(`${API_URL}/v1/analyze/other`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-user-lang': 'tr',
          'x-user-id': userEmail,
          'x-user-email': userEmail,
        },
        body: JSON.stringify({
          targetId: stepData.personName,
          context: {
            personAge: stepData.personAge,
            relationshipCategory: stepData.relationshipCategory,
            relationshipDetail: stepData.relationshipDetail,
            relationshipDepth: stepData.relationshipDepth,
            analysisGoal: stepData.analysisGoal,
          },
          observerBigFive: stepData.observerBigFive,
          narrative: {
            strengths: stepData.strengths,
            blindSpots: stepData.blindSpots,
            stressBehavior: stepData.stressBehavior,
            growthAreas: stepData.growthAreas,
            freeForm: stepData.freeNarrative,
          },
        }),
      });

      const responseText = await response.text();
      console.log('Response status:', response.status);
      console.log('Response text:', responseText);

      if (!response.ok) {
        throw new Error(`Analiz başarısız oldu: ${responseText}`);
      }

      const result = JSON.parse(responseText);
      
      // Delete draft on successful submission
      await deleteDraft();
      
      Alert.alert('Başarılı', 'Kişi analizi tamamlandı!', [
        { text: 'Tamam', onPress: onClose },
      ]);
    } catch (error) {
      console.error('Analysis error:', error);
      Alert.alert(
        'Hata', 
        `Analiz sırasında bir hata oluştu: ${error.message}. Lütfen tekrar deneyin.`
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.headerContainer}>
        <View style={styles.headerContent}>
          <View style={styles.headerLeft}>
            <TouchableOpacity
              style={styles.headerBackButton}
              onPress={onClose}
            >
              <Text style={styles.headerBackText}>←</Text>
            </TouchableOpacity>
          </View>
          
          <View style={styles.headerTitleContainer}>
            <View style={styles.titleWithIcon}>
              <Image 
                source={require('../assets/images/cogni-coach-icon.png')} 
                style={styles.headerIcon}
                resizeMode="contain"
              />
              <Text style={styles.headerTitle}>
                Yeni Kişi Analizi
              </Text>
            </View>
            <Text style={styles.headerSubtitle}>
              Adım {currentStep}/4
            </Text>
          </View>
          
          <View style={styles.headerRight}>
            <View style={styles.progressInfo}>
              <View style={styles.progressBadge}>
                <Text style={styles.progressText}>
                  {currentStep}/4
                </Text>
              </View>
              {stepData.personName && (
                <Text style={styles.savedIndicator}>
                  💾 Taslak
                </Text>
              )}
            </View>
          </View>
        </View>
      </View>

      <View style={styles.content}>
        {currentStep === 1 && renderStep1()}
        {currentStep === 2 && renderStep2()}
        {currentStep === 3 && renderStep3()}
        {currentStep === 4 && renderStep4()}
      </View>

      <View style={styles.footer}>
        <View style={styles.buttonContainer}>
          {currentStep > 1 && (
            <TouchableOpacity
              style={styles.secondaryButton}
              onPress={() => handleStepChange(currentStep - 1)}
            >
              <Text style={styles.secondaryButtonText}>← Geri</Text>
            </TouchableOpacity>
          )}
          
          {currentStep < 4 ? (
            <TouchableOpacity
              style={[
                styles.primaryButton,
                !canProceedToNext() && styles.primaryButtonDisabled,
              ]}
              onPress={() => canProceedToNext() && handleStepChange(currentStep + 1)}
              disabled={!canProceedToNext()}
            >
              <Text style={styles.primaryButtonText}>İleri →</Text>
            </TouchableOpacity>
          ) : (
            <TouchableOpacity
              style={[
                styles.submitButton,
                (!canProceedToNext() || isSubmitting) && styles.submitButtonDisabled,
              ]}
              onPress={handleSubmit}
              disabled={!canProceedToNext() || isSubmitting}
            >
              {isSubmitting ? (
                <ActivityIndicator color="#fff" />
              ) : (
                <Text style={styles.submitButtonText}>Analizi Başlat</Text>
              )}
            </TouchableOpacity>
          )}
        </View>
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F9FAFB',
  },
  formContainer: {
    flex: 1,
    backgroundColor: '#F9FAFB',
    paddingHorizontal: 16,
  },
  questionBox: {
    backgroundColor: '#fff',
    borderRadius: 3,
    padding: 16,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#E5E7EB',
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
    paddingVertical: 12,
  },
  headerLeft: {
    width: 60,
  },
  headerBackButton: {
    padding: 8,
  },
  headerBackText: {
    fontSize: 24,
    color: '#374151',
  },
  headerTitleContainer: {
    flex: 1,
    alignItems: 'center',
  },
  titleWithIcon: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  headerIcon: {
    width: 24,
    height: 24,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1F2937',
  },
  headerSubtitle: {
    fontSize: 12,
    color: '#6B7280',
    marginTop: 2,
  },
  headerRight: {
    width: 60,
    alignItems: 'flex-end',
  },
  progressInfo: {
    alignItems: 'flex-end',
  },
  progressBadge: {
    backgroundColor: 'rgb(96, 187, 202)',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 3,
  },
  progressText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '600',
  },
  savedIndicator: {
    fontSize: 10,
    color: '#6B7280',
    marginTop: 2,
  },
  content: {
    flex: 1,
    backgroundColor: '#F9FAFB',
  },
  stepTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#000',
    marginBottom: 20,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '500',
    color: '#000',
    marginTop: 16,
    marginBottom: 12,
  },
  optionsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  optionButton: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    backgroundColor: '#fff',
  },
  optionButtonSelected: {
    backgroundColor: 'rgb(96, 187, 202)',
    borderColor: 'rgb(96, 187, 202)',
  },
  optionText: {
    fontSize: 14,
    color: '#000',
  },
  optionTextSelected: {
    color: '#fff',
  },
  questionCount: {
    fontSize: 12,
    color: '#666',
    marginTop: 2,
  },
  textInput: {
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    padding: 12,
    fontSize: 14,
    backgroundColor: 'rgb(244, 244, 244)',
    color: '#000',
    marginBottom: 8,
  },
  questionCountInfo: {
    fontSize: 12,
    color: '#666',
    textAlign: 'center',
    marginBottom: 16,
  },
  instructionText: {
    fontSize: 14,
    color: '#666',
    marginBottom: 16,
  },
  questionContainer: {
    marginBottom: 24,
  },
  questionText: {
    fontSize: 14,
    color: '#000',
    marginBottom: 12,
  },
  likertContainer: {
    flexDirection: 'row',
    gap: 8,
  },
  likertOption: {
    flex: 1,
    paddingVertical: 10,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    alignItems: 'center',
    backgroundColor: '#fff',
  },
  likertOptionSelected: {
    backgroundColor: 'rgb(96, 187, 202)',
    borderColor: 'rgb(96, 187, 202)',
  },
  likertText: {
    fontSize: 14,
    color: '#000',
  },
  likertTextSelected: {
    color: '#fff',
  },
  likertLabels: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 4,
  },
  likertLabel: {
    fontSize: 11,
    color: '#666',
  },
  inputLabel: {
    fontSize: 14,
    fontWeight: '500',
    color: '#000',
    marginTop: 16,
    marginBottom: 8,
  },
  helperText: {
    fontSize: 12,
    color: '#666',
    marginBottom: 8,
  },
  importantHelperText: {
    fontSize: 14,
    color: 'rgb(96, 187, 202)',
    marginBottom: 12,
    lineHeight: 20,
  },
  textArea: {
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    padding: 12,
    fontSize: 14,
    backgroundColor: 'rgb(244, 244, 244)',
    color: '#000',
    minHeight: 100,
    textAlignVertical: 'top',
  },
  footer: {
    backgroundColor: '#FFFFFF',
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
    paddingVertical: 16,
    paddingHorizontal: 16,
    ...Platform.select({
      web: {
        position: 'sticky',
        bottom: 0,
        zIndex: 100,
      },
      default: {
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
      }
    })
  },
  buttonContainer: {
    flexDirection: 'row',
    gap: 12,
  },
  primaryButton: {
    flex: 1,
    paddingVertical: 14,
    backgroundColor: 'rgb(96, 187, 202)',
    borderRadius: 3,
    alignItems: 'center',
  },
  primaryButtonDisabled: {
    backgroundColor: '#9CA3AF',
  },
  primaryButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  secondaryButton: {
    flex: 1,
    paddingVertical: 14,
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    alignItems: 'center',
  },
  secondaryButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#374151',
  },
  submitButton: {
    flex: 1,
    paddingVertical: 14,
    backgroundColor: 'rgb(34, 197, 94)',
    borderRadius: 3,
    alignItems: 'center',
  },
  submitButtonDisabled: {
    backgroundColor: '#9CA3AF',
  },
  submitButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  textAreaContainer: {
    position: 'relative',
    width: '100%',
  },
  micButtonInline: {
    position: 'absolute',
    right: 8,
    bottom: 8,
    padding: 8,
    borderRadius: 3,
    backgroundColor: '#F3F4F6',
    borderWidth: 1,
    borderColor: '#E5E7EB',
    alignItems: 'center',
    justifyContent: 'center',
    width: 40,
    height: 40,
  },
  micButtonInlineActive: {
    backgroundColor: 'rgba(239, 68, 68, 0.1)',
    borderColor: '#EF4444',
  },
  micIcon: {
    fontSize: 20,
  },
  micImageIcon: {
    width: 20,
    height: 20,
  },
});

export default NewPersonAnalysisScreen;