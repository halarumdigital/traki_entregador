echo image changes started

rm -rf ./assets/images/logo.png
cp ../image.png ./assets/images/logo.png

rm -rf ./android/app/src/main/res/drawable/logo.png
cp ../image.png ./android/app/src/main/res/drawable/logo.png
sips -Z 100 ./android/app/src/main/res/drawable/logo.png

rm -rf ./android/app/src/main/res/mipmap-mdpi/ic_launcher.png
cp ../image.png ./android/app/src/main/res/mipmap-mdpi/ic_launcher.png
sips -Z 48 ./android/app/src/main/res/mipmap-mdpi/ic_launcher.png

rm -rf ./android/app/src/main/res/mipmap-hdpi/ic_launcher.png
cp ../image.png ./android/app/src/main/res/mipmap-hdpi/ic_launcher.png
sips -Z 72 ./android/app/src/main/res/mipmap-hdpi/ic_launcher.png

rm -rf ./android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
cp ../image.png ./android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
sips -Z 96 ./android/app/src/main/res/mipmap-xhdpi/ic_launcher.png

rm -rf ./android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
cp ../image.png ./android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
sips -Z 144 ./android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png

rm -rf ./android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
cp ../image.png ./android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
sips -Z 192 ./android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png

rm -rf ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png
cp ../image.png ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png
sips -Z 20 ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png

rm -rf ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
rm -rf ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png
cp ../image.png ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
cp ../image.png ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png
sips -Z 40 ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
sips -Z 40 ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png

rm -rf ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png
cp ../image.png ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png
sips -Z 60 ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png

rm -rf ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png
cp ../image.png ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png
sips -Z 29 ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png

rm -rf ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png
cp ../image.png ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png
sips -Z 58 ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png

rm -rf ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png
cp ../image.png ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png
sips -Z 87 ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png

rm -rf ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png
cp ../image.png ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png
sips -Z 80 ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png

rm -rf ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png
rm -rf ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png
cp ../image.png ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png
cp ../image.png ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png
sips -Z 120 ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png
sips -Z 120 ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png

rm -rf ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png
cp ../image.png ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png
sips -Z 180 ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png

rm -rf ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png
cp ../image.png ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png
sips -Z 76 ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png

rm -rf ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png
cp ../image.png ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png
sips -Z 152 ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png

rm -rf ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png
cp ../image.png ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png
sips -Z 167 ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png

rm -rf ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
cp ../image.png ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
sips -Z 1024 ./ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png

echo image changes completed