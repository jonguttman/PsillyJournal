import { useEffect, Component, ReactNode } from 'react';
import { Stack, useRouter } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { View, Text, StyleSheet } from 'react-native';
import * as Linking from 'expo-linking';
import { useAppStore } from '../src/store/appStore';
import { extractTokenFromDeepLink } from '../src/utils/qr';
import { fetchProductInfo } from '../src/services/productApi';
import {
  configureNotifications,
  requestNotificationPermissions,
  setupNotificationResponseHandler,
} from '../src/services/notificationService';

// Error Boundary Component
class ErrorBoundary extends Component<
  { children: ReactNode },
  { hasError: boolean; error: Error | null }
> {
  constructor(props: { children: ReactNode }) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: any) {
    console.error('[ErrorBoundary]', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <View style={errorStyles.container}>
          <Text style={errorStyles.title}>Something went wrong</Text>
          <Text style={errorStyles.message}>
            {this.state.error?.message || 'Unknown error'}
          </Text>
          <Text style={errorStyles.stack}>
            {this.state.error?.stack}
          </Text>
        </View>
      );
    }

    return this.props.children;
  }
}

const errorStyles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0a',
    padding: 20,
    justifyContent: 'center',
  },
  title: {
    color: '#ef4444',
    fontSize: 24,
    fontWeight: '700',
    marginBottom: 16,
  },
  message: {
    color: '#ffffff',
    fontSize: 16,
    marginBottom: 16,
  },
  stack: {
    color: '#a1a1aa',
    fontSize: 12,
    fontFamily: 'monospace',
  },
});

function RootLayoutContent() {
  const router = useRouter();
  const { setPendingBottle, setLoading, setInitialized, isLocked } = useAppStore();

  useEffect(() => {
    // Configure notifications on app start
    configureNotifications();
    
    // Request notification permissions (non-blocking)
    requestNotificationPermissions().then((granted) => {
      console.log('[Layout] Notification permissions:', granted ? 'granted' : 'denied');
    });

    // Setup notification response handler for deep links
    const cleanupNotificationHandler = setupNotificationResponseHandler(
      (pathname, params) => {
        router.push({ pathname: pathname as any, params });
      }
    );

    const handleInitialURL = async () => {
      const url = await Linking.getInitialURL();
      if (url) {
        handleDeepLink(url);
      }
      setInitialized(true);
      setLoading(false);
    };

    const subscription = Linking.addEventListener('url', (event) => {
      handleDeepLink(event.url);
    });

    handleInitialURL();

    return () => {
      subscription.remove();
      cleanupNotificationHandler();
    };
  }, []);

  const handleDeepLink = async (url: string) => {
    console.log('[DeepLink] Received:', url);

    // Handle check-in deep links from notifications
    if (url.includes('check-in/post-dose')) {
      try {
        const urlObj = new URL(url);
        const doseId = urlObj.searchParams.get('dose_id');
        const entryId = urlObj.searchParams.get('entry_id');
        
        if (doseId && entryId) {
          router.push({
            pathname: '/check-in/post-dose',
            params: { dose_id: doseId, entry_id: entryId },
          });
          return;
        }
      } catch (e) {
        console.error('[DeepLink] Error parsing check-in URL:', e);
      }
    }

    // Handle product QR deep links
    const result = extractTokenFromDeepLink(url);

    if (result.success && result.token) {
      const productInfo = await fetchProductInfo(result.token);

      if (productInfo) {
        setPendingBottle({
          token: result.token,
          productInfo,
          source: 'deep_link',
        });
      }
    }
  };

  return (
    <>
      <StatusBar style="light" />
      <Stack
        screenOptions={{
          headerShown: false,
          contentStyle: { backgroundColor: '#0a0a0a' },
          animation: 'slide_from_right',
        }}
      >
        <Stack.Screen name="lock" options={{ presentation: 'fullScreenModal' }} />
        <Stack.Screen name="index" />
        <Stack.Screen name="scan" options={{ presentation: 'fullScreenModal' }} />
        <Stack.Screen name="onboarding" />
        <Stack.Screen name="journal" />
        <Stack.Screen name="settings" />
        <Stack.Screen name="check-in/pre-dose" />
        <Stack.Screen name="check-in/post-dose" />
      </Stack>
    </>
  );
}

export default function RootLayout() {
  return (
    <ErrorBoundary>
      <RootLayoutContent />
    </ErrorBoundary>
  );
}
