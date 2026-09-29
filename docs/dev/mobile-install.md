# VOID DRIFTER Android-installatie

De primaire VOID DRIFTER-runtime is Godot. De Android-preset staat in
`godot/void-drifter/export_presets.cfg`; Expo is niet de native gameplay-build.

## Snelpad voor een USB-Androidtoestel

1. Controleer het toestel:

```bash
adb devices
adb -s <SERIAL> shell getprop ro.product.model
```

2. Controleer de Godot-build en exporteer de actuele webbuild indien nodig:

```bash
npm run godot:check
npm run godot:export:web
```

3. Exporteer de Android-debug-APK naar het repository-root `builds/`-pad.
Godot resolveert relatieve Android-exportpaden vanaf `godot/void-drifter`, dus
gebruik een absoluut pad of `../../builds/`:

```bash
  godot --headless --path godot/void-drifter \
  --export-debug Android "$PWD/builds/void-drifter-latest.apk"
```

Maak vóór een update een lokale kopie van het profiel. Dit werkt voor de
debug-APK zolang `run-as` toegang heeft tot de package-data en verwijdert niets:

```bash
mkdir -p builds/phone-backup
adb -s <SERIAL> shell run-as com.budio.voiddrifter ls -la files
adb -s <SERIAL> exec-out run-as com.budio.voiddrifter \
  cat files/void_drifter_profile.json > builds/phone-backup/void_drifter_profile.json
adb -s <SERIAL> exec-out run-as com.budio.voiddrifter \
  cat files/void_drifter_profile.json.bak > builds/phone-backup/void_drifter_profile.json.bak
```

Als `run-as` geen toegang heeft, maak dan geen uninstall of `pm clear`-actie
aan; de appdata is dan alleen via de in-game herstelkopie of Android Backup
terug te halen.

Als Godot meldt dat het Java-pad niet bestaat, controleer dan
`~/Library/Application Support/Godot/editor_settings-4.tres`. Zet
`export/android/java_sdk_path` tijdelijk op de aanwezige JDK, bijvoorbeeld:

```text
/Library/Java/JavaVirtualMachines/temurin-26.jdk/Contents/Home
```

Herstel daarna het persoonlijke editor-pad; wijzig dit niet in de repository.

4. Installeer zonder incremental-installatie (Samsung Secure Folder/ADB kan
anders een schijnbaar succesvolle maar niet-startbare package opleveren):

```bash
adb -s <SERIAL> install --no-incremental -r -d builds/void-drifter-latest.apk
```

Gebruik bij updates nooit `adb uninstall`, `pm clear` of een installatie zonder
`-r`: die acties kunnen de lokale voortgang verwijderen. Controleer vóór en na
de update dezelfde package en Android-user:

```bash
adb -s <SERIAL> shell am get-current-user
adb -s <SERIAL> shell dumpsys package com.budio.voiddrifter | rg 'userId=|dataDir=|versionCode='
```

5. Controleer package, launcher en startscherm:

```bash
adb -s <SERIAL> shell pm path com.budio.voiddrifter
adb -s <SERIAL> shell cmd package resolve-activity --brief \
  -a android.intent.action.MAIN -c android.intent.category.LAUNCHER \
  com.budio.voiddrifter
adb -s <SERIAL> shell monkey -p com.budio.voiddrifter 1
adb -s <SERIAL> shell dumpsys activity activities | \
  rg 'topResumedActivity|com.budio.voiddrifter'
```

De launchercomponent is normaal `com.godot.game.GodotAppLauncher`. Bewaar de
APK alleen lokaal; `builds/` is een lokale build-output en hoort niet bij de
canonieke bronbestanden.
