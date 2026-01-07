import { useEffect } from 'react';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import * as Linking from 'expo-linking';
import { useAppStore } from '../src/store/appStore';
import { extractTokenFromDeepLink } from '../src/utils/qr';
import { fetchProductInfo } from '../src/services/productApi';

export default function RootLayout() {
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
