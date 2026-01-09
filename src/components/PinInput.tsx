import React, { useState, useRef, useEffect } from 'react';
import {
  View,
  TextInput,
  StyleSheet,
  TouchableOpacity,
  Text,
  Animated,
  Platform,
} from 'react-native';

interface PinInputProps {
  length?: number;
  onComplete: (pin: string) => void;
  error?: boolean;
  onErrorAnimationComplete?: () => void;
}

export function PinInput({
  length = 4,
  onComplete,
  error = false,
  onErrorAnimationComplete,
}: PinInputProps) {
  const [pin, setPin] = useState('');
  const inputRef = useRef<TextInput>(null);
  const shakeAnim = useRef(new Animated.Value(0)).current;

  // Focus input on mount
  useEffect(() => {
    setTimeout(() => {
      inputRef.current?.focus();
    }, 300);
  }, []);

  // Shake animation on error
  useEffect(() => {
    if (error) {
      Animated.sequence([
        Animated.timing(shakeAnim, {
          toValue: 10,
          duration: 50,
          useNativeDriver: true,
        }),
        Animated.timing(shakeAnim, {
          toValue: -10,
          duration: 50,
          useNativeDriver: true,
        }),
        Animated.timing(shakeAnim, {
          toValue: 10,
          duration: 50,
          useNativeDriver: true,
        }),
        Animated.timing(shakeAnim, {
          toValue: 0,
          duration: 50,
          useNativeDriver: true,
        }),
      ]).start(() => {
        onErrorAnimationComplete?.();
      });
    }
  }, [error]);

  const handleChangeText = (text: string) => {
    // Only allow digits
    const filtered = text.replace(/[^0-9]/g, '');

    if (filtered.length <= length) {
      setPin(filtered);

      // Call onComplete when full length is reached
      if (filtered.length === length) {
        onComplete(filtered);
      }
    }
  };

  const handlePress = () => {
    inputRef.current?.focus();
  };

  return (
    <View style={styles.container}>
      {/* Hidden input for keyboard */}
      <TextInput
        ref={inputRef}
        value={pin}
        onChangeText={handleChangeText}
        keyboardType="number-pad"
        maxLength={length}
        secureTextEntry={Platform.OS !== 'web'}
        style={styles.hiddenInput}
        autoFocus
      />

      {/* Visual PIN dots */}
      <Animated.View
        style={[
          styles.dotsContainer,
          { transform: [{ translateX: shakeAnim }] },
        ]}
      >
        <TouchableOpacity
          activeOpacity={1}
          onPress={handlePress}
          style={styles.dotsRow}
        >
          {Array.from({ length }).map((_, index) => (
            <View
              key={index}
              style={[
                styles.dot,
                pin.length > index && styles.dotFilled,
                error && styles.dotError,
              ]}
            />
          ))}
        </TouchableOpacity>
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
  },
  hiddenInput: {
    position: 'absolute',
    opacity: 0,
    width: 1,
    height: 1,
  },
  dotsContainer: {
    flexDirection: 'row',
  },
  dotsRow: {
    flexDirection: 'row',
    gap: 16,
  },
  dot: {
    width: 16,
    height: 16,
    borderRadius: 8,
    backgroundColor: '#27272a',
    borderWidth: 2,
    borderColor: '#3f3f46',
  },
  dotFilled: {
    backgroundColor: '#8b5cf6',
    borderColor: '#8b5cf6',
  },
  dotError: {
    backgroundColor: '#ef4444',
    borderColor: '#ef4444',
  },
});
