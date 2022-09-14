// Packaging requires Multiple APK support see:
// https://developer.android.com/training/wearables/packaging

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:wear/wear.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

import 'package:brethap/hive_storage.dart';
import 'package:brethap/wear.dart';
import 'package:brethap/constants.dart';

Future<void> main() async {
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

  static const String title = "Brethap for Wear OS";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // To change device to dark mode run: adb shell "cmd uimode night yes"
      darkTheme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const HomeWidget(title: title),
    );
  }
}

class HomeWidget extends StatefulWidget {
  const HomeWidget({Key? key, required this.title}) : super(key: key);
  final String title;

  static const String appName = "Brethap",
      phonePreference = "Phone Preference",
      keyTitle = "Title";

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  Duration _duration = const Duration(seconds: 0);
  bool _isRunning = false,
      _hasVibrate = false,
      _connected = false,
      _sync = true;
  double _scale = 0.0;
  String _title = "", _timer = "";
  Preference? _phonePreference;
  Preference _preference = Preference.getDefaultPref();
  final WatchConnectivity _watch = WatchConnectivity();

  final List<String> presets = [
    HomeWidget.phonePreference,
    PRESET_478_TEXT,
    BOX_TEXT,
    PHYS_SIGH_TEXT,
    DEFAULT_TEXT,
  ];

  @override
  initState() {
    debugPrint("$widget.initState");

    // Set default preference
    updatePreference(DEFAULT_TEXT);

    // Init vibration
    initVibrate();

    // Init phone communication
    initWear();

    super.initState();
  }

  @override
  void dispose() {
    debugPrint("$widget.dispose");
    super.dispose();
  }

  // To pair phone for testing see:
  // https://developer.android.com/training/wearables/get-started/creating#pair-phone-with-avd
  void initWear() {
    _watch.messageStream.listen((message) => setState(() {
          debugPrint('Received message: $message');
          _connected = true;
          if (Preference.isPreference(message) && _sync) {
            _phonePreference = Preference.fromJson(message);
            updatePreference(HomeWidget.phonePreference);
          }
        }));

    // request the current preference from phone
    send({"preference": 0});
  }

  Future<void> initVibrate() async {
    try {
      _hasVibrate = await Vibration.hasVibrator() ?? false;
      if (_hasVibrate) {
        _hasVibrate = await Vibration.hasCustomVibrationsSupport() ?? false;
      }
    } catch (e) {
      debugPrint(e.toString());
      _hasVibrate = false;
    }
  }

  Future<void> vibrate(int duration) async {
    debugPrint("$widget.vibrate($duration)");
    if (_hasVibrate && duration > 0) {
      await Vibration.vibrate(duration: duration);
    }
  }

  void send(message) {
    if (_sync) {
      debugPrint("Sent message: $message");
      _watch.sendMessage(message);
    }
  }

