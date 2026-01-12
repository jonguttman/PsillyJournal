import { useState, useEffect } from 'react';
import { localStorageDB, type Protocol } from '../db/localStorageDB';

export function useActiveProtocol() {
  const [protocol, setProtocol] = useState<Protocol | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Load active protocol on mount
    const loadProtocol = async () => {
      const protocols = await localStorageDB.protocols.query(p => p.status === 'active');
      const active = protocols.length > 0 ? protocols[0] : null;
      setProtocol(active);
      setIsLoading(false);
    };

    loadProtocol();

    // Poll for changes every 2 seconds (simple approach for localStorage)
    // In a production app, you might want to use a more sophisticated state management
    const interval = setInterval(loadProtocol, 2000);

    return () => clearInterval(interval);
  }, []);

  return { protocol, isLoading };
}
