import React, { useState, useEffect } from 'react';
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

// Images
const profileImage = require('./assets/images/profile.jpg');
const analysisImage = require('./assets/images/analysis.png');
const newPersonAnalysisImage = require('./assets/images/new-person-analysis.png');

// Screens
import S0ProfileScreen from './screens/S0ProfileScreen';
import S0CheckScreen from './screens/S0CheckScreen';
import S1FormScreen from './screens/S1FormScreen';
import S1CheckScreen from './screens/S1CheckScreen';

export default function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [currentScreen, setCurrentScreen] = useState('home');
  const [email, setEmail] = useState('test@test.com');
  const [password, setPassword] = useState('test123');
  const [isLoading, setIsLoading] = useState(true);

  // Check for existing session on mount
  useEffect(() => {
    checkAuthStatus();
  }, []);

  // Update page title based on current screen
  useEffect(() => {
    if (Platform.OS === 'web') {
      switch(currentScreen) {
        case 'home':
          document.title = 'PersonaX - İlişki Koçunuz';
          break;
        case 'login':
          document.title = 'Giriş Yap - PersonaX';
          break;
        case 's0profile':
          document.title = 'S0 Formu - Hadi Tanışalım';
          break;
        case 's0check':
        case 'S0Check':
          document.title = 'Atladığınız Sorular - PersonaX';
          break;
        case 's1form':
        case 'S1Form':
          document.title = 'S1 Formu - Kişilik Değerlendirmesi';
          break;
        case 's1check':
        case 'S1Check':
          document.title = 'S1 Eksik Sorular - PersonaX';
          break;
        case 's2form':
          document.title = 'S2 Formu - Partner Değerlendirmesi';
          break;
        case 's3form':
          document.title = 'S3 Formu - İlişki Dinamikleri';
          break;
        case 's4form':
          document.title = 'S4 Formu - Koçluk Seansı';
          break;
        default:
          document.title = 'PersonaX';
      }
    }
  }, [currentScreen]);

  const checkAuthStatus = () => {
    if (Platform.OS === 'web') {
      try {
        const authData = localStorage.getItem('relateCoachAuth');
        if (authData) {
          const { expiresAt } = JSON.parse(authData);
          if (new Date().getTime() < expiresAt) {
            setIsAuthenticated(true);
          } else {
            localStorage.removeItem('relateCoachAuth');
          }
        }
      } catch (error) {
        console.error('Error checking auth status:', error);
      }
    }
    setIsLoading(false);
  };

  const saveAuthSession = () => {
    if (Platform.OS === 'web') {
      try {
        const oneYearFromNow = new Date();
        oneYearFromNow.setFullYear(oneYearFromNow.getFullYear() + 1);
        
        const authData = {
          email: email,
          expiresAt: oneYearFromNow.getTime(),
          timestamp: new Date().getTime()
        };
        
        localStorage.setItem('relateCoachAuth', JSON.stringify(authData));
      } catch (error) {
        console.error('Error saving auth session:', error);
      }
    }
  };

  const handleEmailSignIn = () => {
    if (email === 'test@test.com' && password === 'test123') {
      setIsAuthenticated(true);
      saveAuthSession();
    } else {
      Alert.alert('Invalid Credentials', 'Please use test@test.com / test123 for demo');
    }
  };

  const handleLogout = () => {
    setIsAuthenticated(false);
    setCurrentScreen('home');
    if (Platform.OS === 'web') {
      localStorage.removeItem('relateCoachAuth');
    }
  };

  const handleAppleSignIn = () => {
    Alert.alert('Demo Mode', 'Apple Sign In - Demo mode only');
  };

  const handleGoogleSignIn = () => {
    Alert.alert('Demo Mode', 'Google Sign In - Demo mode only');
  };

  const handleNewPersonAnalysis = () => {
    setCurrentScreen('s2form');
  };
  
  const handleSelfAnalysis = () => {
    // Her zaman S0'dan başla, önceki cevaplar hatırlanacak
    setCurrentScreen('s0profile');
  };
  
  const handleRelationshipAnalysis = () => {
    setCurrentScreen('s4form');
  };

  // S2 Form Screen Components
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
    const labels = ['-2', '-1', '0', '+1', '+2'];
    
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
        <View style={styles.likertOptions}>
          {labels.map((label: string, idx: number) => (
            <TouchableOpacity 
              key={idx} 
              onPress={() => onChange(idx + 1)} 
              style={[
                styles.likertOption,
                value === idx + 1 && styles.likertOptionSelected,
                isHighlighted && !value && styles.likertOptionHighlighted
              ]}
            >
              <Text style={[
                styles.likertOptionText,
                value === idx + 1 && styles.likertOptionTextSelected
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
          {opts.map((opt: string, idx: number) => (
            <TouchableOpacity 
              key={idx} 
              onPress={() => onChange(String.fromCharCode(65 + idx))} 
              style={[
                styles.multiOption,
                value === String.fromCharCode(65 + idx) && styles.multiOptionSelected
              ]}
            >
              <Text style={[
                styles.multiOptionText,
                value === String.fromCharCode(65 + idx) && styles.multiOptionTextSelected
              ]}>{opt}</Text>
            </TouchableOpacity>
          ))}
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

  // S2 Form Screen (Other Person Analysis)
  const S2FormScreen = () => {
    const [relation, setRelation] = useState<any>(null);
    const [personName, setPersonName] = useState<string>('');
    const [items, setItems] = useState<any[]>([]);
    const [answers, setAnswers] = useState<any>({});
    const [isLoading, setIsLoading] = useState(false);
    const [showNameInput, setShowNameInput] = useState(false);
    
    useEffect(() => {
      if (relation?.key && personName) {
        setIsLoading(true);
        setAnswers({}); // Reset answers when relation changes
        fetch(`http://localhost:8080/v1/items/by-form?form=S2R_${relation.key}`)
          .then(r => r.json())
          .then(data => {
            setItems(data.items || []);
            setIsLoading(false);
          })
          .catch(err => {
            console.error('Error loading form:', err);
            setIsLoading(false);
            Alert.alert('Hata', 'Form yüklenirken bir hata oluştu');
          });
      }
    }, [relation?.key, personName]);
    
    const handleRelationSelect = (rel: any) => {
      setRelation(rel);
      setShowNameInput(true);
    };
    
    const handleNameSubmit = () => {
      if (!personName.trim()) {
        Alert.alert('Uyarı', 'Lütfen kişinin adını girin');
        return;
      }
      setShowNameInput(false);
    };
    
    const setAnswer = (id: string, val: any) => {
      setAnswers((prev: any) => ({ ...prev, [id]: val }));
    };
    
    const getProgress = () => {
      const answered = Object.keys(answers).length;
      const total = items.length;
      return { answered, total, percentage: total > 0 ? Math.round((answered / total) * 100) : 0 };
    };
    
    const getRelationEmoji = (key: string) => {
      const emojis: any = {
        'mother': '👩',
        'father': '👨',
        'sibling': '👥',
        'relative': '👨‍👩‍👧‍👦',
        'best_friend': '💛',
        'friend': '🤝',
        'roommate': '🏠',
        'neighbor': '🏘️',
        'crush': '💕',
        'date': '💗',
        'partner': '❤️',
        'fiance': '💍',
        'spouse': '💑',
        'coworker': '💼',
        'manager': '👔',
        'direct_report': '👥',
        'client': '🤝',
        'vendor': '📦',
        'mentor': '🎓',
        'mentee': '📚'
      };
      return emojis[key] || '👤';
    };
    
    const handleSubmit = () => {
      const progress = getProgress();
      
      if (progress.answered === 0) {
        Alert.alert('Uyarı', 'Lütfen en az bir soruyu yanıtlayın');
        return;
      }
      
      if (progress.answered < progress.total) {
        Alert.alert(
          'Eksik Yanıtlar',
          `${progress.total} sorudan ${progress.answered} tanesi yanıtlandı. Eksik soruları tamamlamak ister misiniz?`,
          [
            {
              text: 'Devam Et',
              style: 'cancel'
            },
            {
              text: 'Yine de Gönder',
              onPress: () => submitForm()
            }
          ]
        );
      } else {
        submitForm();
      }
    };
    
    const submitForm = () => {
      const progress = getProgress();
      // TODO: API'ye gönder
      // fetch('/v1/analyze/other', { method: 'POST', body: JSON.stringify({ 
      //   answers, 
      //   relation: relation.key,
      //   personName 
      // }) })
      
      Alert.alert(
        'Analiz Tamamlandı', 
        `${personName} için ${relation.label} analiziniz tamamlandı.\n\n${progress.answered} yanıt başarıyla kaydedildi.`,
        [
          {
            text: 'Tamam',
            onPress: () => {
              setCurrentScreen('home');
              setRelation(null);
              setPersonName('');
              setItems([]);
              setAnswers({});
            }
          }
        ]
      );
    };
    
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.screenContainer}>
          {/* Header */}
          <View style={styles.header}>
            <TouchableOpacity 
              onPress={() => setCurrentScreen('people')} 
              style={styles.backButtonContainer}
            >
              <Text style={styles.backArrow}>←</Text>
            </TouchableOpacity>
            <Text style={styles.headerTitle}>Yeni Kişi Analizi</Text>
            <View style={styles.headerSpacer} />
          </View>

          {!relation ? (
            <View style={styles.relationPickerContainer}>
              <Text style={styles.relationPickerTitle}>İlişki Türünü Seçin:</Text>
              <Text style={styles.relationPickerSubtitle}>
                Analiz edeceğiniz kişi sizin için kim?
              </Text>
              <ScrollView style={styles.relationPickerScroll} showsVerticalScrollIndicator={false}>
                {[
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
                ].map(o => (
                  <TouchableOpacity 
                    key={o.key} 
                    onPress={() => handleRelationSelect(o)} 
                    style={[
                      styles.relationOption,
                      relation?.key === o.key && styles.relationOptionSelected
                    ]}
                  >
                    <View style={styles.relationOptionContent}>
                      <Text style={styles.relationEmoji}>{getRelationEmoji(o.key)}</Text>
                      <Text style={[
                        styles.relationOptionText,
                        relation?.key === o.key && styles.relationOptionTextSelected
                      ]}>{o.label}</Text>
                    </View>
                  </TouchableOpacity>
                ))}
              </ScrollView>
            </View>
          ) : showNameInput ? (
            <View style={styles.nameInputContainer}>
              <View style={styles.nameInputHeader}>
                <Text style={styles.nameInputEmoji}>{getRelationEmoji(relation.key)}</Text>
                <Text style={styles.nameInputTitle}>{relation.label}</Text>
              </View>
              <Text style={styles.nameInputLabel}>Bu kişinin adı nedir?</Text>
              <TextInput
                style={styles.nameInput}
                placeholder="Örn: Ahmet, Ayşe..."
                value={personName}
                onChangeText={setPersonName}
                autoFocus
                onSubmitEditing={handleNameSubmit}
              />
              <View style={styles.nameInputButtons}>
                <TouchableOpacity 
                  style={styles.nameInputButtonSecondary}
                  onPress={() => {
                    setRelation(null);
                    setPersonName('');
                    setShowNameInput(false);
                  }}
                >
                  <Text style={styles.nameInputButtonSecondaryText}>Geri</Text>
                </TouchableOpacity>
                <TouchableOpacity 
                  style={styles.nameInputButton}
                  onPress={handleNameSubmit}
                >
                  <Text style={styles.nameInputButtonText}>Devam Et</Text>
                </TouchableOpacity>
              </View>
            </View>
          ) : (
            <ScrollView 
              showsVerticalScrollIndicator={false} 
              style={styles.content}
              contentContainerStyle={styles.formContentContainer}
            >
              {/* Person Info Card */}
              <View style={styles.personInfoCard}>
                <View style={styles.personInfoHeader}>
                  <Text style={styles.personInfoEmoji}>{getRelationEmoji(relation.key)}</Text>
                  <View style={styles.personInfoDetails}>
                    <Text style={styles.personInfoName}>{personName}</Text>
                    <Text style={styles.personInfoRelation}>{relation.label}</Text>
                  </View>
                  <TouchableOpacity 
                    onPress={() => {
                      setRelation(null);
                      setPersonName('');
                      setItems([]);
                      setAnswers({});
                      setShowNameInput(false);
                    }}
                    style={styles.changeButton}
                  >
                    <Text style={styles.changeButtonText}>Değiştir</Text>
                  </TouchableOpacity>
                </View>
              </View>

              {/* Progress Bar */}
              {items.length > 0 && (
                <View style={styles.progressContainer}>
                  <View style={styles.progressHeader}>
                    <Text style={styles.progressText}>
                      İlerleme: {getProgress().answered} / {getProgress().total}
                    </Text>
                    <Text style={styles.progressPercentage}>
                      %{getProgress().percentage}
                    </Text>
                  </View>
                  <View style={styles.progressBarBackground}>
                    <View 
                      style={[
                        styles.progressBarFill,
                        { width: `${getProgress().percentage}%` }
                      ]} 
                    />
                  </View>
                </View>
              )}
              
              {isLoading ? (
                <View style={styles.loadingContainer}>
                  <Text style={styles.loadingText}>Form yükleniyor...</Text>
                </View>
              ) : items.length === 0 ? (
                <View style={styles.emptyState}>
                  <Text style={styles.emptyIcon}>📋</Text>
                  <Text style={styles.emptyTitle}>Form bulunamadı</Text>
                  <Text style={styles.emptyDescription}>
                    Bu ilişki türü için henüz soru eklenmemiş
                  </Text>
                </View>
              ) : (
                <>
                  <View style={styles.questionsContainer}>
                    {items.map((item: any, index: number) => {
                      // Replace [AD] with person's name
                      const modifiedItem = {
                        ...item,
                        text_tr: item.text_tr?.replace('[AD]', personName)
                      };
                      
                      return (
                        <View key={item.id}>
                          {item.type === 'MultiChoice5' ? (
                            <MultiRow 
                              item={modifiedItem} 
                              value={answers[item.id]} 
                              onChange={(v: any) => setAnswer(item.id, v)} 
                            />
                          ) : (
                            <LikertRow 
                              item={modifiedItem} 
                              value={answers[item.id]} 
                              onChange={(v: any) => setAnswer(item.id, v)} 
                            />
                          )}
                        </View>
                      );
                    })}
                  </View>
                  
                  <View style={styles.formFooter}>
                    <View style={styles.summaryCard}>
                      <Text style={styles.summaryTitle}>Özet</Text>
                      <Text style={styles.summaryText}>
                        {personName} için {getProgress().answered}/{getProgress().total} soru yanıtlandı
                      </Text>
                      {getProgress().answered === getProgress().total && (
                        <Text style={styles.completedText}>Tüm sorular tamamlandı!</Text>
                      )}
                    </View>
                    
                    <TouchableOpacity 
                      style={[
                        styles.submitButton,
                        getProgress().answered === 0 && styles.submitButtonDisabled
                      ]} 
                      onPress={handleSubmit}
                    >
                      <Text style={styles.submitButtonText}>
                        {getProgress().answered === getProgress().total ? 'Analizi Tamamla' : 'Gönder'}
                      </Text>
                    </TouchableOpacity>
                  </View>
                </>
              )}
            </ScrollView>
          )}
        </View>
      </SafeAreaView>
    );
  };

  // S1 Form Screen - moved to separate file: screens/S1FormScreen.tsx
  // S1 Check Screen - moved to separate file: screens/S1CheckScreen.tsx

  // S3 Form Screen (Type Check)
  const S3FormScreen = () => {
    const [items, setItems] = useState<any[]>([]);
    const [answers, setAnswers] = useState<any>({});
    const [isLoading, setIsLoading] = useState(false);
    
    useEffect(() => {
      setIsLoading(true);
      fetch('http://localhost:8080/v1/items/by-form?form=S3_self')
        .then(r => r.json())
        .then(data => {
          setItems(data.items || []);
          setIsLoading(false);
        })
        .catch(err => {
          console.error('Error loading S3 form:', err);
          setIsLoading(false);
          Alert.alert('Hata', 'Form yüklenirken bir hata oluştu');
        });
    }, []);
    
    const setAnswer = (id: string, val: any) => {
      setAnswers((prev: any) => ({ ...prev, [id]: val }));
    };
    
    const handleSubmit = () => {
      const answeredCount = Object.keys(answers).length;
      if (answeredCount < items.length) {
        Alert.alert('Uyarı', `Lütfen tüm soruları yanıtlayın (${answeredCount}/${items.length})`);
        return;
      }
      // S3 tamamlandı, S4 seçeneği sun
      Alert.alert(
        '📊 Değerler & Sınırlar',
        'İlişki dinamiklerinizi daha iyi anlamak için değerler ve sınırlar testini yapmak ister misiniz?',
        [
          {
            text: 'Hayır, Bitir',
            onPress: () => {
              Alert.alert('✅ Tamamlandı', 'Analiziniz başarıyla kaydedildi.');
              setCurrentScreen('home');
            },
            style: 'cancel'
          },
          {
            text: 'Evet',
            onPress: () => setCurrentScreen('s4form')
          }
        ]
      );
    };
    
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.screenContainer}>
          <View style={styles.header}>
            <TouchableOpacity 
              onPress={() => setCurrentScreen('home')} 
              style={styles.backButtonContainer}
            >
              <Text style={styles.backArrow}>←</Text>
            </TouchableOpacity>
            <Text style={styles.headerTitle}>Tip Doğrulama (S3)</Text>
            <View style={styles.headerSpacer} />
          </View>

          <ScrollView 
            showsVerticalScrollIndicator={false} 
            style={styles.content}
            contentContainerStyle={styles.formContentContainer}
          >
            <View style={styles.infoCard}>
              <Text style={styles.infoText}>
                Aşağıdaki seçeneklerden size daha yakın olanı seçin
              </Text>
            </View>
            
            {isLoading ? (
              <View style={styles.loadingContainer}>
                <Text style={styles.loadingText}>Form yükleniyor...</Text>
              </View>
            ) : items.length === 0 ? (
              <View style={styles.emptyState}>
                <Text style={styles.emptyIcon}>📋</Text>
                <Text style={styles.emptyTitle}>Form bulunamadı</Text>
              </View>
            ) : (
              <>
                {items.map((item: any) => (
                  <ForcedRow 
                    key={item.id} 
                    item={item} 
                    value={answers[item.id]} 
                    onChange={(v: any) => setAnswer(item.id, v)} 
                  />
                ))}
                
                <TouchableOpacity 
                  style={styles.submitButton} 
                  onPress={handleSubmit}
                >
                  <Text style={styles.submitButtonText}>Gönder</Text>
                </TouchableOpacity>
              </>
            )}
          </ScrollView>
        </View>
      </SafeAreaView>
    );
  };

  // S4 Form Screen (Values & Boundaries)
  const S4FormScreen = () => {
    const [domain, setDomain] = useState<string>('S4_romantic');
    const [items, setItems] = useState<any[]>([]);
    const [answers, setAnswers] = useState<any>({});
    const [isLoading, setIsLoading] = useState(false);
    
    useEffect(() => {
      setIsLoading(true);
      setAnswers({});
      fetch(`http://localhost:8080/v1/items/by-form?form=${domain}`)
        .then(r => r.json())
        .then(data => {
          setItems(data.items || []);
          setIsLoading(false);
        })
        .catch(err => {
          console.error('Error loading S4 form:', err);
          setIsLoading(false);
          Alert.alert('Hata', 'Form yüklenirken bir hata oluştu');
        });
    }, [domain]);
    
    const setAnswer = (id: string, val: any) => {
      setAnswers((prev: any) => ({ ...prev, [id]: val }));
    };
    
    const handleSubmit = () => {
      const answeredCount = Object.keys(answers).length;
      if (answeredCount === 0) {
        Alert.alert('Uyarı', 'Lütfen en az bir soruyu yanıtlayın');
        return;
      }
      // S4 tamamlandı, analiz bitti
      Alert.alert(
        '✅ Tüm Analizler Tamamlandı', 
        'Kişilik analiziniz ve değerler/sınırlar testiniz başarıyla kaydedildi.',
        [
          {
            text: 'Ana Sayfaya Dön',
            onPress: () => {
              setCurrentScreen('home');
            }
          }
        ]
      );
    };
    
    const domainLabels = {
      'S4_family': 'Aile',
      'S4_friend': 'Arkadaş',
      'S4_work': 'İş',
      'S4_romantic': 'Romantik'
    };
    
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.screenContainer}>
          <View style={styles.header}>
            <TouchableOpacity 
              onPress={() => setCurrentScreen('home')} 
              style={styles.backButtonContainer}
            >
              <Text style={styles.backArrow}>←</Text>
            </TouchableOpacity>
            <Text style={styles.headerTitle}>Değerler & Sınırlar (S4)</Text>
            <View style={styles.headerSpacer} />
          </View>

          <ScrollView 
            showsVerticalScrollIndicator={false} 
            style={styles.content}
            contentContainerStyle={styles.formContentContainer}
          >
            <View style={styles.domainTabs}>
              {Object.entries(domainLabels).map(([key, label]) => (
                <TouchableOpacity 
                  key={key} 
                  onPress={() => setDomain(key)} 
                  style={[
                    styles.domainTab,
                    domain === key && styles.domainTabActive
                  ]}
                >
                  <Text style={[
                    styles.domainTabText,
                    domain === key && styles.domainTabTextActive
                  ]}>{label}</Text>
                </TouchableOpacity>
              ))}
            </View>
            
            {isLoading ? (
              <View style={styles.loadingContainer}>
                <Text style={styles.loadingText}>Form yükleniyor...</Text>
              </View>
            ) : items.length === 0 ? (
              <View style={styles.emptyState}>
                <Text style={styles.emptyIcon}>📋</Text>
                <Text style={styles.emptyTitle}>Form bulunamadı</Text>
              </View>
            ) : (
              <>
                {items.map((item: any) => (
                  <LikertRow 
                    key={item.id} 
                    item={item} 
                    value={answers[item.id]} 
                    onChange={(v: any) => setAnswer(item.id, v)} 
                  />
                ))}
                
                <TouchableOpacity 
                  style={styles.submitButton} 
                  onPress={handleSubmit}
                >
                  <Text style={styles.submitButtonText}>Gönder</Text>
                </TouchableOpacity>
              </>
            )}
          </ScrollView>
        </View>
      </SafeAreaView>
    );
  };

  // People Screen
  const PeopleScreen = () => (
    <SafeAreaView style={styles.container}>
      <View style={styles.screenContainer}>
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity onPress={() => setCurrentScreen('home')} style={styles.backButtonContainer}>
            <Text style={styles.backArrow}>←</Text>
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Karakter Analizleri</Text>
          <View style={styles.headerSpacer} />
        </View>

        <ScrollView showsVerticalScrollIndicator={false} style={styles.content}>
          {/* Action Buttons */}
          <View style={styles.actionButtonsContainer}>
            <TouchableOpacity 
              style={[styles.actionButton, styles.primaryActionButton]}
              onPress={handleSelfAnalysis}
            >
              <Image source={profileImage} style={styles.actionButtonIconImage} />
              <View style={styles.actionButtonContent}>
                <Text style={styles.primaryActionButtonTitle}>Kendi Analizim</Text>
                <Text style={styles.primaryActionButtonDescription}>60 soruluk kişilik testi</Text>
              </View>
            </TouchableOpacity>
            
            <TouchableOpacity 
              style={styles.actionButton}
              onPress={handleNewPersonAnalysis}
            >
              <Image source={newPersonAnalysisImage} style={styles.actionButtonIconImage} />
              <View style={styles.actionButtonContent}>
                <Text style={styles.actionButtonTitle}>Yeni Analiz</Text>
                <Text style={styles.actionButtonDescription}>Tanıdığınız birini analiz edin</Text>
              </View>
            </TouchableOpacity>
          </View>

          {/* People List */}
          <View style={styles.sectionContainer}>
            <Text style={styles.sectionTitle}>Kayıtlı Kişiler</Text>
            <View style={styles.emptyState}>
              <Text style={styles.emptyIcon}>📋</Text>
              <Text style={styles.emptyTitle}>Henüz kişi eklenmemiş</Text>
              <Text style={styles.emptyDescription}>
                Yeni kişi ekleyerek analizlere başlayabilirsiniz
              </Text>
            </View>
          </View>
        </ScrollView>
      </View>
    </SafeAreaView>
  );

  // Reports Screen
  const ReportsScreen = () => (
    <SafeAreaView style={styles.container}>
      <View style={styles.screenContainer}>
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity onPress={() => setCurrentScreen('home')} style={styles.backButtonContainer}>
            <Text style={styles.backArrow}>←</Text>
          </TouchableOpacity>
          <Text style={styles.headerTitle}>İlişki Analizleri</Text>
          <View style={styles.headerSpacer} />
        </View>

        <ScrollView showsVerticalScrollIndicator={false} style={styles.content}>
          <TouchableOpacity 
            style={[styles.actionCard, styles.primaryCard, styles.fullWidthCard]}
            onPress={handleRelationshipAnalysis}
          >
            <View style={styles.cardIcon}>
              <Text style={styles.iconText}>💞</Text>
            </View>
            <Text style={styles.primaryCardTitle}>İlişki Değerleri & Sınırları</Text>
            <Text style={styles.primaryCardDescription}>
              İlişkinizdeki değerleri ve sınırları belirleyin
            </Text>
          </TouchableOpacity>
          
          <View style={styles.emptyState}>
            <Text style={styles.emptyIcon}></Text>
            <Text style={styles.emptyTitle}>Henüz analiz yok</Text>
            <Text style={styles.emptyDescription}>
              İlk ilişki analizinizi başlatın
            </Text>
          </View>
        </ScrollView>
      </View>
    </SafeAreaView>
  );

  // Show loading screen while checking auth
  if (isLoading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.loadingContainer}>
          <Text style={styles.logoLarge}>🧠</Text>
          <Text style={styles.appName}>My Life Coach</Text>
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
    
    if (currentScreen === 's0profile') {
      return <S0ProfileScreen navigation={{ 
        navigate: (screen: string) => setCurrentScreen(screen),
        goBack: () => setCurrentScreen('home')
      }} />;
    }
    
    if (currentScreen === 's0check' || currentScreen === 'S0Check') {
      return <S0CheckScreen navigation={{ 
        navigate: (screen: string) => setCurrentScreen(screen),
        goBack: () => setCurrentScreen('s0profile')
      }} />;
    }
    
    if (currentScreen === 's1form' || currentScreen === 'S1Form') {
      return <S1FormScreen navigation={{ 
        navigate: setCurrentScreen,
        goBack: () => setCurrentScreen('s0check')
      }} />;
    }
    
    if (currentScreen === 's1check' || currentScreen === 'S1Check') {
      return <S1CheckScreen navigation={{ 
        navigate: setCurrentScreen,
        goBack: () => setCurrentScreen('S1Form')
      }} />;
    }
    
    if (currentScreen === 's2form') {
      return <S2FormScreen />;
    }
    
    if (currentScreen === 's3form') {
      return <S3FormScreen />;
    }
    
    if (currentScreen === 's4form') {
      return <S4FormScreen />;
    }
    
    // Home Screen
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.screenContainer}>
          {/* Header with Profile */}
          <View style={styles.homeHeader}>
            <View>
              <Text style={styles.welcomeText}>Hoş geldiniz</Text>
              <Text style={styles.homeTitle}>My Life Coach</Text>
            </View>
            <TouchableOpacity style={styles.profileButton} onPress={handleLogout}>
              <Image source={profileImage} style={styles.profileImage} />
            </TouchableOpacity>
          </View>

          <ScrollView showsVerticalScrollIndicator={false} style={styles.content}>
            {/* Quick Stats */}
            <View style={styles.statsContainer}>
              <View style={styles.statCard}>
                <Text style={styles.statNumber}>0</Text>
                <Text style={styles.statLabel}>Analizler</Text>
              </View>
              <View style={styles.statCard}>
                <Text style={styles.statNumber}>0</Text>
                <Text style={styles.statLabel}>Kişiler</Text>
              </View>
              <View style={styles.statCard}>
                <Text style={styles.statNumber}>0</Text>
                <Text style={styles.statLabel}>İlişkiler</Text>
              </View>
            </View>

            {/* Profile Edit Button - Only show if S0 completed */}
            {Platform.OS === 'web' && (() => {
              try {
                return localStorage.getItem('S0_profile_answers') !== null;
              } catch {
                return false;
              }
            })() && (
              <TouchableOpacity 
                style={styles.editProfileButton}
                onPress={() => setCurrentScreen('s0profile')}
              >
                <Text style={styles.editProfileButtonText}>🖊️ Profili Düzenle</Text>
              </TouchableOpacity>
            )}

            {/* Main Actions */}
            <View style={styles.sectionContainer}>
              <Text style={styles.sectionTitle}>Karakter Analizleri</Text>
              <View style={styles.menuGrid}>
                <TouchableOpacity 
                  style={styles.menuCard}
                  onPress={handleSelfAnalysis}
                >
                  <Image source={profileImage} style={styles.menuIconImage} />
                  <Text style={styles.menuTitle}>Kendi Analizim</Text>
                </TouchableOpacity>
                
                <TouchableOpacity 
                  style={styles.menuCard}
                  onPress={handleNewPersonAnalysis}
                >
                  <Image source={newPersonAnalysisImage} style={styles.menuIconImage} />
                  <Text style={styles.menuTitle}>Yeni Kişi Analizi</Text>
                </TouchableOpacity>
                
                <TouchableOpacity 
                  style={styles.menuCard}
                  onPress={() => setCurrentScreen('people')}
                >
                  <Image source={analysisImage} style={styles.menuIconImage} />
                  <Text style={styles.menuTitle}>Tüm Analizler</Text>
                </TouchableOpacity>
              </View>
            </View>

            <View style={styles.sectionContainer}>
              <Text style={styles.sectionTitle}>İlişkilerim</Text>
              <TouchableOpacity 
                style={[styles.actionCard, styles.secondaryCard]}
                onPress={() => setCurrentScreen('reports')}
              >
                <View style={styles.cardContent}>
                  <View>
                    <Text style={styles.secondaryCardTitle}>İlişki Analizi Başlat</Text>
                    <Text style={styles.cardDescription}>
                      Kişiler arası dinamikleri keşfedin
                    </Text>
                  </View>
                  <Text style={styles.cardArrow}>→</Text>
                </View>
              </TouchableOpacity>
            </View>
            
            <View style={styles.sectionContainer}>
              <TouchableOpacity 
                style={styles.menuCard}
                onPress={() => setCurrentScreen('s3form')}
              >
                <Text style={styles.menuIcon}></Text>
                <Text style={styles.menuTitle}>Tip Doğrulama</Text>
              </TouchableOpacity>
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
                style={styles.socialButton}
                onPress={handleGoogleSignIn}
              >
                <Text style={styles.socialIcon}>G</Text>
                <Text style={styles.socialButtonText}>Google ile devam et</Text>
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

            <Text style={styles.demoNotice}>
              Demo: test@test.com / test123
            </Text>
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
    paddingTop: 24,
    paddingBottom: 20,
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
  profileButton: {
    width: 48,
    height: 48,
    borderRadius: 3,
    backgroundColor: '#F1F5F9',
    justifyContent: 'center',
    alignItems: 'center',
  },
  profileIcon: {
    fontSize: 24,
  },
  profileImage: {
    width: 40,
    height: 40,
    borderRadius: 3,
  },

  // Content
  content: {
    flex: 1,
    backgroundColor: '#F8FAFC',
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
    backgroundColor: '#FFFFFF',
    padding: 16,
    borderRadius: 3,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  questionText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#000000',  // Siyah
    marginBottom: 20,
    lineHeight: 24,
  },
  likertOptions: {
    flexDirection: 'row',
    gap: 8,
    justifyContent: 'space-between',
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
    backgroundColor: '#000000',  // Siyah arka plan
    borderColor: '#000000',
  },
  likertOptionText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#64748B',
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
    backgroundColor: '#000000',  // Siyah
    borderColor: '#000000',
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
    backgroundColor: '#000000',  // Siyah
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
    backgroundColor: '#000000',  // Siyah
    borderColor: '#000000',
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
    color: '#64748B',
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
    backgroundColor: '#000000',  // Siyah
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
    backgroundColor: '#000000',  // Siyah arka plan
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