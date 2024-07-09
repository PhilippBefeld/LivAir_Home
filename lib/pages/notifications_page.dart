
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class NotificationsPage extends StatefulWidget {

  final String token;
  final String refreshToken;

  const NotificationsPage({super.key, required this.token, required this.refreshToken});

  @override
  State<NotificationsPage> createState() => NotificationsPageState(token, refreshToken);
}

class NotificationsPageState extends State<NotificationsPage>{

  String token;
  String refreshToken;
  final Logger logger = Logger();
  final Dio dio = Dio();

  NotificationsPageState(this.token, this.refreshToken);
  //page variables
  int index = 0;

  //notifications
  List<dynamic> notifications = [];
  bool notificationsLoaded = false;
  List<String> deviceIds = [];
  List<String> labels = [];
  List<int> selectedNotifications = [];
  bool noReloading = false;


  getAllNotifications() async {
    if(notificationsLoaded || noReloading)return;
    notificationsLoaded = true;
    notifications = [];
    String? userId;
    try{
      dio.options.headers['content-Type'] = 'application/json';
      dio.options.headers['Accept'] = "application/json";
      dio.options.headers['Authorization'] = "Bearer $token";
      if(DateTime.fromMillisecondsSinceEpoch(JwtDecoder.decode(token)["exp"]*1000).isBefore(DateTime.now())){
        Response loginResponse = await dio.post('https://dashboard.livair.io/api/auth/token',
            data: {
              "refreshToken": refreshToken
            });
        token = loginResponse.data["token"];
        refreshToken = loginResponse.data["refreshToken"];
      }
      dio.options.headers['Authorization'] = "Bearer $token";
      Response userInfoResponse = await dio.get('https://dashboard.livair.io/api/auth/user');
      userId = userInfoResponse.data["id"]["id"];
      var result = await dio.get('https://dashboard.livair.io/api/plugins/telemetry/USER/$userId/values/timeseries',
        queryParameters: {
          "keys": "notifications",
          "startTs": 0,
          "endTs": DateTime.now().millisecondsSinceEpoch
        },
      );
      try{
        if(result.data["notifications"] != null){
          notifications = result.data["notifications"];
        }
        await getAllDevices();
      }catch(e){
        print(e);
      }
    }on DioError catch(e){
      print(e.response);
    }on Error catch(e){
      print(e);
    }
  }

  getAllDevices() async{
    deviceIds = [];
    labels = [];
    WebSocketChannel? channel;
    try {
      channel = WebSocketChannel.connect(
        Uri.parse(
            'wss://dashboard.livair.io/api/ws/plugins/telemetry?token=$token'),
      );
      channel.sink.add(
          jsonEncode(
              {
                "attrSubCmds": [],
                "tsSubCmds": [],
                "historyCmds": [],
                "entityDataCmds": [
                  {
                    "query": {
                      "entityFilter": {
                        "type": "entitiesByGroupName",
                        "resolveMultiple": true,
                        "groupStateEntity": true,
                        "stateEntityParamName": null,
                        "groupType": "DEVICE",
                        "entityGroupNameFilter": "All"
                      },
                      "pageLink": {
                        "pageSize": 1024,
                        "page": 0,
                        "sortOrder": {
                          "key": {
                            "type": "ENTITY_FIELD",
                            "key": "createdTime"
                          },
                          "direction": "DESC"
                        }
                      },
                      "entityFields": [
                        {
                          "type": "ENTITY_FIELD",
                          "key": "label"
                        }
                      ],
                      "latestValues": []
                    },
                    "cmdId": 1
                  },

                ],
                "entityDataUnsubscribeCmds": [],
                "alarmDataCmds": [],
                "alarmDataUnsubscribeCmds": [],
                "entityCountCmds": [],
                "entityCountUnsubscribeCmds": [],
                "alarmCountCmds": [],
                "alarmCountUnsubscribeCmds": []
              }
          )
      );
      channel.stream.listen((data) async {
        print(jsonDecode(data));
        List<dynamic> deviceData = jsonDecode(data)["data"]["data"];
        for(var element in deviceData){
          deviceIds.add(element["entityId"]["id"]);
          labels.add(element["latest"]["ENTITY_FIELD"]["label"]["value"]);
        }
        channel!.sink.close();
        setState(() {
          index = 1;
        });
        await Future<void>.delayed( const Duration(seconds: 1));
        notificationsLoaded = false;
      });
    }catch(e){
      print(e);
    }
  }

