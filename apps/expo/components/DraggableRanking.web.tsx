import React, { useState, useRef, useEffect } from 'react';
import './DraggableRanking.css';

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

export default function DraggableRanking({ values, currentRanking, onRankingChange }: DraggableRankingProps) {
  const [draggedItem, setDraggedItem] = useState<string | null>(null);
  const [draggedFromIndex, setDraggedFromIndex] = useState<number | null>(null);
  const [dropIndicatorIndex, setDropIndicatorIndex] = useState<number | null>(null);
  const [isDraggingOver, setIsDraggingOver] = useState(false);
  const [touchItem, setTouchItem] = useState<string | null>(null);
  const dragImageRef = useRef<HTMLDivElement | null>(null);
  const containerRef = useRef<HTMLDivElement | null>(null);
  const lastValidDropIndex = useRef<number | null>(null);
  
  const remainingValues = values.filter(v => !currentRanking.includes(v.key));
  
  // Prevent default touch behavior
  const preventDefaultTouch = (e: TouchEvent) => {
    if (touchItem) {
      e.preventDefault();
      e.stopPropagation();
    }
  };
  
  // Touch event handlers
  const handleTouchStart = (e: React.TouchEvent, valueKey: string, fromIndex?: number) => {
    e.stopPropagation();
    
    // Prevent default immediately to stop scrolling
    e.preventDefault();
    
    setTouchItem(valueKey);
    setDraggedItem(valueKey);
    setDraggedFromIndex(fromIndex ?? null);
    lastValidDropIndex.current = null;
    
    // Add class to prevent scrolling
    const container = containerRef.current;
    if (container) {
      container.classList.add('touch-dragging');
    }
    
    // Store current scroll position
    const scrollY = window.scrollY;
    const scrollX = window.scrollX;
    
    // Prevent all scrolling but maintain position
    document.body.style.overflow = 'hidden';
    document.body.style.position = 'fixed';
    document.body.style.width = '100%';
    document.body.style.top = `-${scrollY}px`;
    document.body.style.left = `-${scrollX}px`;
    document.body.style.touchAction = 'none';
    
    // Store scroll position for restoration
    document.body.dataset.scrollY = scrollY.toString();
    document.body.dataset.scrollX = scrollX.toString();
    
    // Add global touch move listener
    document.addEventListener('touchmove', preventDefaultTouch, { passive: false });
    
    // Create drag image for touch
    if (dragImageRef.current) {
      const touch = e.touches[0];
      dragImageRef.current.style.display = 'block';
      dragImageRef.current.style.left = `${touch.clientX - 50}px`;
      dragImageRef.current.style.top = `${touch.clientY - 20}px`;
      dragImageRef.current.textContent = values.find(v => v.key === valueKey)?.label || '';
    }
  };
  
  const handleTouchMove = (e: React.TouchEvent) => {
    if (!touchItem) return;
    
    // Always prevent default to stop scrolling
    e.preventDefault();
    e.stopPropagation();
    
    const touch = e.touches[0];
    
    // Update drag image position
    if (dragImageRef.current) {
      dragImageRef.current.style.left = `${touch.clientX - 50}px`;
      dragImageRef.current.style.top = `${touch.clientY - 20}px`;
    }
    
    // Hide drag image temporarily to find element under it
    if (dragImageRef.current) {
      dragImageRef.current.style.pointerEvents = 'none';
      dragImageRef.current.style.display = 'none';
    }
    
    // Find element under touch point
    const element = document.elementFromPoint(touch.clientX, touch.clientY);
    
    // Show drag image again
    if (dragImageRef.current) {
      dragImageRef.current.style.display = 'block';
    }
    
    if (element) {
      // Check if we're over a slot or empty slot
      const slotElement = element.closest('.ranking-slot');
      const emptySlotElement = element.closest('.ranking-empty-slot');
      const slotContentElement = element.closest('.ranking-slot-content');
      
      if (slotElement) {
        const index = parseInt(slotElement.getAttribute('data-index') || '0');
        const rect = slotElement.getBoundingClientRect();
        
        // Determine position more accurately
        let targetIndex = index;
        
        if (slotContentElement || emptySlotElement) {
          // We're directly over a slot
          targetIndex = index;
        } else {
          // Check position within slot
          const y = touch.clientY - rect.top;
          const height = rect.height;
          
          if (!currentRanking[index]) {
            // Empty slot
            targetIndex = index;
          } else if (y < height / 2) {
            // Top half - insert before
            targetIndex = index;
          } else {
            // Bottom half - insert after
            targetIndex = index + 1;
          }
        }
        
        // Adjust for removal if dragging from ranking
        if (draggedFromIndex !== null && targetIndex > draggedFromIndex) {
          targetIndex--;
        }
        
        // Ensure target index is within valid bounds
        targetIndex = Math.max(0, Math.min(targetIndex, currentRanking.length));
        
        setDropIndicatorIndex(targetIndex);
        lastValidDropIndex.current = targetIndex;
      }
    }
  };
  
  const handleTouchEnd = (e: React.TouchEvent) => {
    if (!touchItem) return;
    
    // Hide drag image
    if (dragImageRef.current) {
      dragImageRef.current.style.display = 'none';
    }
    
    // Remove class to allow scrolling again
    const container = containerRef.current;
    if (container) {
      container.classList.remove('touch-dragging');
    }
    
    // Re-enable body scrolling and restore position
    const scrollY = parseInt(document.body.dataset.scrollY || '0');
    const scrollX = parseInt(document.body.dataset.scrollX || '0');
    
    document.body.style.overflow = '';
    document.body.style.position = '';
    document.body.style.width = '';
    document.body.style.top = '';
    document.body.style.left = '';
    document.body.style.touchAction = '';
    
    // Restore scroll position
    window.scrollTo(scrollX, scrollY);
    
    // Clean up data attributes
    delete document.body.dataset.scrollY;
    delete document.body.dataset.scrollX;
    
    // Remove global touch move listener
    document.removeEventListener('touchmove', preventDefaultTouch);
    
    // Perform the drop if we have a valid index
    if (lastValidDropIndex.current !== null) {
      performDrop(lastValidDropIndex.current);
    }
    
    // Reset state
    setTouchItem(null);
    setDraggedItem(null);
    setDraggedFromIndex(null);
    setDropIndicatorIndex(null);
    setIsDraggingOver(false);
    lastValidDropIndex.current = null;
  };
  
  // Drag event handlers
  const handleDragStart = (e: React.DragEvent, valueKey: string, fromIndex?: number) => {
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/plain', valueKey);
    setDraggedItem(valueKey);
    setDraggedFromIndex(fromIndex ?? null);
  };
  
  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    setIsDraggingOver(true);
  };
  
  const handleDragOverSlot = (index: number, clientY: number, rect: DOMRect) => {
    if (!draggedItem) return;
    
    const y = clientY - rect.top;
    const height = rect.height;
    
    // Determine if we should show indicator above or below this slot
    let indicatorPos = index;
    
    // If dragging over an empty slot, show indicator at that position
    if (!currentRanking[index]) {
      setDropIndicatorIndex(index);
      return;
    }
    
    // If dragging over a filled slot, determine position based on mouse position
    if (y < height / 2) {
      // Top half - show indicator above
      indicatorPos = index;
    } else {
      // Bottom half - show indicator below
      indicatorPos = index + 1;
    }
    
    // If dragging from within the ranking, adjust for the removal
    // This adjustment should only happen if we're moving to a position after the original
    if (draggedFromIndex !== null && indicatorPos > draggedFromIndex) {
      indicatorPos--;
    }
    
    // Ensure indicator position is within valid bounds
    indicatorPos = Math.max(0, Math.min(indicatorPos, currentRanking.length));
    
    setDropIndicatorIndex(indicatorPos);
  };
  
  const handleDragOverSlotEvent = (e: React.DragEvent, index: number) => {
    e.preventDefault();
    e.stopPropagation();
    
    if (!draggedItem) return;
    
    const rect = e.currentTarget.getBoundingClientRect();
    handleDragOverSlot(index, e.clientY, rect);
  };
  
  const handleDragLeave = (e: React.DragEvent) => {
    // Only clear if we're leaving the entire ranking area
    if (!e.currentTarget.contains(e.relatedTarget as Node)) {
      setDropIndicatorIndex(null);
      setIsDraggingOver(false);
    }
  };
  
  const performDrop = (targetIndex: number) => {
    if (!draggedItem) return;
    
    // Create a copy of current ranking
    let newRanking = [...currentRanking];
    
    // If dragging from unranked values (adding new item)
    if (draggedFromIndex === null) {
      // We have 10 total slots, check how many are actually filled
      // The currentRanking array only contains filled items, not empty slots
      // So if currentRanking.length < 10, we have empty slots available
      
      // Simply insert the new item at the target position
      // The target index represents where in the ranking to place it
      const insertIndex = Math.min(targetIndex, newRanking.length);
      
      // Insert the new item at the target position
      newRanking.splice(insertIndex, 0, draggedItem);
      
      // Only limit to 10 items maximum
      if (newRanking.length > 10) {
        // This should rarely happen, but just in case
        newRanking = newRanking.slice(0, 10);
      }
      
      onRankingChange(newRanking);
    } 
    // If dragging within ranked values (reordering existing items)
    else {
      // Remove from old position
      const [removed] = newRanking.splice(draggedFromIndex, 1);
      
      // Calculate correct insert index
      let insertIndex = targetIndex;
      
      // If we removed an item before the target, adjust the index
      if (draggedFromIndex < targetIndex) {
        insertIndex = Math.max(0, insertIndex - 1);
      }
      
      // Ensure index is within bounds
      insertIndex = Math.min(insertIndex, newRanking.length);
      insertIndex = Math.max(0, insertIndex);
      
      // Insert at new position
      newRanking.splice(insertIndex, 0, removed);
      
      onRankingChange(newRanking);
    }
  };
  
  const handleDrop = (e?: React.DragEvent) => {
    if (e) {
      e.preventDefault();
      e.stopPropagation();
    }
    
    if (!draggedItem || dropIndicatorIndex === null) {
      // Reset state
      setDraggedItem(null);
      setDraggedFromIndex(null);
      setDropIndicatorIndex(null);
      setIsDraggingOver(false);
      return;
    }
    
    performDrop(dropIndicatorIndex);
    
    // Reset drag state
    setDraggedItem(null);
    setDraggedFromIndex(null);
    setDropIndicatorIndex(null);
    setIsDraggingOver(false);
  };
  
  const handleRemove = (valueKey: string) => {
    const newRanking = currentRanking.filter(key => key !== valueKey);
    onRankingChange(newRanking);
  };
  
  const handleDragEnd = () => {
    // Clean up in case drop didn't fire
    setDraggedItem(null);
    setDraggedFromIndex(null);
    setDropIndicatorIndex(null);
    setIsDraggingOver(false);
  };
  
  // Add touch drag image element
  useEffect(() => {
    if (!dragImageRef.current) {
      const dragImage = document.createElement('div');
      dragImage.className = 'touch-drag-image';
      dragImage.style.position = 'fixed';
      dragImage.style.display = 'none';
      dragImage.style.zIndex = '9999';
      dragImage.style.pointerEvents = 'none';
      document.body.appendChild(dragImage);
      dragImageRef.current = dragImage;
    }
    
    return () => {
      if (dragImageRef.current && dragImageRef.current.parentNode) {
        dragImageRef.current.parentNode.removeChild(dragImageRef.current);
      }
    };
  }, []);
  
  return (
    <div className="ranking-container" ref={containerRef}>
      <div className="ranking-columns">
        {/* Left Column - Available Values */}
        <div className="ranking-column ranking-left">
          <h3 className="ranking-column-title">Seçenekler (Sürükleyin)</h3>
          <div className="ranking-values-container">
            {remainingValues.map((val) => (
              <div
                key={val.key}
                className={`ranking-value-button ${draggedItem === val.key ? 'dragging' : ''}`}
                draggable
                onDragStart={(e) => handleDragStart(e, val.key)}
                onDragEnd={handleDragEnd}
                onTouchStart={(e) => handleTouchStart(e, val.key)}
                onTouchMove={handleTouchMove}
                onTouchEnd={handleTouchEnd}
                title={val.desc}
                style={{ touchAction: 'none' }}
              >
                {val.label}
              </div>
            ))}
            {remainingValues.length === 0 && (
              <div className="ranking-empty-message">
                Tüm değerler sıralandı
              </div>
            )}
          </div>
        </div>
        
        {/* Right Column - Ranked Values */}
        <div className="ranking-column ranking-right">
          <h3 className="ranking-column-title">Sıralama (1 = En Önemli, 10 = En Az Önemli)</h3>
          <div 
            className={`ranking-slots-container ${isDraggingOver ? 'dragging-over' : ''}`}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            onDrop={handleDrop}
          >
            {[...Array(10)].map((_, index) => {
              const valueKey = currentRanking[index];
              const valueData = valueKey ? values.find(v => v.key === valueKey) : null;
              const showIndicatorAbove = dropIndicatorIndex === index && draggedItem;
              const showIndicatorBelow = dropIndicatorIndex === index + 1 && draggedItem && index === currentRanking.length - 1;
              
              return (
                <React.Fragment key={index}>
                  {showIndicatorAbove && (
                    <div className="ranking-drop-indicator">
                      <div className="indicator-line"></div>
                      <div className="indicator-preview">
                        {values.find(v => v.key === draggedItem)?.label}
                      </div>
                    </div>
                  )}
                  <div
                    className={`ranking-slot ${!valueData ? 'empty' : ''}`}
                    data-index={index}
                    onDragOver={(e) => handleDragOverSlotEvent(e, index)}
                  >
                    <span className="ranking-slot-number">{index + 1}.</span>
                    {valueData ? (
                      <div
                        className={`ranking-slot-content ${draggedItem === valueKey ? 'dragging' : ''}`}
                        draggable
                        onDragStart={(e) => handleDragStart(e, valueKey, index)}
                        onDragEnd={handleDragEnd}
                        onTouchStart={(e) => handleTouchStart(e, valueKey, index)}
                        onTouchMove={handleTouchMove}
                        onTouchEnd={handleTouchEnd}
                        onDoubleClick={() => handleRemove(valueKey)}
                        title="Çift tıklayarak kaldırın veya sürükleyin"
                        style={{ touchAction: 'none' }}
                      >
                        <span className="ranking-slot-label">{valueData.label}</span>
                      </div>
                    ) : (
                      <div className="ranking-empty-slot" data-index={index}>
                        <span className="empty-slot-text">Boş</span>
                      </div>
                    )}
                  </div>
                  {showIndicatorBelow && (
                    <div className="ranking-drop-indicator">
                      <div className="indicator-line"></div>
                      <div className="indicator-preview">
                        {values.find(v => v.key === draggedItem)?.label}
                      </div>
                    </div>
                  )}
                </React.Fragment>
              );
            })}
          </div>
        </div>
      </div>
      
      {/* Value Descriptions */}
      <div className="ranking-descriptions">
        <h4 className="ranking-desc-title">Değer Açıklamaları:</h4>
        {values.map((val) => (
          <p key={val.key} className="ranking-desc-item">
            <strong>{val.label}:</strong> {val.desc}
          </p>
        ))}
      </div>
      
      {/* Instructions */}
      <div className="ranking-instructions">
        <p>💡 <strong>Kullanım:</strong> Soldaki değerleri sağdaki sıralamaya sürükleyin. Sıralamadaki öğeleri yeniden düzenlemek için sürükleyin. Çift tıklayarak kaldırın.</p>
      </div>
    </div>
  );
}