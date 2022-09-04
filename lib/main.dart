import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:brethap/constants.dart';
import 'package:wear/wear.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

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
  final List<int> _inhales = [0, 0, 0];
  final List<int> _exhales = [0, 0, 0];
  final WatchConnectivity _watch = WatchConnectivity();

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

    // Init phone communication
    initWear();

    super.initState();
  }

  @override
  void dispose() {
    debugPrint("$widget.dispose");
    super.dispose();
  }

  void initWear() {
    _watch.messageStream.listen((msg) => setState(() {
          debugPrint('Received message: $msg');
        }));
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

  void send(message) {
    debugPrint("Sent message: $message");
    _watch.sendMessage(message);
  }

  void buttonPressed() {
    debugPrint("$widget.buttonPressed");

    if (_isRunning) {
      _isRunning = false;
    } else {
      _isRunning = true;
      Duration timerSpan = const Duration(milliseconds: 100);
      Duration duration = const Duration(milliseconds: 0);
      int inhale = _inhales[0] + _inhales[1] + _inhales[2];
      int exhale = _exhales[0] + _exhales[1] + _exhales[2];
      int breath = inhale + exhale;
      int cycle = 0;
      double inhaleScale =
          timerSpan.inMilliseconds / (_inhales[0] + _inhales[2]);
      double exhaleScale =
          timerSpan.inMilliseconds / (_exhales[0] + _exhales[2]);
      bool inhaling = true, exhaling = false;

      DateTime start = DateTime.now();
      Timer.periodic(timerSpan, (Timer timer) {
        if (!_isRunning) {
          setState(() {
            _isRunning = false;
            _scale = 0.0;
            _status = getDurationString(const Duration(milliseconds: 0));
            timer.cancel();
            int breaths = (duration.inMilliseconds / breath).round();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: MainWidget.color,
              content: Text(
                  "Duration: ${getDurationString(duration)}  Breaths: $breaths\n\n"),
            ));
            vibrate();
            send({
              'start': start.millisecondsSinceEpoch,
              'end': start.add(duration).millisecondsSinceEpoch,
              'breaths': breaths
            });
          });
        } else {
          setState(() {
            if (cycle == 0) {
              inhaling = true;
              exhaling = false;
              _scale = 0.0;
              vibrate();
            } else if (_inhales[1] > 0 && cycle == _inhales[0]) {
              inhaling = false;
              exhaling = false;
              vibrate();
            } else if (_inhales[2] > 0 && cycle == _inhales[0] + _inhales[1]) {
              inhaling = true;
              exhaling = false;
              vibrate();
            } else if (cycle == inhale) {
              inhaling = false;
              exhaling = true;
              _scale = 1.0;
              vibrate();
            } else if (_exhales[1] > 0 && cycle == inhale + _exhales[0]) {
              inhaling = false;
              exhaling = false;
              vibrate();
            } else if (_exhales[2] > 0 &&
                cycle == inhale + _exhales[0] + _exhales[1]) {
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
          _inhales[0] = INHALE_PS;
          _inhales[1] = INHALE_HOLD_PS;
          _inhales[2] = INHALE_LAST_PS;
          _exhales[0] = EXHALE_PS;
          _exhales[1] = 0;
          _exhales[2] = 0;
          break;
        case PRESET_478_TEXT:
          _inhales[0] = INHALE_478;
          _inhales[1] = INHALE_HOLD_478;
          _inhales[2] = 0;
          _exhales[0] = EXHALE_478;
          _exhales[1] = 0;
          _exhales[2] = 0;
          break;
        case BOX_TEXT:
          _inhales[0] = INHALE_BOX;
          _inhales[1] = INHALE_HOLD_BOX;
          _inhales[2] = 0;
          _exhales[0] = EXHALE_BOX;
          _exhales[1] = EXHALE_HOLD_BOX;
          _exhales[2] = 0;
          break;
        default:
          _title = HomeWidget.appName;
          _inhales[0] = INHALE;
          _inhales[1] = 0;
          _inhales[2] = 0;
          _exhales[0] = EXHALE;
          _exhales[1] = 0;
          _exhales[2] = 0;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (BuildContext context, WearShape shape, Widget? child) {
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
