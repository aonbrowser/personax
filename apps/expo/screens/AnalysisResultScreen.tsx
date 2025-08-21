import React from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
} from 'react-native';
import Markdown from 'react-native-markdown-display';

interface AnalysisResultScreenProps {
  navigation: any;
  route: {
    params: {
      result?: {
        markdown?: string;
        analysisId: string;
      };
      markdown?: string;
      analysisType?: string;
    };
  };
}

export default function AnalysisResultScreen({ navigation, route }: AnalysisResultScreenProps) {
  // Support both old format (result.markdown) and new format (direct markdown)
  const markdown = route.params?.result?.markdown || route.params?.markdown;

  if (!markdown) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backButton}>
            <Text style={styles.backArrow}>←</Text>
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Analiz Sonucu</Text>
          <View style={styles.headerSpacer} />
        </View>
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>Analiz sonucu bulunamadı</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backButton}>
          <Text style={styles.backArrow}>←</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Analiz Sonucu</Text>
        <View style={styles.headerSpacer} />
      </View>
      
      <ScrollView style={styles.scrollView} contentContainerStyle={styles.contentContainer}>
        <View style={styles.markdownContainer}>
          <Markdown style={markdownStyles}>
            {markdown}
          </Markdown>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const markdownStyles = StyleSheet.create({
  body: {
    fontSize: 16,
    lineHeight: 32,
    color: '#2D3748',
  },
  heading1: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#1A202C',
    marginVertical: 16,
    lineHeight: 36,
  },
  heading2: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1A202C',
    marginVertical: 14,
    lineHeight: 32,
  },
  heading3: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#2D3748',
    marginVertical: 12,
    lineHeight: 28,
  },
  paragraph: {
    fontSize: 16,
    lineHeight: 32,
    color: '#2D3748',
    marginVertical: 8,
  },
  strong: {
    fontWeight: 'bold',
    color: '#1A202C',
  },
  em: {
    fontStyle: 'italic',
  },
  bullet_list: {
    marginVertical: 8,
  },
  ordered_list: {
    marginVertical: 8,
  },
  list_item: {
    flexDirection: 'row',
    marginVertical: 4,
  },
  bullet_list_icon: {
    fontSize: 16,
    lineHeight: 32,
    marginRight: 8,
  },
  ordered_list_icon: {
    fontSize: 16,
    lineHeight: 32,
    marginRight: 8,
  },
  code_inline: {
    backgroundColor: '#F7FAFC',
    borderColor: '#E2E8F0',
    borderWidth: 1,
    borderRadius: 3,
    paddingHorizontal: 4,
    paddingVertical: 2,
    fontFamily: 'monospace',
    fontSize: 14,
  },
  code_block: {
    backgroundColor: '#F7FAFC',
    borderColor: '#E2E8F0',
    borderWidth: 1,
    borderRadius: 3,
    padding: 12,
    marginVertical: 8,
    fontFamily: 'monospace',
    fontSize: 14,
  },
  blockquote: {
    borderLeftWidth: 4,
    borderLeftColor: '#4299E1',
    paddingLeft: 16,
    marginVertical: 8,
    fontStyle: 'italic',
  },
  hr: {
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
    marginVertical: 16,
  },
  table: {
    borderWidth: 1,
    borderColor: '#E2E8F0',
    marginVertical: 8,
  },
  tr: {
    flexDirection: 'column',
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
  },
  td: {
    padding: 8,
    fontSize: 16,
    lineHeight: 24,
  },
});

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F7FAFC',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
  },
  backButton: {
    padding: 8,
  },
  backArrow: {
    fontSize: 24,
    color: '#2D3748',
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#2D3748',
    flex: 1,
    textAlign: 'center',
  },
  headerSpacer: {
    width: 40,
  },
  scrollView: {
    flex: 1,
  },
  contentContainer: {
    padding: 20,
  },
  markdownContainer: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  errorText: {
    fontSize: 16,
    color: '#718096',
  },
});