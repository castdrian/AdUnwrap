import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optimize_battery/optimize_battery.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:clipboard_listener/clipboard_listener.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AdUnwrap',
      theme: ThemeData(
        primarySwatch: Colors.blue, brightness: Brightness.dark
      ),
      home: MyHomePage(title: 'AdUnwrap'),
    );
  }
}

// ignore: must_be_immutable
class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  Text serviceStatus = Text("Launch AdUnwrap Service");
  Icon buttonIcon = Icon(Icons.launch_outlined);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    ClipboardListener.addListener(() async {
      String? clipBoardText = (await Clipboard.getData(Clipboard.kTextPlain))!.text;
      if (clipBoardText != null) {
        // check if the clipboard contains a url
        bool isUrl = Uri.parse(clipBoardText).isAbsolute;
        if (isUrl) {
          Fluttertoast.showToast(msg: "Clipboard text: $clipBoardText");
        }
      }
    });
  }
  
  Future<void> _startService() async {
    final androidConfig = FlutterBackgroundAndroidConfig(
        notificationTitle: "AdUnwrap Service",
        notificationText: "Monitoring clipboard for ad links",
        notificationImportance: AndroidNotificationImportance.Default,
        notificationIcon: AndroidResource(name: 'launcher_icon', defType: 'drawable'),
    );
    bool success = await FlutterBackground.initialize(androidConfig: androidConfig);

    OptimizeBattery.isIgnoringBatteryOptimizations().then((onValue) {
      setState(() {
        if (onValue) {
          if (FlutterBackground.isBackgroundExecutionEnabled) {
            FlutterBackground.disableBackgroundExecution();
            setState(() {
              widget.serviceStatus = Text("Launch AdUnwrap Service");
              widget.buttonIcon = Icon(Icons.launch_outlined);
            });
            Fluttertoast.showToast(msg: "AdUnwrap service stopped");
          } else {
              if (success) {
                setState(() {
                  widget.serviceStatus = Text("Stop AdUnwrap Service");
                  widget.buttonIcon = Icon(Icons.cancel_outlined);
                });
                FlutterBackground.enableBackgroundExecution();
                Fluttertoast.showToast(msg: "AdUnwrap service launched");
                MoveToBackground.moveTaskToBack();
              }
          }
        } else {
          OptimizeBattery.stopOptimizingBatteryUsage();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/icon/icon.png', width: 250, height: 250),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startService,
        tooltip: 'AdUnwrap Service',
        label: widget.serviceStatus,
        icon: widget.buttonIcon,
      ),
    );
  }
}
