import { useState, useEffect, useCallback } from 'react';
import type { Protocol, Dose } from '../db/localStorageDB';
import { logDose, deleteDose, getDoseCountToday } from '../services/doseService';

interface UseDoseTrackingResult {
  doseCountToday: number;
  isLogging: boolean;
  lastDose: Dose | null;
  handleLogDose: () => Promise<void>;
  handleUndo: () => Promise<void>;
}

export function useDoseTracking(protocol: Protocol | null): UseDoseTrackingResult {
  const [doseCountToday, setDoseCountToday] = useState(0);
  const [isLogging, setIsLogging] = useState(false);
  const [lastDose, setLastDose] = useState<Dose | null>(null);

  // Load dose count on mount and when protocol changes
  useEffect(() => {
    if (protocol) {
      getDoseCountToday(protocol.id).then(setDoseCountToday);
    }
  }, [protocol?.id]);

  const handleLogDose = useCallback(async () => {
    if (!protocol) return;

    setIsLogging(true);
    try {
      const dose = await logDose(protocol);
      setLastDose(dose);
      setDoseCountToday((prev) => prev + 1);
    } catch (error) {
      console.error('Failed to log dose:', error);
      throw error;
    } finally {
      setIsLogging(false);
    }
  }, [protocol]);

  const handleUndo = useCallback(async () => {
    if (!lastDose) return;

    try {
      await deleteDose(lastDose.id);
      setLastDose(null);
      setDoseCountToday((prev) => Math.max(0, prev - 1));
    } catch (error) {
      console.error('Failed to undo dose:', error);
    }
  }, [lastDose]);

  return {
    doseCountToday,
    isLogging,
    lastDose,
    handleLogDose,
    handleUndo,
  };
}
