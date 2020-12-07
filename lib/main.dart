import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart' as worker;

var t = DateTime.now();

void callbackDispatcher() {
  worker.Workmanager.executeTask((task, inputData) {
    print("Ini background task: $task"); //simpleTask will be emitted here.
    DateTime now = DateTime.now();
    switch (task) {
      case simplePeriodicTask:
        print("${now.hour}:${now.minute}" + simplePeriodicTask + "deployed");
        break;
      case nextTask:
        print("${now.hour}:${now.minute}  background task $nextTask");
        break;
      default:
        print("${now.hour}:${now.minute} default deploy");
        break;
    }
    return Future.value(true);
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  worker.Workmanager.initialize(callbackDispatcher, isInDebugMode: true);
  runApp(MyApp());
}

const simplePeriodicTask = "simplePeriodicTask";
const nextTask = "next";

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final fcm = FirebaseMessaging();

  FlutterLocalNotificationsPlugin flutterLocalNotificationPlugin;

  int _counter = 0;

  @override
  void initState() {
    super.initState();
    var androidInitialize = AndroidInitializationSettings("app_icon");
    var iOSinitialize = IOSInitializationSettings();
    var initializationsSettings = new InitializationSettings(
        android: androidInitialize, iOS: iOSinitialize);

    flutterLocalNotificationPlugin = new FlutterLocalNotificationsPlugin();
    flutterLocalNotificationPlugin.initialize(initializationsSettings,
        onSelectNotification: notificationSelected);

    fcm.configure(
      onMessage: (Map<String, dynamic> message) async {
        debugPrint('onMessage: $message');
        print(message['data']['test']);
      },
      onResume: (Map<String, dynamic> message) async {
        debugPrint('onResume: $message');
      },
      onLaunch: (Map<String, dynamic> message) async {
        debugPrint('onLaunch: $message');
      },
    );
    fcm.requestNotificationPermissions(
      const IosNotificationSettings(
          sound: true, badge: true, alert: true, provisional: true),
    );
    fcm.onIosSettingsRegistered.listen((settings) {
      debugPrint('Settings registered: $settings');
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
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          print("${t.hour}:${t.minute} : ini bos ");
        },
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    worker.Workmanager.registerOneOffTask(nextTask, nextTask,
        initialDelay: Duration(minutes: 20));

    worker.Workmanager.registerPeriodicTask(
        simplePeriodicTask, simplePeriodicTask,
        frequency: Duration(minutes: 15),
        inputData: <String, dynamic>{
          'int': 1,
          'bool': true,
          'double': 1.0,
          'string': '15',
          'array': [1, 2, 3],
        },
        constraints: worker.Constraints(
            requiresBatteryNotLow: false, requiresCharging: false),
        backoffPolicy: worker.BackoffPolicy.exponential,
        backoffPolicyDelay: Duration(seconds: 10));
  }


  Future _showNotification() async {
    var androidDetails = new AndroidNotificationDetails(
        "Channel Id", "febriansyah", "this is the message");
    var iOSDetails = new IOSNotificationDetails();
    var generalNotifications =
    new NotificationDetails(iOS: iOSDetails, android: androidDetails);

    await flutterLocalNotificationPlugin.show(
        0, "MyTitle", "MyBody", generalNotifications);
    // await flutterLocalNotificationPlugin.periodicallyShow(1, "subuh", "sholat subuh dulu bos", repeatInterval, notificationDetails)

  }


  Future notificationSelected(String payload) async {
    showDialog(context: context, builder: (context) => AlertDialog(
      content:  Text("Notification Clicked"),
    ));
  }

}
