#!/bin/bash

# 1. Verify the version argument is passed. We use the same version for react-native-aztec and react-native-bridge libraries.
VERSION=$1
if [[ -z $VERSION ]]; then
    echo "This script requires the Bintray version to be passed as an argument."
    echo "Example usage: './publish-aztec-and-bridge.sh \$VERSION'"
    exit 1
fi

# 2. Check if we can call gradlew successfully
./gradlew --help > /dev/null 2>&1
gradlew_exists=$?
if [ $gradlew_exists -ne 0 ]; then
    echo "Gradle wrapper is not available. Make sure to run this script from '/packages/react-native-bridge/android'"
	exit 1
fi

# 3. Clean and copy the bundle
./gradlew clean -q
mkdir -p react-native-bridge/build/assets
cp ../../../../bundle/android/App.js ./react-native-bridge/build/assets/index.android.bundle

if [ $? -ne 0 ]; then
	echo "Make sure to run 'npm install' & 'npm run bundle:android' from the root folder of the project before running this script."
	exit 1
fi

# 4. Publish 'react-native-aztec` library to Bintray
echo "Publishing 'react-native-aztec' version '$VERSION'"
./gradlew :react-native-aztec:bintrayUpload -q -PpublishReactNativeAztecVersion=$VERSION

if [ $? -eq 0 ]; then
	echo "Successfully published 'react-native-aztec' version '$VERSION'."
	echo "Wait 30 seconds for the new 'react-native-aztec' version to be available"
	sleep 30
else
	echo "Failed to publish 'react-native-aztec' version '$VERSION'."
	echo "We'll still proceed to build and publish 'react-native-bridge' since this failure might be due to this version being published already, for example when the CI task is restarted."
fi

# 5. Publish 'react-native-bridge` library to Bintray
echo "Publishing react-native-bridge version '$VERSION'"
./gradlew :react-native-bridge:bintrayUpload -q -PpublishReactNativeBridgeVersion=$VERSION -PreactNativeAztecVersion=$VERSION

if [ $? -eq 0 ]; then
	echo "Successfully published 'react-native-bridge' version '$VERSION'."
else
	echo "Failed to publish 'react-native-bridge' version '$VERSION'."
	exit 1
fi