  Widget showNotificationsScreen(){
    if(notifications.isEmpty || labels.isEmpty){
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Text(AppLocalizations.of(context)!.notificationsT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
            ],
          ),
          automaticallyImplyLeading: false,
          iconTheme: const IconThemeData(
            color: Colors.black,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ImageIcon(AssetImage('lib/images/notifications.png'),size: 50,),
              const SizedBox(height: 15,),
              Text(AppLocalizations.of(context)!.upToDate),
              const SizedBox(height: 15,),
              Text(AppLocalizations.of(context)!.noNotificationsT),
            ],
          ),
        ),
      );
    }else{
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          title: Text(AppLocalizations.of(context)!.notificationsT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
          iconTheme: const IconThemeData(
            color: Colors.black,
          ),
          actions: [
            IconButton(
                onPressed: (){
                  AlertDialog alert = AlertDialog(
                    title: Text(AppLocalizations.of(context)!.deleteNotificationsQ, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                  onPressed: () async{
                                    try {
                                      final result = await InternetAddress.lookup('example.com');
                                      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                                      }
                                    } on SocketException catch (_) {
                                      Fluttertoast.showToast(
                                          msg: AppLocalizations.of(context)!.noInternetT
                                      );
                                      return;
                                    }
                                    setState(() {
                                      deleteNotifications();
                                      Navigator.pop(context);
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white,minimumSize: const Size(100, 50), side: const BorderSide(color: Color(0xff0099f0))),
                                  child: Text(AppLocalizations.of(context)!.contin,style: const TextStyle(color: Color(0xff0099f0)),)
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20,),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      Navigator.pop(context);
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white,minimumSize: const Size(100, 50), side: const BorderSide(color: Color(0xff0099f0))),
                                  child: Text(AppLocalizations.of(context)!.cancel,style: const TextStyle(color: Color(0xff0099f0)),)
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                  showDialog(
                    context: context,
                    builder: (BuildContext context){
                      return alert;
                    },
                  );
                },
                icon: const ImageIcon(AssetImage('lib/images/TrashbinButton.png'),)
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemBuilder: (BuildContext context, int index){
                  String deviceId = notifications.elementAt(index).keys.first;
                  int deviceIndex = deviceIds.indexOf(deviceId);

                  int msOnCreation = notifications.elementAt(index)["ts"];
                  Duration msSinceCreation = Duration(milliseconds: DateTime.now().subtract(Duration(milliseconds: msOnCreation)).millisecondsSinceEpoch);
                  String timeSinceCreation = "0 m";
                  if(msSinceCreation.inDays.toInt()!= 0){
                    timeSinceCreation = "${msSinceCreation.inMinutes} ${AppLocalizations.of(context)!.minutesAgo}";
                  }
                  if(msSinceCreation.inHours.toInt() !=0){
                    timeSinceCreation = "${msSinceCreation.inHours} ${AppLocalizations.of(context)!.hoursAgo}";
                  }
                  if(msSinceCreation.inDays.toInt() !=0){
                    timeSinceCreation = "${msSinceCreation.inDays} ${AppLocalizations.of(context)!.daysAgo}";
                  }
                  Map<String,dynamic> test = notifications.elementAt(index);
                  Map<String,dynamic> test2 = jsonDecode(test["value"]);
                  print(test);

                  return Container(
                    height: 100,
                    color: selectedNotifications.contains(index) ? const Color(0xffb0bec5) : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment:  MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(test2["subject"], style: const TextStyle(color: Colors.black, fontSize: 16),),
                                ],
                              ),
                              Text(timeSinceCreation),
                            ],
                          ),
                          const SizedBox(height: 15,),
                          Row(
                            children: [
                              Text("${test2["body"]}", style: const TextStyle(color: Colors.black),),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(height: 1,),
                itemCount: notifications.length
              ),
            )
          ],
        ),
      );
    }
  }

  deleteNotifications() async {
    String? userId;
    try{
      dio.options.headers['content-Type'] = 'application/json';
      dio.options.headers['Accept'] = "application/json";
      dio.options.headers['Authorization'] = "Bearer $token";
      if(DateTime.fromMillisecondsSinceEpoch(JwtDecoder.decode(token)["exp"]*1000).isBefore(DateTime.now())){
        Response loginResponse = await dio.post('https://dashboard.livair.io/api/auth/token',
            data: {
              "refreshToken": refreshToken
            });
        token = loginResponse.data["token"];
        refreshToken = loginResponse.data["refreshToken"];
      }
      dio.options.headers['Authorization'] = "Bearer $token";
      Response userInfoResponse = await dio.get('https://dashboard.livair.io/api/auth/user');
      userId = userInfoResponse.data["id"]["id"];
      await dio.delete('https://dashboard.livair.io/api/plugins/telemetry/USER/$userId/timeseries/delete',
        queryParameters: {
          "keys": "notifications",
          "startTs": 0,
          "endTs": DateTime.now().millisecondsSinceEpoch,
        },
      );
    }on DioException catch(e){
      print(e.response);
    }on Error catch(e){
      print(e);
    }
  }

  Widget setScreen() {
    switch (index) {
      case 0: return const Center();
      case 1: return showNotificationsScreen();
      default:
        return showNotificationsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    var build = FutureBuilder(
        future: getAllNotifications(),
        builder: (context,snapshot){
          return WillPopScope(
              onWillPop: () async{
                return false;
              },
          child: setScreen()
          );
        }
    );
    return build;
  }

}