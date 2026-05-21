import { Link } from 'expo-router';
import { StyleSheet, Pressable, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { ENCOUNTER_SECONDS, GAME_COPY } from '@/game/core/prototype-content';
import { usePrototypeGameState } from '@/game/state/use-prototype-game-state';

export function SpaceIdleHomeScreen() {
  const { resources, scanSector, upgradeShip } = usePrototypeGameState();

  return (
    <View style={styles.screen}>
      <View style={styles.backgroundGlowTop} />
      <View style={styles.backgroundGlowBottom} />

      <SafeAreaView style={styles.safeArea}>
        <View style={styles.hero}>
          <Text style={styles.kicker}>Prototype foundation</Text>
          <Text style={styles.title}>{GAME_COPY.title}</Text>
          <Text style={styles.subtitle}>{GAME_COPY.subtitle}</Text>
        </View>

        <View style={styles.shipCard}>
          <Text style={styles.shipLabel}>Scout vessel</Text>
          <View style={styles.shipVisual}>
            <View style={styles.shipCore} />
            <View style={styles.shipWingLeft} />
            <View style={styles.shipWingRight} />
          </View>
          <Text style={styles.shipStatus}>Systems nominal. Quiet signal traffic detected.</Text>
        </View>

        <View style={styles.statsRow}>
          <View style={styles.statCard}>
            <Text style={styles.statLabel}>{GAME_COPY.resourceLabel}</Text>
            <Text style={styles.statValue}>{resources}</Text>
          </View>
          <View style={styles.statCard}>
            <Text style={styles.statLabel}>{GAME_COPY.encounterLabel}</Text>
            <Text style={styles.statValue}>{ENCOUNTER_SECONDS}s</Text>
          </View>
        </View>

        <View style={styles.actions}>
          <Link href="/void-drifter" asChild>
            <Pressable style={styles.voidButton}>
              <Text style={styles.voidButtonText}>Open VOID DRIFTER</Text>
            </Pressable>
          </Link>

          <Pressable style={styles.primaryButton} onPress={scanSector}>
            <Text style={styles.primaryButtonText}>{GAME_COPY.scanLabel}</Text>
          </Pressable>

          <Pressable style={styles.secondaryButton} onPress={upgradeShip}>
            <Text style={styles.secondaryButtonText}>{GAME_COPY.upgradeLabel}</Text>
          </Pressable>
        </View>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: '#050816',
  },
  backgroundGlowTop: {
    position: 'absolute',
    top: -120,
    right: -60,
    width: 260,
    height: 260,
    borderRadius: 999,
    backgroundColor: '#1e3a8a',
    opacity: 0.18,
  },
  backgroundGlowBottom: {
    position: 'absolute',
    bottom: -120,
    left: -40,
    width: 220,
    height: 220,
    borderRadius: 999,
    backgroundColor: '#0f766e',
    opacity: 0.14,
  },
  safeArea: {
    flex: 1,
    paddingHorizontal: 24,
    paddingVertical: 20,
    gap: 24,
    justifyContent: 'center',
  },
  hero: {
    gap: 10,
  },
  kicker: {
    color: '#7dd3fc',
    fontSize: 12,
    textTransform: 'uppercase',
    letterSpacing: 2,
  },
  title: {
    color: '#f8fafc',
    fontSize: 36,
    fontWeight: '700',
    lineHeight: 42,
  },
  subtitle: {
    color: '#cbd5e1',
    fontSize: 16,
    lineHeight: 24,
    maxWidth: 520,
  },
  shipCard: {
    backgroundColor: 'rgba(15, 23, 42, 0.78)',
    borderRadius: 24,
    padding: 24,
    gap: 16,
  },
  shipLabel: {
    color: '#93c5fd',
    fontSize: 14,
    fontWeight: '600',
    textTransform: 'uppercase',
    letterSpacing: 1.4,
  },
  shipVisual: {
    height: 120,
    alignItems: 'center',
    justifyContent: 'center',
  },
  shipCore: {
    width: 84,
    height: 30,
    borderRadius: 18,
    backgroundColor: '#e2e8f0',
  },
  shipWingLeft: {
    position: 'absolute',
    left: '24%',
    width: 28,
    height: 10,
    borderRadius: 10,
    backgroundColor: '#7dd3fc',
    transform: [{ rotate: '-22deg' }],
  },
  shipWingRight: {
    position: 'absolute',
    right: '24%',
    width: 28,
    height: 10,
    borderRadius: 10,
    backgroundColor: '#7dd3fc',
    transform: [{ rotate: '22deg' }],
  },
  shipStatus: {
    color: '#94a3b8',
    fontSize: 14,
    lineHeight: 20,
  },
  statsRow: {
    flexDirection: 'row',
    gap: 16,
  },
  statCard: {
    flex: 1,
    backgroundColor: 'rgba(15, 23, 42, 0.82)',
    borderRadius: 20,
    padding: 20,
    gap: 8,
  },
  statLabel: {
    color: '#94a3b8',
    fontSize: 13,
    textTransform: 'uppercase',
    letterSpacing: 1.2,
  },
  statValue: {
    color: '#f8fafc',
    fontSize: 28,
    fontWeight: '700',
  },
  actions: {
    gap: 14,
  },
  voidButton: {
    backgroundColor: '#22d3ee',
    borderRadius: 18,
    paddingVertical: 18,
    alignItems: 'center',
  },
  voidButtonText: {
    color: '#082f49',
    fontSize: 16,
    fontWeight: '800',
  },
  primaryButton: {
    backgroundColor: '#e879f9',
    borderRadius: 18,
    paddingVertical: 18,
    alignItems: 'center',
  },
  primaryButtonText: {
    color: '#0f172a',
    fontSize: 16,
    fontWeight: '700',
  },
  secondaryButton: {
    backgroundColor: '#172033',
    borderRadius: 18,
    paddingVertical: 18,
    alignItems: 'center',
  },
  secondaryButtonText: {
    color: '#e2e8f0',
    fontSize: 16,
    fontWeight: '600',
  },
});
