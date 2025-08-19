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
} from 'react-native';

const API_URL = 'http://localhost:8080';

interface S1Item {
  id: string;
  text_tr: string;
  type: string;
  section: string;
  options_tr?: string;
  notes?: string;
  scoring_key?: string;
}

interface S1Answers {
  [key: string]: string | number | undefined;
}

export default function S1FormScreen({ navigation }: any) {
  const [items, setItems] = useState<S1Item[]>([]);
  const [answers, setAnswers] = useState<S1Answers>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    console.log('S1FormScreen mounted');
    loadItems();
    loadSavedAnswers();
  }, []);

  // Section order and Turkish titles
  const sectionOrder = [
    'BigFive',
    'MBTI',
    'DISC',
    'Attachment',
    'Conflict',
    'Scenario',
    'OpenEnded',
    'Quality',
    'LifeStory'
  ];

  const getSectionTitle = (section: string): string => {
    const titles: { [key: string]: string } = {
      'BigFive': 'Kişilik Özellikleri (Big Five)',
      'MBTI': 'Düşünce ve Karar Verme Tarzı',
      'DISC': 'Davranış Profili',
      'Attachment': 'Bağlanma Stili',
      'Conflict': 'Çatışma Yönetimi',
      'Scenario': 'Senaryo Soruları',
      'OpenEnded': 'Açık Uçlu Sorular',
      'Quality': 'Kalite Kontrol',
      'LifeStory': 'Yaşam Öyküsü'
    };
    return titles[section] || section;
  };

  const loadItems = async () => {
    console.log('Loading S1 items from:', `${API_URL}/v1/items/by-form?form=S1_self`);
    try {
      const response = await fetch(`${API_URL}/v1/items/by-form?form=S1_self`, {
        headers: {
          'x-user-lang': 'tr',
          'x-user-id': 'test-user',
        },
      });
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      console.log('S1 items count:', data.items?.length || 0);
      
      if (data.items && data.items.length > 0) {
        // Sort items by section order
        const sortedItems = data.items.sort((a: S1Item, b: S1Item) => {
          const aIndex = sectionOrder.indexOf(a.section);
          const bIndex = sectionOrder.indexOf(b.section);
          return aIndex - bIndex;
        });
        setItems(sortedItems);
      } else {
        setItems([]);
      }
    } catch (error) {
      console.error('Error loading S1 items:', error);
      Alert.alert('Hata', `Form yüklenemedi: ${error.message}`);
      setItems([]);
    } finally {
      setLoading(false);
    }
  };

  const loadSavedAnswers = () => {
    try {
      if (Platform.OS === 'web') {
        const saved = localStorage.getItem('S1_self_answers');
        if (saved) {
          const parsedAnswers = JSON.parse(saved);
          setAnswers(parsedAnswers);
          
          // Inform if there are saved answers
          const answeredCount = Object.keys(parsedAnswers).length;
          if (answeredCount > 0) {
            Alert.alert(
              '📝 Devam Et',
              `Önceki taslağınız yüklendi. ${answeredCount} yanıt bulundu.`,
              [{ text: 'Tamam' }]
            );
          }
        }
      }
    } catch (error) {
      console.error('Error loading saved answers:', error);
    }
  };

  const saveAnswers = () => {
    try {
      if (Platform.OS === 'web') {
        localStorage.setItem('S1_self_answers', JSON.stringify(answers));
      }
    } catch (error) {
      console.error('Error saving answers:', error);
    }
  };

  const handleAnswer = (itemId: string, value: string | number) => {
    const newAnswers = { ...answers, [itemId]: value };
    setAnswers(newAnswers);
    // Auto-save to localStorage
    if (Platform.OS === 'web') {
      localStorage.setItem('S1_self_answers', JSON.stringify(newAnswers));
    }
  };

  const getProgress = () => {
    const answered = Object.keys(answers).filter(key => 
      answers[key] !== undefined && answers[key] !== null && answers[key] !== ''
    ).length;
    const total = items.length;
    return { answered, total, percentage: total > 0 ? Math.round((answered / total) * 100) : 0 };
  };

  const getUnansweredQuestions = () => {
    return items.filter(item => {
      // Skip ONLY truly optional questions (LifeStory section)
      const isOptional = item.notes?.toLowerCase().includes('opsiyonel');
      if (isOptional) return false;
      
      const hasAnswer = answers[item.id] !== undefined && 
                       answers[item.id] !== '' && 
                       answers[item.id] !== null;
      if (!hasAnswer) {
        console.log('Unanswered:', item.id, item.text_tr);
      }
      return !hasAnswer;
    });
  };

  const handleContinue = () => {
    const unanswered = getUnansweredQuestions();
    
    if (unanswered.length > 0) {
      // Has unanswered questions - go to S1Check screen
      setSaving(true);
      saveAnswers();
      navigation.navigate('S1Check');
    } else {
      // All required questions answered - proceed to analysis
      setSaving(true);
      saveAnswers();
      Alert.alert(
        '✅ Form Tamamlandı',
        'Tüm zorunlu sorular yanıtlandı. Analiz için devam edebilirsiniz.',
        [
          { text: 'Analiz Et', onPress: () => navigation.navigate('S1Analysis') }
        ]
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

      case 'ForcedChoice2':
        // MBTI A/B choice questions
        const choices = item.text_tr?.split('|').map(c => c.trim()) || [];
        const choiceOptions = item.options_tr?.split('|') || ['A', 'B'];
        return (
          <View style={styles.mbtiContainer}>
            {choices.map((choice, index) => {
              const optionKey = choiceOptions[index];
              const isSelected = value === optionKey;
              const choiceParts = choice.match(/^([AB])\)\s*(.+)$/);
              const letter = choiceParts ? choiceParts[1] : optionKey;
              const text = choiceParts ? choiceParts[2] : choice;
              
              return (
                <TouchableOpacity
                  key={optionKey}
                  style={[
                    styles.mbtiOption,
                    isSelected && styles.mbtiOptionSelected
                  ]}
                  onPress={() => handleAnswer(item.id, optionKey)}
                >
                  <View style={styles.mbtiContent}>
                    <View style={[
                      styles.mbtiLetter,
                      isSelected && styles.mbtiLetterSelected
                    ]}>
                      <Text style={[
                        styles.mbtiLetterText,
                        isSelected && styles.mbtiLetterTextSelected
                      ]}>{letter}</Text>
                    </View>
                    <Text style={[
                      styles.mbtiText,
                      isSelected && styles.mbtiTextSelected
                    ]}>{text}</Text>
                  </View>
                </TouchableOpacity>
              );
            })}
          </View>
        );

      case 'MultiChoice4':
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
        return null;
    }
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.loadingContainer}>
          <Text style={styles.loadingText}>Form yükleniyor...</Text>
        </View>
      </SafeAreaView>
    );
  }

  const progress = getProgress();

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.screenContainer}>
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity 
            onPress={() => navigation.navigate('S0Profile')} 
            style={styles.backButtonContainer}
          >
            <Text style={styles.backArrow}>←</Text>
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Kişilik Değerlendirmesi (S1)</Text>
          <View style={styles.headerSpacer} />
        </View>

        <ScrollView 
          showsVerticalScrollIndicator={false} 
          style={styles.content}
          contentContainerStyle={styles.formContentContainer}
        >
          {/* Progress Bar */}
          {items.length > 0 && (
            <View style={styles.progressContainer}>
              <View style={styles.progressHeader}>
                <Text style={styles.progressText}>
                  İlerleme: {progress.answered} / {progress.total}
                </Text>
                <Text style={styles.progressPercentage}>
                  %{progress.percentage}
                </Text>
              </View>
              <View style={styles.progressBarBackground}>
                <View 
                  style={[
                    styles.progressBarFill,
                    { width: `${progress.percentage}%` }
                  ]} 
                />
              </View>
            </View>
          )}

          {/* Instructions */}
          <View style={styles.instructionsCard}>
            <Text style={styles.instructionsTitle}>Yönergeler</Text>
            <Text style={styles.instructionText}>
              Bu form kişilik özelliklerinizi değerlendirmek için tasarlanmıştır. 
              Lütfen tüm soruları samimiyetle yanıtlayın.
            </Text>
            <Text style={styles.instructionNote}>
              "Opsiyonel" işaretli sorular hariç tüm soruları yanıtlamanız gerekmektedir.
            </Text>
          </View>

          {/* Questions */}
          <View style={styles.questionsContainer}>
            {items.map((item, index) => {
              // Section header
              const showSectionHeader = index === 0 || items[index - 1]?.section !== item.section;
              
              return (
                <View key={item.id}>
                  {showSectionHeader && (
                    <View style={styles.sectionDivider}>
                      <Text style={styles.sectionDividerText}>
                        {getSectionTitle(item.section)}
                      </Text>
                    </View>
                  )}
                  
                  <View style={styles.questionContainer}>
                    {/* Don't show question text for ForcedChoice2 (MBTI) questions */}
                    {item.type !== 'ForcedChoice2' && (
                      <>
                        <Text style={styles.questionText}>
                          {item.text_tr}
                        </Text>
                        {item.notes && item.notes.toLowerCase().includes('opsiyonel') && (
                          <Text style={styles.optionalLabel}>
                            (Opsiyonel)
                          </Text>
                        )}
                      </>
                    )}
                    {renderInput(item)}
                  </View>
                </View>
              );
            })}
          </View>

          {/* Footer */}
          <View style={styles.formFooter}>
            <View style={styles.summaryCard}>
              <Text style={styles.summaryTitle}>📊 Özet</Text>
              <Text style={styles.summaryText}>
                Toplam {progress.total} sorudan {progress.answered} tanesi yanıtlandı
              </Text>
              {progress.answered === progress.total && (
                <Text style={styles.completedText}>✅ Tüm sorular tamamlandı!</Text>
              )}
            </View>
            
            <TouchableOpacity 
              style={[
                styles.submitButton,
                saving && styles.submitButtonDisabled
              ]} 
              onPress={handleContinue}
              disabled={saving}
            >
              <Text style={styles.submitButtonText}>
                {saving ? 'Kaydediliyor...' : 'Devam Et'}
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
    backgroundColor: '#F0F4F8',
  },
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
    paddingVertical: 8,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
  },
  backButtonContainer: {
    width: 40,
    height: 40,
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 3,
    backgroundColor: '#F7FAFC',
  },
  backArrow: {
    fontSize: 20,
    color: '#2D3748',
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#2D3748',
    flex: 1,
    marginVertical: 8,
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
    color: '#4A5568',
  },
  
  // Progress
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
    color: '#718096',
  },
  progressPercentage: {
    fontSize: 15,
    fontWeight: 'bold',
    color: '#2D3748',
  },
  progressBarBackground: {
    height: 10,
    backgroundColor: '#E2E8F0',
    borderRadius: 3,
    overflow: 'hidden',
  },
  progressBarFill: {
    height: '100%',
    backgroundColor: '#4299E1',
    borderRadius: 3,
  },
  
  // Instructions
  instructionsCard: {
    backgroundColor: '#EDF2F7',
    padding: 20,
    borderRadius: 3,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#CBD5E0',
  },
  instructionsTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#2D3748',
    marginBottom: 12,
  },
  instructionText: {
    fontSize: 14,
    color: '#4A5568',
    lineHeight: 20,
  },
  instructionNote: {
    fontSize: 13,
    color: '#E53E3E',
    marginTop: 8,
  },
  
  // Questions
  questionsContainer: {
    marginBottom: 20,
  },
  questionContainer: {
    marginBottom: 20,
    padding: 16,
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  questionText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#2D3748',
    marginBottom: 12,
  },
  optionalLabel: {
    fontSize: 12,
    color: '#718096',
    fontStyle: 'italic',
    marginBottom: 8,
  },
  
  // Section Divider
  sectionDivider: {
    backgroundColor: '#2D3748',
    paddingVertical: 8,
    paddingHorizontal: 16,
    marginBottom: 16,
    marginTop: 8,
    borderRadius: 3,
  },
  sectionDividerText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
  },
  
  // Inputs
  textInput: {
    borderWidth: 1,
    borderColor: '#CBD5E0',
    borderRadius: 3,
    padding: 12,
    fontSize: 14,
    minHeight: 100,
    textAlignVertical: 'top',
    backgroundColor: '#F7FAFC',
    color: '#2D3748',
  },
  
  // Choice Buttons
  choiceContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
  },
  choiceButton: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderWidth: 1,
    borderColor: '#CBD5E0',
    borderRadius: 3,
    backgroundColor: '#FFFFFF',
    flexShrink: 1,
    minWidth: 0,
  },
  choiceButtonSelected: {
    backgroundColor: '#4299E1',
    borderColor: '#4299E1',
  },
  choiceText: {
    fontSize: 14,
    color: '#2D3748',
    flexWrap: 'wrap',
    textAlign: 'center',
  },
  choiceTextSelected: {
    color: '#FFFFFF',
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
    color: '#718096',
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
    borderColor: '#CBD5E0',
    borderRadius: 3,
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
  },
  likertOptionSelected: {
    backgroundColor: '#4299E1',
    borderColor: '#4299E1',
  },
  likertOptionText: {
    fontSize: 14,
    color: '#2D3748',
  },
  likertOptionTextSelected: {
    color: '#FFFFFF',
  },
  
  // MBTI Styles
  mbtiContainer: {
    gap: 12,
  },
  mbtiOption: {
    flexDirection: 'row',
    padding: 16,
    borderWidth: 2,
    borderColor: '#CBD5E0',
    borderRadius: 3,
    backgroundColor: '#FFFFFF',
  },
  mbtiOptionSelected: {
    backgroundColor: '#EBF8FF',
    borderColor: '#4299E1',
  },
  mbtiContent: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  mbtiLetter: {
    width: 36,
    height: 36,
    borderRadius: 3,
    backgroundColor: '#F7FAFC',
    borderWidth: 2,
    borderColor: '#CBD5E0',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  mbtiLetterSelected: {
    backgroundColor: '#4299E1',
    borderColor: '#4299E1',
  },
  mbtiLetterText: {
    fontSize: 18,
    fontWeight: '700',
    color: '#4A5568',
  },
  mbtiLetterTextSelected: {
    color: '#FFFFFF',
  },
  mbtiText: {
    flex: 1,
    fontSize: 15,
    color: '#2D3748',
    lineHeight: 20,
  },
  mbtiTextSelected: {
    color: '#2B6CB0',
    fontWeight: '500',
  },
  
  // Footer
  formFooter: {
    marginTop: 20,
  },
  summaryCard: {
    backgroundColor: '#EBF8FF',
    padding: 16,
    borderRadius: 3,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#90CDF4',
  },
  summaryTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#2B6CB0',
    marginBottom: 8,
  },
  summaryText: {
    fontSize: 14,
    color: '#2B6CB0',
  },
  completedText: {
    fontSize: 14,
    color: '#38A169',
    fontWeight: '600',
    marginTop: 8,
  },
  
  // Submit Button
  submitButton: {
    backgroundColor: '#4299E1',
    padding: 16,
    borderRadius: 3,
    alignItems: 'center',
  },
  submitButtonDisabled: {
    opacity: 0.6,
  },
  submitButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
});