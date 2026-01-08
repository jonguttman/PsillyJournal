import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, SafeAreaView, ScrollView } from 'react-native';
import { useRouter } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import {
  ProtocolCard,
  DoseButton,
  DoseSuccessToast,
  ConfirmDoseModal,
  EmptyProtocolCard,
} from '../src/components';
import { useActiveProtocol, useDoseTracking } from '../src/hooks';

export default function HomeScreen() {
  const router = useRouter();
  const { protocol, isLoading } = useActiveProtocol();
  const { doseCountToday, isLogging, lastDose, handleLogDose, handleUndo } = useDoseTracking(protocol);

  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [showSuccessToast, setShowSuccessToast] = useState(false);
  const [lastDoseTime, setLastDoseTime] = useState<Date | null>(null);

  const onDosePress = () => {
    if (doseCountToday > 0) {
      setShowConfirmModal(true);
    } else {
      confirmDose();
    }
  };

  const confirmDose = async () => {
    setShowConfirmModal(false);
    try {
      await handleLogDose();
      setLastDoseTime(new Date());
      setShowSuccessToast(true);
    } catch (error) {
      // TODO: Show error toast
      console.error(error);
    }
  };

  const onUndo = async () => {
    setShowSuccessToast(false);
    await handleUndo();
  };

  if (isLoading) {
    return (
      <SafeAreaView style={styles.container}>
        <StatusBar style="light" />
        <View style={styles.loading}>
          <Text style={styles.loadingText}>Loading...</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar style="light" />

      <ScrollView style={styles.scroll} contentContainerStyle={styles.content}>
        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.title}>Psilly Journal</Text>
          <TouchableOpacity onPress={() => router.push('/settings')}>
            <Text style={styles.settingsIcon}>⚙️</Text>
          </TouchableOpacity>
        </View>

        {/* Protocol Card or Empty State */}
        {protocol ? (
          <>
            <ProtocolCard
              productName={protocol.productName}
              currentDay={protocol.currentDay}
              totalDays={protocol.totalDays}
            />

            {/* Dose Button */}
            <DoseButton
              onPress={onDosePress}
              isLoading={isLogging}
              hasLoggedToday={doseCountToday > 0}
            />

            {/* Quick Actions */}
            <View style={styles.actions}>
              <TouchableOpacity
                style={styles.actionButton}
                onPress={() => router.push('/scan')}
              >
                <Text style={styles.actionIcon}>📷</Text>
                <Text style={styles.actionText}>Scan Bottle</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.actionButton}
                onPress={() => router.push('/entry')}
              >
                <Text style={styles.actionIcon}>✏️</Text>
                <Text style={styles.actionText}>New Entry</Text>
              </TouchableOpacity>
            </View>

            {/* Recent Entries Section */}
            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <Text style={styles.sectionTitle}>Recent Entries</Text>
                <TouchableOpacity onPress={() => router.push('/journal')}>
                  <Text style={styles.viewAll}>View All →</Text>
                </TouchableOpacity>
              </View>
              <View style={styles.emptyEntries}>
                <Text style={styles.emptyText}>No entries yet</Text>
                <Text style={styles.emptySubtext}>
                  Tap "New Entry" to record your first reflection
                </Text>
              </View>
            </View>
          </>
        ) : (
          <EmptyProtocolCard onScanPress={() => router.push('/scan')} />
        )}
      </ScrollView>

      {/* Confirm Modal */}
      <ConfirmDoseModal
        visible={showConfirmModal}
        doseCount={doseCountToday}
        onConfirm={confirmDose}
        onCancel={() => setShowConfirmModal(false)}
      />

      {/* Success Toast */}
      <DoseSuccessToast
        visible={showSuccessToast}
        timestamp={lastDoseTime || new Date()}
        onUndo={onUndo}
        onDismiss={() => setShowSuccessToast(false)}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0a',
  },
  scroll: {
    flex: 1,
  },
  content: {
    padding: 20,
    paddingTop: 10,
  },
  loading: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    color: '#a1a1aa',
    fontSize: 16,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 24,
  },
  title: {
    color: '#ffffff',
    fontSize: 24,
    fontWeight: '700',
  },
  settingsIcon: {
    fontSize: 24,
  },
  actions: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 24,
  },
  actionButton: {
    flex: 1,
    backgroundColor: '#18181b',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    gap: 8,
  },
  actionIcon: {
    fontSize: 24,
  },
  actionText: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: '500',
  },
  section: {
    marginTop: 8,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  sectionTitle: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '600',
  },
  viewAll: {
    color: '#8b5cf6',
    fontSize: 14,
  },
  emptyEntries: {
    backgroundColor: '#18181b',
    borderRadius: 12,
    padding: 24,
    alignItems: 'center',
  },
  emptyText: {
    color: '#a1a1aa',
    fontSize: 16,
    marginBottom: 4,
  },
  emptySubtext: {
    color: '#71717a',
    fontSize: 14,
    textAlign: 'center',
  },
});
