import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optimize_battery/optimize_battery.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:flutter_background/flutter_background.dart';

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
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'AdUnwrap'),
    );
  }
}

// ignore: must_be_immutable
class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  String serviceStatus = "Press the button to launch the AdUnwrap service";
  Icon buttonIcon = Icon(Icons.launch_outlined);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
              widget.serviceStatus = "Press the button to launch the AdUnwrap service";
              widget.buttonIcon = Icon(Icons.launch_outlined);
            });
            Fluttertoast.showToast(msg: "AdUnwrap service stopped");
          } else {
              if (success) {
                setState(() {
                  widget.serviceStatus = "Press the button to stop the AdUnwrap service";
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
            Text(
              widget.serviceStatus
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startService,
        tooltip: 'AdUnwrap Service',
        child: widget.buttonIcon,
      ),
    );
  }
}
