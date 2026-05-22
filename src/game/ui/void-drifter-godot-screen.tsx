import { Link } from 'expo-router';
import React, { useEffect, useState } from 'react';
import { Platform, Pressable, SafeAreaView, StyleSheet, Text, View } from 'react-native';

const GODOT_BUILD_INFO_URL = '/godot/void-drifter/build-info.json';
const GODOT_FRAME_URL = '/godot/void-drifter/index.html';
const godotFrameStyle: React.CSSProperties = {
  display: 'block',
  width: '100%',
  height: '100%',
  border: 0,
  backgroundColor: '#030712',
};

type BuildStatus = 'checking' | 'ready' | 'missing';

export function VoidDrifterGodotScreen() {
  const [buildStatus, setBuildStatus] = useState<BuildStatus>(
    Platform.OS === 'web' ? 'checking' : 'missing'
  );

  useEffect(() => {
    if (Platform.OS !== 'web') {
      return;
    }

    let cancelled = false;
    fetch(`${GODOT_BUILD_INFO_URL}?t=${Date.now()}`, { cache: 'no-store' })
      .then((response) => {
        if (!cancelled) {
          setBuildStatus(response.ok ? 'ready' : 'missing');
        }
      })
      .catch(() => {
        if (!cancelled) {
          setBuildStatus('missing');
        }
      });

    return () => {
      cancelled = true;
    };
  }, []);

  if (Platform.OS === 'web' && buildStatus === 'ready') {
    return (
      <View style={styles.godotShell}>
        {React.createElement('iframe', {
          allow: 'fullscreen; gamepad',
          src: GODOT_FRAME_URL,
          style: godotFrameStyle,
          title: 'VOID DRIFTER Godot',
        })}
      </View>
    );
  }

  return (
    <View style={styles.screen}>
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.panel}>
          <Text style={styles.kicker}>VOID DRIFTER</Text>
          <Text style={styles.title}>Godot build not embedded yet</Text>
          <Text style={styles.body}>
            Export the Godot web build once, then this Expo route will load it directly.
          </Text>
          <View style={styles.commandBox}>
            <Text style={styles.command}>npm run godot:export:web</Text>
            <Text style={styles.command}>npm run web</Text>
          </View>
          <Text style={styles.note}>
            Godot is not installed in this Codex environment, so the export could not be generated
            here. VOID DRIFTER now runs Godot-first, so export the web build to play.
          </Text>

          <Link href="/void-drifter/enemies" asChild>
            <Pressable style={styles.secondaryButton}>
              <Text style={styles.secondaryButtonText}>Enemy Codex</Text>
            </Pressable>
          </Link>
        </View>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  godotShell: {
    flex: 1,
    backgroundColor: '#030712',
  },
  screen: {
    flex: 1,
    backgroundColor: '#030712',
  },
  safeArea: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  panel: {
    width: '100%',
    maxWidth: 560,
    gap: 14,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(34, 211, 238, 0.35)',
    backgroundColor: 'rgba(15, 23, 42, 0.9)',
    padding: 24,
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
  body: {
    color: '#cbd5e1',
    fontSize: 16,
    lineHeight: 23,
  },
  commandBox: {
    gap: 6,
    borderRadius: 8,
    backgroundColor: 'rgba(2, 6, 23, 0.92)',
    padding: 14,
  },
  command: {
    color: '#67e8f9',
    fontFamily: Platform.select({ default: 'monospace', ios: 'Menlo' }),
    fontSize: 14,
    fontWeight: '700',
  },
  note: {
    color: '#94a3b8',
    fontSize: 13,
    lineHeight: 19,
  },
  secondaryButton: {
    alignItems: 'center',
    alignSelf: 'flex-start',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(103, 232, 249, 0.46)',
    backgroundColor: 'rgba(8, 47, 73, 0.6)',
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  secondaryButtonText: {
    color: '#cffafe',
    fontSize: 14,
    fontWeight: '900',
  },
});
