import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:brethap/constants.dart';
import 'package:wear/wear.dart';

void main() {
  // Do not debugPrint in release
  bool isInRelease = true;
  assert(() {
    isInRelease = false;
    return true;
  }());
  if (isInRelease) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  runApp(const MainWidget());
}

class MainWidget extends StatelessWidget {
  const MainWidget({Key? key}) : super(key: key);

  static const Color color = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // To change device to dark mode run: adb shell "cmd uimode night yes"
      darkTheme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const HomeWidget(title: 'Brethap for Wear OS'),
    );
  }
}

class HomeWidget extends StatefulWidget {
  const HomeWidget({Key? key, required this.title}) : super(key: key);
  final String title;

  static const String appName = "Brethap";
  static const String physSigh = "Physio Sigh";

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  bool _isRunning = false, _hasVibrate = false, _vibrate = false;
  double _scale = 0.0;
  String _title = "", _status = "";
  List<int> inhales = [0, 0, 0];
  List<int> exhales = [0, 0, 0];

  final List<String> presets = [
    HomeWidget.physSigh,
    PRESET_478_TEXT,
    BOX_TEXT,
    DEFAULT_TEXT,
  ];

  @override
  initState() {
    debugPrint("$widget.initState");

    // Set default preset
    updatePreset(DEFAULT_TEXT);

    // Check for vibration
    hasVibrate();

    super.initState();
  }

  @override
  void dispose() {
    debugPrint("$widget.dispose");
    super.dispose();
  }

  String getDurationString(Duration duration) {
    String dur = duration.toString();
    return dur.substring(0, dur.indexOf('.'));
  }

  Future<void> hasVibrate() async {
    try {
      _hasVibrate = await Vibration.hasVibrator() ?? false;
      if (_hasVibrate) {
        _hasVibrate = await Vibration.hasCustomVibrationsSupport() ?? false;
      }
      _vibrate = _hasVibrate;
    } catch (e) {
      debugPrint(e.toString());
      _hasVibrate = _vibrate = false;
    }
  }

  Future<void> vibrate() async {
    debugPrint("$widget.vibrate");
    if (_hasVibrate && _vibrate) {
      await Vibration.vibrate(duration: 50);
    }
  }

