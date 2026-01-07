import { ExpoConfig, ConfigContext } from 'expo/config';

export default ({ config }: ConfigContext): ExpoConfig => ({
  ...config,
  name: 'Psilly Journal',
  slug: 'psilly-journal',
  version: '1.0.0',
  orientation: 'portrait',
  icon: './assets/icon.png',
  userInterfaceStyle: 'dark',
  scheme: 'psillyjournal',
  
  splash: {
    image: './assets/splash.png',
    resizeMode: 'contain',
    backgroundColor: '#0a0a0a',
  },

  assetBundlePatterns: ['**/*'],

  ios: {
    supportsTablet: true,
    bundleIdentifier: 'com.psillyops.journal',
    buildNumber: '1',
    infoPlist: {
      NSCameraUsageDescription: 'Camera access is needed to scan QR codes on your Psilly bottles.',
    },
    associatedDomains: [
      'applinks:journal.originalpsilly.com',
    ],
  },

  android: {
    adaptiveIcon: {
      foregroundImage: './assets/adaptive-icon.png',
      backgroundColor: '#0a0a0a',
    },
    package: 'com.psillyops.journal',
    versionCode: 1,
    permissions: ['CAMERA'],
    intentFilters: [
      {
        action: 'VIEW',
        autoVerify: true,
        data: [
          {
            scheme: 'https',
            host: 'journal.originalpsilly.com',
            pathPrefix: '/bottle',
          },
        ],
        category: ['BROWSABLE', 'DEFAULT'],
      },
      {
        action: 'VIEW',
        data: [
          {
            scheme: 'psillyjournal',
          },
        ],
        category: ['BROWSABLE', 'DEFAULT'],
      },
    ],
  },

  web: {
    favicon: './assets/favicon.png',
  },

  plugins: [
    'expo-router',
    [
      'expo-camera',
      {
        cameraPermission: 'Allow Psilly Journal to access your camera to scan QR codes.',
      },
    ],
    'expo-secure-store',
  ],

  experiments: {
    typedRoutes: true,
  },

  extra: {
    // Environment configuration
    apiUrl: process.env.API_URL || 'https://journal.originalpsilly.com/api',
    psillyOpsApiUrl: process.env.PSILLYOPS_API_URL || 'https://api.psillyops.com',
  },
});
