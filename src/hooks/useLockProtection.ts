import { useEffect } from 'react';
import { useRouter, usePathname } from 'expo-router';
import { useAppStore, selectIsLocked } from '../store/appStore';

/**
 * Hook to protect routes from being accessed when journal is locked
 * Redirects to lock screen if journal is locked
 */
export function useLockProtection() {
  const router = useRouter();
  const pathname = usePathname();
  const isLocked = useAppStore(selectIsLocked);

  useEffect(() => {
    // Allow access to lock and scan screens even when locked
    const allowedPaths = ['/lock', '/scan'];
    const isAllowedPath = allowedPaths.some(path => pathname?.startsWith(path));

    if (isLocked && !isAllowedPath) {
      // Journal is locked and user is trying to access protected route
      router.replace('/lock');
    }
  }, [isLocked, pathname]);

  return { isLocked };
}
