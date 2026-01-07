import { Platform } from 'react-native';

export const isWeb = Platform.OS === 'web';
export const isNative = Platform.OS === 'ios' || Platform.OS === 'android';

export function webOnly<T>(webValue: T, nativeValue: T): T {
  return isWeb ? webValue : nativeValue;
}

export function nativeOnly<T>(value: T, fallback: T): T {
  return isNative ? value : fallback;
}
