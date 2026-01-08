import { useState } from 'react';
import { View, Text, StyleSheet, Alert } from 'react-native';
import { useRouter } from 'expo-router';
import { QRScanner } from '../src/components/QRScanner';
import { handleScannedToken, switchProduct, logDose } from '../src/services/bottleService';
import { useAppStore } from '../src/store/appStore';
import type { QRToken } from '../src/types';

export default function ScanScreen() {
  const router = useRouter();
  const [isProcessing, setIsProcessing] = useState(false);
  const { setPendingBottle, setActiveProtocol, activeProtocol } = useAppStore();

  const handleScan = async (token: QRToken) => {
    if (isProcessing) return;
    setIsProcessing(true);

    try {
      const result = await handleScannedToken(token);

      switch (result.type) {
        case 'known_bottle':
          // Bottle exists - welcome back the user
          if (result.protocol && result.bottle) {
            setActiveProtocol({
              id: result.protocol.id,
              sessionId: result.protocol.sessionId,
              productId: result.protocol.productId,
              productName: result.protocol.productName,
              currentDay: result.protocol.currentDay,
              totalDays: result.protocol.totalDays,
              status: result.protocol.status,
            });

            Alert.alert(
              'Welcome Back! 🍄',
              `Day ${result.protocol.currentDay} of your ${result.protocol.productName} protocol.`,
              [{ text: 'Continue', onPress: () => router.replace('/') }]
            );
          } else {
            Alert.alert(
              'Welcome Back!',
              'This bottle was previously used. Start a new protocol?',
              [
                { text: 'Cancel', style: 'cancel', onPress: () => router.back() },
                { text: 'Start New', onPress: () => router.back() },
              ]
            );
          }
          break;

        case 'new_bottle':
          if (result.productInfo) {
            setPendingBottle({
              token,
              productInfo: result.productInfo,
              source: 'qr_scan',
            });
            router.replace('/onboarding');
          }
          break;

        case 'product_switch':
          if (result.productInfo && result.protocol) {
            Alert.alert(
              'New Product Detected',
              `You've been using ${result.protocol.productName}.\n\nStart new protocol with ${result.productInfo.name}?\n\nYour previous history will be preserved.`,
              [
                { text: 'Cancel', style: 'cancel', onPress: () => router.back() },
                { 
                  text: 'Start New Protocol', 
                  onPress: async () => {
                    try {
                      const { protocol } = await switchProduct(
                        token,
                        result.productInfo!,
                        result.protocol!
                      );
                      setActiveProtocol({
                        id: protocol.id,
                        sessionId: protocol.sessionId,
                        productId: protocol.productId,
                        productName: protocol.productName,
                        currentDay: protocol.currentDay,
                        totalDays: protocol.totalDays,
                        status: protocol.status,
                      });
                      router.replace('/');
                    } catch (error) {
                      Alert.alert('Error', 'Failed to switch products.');
                    }
                  }
                },
              ]
            );
          }
          break;

        case 'error':
          Alert.alert('Error', result.error || 'Failed to process QR code');
          setIsProcessing(false);
          break;
      }
    } catch (error) {
      Alert.alert('Error', 'Something went wrong. Please try again.');
      setIsProcessing(false);
    }
  };

  if (isProcessing) {
    return (
      <View style={styles.processingContainer}>
        <Text style={styles.processingText}>Logging dose...</Text>
      </View>
    );
  }

  return (
    <QRScanner
      onScan={handleScan}
      onCancel={() => router.back()}
      onManualEntry={() => Alert.alert('Coming Soon', 'Manual entry not yet available.')}
    />
  );
}

const styles = StyleSheet.create({
  processingContainer: {
    flex: 1,
    backgroundColor: '#0a0a0a',
    justifyContent: 'center',
    alignItems: 'center',
  },
  processingText: {
    color: '#ffffff',
    fontSize: 18,
  },
});
