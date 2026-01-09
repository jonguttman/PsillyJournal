import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Alert,
  Animated,
} from 'react-native';
import { useRouter } from 'expo-router';
import { PinInput } from '../src/components/PinInput';
import { verifyPin, isPinSet, setPin } from '../src/utils/lock';
import { useAppStore } from '../src/store/appStore';
import { localStorageDB } from '../src/db/localStorageDB';

export default function LockScreen() {
  const router = useRouter();
  const { setLocked } = useAppStore();
  const [mode, setMode] = useState<'unlock' | 'setup' | 'confirm'>('unlock');
  const [setupPin, setSetupPin] = useState('');
  const [hasPin, setHasPin] = useState(false);
  const [error, setError] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');
  const fadeAnim = useState(new Animated.Value(0))[0];

  useEffect(() => {
    checkPinStatus();
    // Fade in animation
    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 300,
      useNativeDriver: true,
    }).start();
  }, []);

  const checkPinStatus = async () => {
    const pinExists = await isPinSet();
    setHasPin(pinExists);
    if (!pinExists) {
      setMode('setup');
    }
  };

  const handlePinComplete = async (pin: string) => {
    if (mode === 'setup') {
      // First PIN entry in setup
      setSetupPin(pin);
      setMode('confirm');
      setError(false);
      setErrorMessage('');
    } else if (mode === 'confirm') {
      // Confirm PIN matches
      if (pin === setupPin) {
        await setPin(pin);
        await unlockJournal();
      } else {
        setError(true);
        setErrorMessage('PINs do not match');
        setTimeout(() => {
          setMode('setup');
          setSetupPin('');
          setError(false);
          setErrorMessage('');
        }, 1500);
      }
    } else {
      // Unlock mode - verify PIN
      const isValid = await verifyPin(pin);
      if (isValid) {
        await unlockJournal();
      } else {
        setError(true);
        setErrorMessage('Incorrect PIN');
        setTimeout(() => {
          setError(false);
          setErrorMessage('');
        }, 1000);
      }
    }
  };

  const unlockJournal = async () => {
    setLocked(false);
    router.replace('/');
  };

  const handleQRUnlock = () => {
    router.push('/scan?unlock=true');
  };

  const getTitleText = () => {
    if (mode === 'setup') return 'Set Your PIN';
    if (mode === 'confirm') return 'Confirm Your PIN';
    return 'Journal Locked';
  };

  const getSubtitleText = () => {
    if (mode === 'setup') return 'Enter a 4-digit PIN to secure your journal';
    if (mode === 'confirm') return 'Enter your PIN again to confirm';
    return 'Enter your PIN or scan your bottle to unlock';
  };

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.content}
    >
      <Animated.View style={[styles.animated, { opacity: fadeAnim }]}>
        {/* Journal Illustration */}
        <View style={styles.illustrationContainer}>
          <View style={styles.journal}>
            <View style={styles.journalCover}>
              {/* Mushroom Keyhole */}
              <View style={styles.keyhole}>
                <View style={styles.mushroomCap} />
                <View style={styles.mushroomStem} />
                <View style={styles.keyholeCircle} />
                <View style={styles.keyholeSlot} />
              </View>
            </View>
            <View style={styles.journalShadow} />
          </View>
        </View>

        {/* Title */}
        <Text style={styles.title}>{getTitleText()}</Text>
        <Text style={styles.subtitle}>{getSubtitleText()}</Text>

        {/* Error Message */}
        {errorMessage ? (
          <Text style={styles.errorText}>{errorMessage}</Text>
        ) : (
          <View style={styles.errorPlaceholder} />
        )}

        {/* PIN Input */}
        <View style={styles.pinContainer}>
          <PinInput
            length={4}
            onComplete={handlePinComplete}
            error={error}
            onErrorAnimationComplete={() => setError(false)}
          />
        </View>

        {/* QR Unlock Option (only in unlock mode) */}
        {mode === 'unlock' && (
          <>
            <View style={styles.divider}>
              <View style={styles.dividerLine} />
              <Text style={styles.dividerText}>or</Text>
              <View style={styles.dividerLine} />
            </View>

            <TouchableOpacity
              style={styles.qrButton}
              onPress={handleQRUnlock}
            >
              <Text style={styles.qrButtonIcon}>📷</Text>
              <Text style={styles.qrButtonText}>Scan Bottle QR</Text>
            </TouchableOpacity>
          </>
        )}
      </Animated.View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F5F1E8',
  },
  content: {
    padding: 32,
    paddingTop: 80,
    alignItems: 'center',
    minHeight: '100%',
  },
  animated: {
    width: '100%',
    alignItems: 'center',
  },
  illustrationContainer: {
    marginBottom: 40,
    alignItems: 'center',
  },
  journal: {
    position: 'relative',
  },
  journalCover: {
    width: 200,
    height: 260,
    backgroundColor: '#8B7355',
    borderRadius: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 8,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#6B5845',
  },
  journalShadow: {
    position: 'absolute',
    bottom: -8,
    left: 8,
    right: -8,
    height: 260,
    backgroundColor: '#00000015',
    borderRadius: 8,
    zIndex: -1,
  },
  keyhole: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  mushroomCap: {
    width: 60,
    height: 35,
    backgroundColor: '#D4AF37',
    borderRadius: 30,
    marginBottom: -5,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 4,
  },
  mushroomStem: {
    width: 30,
    height: 40,
    backgroundColor: '#E8D4A0',
    borderRadius: 15,
    marginBottom: -10,
  },
  keyholeCircle: {
    width: 20,
    height: 20,
    backgroundColor: '#2C2416',
    borderRadius: 10,
    marginBottom: -2,
  },
  keyholeSlot: {
    width: 8,
    height: 20,
    backgroundColor: '#2C2416',
    borderBottomLeftRadius: 4,
    borderBottomRightRadius: 4,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: '#2C2416',
    marginBottom: 8,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 14,
    color: '#6B5845',
    textAlign: 'center',
    marginBottom: 8,
    paddingHorizontal: 40,
  },
  errorPlaceholder: {
    height: 24,
  },
  errorText: {
    fontSize: 14,
    color: '#ef4444',
    textAlign: 'center',
    marginBottom: 8,
    height: 24,
  },
  pinContainer: {
    marginVertical: 32,
  },
  divider: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 24,
    width: '100%',
  },
  dividerLine: {
    flex: 1,
    height: 1,
    backgroundColor: '#D4C5B0',
  },
  dividerText: {
    marginHorizontal: 16,
    fontSize: 14,
    color: '#8B7355',
    fontWeight: '500',
  },
  qrButton: {
    backgroundColor: '#ffffff',
    paddingVertical: 16,
    paddingHorizontal: 24,
    borderRadius: 12,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
    borderWidth: 1,
    borderColor: '#D4C5B0',
  },
  qrButtonIcon: {
    fontSize: 24,
  },
  qrButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#2C2416',
  },
});
