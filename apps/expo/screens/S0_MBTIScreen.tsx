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

import { API_URL } from '../config';

interface MBTIItem {
  id: string;
  text_tr: string;
  type: string;
  section: string;
  subscale: string;
  options_tr?: string;
  notes?: string;
  display_order?: number;
}

interface MBTIAnswers {
  [key: string]: string | number | undefined;
}

export default function S0_MBTIScreen({ navigation }: any) {
  const [items, setItems] = useState<MBTIItem[]>([]);
  const [answers, setAnswers] = useState<MBTIAnswers>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [currentSection, setCurrentSection] = useState('');

  useEffect(() => {
    loadItems();
    loadAnswers();
  }, []);

  const loadItems = async () => {
    try {
      console.log('Loading MBTI items...');
      const response = await fetch(`${API_URL}/v1/items/by-form?form=S0_MBTI`, {
        headers: {
          'x-user-lang': 'tr',
          'x-user-id': 'test-user',
        },
      });
      
      const data = await response.json();
      console.log('Total MBTI items:', data.items?.length);
      
      if (data.items && data.items.length > 0) {
        // Sort by display_order
        const sortedItems = data.items.sort((a: MBTIItem, b: MBTIItem) => 
          (a.display_order || 0) - (b.display_order || 0)
        );
        setItems(sortedItems);
        
        // Set initial section
        const sections = [...new Set(sortedItems.map((item: MBTIItem) => item.subscale))];
        if (sections.length > 0) {
          setCurrentSection(sections[0]);
        }
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
      let saved = null;
      if (Platform.OS === 'web') {
        saved = localStorage.getItem('S0_MBTI_answers');
      } else {
        saved = await AsyncStorage.getItem('S0_MBTI_answers');
      }
      
      if (saved) {
        setAnswers(JSON.parse(saved));
      }
    } catch (error) {
      console.error('Error loading answers:', error);
    }
  };

  const saveAnswers = async () => {
    try {
      const answersString = JSON.stringify(answers);
      if (Platform.OS === 'web') {
        localStorage.setItem('S0_MBTI_answers', answersString);
      } else {
        await AsyncStorage.setItem('S0_MBTI_answers', answersString);
      }
    } catch (error) {
      console.error('Error saving answers:', error);
    }
  };

  const handleAnswer = (itemId: string, value: string) => {
    const newAnswers = { ...answers, [itemId]: value };
    setAnswers(newAnswers);
  };

  const renderItem = (item: MBTIItem) => {
    const currentAnswer = answers[item.id];
    const options = item.options_tr?.split('|') || [];
    
    return (
      <View key={item.id} style={styles.itemContainer}>
        <Text style={styles.questionText}>{item.text_tr}</Text>
        
        <View style={styles.optionsContainer}>
          {options.map((option, index) => {
            const optionKey = `${index}`;
            const isSelected = currentAnswer === optionKey;
            
            return (
              <TouchableOpacity
                key={index}
                style={[
                  styles.optionButton,
                  isSelected && styles.optionButtonSelected
                ]}
                onPress={() => handleAnswer(item.id, optionKey)}
              >
                <Text style={[
                  styles.optionText,
                  isSelected && styles.optionTextSelected
                ]}>
                  {option}
                </Text>
              </TouchableOpacity>
            );
          })}
        </View>
      </View>
    );
  };

  const handleNext = async () => {
    // Check if all questions are answered
    const unansweredItems = items.filter(item => !answers[item.id]);
    
    if (unansweredItems.length > 0) {
      Alert.alert('Uyarı', `Lütfen tüm soruları cevaplayın. ${unansweredItems.length} soru kaldı.`);
      return;
    }
    
    setSaving(true);
    await saveAnswers();
    
    // Navigate to S1Form
    navigation.navigate('S1Form');
    setSaving(false);
  };

  const handleBack = () => {
    navigation.navigate('S0Check');
  };

  const getSectionTitle = (subscale: string) => {
    const titles: { [key: string]: string } = {
      'E_I': 'Bölüm 1: Enerjinizi Nereden Alırsınız?',
      'S_N': 'Bölüm 2: Bilgiyi Nasıl İşlersiniz?',
      'T_F': 'Bölüm 3: Kararlarınızı Nasıl Verirsiniz?',
      'J_P': 'Bölüm 4: Hayata Karşı Yaklaşımınız Nasıldır?'
    };
    return titles[subscale] || subscale;
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.centerContent}>
          <Text style={styles.loadingText}>Yükleniyor...</Text>
        </View>
      </SafeAreaView>
    );
  }

  // Group items by subscale
  const groupedItems: { [key: string]: MBTIItem[] } = {};
  items.forEach(item => {
    if (!groupedItems[item.subscale]) {
      groupedItems[item.subscale] = [];
    }
    groupedItems[item.subscale].push(item);
  });

  return (
    <SafeAreaView style={styles.container}>
      <KeyboardAvoidingView 
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.container}
      >
        <ScrollView contentContainerStyle={styles.scrollContent}>
          <View style={styles.header}>
            <Text style={styles.title}>MBTI Analizi</Text>
            <Text style={styles.subtitle}>Kişilik tipinizi belirlemeye yönelik sorular</Text>
          </View>

          {Object.entries(groupedItems).map(([subscale, sectionItems]) => (
            <View key={subscale}>
              <View style={styles.sectionDivider}>
                <Text style={styles.sectionDividerText}>{getSectionTitle(subscale)}</Text>
              </View>
              {sectionItems.map(item => renderItem(item))}
            </View>
          ))}

          <View style={styles.navigationButtons}>
            <TouchableOpacity
              style={[styles.navButton, styles.backButton]}
              onPress={handleBack}
            >
              <Text style={styles.navButtonText}>Geri</Text>
            </TouchableOpacity>
            
            <TouchableOpacity
              style={[styles.navButton, styles.nextButton]}
              onPress={handleNext}
              disabled={saving}
            >
              <Text style={[styles.navButtonText, styles.nextButtonText]}>
                {saving ? 'Kaydediliyor...' : 'İleri'}
              </Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8F9FA',
  },
  scrollContent: {
    padding: 20,
    paddingBottom: 100,
  },
  centerContent: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  header: {
    marginBottom: 24,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: 'rgb(45, 55, 72)',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#64748B',
  },
  loadingText: {
    fontSize: 18,
    color: '#64748B',
  },
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
  itemContainer: {
    marginBottom: 20,
    backgroundColor: '#FFFFFF',
    padding: 16,
    borderRadius: 3,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 1,
    },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  questionText: {
    fontSize: 16,
    color: 'rgb(0, 0, 0)',
    marginBottom: 12,
    lineHeight: 24,
  },
  optionsContainer: {
    gap: 8,
  },
  optionButton: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 3,
    backgroundColor: '#FFFFFF',
  },
  optionButtonSelected: {
    backgroundColor: 'rgb(96, 187, 202)',
    borderColor: 'rgb(96, 187, 202)',
  },
  optionText: {
    fontSize: 14,
    color: 'rgb(0, 0, 0)',
    lineHeight: 20,
  },
  optionTextSelected: {
    color: '#FFFFFF',
  },
  navigationButtons: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 32,
    gap: 16,
  },
  navButton: {
    flex: 1,
    paddingVertical: 14,
    borderRadius: 3,
    alignItems: 'center',
  },
  backButton: {
    backgroundColor: '#E5E7EB',
  },
  nextButton: {
    backgroundColor: 'rgb(96, 187, 202)',
  },
  navButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'rgb(45, 55, 72)',
  },
  nextButtonText: {
    color: '#FFFFFF',
  },
});