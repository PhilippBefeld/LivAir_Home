
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_material_symbols/flutter_material_symbols.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:livair_home/components/my_device_widget.dart';
import 'package:livair_home/pages/device_detail_page.dart';
import 'package:livair_home/components/data/device.dart';
import 'package:logger/logger.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:location/location.dart';

class DevicePage extends StatefulWidget {

  final String token;
  final String refreshToken;

  const DevicePage({super.key, required this.token, required this.refreshToken});

  @override
  State<DevicePage> createState() => DevicePageState(token, refreshToken);
}

class DevicePageState extends State<DevicePage> {

  String token;
  String refreshToken;
  final logger = Logger();
  final Dio dio = Dio();
  final location = Location();
  final storage = const FlutterSecureStorage();
  String? unit;

  List<String> isBtAvailable = [];

  DevicePageState(this.token, this.refreshToken);
  DeviceResponse pagingInfo = DeviceResponse(0,0);
  List<Map<String,dynamic>> currentDevices = [];
  List<Map<String,Device2>> currentDevices2 = [];
  List<String> currentRadonValues = [];
  bool searchedAdditionalDevices = false;

  List<DropdownMenuItem<String>> locationsDropdownMenuItems = [const DropdownMenuItem<String>(value: "Wähle einen Standort", child: Text("Wähle einen Standort"))];
  List<DropdownMenuItem<String>> floorsOfLocationDropdownMenuItems = [const DropdownMenuItem<String>(value: "Wähle ein Stockwerk", child: Text("Wähle ein Stockwerk"))];
  Map<String, List<DropdownMenuItem<String>>> floorsPerLocationDropdownMenuItems = {};
  WebSocketChannel? channel;

  //Screen control variables
  int screenIndex = 0;
  bool firstTry = true;

  //addDevice variables
  StreamSubscription<List<ScanResult>>? subscription;
  StreamSubscription<dynamic>? btChat;
  List<BluetoothDevice>? foundDevices;
  List<String>? foundDevicesIds;
  BluetoothDevice? deviceToAdd;
  Map<String, int> foundAccessPoints = {};
  String selectedWifiAccesspoint = "";
  String newDeviceId = "";
  TextEditingController newDeviceIdController = TextEditingController();
  BluetoothCharacteristic? writeCharacteristic;
  BluetoothCharacteristic? readCharacteristic;
  TextEditingController wifiPasswordController = TextEditingController();
  TextEditingController deviceNameController = TextEditingController();
  String newDeviceName = "";
  TextEditingController deviceLocationController = TextEditingController();
  String newDeviceLocation = "";

