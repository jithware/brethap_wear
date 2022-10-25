// Packaging requires Multiple APK support see:
// https://developer.android.com/training/wearables/packaging

import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sensors/flutter_sensors.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock/wakelock.dart';
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
      theme: ThemeData.dark().copyWith(primaryColor: Colors.blue),
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
      keyConnect = "Connect",
      keyStart = "Start",
      keyDrag = "Drag";
  static const snackBarDuration = Duration(seconds: 5);

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  Duration _duration = const Duration(seconds: 0);
  bool _isRunning = false,
      _hasVibrate = false,
      _hasWakelock = false,
      _hasHeartRate = false,
      _connected = false;
  double _scale = 0.0;
  String _title = "", _timer = "";
  Preference? _phonePreference;
  Preference _preference = Preference.getDefaultPref();
  final WatchConnectivity _watch = WatchConnectivity();

  final Duration _heartSensorDelay = const Duration(seconds: 1);
  Stream? _heartStream;
  StreamSubscription? _heartSubscription;
  List<double>? _heartrates;

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
    _updatePreference(DEFAULT_TEXT);

    // Init vibration
    _initVibrate();

    // Init wakelock
    _initWakeLock();

    // Init phone communication
    _initWear();

    // Init sensors
    _initSensors();

    super.initState();
  }

  @override
  void dispose() {
    debugPrint("$widget.dispose");
    super.dispose();
  }

  // To pair phone for testing see:
  // https://developer.android.com/training/wearables/get-started/creating#pair-phone-with-avd
  void _initWear() {
    _watch.messageStream.listen((message) => setState(() {
          debugPrint('Received message: $message');
          _connected = true;
          if (Preference.isPreference(message)) {
            _phonePreference = Preference.fromJson(message);
            _updatePreference(HomeWidget.phonePreference);
          }
        }));

    // request the current preference from phone
    _send({"preference": 0});
  }

  void _send(message) {
    debugPrint("Sent message: $message");
    _watch.sendMessage(message);
  }

  Future<void> _initVibrate() async {
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

  Future<void> _vibrate(int duration) async {
    debugPrint("$widget.vibrate($duration)");
    if (_hasVibrate && duration > 0) {
      await Vibration.vibrate(duration: duration);
    }
  }

  Future<void> _initWakeLock() async {
    try {
      await Wakelock.enabled;
      _hasWakelock = true;
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _wakeLock(bool enable) {
    if (_hasWakelock) {
      debugPrint("$widget.wakelock($enable)");
      Wakelock.toggle(enable: enable);
    }
  }

  Future<void> _initSensors() async {
    // https://developer.android.com/reference/android/hardware/Sensor#TYPE_HEART_RATE
    // ignore: constant_identifier_names
    const int TYPE_HEART_RATE = 21;

    try {
      _hasHeartRate = await SensorManager().isSensorAvailable(TYPE_HEART_RATE);
      if (_hasHeartRate) {
        Permission.sensors.request().then((value) async {
          if (value.isGranted) {
            _heartStream = await SensorManager().sensorUpdates(
              sensorId: TYPE_HEART_RATE,
              interval: _heartSensorDelay,
            );
          } else {
            _hasHeartRate = false;
          }
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      _hasHeartRate = false;
    }
  }

  void _heartRate(bool enable) {
    if (_hasHeartRate) {
      if (enable) {
        _heartrates = [];
        _heartSubscription = _heartStream!.listen((sensorEvent) {
          _heartrates!.addAll(sensorEvent.data);
          debugPrint("heartRates: $_heartrates");
        });
      } else {
        if (_heartSubscription != null) {
          _heartSubscription!.cancel();
        }
      }
    }
  }

  void _showSessionSnackBar(Session session, int breaths) {
    Widget heart = const SizedBox.shrink(), bpm = const Text("");
    TextStyle textStyle = const TextStyle(
      color: Colors.white,
    );
    List<double>? heartrates = session.heartrates;
    if (heartrates != null) {
      int average = heartrates.average.toInt();
      if (average > 0) {
        bpm = Text("$average", style: textStyle);
        heart = Icon(Icons.favorite, color: Theme.of(context).primaryColor);
      }
    }

    SizedBox spacer = const SizedBox(width: 5);
    Column content =
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Icon(
          key: const Key(HomeWidget.keyDrag),
          Icons.timer,
          color: Theme.of(context).primaryColor,
        ),
        spacer,
        Text(
            getDurationString(
                roundDuration(session.end.difference(session.start))),
            style: textStyle),
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Icon(
          Icons.air,
          color: Theme.of(context).primaryColor,
        ),
        spacer,
        Text("$breaths", style: textStyle),
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        heart,
        spacer,
        bpm,
      ])
    ]);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: HomeWidget.snackBarDuration,
      backgroundColor: Theme.of(context).canvasColor,
      content: content,
    ));
  }

  void _buttonPressed() {
    debugPrint("$widget.buttonPressed");

    _connected = false;
    if (_isRunning) {
      _isRunning = false;
    } else {
      _isRunning = true;
      _heartRate(true);
      _wakeLock(true);
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
            _heartRate(false);
            _wakeLock(false);
            _scale = 0.0;
            _timer = getDurationString(_duration);
            timer.cancel();
            _vibrate(_preference.vibrateDuration);
            int breaths = (duration.inMilliseconds / breath).round();
            Session session = Session(start: start);
            session.end = DateTime.now();
            session.breaths = breaths;
            session.heartrates = _heartrates;
            _send(session.toJson());
            _showSessionSnackBar(session, breaths);
          });
        } else {
          setState(() {
            if (cycle == 0) {
              inhaling = true;
              exhaling = false;
              _scale = 0.0;
              _vibrate(_preference.vibrateBreath);
            } else if (_preference.inhale[1] > 0 &&
                cycle == _preference.inhale[0]) {
              inhaling = false;
              exhaling = false;
              _vibrate(_preference.vibrateBreath);
            } else if (_preference.inhale[2] > 0 &&
                cycle == _preference.inhale[0] + _preference.inhale[1]) {
              inhaling = true;
              exhaling = false;
              _vibrate(_preference.vibrateBreath);
            } else if (cycle == inhale) {
              inhaling = false;
              exhaling = true;
              _scale = 1.0;
              _vibrate(_preference.vibrateBreath);
            } else if (_preference.exhale[1] > 0 &&
                cycle == inhale + _preference.exhale[0]) {
              inhaling = false;
              exhaling = false;
              _vibrate(_preference.vibrateBreath);
            } else if (_preference.exhale[2] > 0 &&
                cycle ==
                    inhale + _preference.exhale[0] + _preference.exhale[1]) {
              inhaling = false;
              exhaling = true;
              _vibrate(_preference.vibrateBreath);
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

        // debugPrint(
        //     "duration: $duration  breaths: ${(duration.inMilliseconds / breath).toStringAsFixed(3)} scale: ${_scale.toStringAsFixed(3)} cycle: $cycle");
      });
    }
  }

  Future<void> _updatePreference(String value) async {
    debugPrint("$widget.updatePreference($value)");

    setState(() {
      _isRunning = false;
      switch (value) {
        case HomeWidget.phonePreference:
          if (_phonePreference != null) {
            _preference = _phonePreference!;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Theme.of(context).canvasColor,
              content: const Text("Not paired to Brethap phone app\n",
                  style: TextStyle(
                    color: Colors.white,
                  )),
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

  Widget _getLeading(double leftPad, double topPad) {
    if (_connected && !_isRunning) {
      return IconButton(
        icon: Icon(Icons.phonelink_ring, color: Theme.of(context).primaryColor),
        padding: EdgeInsets.only(left: leftPad, top: topPad),
        onPressed: () {
          setState(() {
            _send({"preference": 0});
          });
        },
      );
    }
    if (!_connected && !_isRunning) {
      return IconButton(
        key: const Key(HomeWidget.keyConnect),
        icon:
            Icon(Icons.phonelink_erase, color: Theme.of(context).disabledColor),
        padding: EdgeInsets.only(left: leftPad, top: topPad),
        onPressed: () {
          setState(() {
            _send({"preference": 0});
          });
        },
      );
    }

    return const SizedBox.shrink();
  }

  List<Widget> _getActions(double rightPad, double topPad, double prefWidth) {
    if (!_isRunning) {
      return [
        PopupMenuButton<String>(
          color: Theme.of(context).canvasColor,
          elevation: 0,
          padding: EdgeInsets.only(right: rightPad, top: topPad),
          icon: Icon(Icons.more_vert, color: Theme.of(context).primaryColor),
          onSelected: (value) {
            _updatePreference(value);
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
        )
      ];
    }

    return [const SizedBox.shrink()];
  }

  Widget _getCenterWidgets(double leftPad, double rightPad) {
    Widget heart = const SizedBox.shrink(),
        spacer = const SizedBox.shrink(),
        bpm = const Text("");
    const double iconSize = 15.0;

    if (_isRunning && _hasHeartRate) {
      if (_heartrates != null && _heartrates!.isNotEmpty) {
        int heartrate = _heartrates!.last.toInt();
        bpm = Text(
          "$heartrate",
        );
      }
      heart = Icon(Icons.favorite,
          size: iconSize, color: Theme.of(context).primaryColor);
      spacer = const SizedBox(width: 5);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.timer,
          size: iconSize,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 1),
        Text(
          _timer,
        ),
        spacer,
        heart,
        const SizedBox(width: 1),
        bpm,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (BuildContext context, WearShape shape, Widget? child) {
        double leftPad = 0.0,
            rightPad = 0.0,
            topPad = 0.0,
            fontSize = 10.0,
            prefWidth = 150,
            iconSize = 40.0;
        if (shape == WearShape.round) {
          leftPad = 30.0;
          rightPad = 35.0;
          topPad = 30.0;
          prefWidth = 125;
        }
        return Scaffold(
          appBar: AppBar(
              leading: _getLeading(leftPad, topPad),
              centerTitle: true,
              title: Visibility(
                  visible: !_isRunning,
                  child: Text(_title,
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: fontSize))),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: _getActions(rightPad, topPad, prefWidth)),
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
              _getCenterWidgets(leftPad, rightPad),
              IconButton(
                  key: const Key(HomeWidget.keyStart),
                  iconSize: iconSize,
                  onPressed: () {
                    setState(() {
                      _buttonPressed();
                    });
                  },
                  icon: _isRunning
                      ? Icon(
                          Icons.stop_rounded,
                          color: Theme.of(context).primaryColor,
                        )
                      : Icon(
                          Icons.play_arrow_rounded,
                          color: Theme.of(context).primaryColor,
                        ))
            ],
          ),
        );
      },
    );
  }
}
