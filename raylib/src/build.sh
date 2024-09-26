#"/bin/bash"
make clean
make PLATFORM=PLATFORM_ANDROID ANDROID_NDK=~/Android/android-ndk-r27b/ ANDROID_ARCH=arm ANDROID_API_VERSION=34
mv libraylib.a ../../lib/armeabi-v7a
make clean
make PLATFORM=PLATFORM_ANDROID ANDROID_NDK=~/Android/android-ndk-r27b/ ANDROID_ARCH=arm64 ANDROID_API_VERSION=34
mv libraylib.a ../../lib/arm64-v8a
make clean
make PLATFORM=PLATFORM_ANDROID ANDROID_NDK=~/Android/android-ndk-r27b/ ANDROID_ARCH=x86 ANDROID_API_VERSION=34
mv libraylib.a ../../lib/x86
make clean
make PLATFORM=PLATFORM_ANDROID ANDROID_NDK=~/Android/android-ndk-r27b/ ANDROID_ARCH=x86_64 ANDROID_API_VERSION=34
mv libraylib.a ../../lib/x86_64
make clean
cd ../..
