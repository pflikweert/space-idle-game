import { Image } from 'expo-image';
import { Link } from 'expo-router';
import React, { useCallback, useEffect, useRef, useState } from 'react';
import {
  GestureResponderEvent,
  LayoutChangeEvent,
  Pressable,
  SafeAreaView,
  StyleSheet,
  Text,
  useWindowDimensions,
  View,
} from 'react-native';

import {
  MAX_DELTA_SECONDS,
  PARALLAX_LAYER_HEIGHT,
  PARTICLE_LIFETIME,
  PLAYER_BANKING_THRESHOLD,
  PLAYER_DAMAGED_HP_THRESHOLD,
  PLAYER_HP,
  PLAYER_SPRITE_SIZE,
} from '../core/constants';
import { formatTime } from '../core/math';
import type { PlayfieldSize, WorldInput, WorldSnapshot } from '../core/types';
import { createInitialWorld, createWorldSnapshot } from '../runtime/createInitialWorld';
import { updateWorld } from '../runtime/updateWorld';

const ENEMY_SPRITE_SIZE = 68;

const PARALLAX_LAYERS = [
  {
    id: 'far-stars',
    source: require('@/assets/images/void-drifter/backgrounds/bg_far_stars.png'),
    speed: 12,
    opacity: 0.72,
  },
  {
    id: 'mid-nebula',
    source: require('@/assets/images/void-drifter/backgrounds/bg_mid_nebula.png'),
    speed: 24,
    opacity: 0.34,
  },
  {
    id: 'near-asteroids',
    source: require('@/assets/images/void-drifter/backgrounds/bg_near_asteroids.png'),
    speed: 48,
    opacity: 0.2,
  },
] as const;

const PLAYER_SHIP_SPRITES = {
  idle: require('@/assets/images/void-drifter/player-ship/256/player_ship_idle.png'),
  bankLeft: require('@/assets/images/void-drifter/player-ship/256/player_ship_bank_left.png'),
  bankRight: require('@/assets/images/void-drifter/player-ship/256/player_ship_bank_right.png'),
  damaged: require('@/assets/images/void-drifter/player-ship/256/player_ship_damaged.png'),
} as const;

const RED_SCOUT_DRONE_FRAMES = {
  'move-down': require('@/assets/game/enemies/red-scout-drone/frames/move-down.png'),
  'move-up': require('@/assets/game/enemies/red-scout-drone/frames/move-up.png'),
  'move-left': require('@/assets/game/enemies/red-scout-drone/frames/move-left.png'),
  'move-right': require('@/assets/game/enemies/red-scout-drone/frames/move-right.png'),
} as const;

function getScore(score: number, elapsed: number) {
  return score + Math.floor(elapsed) * 5;
}

function getPlayerShipSprite(snapshot: WorldSnapshot) {
  if (snapshot.player.hp / PLAYER_HP <= PLAYER_DAMAGED_HP_THRESHOLD) {
    return PLAYER_SHIP_SPRITES.damaged;
  }

  if (snapshot.playerVelocityX < -PLAYER_BANKING_THRESHOLD) {
    return PLAYER_SHIP_SPRITES.bankLeft;
  }

  if (snapshot.playerVelocityX > PLAYER_BANKING_THRESHOLD) {
    return PLAYER_SHIP_SPRITES.bankRight;
  }

  return PLAYER_SHIP_SPRITES.idle;
}

