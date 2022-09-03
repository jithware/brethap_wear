# Screenshots

To take screenshots, run:
```
flutter screenshot -d <device name> -o android/<image>.png
```

To take video, install [scrcpy](https://github.com/Genymobile/scrcpy#get-the-app) and run:
```
scrcpy --record android/<video>.mp4 --max-fps 10
```

To convert mp4 to webp, install [ffmpeg](https://ffmpeg.org/download.html) and run:
```
ffmpeg -y -i android/<video>.mp4 -vcodec libwebp -filter:v fps=10 -lossless 0 -compression_level 3 -q:v 70 -loop 1 -preset picture -an -vsync 0 android/<video>.webp
```