# Screenshots

To take screenshots, run:
```
flutter screenshot -d <device name> -o fastlane/metadata/android/en-US/images/wearScreenshots/<image>.png
```

To take video, install [scrcpy](https://github.com/Genymobile/scrcpy#get-the-app) and run:
```
scrcpy --record screenshots/android/<video>.mp4 --max-fps 10
```

To convert mp4 to webp, install [ffmpeg](https://ffmpeg.org/download.html) and run:
```
ffmpeg -y -i screenshots/android/<video>.mp4 -vcodec libwebp -filter:v fps=10 -lossless 0 -compression_level 3 -q:v 70 -loop 1 -preset picture -an -vsync 0 screenshots/android/<video>.webp
```

Google Play requires minimum size of wear screenshots to be 384x384, run:
```
mogrify -resize 384x384 fastlane/metadata/android/en-US/images/wearScreenshots/*.png
```