export function VoidDrifterPrototypeScreen() {
  const windowSize = useWindowDimensions();
  const animationFrameRef = useRef<number | null>(null);
  const lastFrameTimeRef = useRef<number | null>(null);
  const [playfieldSize, setPlayfieldSize] = useState<PlayfieldSize>({
    width: Math.min(windowSize.width, 980),
    height: Math.max(420, windowSize.height),
  });
  const inputRef = useRef<WorldInput>({ playerTarget: null });
  const gameRef = useRef(createInitialWorld(playfieldSize));
  const [snapshot, setSnapshot] = useState<WorldSnapshot>(() =>
    createWorldSnapshot(gameRef.current)
  );

  const resetToReady = useCallback(() => {
    const freshState = createInitialWorld(playfieldSize, 'ready');
    inputRef.current = { playerTarget: null };
    gameRef.current = freshState;
    setSnapshot(createWorldSnapshot(freshState));
  }, [playfieldSize]);

  const startRun = useCallback(() => {
    const freshState = createInitialWorld(playfieldSize, 'running');
    inputRef.current = { playerTarget: null };
    gameRef.current = freshState;
    setSnapshot(createWorldSnapshot(freshState));
  }, [playfieldSize]);

  useEffect(() => {
    resetToReady();
  }, [resetToReady]);

  useEffect(() => {
    function tick(timestamp: number) {
      if (lastFrameTimeRef.current === null) {
        lastFrameTimeRef.current = timestamp;
      }

      const deltaSeconds = Math.min(
        MAX_DELTA_SECONDS,
        (timestamp - lastFrameTimeRef.current) / 1000
      );
      lastFrameTimeRef.current = timestamp;

      updateWorld(gameRef.current, inputRef.current, deltaSeconds * 1000);
      setSnapshot(createWorldSnapshot(gameRef.current));
      animationFrameRef.current = requestAnimationFrame(tick);
    }

    animationFrameRef.current = requestAnimationFrame(tick);
    return () => {
      if (animationFrameRef.current !== null) {
        cancelAnimationFrame(animationFrameRef.current);
      }
    };
  }, [playfieldSize]);

  function handlePlayfieldLayout(event: LayoutChangeEvent) {
    const { width, height } = event.nativeEvent.layout;
    if (width <= 0 || height <= 0) {
      return;
    }

    setPlayfieldSize((current) => {
      const next = {
        width: Math.round(width),
        height: Math.round(height),
      };

      if (current.width === next.width && current.height === next.height) {
        return current;
      }

      return next;
    });
  }

  const hpPercent = Math.max(0, Math.min(100, (snapshot.player.hp / PLAYER_HP) * 100));
  const playerShipSprite = getPlayerShipSprite(snapshot);
  const parallaxTileHeight = Math.max(PARALLAX_LAYER_HEIGHT, playfieldSize.height);

  function updatePlayerTarget(event: GestureResponderEvent) {
    if (gameRef.current.status !== 'running') {
      return;
    }

    inputRef.current = {
      playerTarget: {
        x: event.nativeEvent.locationX,
        y: event.nativeEvent.locationY,
      },
    };
  }

  return (
    <View style={styles.screen}>
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.header}>
          <View>
            <Text style={styles.kicker}>VOID DRIFTER</Text>
            <Text style={styles.title}>Core Fun Prototype</Text>
          </View>
          <View style={styles.headerActions}>
            <Link href="/void-drifter/enemies" asChild>
              <Pressable style={styles.headerButton}>
                <Text style={styles.headerButtonText}>Enemies</Text>
              </Pressable>
            </Link>
            {snapshot.status !== 'ready' && (
              <Pressable style={styles.headerButton} onPress={startRun}>
                <Text style={styles.headerButtonText}>Restart</Text>
              </Pressable>
            )}
          </View>
        </View>

        <View style={styles.hud}>
          <View style={styles.hudItemWide}>
            <Text style={styles.hudLabel}>HP</Text>
            <View style={styles.hpTrack}>
              <View style={[styles.hpFill, { width: `${hpPercent}%` }]} />
            </View>
            <Text style={styles.hudValue}>{snapshot.player.hp}</Text>
          </View>
          <View style={styles.hudItem}>
            <Text style={styles.hudLabel}>Kills</Text>
            <Text style={styles.hudValue}>{snapshot.kills}</Text>
          </View>
          <View style={styles.hudItem}>
            <Text style={styles.hudLabel}>Time</Text>
            <Text style={styles.hudValue}>{formatTime(snapshot.elapsed)}</Text>
          </View>
          <View style={styles.hudItem}>
            <Text style={styles.hudLabel}>Enemies</Text>
            <Text style={styles.hudValue}>{snapshot.enemies.length}</Text>
          </View>
        </View>

        <View
          testID="void-drifter-playfield"
          style={styles.playfield}
          onLayout={handlePlayfieldLayout}
          onMoveShouldSetResponder={() => snapshot.status === 'running'}
          onResponderGrant={updatePlayerTarget}
          onResponderMove={updatePlayerTarget}
          onStartShouldSetResponder={() => snapshot.status === 'running'}>
          {PARALLAX_LAYERS.map((layer) => {
            const offset = (snapshot.backgroundTime * layer.speed) % parallaxTileHeight;

            return (
              <View key={layer.id} pointerEvents="none" style={styles.parallaxLayer}>
                {[-1, 0].map((tileIndex) => (
                  <Image
                    contentFit="cover"
                    key={`${layer.id}-${tileIndex}`}
                    source={layer.source}
                    style={[
                      styles.parallaxTile,
                      {
                        height: parallaxTileHeight,
                        opacity: layer.opacity,
                        top: offset + tileIndex * parallaxTileHeight,
                      },
                    ]}
                  />
                ))}
              </View>
            );
          })}

          <View pointerEvents="none" style={styles.gameplayReadabilityOverlay} />

          <View style={styles.scanLine} />

          {snapshot.particles.map((particle) => (
            <View
              key={particle.id}
              style={[
                styles.particle,
                {
                  backgroundColor: particle.color,
                  left: particle.x - particle.radius,
                  top: particle.y - particle.radius,
                  width: particle.radius * 2,
                  height: particle.radius * 2,
                  borderRadius: particle.radius,
                  opacity: Math.max(0, particle.life / PARTICLE_LIFETIME),
                },
              ]}
            />
          ))}

          {snapshot.bullets.map((bullet) => (
            <View
              key={bullet.id}
              style={[
                styles.bullet,
                {
                  left: bullet.x - bullet.radius,
                  top: bullet.y - bullet.radius,
                  width: bullet.radius * 2,
                  height: bullet.radius * 2,
                  borderRadius: bullet.radius,
                },
              ]}
            />
          ))}

          {snapshot.enemies.map((enemy) => (
            <View
              key={enemy.id}
              style={[
                styles.enemySpriteWrap,
                {
                  left: enemy.x - ENEMY_SPRITE_SIZE / 2,
                  top: enemy.y - ENEMY_SPRITE_SIZE / 2,
                  width: ENEMY_SPRITE_SIZE,
                  height: ENEMY_SPRITE_SIZE,
                },
              ]}>
              <Image
                contentFit="contain"
                source={RED_SCOUT_DRONE_FRAMES[enemy.movementFrame]}
                style={styles.enemySprite}
              />
            </View>
          ))}

          <View
            testID="void-drifter-player"
            style={[
              styles.player,
              {
                left: snapshot.player.x - PLAYER_SPRITE_SIZE / 2,
                top: snapshot.player.y - PLAYER_SPRITE_SIZE / 2,
                width: PLAYER_SPRITE_SIZE,
                height: PLAYER_SPRITE_SIZE,
              },
            ]}>
            <Image
              contentFit="contain"
              source={playerShipSprite}
              style={styles.playerSprite}
              testID="void-drifter-player-sprite"
            />
          </View>

          {snapshot.status === 'ready' && (
            <View style={styles.startOverlay}>
              <Text style={styles.startTitle}>VOID DRIFTER</Text>
              <Text style={styles.startSubtitle}>
                Survive the sector. Your ship fires automatically.
              </Text>
              <Text style={styles.startHint}>
                Click or drag to steer. Weapons auto-target the nearest enemy.
              </Text>
              <Pressable
                testID="void-drifter-start-run"
                style={styles.startButton}
                onPress={startRun}>
                <Text style={styles.startButtonText}>Start Run</Text>
              </Pressable>
            </View>
          )}

          {snapshot.status === 'dead' && (
            <View style={styles.deathOverlay}>
              <Text style={styles.deathKicker}>Run ended</Text>
              <Text style={styles.deathTitle}>Signal Lost</Text>
              <View style={styles.deathStatsRow}>
                <View style={styles.deathStat}>
                  <Text style={styles.deathStatLabel}>Kills</Text>
                  <Text style={styles.deathStatValue}>{snapshot.kills}</Text>
                </View>
                <View style={styles.deathStat}>
                  <Text style={styles.deathStatLabel}>Survived</Text>
                  <Text style={styles.deathStatValue}>{formatTime(snapshot.elapsed)}</Text>
                </View>
                <View style={styles.deathStat}>
                  <Text style={styles.deathStatLabel}>Score</Text>
                  <Text style={styles.deathStatValue}>
                    {getScore(snapshot.score, snapshot.elapsed)}
                  </Text>
                </View>
              </View>
              <Pressable style={styles.deathButton} onPress={startRun}>
                <Text style={styles.deathButtonText}>Restart Run</Text>
              </Pressable>
            </View>
          )}
        </View>
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
    gap: 12,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 12,
  },
  kicker: {
    color: '#22d3ee',
    fontSize: 12,
    fontWeight: '800',
    letterSpacing: 1.8,
  },
  title: {
    color: '#f8fafc',
    fontSize: 24,
    fontWeight: '800',
  },
  headerActions: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'flex-end',
    gap: 8,
  },
  headerButton: {
    borderWidth: 1,
    borderColor: 'rgba(103, 232, 249, 0.46)',
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 10,
    backgroundColor: 'rgba(8, 47, 73, 0.6)',
  },
  headerButtonText: {
    color: '#cffafe',
    fontSize: 13,
    fontWeight: '800',
  },
  hud: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  hudItem: {
    minWidth: 92,
    flexGrow: 1,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(148, 163, 184, 0.22)',
    backgroundColor: 'rgba(15, 23, 42, 0.82)',
    paddingHorizontal: 12,
    paddingVertical: 10,
    gap: 4,
  },
  hudItemWide: {
    minWidth: 160,
    flexGrow: 2,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(148, 163, 184, 0.22)',
    backgroundColor: 'rgba(15, 23, 42, 0.82)',
    paddingHorizontal: 12,
    paddingVertical: 10,
    gap: 5,
  },
  hudLabel: {
    color: '#94a3b8',
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 1.2,
    textTransform: 'uppercase',
  },
  hudValue: {
    color: '#f8fafc',
    fontSize: 18,
    fontWeight: '800',
  },
  hpTrack: {
    height: 6,
    overflow: 'hidden',
    borderRadius: 6,
    backgroundColor: 'rgba(15, 23, 42, 0.94)',
  },
  hpFill: {
    height: '100%',
    borderRadius: 6,
    backgroundColor: '#22c55e',
  },
  playfield: {
    flex: 1,
    minHeight: 420,
    overflow: 'hidden',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(125, 211, 252, 0.28)',
    backgroundColor: '#050816',
  },
  parallaxLayer: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    overflow: 'hidden',
    right: 0,
    top: 0,
  },
  parallaxTile: {
    left: 0,
    position: 'absolute',
    right: 0,
    width: '100%',
  },
  gameplayReadabilityOverlay: {
    backgroundColor: 'rgba(2, 6, 23, 0.38)',
    bottom: 0,
    left: 0,
    position: 'absolute',
    right: 0,
    top: 0,
  },
  scanLine: {
    position: 'absolute',
    left: 0,
    right: 0,
    top: '68%',
    height: 1,
    backgroundColor: 'rgba(34, 211, 238, 0.18)',
  },
  bullet: {
    position: 'absolute',
    backgroundColor: '#67e8f9',
    borderWidth: 1,
    borderColor: '#ecfeff',
  },
  enemySpriteWrap: {
    position: 'absolute',
    alignItems: 'center',
    justifyContent: 'center',
    opacity: 0.94,
  },
  enemySprite: {
    width: ENEMY_SPRITE_SIZE,
    height: ENEMY_SPRITE_SIZE,
  },
  particle: {
    position: 'absolute',
  },
  player: {
    position: 'absolute',
    alignItems: 'center',
    justifyContent: 'center',
  },
  playerSprite: {
    width: PLAYER_SPRITE_SIZE,
    height: PLAYER_SPRITE_SIZE,
    transform: [{ rotate: '180deg' }],
  },
  startOverlay: {
    position: 'absolute',
    left: 18,
    right: 18,
    top: '24%',
    alignItems: 'center',
    gap: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(34, 211, 238, 0.42)',
    backgroundColor: 'rgba(2, 6, 23, 0.9)',
    paddingHorizontal: 24,
    paddingVertical: 30,
  },
  startTitle: {
    color: '#f8fafc',
    fontSize: 34,
    fontWeight: '900',
    letterSpacing: 1.6,
    textAlign: 'center',
  },
  startSubtitle: {
    color: '#cbd5e1',
    fontSize: 16,
    fontWeight: '700',
    lineHeight: 22,
    maxWidth: 420,
    textAlign: 'center',
  },
  startHint: {
    color: '#67e8f9',
    fontSize: 13,
    fontWeight: '700',
    lineHeight: 19,
    maxWidth: 430,
    textAlign: 'center',
  },
  startButton: {
    marginTop: 6,
    borderRadius: 8,
    backgroundColor: '#22d3ee',
    paddingHorizontal: 22,
    paddingVertical: 13,
  },
  startButtonText: {
    color: '#082f49',
    fontSize: 15,
    fontWeight: '900',
  },
  deathOverlay: {
    position: 'absolute',
    left: 18,
    right: 18,
    top: '28%',
    alignItems: 'center',
    gap: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(248, 113, 113, 0.42)',
    backgroundColor: 'rgba(2, 6, 23, 0.92)',
    paddingHorizontal: 24,
    paddingVertical: 28,
  },
  deathKicker: {
    color: '#fca5a5',
    fontSize: 12,
    fontWeight: '800',
    letterSpacing: 1.6,
    textTransform: 'uppercase',
  },
  deathTitle: {
    color: '#f8fafc',
    fontSize: 30,
    fontWeight: '900',
    textAlign: 'center',
  },
  deathStats: {
    color: '#cbd5e1',
    fontSize: 16,
    fontWeight: '700',
  },
  deathStatsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: 10,
    width: '100%',
  },
  deathStat: {
    minWidth: 96,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(148, 163, 184, 0.2)',
    backgroundColor: 'rgba(15, 23, 42, 0.72)',
    paddingHorizontal: 12,
    paddingVertical: 10,
    alignItems: 'center',
    gap: 3,
  },
  deathStatLabel: {
    color: '#94a3b8',
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 1.1,
    textTransform: 'uppercase',
  },
  deathStatValue: {
    color: '#f8fafc',
    fontSize: 17,
    fontWeight: '900',
  },
  deathButton: {
    marginTop: 4,
    borderRadius: 8,
    backgroundColor: '#22d3ee',
    paddingHorizontal: 18,
    paddingVertical: 12,
  },
  deathButtonText: {
    color: '#082f49',
    fontSize: 15,
    fontWeight: '900',
  },
});
