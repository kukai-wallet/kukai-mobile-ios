#!/bin/sh
set -eo pipefail

gpg --quiet --batch --yes --decrypt --passphrase="$KUKAI_DIST_PW" --output ./.github/secrets/Kukai_Mobile_Prov_Dist_App_Store.mobileprovision ./.github/secrets/Kukai_Mobile_Prov_Dist_App_Store.mobileprovision.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$KUKAI_PROV_PW" --output ./.github/secrets/distribution.cer ./.github/secrets/distribution.cer.gpg

mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles

cp ./.github/secrets/Kukai_Mobile_Prov_Dist_App_Store.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/Kukai_Mobile_Prov_Dist_App_Store.mobileprovision


security create-keychain -p "" build.keychain
security import ./.github/secrets/distribution.cer -t agg -k ~/Library/Keychains/build.keychain -P "" -A

security list-keychains -s ~/Library/Keychains/build.keychain
security default-keychain -s ~/Library/Keychains/build.keychain
security unlock-keychain -p "" ~/Library/Keychains/build.keychain

security set-key-partition-list -S apple-tool:,apple: -s -k "" ~/Library/Keychains/build.keychain