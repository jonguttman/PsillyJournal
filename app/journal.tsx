import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';

export default function JournalScreen() {
  const router = useRouter();

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <Text style={styles.backText}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.title}>Journal</Text>
        <View style={styles.placeholder} />
      </View>

      <View style={styles.content}>
        <Text style={styles.emptyText}>Your journal entries will appear here.</Text>
        <TouchableOpacity style={styles.button} onPress={() => router.push('/entry')}>
          <Text style={styles.buttonText}>Write First Entry</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0a0a0a' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 20, paddingTop: 60, paddingBottom: 20 },
  backText: { color: '#8b5cf6', fontSize: 16 },
  title: { color: '#ffffff', fontSize: 18, fontWeight: '600' },
  placeholder: { width: 50 },
  content: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 24 },
  emptyText: { color: '#a1a1aa', fontSize: 16, marginBottom: 24 },
  button: { backgroundColor: '#8b5cf6', paddingVertical: 14, paddingHorizontal: 24, borderRadius: 12 },
  buttonText: { color: '#ffffff', fontSize: 16, fontWeight: '600' },
});
