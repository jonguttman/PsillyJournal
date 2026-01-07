import { useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { useRouter } from 'expo-router';
import { useAppStore, selectNeedsOnboarding, selectHasActiveProtocol } from '../src/store/appStore';
import { getActiveProtocol } from '../src/services/bottleService';

export default function HomeScreen() {
  const router = useRouter();
  const { 
    isLoading, 
    activeProtocol, 
    pendingBottle,
    setActiveProtocol,
    setLoading 
  } = useAppStore();
  
  const needsOnboarding = useAppStore(selectNeedsOnboarding);
  const hasActiveProtocol = useAppStore(selectHasActiveProtocol);

  // Load active protocol on mount
  useEffect(() => {
    loadActiveProtocol();
  }, []);

  // Handle pending bottle from deep link
  useEffect(() => {
    if (pendingBottle) {
      router.push('/onboarding');
    }
  }, [pendingBottle]);

  const loadActiveProtocol = async () => {
    try {
      const protocol = await getActiveProtocol();
      if (protocol) {
        setActiveProtocol({
          id: protocol.id,
          sessionId: protocol.sessionId,
          productId: protocol.productId,
          productName: protocol.productName,
          currentDay: protocol.currentDay,
          totalDays: protocol.totalDays,
          status: protocol.status,
        });
      }
    } catch (error) {
      console.error('Failed to load protocol:', error);
    } finally {
      setLoading(false);
    }
  };

  if (isLoading) {
    return (
      <View style={styles.container}>
        <Text style={styles.loadingText}>Loading...</Text>
      </View>
    );
  }

  // No active protocol - show onboarding prompt
  if (needsOnboarding) {
    return (
      <View style={styles.container}>
        <View style={styles.content}>
          <Text style={styles.title}>Psilly Journal</Text>
          <Text style={styles.subtitle}>Your private microdosing companion</Text>
          
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Get Started</Text>
            <Text style={styles.cardText}>
              Scan the QR code on your Psilly bottle to begin your journaling journey.
            </Text>
            
            <TouchableOpacity 
              style={styles.primaryButton}
              onPress={() => router.push('/scan')}
            >
              <Text style={styles.primaryButtonText}>Scan Bottle</Text>
            </TouchableOpacity>
          </View>
          
          <TouchableOpacity 
            style={styles.linkButton}
            onPress={() => router.push('/settings')}
          >
            <Text style={styles.linkText}>Restore from recovery key</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  }

  // Has active protocol - show journal home
  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Psilly Journal</Text>
        <TouchableOpacity onPress={() => router.push('/settings')}>
          <Text style={styles.settingsIcon}>⚙️</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.content}>
        {/* Protocol Summary Card */}
        <View style={styles.card}>
          <Text style={styles.productName}>{activeProtocol?.productName}</Text>
          <Text style={styles.dayCounter}>
            Day {activeProtocol?.currentDay} of {activeProtocol?.totalDays}
          </Text>
          
          {/* Progress Bar */}
          <View style={styles.progressBar}>
            <View 
              style={[
                styles.progressFill, 
                { width: `${((activeProtocol?.currentDay || 0) / (activeProtocol?.totalDays || 30)) * 100}%` }
              ]} 
            />
          </View>
        </View>

        {/* Quick Actions */}
        <View style={styles.actionsContainer}>
          <TouchableOpacity 
            style={styles.actionButton}
            onPress={() => router.push('/scan')}
          >
            <Text style={styles.actionIcon}>📷</Text>
            <Text style={styles.actionText}>Log Dose</Text>
          </TouchableOpacity>

          <TouchableOpacity 
            style={styles.actionButton}
            onPress={() => router.push('/entry')}
          >
            <Text style={styles.actionIcon}>✏️</Text>
            <Text style={styles.actionText}>New Entry</Text>
          </TouchableOpacity>
        </View>

        {/* View Journal */}
        <TouchableOpacity 
          style={styles.secondaryButton}
          onPress={() => router.push('/journal')}
        >
          <Text style={styles.secondaryButtonText}>View Journal</Text>
        </TouchableOpacity>
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
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 60,
    paddingBottom: 20,
  },
  headerTitle: {
    color: '#ffffff',
    fontSize: 24,
    fontWeight: '700',
  },
  settingsIcon: {
    fontSize: 24,
  },
  content: {
    flex: 1,
    paddingHorizontal: 20,
    paddingTop: 40,
  },
  title: {
    color: '#ffffff',
    fontSize: 32,
    fontWeight: '700',
    textAlign: 'center',
    marginBottom: 8,
  },
  subtitle: {
    color: '#a1a1aa',
    fontSize: 16,
    textAlign: 'center',
    marginBottom: 48,
  },
  card: {
    backgroundColor: '#18181b',
    borderRadius: 16,
    padding: 24,
    marginBottom: 24,
  },
  cardTitle: {
    color: '#ffffff',
    fontSize: 20,
    fontWeight: '600',
    marginBottom: 8,
  },
  cardText: {
    color: '#a1a1aa',
    fontSize: 16,
    lineHeight: 24,
    marginBottom: 24,
  },
  productName: {
    color: '#8b5cf6',
    fontSize: 14,
    fontWeight: '600',
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginBottom: 8,
  },
  dayCounter: {
    color: '#ffffff',
    fontSize: 28,
    fontWeight: '700',
    marginBottom: 16,
  },
  progressBar: {
    height: 8,
    backgroundColor: '#27272a',
    borderRadius: 4,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: '#8b5cf6',
    borderRadius: 4,
  },
  actionsContainer: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 24,
  },
  actionButton: {
    flex: 1,
    backgroundColor: '#18181b',
    borderRadius: 12,
    padding: 20,
    alignItems: 'center',
  },
  actionIcon: {
    fontSize: 28,
    marginBottom: 8,
  },
  actionText: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: '500',
  },
  primaryButton: {
    backgroundColor: '#8b5cf6',
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
  },
  primaryButtonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '600',
  },
  secondaryButton: {
    borderWidth: 1,
    borderColor: '#27272a',
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
  },
  secondaryButtonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '500',
  },
  linkButton: {
    alignItems: 'center',
    padding: 16,
  },
  linkText: {
    color: '#8b5cf6',
    fontSize: 14,
  },
  loadingText: {
    color: '#a1a1aa',
    fontSize: 16,
    textAlign: 'center',
    marginTop: 100,
  },
});
