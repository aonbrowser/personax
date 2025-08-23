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
} from 'react-native';

import { API_URL } from '../config';

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

export default function S0ProfileScreen({ navigation }: any) {
  const [items, setItems] = useState<ProfileItem[]>([]);
  const [answers, setAnswers] = useState<ProfileAnswers>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [showOnlyUnanswered, setShowOnlyUnanswered] = useState(false);
  const [highlightUnanswered, setHighlightUnanswered] = useState(false);

  useEffect(() => {
    console.log('S0ProfileScreen mounted');
    loadItems();
    loadSavedAnswers();
  }, []);

  // Section order and Turkish titles - matches database display_order
  const sectionOrder = [
    'Demographics',
    'EducationWork',
    'Relationship',
    'Preferences',
    'Goals',
    'Challenges',
    'Values',
    'Support',
    'Romantic',
    'Consent'
  ];

  const getSectionTitle = (section: string): string => {
    const titles: { [key: string]: string } = {
      'Demographics': 'Demografik Bilgiler',
      'EducationWork': 'Eğitim ve İş',
      'Relationship': 'İlişki Durumu',
      'Preferences': 'Tercihler',
      'Goals': 'Hedefler',
      'Challenges': 'Zorluklar',
      'Values': 'Değerler',
      'Support': 'Destek',
      'Romantic': 'Romantik',
      'Consent': 'Onay ve Gizlilik'
    };
    return titles[section] || section;
  };

  const loadItems = async () => {
    console.log('Loading S0 items from:', `${API_URL}/v1/items/by-form?form=S0_profile`);
    try {
      const response = await fetch(`${API_URL}/v1/items/by-form?form=S0_profile`, {
        headers: {
          'x-user-lang': 'tr',
          'x-user-id': 'test-user',
        },
      });
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      console.log('S0 items count:', data.items?.length || 0);
      
      if (data.items && data.items.length > 0) {
        // Sort items by section order
        const sortedItems = data.items.sort((a: ProfileItem, b: ProfileItem) => {
          const aIndex = sectionOrder.indexOf(a.section);
          const bIndex = sectionOrder.indexOf(b.section);
          return aIndex - bIndex;
        });
        setItems(sortedItems);
      } else {
        setItems([]);
      }
    } catch (error) {
      console.error('Error loading S0 items:', error);
      Alert.alert('Hata', `Form yüklenemedi: ${error.message}`);
      setItems([]);
    } finally {
      setLoading(false);
    }
  };

  const loadSavedAnswers = () => {
    try {
      if (Platform.OS === 'web') {
        const saved = localStorage.getItem('S0_profile_answers');
        if (saved) {
          const parsedAnswers = JSON.parse(saved);
          setAnswers(parsedAnswers);
          
          // Eğer kayıtlı cevaplar varsa bilgilendir
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
        localStorage.setItem('S0_profile_answers', JSON.stringify(answers));
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
      localStorage.setItem('S0_profile_answers', JSON.stringify(newAnswers));
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
      // Skip ONLY truly optional questions  
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
      // Has unanswered questions - go to S0Check screen
      setSaving(true);
      saveAnswers();
      navigation.navigate('S0Check');
    } else {
      // All questions answered - go to S1
      setSaving(true);
      saveAnswers();
      navigation.navigate('S1Form');
    }
  };

  const renderInput = (item: ProfileItem, isHighlighted: boolean) => {
    const value = answers[item.id] || '';

    switch (item.type) {
      case 'Number':
        return (
          <TextInput
            style={[
              styles.numberInput,
              isHighlighted && !value && styles.inputHighlighted
            ]}
            value={value.toString()}
            onChangeText={(text) => {
              const num = parseInt(text) || '';
              handleAnswer(item.id, num);
            }}
            keyboardType="numeric"
            placeholder="Sayı giriniz"
            placeholderTextColor="rgb(0,0,0)"
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
                  value === option && styles.choiceButtonSelected,
                  isHighlighted && !value && styles.choiceHighlighted
                ]}
                onPress={() => handleAnswer(item.id, option)}
              >
                <Text
                  style={[
                    styles.choiceText,
                    value === option && styles.choiceTextSelected,
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
                    value === opt && styles.likertOptionSelected,
                    isHighlighted && !value && styles.likertOptionHighlighted
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
                    selectedValues.includes(option) && styles.choiceButtonSelected,
                    isHighlighted && !value && styles.choiceHighlighted
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
                      rank > 0 && styles.choiceButtonSelected,
                      isHighlighted && !value && styles.choiceHighlighted
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
            style={[
              styles.singleLineInput,
              isHighlighted && !value && styles.inputHighlighted
            ]}
            value={value.toString()}
            onChangeText={(text) => handleAnswer(item.id, text)}
            placeholder={item.notes || item.options_tr || 'Cevabınızı yazınız'}
            placeholderTextColor="rgba(0,0,0,0.5)"
            multiline={false}
          />
        );
      
      case 'OpenText':
      default:
        return (
          <TextInput
            style={[
              styles.textInput,
              isHighlighted && !value && styles.inputHighlighted
            ]}
            value={value.toString()}
            onChangeText={(text) => handleAnswer(item.id, text)}
            placeholder={item.notes || item.options_tr || 'Cevabınızı yazınız'}
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
          <Text style={styles.loadingText}>Form yükleniyor...</Text>
        </View>
      </SafeAreaView>
    );
  }

  const itemsToShow = showOnlyUnanswered ? getUnansweredQuestions() : items;
  const progress = getProgress();

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.screenContainer}>
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity 
            onPress={() => navigation.navigate('home')} 
            style={styles.backButtonContainer}
          >
            <Text style={styles.backArrow}>←</Text>
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Hadi Sizi Tanıyalım</Text>
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
              Lütfen size daha iyi koçluk yapabilmemiz için aşağıdaki bilgileri doldurun.
            </Text>
            <Text style={styles.instructionNote}>
              "Opsiyonel" işaretli sorular hariç tüm soruları yanıtlamanız gerekmektedir.
            </Text>
          </View>

          {/* Filter for unanswered */}
          {showOnlyUnanswered && (
            <View style={styles.filterContainer}>
              <Text style={styles.filterText}>
                Sadece eksik sorular gösteriliyor ({getUnansweredQuestions().length})
              </Text>
              <TouchableOpacity
                onPress={() => {
                  setShowOnlyUnanswered(false);
                  setHighlightUnanswered(false);
                }}
                style={styles.filterButton}
              >
                <Text style={styles.filterButtonText}>Tüm Soruları Göster</Text>
              </TouchableOpacity>
            </View>
          )}

          {/* Questions */}
          <View style={styles.questionsContainer}>
            {itemsToShow.map((item, index) => {
              const isUnanswered = !answers[item.id] || answers[item.id] === '';
              
              // Section header
              const showSectionHeader = !showOnlyUnanswered && (
                index === 0 || itemsToShow[index - 1]?.section !== item.section
              );
              
              return (
                <View key={item.id}>
                  {showSectionHeader && (
                    <View style={styles.sectionDivider}>
                      <Text style={styles.sectionDividerText}>
                        {getSectionTitle(item.section)}
                      </Text>
                    </View>
                  )}
                  
                  <View style={[
                    styles.questionContainer,
                    highlightUnanswered && isUnanswered && styles.questionContainerHighlighted
                  ]}>
                    <Text style={[
                      styles.questionText,
                      highlightUnanswered && isUnanswered && styles.questionTextHighlighted
                    ]}>
                      {item.text_tr}
                    </Text>
                    {renderInput(item, highlightUnanswered && isUnanswered)}
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
                {saving ? 'Kaydediliyor...' : 'Devam Et (S1)'}
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
    backgroundColor: '#F8FAFC',
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
    borderBottomColor: '#F1F5F9',
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
    color: '#666',
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
    color: '#64748B',
  },
  progressPercentage: {
    fontSize: 15,
    fontWeight: 'bold',
    color: '#000000',
  },
  progressBarBackground: {
    height: 10,
    backgroundColor: '#E5E7EB',
    borderRadius: 3,
    overflow: 'hidden',
  },
  progressBarFill: {
    height: '100%',
    backgroundColor: '#000000',
    borderRadius: 3,
  },
  
  // Instructions
  instructionsCard: {
    backgroundColor: '#FAFAFA',
    padding: 20,
    borderRadius: 3,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  instructionsTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#374151',
    marginBottom: 12,
  },
  instructionText: {
    fontSize: 14,
    color: '#64748B',
    lineHeight: 20,
  },
  instructionNote: {
    fontSize: 13,
    color: '#DC2626',
    marginTop: 8,
  },
  
  // Filter
  filterContainer: {
    backgroundColor: '#FEF3C7',
    padding: 12,
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
    borderColor: '#E5E7EB',
  },
  questionContainerHighlighted: {
    borderColor: '#EF4444',
    borderWidth: 2,
    backgroundColor: '#FEF2F2',
  },
  questionText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#000000',
    marginBottom: 12,
  },
  questionTextHighlighted: {
    color: '#DC2626',
  },
  questionNote: {
    fontSize: 13,
    color: '#64748B',
    fontStyle: 'italic',
    marginTop: -8,
    marginBottom: 12,
  },
  
  // Section Divider
  sectionDivider: {
    backgroundColor: 'rgb(45, 55, 72)',
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
    borderColor: '#E5E7EB',
    borderRadius: 3,
    padding: 12,
    fontSize: 14,
    minHeight: 80,
    textAlignVertical: 'top',
    backgroundColor: 'rgb(244,244,244)',
    color: 'rgb(0,0,0)',
  },
  singleLineInput: {
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    padding: 12,
    fontSize: 14,
    height: 44,
    backgroundColor: 'rgb(244,244,244)',
    color: 'rgb(0,0,0)',
  },
  numberInput: {
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    padding: 12,
    fontSize: 14,
    width: 150,
    backgroundColor: 'rgb(244,244,244)',
    color: 'rgb(0,0,0)',
  },
  inputHighlighted: {
    borderColor: '#EF4444',
    borderWidth: 2,
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
    borderColor: '#E5E7EB',
    borderRadius: 3,
    backgroundColor: '#FFFFFF',
  },
  choiceButtonSelected: {
    backgroundColor: 'rgb(96, 187, 202)',
    borderColor: 'rgb(96, 187, 202)',
  },
  choiceHighlighted: {
    borderColor: '#EF4444',
    borderWidth: 2,
  },
  choiceText: {
    fontSize: 14,
    color: '#333',
  },
  choiceTextSelected: {
    color: '#FFFFFF',
  },
  multiSelectHelp: {
    fontSize: 12,
    color: '#64748B',
    marginBottom: 8,
    textAlign: 'right',
  },
  rankedHelpText: {
    fontSize: 12,
    color: '#64748B',
    marginBottom: 8,
    fontStyle: 'italic',
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
    color: '#64748B',
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
  likertOptionHighlighted: {
    borderColor: '#EF4444',
    borderWidth: 2,
  },
  likertOptionText: {
    fontSize: 14,
    color: '#1E293B',
  },
  likertOptionTextSelected: {
    color: '#FFFFFF',
  },
  
  // Footer
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
    color: '#1E40AF',
  },
  completedText: {
    fontSize: 14,
    color: '#059669',
    fontWeight: '600',
    marginTop: 8,
  },
  
  // Submit Button
  submitButton: {
    backgroundColor: '#000000',
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