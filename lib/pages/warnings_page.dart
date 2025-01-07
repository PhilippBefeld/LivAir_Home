
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../components/data/device.dart';
import '../components/my_device_widget.dart';

class WarningsPage extends StatefulWidget {

  final String token;
  final String refreshToken;

  const WarningsPage({super.key, required this.token, required this.refreshToken});

  @override
  State<WarningsPage> createState() => WarningsPageState(token, refreshToken);
}

class WarningsPageState extends State<WarningsPage>{

  String token;
  String refreshToken;
  final dio = Dio();


  final storage = FlutterSecureStorage();
  String? unit;

  WarningsPageState(this.token, this.refreshToken);
  //page variables
  int index = 0;

  //warnings
  List<dynamic> warnings = [];
  bool gettingWarnings = false;

  //devices and new warnings variables
  List<Map<String,Device2>> currentDevices2 = [];
  String selectedDevice = "";
  TextEditingController thresholdController = TextEditingController();
  int selectedHours = 0;
  int selectedMinutes = 0;


  getAllWarnings() async {
    if(gettingWarnings) return;
    gettingWarnings = true;
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
    warnings.clear();
    unit = await storage.read(key: 'unit');

    var response;
    try {
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
      response = await dio.get('https://dashboard.livair.io/api/livAir/warnings');
    }catch(e){
    }
    List<dynamic> data = response.data;
    for (var element in data) {
      warnings.add(element);
    }
    setState(() {

    });
    await Future<void>.delayed( const Duration(seconds: 1));
    gettingWarnings = false;
  }