  void buttonPressed() {
    debugPrint("$widget.buttonPressed");

    if (_isRunning) {
      _isRunning = false;
    } else {
      _isRunning = true;

      Duration timerSpan = const Duration(milliseconds: 100);
      Duration duration = const Duration(milliseconds: 0);
      int inhale = inhales[0] + inhales[1] + inhales[2];
      int exhale = exhales[0] + exhales[1] + exhales[2];
      int breath = inhale + exhale;
      int cycle = 0;
      double inhaleScale = timerSpan.inMilliseconds / (inhales[0] + inhales[2]);
      double exhaleScale = timerSpan.inMilliseconds / (exhales[0] + exhales[2]);
      bool inhaling = true, exhaling = false;

      Timer.periodic(timerSpan, (Timer timer) {
        if (!_isRunning) {
          setState(() {
            _isRunning = false;
            _scale = 0.0;
            _status = getDurationString(const Duration(milliseconds: 0));
            timer.cancel();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: MainWidget.color,
              content: Text(
                  "Duration: ${getDurationString(duration)}  Breaths: ${(duration.inMilliseconds / breath).round()}\n\n\n"),
            ));
            vibrate();
          });
        } else {
          setState(() {
            if (cycle == 0) {
              inhaling = true;
              exhaling = false;
              _scale = 0.0;
              vibrate();
            } else if (inhales[1] > 0 && cycle == inhales[0]) {
              inhaling = false;
              exhaling = false;
              vibrate();
            } else if (inhales[2] > 0 && cycle == inhales[0] + inhales[1]) {
              inhaling = true;
              exhaling = false;
              vibrate();
            } else if (cycle == inhale) {
              inhaling = false;
              exhaling = true;
              _scale = 1.0;
              vibrate();
            } else if (exhales[1] > 0 && cycle == inhale + exhales[0]) {
              inhaling = false;
              exhaling = false;
              vibrate();
            } else if (exhales[2] > 0 &&
                cycle == inhale + exhales[0] + exhales[1]) {
              inhaling = false;
              exhaling = true;
              vibrate();
            }

            cycle += timerSpan.inMilliseconds;
            if (cycle >= breath) {
              cycle = 0;
            }

            if (inhaling) {
              _scale += inhaleScale;
              if (_scale > 1.0) {
                _scale = 1.0;
              }
            } else if (exhaling) {
              _scale -= exhaleScale;
              if (_scale < 0.0) {
                _scale = 0.0;
              }
            }

            duration += Duration(milliseconds: timerSpan.inMilliseconds);
            _status = getDurationString(duration);
          });
        }

        debugPrint(
            "duration: $duration  breaths: ${duration.inMilliseconds / breath}  scale: $_scale  cycle: $cycle");
      });
    }
  }

  void updatePreset(String value) {
    debugPrint("$widget.updatePreset");

    setState(() {
      _isRunning = false;
      _title = value;
      _status = getDurationString(const Duration(milliseconds: 0));
      switch (value) {
        case HomeWidget.physSigh:
          inhales[0] = INHALE_PS;
          inhales[1] = INHALE_HOLD_PS;
          inhales[2] = INHALE_LAST_PS;
          exhales[0] = EXHALE_PS;
          exhales[1] = 0;
          exhales[2] = 0;
          break;
        case PRESET_478_TEXT:
          inhales[0] = INHALE_478;
          inhales[1] = INHALE_HOLD_478;
          inhales[2] = 0;
          exhales[0] = EXHALE_478;
          exhales[1] = 0;
          exhales[2] = 0;
          break;
        case BOX_TEXT:
          inhales[0] = INHALE_BOX;
          inhales[1] = INHALE_HOLD_BOX;
          inhales[2] = 0;
          exhales[0] = EXHALE_BOX;
          exhales[1] = EXHALE_HOLD_BOX;
          exhales[2] = 0;
          break;
        default:
          _title = HomeWidget.appName;
          inhales[0] = INHALE;
          inhales[1] = 0;
          inhales[2] = 0;
          exhales[0] = EXHALE;
          exhales[1] = 0;
          exhales[2] = 0;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (BuildContext context, WearShape shape, Widget? child) {
        debugPrint("Watch shape: $shape");
        double padding = 0.0, fontSize = 12.0;
        if (shape == WearShape.round) {
          padding = 35.0;
          fontSize = 9.0;
        }
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Visibility(
                visible: !_isRunning,
                child: Text(_title,
                    style: TextStyle(
                        color: MainWidget.color, fontSize: fontSize))),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: <Widget>[
              Visibility(
                visible: !_isRunning,
                child: PopupMenuButton<String>(
                  elevation: 0,
                  icon: const Icon(
                    Icons.more_vert,
                    color: MainWidget.color,
                  ),
                  onSelected: updatePreset,
                  itemBuilder: (BuildContext context) {
                    return presets.map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(choice,
                                style: const TextStyle(
                                  color: MainWidget.color,
                                ))
                          ],
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              SizedBox(width: padding), // moves menu to left
            ],
          ),
          extendBodyBehindAppBar: true,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                  child: Transform.scale(
                      scale: _scale,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: 90.0,
                          height: 90.0,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ))),
              Text(
                _status,
              ),
              ElevatedButton(
                  style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  )),
                  onPressed: () {
                    setState(() {
                      buttonPressed();
                    });
                  },
                  child: _isRunning
                      ? const Text(
                          "Stop",
                        )
                      : const Text("Start"))
            ],
          ),
        );
      },
    );
  }
}