  void buttonPressed() {
    debugPrint("$widget.buttonPressed");

    _connected = false;
    if (_isRunning) {
      _isRunning = false;
    } else {
      _isRunning = true;
      Duration timerSpan = const Duration(milliseconds: 100);
      Duration duration = const Duration(milliseconds: 0);
      int inhale =
          _preference.inhale[0] + _preference.inhale[1] + _preference.inhale[2];
      int exhale =
          _preference.exhale[0] + _preference.exhale[1] + _preference.exhale[2];
      int breath = inhale + exhale;
      int cycle = 0;
      double inhaleScale = timerSpan.inMilliseconds /
          (_preference.inhale[0] + _preference.inhale[2]);
      double exhaleScale = timerSpan.inMilliseconds /
          (_preference.exhale[0] + _preference.exhale[2]);
      bool inhaling = true, exhaling = false;

      DateTime start = DateTime.now();
      Timer.periodic(timerSpan, (Timer timer) {
        if (!_isRunning ||
            (duration.inSeconds >= _duration.inSeconds && cycle <= 0)) {
          setState(() {
            _isRunning = false;
            _scale = 0.0;
            _timer = getDurationString(_duration);
            timer.cancel();
            vibrate(_preference.vibrateDuration);
            int breaths = (duration.inMilliseconds / breath).round();
            Session session = Session(start: start);
            session.end = DateTime.now();
            session.breaths = breaths;
            send(session.toJson());
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Theme.of(context).primaryColor,
              content: Text(
                  "Duration: ${getDurationString(roundDuration(session.end.difference(session.start)))}  Breaths: $breaths\n\n"),
            ));
          });
        } else {
          setState(() {
            if (cycle == 0) {
              inhaling = true;
              exhaling = false;
              _scale = 0.0;
              vibrate(_preference.vibrateBreath);
            } else if (_preference.inhale[1] > 0 &&
                cycle == _preference.inhale[0]) {
              inhaling = false;
              exhaling = false;
              vibrate(_preference.vibrateBreath);
            } else if (_preference.inhale[2] > 0 &&
                cycle == _preference.inhale[0] + _preference.inhale[1]) {
              inhaling = true;
              exhaling = false;
              vibrate(_preference.vibrateBreath);
            } else if (cycle == inhale) {
              inhaling = false;
              exhaling = true;
              _scale = 1.0;
              vibrate(_preference.vibrateBreath);
            } else if (_preference.exhale[1] > 0 &&
                cycle == inhale + _preference.exhale[0]) {
              inhaling = false;
              exhaling = false;
              vibrate(_preference.vibrateBreath);
            } else if (_preference.exhale[2] > 0 &&
                cycle ==
                    inhale + _preference.exhale[0] + _preference.exhale[1]) {
              inhaling = false;
              exhaling = true;
              vibrate(_preference.vibrateBreath);
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
            _timer = getDurationString(_duration - duration);
          });
        }

        debugPrint(
            "duration: $duration  breaths: ${(duration.inMilliseconds / breath).toStringAsFixed(3)} scale: ${_scale.toStringAsFixed(3)} cycle: $cycle");
      });
    }
  }

  Future<void> updatePreference(String value) async {
    debugPrint("$widget.updatePreference($value)");

    setState(() {
      _isRunning = false;
      switch (value) {
        case HomeWidget.phonePreference:
          if (_phonePreference != null) {
            _preference = _phonePreference!;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Theme.of(context).primaryColor,
              content: const Text("Not paired to phone\n\n\n"),
            ));
          }
          break;
        case PRESET_478_TEXT:
          _preference = Preference.get478Pref();
          break;
        case BOX_TEXT:
          _preference = Preference.getBoxPref();
          break;
        case PHYS_SIGH_TEXT:
          _preference = Preference.getPhysSighPref();
          break;
        case DEFAULT_TEXT:
          _preference = Preference.getDefaultPref();
          break;
        default:
          _preference = Preference.getDefaultPref();
          break;
      }

      _title = _preference.name;
      if (_title.isEmpty) {
        _title = HomeWidget.appName;
      }
      _duration = Duration(seconds: _preference.duration);
      _timer = getDurationString(_duration);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (BuildContext context, WearShape shape, Widget? child) {
        double leftPad = 0.0,
            rightPad = 0.0,
            topPad = 0.0,
            fontSize = 12.0,
            prefWidth = 150;
        if (shape == WearShape.round) {
          leftPad = 40.0;
          rightPad = 35.0;
          topPad = 15.0;
          prefWidth = 125;
        }
        return Scaffold(
          appBar: AppBar(
            leading: Visibility(
              visible: !_isRunning,
              child: _connected && _sync
                  ? IconButton(
                      icon: Icon(Icons.phonelink_ring,
                          color: Theme.of(context).primaryColor),
                      padding: EdgeInsets.only(left: leftPad, top: topPad),
                      onPressed: () {
                        setState(() {
                          _sync = false;
                        });
                      },
                    )
                  : IconButton(
                      icon:
                          const Icon(Icons.phonelink_erase, color: Colors.grey),
                      padding: EdgeInsets.only(left: leftPad, top: topPad),
                      onPressed: () {
                        setState(() {
                          _sync = true;
                          send({"preference": 0});
                        });
                      },
                    ),
            ),
            centerTitle: true,
            title: GestureDetector(
                key: const Key(HomeWidget.keyTitle),
                onTap: () {
                  setState(() {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  });
                },
                child: Visibility(
                    visible: !_isRunning,
                    child: Text(_title,
                        style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: fontSize)))),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: <Widget>[
              Visibility(
                visible: !_isRunning,
                child: PopupMenuButton<String>(
                  elevation: 0,
                  padding: EdgeInsets.only(right: rightPad, top: topPad),
                  icon: Icon(Icons.more_vert,
                      color: Theme.of(context).primaryColor),
                  onSelected: (value) {
                    updatePreference(value);
                  },
                  itemBuilder: (BuildContext context) {
                    return presets.map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: SizedBox(
                          width: prefWidth,
                          child: Text(choice,
                              key: Key(choice),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                              )),
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ],
          ),
          extendBodyBehindAppBar: true,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            child: Column(
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
                  _timer,
                ),
                ElevatedButton(
                    style: ButtonStyle(
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
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
          ),
        );
      },
    );
  }
}
