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
  KeyboardAvoidingView,
  Platform,
  AsyncStorage,
} from 'react-native';

const API_URL = 'http://localhost:8080';

interface ProfileItem {
  id: string;
  text_tr: string;
  type: string;
  section: string;
  options_tr?: string;
  notes?: string;
}

interface ProfileAnswers {
  [key: string]: string | number | undefined;
}

export default function S0CheckScreen({ navigation }: any) {
  const [items, setItems] = useState<ProfileItem[]>([]);
  const [answers, setAnswers] = useState<ProfileAnswers>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [hideAnswered, setHideAnswered] = useState(false);
  const [attemptCount, setAttemptCount] = useState(0);
  const [justSavedAnswers, setJustSavedAnswers] = useState(false);

  useEffect(() => {
    loadUnansweredItems();
  }, []);

  const loadAnswers = async () => {
    try {
      const saved = await AsyncStorage.getItem('s0_answers');
      if (saved) {
        setAnswers(JSON.parse(saved));
      }
    } catch (error) {
      console.error('Error loading answers:', error);
    }
  };

  const loadUnansweredItems = async () => {
    try {
      console.log('Loading unanswered items...');
      
      // First get all items
      const response = await fetch(`${API_URL}/v1/items/by-form?form=S0_profile`, {
        headers: {
          'x-user-lang': 'tr',
          'x-user-id': 'test-user',
        },
      });
      
      const data = await response.json();
      console.log('Total S0 items:', data.items?.length);
      
      // Get saved answers - check both localStorage and AsyncStorage
      let saved = null;
      let savedAnswers = {};
      
      if (Platform.OS === 'web') {
        // Web uses localStorage
        saved = localStorage.getItem('S0_profile_answers');
        savedAnswers = saved ? JSON.parse(saved) : {};
      } else {
        // Mobile uses AsyncStorage
        saved = await AsyncStorage.getItem('S0_profile_answers');
        savedAnswers = saved ? JSON.parse(saved) : {};
      }
      console.log('Saved answers count:', Object.keys(savedAnswers).length);
      
      // Reset answers state to empty for this screen (we only track new answers)
      setAnswers({});
      
      // Filter only unanswered required questions
      const unanswered = data.items.filter((item: ProfileItem) => {
        // Skip ONLY truly optional questions
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
      
      // If all questions are answered, go to S1
      if (unanswered.length === 0) {
        console.log('All questions answered, navigating to S1Form');
        navigation.navigate('S0_MBTI');
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

  const saveAnswers = async (answersToSave?: ProfileAnswers) => {
    try {
      const toSave = answersToSave || answers;
      
      if (Platform.OS === 'web') {
        // Web uses localStorage
        const existing = localStorage.getItem('S0_profile_answers');
        const merged = existing ? { ...JSON.parse(existing), ...toSave } : toSave;
        localStorage.setItem('S0_profile_answers', JSON.stringify(merged));
      } else {
        // Mobile uses AsyncStorage
        const existing = await AsyncStorage.getItem('S0_profile_answers');
        const merged = existing ? { ...JSON.parse(existing), ...toSave } : toSave;
        await AsyncStorage.setItem('S0_profile_answers', JSON.stringify(merged));
      }
    } catch (error) {
      console.error('Error saving answers:', error);
    }
  };

  const getVisibleItems = () => {
    if (!hideAnswered) return items;
    
    return items.filter(item => {
      const hasAnswer = answers[item.id] !== undefined && 
                       answers[item.id] !== '' && 
                       answers[item.id] !== null;
      return !hasAnswer;
    });
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
    } else {
      // All questions answered - check if really all S0 questions are answered
      await saveAnswers();
      
      // Reload to check if there are any remaining unanswered questions
      const response = await fetch(`${API_URL}/v1/items/by-form?form=S0_profile`);
      const data = await response.json();
      
      let saved = null;
      let savedAnswers = {};
      if (Platform.OS === 'web') {
        saved = localStorage.getItem('S0_profile_answers');
        savedAnswers = saved ? JSON.parse(saved) : {};
      } else {
        saved = await AsyncStorage.getItem('S0_profile_answers');
        savedAnswers = saved ? JSON.parse(saved) : {};
      }
      
      const stillUnanswered = data.items.filter((item: ProfileItem) => {
        const isOptional = item.notes?.toLowerCase().includes('opsiyonel');
        if (isOptional) return false;
        
        const hasAnswer = savedAnswers[item.id] !== undefined && 
                         savedAnswers[item.id] !== '' && 
                         savedAnswers[item.id] !== null;
        return !hasAnswer;
      });
      
      if (stillUnanswered.length === 0) {
        // Really all done - go to S1
        navigation.navigate('S0_MBTI');
      } else {
        // Reload with remaining questions
        setItems(stillUnanswered);
        setHideAnswered(false);
      }
    }
  };

  const renderInput = (item: ProfileItem) => {
    const value = answers[item.id] || '';

    switch (item.type) {
      case 'Number':
        return (
          <TextInput
            style={styles.numberInput}
            value={value.toString()}
            onChangeText={(text) => {
              const num = parseInt(text) || '';
              handleAnswer(item.id, num);
            }}
            keyboardType="numeric"
            placeholder="Sayı giriniz"
            placeholderTextColor="rgba(0,0,0,0.5)"
          />
        );

      case 'SingleChoice':
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

      case 'MultiSelect':
        const multiOptions = item.options_tr?.split('|') || [];
        const selectedValues = value ? value.toString().split(',').filter(v => v) : [];
        const maxSelections = item.id === 'S0_VALUES_TOP3' ? 3 : undefined;
        
        return (
          <View>
            {maxSelections && (
              <Text style={styles.multiSelectHelp}>
                {selectedValues.length}/{maxSelections} seçildi
              </Text>
            )}
            <View style={styles.choiceContainer}>
              {multiOptions.map((option) => (
                <TouchableOpacity
                  key={option}
                  style={[
                    styles.choiceButton,
                    selectedValues.includes(option) && styles.choiceButtonSelected
                  ]}
                  onPress={() => {
                    let newValues = [...selectedValues];
                    if (selectedValues.includes(option)) {
                      newValues = newValues.filter(v => v !== option);
                    } else {
                      // Check max selections
                      if (maxSelections && newValues.filter(v => v).length >= maxSelections) {
                        Alert.alert(
                          'Maksimum Seçim',
                          `En fazla ${maxSelections} seçim yapabilirsiniz. Yeni bir seçim yapmak için önce mevcut seçimlerden birini kaldırın.`,
                          [{ text: 'Tamam' }]
                        );
                        return;
                      }
                      newValues.push(option);
                    }
                    handleAnswer(item.id, newValues.filter(v => v).join(','));
                  }}
                >
                  <Text
                    style={[
                      styles.choiceText,
                      selectedValues.includes(option) && styles.choiceTextSelected,
                    ]}
                  >
                    {option}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>
        );

      case 'RankedMulti':
        const rankedOptions = item.options_tr?.split('|') || [];
        const rankedValues = value ? value.toString().split(',') : [];
        return (
          <View>
            <Text style={styles.rankedHelpText}>Öncelik sırasına göre seçin (1. en önemli)</Text>
            <View style={styles.choiceContainer}>
              {rankedOptions.map((option) => {
                const rank = rankedValues.indexOf(option) + 1;
                return (
                  <TouchableOpacity
                    key={option}
                    style={[
                      styles.choiceButton,
                      rank > 0 && styles.choiceButtonSelected
                    ]}
                    onPress={() => {
                      let newValues = [...rankedValues];
                      if (rank > 0) {
                        // Remove if already selected
                        newValues = newValues.filter(v => v !== option);
                      } else {
                        // Add to the end
                        newValues.push(option);
                      }
                      handleAnswer(item.id, newValues.join(','));
                    }}
                  >
                    <Text
                      style={[
                        styles.choiceText,
                        rank > 0 && styles.choiceTextSelected,
                      ]}
                    >
                      {rank > 0 ? `${rank}. ` : ''}{option}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          </View>
        );

      case 'SingleLineText':
        return (
          <TextInput
            style={styles.singleLineInput}
            value={value.toString()}
            onChangeText={(text) => handleAnswer(item.id, text)}
            placeholder={item.notes || 'Cevabınızı yazınız'}
            placeholderTextColor="rgba(0,0,0,0.5)"
            multiline={false}
          />
        );
      
      case 'OpenText':
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
          <Text style={styles.headerTitle}>Atladığınız Sorular</Text>
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

            {visibleItems.map((item, index) => (
              <View key={item.id} style={styles.questionContainer}>
                <Text style={styles.questionNumber}>
                  Soru {index + 1} / {visibleItems.length}
                </Text>
                <Text style={styles.questionText}>{item.text_tr}</Text>
                {renderInput(item)}
              </View>
            ))}

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
    backgroundColor: '#FEF2F2',
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
    borderBottomColor: '#DC2626',
  },
  backButtonContainer: {
    width: 40,
    height: 40,
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 3,
    backgroundColor: '#FEE2E2',
  },
  backArrow: {
    fontSize: 20,
    color: '#DC2626',
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#DC2626',
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
    color: '#DC2626',
  },
  
  // Warning Card
  warningCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    padding: 16,
    marginBottom: 24,
    borderWidth: 2,
    borderColor: '#DC2626',
  },
  warningTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#DC2626',
    marginBottom: 8,
  },
  warningText: {
    fontSize: 14,
    color: '#7F1D1D',
  },
  warningNote: {
    fontSize: 12,
    color: '#991B1B',
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
    borderColor: '#FCA5A5',
  },
  questionNumber: {
    fontSize: 12,
    color: '#DC2626',
    fontWeight: '600',
    marginBottom: 8,
  },
  questionText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#000000',
    marginBottom: 12,
  },
  
  // Inputs
  textInput: {
    borderWidth: 1,
    borderColor: '#FCA5A5',
    borderRadius: 3,
    padding: 12,
    fontSize: 14,
    minHeight: 80,
    textAlignVertical: 'top',
    backgroundColor: '#FFF5F5',
    color: 'rgb(0,0,0)',
  },
  singleLineInput: {
    borderWidth: 1,
    borderColor: '#FCA5A5',
    borderRadius: 3,
    padding: 12,
    fontSize: 14,
    height: 44,
    backgroundColor: '#FFF5F5',
    color: 'rgb(0,0,0)',
  },
  numberInput: {
    borderWidth: 1,
    borderColor: '#FCA5A5',
    borderRadius: 3,
    padding: 12,
    fontSize: 14,
    width: 150,
    backgroundColor: '#FFF5F5',
    color: 'rgb(0,0,0)',
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
    borderColor: '#FCA5A5',
    marginBottom: 8,
    marginRight: 8,
  },
  choiceButtonSelected: {
    backgroundColor: '#DC2626',
    borderColor: '#DC2626',
  },
  choiceText: {
    fontSize: 14,
    color: '#000000',
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
    color: '#991B1B',
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
    borderColor: '#FCA5A5',
    borderRadius: 3,
    alignItems: 'center',
    backgroundColor: '#FFF5F5',
  },
  likertOptionSelected: {
    backgroundColor: '#DC2626',
    borderColor: '#DC2626',
  },
  likertOptionText: {
    fontSize: 14,
    color: '#7F1D1D',
  },
  likertOptionTextSelected: {
    color: '#FFFFFF',
    fontWeight: '600',
  },
  
  // Multi-select helpers
  multiSelectHelp: {
    fontSize: 12,
    color: '#991B1B',
    marginBottom: 8,
    textAlign: 'right',
  },
  rankedHelpText: {
    fontSize: 12,
    color: '#991B1B',
    marginBottom: 8,
    fontStyle: 'italic',
  },
  
  // Continue Button
  continueButton: {
    backgroundColor: '#DC2626',
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