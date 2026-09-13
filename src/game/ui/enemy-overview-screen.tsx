import { Image } from 'expo-image';
import { Link } from 'expo-router';
import { useRef, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { getEnemyPreviewSource } from '../core/enemyAssets';
import { ENEMY_DEFINITIONS, GROWTH_START_WAVE } from '../core/enemies';

export function EnemyOverviewScreen() {
  const [tab, setTab] = useState<'active' | 'archive'>('active');
  const list = useRef<ScrollView>(null);
  const enemies = ENEMY_DEFINITIONS.filter((enemy) => (enemy.status === 'active') === (tab === 'active'))
    .sort((a, b) => a.unlockWave - b.unlockWave);
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

        <View style={styles.tabs}>
          {(['active', 'archive'] as const).map((group) => (
            <Pressable key={group} accessibilityRole="tab" accessibilityState={{ selected: tab === group }}
              style={[styles.tab, tab === group && styles.tabSelected]}
              onPress={() => { setTab(group); list.current?.scrollTo({ y: 0, animated: false }); }}>
              <Text style={styles.headerButtonText}>{group === 'active' ? 'Active' : 'Archive'} / {ENEMY_DEFINITIONS.filter((enemy) => (enemy.status === 'active') === (group === 'active')).length}</Text>
            </Pressable>
          ))}
        </View>
        <Text style={styles.enemyDescription}>{tab === 'active' ? 'Four combat roles. A Dreadnought every ten waves.' : 'Archived designs. These enemies do not spawn in this mode.'}</Text>
        <ScrollView ref={list} contentContainerStyle={styles.list}>
          {enemies.map((enemy) => (
            <View key={enemy.id} style={[styles.card, enemy.id === 'void_boss' && styles.bossCard]}>
              <View style={styles.cardHeader}>
                <View style={styles.previewFrame}>
                  <Image
                    accessibilityLabel={enemy.name}
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
                      <Text style={styles.statusText}>{enemy.status !== 'active' ? 'Archive' : enemy.id === 'void_boss' ? 'Every 10 waves' : `Wave ${enemy.unlockWave}+`}</Text>
                    </View>
                  </View>
                  <Text style={styles.enemyRole}>{enemy.role}</Text>
                </View>
              </View>

              <Text style={styles.enemyDescription}>{enemy.description}</Text>
              <View style={styles.panel}>
                <Text style={styles.sectionTitle}>Base combat stats</Text>
                {[
                  ['Hull', enemy.baseStats.hp],
                  ['First impact', enemy.baseStats.contactDamage * 2],
                  ['Contact hit', enemy.baseStats.contactDamage],
                  ...('contactInterval' in enemy.baseStats ? [
                    ['Contact cadence', `${enemy.baseStats.contactInterval}s`],
                  ] : []),
                  ...('flight' in enemy ? [
                    ['Spiral to impact', `${enemy.flight.approachDelaySeconds + enemy.flight.approachSeconds}s`],
                  ] : []),
                  ...("weapon" in enemy ? [
                    [enemy.id === 'void_boss' ? 'Rocket' : 'Railgun', enemy.weapon.projectileDamage],
                    ['Magazine', enemy.weapon.magazine],
                    ['Reload', `${enemy.weapon.reloadSeconds}s`],
                  ] : []),
                  ['Cash / kill', `+${enemy.baseStats.cashReward}`],
                  ['Coins / kill', `+${enemy.baseStats.coinReward}`],
                ].map(([label, value]) => (
                  <View key={label} style={styles.statRow}>
                    <Text style={styles.statLabel}>{label}</Text>
                    <Text style={styles.statValue}>{value}</Text>
                  </View>
                ))}
                <Text style={styles.statLabel}>Before armor and income bonuses. Hull and damage grow after wave {GROWTH_START_WAVE}.</Text>
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
    minHeight: 44,
    justifyContent: 'center',
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
    borderColor: '#264451',
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
    width: 100,
    height: 100,
    overflow: 'hidden',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(251, 146, 60, 0.42)',
    backgroundColor: '#111827',
  },
  preview: {
    width: 96,
    height: 96,
  },
  enemyIntro: {
    flex: 1,
    minWidth: 130,
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
    fontSize: 20,
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
  panel: {
    flex: 1,
    minWidth: 130,
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
  tabs: { flexDirection: 'row', gap: 8 },
  tab: { flex: 1, minHeight: 48, alignItems: 'center', justifyContent: 'center', borderWidth: 1, borderColor: '#264451', borderRadius: 8 },
  tabSelected: { backgroundColor: '#18394b', borderColor: '#67e8f9' },
  bossCard: { borderColor: '#9b653a' },
});