  Widget showWarningsScreen(){
    if(warnings.isEmpty){
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Text(AppLocalizations.of(context)!.warningsT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
            ],
          ),
          automaticallyImplyLeading: false,
          iconTheme: const IconThemeData(
            color: Colors.black,
          ),
          actions: [
            IconButton(
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
                  getAllDevices();
                });
              },
              icon: const Icon(Icons.add,color: Color(0xff0099f0),),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ImageIcon(AssetImage('lib/images/warnings.png'),size: 50,),
              const SizedBox(height: 15,),
              Text(AppLocalizations.of(context)!.noWarningsYet),
              const SizedBox(height: 15,),
              Text(AppLocalizations.of(context)!.noWarningsT),
              const SizedBox(height: 30,),
              OutlinedButton(
                onPressed: () async {
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
                    getAllDevices();
                  });
                },
                style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),side: (const BorderSide(color: Color(0xff0099f0)))),
                child: Text(AppLocalizations.of(context)!.addWarning,style: const TextStyle(color: Colors.white),),
              )
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
          title: Row(
            children: [
              Text(AppLocalizations.of(context)!.warningsT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
            ],
          ),
          iconTheme: const IconThemeData(
            color: Colors.black,
          ),
          actions: [
            IconButton(
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
                    getAllDevices();
                  });
                },
                icon: const Icon(Icons.add,color: Color(0xff0099f0),),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                    separatorBuilder: (context, index) => const SizedBox(height: 1),
                    itemCount: warnings.length,
                    itemBuilder: (BuildContext context, int index){
                      return GestureDetector(
                          onTap: (){

                          },
                          child: Container(
                            height: 114,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      child: Text("${warnings.elementAt(index).values.elementAt(1)}",
                                        style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600, overflow: TextOverflow.ellipsis),
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 16,),
                                    Text("${warnings.elementAt(index).values.elementAt(2)} ${warnings.elementAt(index).values.elementAt(4)}",
                                      style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w400, overflow: TextOverflow.ellipsis)
                                    ),
                                    Text("${Duration(minutes: warnings.elementAt(index).values.elementAt(3)).toString().substring(0,2).replaceAll(":", "")}h ${Duration(minutes: warnings.elementAt(index).values.elementAt(3)).toString().substring(2,5).replaceAll(":", "")}m",
                                      style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                ),
                                IconButton(
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
                                      selectedDevice = warnings.elementAt(index).values.elementAt(0);
                                      deleteWarningDialog();
                                    },
                                    color: Colors.black,
                                    icon: const ImageIcon(AssetImage('lib/images/TrashbinButton.png'),)
                                )
                              ],
                            ),
                          )
                      );
                    },
                ),
              )
            ],
          ),
        ),
      );
    }
  }

  getAllDevices() async{
    WebSocketChannel? channel;
    try {
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

      String? customerId;
      Response customerInfoResponse = await dio.get('https://dashboard.livair.io/api/auth/user');
      customerId = customerInfoResponse.data["customerId"]["id"];
      var result2 = await dio.get('https://dashboard.livair.io/api/customer/$customerId/devices',
          queryParameters:
          {
            "pageSize": 1000,
            "page": 0
          }
      );
      Map<String,dynamic> map = result2.data;
      List list = map["data"];
      for (var element in list) {
        bool found = false;
        for( var element2 in currentDevices2){
          if(element2.keys.first == element["id"]["id"]){
            found = true;
          }
        }
        if(!found){
          var result2 = await dio.get('https://dashboard.livair.io/api/plugins/telemetry/DEVICE/${element["id"]["id"]}/values/timeseries',
              queryParameters:
              {
                "keys": "radon"
              }
          );
          var msSincelastSync = -1;
          try{
            msSincelastSync = (DateTime.now().millisecondsSinceEpoch-result2.data["radon"].elementAt(0)["ts"]).toInt();
          }catch(e){}
          currentDevices2.add({
            element["id"]["id"].toString() : Device2(
              lastSync : msSincelastSync,
              location : "/",
              floor : "",
              locationId : "/",
              isOnline : element["additionalInfo"]["syncStatus"] == "active" ? true : false,
              radon : int.parse(result2.data["radon"].elementAt(0)["value"] ?? "0"),
              label : element["label"],
              name : element["name"],
              deviceAdded: 1,
            )
          });
        }
      }
      setState(() {
        index = 1;
      });
    }catch(e){print(e);
    }
  }

  showSelectThresholdScreen(){
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                setState(() {
                  index = 1;
                });
              },
            ),
            Text(AppLocalizations.of(context)!.selectThresholdT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                const SizedBox(height: 20),
                Text(AppLocalizations.of(context)!.selectThresholdDialog1),
                const SizedBox(height: 20),
                TextField(
                  keyboardType: TextInputType.number,
                  controller: thresholdController,
                  autofocus: true,
                  decoration: InputDecoration(
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    hintText: unit == "Bq/m³" ? "Bq/m³": "pCi/L",
                    hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                  ),

                ),
                const SizedBox(height: 10),
                Text("${AppLocalizations.of(context)!.selectThresholdDialog2}${(unit == "Bq/m³" ? 150 : 150*37)} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"},${AppLocalizations.of(context)!.selectThresholdDialog3}"
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: ()=> setState(() {
                        index = 3;
                      }),
                      style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50)),
                      child: Text(AppLocalizations.of(context)!.selectDuration,style: const TextStyle(color: Colors.white),)
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }

  showDeviceSelectScreen(){
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          iconTheme: const IconThemeData(
            color: Colors.black,
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: (){
                  setState(() {
                    index = 0;
                  });
                },
              ),
              Text(AppLocalizations.of(context)!.selectDeviceT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.separated(
                separatorBuilder: (context, index) => const SizedBox(height: 10,),
                padding: const EdgeInsets.only(bottom: 10),
                itemCount: currentDevices2.length,
                itemBuilder: (BuildContext context, int deviceIndex) {
                  return MyDeviceWidget(
                    onTap: (){
                      selectedDevice = currentDevices2[deviceIndex].keys.first;
                      setState(() {
                        index = 2;
                      });
                    },
                    name: currentDevices2[deviceIndex].values.first.name,
                    isOnline: currentDevices2[deviceIndex].values.first.isOnline,
                    radonValue: currentDevices2[deviceIndex].values.first.radon,
                    lastSync: currentDevices2[deviceIndex].values.first.lastSync,
                    unit: unit == "Bq/m³" ? "Bq/m³": "pCi/L",
                    isViewer: false,
                  );
                },
              ),
            ),],
        ),
      );
  }

  showSelectDurationScreen(){
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                setState(() {
                  index = 2;
                });
              },
            ),
            Text(AppLocalizations.of(context)!.selectDurationT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context)!.selectDurationDialog),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TimePickerSpinner(
                  time: DateTime.fromMillisecondsSinceEpoch(0),
                  is24HourMode: true,
                  minutesInterval: 10,
                  onTimeChange: (time){
                    setState(() {
                      selectedHours = time.hour;
                      selectedMinutes = time.minute;
                    });
                  },
                ),
                const SizedBox(width: 24,),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("H",style: TextStyle(fontSize: 40),),
                SizedBox(width: 22,),
                Text("M",style: TextStyle(fontSize: 40),)
              ],
            ),
            Row(
              children: [

              ],
            ),
            const SizedBox(height: 20),
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
                        setState(() async{
                          updateWarning();
                          await Future.delayed(const Duration(milliseconds: 100));
                          index = 0;
                        });
                      } ,
                      style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50)),
                      child: Text(AppLocalizations.of(context)!.createWarning,style: const TextStyle(color: Colors.white),)
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }

  updateWarning() async{
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
      dio.post(
          "https://dashboard.livair.io/api/livAir/warning",
          data: jsonEncode(
              {
                "deviceId": selectedDevice,
                "radonUpperThreshold": int.parse(thresholdController.text),
                "radonAlarmDuration": selectedHours*60+selectedMinutes
              }
          ),
      );
    }catch(e){
    }
    selectedMinutes = 0;
    selectedHours = 0;
    thresholdController.text = "";
    selectedDevice = "";
    await Future<void>.delayed( const Duration(seconds: 1));
    setState(() {

    });
  }

  deleteWarningDialog() {
    AlertDialog alert = AlertDialog(
      title: Text(AppLocalizations.of(context)!.removeWarningT, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.removeWarningDialog),
          const SizedBox(height: 10,),
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
                    deleteWarning();
                  },
                  style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0)),
                  child: Text(AppLocalizations.of(context)!.removeWarning,style: const TextStyle(color: Colors.white),),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (){
                    selectedDevice = "";
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Color(0xff0099f0))),
                  child: Text(AppLocalizations.of(context)!.cancel,style: const TextStyle(color: Color(0xff0099f0)),),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  deleteWarning() async{
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";

    try{
      dio.delete(
        "https://dashboard.livair.io/api/livAir/warning/${selectedDevice}",
      );
    }catch(e){
    }
    selectedDevice = "";
    Navigator.pop(context);
    await Future<void>.delayed( const Duration(seconds: 1));
    setState(() {

    });
  }

  Widget setScreen() {
    switch (index) {
      case 0:
        return showWarningsScreen();
      case 1:
        return showDeviceSelectScreen();
      case 2:
        return showSelectThresholdScreen();
      case 3:
        return showSelectDurationScreen();
      default:
        return showWarningsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    var build = FutureBuilder(
        future: getAllWarnings(),
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