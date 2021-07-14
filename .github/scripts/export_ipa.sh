#!/bin/bash

set -eo pipefail

xcodebuild -archivePath $PWD/build/Kukai-mobile.xcarchive \
            -exportOptionsPlist Kukai\ Mobile/ExportOptions.plist \
            -exportPath $PWD/build \
            -allowProvisioningUpdates \
            -exportArchive