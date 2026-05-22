import { Image } from 'expo-image';
import { Link } from 'expo-router';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { getEnemyPreviewSource } from '../core/enemyAssets';
import { ENEMY_DEFINITIONS } from '../core/enemies';

function formatStatLabel(label: string) {
  return label.replace(/([A-Z])/g, ' $1').trim();
}

function formatAbility(ability: string) {
  return ability.replaceAll('_', ' ');
}

export function EnemyOverviewScreen() {
  return (
    <View style={styles.screen}>
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.header}>
          <View>
            <Text style={styles.kicker}>VOID DRIFTER</Text>
            <Text style={styles.title}>Enemy Codex</Text>
          </View>
          <Link href="/void-drifter" asChild>
            <Pressable style={styles.headerButton}>
              <Text style={styles.headerButtonText}>Back</Text>
            </Pressable>
          </Link>
        </View>

        <ScrollView contentContainerStyle={styles.list}>
          {ENEMY_DEFINITIONS.map((enemy) => (
            <View key={enemy.id} style={styles.card}>
              <View style={styles.cardHeader}>
                <View style={styles.previewFrame}>
                  <View style={styles.previewGlow} />
                  <Image
                    contentFit="contain"
                    source={getEnemyPreviewSource(enemy.id)}
                    style={styles.preview}
                  />
                </View>
                <View style={styles.enemyIntro}>
                  <View style={styles.titleRow}>
                    <Text style={styles.enemyName}>{enemy.name}</Text>
                    <View
                      style={[
                        styles.statusPill,
                        enemy.status === 'active' ? styles.statusActive : styles.statusLocked,
                      ]}>
                      <Text style={styles.statusText}>{enemy.status}</Text>
                    </View>
                  </View>
                  <Text style={styles.enemyRole}>{enemy.role}</Text>
                  <Text style={styles.enemyDescription}>{enemy.description}</Text>
                </View>
              </View>

              <View style={styles.sectionGrid}>
                <View style={styles.panel}>
                  <Text style={styles.sectionTitle}>Base Stats</Text>
                  {Object.entries(enemy.baseStats).map(([label, value]) => (
                    <View key={label} style={styles.statRow}>
                      <Text style={styles.statLabel}>{formatStatLabel(label)}</Text>
                      <Text style={styles.statValue}>{value}</Text>
                    </View>
                  ))}
                </View>

                <View style={styles.panel}>
                  <Text style={styles.sectionTitle}>Scaling</Text>
                  {Object.entries(enemy.scaling).map(([label, value]) => (
                    <View key={label} style={styles.statRow}>
                      <Text style={styles.statLabel}>{formatStatLabel(label)}</Text>
                      <Text style={styles.statValue}>+{value}/level</Text>
                    </View>
                  ))}
                </View>
              </View>

              <View style={styles.sectionGrid}>
                <View style={styles.panel}>
                  <Text style={styles.sectionTitle}>Spawn</Text>
                  <View style={styles.statRow}>
                    <Text style={styles.statLabel}>XP / Coins / Score</Text>
                    <Text style={styles.statValue}>
                      {enemy.baseStats.xpReward} / {enemy.baseStats.coinReward} /{' '}
                      {enemy.baseStats.scoreReward}
                    </Text>
                  </View>
                  <View style={styles.statRow}>
                    <Text style={styles.statLabel}>Unlock Wave</Text>
                    <Text style={styles.statValue}>{enemy.unlockWave}</Text>
                  </View>
                  <View style={styles.statRow}>
                    <Text style={styles.statLabel}>Weight</Text>
                    <Text style={styles.statValue}>{enemy.spawn.weight}</Text>
                  </View>
                </View>

                <View style={styles.panel}>
                  <Text style={styles.sectionTitle}>Abilities</Text>
                  <View style={styles.abilityList}>
                    {enemy.abilities.map((ability) => (
                      <View key={ability} style={styles.abilityPill}>
                        <Text style={styles.abilityText}>{formatAbility(ability)}</Text>
                      </View>
                    ))}
                  </View>
                </View>
              </View>
            </View>
          ))}
        </ScrollView>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: '#030712',
  },
  safeArea: {
    flex: 1,
    paddingHorizontal: 16,
    paddingVertical: 14,
    gap: 14,
  },
  header: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: 12,
    justifyContent: 'space-between',
  },
  kicker: {
    color: '#22d3ee',
    fontSize: 12,
    fontWeight: '800',
    letterSpacing: 1.8,
  },
  title: {
    color: '#f8fafc',
    fontSize: 28,
    fontWeight: '900',
  },
  headerButton: {
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(103, 232, 249, 0.46)',
    backgroundColor: 'rgba(8, 47, 73, 0.6)',
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  headerButtonText: {
    color: '#cffafe',
    fontSize: 13,
    fontWeight: '800',
  },
  list: {
    gap: 14,
    paddingBottom: 20,
  },
  card: {
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(248, 113, 113, 0.34)',
    backgroundColor: 'rgba(15, 23, 42, 0.9)',
    gap: 14,
    padding: 16,
  },
  cardHeader: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 14,
  },
  previewFrame: {
    alignItems: 'center',
    justifyContent: 'center',
    width: 172,
    height: 172,
    overflow: 'hidden',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(251, 146, 60, 0.42)',
    backgroundColor: '#111827',
  },
  previewGlow: {
    position: 'absolute',
    width: 118,
    height: 118,
    borderRadius: 59,
    backgroundColor: 'rgba(248, 113, 113, 0.18)',
  },
  preview: {
    width: 164,
    height: 164,
  },
  enemyIntro: {
    flex: 1,
    minWidth: 220,
    gap: 6,
  },
  titleRow: {
    alignItems: 'center',
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  enemyName: {
    color: '#f8fafc',
    fontSize: 24,
    fontWeight: '900',
  },
  statusPill: {
    borderRadius: 8,
    borderWidth: 1,
    paddingHorizontal: 9,
    paddingVertical: 5,
  },
  statusActive: {
    borderColor: 'rgba(34, 197, 94, 0.5)',
    backgroundColor: 'rgba(22, 101, 52, 0.34)',
  },
  statusLocked: {
    borderColor: 'rgba(148, 163, 184, 0.32)',
    backgroundColor: 'rgba(51, 65, 85, 0.42)',
  },
  statusText: {
    color: '#f8fafc',
    fontSize: 11,
    fontWeight: '900',
    textTransform: 'uppercase',
  },
  enemyRole: {
    color: '#fca5a5',
    fontSize: 13,
    fontWeight: '800',
    letterSpacing: 1,
    textTransform: 'uppercase',
  },
  enemyDescription: {
    color: '#cbd5e1',
    fontSize: 15,
    lineHeight: 22,
  },
  sectionGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
  },
  panel: {
    flex: 1,
    minWidth: 220,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(148, 163, 184, 0.2)',
    backgroundColor: 'rgba(2, 6, 23, 0.52)',
    gap: 8,
    padding: 12,
  },
  sectionTitle: {
    color: '#67e8f9',
    fontSize: 12,
    fontWeight: '900',
    letterSpacing: 1.1,
    textTransform: 'uppercase',
  },
  statRow: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 12,
  },
  statLabel: {
    color: '#94a3b8',
    flex: 1,
    fontSize: 13,
    textTransform: 'capitalize',
  },
  statValue: {
    color: '#f8fafc',
    fontSize: 14,
    fontWeight: '800',
  },
  abilityList: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  abilityPill: {
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(248, 113, 113, 0.36)',
    backgroundColor: 'rgba(127, 29, 29, 0.26)',
    paddingHorizontal: 10,
    paddingVertical: 7,
  },
  abilityText: {
    color: '#fecaca',
    fontSize: 12,
    fontWeight: '800',
    textTransform: 'uppercase',
  },
});
