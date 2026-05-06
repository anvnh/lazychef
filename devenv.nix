{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  # https://devenv.sh/packages/
  packages = with pkgs; [
    git
    # flutter # Removed to avoid conflict with android.flutter
    turso-cli
    typescript-language-server
    vscode-langservers-extracted
    google-cloud-sdk
  ];

  env = {
    GREET = "Welcome to LazyChef development environment!";
    ANDROID_HOME = "${config.android.sdk.path}/libexec/android-sdk";
    ANDROID_SDK_ROOT = "${config.android.sdk.path}/libexec/android-sdk";
    JAVA_HOME = pkgs.jdk17.home;
  };

  languages.javascript = {
    enable = true;
    pnpm.enable = true;
  };

  languages.typescript.enable = true;

  android = {
    enable = true;
    flutter.enable = true;
    sdk = {
      packages = [
        "platforms;android-34"
        "build-tools;34.0.0"
        "platform-tools"
        "cmdline-tools;latest"
        "extras;google;m2repository"
        "extras;android;m2repository"
      ];
    };
  };

  enterShell = ''
    echo "$GREET"
    # Ensure flutter knows where the Android SDK is
    flutter config --android-sdk $ANDROID_HOME > /dev/null 2>&1
    echo "Flutter version: $(flutter --version | head -n 1)"
    echo "Node version: $(node --version)"
    echo "Turso CLI: $(turso --version)"
  '';
}
