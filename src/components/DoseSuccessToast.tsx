import React, { useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Animated } from 'react-native';

interface DoseSuccessToastProps {
  visible: boolean;
  timestamp: Date;
  onUndo: () => void;
  onDismiss: () => void;
}

export function DoseSuccessToast({ visible, timestamp, onUndo, onDismiss }: DoseSuccessToastProps) {
  const opacity = React.useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (visible) {
      Animated.timing(opacity, {
        toValue: 1,
        duration: 200,
        useNativeDriver: true,
      }).start();

      // Auto-dismiss after 5 seconds
      const timer = setTimeout(() => {
        Animated.timing(opacity, {
          toValue: 0,
          duration: 200,
          useNativeDriver: true,
        }).start(() => onDismiss());
      }, 5000);

      return () => clearTimeout(timer);
    }
  }, [visible]);

  if (!visible) return null;

  const timeString = timestamp.toLocaleTimeString([], {
    hour: 'numeric',
    minute: '2-digit'
  });

  return (
    <Animated.View style={[styles.toast, { opacity }]}>
      <View style={styles.content}>
        <Text style={styles.icon}>✓</Text>
        <View style={styles.textContainer}>
          <Text style={styles.title}>Dose logged</Text>
          <Text style={styles.time}>{timeString}</Text>
        </View>
      </View>
      <TouchableOpacity onPress={onUndo} style={styles.undoButton}>
        <Text style={styles.undoText}>Undo</Text>
      </TouchableOpacity>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  toast: {
    position: 'absolute',
    bottom: 100,
    left: 20,
    right: 20,
    backgroundColor: '#22c55e',
    borderRadius: 12,
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  content: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  icon: {
    fontSize: 20,
    color: '#ffffff',
  },
  textContainer: {
    gap: 2,
  },
  title: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '600',
  },
  time: {
    color: '#ffffff',
    opacity: 0.8,
    fontSize: 14,
  },
  undoButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
  },
  undoText: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: '600',
  },
});
