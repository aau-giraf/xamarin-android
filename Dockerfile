FROM ubuntu:18.04

ARG DOTNET_SDK_VERSION=2.1.200
ARG GIT_BRANCH=release-2018S4R1
ARG XAMARIN_VERSION=8.3.99.189
ARG ANDROID_SDK_TOOLS_VERSION=3859397
LABEL maintainer=SW611f19

RUN apt-get update
RUN apt-get -y install unzip openjdk-8-jdk libzip4 apt-transport-https curl gnupg
ENV DEBIAN_FRONTEND=noninteractive

# Mono
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
RUN echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | tee /etc/apt/sources.list.d/mono-official-stable.list
RUN apt-get update
RUN apt-get install -y mono-devel

# Android
RUN curl https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_TOOLS_VERSION}.zip -o sdk-tools.zip
RUN mkdir /android
RUN unzip sdk-tools.zip -d android
RUN rm -rf sdk-tools.zip
RUN rm -rf android/licenses
RUN echo yes | /android/tools/bin/sdkmanager --update --licenses
RUN echo yes | /android/tools/bin/sdkmanager "platforms;android-26" "build-tools;27.0.3"
RUN echo yes | /android/tools/bin/sdkmanager --update

# Xamarin
RUN curl https://xamjenkinsartifact.blob.core.windows.net/xamarin-android/xamarin-android/xamarin.android-oss_${XAMARIN_VERSION}.orig.tar.bz2 -o xamarin.tar.bz2
RUN tar xvjf xamarin.tar.bz2
RUN mv xamarin.android-oss_v8.3.99.189_Linux-x86_64_HEAD_7b85e47 /android/xamarin
RUN rm -rf xamarin.tar.bz2

# Dotnet
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
RUN mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
RUN sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-bionic-prod bionic main" > /etc/apt/sources.list.d/dotnetdev.list'
RUN apt-get update
RUN apt-get install -y dotnet-sdk-${DOTNET_SDK_VERSION}

ENV ANDROID_SDK_PATH=/android/
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV MSBuildSDKsPath=/usr/share/dotnet/sdk/2.1.200

RUN curl https://dist.nuget.org/win-x86-commandline/latest/nuget.exe -o nuget.exe
RUN cp -r /android/xamarin/bin/Release/lib/xamarin.android/* /usr/lib/mono/
RUN mkdir -p /usr/lib/mono/xamarin-android/bin/
RUN cp -r /android/xamarin/bin/Release/lib/xamarin.android/xbuild/* /usr/share/dotnet/sdk/${DOTNET_SDK_VERSION}

ENTRYPOINT cd weekplanner \
           && mono /nuget.exe restore . \
           && msbuild /t:PackageForAndroid \
                      /p:Configuration=Release \
                      /p:AndroidLinkMode=None \
                      Droid/WeekPlanner.Droid.csproj \
           && mv Droid/obj/Release/android/bin/dk.aau.cs.giraf.weekplanner.apk dk.aau.cs.giraf.weekplanner.apk
