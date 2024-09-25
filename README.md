## Raylib - Zig on Android
### Setup
Setup your project as in
[Raylib's Android tutorial](https://github.com/raysan5/raylib/wiki/Working-for-Android-(on-Linux)).
A few modifications must be made. First, in the manifest, change
```xml
<uses-sdk android:minSdkVersion="23" android:targetSdkVersion="29"/>
```
to
```xml
<uses-sdk android:minSdkVersion="23" android:targetSdkVersion="34"/>
```
You must also add
```xml
android:exported="true"
```
in the activity tag.

Now, on `build.sh`, replace
```bash
jarsigner -keystore android/raylib.keystore -storepass raylib -keypass raylib \
	-signedjar game.apk game.apk projectKey

$BUILD_TOOLS/zipalign -f 4 game.apk game.final.apk
mv -f game.final.apk game.apk
```
with
```bash
$BUILD_TOOLS/zipalign -f 4 game.apk game.final.apk
mv -f game.final.apk game.apk

apksigner sign  --ks android/raylib.keystore --out my-app-release.apk --ks-pass pass:raylib game.apk
mv my-app-release.apk game.apk
```
