#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

DOTNET_SDK_VERSION=2.1.200
XAMARIN_VERSION=8.3.99.189
ANDROID_SDK_TOOLS_VERSION=3859397

apt-get update
apt-get -y install unzip openjdk-8-jdk libzip4 apt-transport-https curl gnupg
DEBIAN_FRONTEND=noninteractive

# Mono
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | tee /etc/apt/sources.list.d/mono-official-stable.list
apt-get update
apt-get install -y mono-devel

# Android
curl https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_TOOLS_VERSION}.zip -o sdk-tools.zip
mkdir /android
unzip sdk-tools.zip -d /android
rm -rf sdk-tools.zip
rm -rf /android/licenses
echo yes | /android/tools/bin/sdkmanager --update --licenses
echo yes | /android/tools/bin/sdkmanager "platforms;android-26" "build-tools;27.0.3"
echo yes | /android/tools/bin/sdkmanager --update

# Xamarin
curl https://xamjenkinsartifact.blob.core.windows.net/xamarin-android/xamarin-android/xamarin.android-oss_${XAMARIN_VERSION}.orig.tar.bz2 -o xamarin.tar.bz2
tar xvjf xamarin.tar.bz2
mv xamarin.android-oss_* /android/xamarin
rm -rf xamarin.tar.bz2

# Dotnet
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-bionic-prod bionic main" > /etc/apt/sources.list.d/dotnetdev.list'
apt-get update
apt-get install -y dotnet-sdk-${DOTNET_SDK_VERSION}

echo "\nexport ANDROID_SDK_PATH=/android/\nDOTNET_CLI_TELEMETRY_OPTOUT=1\nMSBuildSDKsPath=/usr/share/dotnet/sdk/${DOTNET_SDK_VERSION}" \
    >> /etc/environment

curl https://dist.nuget.org/win-x86-commandline/latest/nuget.exe -o /nuget.exe
cp -r /android/xamarin/bin/Release/lib/xamarin.android/* /usr/lib/mono/
mkdir -p /usr/lib/mono/xamarin-android/bin/
cp -r /android/xamarin/bin/Release/lib/xamarin.android/xbuild/* /usr/share/dotnet/sdk/${DOTNET_SDK_VERSION}
