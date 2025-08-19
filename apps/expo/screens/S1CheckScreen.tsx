import React, { useState, useEffect } from 'react';
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
} from 'react-native';

const API_URL = 'http://localhost:8080';

interface S1Item {
  id: string;
  text_tr: string;
  type: string;
  section: string;
  subscale?: string;
  options_tr?: string;
  notes?: string;
  scoring_key?: string;
}

interface S1Answers {
  [key: string]: string | number | undefined;
}

export default function S1CheckScreen({ navigation }: any) {
  const [items, setItems] = useState<S1Item[]>([]);
  const [answers, setAnswers] = useState<S1Answers>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [justSavedAnswers, setJustSavedAnswers] = useState(false);

  useEffect(() => {
    loadUnansweredItems();
  }, []);

  const loadUnansweredItems = async () => {
    try {
      console.log('Loading unanswered S1 items...');
      
      // First get all items
      const response = await fetch(`${API_URL}/v1/items/by-form?form=S1_self`, {
        headers: {
          'x-user-lang': 'tr',
          'x-user-id': 'test-user',
        },
      });
      
      const data = await response.json();
      console.log('Total S1 items:', data.items?.length);
      
      // Get saved answers - check both localStorage and AsyncStorage
      let saved = null;
      let savedAnswers = {};
      
      if (Platform.OS === 'web') {
        // Web uses localStorage
        saved = localStorage.getItem('S1_self_answers');
        savedAnswers = saved ? JSON.parse(saved) : {};
      } else {
        // Mobile uses AsyncStorage
        saved = await AsyncStorage.getItem('S1_self_answers');
        savedAnswers = saved ? JSON.parse(saved) : {};
      }
      console.log('Saved answers count:', Object.keys(savedAnswers).length);
      
      // Reset answers state to empty for this screen (we only track new answers)
      setAnswers({});
      
      // Filter only unanswered required questions
      const unanswered = data.items.filter((item: S1Item) => {
        // Skip ONLY truly optional questions (LifeStory questions marked as optional)
        const isOptional = item.notes?.toLowerCase().includes('opsiyonel');
        if (isOptional) {
          console.log('Skipping optional:', item.id);
          return false;
        }
        
        // Check if answered
        const hasAnswer = savedAnswers[item.id] !== undefined && 
                         savedAnswers[item.id] !== '' && 
                         savedAnswers[item.id] !== null;
        
        if (!hasAnswer) {
          console.log('Unanswered:', item.id, item.text_tr);
        }
        
        return !hasAnswer;
      });
      
      console.log('Unanswered questions count:', unanswered.length);
      setItems(unanswered);
      setLoading(false);
      
      // If all questions are answered, go to analysis
      if (unanswered.length === 0) {
        console.log('All questions answered, ready for analysis');
        Alert.alert(
          '✅ Tüm Sorular Tamamlandı',
          'Kişilik analiziniz hazır. Sonuçları görmek ister misiniz?',
          [
            { text: 'Analizi Gör', onPress: () => navigation.navigate('S1Analysis') }
          ]
        );
      } else if (justSavedAnswers) {
        // If we just saved some answers and there are still questions left
        setJustSavedAnswers(false);
        Alert.alert(
          '⚠️ Hala Eksik Sorular Var',
          `${unanswered.length} soru daha cevaplanması gerekiyor. Lütfen tüm soruları doldurun.`,
          [{ text: 'Tamam' }]
        );
      }
    } catch (error) {
      console.error('Error loading items:', error);
      setLoading(false);
    }
  };

  const handleAnswer = (itemId: string, value: any) => {
    const newAnswers = { ...answers, [itemId]: value };
    setAnswers(newAnswers);
    saveAnswers(newAnswers);
  };

  const saveAnswers = async (answersToSave?: S1Answers) => {
    try {
      const toSave = answersToSave || answers;
      
      if (Platform.OS === 'web') {
        // Web uses localStorage
        const existing = localStorage.getItem('S1_self_answers');
        const merged = existing ? { ...JSON.parse(existing), ...toSave } : toSave;
        localStorage.setItem('S1_self_answers', JSON.stringify(merged));
      } else {
        // Mobile uses AsyncStorage
        const existing = await AsyncStorage.getItem('S1_self_answers');
        const merged = existing ? { ...JSON.parse(existing), ...toSave } : toSave;
        await AsyncStorage.setItem('S1_self_answers', JSON.stringify(merged));
      }
    } catch (error) {
      console.error('Error saving answers:', error);
    }
  };

  const getVisibleItems = () => {
    return items;
  };

  const handleContinue = async () => {
    // First save current answers
    await saveAnswers();
    
    // Check which questions are still unanswered
    const answeredSomeQuestions = Object.keys(answers).length > 0;
    
    if (answeredSomeQuestions) {
      // Reload the page with updated data
      setLoading(true);
      setJustSavedAnswers(true);
      await loadUnansweredItems();
      // loadUnansweredItems will handle navigation or update state
      return;
    }
    
    // If no answers were provided in this session
    const visibleItems = getVisibleItems();
    const unansweredVisible = visibleItems.filter(item => {
      const hasAnswer = answers[item.id] !== undefined && 
                       answers[item.id] !== '' && 
                       answers[item.id] !== null;
      return !hasAnswer;
    });
    
    if (unansweredVisible.length > 0) {
      Alert.alert(
        '⚠️ Zorunlu Sorular',
        `Bu ${unansweredVisible.length} soru zorunludur. Lütfen en az birini cevaplayın.`,
        [{ text: 'Tamam' }]
      );
    }
  };

  const renderInput = (item: S1Item) => {
    const value = answers[item.id] || '';

    switch (item.type) {
      case 'Likert5':
        const likertOptions = ['1', '2', '3', '4', '5'];
        const likertLabels = item.options_tr?.split('|') || [];
        return (
          <View>
            <View style={styles.likertLabels}>
              <Text style={styles.likertLabelText}>{likertLabels[0]}</Text>
              <Text style={styles.likertLabelText}>{likertLabels[likertLabels.length - 1]}</Text>
            </View>
            <View style={styles.likertOptions}>
              {likertOptions.map((opt) => (
                <TouchableOpacity
                  key={opt}
                  style={[
                    styles.likertOption,
                    value === opt && styles.likertOptionSelected
                  ]}
                  onPress={() => handleAnswer(item.id, opt)}
                >
                  <Text style={[
                    styles.likertOptionText,
                    value === opt && styles.likertOptionTextSelected
                  ]}>{opt}</Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>
        );

      case 'MultiChoice5':
        const options = item.options_tr?.split('|') || [];
        return (
          <View style={styles.choiceContainer}>
            {options.map((option) => (
              <TouchableOpacity
                key={option}
                style={[
                  styles.choiceButton,
                  value === option && styles.choiceButtonSelected
                ]}
                onPress={() => handleAnswer(item.id, option)}
              >
                <Text
                  style={[
                    styles.choiceText,
                    value === option && styles.choiceTextSelected
                  ]}
                >
                  {option}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        );

      case 'OpenText':
        return (
          <TextInput
            style={styles.textInput}
            value={value.toString()}
            onChangeText={(text) => handleAnswer(item.id, text)}
            placeholder={item.notes || 'Cevabınızı yazınız'}
            placeholderTextColor="rgba(0,0,0,0.5)"
            multiline
            numberOfLines={4}
          />
        );

      default:
        return (
          <TextInput
            style={styles.textInput}
            value={value.toString()}
            onChangeText={(text) => handleAnswer(item.id, text)}
            placeholder={item.notes || 'Cevabınızı yazınız'}
            placeholderTextColor="rgba(0,0,0,0.5)"
            multiline
            numberOfLines={3}
          />
        );
    }
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.loadingContainer}>
          <Text style={styles.loadingText}>Kontrol ediliyor...</Text>
        </View>
      </SafeAreaView>
    );
  }

  const visibleItems = getVisibleItems();

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.screenContainer}>
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity
            style={styles.backButtonContainer}
            onPress={() => navigation.goBack()}
          >
            <Text style={styles.backArrow}>←</Text>
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Eksik Sorular</Text>
          <View style={styles.headerSpacer} />
        </View>

        {/* Content */}
        <ScrollView style={styles.content}>
          <View style={styles.formContentContainer}>
            <View style={styles.warningCard}>
              <Text style={styles.warningTitle}>⚠️ Dikkat</Text>
              <Text style={styles.warningText}>
                Hala cevaplanmamış {visibleItems.length} soru var. Lütfen hepsini doldurun.
              </Text>
              {visibleItems.length > 5 && (
                <Text style={styles.warningNote}>
                  Her "Devam Et" butonuna bastığınızda cevapladığınız sorular listeden çıkarılacaktır.
                </Text>
              )}
            </View>

            {visibleItems.map((item, index) => {
              // Get section name for display
              const getSectionName = (section: string) => {
                const names: { [key: string]: string } = {
                  'BigFive': 'Kişilik',
                  'MBTI': 'Düşünce Tarzı',
                  'DISC': 'Davranış',
                  'Attachment': 'Bağlanma',
                  'Conflict': 'Çatışma',
                  'Scenario': 'Senaryo',
                  'OpenEnded': 'Açık Uçlu',
                  'Quality': 'Kalite',
                  'LifeStory': 'Yaşam Öyküsü'
                };
                return names[section] || section;
              };

              return (
                <View key={item.id} style={styles.questionContainer}>
                  <View style={styles.questionHeader}>
                    <Text style={styles.questionNumber}>
                      Soru {index + 1} / {visibleItems.length}
                    </Text>
                    <Text style={styles.questionSection}>
                      {getSectionName(item.section)}
                    </Text>
                  </View>
                  <Text style={styles.questionText}>{item.text_tr}</Text>
                  {renderInput(item)}
                </View>
              );
            })}

            {/* Continue Button */}
            <TouchableOpacity
              style={[
                styles.continueButton,
                saving && styles.continueButtonDisabled
              ]}
              onPress={handleContinue}
              disabled={saving}
            >
              <Text style={styles.continueButtonText}>
                {saving ? 'Kontrol ediliyor...' : 'Devam Et'}
              </Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFF5F5',
  },
  screenContainer: {
    flex: 1,
    maxWidth: 990,
    width: '100%',
    alignSelf: 'center',
  },
  
  // Header
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 24,
    paddingVertical: 8,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 2,
    borderBottomColor: '#E53E3E',
  },
  backButtonContainer: {
    width: 40,
    height: 40,
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 3,
    backgroundColor: '#FED7D7',
  },
  backArrow: {
    fontSize: 20,
    color: '#E53E3E',
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#E53E3E',
    flex: 1,
    textAlign: 'center',
  },
  headerSpacer: {
    width: 40,
  },
  
  // Content
  content: {
    flex: 1,
  },
  formContentContainer: {
    paddingHorizontal: 24,
    paddingVertical: 20,
  },
  
  // Loading
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    fontSize: 16,
    color: '#E53E3E',
  },
  
  // Warning Card
  warningCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    padding: 16,
    marginBottom: 24,
    borderWidth: 2,
    borderColor: '#E53E3E',
  },
  warningTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#E53E3E',
    marginBottom: 8,
  },
  warningText: {
    fontSize: 14,
    color: '#742A2A',
  },
  warningNote: {
    fontSize: 12,
    color: '#9B2C2C',
    fontStyle: 'italic',
    marginTop: 8,
  },
  
  // Questions
  questionContainer: {
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    padding: 20,
    marginBottom: 16,
    borderWidth: 2,
    borderColor: '#FC8181',
  },
  questionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  questionNumber: {
    fontSize: 12,
    color: '#E53E3E',
    fontWeight: '600',
  },
  questionSection: {
    fontSize: 12,
    color: '#718096',
    fontWeight: '500',
  },
  questionText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#2D3748',
    marginBottom: 12,
  },
  
  // Inputs
  textInput: {
    borderWidth: 1,
    borderColor: '#FC8181',
    borderRadius: 3,
    padding: 12,
    fontSize: 14,
    minHeight: 100,
    textAlignVertical: 'top',
    backgroundColor: '#FFF5F5',
    color: '#2D3748',
  },
  
  // Choices
  choiceContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  choiceButton: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 3,
    backgroundColor: '#FFF5F5',
    borderWidth: 1,
    borderColor: '#FC8181',
    marginBottom: 8,
    marginRight: 8,
  },
  choiceButtonSelected: {
    backgroundColor: '#E53E3E',
    borderColor: '#E53E3E',
  },
  choiceText: {
    fontSize: 14,
    color: '#2D3748',
  },
  choiceTextSelected: {
    color: '#FFFFFF',
    fontWeight: '600',
  },
  
  // Likert Scale
  likertLabels: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
    paddingHorizontal: 4,
  },
  likertLabelText: {
    fontSize: 12,
    color: '#9B2C2C',
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
    borderColor: '#FC8181',
    borderRadius: 3,
    alignItems: 'center',
    backgroundColor: '#FFF5F5',
  },
  likertOptionSelected: {
    backgroundColor: '#E53E3E',
    borderColor: '#E53E3E',
  },
  likertOptionText: {
    fontSize: 14,
    color: '#742A2A',
  },
  likertOptionTextSelected: {
    color: '#FFFFFF',
    fontWeight: '600',
  },
  
  // Continue Button
  continueButton: {
    backgroundColor: '#E53E3E',
    borderRadius: 3,
    paddingVertical: 16,
    alignItems: 'center',
    marginTop: 24,
  },
  continueButtonDisabled: {
    opacity: 0.5,
  },
  continueButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '700',
  },
});