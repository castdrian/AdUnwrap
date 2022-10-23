import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import 'constants.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optimize_battery/optimize_battery.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:clipboard_listener/clipboard_listener.dart';
import 'package:package_info/package_info.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AdUnwrap',
      theme: ThemeData(primarySwatch: Colors.blue, brightness: Brightness.dark),
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
  String? ver;
  String? bnum;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();

    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      widget.ver = packageInfo.version;
      widget.bnum = packageInfo.buildNumber;
    });

    ClipboardListener.addListener(() async {
      String? clipBoardText =
          (await Clipboard.getData(Clipboard.kTextPlain))!.text;
      if (clipBoardText != null) {
        // check if the clipboard contains a url
        bool isUrl = Uri.parse(clipBoardText).isAbsolute;
        if (isUrl) {
          // check if supportedUrls contains the url
          bool isSupported = supportedUrls.any((element) =>
              clipBoardText.toLowerCase().contains(element.toLowerCase()));

          if (isSupported) {
            await bypassLink(clipBoardText);
          }
        }
      }
    });
  }

  Future<void> bypassLink(String url) async {
    Fluttertoast.showToast(msg: "Bypassing ad link...");

    http.Response response = await http.post(
      Uri.parse('https://api.bypass.vip/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'url': url,
      }),
    );

    if (response.statusCode == 200) {
      String? bypassedUrl = jsonDecode(response.body)['destination'];
      if (bypassedUrl != null) {
        // check if the bypassed url is also an ad url and bypass it again
        bool isUrl = Uri.parse(bypassedUrl).isAbsolute;
        if (isUrl) {
          bool isSupported = supportedUrls.any((element) =>
              bypassedUrl.toLowerCase().contains(element.toLowerCase()));

          if (isSupported) {
            await bypassLink(bypassedUrl);
            return;
          }
        }

        await Clipboard.setData(ClipboardData(text: bypassedUrl));
        Fluttertoast.showToast(msg: "Bypassed URL: $bypassedUrl");
        await launchUrl(Uri.parse(bypassedUrl));
      } else {
        Fluttertoast.showToast(msg: "Error: ${response.statusCode}");
      }
    }
  }

  Future<void> startService() async {
    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "AdUnwrap Service",
      notificationText: "Monitoring clipboard for ad links",
      notificationImportance: AndroidNotificationImportance.Default,
      notificationIcon:
          AndroidResource(name: 'launcher_icon', defType: 'drawable'),
    );
    bool success =
        await FlutterBackground.initialize(androidConfig: androidConfig);

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
        title:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(widget.title),
          kReleaseMode
              ? Text('v${widget.ver} (${widget.bnum})',
                  style: TextStyle(fontSize: 12))
              : Text('')
        ]),
        leading: Image.asset('assets/icon/icon.png'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Supported URLs (via bypass.vip):',
              style: TextStyle(fontSize: 16),
            ),
            Container(
              height: 400,
              child: ListView.builder(
                itemCount: supportedUrls.length,
                itemBuilder: (context, index) {
                  return Text(supportedUrls[index]);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: startService,
        tooltip: 'AdUnwrap Service',
        label: widget.serviceStatus,
        icon: widget.buttonIcon,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
