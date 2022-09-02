import 'dart:async';

import 'package:flutter/material.dart';
import 'package:brethap/constants.dart';

void main() {
  runApp(const MainWidget());
}

class MainWidget extends StatelessWidget {
  const MainWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const HomeWidget(title: 'Brethap for Wear OS'),
    );
  }
}

class HomeWidget extends StatefulWidget {
  const HomeWidget({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  bool _isRunning = false;
  double _scale = 0.0;
  String _title = "", _preset = "";
  List<int> inhales = [0, 0, 0];
  List<int> exhales = [0, 0, 0];

  final List<String> presets = [
    PHYS_SIGH_TEXT,
    PRESET_478_TEXT,
    BOX_TEXT,
    DEFAULT_TEXT,
  ];

  @override
  initState() {
    debugPrint("$widget.initState");
    updatePreset(DEFAULT_TEXT);
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
            _title = _preset;
            timer.cancel();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  "Duration: ${getDurationString(duration)}  Breaths: ${(duration.inMilliseconds / breath).round()}"),
            ));
          });
        } else {
          setState(() {
            if (cycle == 0) {
              inhaling = true;
              exhaling = false;
              _scale = 0.0;
            } else if (inhales[1] > 0 && cycle == inhales[0]) {
              inhaling = false;
              exhaling = false;
            } else if (inhales[2] > 0 && cycle == inhales[0] + inhales[1]) {
              inhaling = true;
              exhaling = false;
            } else if (cycle == inhale) {
              inhaling = false;
              exhaling = true;
              _scale = 1.0;
            } else if (exhales[1] > 0 && cycle == inhale + exhales[0]) {
              inhaling = false;
              exhaling = false;
            } else if (exhales[2] > 0 &&
                cycle == inhale + exhales[0] + exhales[1]) {
              inhaling = false;
              exhaling = true;
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
            _title = getDurationString(duration);
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
      _preset = _title = value;
      switch (value) {
        case PHYS_SIGH_TEXT:
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
          _preset = _title = "Brethap";
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.blue,
            ),
            onSelected: updatePreset,
            itemBuilder: (BuildContext context) {
              return presets.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _title,
            ),
            Center(
                child: Transform.scale(
                    scale: _scale,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: 80.0,
                        height: 80.0,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ))),
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
      ),
    );
  }
}