  Future<dynamic> getAllDevices() async{
    if(!firstTry)return;
    searchedAdditionalDevices = false;
    unit = await storage.read(key: 'unit');
    currentDevices2 = [];
    isBtAvailable = [];
    firstTry = false;
    try{
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
      if(!searchedAdditionalDevices){
        searchedAdditionalDevices = true;
        try {
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
          logger.d(result2.data);
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
          var result = await dio.get('https://dashboard.livair.io/api/user/devices',
              queryParameters:
              {
                "pageSize": 1000,
                "page": 0
              }
          );
          logger.d(result.data);
          map = result.data;
          list = map["data"];
          for (var element in list) {
            bool found = false;
            for( var element2 in currentDevices2){
              if(element2.keys.first == element["id"]["id"]){
                found = true;
              }
            }
            if(!found){
              var result = await dio.get('https://dashboard.livair.io/api/plugins/telemetry/DEVICE/${element["id"]["id"]}/values/timeseries',
                  queryParameters:
                  {
                    "keys": "radon"
                  }
              );
              var msSinceLastSync = -1;
              try{
                msSinceLastSync = (DateTime.now().millisecondsSinceEpoch-result.data["radon"].elementAt(0)["ts"]).toInt();
              }catch(e){}
              currentDevices2.add({
                element["id"]["id"].toString() : Device2(
                  lastSync : msSinceLastSync,
                  location : "/",
                  floor : "viewer",
                  locationId : "/",
                  isOnline : element["additionalInfo"]["syncStatus"] == "active" ? true : false,
                  radon : int.parse(result.data["radon"].elementAt(0)["value"] ?? "0"),
                  label : element["label"],
                  name : element["name"],
                  deviceAdded: 1,
                )
              });
            }
          }
          setState(() {

          });
          if (Platform.isAndroid) {
            await FlutterBluePlus.turnOn();
          }
          var locationEnabled = await location.serviceEnabled();
          if(!locationEnabled){
            var locationEnabled2 = await location.requestService();
            if(!locationEnabled2){
            }
          }
          var permissionGranted = await location.hasPermission();
          if(permissionGranted == PermissionStatus.denied){
            permissionGranted = await location.requestPermission();
            if(permissionGranted != PermissionStatus.granted){
            }
          }
          FlutterBluePlus.stopScan();
          bool deviceFound = false;
          bool listening = false;
          subscription = FlutterBluePlus.scanResults.listen((results) async {
            for (ScanResult r in results) {
              if (!deviceFound) {
                List<int> bluetoothAdvertisementData = [];
                String bluetoothDeviceName = "";
                if(r.advertisementData.manufacturerData.keys.isNotEmpty){
                  logger.d(r.advertisementData.manufacturerData);
                  if(r.advertisementData.manufacturerData.values.isNotEmpty){
                    bluetoothAdvertisementData = r.advertisementData.manufacturerData.values.first;
                  }
                  if(r.advertisementData.manufacturerData.keys.first == 3503) bluetoothDeviceName += utf8.decode(bluetoothAdvertisementData.sublist(15,23));
                  currentDevices2.forEach((device){
                    if(device.values.first.name == bluetoothDeviceName){
                      device.values.first.isBtAvailable = true;
                    }
                  });
                }
              }
            }
          });
          FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
          await Future<void>.delayed( const Duration(seconds: 4));
          setState(() {

          });
        }catch(e){
          print(e);
        }
      }

    }catch(e){
      Fluttertoast.showToast(
          msg: "Failed to receive data"
      );
    }
  }

  void showDeviceDetails(Map<String,Device2> device){

    Navigator.of(context).push(
        PageRouteBuilder(
            pageBuilder: (context, Animation<double> animation1, Animation<double> animation2) => DeviceDetailPage(token: token, refreshToken: refreshToken,device: device,),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero
        )
    ).then((_) => setState(() {
      firstTry = true;
    }));
  }


  Widget setPage(){
    switch(screenIndex){
      case 0: return deviceScreen();
      case 1: return claimDeviceScreen();
      case 11: return deviceWifiSelectScreen();
      case 12: return deviceWifiPasswordScreen();
      case 13: return deviceNameScreen();
      case 14: return deviceLocationScreen();
      case 15: return deviceScreenManual();
      default: return deviceScreen();
    }
  }

