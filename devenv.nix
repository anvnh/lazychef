{ pkgs, ... }:

let
  unfreePkgs = import pkgs.path {
    system = pkgs.system;
    config.allowUnfree = true;
    config.android_sdk.accept_license = true;
  };

  androidComposition = unfreePkgs.androidenv.composeAndroidPackages {
    cmdLineToolsVersion = "9.0";
    toolsVersion = "26.1.1";
    platformToolsVersion = "35.0.2";
    buildToolsVersions = [
      "34.0.0"
      "28.0.3"
      "35.0.0"
    ];
    platformVersions = [
      "36"
      "35"
    ];
    includeEmulator = false;
    emulatorVersion = "30.3.4";
    includeSources = false;
    includeSystemImages = false;
    systemImageTypes = [ "google_apis_playstore" ];
    abiVersions = [ "arm64-v8a" ];
    cmakeVersions = [ "3.22.1" ];
    includeNDK = true;
    ndkVersions = [
      "25.1.8937393"
      "28.2.13676358"
    ];
    useGoogleAPIs = false;
    useGoogleTVAddOns = false;
    includeExtras = [ ];
  };

  androidSdk = androidComposition.androidsdk;
in
{
  packages = [
    pkgs.flutter
    pkgs.jdk17
    pkgs.nodejs_22
    androidSdk
    pkgs.gradle
  ];

  env = {
    ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
    ANDROID_NDK_ROOT = "${androidSdk}/libexec/android-sdk/ndk-bundle";
    ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
    JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";
    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/34.0.0/aapt2";
  };

  enterShell = ''
    flutter config --android-sdk $ANDROID_SDK_ROOT
    echo "Flutter: $(flutter --version | head -1)"
    echo "Java: $(java -version 2>&1 | head -1)"
    echo "Node: $(node --version)"
  '';
}
