#!/bin/bash

set -eo pipefail

xcodebuild -scheme "Kukai Mobile Release"\
            -sdk iphoneos \
            -configuration release \
            -archivePath $PWD/build/Kukai-mobile.xcarchive \
            clean archive