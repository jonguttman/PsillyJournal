import { useEffect, Component, ReactNode } from 'react';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { View, Text, StyleSheet } from 'react-native';
import * as Linking from 'expo-linking';
import { useAppStore } from '../src/store/appStore';
import { extractTokenFromDeepLink } from '../src/utils/qr';
import { fetchProductInfo } from '../src/services/productApi';

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
  const { setPendingBottle, setLoading, setInitialized } = useAppStore();

  useEffect(() => {
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
    };
  }, []);

  const handleDeepLink = async (url: string) => {
    console.log('[DeepLink] Received:', url);

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
        <Stack.Screen name="index" />
        <Stack.Screen name="scan" options={{ presentation: 'fullScreenModal' }} />
        <Stack.Screen name="onboarding" />
        <Stack.Screen name="journal" />
        <Stack.Screen name="entry" />
        <Stack.Screen name="settings" />
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