  deviceNameScreen(){
    if(btChat!=null)btChat!.cancel();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: (){
            setState(() {
              screenIndex = 0;
            });
          },
        ),
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.chooseMeaningfulName,style: const TextStyle(fontSize: 16),),
            const SizedBox(height: 30,),
            Text(AppLocalizations.of(context)!.deviceName),
            const SizedBox(height: 5,),
            TextField(
              controller: deviceNameController,
              decoration: InputDecoration(
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(width: 2,color: Colors.black),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(width: 2,color: Colors.black),
                ),
                fillColor: Colors.white,
                filled: true,
                hintText: AppLocalizations.of(context)!.egKitchen,
                hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
              ),
            ),
            const SizedBox(height: 30,),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: (){
                        newDeviceName = deviceNameController.text;
                        setState(() {
                          screenIndex = 14;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(width: 0),
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          minimumSize: const Size(60,50)
                      ),
                      child: Text(AppLocalizations.of(context)!.contin)
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  sendDeviceClaimRequest() async{
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
      await dio.post('https://dashboard.livair.io/api/livAir/claim',
          data:
          {
            "claimingKey": newDeviceId,
            "deviceName": newDeviceName,
            "location": newDeviceLocation
          }
      );
      deviceLocationController.text = "";
      deviceNameController.text = "";
      setState(() {
        screenIndex = 0;
      });
    }on DioException catch(e){
      setState(() {
        screenIndex = 0;
      });
      Fluttertoast.showToast(
          msg: e.error.toString().split("\n").elementAt(1)
      );
    }
  }

  deviceLocationScreen(){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: (){
            setState(() {
              screenIndex = 0;
            });
          },
        ),
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10,),
            Text(AppLocalizations.of(context)!.locationDialog),
            const SizedBox(height: 30,),
            Text(AppLocalizations.of(context)!.deviceLocation),
            const SizedBox(height: 5,),
            GooglePlaceAutoCompleteTextField(
              textEditingController: deviceLocationController,
              googleAPIKey: "AIzaSyAxry8f1YCKcXgQh6LOgCESzckFyryAgXE",
              inputDecoration: InputDecoration(
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(width: 2,color: Colors.black),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(width: 2,color: Colors.black),
                ),
                fillColor: Colors.white,
                filled: true,
                hintText: AppLocalizations.of(context)!.locationHint,
                hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
              ),
              debounceTime: 800, // default 600 ms,
              //countries: ["in","fr"],// optional by default null is set
              isLatLngRequired:true,// if you required coordinates from place detail
              getPlaceDetailWithLatLng: (Prediction prediction) {
                // this method will return latlng with place detail
                print("placeDetails${prediction.lng}");
              }, // this callback is called when isLatLngRequired is true
              itemClick: (Prediction prediction) {
                deviceLocationController.text = prediction.description!;
                deviceLocationController.selection = TextSelection.fromPosition(TextPosition(offset: prediction.description!.length));
              },
              // if we want to make custom list item builder
              itemBuilder: (context, index, Prediction prediction) {
                return Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on),
                      const SizedBox(
                        width: 7,
                      ),
                      Expanded(child: Text(prediction.description??""))
                    ],
                  ),
                );
              },
                  // if you want to add seperator between list items
            seperatedBuilder: const Divider(),
              // want to show close icon
            isCrossBtnShown: true,
            ),
            const SizedBox(height: 30,),
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
                        newDeviceLocation = deviceLocationController.text;
                        sendDeviceClaimRequest();
                      },
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(width: 0),
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          minimumSize: const Size(60,50)
                      ),
                      child: Text(AppLocalizations.of(context)!.finish)
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  deviceWifiPasswordScreen(){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: (){
            deviceToAdd!.disconnect(timeout: 1);
            deviceToAdd!.removeBond();
            btChat!.cancel();
            setState(() {
              screenIndex = 0;
            });
          },
        ),
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Text(AppLocalizations.of(context)!.connectToWifiT,style: const TextStyle( fontSize: 20,fontWeight: FontWeight.w400),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10,),
            Text(AppLocalizations.of(context)!.pleaseEnterWifiPassword),
            Text(selectedWifiAccesspoint, style: const TextStyle(fontWeight: FontWeight.bold),),
            const SizedBox(height: 36,),
            Text(AppLocalizations.of(context)!.password),
            const SizedBox(height: 36,),
            TextField(
              controller: wifiPasswordController,
              decoration: const InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(width: 2,color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(width: 2,color: Colors.black),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 36,),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: () {
                        writeCharacteristic!.write(utf8.encode("CONNECT:${foundAccessPoints[selectedWifiAccesspoint]},|${wifiPasswordController.text}"));
                      },
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(width: 0),
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          minimumSize: const Size(60,50)
                      ),
                      child: Text(AppLocalizations.of(context)!.connect,style: const TextStyle(color: Colors.white),)
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  deviceWifiSelectScreen() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: (){
            deviceToAdd!.disconnect(timeout: 1);
            deviceToAdd!.removeBond();
            btChat!.cancel();
            setState(() {
              screenIndex = 1;
            });
          },
        ),
        title: Text(AppLocalizations.of(context)!.connectToWifiT,style: const TextStyle( fontSize: 20,fontWeight: FontWeight.w400),),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.separated(
                itemBuilder: (BuildContext context, int index){
                  return OutlinedButton(
                      onPressed: () {
                        setState(() {
                          screenIndex = 12;
                          selectedWifiAccesspoint = foundAccessPoints.keys.elementAt(index);
                        });
                      },
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(width: 0),
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          minimumSize: const Size(60,50)
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(foundAccessPoints.keys.elementAt(index), style: const TextStyle(fontSize: 20,fontWeight: FontWeight.w400),),
                        ],
                      )
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(height: 0,),
                itemCount: foundAccessPoints.length
            ),
          ),
        ],
      ),
    );
  }

  claimDeviceScreen2() async{
    int foundAccesspointCount = 0;
    int counter = 0;
    foundAccessPoints = {};
    showDialog(context: context, builder: (context){
      return PopScope(
        canPop: false,
        child: Scaffold(
            body: Center(
                child:Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Searching for Wifi access points"),
                    const SizedBox(height: 36,),
                    const CircularProgressIndicator(color: Colors.black,),
                  ],
                )
            )
        ),
      );
    });

    await deviceToAdd!.connect();
    if (Platform.isAndroid) {
      await deviceToAdd!.requestMtu(100);
    }
    bool loginSuccessful = false;
    bool hasScanned = false;
    List<BluetoothService> services = await deviceToAdd!.discoverServices();
    for (var service in services){
      for(var characteristic in service.characteristics){
        if(characteristic.properties.notify){
          await characteristic.setNotifyValue(true);
          readCharacteristic = characteristic;
          btChat = characteristic.lastValueStream.listen((data) async{
            String message = utf8.decode(data).trim();
            print(utf8.decode(data));
            if(message == ""){
            }
            if(message == 'LOGIN OK' && !hasScanned){
              loginSuccessful = true;
              hasScanned = true;
              await Future<void>.delayed( const Duration(milliseconds: 300));
              await writeCharacteristic!.write(utf8.encode('SCAN'));
            }
            if(message.length >=7){
              if(message.substring(0,6) == 'Found:'){
                foundAccesspointCount = int.parse(message.substring(6,message.length));
              }
            }
            if(message.length>= 4 && message.contains(",|")){
              foundAccessPoints.addEntries([MapEntry(message.substring(message.indexOf("|")+1,message.indexOf(",",message.indexOf("|")+1)),int.parse(message.substring(0,message.indexOf(","))))]);
              counter++;
              if(counter==foundAccesspointCount){
                if(foundAccesspointCount ==0){
                  Navigator.pop(context);
                  setState(() {
                    screenIndex = 0;
                  });
                  Fluttertoast.showToast(
                      msg: "No access points found"
                  );
                }
                Navigator.pop(context);
                setState(() {
                  screenIndex = 11;
                });
              }
            }
            if(message == "Connect Success"){
              deviceToAdd!.disconnect(timeout: 1);
              deviceToAdd!.removeBond();
              setState(() {
                screenIndex = 13;
              });
              Fluttertoast.showToast(
                  msg: "Device successfully connected"
              );
            }
          });
        }
        if(characteristic.properties.write){
          writeCharacteristic = characteristic;
          await Future<void>.delayed( const Duration(milliseconds: 300));
          if(!loginSuccessful){
            try{
              loginSuccessful = true;
              await writeCharacteristic!.write(utf8.encode('k47t58W43Lds8'));
            }catch(e){
            }
          }
        }
      }
    }
  }



  searchAvailableDevices() async{
    showDialog(context: context, builder: (context){
      return PopScope(
        canPop: false,
        child: Scaffold(
            body: Center(
                child:Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Searching for devices in area"),
                    const SizedBox(height: 36,),
                    const CircularProgressIndicator(color: Colors.black,),
                  ],
                )
            )
        ),
      );
    });
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      }
    } on SocketException catch (_) {
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.noInternetT
      );
      Navigator.pop(context);
      return;
    }
    foundDevices = [];
    foundDevicesIds = [];

    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }
    var locationEnabled = await location.serviceEnabled();
    if(!locationEnabled){
      var locationEnabled2 = await location.requestService();
      if(!locationEnabled2){

      }
    }
    var permissionGranted = await location.hasPermission();
    if(permissionGranted == PermissionStatus.denied){
      permissionGranted = await location.requestPermission();
      if(permissionGranted != PermissionStatus.granted){
      }
    }
    FlutterBluePlus.scanResults.timeout( const Duration(seconds: 2));
    var subscription = FlutterBluePlus.scanResults.listen((results) async{
      for(ScanResult r in results){
        if(r.advertisementData.manufacturerData.keys.isNotEmpty){
          if(r.advertisementData.manufacturerData.keys.first == 3503){
            List<int> data = r.advertisementData.manufacturerData.values.elementAt(0).sublist(15,23);
            Iterable<int> dataIter = data;

            if(!foundDevicesIds!.contains(String.fromCharCodes(dataIter))){
              foundDevicesIds!.add(String.fromCharCodes(dataIter));
              foundDevices!.add(r.device);
            }
          }
        }
      }
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    await Future<void>.delayed( const Duration(seconds: 4));
    subscription.cancel();
    if(foundDevices!.isEmpty){
      Fluttertoast.showToast(
          msg: "No devices found"
      );
    }
    Navigator.pop(context);
    setState(() {
      screenIndex = 1;
    });
  }

  claimDeviceScreen(){

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: (){
            setState(() {
              screenIndex = 0;
            });
          },
        ),
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Text(AppLocalizations.of(context)!.visibleDevicesT,style: const TextStyle( fontSize: 20,fontWeight: FontWeight.w400),),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(height: 1,),
              padding: const EdgeInsets.only(bottom: 10),
              itemCount: foundDevicesIds!.length,
              itemBuilder: (BuildContext context, int index) {
                String? ifHasLabel;
                for (var element in currentDevices2) {
                  if(element.values.first.name.toUpperCase() == foundDevicesIds![index]){
                    ifHasLabel = element.values.first.label;
                  }
                }
                return OutlinedButton(
                    onPressed: (){
                      newDeviceId = foundDevicesIds![index];
                      deviceToAdd = foundDevices![index];
                      AlertDialog alert = AlertDialog(
                        title: Text(AppLocalizations.of(context)!.connectWifiQ, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(AppLocalizations.of(context)!.connectWifiT),
                            const SizedBox(height: 10,),
                            OutlinedButton(
                                onPressed: (){
                                  Navigator.pop(context);
                                  claimDeviceScreen2();
                                },
                                style: OutlinedButton.styleFrom(
                                    side: const BorderSide(width: 0),
                                    foregroundColor: const Color(0xff0099F0),
                                    backgroundColor: const Color(0xff0099F0),
                                    minimumSize: const Size(60,50)
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(AppLocalizations.of(context)!.connect, style: const TextStyle(fontSize: 20,fontWeight: FontWeight.w400, color: Colors.white),),
                                  ],
                                )
                            ),
                            const SizedBox(height: 10,),
                            OutlinedButton(
                                onPressed: (){
                                  Navigator.pop(context);
                                  setState(() {
                                    screenIndex = 13;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                    side: const BorderSide(width: 0),
                                    foregroundColor: Colors.black,
                                    backgroundColor: Colors.white,
                                    minimumSize: const Size(60,50)
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(AppLocalizations.of(context)!.skip, style: const TextStyle(fontSize: 20,fontWeight: FontWeight.w400),),
                                  ],
                                )
                            ),
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
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(width: 0),
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        minimumSize: const Size(60,50)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(ifHasLabel ?? foundDevicesIds![index], style: const TextStyle(fontSize: 20,fontWeight: FontWeight.w400),),
                      ],
                    )
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: OutlinedButton(
                    onPressed: (){
                      newDeviceName = deviceNameController.text;
                      setState(() {
                        screenIndex = 15;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(width: 0),
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      minimumSize: const Size(60,50)
                    ),
                    child: Text(AppLocalizations.of(context)!.addDevManually,style: const TextStyle(color: Colors.black),)
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  deviceScreenManual(){
    return FutureBuilder(
        future: getAllDevices(),
        builder: (context,snapshot) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: (){
                  setState(() {
                    screenIndex = 1;
                  });
                },
              ),
              iconTheme: const IconThemeData(
                color: Colors.black,
              ),
              backgroundColor: Colors.white,
              titleTextStyle: const TextStyle(color: Colors.black),
              title: Text(AppLocalizations.of(context)!.addDevManuallyT,style: const TextStyle( fontSize: 20,fontWeight: FontWeight.w400),),
            ),
            body: SafeArea(
              child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10,),
                            Text(AppLocalizations.of(context)!.deviceIDDialog),
                            const SizedBox(height: 30,),
                            TextField(
                              controller: newDeviceIdController,
                              decoration: InputDecoration(
                                enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(width: 2,color: Colors.black),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(width: 2,color: Colors.black),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                hintText: AppLocalizations.of(context)!.deviceIDHint,
                                hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                  onPressed: (){
                                    newDeviceId = newDeviceIdController.text;
                                    setState(() {
                                      screenIndex = 13;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                      side: const BorderSide(width: 0),
                                      foregroundColor: Colors.black,
                                      backgroundColor: Colors.white,
                                      minimumSize: const Size(60,50)
                                  ),
                                  child: Text(AppLocalizations.of(context)!.contin,style: const TextStyle(color: Colors.black),)
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
              ),
            ),
          );
        }
    );
  }

  showColorInfo(){
    AlertDialog alert = AlertDialog(
      title: Text("Radon Index", style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('lib/images/radonranges.png'),
          Row(
            children: [
              SizedBox(width:24,height:28,child: Image.asset('lib/images/greenLine.png')),
              SizedBox(width: 10,),
              Text("No action required", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),),
            ],
          ),
          Row(
            children: [
              SizedBox(width:24,height:28,child: Image.asset('lib/images/yellowLine.png')),
              SizedBox(width: 10,),
              Text("Consider actions (eg. ventilating)", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),),
            ],
          ),
          Row(
            children: [
              SizedBox(width:24,height:28,child: Image.asset('lib/images/redLine.png')),
              SizedBox(width: 10,),
              Text("Action strongly recommended)", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),),
            ],
          ),
          SizedBox(height: 10,),
          Text("*Measuring interval: 10 min", style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),),
        ],
      ),
    );
    showDialog(
      context: context,
      builder: (BuildContext context){
        return alert;
      },
    );
  }
  
  deviceScreen(){
    return FutureBuilder(
        future: getAllDevices(),
        builder: (context,snapshot) {
          return Scaffold(
            appBar: AppBar(
              iconTheme: const IconThemeData(
                color: Colors.black,
              ),
              backgroundColor: Colors.white,
              titleTextStyle: const TextStyle(color: Colors.black),
              automaticallyImplyLeading: false,
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
                        channel = null;
                        firstTry = true;
                      });
                    },
                    icon: const Icon(MaterialSymbols.refresh,color: Color(0xff0099f0),)
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
                      searchAvailableDevices();
                    },
                    icon: const Icon(MaterialSymbols.add,color: Color(0xff0099f0),)
                ),
              ],
              elevation: 0,
              title: Row(
                children: [
                  Text(AppLocalizations.of(context)!.allDevicesT,style: const TextStyle( fontSize: 20,fontWeight: FontWeight.w400),),
                  IconButton(onPressed: showColorInfo, icon: const Icon(Icons.info_outline),color: const Color(0xff0099f0))
                ],
              ),
              centerTitle: false,
            ),
            body: SafeArea(
              child: Center(
                  child: Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async{
                            setState(() {
                              channel = null;
                              firstTry = true;
                            });
                          },
                          child: ListView.separated(
                            separatorBuilder: (context, index) => const SizedBox(height: 0,),
                            padding: const EdgeInsets.only(bottom: 10),
                            itemCount: currentDevices2.length,
                            itemBuilder: (BuildContext context, int index) {
                              return MyDeviceWidget(
                                onTap: () async{
                                  showDeviceDetails(currentDevices2[index]);
                                },
                                name: currentDevices2[index].values.elementAt(0).floor == "viewer" ?  "${currentDevices2[index].values.elementAt(0).label} (as Viewer)" : currentDevices2[index].values.elementAt(0).label!,
                                isOnline: currentDevices2[index].values.elementAt(0).isOnline,
                                lastSync: currentDevices2[index].values.elementAt(0).lastSync,
                                radonValue: currentDevices2[index].values.elementAt(0).radon,
                                unit: unit == "Bq/m³" ? "Bq/m³": "pCi/L",
                                isViewer: currentDevices2[index].values.elementAt(0).floor == "viewer" ? true : false,
                                isBtAvailable: currentDevices2[index].values.elementAt(0).isBtAvailable,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  )
              ),
            ),
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
   return PopScope(
       canPop: false,
       child: setPage()
   );
  }
}

class DeviceResponse {
  final int deviceCount;
  final int pageCount;

  DeviceResponse(this.deviceCount, this.pageCount);

  DeviceResponse.fromJson(Map<String, dynamic> json)
        :deviceCount = json['totalElements'],
        pageCount = json['totalPages'];
}
