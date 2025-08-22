import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  StyleSheet,
} from 'react-native';

interface Value {
  key: string;
  label: string;
  desc: string;
}

interface DraggableRankingProps {
  values: Value[];
  currentRanking: string[];
  onRankingChange: (newRanking: string[]) => void;
}

// Native version - tap to add, hold to insert at position
export default function DraggableRanking({ values, currentRanking, onRankingChange }: DraggableRankingProps) {
  const [selectedItem, setSelectedItem] = useState<string | null>(null);
  const [insertIndex, setInsertIndex] = useState<number | null>(null);
  
  const remainingValues = values.filter(v => !currentRanking.includes(v.key));
  
  const handleAddValue = (valueKey: string) => {
    if (insertIndex !== null) {
      // Insert at specific position
      const newRanking = [...currentRanking];
      newRanking.splice(insertIndex, 0, valueKey);
      if (newRanking.length > 10) {
        newRanking.pop();
      }
      onRankingChange(newRanking);
      setInsertIndex(null);
    } else {
      // Add to end
      const newRanking = [...currentRanking, valueKey];
      if (newRanking.length <= 10) {
        onRankingChange(newRanking);
      }
    }
    setSelectedItem(null);
  };
  
  const handleRemoveValue = (valueKey: string) => {
    const newRanking = currentRanking.filter(key => key !== valueKey);
    onRankingChange(newRanking);
  };
  
  const handleSlotPress = (index: number) => {
    if (selectedItem) {
      // If an item is selected, insert it at this position
      const newRanking = [...currentRanking];
      newRanking.splice(index, 0, selectedItem);
      if (newRanking.length > 10) {
        newRanking.pop();
      }
      onRankingChange(newRanking);
      setSelectedItem(null);
      setInsertIndex(null);
    } else if (!currentRanking[index]) {
      // If slot is empty, prepare for insertion
      setInsertIndex(index);
    }
  };
  
  const handleValueSelect = (valueKey: string) => {
    if (selectedItem === valueKey) {
      // Deselect if already selected
      setSelectedItem(null);
      setInsertIndex(null);
    } else {
      // Select for insertion
      setSelectedItem(valueKey);
      setInsertIndex(null);
    }
  };
  
  return (
    <View style={styles.container}>
      {/* Instructions */}
      <View style={styles.instructions}>
        <Text style={styles.instructionText}>
          💡 Sol taraftan bir değer seçin, ardından sağ tarafta yerleştirmek istediğiniz pozisyona dokunun.
        </Text>
      </View>
      
      <View style={styles.columns}>
        {/* Left Column - Available Values */}
        <View style={styles.leftColumn}>
          <Text style={styles.columnTitle}>Seçenekler</Text>
          <View style={styles.valuesContainer}>
            {remainingValues.map((val) => (
              <TouchableOpacity
                key={val.key}
                style={[
                  styles.valueButton,
                  selectedItem === val.key && styles.valueButtonSelected
                ]}
                onPress={() => handleValueSelect(val.key)}
              >
                <Text style={[
                  styles.valueLabel,
                  selectedItem === val.key && styles.valueLabelSelected
                ]}>
                  {val.label}
                </Text>
              </TouchableOpacity>
            ))}
            {remainingValues.length === 0 && (
              <Text style={styles.emptyMessage}>
                Tüm değerler sıralandı
              </Text>
            )}
          </View>
        </View>
        
        {/* Right Column - Ranked Values */}
        <View style={styles.rightColumn}>
          <Text style={styles.columnTitle}>Sıralama (1 = En Önemli)</Text>
          <ScrollView style={styles.slotsContainer}>
            {[...Array(10)].map((_, index) => {
              const valueKey = currentRanking[index];
              const valueData = valueKey ? values.find(v => v.key === valueKey) : null;
              const showInsertIndicator = selectedItem && (insertIndex === index || (!valueData && !insertIndex));
              
              return (
                <View key={index}>
                  {showInsertIndicator && !valueData && (
                    <View style={styles.insertIndicator}>
                      <Text style={styles.insertIndicatorText}>
                        {values.find(v => v.key === selectedItem)?.label} buraya eklenecek
                      </Text>
                    </View>
                  )}
                  <TouchableOpacity
                    style={styles.slot}
                    onPress={() => handleSlotPress(index)}
                    activeOpacity={0.7}
                  >
                    <Text style={styles.slotNumber}>{index + 1}.</Text>
                    {valueData ? (
                      <TouchableOpacity
                        style={styles.slotContent}
                        onLongPress={() => handleRemoveValue(valueKey)}
                        activeOpacity={0.8}
                      >
                        <Text style={styles.slotLabel}>{valueData.label}</Text>
                      </TouchableOpacity>
                    ) : (
                      <View style={styles.emptySlot}>
                        <Text style={styles.emptySlotText}>Boş</Text>
                      </View>
                    )}
                  </TouchableOpacity>
                </View>
              );
            })}
          </ScrollView>
        </View>
      </View>
      
      {/* Value Descriptions */}
      <View style={styles.descriptions}>
        <Text style={styles.descTitle}>Değer Açıklamaları:</Text>
        {values.map((val) => (
          <Text key={val.key} style={styles.descItem}>
            <Text style={styles.descBold}>{val.label}:</Text> {val.desc}
          </Text>
        ))}
      </View>
      
      {/* Selected Item Info */}
      {selectedItem && (
        <View style={styles.selectedInfo}>
          <Text style={styles.selectedInfoText}>
            Seçili: {values.find(v => v.key === selectedItem)?.label}
          </Text>
          <TouchableOpacity
            style={styles.cancelButton}
            onPress={() => {
              setSelectedItem(null);
              setInsertIndex(null);
            }}
          >
            <Text style={styles.cancelButtonText}>İptal</Text>
          </TouchableOpacity>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: 16,
  },
  instructions: {
    backgroundColor: '#eff6ff',
    padding: 12,
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#bfdbfe',
  },
  instructionText: {
    fontSize: 13,
    color: '#1e40af',
    lineHeight: 20,
  },
  columns: {
    flexDirection: 'column',
    gap: 16,
  },
  leftColumn: {
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    padding: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  rightColumn: {
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    padding: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  columnTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: 'rgb(45, 55, 72)',
    marginBottom: 12,
    textAlign: 'center',
  },
  valuesContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  valueButton: {
    backgroundColor: 'rgb(96, 187, 202)',
    paddingVertical: 10,
    paddingHorizontal: 14,
    borderRadius: 3,
    minWidth: 100,
  },
  valueButtonSelected: {
    backgroundColor: 'rgb(56, 143, 215)',
    borderWidth: 2,
    borderColor: '#1e40af',
  },
  valueLabel: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '500',
    textAlign: 'center',
  },
  valueLabelSelected: {
    fontWeight: '600',
  },
  emptyMessage: {
    color: '#64748B',
    fontSize: 14,
    fontStyle: 'italic',
    textAlign: 'center',
    paddingVertical: 20,
    width: '100%',
  },
  slotsContainer: {
    maxHeight: 400,
  },
  slot: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
    minHeight: 44,
  },
  slotNumber: {
    width: 30,
    fontSize: 14,
    fontWeight: '600',
    color: '#64748B',
  },
  slotContent: {
    flex: 1,
    backgroundColor: 'rgb(244, 244, 244)',
    paddingVertical: 10,
    paddingHorizontal: 14,
    borderRadius: 3,
    borderWidth: 2,
    borderColor: 'rgb(96, 187, 202)',
  },
  slotLabel: {
    fontSize: 14,
    color: 'rgb(0, 0, 0)',
    fontWeight: '500',
  },
  emptySlot: {
    flex: 1,
    height: 40,
    borderWidth: 2,
    borderColor: '#cbd5e1',
    borderStyle: 'dashed',
    borderRadius: 3,
    backgroundColor: '#F8F9FA',
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptySlotText: {
    color: '#94a3b8',
    fontSize: 13,
    fontStyle: 'italic',
  },
  insertIndicator: {
    backgroundColor: 'rgba(66, 153, 225, 0.1)',
    borderWidth: 2,
    borderColor: 'rgb(96, 187, 202)',
    borderStyle: 'dashed',
    borderRadius: 3,
    padding: 8,
    marginBottom: 8,
  },
  insertIndicatorText: {
    color: 'rgb(96, 187, 202)',
    fontSize: 13,
    fontWeight: '500',
    textAlign: 'center',
  },
  descriptions: {
    backgroundColor: '#F8F9FA',
    padding: 16,
    borderRadius: 3,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  descTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: 'rgb(45, 55, 72)',
    marginBottom: 12,
  },
  descItem: {
    fontSize: 12,
    color: '#64748B',
    marginBottom: 6,
    lineHeight: 18,
  },
  descBold: {
    fontWeight: '600',
    color: 'rgb(45, 55, 72)',
  },
  selectedInfo: {
    position: 'absolute',
    bottom: -60,
    left: 0,
    right: 0,
    backgroundColor: 'rgb(45, 55, 72)',
    padding: 12,
    borderRadius: 3,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  selectedInfoText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '500',
  },
  cancelButton: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    paddingVertical: 6,
    paddingHorizontal: 12,
    borderRadius: 3,
  },
  cancelButtonText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '500',
  },
});