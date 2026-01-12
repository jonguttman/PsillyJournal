import React, { useState, useEffect, useCallback } from 'react';
import { StyleSheet, View, Text, TouchableOpacity, Alert } from 'react-native';
import { CameraView, useCameraPermissions } from 'expo-camera';
import { extractQRToken } from '../utils/qr';
import type { QRToken, QRScanResult } from '../types';

interface QRScannerProps {
  onScan: (token: QRToken) => void;
  onCancel: () => void;
  onManualEntry?: () => void;
}

/**
 * QR Scanner Component
 * 
 * CRITICAL BEHAVIORS:
 * 1. Extracts token from PsillyOps URL - does NOT navigate to URL
 * 2. Browser should NEVER open when scanning
 * 3. Validates token format before calling onScan
 * 4. Handles camera permissions gracefully
 */
export function QRScanner({ onScan, onCancel, onManualEntry }: QRScannerProps) {
  const [permission, requestPermission] = useCameraPermissions();
  const [scanned, setScanned] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Reset scanned state when component mounts
  useEffect(() => {
    setScanned(false);
    setError(null);
    console.log('[QRScanner] Component mounted. Permission state:', permission);
  }, []);

  // Log permission changes
  useEffect(() => {
    console.log('[QRScanner] Permission changed:', permission);
  }, [permission]);

  /**
   * Handle barcode scan
   * 
   * IMPORTANT: We extract the token from the URL and process it locally.
   * We do NOT open the URL in a browser or navigate anywhere.
   */
  const handleBarcodeScanned = useCallback(
    ({ data }: { data: string }) => {
      // Prevent multiple scans
      if (scanned) return;

      console.log('[QRScanner] Scanned data:', data);

      // Extract token from PsillyOps URL
      const result: QRScanResult = extractQRToken(data);

      if (result.success && result.token) {
        setScanned(true);
        setError(null);
        
        // Call parent handler with token
        // Parent will handle bottle lookup, NOT browser navigation
        onScan(result.token);
      } else {
        // Show error briefly, then allow retry
        setError(result.error || 'Invalid QR code');
        
        // Reset after delay to allow retry
        setTimeout(() => {
          setError(null);
        }, 2000);
      }
    },
    [scanned, onScan]
  );

  // Handle permission not yet determined
  if (!permission) {
    return (
      <View style={styles.container}>
        <Text style={styles.message}>Requesting camera permission...</Text>
      </View>
    );
  }

  // Handle permission request
  const handleRequestPermission = async () => {
    console.log('[QRScanner] Requesting camera permission...');
    try {
      const result = await requestPermission();
      console.log('[QRScanner] Permission result:', result);

      if (!result.granted) {
        console.log('[QRScanner] Permission denied by user');
        Alert.alert(
          'Camera Access Required',
          'Please enable camera access in Settings to scan QR codes.',
          [{ text: 'OK' }]
        );
      } else {
        console.log('[QRScanner] Permission granted!');
      }
    } catch (error) {
      console.error('[QRScanner] Error requesting permission:', error);
      Alert.alert(
        'Error',
        'Failed to request camera permission. Error: ' + error,
        [{ text: 'OK' }]
      );
    }
  };

  // Handle permission denied
  if (!permission.granted) {
    return (
      <View style={styles.container}>
        <Text style={styles.message}>Camera permission is required to scan QR codes.</Text>
        <TouchableOpacity style={styles.button} onPress={handleRequestPermission}>
          <Text style={styles.buttonText}>Grant Permission</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.secondaryButton} onPress={onCancel}>
          <Text style={styles.secondaryButtonText}>Cancel</Text>
        </TouchableOpacity>
        {onManualEntry && (
          <TouchableOpacity style={styles.linkButton} onPress={onManualEntry}>
            <Text style={styles.linkText}>Enter code manually</Text>
          </TouchableOpacity>
        )}
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={onCancel} style={styles.cancelButton}>
          <Text style={styles.cancelText}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.title}>Scan Bottle</Text>
        <View style={styles.placeholder} />
      </View>

      {/* Camera View */}
      <View style={styles.cameraContainer}>
        <CameraView
          style={styles.camera}
          barcodeScannerSettings={{
            barcodeTypes: ['qr'],
          }}
          onBarcodeScanned={scanned ? undefined : handleBarcodeScanned}
        />

        {/* Viewfinder Overlay */}
        <View style={styles.overlay}>
          <View style={styles.viewfinder}>
            <View style={[styles.corner, styles.topLeft]} />
            <View style={[styles.corner, styles.topRight]} />
            <View style={[styles.corner, styles.bottomLeft]} />
            <View style={[styles.corner, styles.bottomRight]} />
          </View>
        </View>

        {/* Error Message */}
        {error && (
          <View style={styles.errorContainer}>
            <Text style={styles.errorText}>{error}</Text>
          </View>
        )}
      </View>

      {/* Instructions */}
      <View style={styles.footer}>
        <Text style={styles.instructions}>
          Point camera at the QR code on your Psilly bottle
        </Text>
        {onManualEntry && (
          <TouchableOpacity style={styles.linkButton} onPress={onManualEntry}>
            <Text style={styles.linkText}>Enter code manually</Text>
          </TouchableOpacity>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0a',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingTop: 60,
    paddingBottom: 16,
  },
  cancelButton: {
    padding: 8,
  },
  cancelText: {
    color: '#8b5cf6',
    fontSize: 16,
  },
  title: {
    color: '#ffffff',
    fontSize: 18,
    fontWeight: '600',
  },
  placeholder: {
    width: 60,
  },
  cameraContainer: {
    flex: 1,
    position: 'relative',
  },
  camera: {
    flex: 1,
  },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'center',
    alignItems: 'center',
  },
  viewfinder: {
    width: 250,
    height: 250,
    position: 'relative',
  },
  corner: {
    position: 'absolute',
    width: 30,
    height: 30,
    borderColor: '#8b5cf6',
  },
  topLeft: {
    top: 0,
    left: 0,
    borderTopWidth: 3,
    borderLeftWidth: 3,
  },
  topRight: {
    top: 0,
    right: 0,
    borderTopWidth: 3,
    borderRightWidth: 3,
  },
  bottomLeft: {
    bottom: 0,
    left: 0,
    borderBottomWidth: 3,
    borderLeftWidth: 3,
  },
  bottomRight: {
    bottom: 0,
    right: 0,
    borderBottomWidth: 3,
    borderRightWidth: 3,
  },
  errorContainer: {
    position: 'absolute',
    bottom: 100,
    left: 20,
    right: 20,
    backgroundColor: 'rgba(239, 68, 68, 0.9)',
    padding: 12,
    borderRadius: 8,
  },
  errorText: {
    color: '#ffffff',
    textAlign: 'center',
    fontSize: 14,
  },
  footer: {
    padding: 24,
    alignItems: 'center',
  },
  instructions: {
    color: '#a1a1aa',
    fontSize: 16,
    textAlign: 'center',
    marginBottom: 16,
  },
  message: {
    color: '#ffffff',
    fontSize: 16,
    textAlign: 'center',
    marginBottom: 24,
    paddingHorizontal: 32,
    marginTop: 100,
  },
  button: {
    backgroundColor: '#8b5cf6',
    paddingVertical: 14,
    paddingHorizontal: 32,
    borderRadius: 8,
    marginHorizontal: 32,
    marginBottom: 12,
  },
  buttonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
  },
  secondaryButton: {
    paddingVertical: 14,
    paddingHorizontal: 32,
    marginHorizontal: 32,
  },
  secondaryButtonText: {
    color: '#a1a1aa',
    fontSize: 16,
    textAlign: 'center',
  },
  linkButton: {
    padding: 8,
  },
  linkText: {
    color: '#8b5cf6',
    fontSize: 14,
  },
});

export default QRScanner;
