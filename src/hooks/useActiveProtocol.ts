import { useState, useEffect } from 'react';
import { Q } from '@nozbe/watermelondb';
import database from '../db';
import type Protocol from '../db/models/Protocol';

export function useActiveProtocol() {
  const [protocol, setProtocol] = useState<Protocol | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const subscription = database
      .get<Protocol>('protocols')
      .query(Q.where('status', 'active'))
      .observe()
      .subscribe((protocols) => {
        const active = protocols.find((p) => p.status === 'active');
        setProtocol(active || null);
        setIsLoading(false);
      });

    return () => subscription.unsubscribe();
  }, []);

  return { protocol, isLoading };
}
