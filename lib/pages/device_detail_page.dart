
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_symbols/flutter_material_symbols.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:location/location.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../components/data/device.dart';
import '../components/line_chart_data/line_chart_data.dart';
import 'package:google_places_flutter/google_places_flutter.dart';

class DeviceDetailPage extends StatefulWidget {

  final String token;
  final String refreshToken;
  final Map<String,Device2> device;


  const DeviceDetailPage({super.key, required this.token, required this.refreshToken, required this.device});

  @override
  State<DeviceDetailPage> createState() => DeviceDetailPageState(token, refreshToken, device);
}

class DeviceDetailPageState extends State<DeviceDetailPage>{

  String token;
  String refreshToken;

  final Dio dio = Dio();
  final logger = Logger();
  final location = Location();

  final Map<String,Device2> device;



  DeviceDetailPageState(this.token, this.refreshToken, this.device);

  int screenIndex = 0;

  final storage = FlutterSecureStorage();

  //deactivate loading data
  bool loaded = false;
  bool loadedInternet = false;

  var value = 0.0;
  //radon unit,
  String? unit;
  String? deviceInternetIP;
  //switch betweem thimgsboard and BT values
  bool useBluetoothData = false;

  bool changeDiagram = false;
  bool showDiagramDots = false;
  bool showAllData = false;

  //websocket channel
  WebSocketChannel? channel;

  //radon data
  List<dynamic> radonHistory = [];
  List<Tuple2<int,int>> radonHistoryTimestamps = [];
  List<int> radonValuesTimeseries = [];

  //chart
  List<ChartData> chartSpots = [];
  List<BarChartGroupData> chartBars = [];
  int selectedNumberOfDays = 1;
  int currentMaxValue = 0;
  int currentMinValue = 0;
  int currentAvgValue = 0;
  int currentMaxAvgValue = 100;
  int currentMaxAvgValueSpots = 100;
  int stepsIntoPast = 1;

  //misc
  List<String> tzLocations = [];
  List<String> tzCodes = [];
  String currentTZ = "";
  String tzServer1 = "";
  String tzServer2 = "";
  String tzServer3 = "";
  TextEditingController customNTPServerController = TextEditingController();
  DetailResponse? detailResponse;
  List<Details> details = [];
  String radonValue = "";
  bool futureFuncRunning = false;
  bool telemetryRunning = false;
  bool firstTry = true;
  int requestMsSinceEpoch = 0;
  bool transmitionMethodSettings = false;

  //deviceInfoScreen
  String firmwareVersion = "";
  int calibrationDate = 0;

  //general telemetry
  bool sentSuccessfullBTTelemetery = false;

  //deviceLightsScreen
  double d_led_fb = 1.0;
  double d_led_fb_old = 1.0;
  double d_led_tb = 1.0;
  double d_led_tb_old = 1.0;
  bool d_led_t = false;
  bool d_led_f = false;
  TextEditingController orangeMinValue = TextEditingController();
  TextEditingController redMinValue = TextEditingController();
  int d_unit = 1;
  int clock = 0;
  int clockType = 0;
  int mezType = 1;
  int displayAnimation = 1;


  //exportDataScreen
  bool customTimeseriesSelected = false;
  DateTime customTimeseriesStart = DateTime.now();
  DateTime customTimeseriesEnd = DateTime.now();

  //renameDeviceScreen
  TextEditingController renameController = TextEditingController();

  //locationScreen
  TextEditingController deviceLocationController = TextEditingController();

  //shareDeviceScreen
  TextEditingController emailController = TextEditingController();
  List<dynamic> viewerData = [];
  String emailToRemove = "";

  //wifiScreen
  String currentWifiName = "Not connected";
  StreamSubscription<List<ScanResult>>? subscription;
  StreamSubscription<List<int>>? subscriptionToDevice;
  Map<String, int> foundAccessPoints = {};
  String selectedWifiAccesspoint = "";
  BluetoothDevice? btDevice;
  BluetoothCharacteristic? writeCharacteristic;
  BluetoothCharacteristic? readCharacteristic;
  TextEditingController wifiPasswordController = TextEditingController();

  //offlineData
  int radonCurrent = 0;
  int radonDaily = 0;
  int radonEver = 0;
  bool readGraph = false;
  bool useBtGraph = false;
  int BtTimestampCount = -1;
  int currentBtTimestampCount = -1;

  //warningScreen
  TextEditingController thresHoldController = TextEditingController();
  int selectedHours = 0;
  int selectedMinutes = 0;

  //clockScreen
  String timezoneCountry = "None selected";
  String timezoneCity = "None selected";
  List<String> tzOfSelection = [];
  String tzSelected = "";

  //knx screen
  bool knxProgMode = false;
  bool knxOnOff = false;
  TextEditingController knxPhysAddress = TextEditingController();
  String? knxPhysIDError;
  TextEditingController knxGroup1 = TextEditingController();
  TextEditingController knxGroup2 = TextEditingController();
  TextEditingController knxGroup3 = TextEditingController();
  TextEditingController knxGroup4 = TextEditingController();
  String? knxGroupError1;
  String? knxGroupError2;
  String? knxGroupError3;
  String? knxGroupError4;
  String knxParam0 = "";
  String knxParam1 = "";
  TextEditingController knxIP = TextEditingController();
  TextEditingController knxSubnetMask = TextEditingController();
  TextEditingController knxGateway = TextEditingController();
  TextEditingController knxMultiCastAddress = TextEditingController();
  String? knxIPError;
  String? knxSubnetMaskError;
  String? knxGatewayError;
  String? knxMultiCastError;

  //Cloud screen
  bool cloudOnOff = false;
  TextEditingController cloudServer = TextEditingController();
  TextEditingController cloudPage = TextEditingController();
  TextEditingController cloudPaChain= TextEditingController();
  TextEditingController cloudPre = TextEditingController();

  //MQTT screen
  TextEditingController mqttClient = TextEditingController();
  TextEditingController mqttServer = TextEditingController();
  TextEditingController mqttUser = TextEditingController();
  TextEditingController mqttPort = TextEditingController();
  TextEditingController mqttTopic = TextEditingController();
  bool mqttOnOff = false;
  
  

  final MaterialStateProperty<Icon?> sliderIcon =
  MaterialStateProperty.resolveWith<Icon?>(
        (Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return const Icon(Icons.chevron_left);
      }
      return const Icon(Icons.chevron_right);
    },
  );

  final MaterialStateProperty<Color?> sliderColor =
  MaterialStateProperty.resolveWith<Color?>(
        (Set<MaterialState> states) {
      return const Color(0xff0099F0);
    },
  );
  final MaterialStateProperty<Color?> trackBorderColor =
  MaterialStateProperty.resolveWith<Color?>(
        (Set<MaterialState> states) {
      return const Color(0xffCCEBFC);
    },
  );

  final MaterialStateProperty<Color?> trackColor =
  MaterialStateProperty.resolveWith<Color?>(
        (Set<MaterialState> states) {
      return const Color(0xffCCEBFC);
    },
  );

  Future<dynamic> futureFunc() async{
    if(futureFuncRunning) return;
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      }
    } on SocketException catch (_) {
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.noInternetT
      );
      useBluetoothData = true;
      try{
        channel!.sink.add({
          "cmds": [
            {
              "entityType": "DEVICE",
              "entityId": device.keys.elementAt(0),
              "scope": "CLIENT_SCOPE",
              "cmdId": 1,
              "unsubscribe": true
            }
          ]
        });
      }catch(e){
      }
      setState(() {
      });
      return;
    }

    if(!device.values.first.isOnline){
      useBluetoothData = true;
      try{
        channel!.sink.add({
          "cmds": [
            {
              "entityType": "DEVICE",
              "entityId": device.keys.elementAt(0),
              "scope": "CLIENT_SCOPE",
              "cmdId": 1,
              "unsubscribe": true
            }
          ]
        });
      }catch(e){
      }
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.noDataOnline
      );
      setState(() {
      });
      return;
    }

    currentMaxAvgValue = 0;
    currentMaxAvgValueSpots= 0;
    futureFuncRunning = true;

    currentTZ = await storage.read(key: 'timezone') ?? "";
    unit = await storage.read(key: 'unit');

    radonValue = AppLocalizations.of(context)!.noRadonValues;
    String id = device.keys.elementAt(0);
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
      channel = WebSocketChannel.connect(
        Uri.parse('wss://dashboard.livair.io/api/ws/plugins/telemetry?token=$token'),
      );
      channel!.sink.add(
        jsonEncode(
          {
            "attrSubCmds":[
                {
                  "entityType":"DEVICE",
                  "entityId":id,
                  "scope":"CLIENT_SCOPE",
                  "cmdId":0
                }
                ],
            "tsSubCmds":[],
            "historyCmds":[],
            "entityDataCmds":[],
            "entityDataUnsubscribeCmds":[],
            "alarmDataCmds":[],
            "alarmDataUnsubscribeCmds":[],
            "entityCountCmds":[],
            "entityCountUnsubscribeCmds":[],
            "alarmCountCmds":[],
            "alarmCountUnsubscribeCmds":[]
          },
        ),
      );
      channel!.sink.add(
        jsonEncode(
          {
            "attrSubCmds":[],
            "tsSubCmds": [
              {
                "entityType":"DEVICE",
                "entityId":id,
                "scope":"CLIENT_SCOPE",
                "cmdId":0
              }
              ],
            "historyCmds":[],
            "entityDataCmds":[],
            "entityDataUnsubscribeCmds":[],
            "alarmDataCmds":[],
            "alarmDataUnsubscribeCmds":[],
            "entityCountCmds":[],
            "entityCountUnsubscribeCmds":[],
            "alarmCountCmds":[],
            "alarmCountUnsubscribeCmds":[]
          },
        ),
      );
      channel!.sink.add(
        jsonEncode(
          {
            "attrSubCmds":[
              {
                "entityType":"DEVICE",
                "entityId":id,
                "scope":"SHARED_SCOPE",
                "cmdId":1
              }
            ],
            "tsSubCmds":[],
            "historyCmds":[],
            "entityDataCmds":[],
            "entityDataUnsubscribeCmds":[],
            "alarmDataCmds":[],
            "alarmDataUnsubscribeCmds":[],
            "entityCountCmds":[],
            "entityCountUnsubscribeCmds":[],
            "alarmCountCmds":[],
            "alarmCountUnsubscribeCmds":[]
          },
        ),
      );
      channel!.sink.add(
        jsonEncode(
          {
            "attrSubCmds":[],
            "tsSubCmds": [
              {
                "entityType":"DEVICE",
                "entityId":id,
                "scope":"SHARED_SCOPE",
                "cmdId":1
              }
            ],
            "historyCmds":[],
            "entityDataCmds":[],
            "entityDataUnsubscribeCmds":[],
            "alarmDataCmds":[],
            "alarmDataUnsubscribeCmds":[],
            "entityCountCmds":[],
            "entityCountUnsubscribeCmds":[],
            "alarmCountCmds":[],
            "alarmCountUnsubscribeCmds":[]
          },
        ),
      );
      channel!.stream.listen(
            (data) {
              if(jsonDecode(data)["subscriptionId"] == 1 && firstTry){
                firstTry = false;
                requestMsSinceEpoch = DateTime.now().millisecondsSinceEpoch;
                channel!.sink.add(
                  jsonEncode(
                      {
                        "attrSubCmds": [],
                        "tsSubCmds": [],
                        "historyCmds": [],
                        "entityDataCmds": [
                          {
                            "query": {
                              "entityFilter": {
                                "type": "singleEntity",
                                "singleEntity": {
                                  "id": device.keys.elementAt(0),
                                  "entityType": "DEVICE"
                                }
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
                                },
                                {
                                  "type": "ENTITY_FIELD",
                                  "key": "name"
                                },
                                {
                                  "type": "ENTITY_FIELD",
                                  "key": "additionalInfo"
                                }
                              ],
                              "latestValues": [
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "location"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "locationId"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "floor"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "deviceAdded"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "serialNumber"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "lastSync"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "lastActivityTime"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "availableKeys"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "isOnline"
                                }
                              ]
                            },
                            "cmdId": 2
                          }
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
                channel!.sink.add(
                  jsonEncode(
                      {
                        "attrSubCmds": [],
                        "tsSubCmds": [],
                        "historyCmds": [],
                        "entityDataCmds": [
                          {
                            "cmdId": 2,
                            "historyCmd": {
                              "keys": [
                                "score",
                                "radon"
                              ],
                              "startTs": 1694383200000,
                              "endTs": requestMsSinceEpoch,
                              "interval": 1000,
                              "limit": 50000,
                              "agg": "NONE"
                            },
                            "latestCmd": {
                              "keys": [
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "location"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "locationId"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "floor"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "deviceAdded"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "serialNumber"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "lastSync"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "lastActivityTime"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "availableKeys"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "isOnline"
                                }
                              ]
                            }
                          }
                        ],
                        "entityDataUnsubscribeCmds": [],
                        "alarmDataCmds": [],
                        "alarmDataUnsubscribeCmds": [],
                        "entityCountCmds": [],
                        "entityCountUnsubscribeCmds": [],
                        "alarmCountCmds": [],
                        "alarmCountUnsubscribeCmds": []
                      }
                  ),
                );
              }
              var allData = jsonDecode(data);
              var telData = jsonDecode(data)["data"];
              try{
                var radonData = telData["radon"];
                if(radonData!=null)radonValue = radonData[0][1];
              }catch(e){
              }

              try{
                var dLedFBdata = telData["current_fw_version"];
                if(dLedFBdata!=null)firmwareVersion = dLedFBdata[0][1];
              }catch(e){
              }
              try{
                var dLedFBdata = telData["Sensor_kalibriert"];
                if(dLedFBdata!=null)calibrationDate = dLedFBdata[0][0];
              }catch(e){
                calibrationDate = 0;
              }
              try{
                var dLedFBdata = telData["d_led_fb"];
                if(dLedFBdata!=null)d_led_fb = int.parse(dLedFBdata[0][1]).toDouble();
                if(dLedFBdata!=null)d_led_fb_old = int.parse(dLedFBdata[0][1]).toDouble();
              }catch(e){
              }
              try{
                var dLedTBdata = telData["d_led_tb"];
                if(dLedTBdata!=null)d_led_tb = int.parse(dLedTBdata[0][1]).toDouble();
                if(dLedTBdata!=null)d_led_tb_old = int.parse(dLedTBdata[0][1]).toDouble();
              }catch(e){
              }
              try{
                var dRangeMdata = telData["d_range_m"];
                if(dRangeMdata!=null)orangeMinValue.text = dRangeMdata[0][1];
              }catch(e){
              }
              try{
                var dRangeTdata = telData["d_range_t"];
                if(dRangeTdata!=null)redMinValue.text = dRangeTdata[0][1];
              }catch(e){
              }
              try{
                var dLedTData = telData["d_led_t"];
                int displayStatus;
                if(dLedTData!=null){
                  displayStatus = int.parse(dLedTData[0][1]);
                    displayStatus==1 ? d_led_t = true : d_led_t = false;
                }
              }catch(e){
              }
              try{
                var dLedFData = telData["d_led_f"];
                int ledStatus;
                if(dLedFData!=null){
                  ledStatus = int.parse(dLedFData[0][1]);
                    ledStatus==1 ? d_led_f = true : d_led_f = false;
                }
              }catch(e){
              }
              try{
                var dUnitData = telData["d_unit"];
                if(dUnitData!=null) d_unit = dUnitData[0][1];
              }catch(e){
              }
              try{
                var dUnitData = telData["u_view_switch"];
                if(dUnitData!=null) clock = int.parse(dUnitData[0][1]);
              }catch(e){
              }
              try{
                var dUnitData = telData["u_clock"];
                if(dUnitData!=null) clockType = int.parse(dUnitData[0][1]);
              }catch(e){
              }
              try{
                var dUnitData = telData["u_mez_ea"];
                if(dUnitData!=null) mezType = int.parse(dUnitData[0][1]);
              }catch(e){
              }
              try{
                var dUnitData = telData["u_led_tf"];
                if(dUnitData!=null) displayAnimation = int.parse(dUnitData[0][1]);
              }catch(e){
              }
              try{
                var dUnitData = telData["u_timezone"];
                //if(dUnitData!=null) currentTZ = dUnitData[0][1];
              }catch(e){
              }
              try{
                var dUnitData = telData["u_ntp1"];
                if(dUnitData!=null) tzServer1 = dUnitData[0][1];
              }catch(e){
              }
              try{
                var dUnitData = telData["u_ntp2"];
                if(dUnitData!=null) tzServer2 = dUnitData[0][1];
              }catch(e){
              }
              try{
                var dUnitData = telData["u_ntp3"];
                if(dUnitData!=null) tzServer3 = dUnitData[0][1];
              }catch(e){
              }
              try{
                var dUnitData = telData["ssid"];
                if(dUnitData!=null) currentWifiName = dUnitData[0][1];
              }catch(e){
              }
              try{
                var dUnitData = telData["localIp"];
                if(dUnitData!=null) deviceInternetIP = dUnitData[0][1];
              }catch(e){
              }
              List<dynamic> updateData = [];
              if(jsonDecode(data)["cmdId"]!=null && jsonDecode(data)["update"]!=null)updateData = jsonDecode(data)["update"];
              if(updateData.isNotEmpty) {
                for (var element in updateData) {
                  try {
                    List<dynamic> radonValues = element["timeseries"]["radon"];
                    device.values.first.isOnline = jsonDecode(updateData.first["latest"]["ENTITY_FIELD"]["additionalInfo"]["value"].toString())["syncStatus"] == "active" ? true : false;
                    if(radonValues.isNotEmpty) {
                      radonHistory = radonValues;
                      radonHistoryTimestamps = [];
                      for (var element in radonHistory) {
                        Tuple2<int, int> singleTimestamp = Tuple2<int, int>(element['ts'], unit == "Bq/m³" ? int.parse(element['value']) : int.parse(element['value'])*27);
                        radonHistoryTimestamps.add(singleTimestamp);
                      }
                      radonCurrent = radonHistoryTimestamps.first.item2;
                      chartSpots = getCurrentSpots();
                      chartBars = getCurrentBars();
                      List<int> barSizes = [];
                      chartBars.forEach((bar) {
                        barSizes.add(bar.barRods.first.toY.toInt());
                      });
                      currentMaxAvgValue = ((barSizes.reduce(max) / 100).ceil()) * 100;
                    }else{
                      radonHistory = radonValues;
                      radonHistoryTimestamps = [];
                      radonCurrent = 0;
                      chartSpots = getCurrentSpots();
                      chartBars = getCurrentBars();
                      List<int> barSizes = [];
                      chartBars.forEach((bar) {
                        barSizes.add(bar.barRods.first.toY.toInt());
                      });
                      currentMaxAvgValue = ((barSizes.reduce(max) / 100).ceil()) * 100;
                    }
                    loadedInternet = true;
                    setState(() {
                      screenIndex = 1;
                    });
                  } catch (e) {
                  }
                }
              }
            },
        onError: (error){
        },
      );
    }catch (e) {
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.failedLoadData
      );
    }
  }

  sendTelemetry(String name, int value, String btValue) async{
    if(telemetryRunning)return;
    telemetryRunning = true;
    if(!transmitionMethodSettings) {
      try {
        final result = await InternetAddress.lookup('example.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        }
      } on SocketException catch (_) {
        Fluttertoast.showToast(
            msg: AppLocalizations.of(context)!.noInternetT
        );
        telemetryRunning = false;
        return;
      }
      String id = device.keys.elementAt(0);
      dio.options.headers['content-Type'] = 'application/json';
      dio.options.headers['Accept'] = "application/json";
      dio.options.headers['Authorization'] = "Bearer $token";
      try{
        if(DateTime.fromMillisecondsSinceEpoch(JwtDecoder.decode(token)["exp"]*1000).isBefore(DateTime.now())){
          Response loginResponse = await dio.post('https://dashboard.livair.io/api/auth/token',
              data: {
                "refreshToken": refreshToken
              });
          token = loginResponse.data["token"];
          refreshToken = loginResponse.data["refreshToken"];
        }
        dio.options.headers['Authorization'] = "Bearer $token";
        dio.post('https://dashboard.livair.io/api/plugins/telemetry/DEVICE/$id/SHARED_SCOPE',
          data: jsonEncode(
              {
                name: value,
              }
          ),
        );
        sentSuccessfullBTTelemetery = true;
      }catch(e){
      }
      telemetryRunning = false;
      return;
    }
    try{
      showDialog(context: context, builder: (context) {
        return Scaffold(
            body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.searchingDevice),
                    const SizedBox(height: 36,),
                    const CircularProgressIndicator(color: Colors.black,),
                  ],
                )
            )
        );
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
      bool sentSuccessfully = false;
      bool loginSuccessful = false;
      subscription = FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
          if (!deviceFound) {
            List<int> bluetoothAdvertisementData = [];
            String bluetoothDeviceName = "";
            if(r.advertisementData.manufacturerData.keys.isNotEmpty){
              if(r.advertisementData.manufacturerData.values.isNotEmpty){
                bluetoothAdvertisementData = r.advertisementData.manufacturerData.values.first;
              }
              if(r.advertisementData.manufacturerData.keys.first == 3503) bluetoothDeviceName += utf8.decode(bluetoothAdvertisementData.sublist(15,23));
              if(bluetoothDeviceName == device.values.first.name){
                radonValue = bluetoothAdvertisementData.elementAt(1).toString();
                radonCurrent = bluetoothAdvertisementData.elementAt(1);
                radonDaily = bluetoothAdvertisementData.elementAt(5);
                currentAvgValue = bluetoothAdvertisementData.elementAt(5);
                radonEver = bluetoothAdvertisementData.elementAt(9);
                deviceFound = true;
                FlutterBluePlus.stopScan();
                subscription!.cancel();
                btDevice = r.device;
                try{
                  await btDevice!.connect();
                }catch(e){
                  Navigator.of(context).pop();
                  setState(() {

                  });
                  return;
                }
                try{
                  if (Platform.isAndroid) {
                    await r.device.requestMtu(300);
                  }
                  List<BluetoothService> services = await r.device.discoverServices();
                  for (var service in services){
                    for(var characteristic in service.characteristics){
                      if(characteristic.properties.notify){
                        await characteristic.setNotifyValue(true);
                        readCharacteristic = characteristic;
                        subscriptionToDevice = readCharacteristic!.lastValueStream.timeout(
                            Duration(seconds: 2),
                            onTimeout: (list)async{
                              await btDevice!.disconnect(timeout: 1);
                              btDevice!.removeBond();
                              subscriptionToDevice?.cancel();
                              loaded = true;
                              setState(() {
                                screenIndex = 1;
                                Navigator.pop(context);
                              });
                              Fluttertoast.showToast(
                                  msg: "Error"
                              );
                            }
                        ).listen((data) async{
                          String message = utf8.decode(data).trim();
                          //logger.d(utf8.decode(data));
                          if(message == "" && !loginSuccessful){
                            await Future<void>.delayed(const Duration(seconds: 1));
                            if(!loginSuccessful){
                              try{
                                loginSuccessful = true;
                                await writeCharacteristic!.write(utf8.encode('k47t58W43Lds8'));
                              }catch(e){
                              }
                            }
                          }
                          if(message == 'LOGIN OK'){
                            sentSuccessfully = true;
                            await writeCharacteristic!.write(utf8.encode(btValue));
                            sentSuccessfullBTTelemetery = true;
                            await btDevice!.disconnect(timeout: 1);
                            btDevice!.removeBond();
                            subscriptionToDevice?.cancel();
                            Navigator.pop(context);
                            setState(() {

                            });
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
                            await btDevice!.disconnect(timeout: 1);
                            btDevice!.removeBond();
                            subscriptionToDevice?.cancel();
                            Navigator.pop(context);
                            setState(() {

                            });
                          }
                        }
                      }
                    }
                  }
                }catch(e){
                  await btDevice!.disconnect(timeout: 1);
                  btDevice!.removeBond();
                  subscriptionToDevice?.cancel();
                  Navigator.pop(context);
                }
              }
            }
          }
        }
      });
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 3));
      await Future<void>.delayed( const Duration(seconds: 3));
      if(!deviceFound){
        subscription!.cancel();
        Navigator.pop(context);
      }
      if(!sentSuccessfully  && loginSuccessful){
        await btDevice!.disconnect(timeout: 1);
        btDevice!.removeBond();
        subscriptionToDevice?.cancel();
        Navigator.pop(context);
      }
    }catch(e){
      try{
        await btDevice!.disconnect(timeout: 1);
        btDevice!.removeBond();
        subscriptionToDevice?.cancel();
        Navigator.pop(context);
      }catch(e){
      }
    }
    telemetryRunning = false;
  }

  void setTimezone(String value) async{
    String id = device.keys.elementAt(0);
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";
    try{
      if(DateTime.fromMillisecondsSinceEpoch(JwtDecoder.decode(token)["exp"]*1000).isBefore(DateTime.now())){
        Response loginResponse = await dio.post('https://dashboard.livair.io/api/auth/token',
            data: {
              "refreshToken": refreshToken
            });
        token = loginResponse.data["token"];
        refreshToken = loginResponse.data["refreshToken"];
        dio.options.headers['Authorization'] = "Bearer $token";
      }
      dio.post('https://dashboard.livair.io/api/plugins/telemetry/DEVICE/$id/SHARED_SCOPE',
        data: jsonEncode(
            {
              "u_timezone": value,
            }
        ),
      );
    }catch(e){
    }
    if(!transmitionMethodSettings) {
      telemetryRunning = false;
      return;
    }
    try{
      showDialog(context: context, builder: (context) {
        return Scaffold(
            body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.searchingDevice),
                    const SizedBox(height: 36,),
                    const CircularProgressIndicator(color: Colors.black,),
                  ],
                )
            )
        );
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
      bool sentSuccessfully = false;
      bool loginSuccessful = false;
      subscription = FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
          if (!deviceFound) {
            List<int> bluetoothAdvertisementData = [];
            String bluetoothDeviceName = "";
            if(r.advertisementData.manufacturerData.keys.isNotEmpty){
              if(r.advertisementData.manufacturerData.values.isNotEmpty){
                bluetoothAdvertisementData = r.advertisementData.manufacturerData.values.first;
              }
              if(r.advertisementData.manufacturerData.keys.first == 3503) bluetoothDeviceName += utf8.decode(bluetoothAdvertisementData.sublist(15,23));
              if(bluetoothDeviceName == device.values.first.name){
                radonValue = bluetoothAdvertisementData.elementAt(1).toString();
                radonCurrent = bluetoothAdvertisementData.elementAt(1);
                radonDaily = bluetoothAdvertisementData.elementAt(5);
                currentAvgValue = bluetoothAdvertisementData.elementAt(5);
                radonEver = bluetoothAdvertisementData.elementAt(9);
                deviceFound = true;
                FlutterBluePlus.stopScan();
                subscription!.cancel();
                btDevice = r.device;
                try{
                  await btDevice!.connect();
                }catch(e){
                  Navigator.of(context).pop();
                  setState(() {

                  });
                  return;
                }
                try{
                  if (Platform.isAndroid) {
                    await r.device.requestMtu(300);
                  }
                  List<BluetoothService> services = await r.device.discoverServices();
                  for (var service in services){
                    for(var characteristic in service.characteristics){
                      if(characteristic.properties.notify){
                        await characteristic.setNotifyValue(true);
                        readCharacteristic = characteristic;
                        subscriptionToDevice = readCharacteristic!.lastValueStream.timeout(
                            Duration(seconds: 2),
                            onTimeout: (list)async{
                              await btDevice!.disconnect(timeout: 1);
                              btDevice!.removeBond();
                              subscriptionToDevice?.cancel();
                              loaded = true;
                              setState(() {
                                screenIndex = 1;
                                Navigator.pop(context);
                              });
                              Fluttertoast.showToast(
                                  msg: "Error"
                              );
                            }
                        ).listen((data) async{
                          String message = utf8.decode(data).trim();
                          //logger.d(utf8.decode(data));
                          if(message == "" && !loginSuccessful){
                            await Future<void>.delayed(const Duration(seconds: 1));
                            if(!loginSuccessful){
                              try{
                                loginSuccessful = true;
                                await writeCharacteristic!.write(utf8.encode('k47t58W43Lds8'));
                              }catch(e){
                              }
                            }
                          }
                          if(message == 'LOGIN OK'){
                            sentSuccessfully = true;
                            await writeCharacteristic!.write(utf8.encode('S31:${value}'));
                            await Future<void>.delayed( const Duration(milliseconds: 500));
                            await btDevice!.disconnect(timeout: 1);
                            btDevice!.removeBond();
                            subscriptionToDevice?.cancel();
                            Navigator.pop(context);
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
                            await btDevice!.disconnect(timeout: 1);
                            btDevice!.removeBond();
                            subscriptionToDevice?.cancel();
                            Navigator.pop(context);
                          }
                        }
                      }
                    }
                  }
                }catch(e){
                  await btDevice!.disconnect(timeout: 1);
                  btDevice!.removeBond();
                  subscriptionToDevice?.cancel();
                  Navigator.pop(context);
                }
              }
            }
          }
        }
      });
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 3));
      await Future<void>.delayed( const Duration(seconds: 3));
      if(!deviceFound){
        subscription!.cancel();
        Navigator.pop(context);
      }
      if(!sentSuccessfully && loginSuccessful){
        await btDevice!.disconnect(timeout: 1);
        btDevice!.removeBond();
        subscriptionToDevice?.cancel();
        Navigator.pop(context);
      }
    }catch(e){
      try{
        await btDevice!.disconnect(timeout: 1);
        btDevice!.removeBond();
        subscriptionToDevice?.cancel();
        Navigator.pop(context);
      }catch(e){
      }
    }
  }

  void setNTPServer(String value) async{
    String id = device.keys.elementAt(0);
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";
    try{
      if(DateTime.fromMillisecondsSinceEpoch(JwtDecoder.decode(token)["exp"]*1000).isBefore(DateTime.now())){
        Response loginResponse = await dio.post('https://dashboard.livair.io/api/auth/token',
            data: {
              "refreshToken": refreshToken
            });
        token = loginResponse.data["token"];
        refreshToken = loginResponse.data["refreshToken"];
      }
      dio.options.headers['Authorization'] = "Bearer $token";
      dio.post('https://dashboard.livair.io/api/plugins/telemetry/DEVICE/$id/SHARED_SCOPE',
        data: jsonEncode(
            {
              "u_ntp3": value,
            }
        ),
      );
    }catch(e){
    }
  }

  List<ChartData> getCurrentSpots(){
    radonHistoryTimestamps.sort((a,b) {
      return a.item1.compareTo(b.item1);
    });
    radonHistoryTimestamps = radonHistoryTimestamps.reversed.toList();
    int startTimeseries =  selectedNumberOfDays == 0 ? radonHistoryTimestamps.last.item1 : requestMsSinceEpoch - (Duration(days: selectedNumberOfDays).inMilliseconds * stepsIntoPast);
    List<ChartData> spots = [];
    radonValuesTimeseries = [];
    int sum = 0;
    if(selectedNumberOfDays == 0){
      for (var element in radonHistoryTimestamps) {
        sum+=element.item2;
        radonValuesTimeseries.add(element.item2);
        spots.add(ChartData(DateTime.fromMillisecondsSinceEpoch(element.item1),element.item2.toDouble()));
      }
    }else{
      for (var element in radonHistoryTimestamps) {
        if(element.item1 >= startTimeseries && element.item1 <= startTimeseries + Duration(days: selectedNumberOfDays).inMilliseconds){
          sum+=element.item2;
          radonValuesTimeseries.add(element.item2);
          spots.add(ChartData(DateTime.fromMillisecondsSinceEpoch(element.item1),element.item2.toDouble()));
        }
      }
    }
    if(useBluetoothData){
      int counter = 0;
      while(counter<spots.length-2){
        if(spots[counter].x == spots[counter+1].x){
          spots[counter+1] = ChartData(spots[counter+1].x.add(const Duration(minutes: 30)),spots[counter+1].y);
        }
        counter++;
      }
    }
    if(radonValuesTimeseries.isEmpty){
      currentAvgValue = 0;
      currentMaxValue = 0;
    }else {
      currentAvgValue = sum~/radonValuesTimeseries.length;
      currentMaxValue = radonValuesTimeseries.reduce(max);
      currentMinValue = radonValuesTimeseries.reduce(min);
    }
    if(showAllData){
      if(spots.length == 0){
        return [
          ChartData(DateTime.fromMillisecondsSinceEpoch(startTimeseries + (Duration(days: selectedNumberOfDays).inMilliseconds)), null),
          ChartData(DateTime.fromMillisecondsSinceEpoch(startTimeseries), null)
        ];
      }
      List<ChartData> newSpots = [];
      int counter = 0;
      int p = 0;
      while(spots[counter].x.millisecondsSinceEpoch <= (requestMsSinceEpoch - Duration(minutes: 11).inMilliseconds - Duration(minutes: 10).inMilliseconds*p)){
        newSpots.add(ChartData(DateTime.fromMillisecondsSinceEpoch(spots[counter].x.millisecondsSinceEpoch - Duration(minutes: 10).inMilliseconds*p), null));
        p++;
      }
      for (var spot in spots) {
        newSpots.add(spot);
        if(spots.length>counter+1){
          p = 0;
          while(spots[counter+1].x.millisecondsSinceEpoch <= (spots[counter].x.millisecondsSinceEpoch - Duration(minutes: 11).inMilliseconds - Duration(minutes: 10).inMilliseconds*p)){
            newSpots.add(ChartData(DateTime.fromMillisecondsSinceEpoch(spots[counter].x.millisecondsSinceEpoch - Duration(minutes: 10).inMilliseconds*p), null));
            p++;
          }
        }
        counter++;
      }
      while(spots[spots.length-1].x.millisecondsSinceEpoch - Duration(minutes: 10).inMilliseconds*p >= startTimeseries){
        newSpots.add(ChartData(DateTime.fromMillisecondsSinceEpoch(spots[spots.length-1].x.millisecondsSinceEpoch - Duration(minutes: 10).inMilliseconds*p), null));
        p++;
      }
      newSpots.add(ChartData(DateTime.fromMillisecondsSinceEpoch(requestMsSinceEpoch - (Duration(days: selectedNumberOfDays).inMilliseconds * (stepsIntoPast-1))), null));
      return newSpots.reversed.toList();
    }
    List<ChartData> newSpots = [];
    int i = 0;
    if(spots.isEmpty){
      return [
        ChartData(DateTime.fromMillisecondsSinceEpoch(requestMsSinceEpoch - (Duration(days: selectedNumberOfDays).inMilliseconds * (stepsIntoPast-1))), null),
        ChartData(DateTime.fromMillisecondsSinceEpoch(startTimeseries), null)
      ];
    }
    if(selectedNumberOfDays == -2){
      while(i < spots.length-1){
        newSpots.add(spots[i]);
        for(var j = spots[i].x.millisecondsSinceEpoch; j - const Duration(minutes: 11).inMilliseconds > spots[i+1].x.millisecondsSinceEpoch; j -= const Duration(minutes: 10).inMilliseconds){
          newSpots.add(ChartData(DateTime.fromMillisecondsSinceEpoch(j), 0));
        }
        i++;
      }
      newSpots.add(spots[i]);
    }else{

      int k = 0;
      int step = Duration(minutes: 10).inMilliseconds * (selectedNumberOfDays == 1 ? 6 : selectedNumberOfDays == 2 ? 12 : selectedNumberOfDays == 7 ? 36 : selectedNumberOfDays == 30 ? 144 : 144);
      double currentSum = 0;
      int currentSpots = 0;
      int i = 0;
      while( requestMsSinceEpoch - (Duration(days: selectedNumberOfDays).inMilliseconds * (stepsIntoPast-1)) - k*step >= startTimeseries ){
        while(i<spots.length && spots[i].x.millisecondsSinceEpoch <= requestMsSinceEpoch - (Duration(days: selectedNumberOfDays).inMilliseconds * (stepsIntoPast-1)) - k*step && spots[i].x.millisecondsSinceEpoch > requestMsSinceEpoch - (Duration(days: selectedNumberOfDays).inMilliseconds * (stepsIntoPast-1)) - (k+1)*step){
          currentSum+= spots[i].y!;
          currentSpots +=1;
          i++;
        }
        newSpots.add(ChartData(DateTime.fromMillisecondsSinceEpoch((requestMsSinceEpoch - (Duration(days: selectedNumberOfDays).inMilliseconds * (stepsIntoPast-1))-step*k-step*0.5).toInt()), currentSum/currentSpots));
        k++;
        currentSum = 0;
        currentSpots = 0;
      }
      List<double> yWerteDurchschnitt = [];
      newSpots.forEach((spot){
        if(spot.y != null ){
          if(!spot.y!.isNaN)yWerteDurchschnitt.add(spot.y!);
        }
      });
      currentMaxValue = yWerteDurchschnitt.reduce(max).toInt();
      currentMinValue = yWerteDurchschnitt.reduce(min).toInt();
    }
    return newSpots.reversed.toList();
  }

  List<BarChartGroupData> getCurrentBars(){
    List<BarChartGroupData> bars = [];
    int startTimeseries = requestMsSinceEpoch - (Duration(days: selectedNumberOfDays).inMilliseconds * stepsIntoPast);
    radonValuesTimeseries = [];
    List<FlSpot> spots = [];
    for (var element in radonHistoryTimestamps) {
      if(element.item1 >= startTimeseries && element.item1 <= startTimeseries + Duration(days: selectedNumberOfDays).inMilliseconds){
        radonValuesTimeseries.add(element.item2);
        spots.add(FlSpot(Duration(milliseconds: (element.item1-startTimeseries)).inMinutes.toDouble(),element.item2.toDouble()));
      }
    }
    int barCount = 24;
    int combinationArea = (Duration(days: selectedNumberOfDays).inMinutes~/24);
    if(selectedNumberOfDays == 7){
      barCount = 28;
      combinationArea = (Duration(days: selectedNumberOfDays).inMinutes~/28);
    }
    if(selectedNumberOfDays == 30){
      barCount = 30;
      combinationArea = (Duration(days: selectedNumberOfDays).inMinutes~/30);
    }

    int j = 0;
    int k = 0;
    for(int i = Duration(days: selectedNumberOfDays).inMinutes; i >= 0; i-=combinationArea){
      double avgOfArea = 0.0;
      double sum = 0;
      int spotsInArea = 0;
      if(k > barCount)break;
      if(j < spots.length){
        while(spots.elementAt(j).x >= i-combinationArea && spots.elementAt(j).x <= i){
          spotsInArea+=1;
          sum += spots.elementAt(j).y;
          if(j+1 >= spots.length) {
            j+=2;
            break;
          }
          j+=1;
        }
      }
      if(spotsInArea > 0){
        avgOfArea = sum/spotsInArea;
        bars.add(
            BarChartGroupData(
              x: barCount - k,
              barRods: [
                BarChartRodData(
                  toY: avgOfArea,
                  color: avgOfArea > 100 ? avgOfArea > 300 ? const Color(0xfffd4c56) : const Color(0xfffdca03) : const Color(0xff0ace84),
                )
              ]
            )
        );
      }else{
        bars.add(
            BarChartGroupData(
                x: barCount - k,
                barRods: [
                  BarChartRodData(
                    toY: 0,
                    color: Colors.green,
                  )
                ]
            )
        );
      }
      k+=1;
    }
    return bars.reversed.toList();
  }

  deviceDetailScreen(bool isWide){
    return isWide ? Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          iconTheme: const IconThemeData(
            color: Colors.black,
          ),
          backgroundColor: Colors.white,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: (){
                        setState(() {
                          try{
                            channel!.sink.add({
                              "cmds": [
                                {
                                  "entityType": "DEVICE",
                                  "entityId": device.keys.elementAt(0),
                                  "scope": "CLIENT_SCOPE",
                                  "cmdId": 1,
                                  "unsubscribe": true
                                }
                              ]
                            });
                          }catch(e){
                          }
                          Navigator.pop(context);
                        });
                      },
                    ),
                    Flexible(
                        child: Tooltip(
                            message: device.values.elementAt(0).label!=null ? device.values.elementAt(0).label!  : device.values.elementAt(0).name,
                            child: Text(device.values.elementAt(0).label!=null ? device.values.elementAt(0).label!  : device.values.elementAt(0).name, style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),overflow: TextOverflow.ellipsis,maxLines: 1,)
                        )
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  !useBluetoothData ? const ImageIcon(AssetImage('lib/images/isOnline.png'),color: Color(0xff0099F0),) : const ImageIcon(AssetImage('lib/images/isOnline.png'),color: Color(0xffCFD8DC),),
                  const SizedBox(width: 5,),
                  Switch(
                    thumbIcon: sliderIcon,
                    trackOutlineColor: trackBorderColor,
                    thumbColor: sliderColor,
                    trackColor: trackColor,
                    value: useBluetoothData,
                    onChanged: (bool value) {
                      chartBars = [];
                      chartSpots = [];
                      radonHistory = [];
                      radonValuesTimeseries = [];
                      loaded = false;
                      loadedInternet = false;
                      futureFuncRunning = false;
                      firstTry = true;
                      selectedNumberOfDays = 1;
                      useBluetoothData = value;
                      radonHistoryTimestamps = [];
                      try{
                        channel!.sink.add({
                          "cmds": [
                            {
                              "entityType": "DEVICE",
                              "entityId": device.keys.elementAt(0),
                              "scope": "CLIENT_SCOPE",
                              "cmdId": 1,
                              "unsubscribe": true
                            }
                          ]
                        });
                      }catch(e){
                      }
                      setState(() {
                      });
                    },
                  ),
                  useBluetoothData ? const ImageIcon(AssetImage('lib/images/isBluetooth.png'),color: Color(0xff0099F0),) : const ImageIcon(AssetImage('lib/images/isBluetooth.png'),color: Color(0xffCFD8DC),),
                ],
              ),
            ],
          ),
          titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20),
          centerTitle: false,
          actions:  [
            IconButton(
              visualDensity: const VisualDensity(horizontal: -4.0, vertical: 0),
              constraints: BoxConstraints(maxWidth: 30),
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: () async{
                loaded = false;
                loadedInternet = false;
                futureFuncRunning = false;
                firstTry = true;
                if(useBluetoothData){
                  readGraph = false;
                }
                try{
                  channel!.sink.add({
                    "cmds": [
                      {
                        "entityType": "DEVICE",
                        "entityId": device.keys.elementAt(0),
                        "scope": "CLIENT_SCOPE",
                        "cmdId": 1,
                        "unsubscribe": true
                      }
                    ]
                  });
                }catch(e){
                }
                setState(() {
                });
              },
            ),
            device.values.elementAt(0).floor != "viewer" ? PopupMenuButton(
                itemBuilder: (context)=>[
                  PopupMenuItem(
                    value: 1,
                    child: Text(AppLocalizations.of(context)!.deviceInfo),
                    onTap: () async{
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
                        screenIndex = 3;
                      });
                    },
                  ),
                  PopupMenuItem(
                    value: 2,
                    child: Text(AppLocalizations.of(context)!.deviceSettings),
                    onTap: () async{
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
                        screenIndex = 2;
                      });
                    },
                  ),
                  PopupMenuItem(
                    value: 5,
                    child: Text(AppLocalizations.of(context)!.exportData),
                    onTap: () async{
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
                        screenIndex = 5;
                      });
                    },
                  ),
                  PopupMenuItem(
                    value: 6,
                    child: Text(AppLocalizations.of(context)!.shareDevice),
                    onTap: () async{
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
                        screenIndex = 6;
                      });
                    },
                  ),
                  PopupMenuItem(
                    value: 8,
                    child: Text(AppLocalizations.of(context)!.warning),
                    onTap: () async{
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
                        screenIndex = 8;
                      });
                    },
                  ),
                  PopupMenuItem(
                    value: 9,
                    child: Text(AppLocalizations.of(context)!.identify),
                    onTap: () async{
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
                        identifyDevice();
                      });
                    },
                  ),
                  PopupMenuItem(
                    value: 10,
                    child: Text(AppLocalizations.of(context)!.delete),
                    onTap: () async{
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
                        deleteDevice();
                      });
                    },
                  ),
                ]
            ) : PopupMenuButton(
                itemBuilder: (context)=>[
                  PopupMenuItem(
                    value: 1,
                    child: Text(AppLocalizations.of(context)!.deviceInfo),
                    onTap: () async{
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
                        screenIndex = 3;
                      });
                    },
                  ),
                  PopupMenuItem(
                    value: 5,
                    child: Text(AppLocalizations.of(context)!.exportData),
                    onTap: () async{
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
                        screenIndex = 5;
                      });
                    },
                  ),
                  PopupMenuItem(
                    value: 9,
                    child: Text(AppLocalizations.of(context)!.stopViewing),
                    onTap: () async{
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
                      stopViewingDialog();
                    },
                  ),
                ]
            )
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('lib/images/radonranges_vertical.png', height: 150,),
                        SizedBox(
                          height: 160,
                          child: radonCurrent <= 100 ? Column(

                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(height: 148-(48*(radonCurrent/100)),),
                              Image.asset('lib/images/indicator_green.png', height: 10,),
                            ],
                          ) : radonCurrent <= 300 ? Column(

                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(height: 97-(48*((radonCurrent-100)/200)),),
                              Image.asset('lib/images/indicator_yellow.png', height: 10,),
                            ],
                          ) : radonCurrent <= 450 ? Column(

                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(height: 46-(46*((radonCurrent-300)/150)),),
                              Image.asset('lib/images/indicator_red.png', height: 10,),
                            ],
                          ) : Column(

                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Image.asset('lib/images/indicator_red.png', height: 10,),
                            ],
                          ),

                        ),
                        SizedBox(width: 20,),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              !useBluetoothData ? Duration(milliseconds: requestMsSinceEpoch-(radonHistoryTimestamps.isNotEmpty ? radonHistoryTimestamps.first.item1 : 0)).inMinutes < 60 ? "${Duration(milliseconds: requestMsSinceEpoch-(radonHistoryTimestamps.isNotEmpty ? radonHistoryTimestamps.first.item1 : 0)).inMinutes} ${AppLocalizations.of(context)!.minsAgo}" :  Duration(milliseconds: requestMsSinceEpoch-(radonHistoryTimestamps.isNotEmpty ? radonHistoryTimestamps.first.item1 : 0)).inHours < 12 ? "${Duration(milliseconds: requestMsSinceEpoch-(radonHistoryTimestamps.isNotEmpty ? radonHistoryTimestamps.first.item1 : 0)).inHours} ${AppLocalizations.of(context)!.hoursAgo}" : "${Duration(milliseconds: requestMsSinceEpoch-(radonHistoryTimestamps.isNotEmpty ? radonHistoryTimestamps.first.item1 : 0)).inDays} ${AppLocalizations.of(context)!.daysAgo}" : AppLocalizations.of(context)!.currentValue,
                              style: const TextStyle(
                                  color: Color(0xff78909C),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400
                              ),
                            ),
                            Row(
                              children: [
                                Text(!useBluetoothData ? radonHistoryTimestamps.isNotEmpty ? "${radonHistoryTimestamps.first.item2} " : "0 " :
                                  "$radonCurrent ",
                                  style: TextStyle(
                                    color: !useBluetoothData ? (radonHistoryTimestamps.isNotEmpty ? radonHistoryTimestamps.first.item2: 0) > 100 ? (radonHistoryTimestamps.isNotEmpty ? radonHistoryTimestamps.first.item2: 0) > 300 ? const Color(0xfffd4c56) : const Color(0xfffdca03) : const Color(0xff0ace84) :
                                    radonCurrent > 100 ? radonCurrent > 300 ? const Color(0xfffd4c56) : const Color(0xfffdca03) : const Color(0xff0ace84) ,
                                    fontSize: 62,
                                    fontWeight: FontWeight.w600
                                  ),
                                ),
                                Column(
                                  children: [
                                    SizedBox(height: 25,),
                                    Text(unit == "Bq/m³" ? "Bq/m³": "pCi/L",
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w400
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20,),
                    SizedBox(
                      height: 35,
                      child: Center(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                          children: [
                            Container(
                              height: 20,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                                child: OutlinedButton(
                                  onPressed: (){
                                    setState((){
                                      stepsIntoPast = 1;
                                      selectedNumberOfDays = 1;
                                      chartSpots = getCurrentSpots();
                                      chartBars = getCurrentBars();
                                      List<int> barSizes = [];
                                      chartBars.forEach((bar) {
                                        barSizes.add(bar.barRods.first.toY.toInt());
                                      });
                                      currentMaxAvgValue = ((barSizes.reduce(max)/100).ceil())*100;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20)
                                    ),
                                    side: BorderSide(width: 2,color: selectedNumberOfDays == 1 ? const Color(0xff0099F0) : const Color(0xff4f99F0)),
                                    foregroundColor: Colors.black,
                                    backgroundColor: selectedNumberOfDays == 1 ? const Color(0xff0099F0) : Colors.white,
                                  ),
                                  child: Text(AppLocalizations.of(context)!.last24h,style: TextStyle(
                                      color: selectedNumberOfDays == 1 ? Colors.white : const Color(0xff0099F0)
                                  ),),
                                ),
                              ),
                            ),
                            Container(
                              height: 30,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                                child: OutlinedButton(
                                  onPressed: (){
                                    setState((){
                                      stepsIntoPast = 1;
                                      selectedNumberOfDays = 2;
                                      chartSpots = getCurrentSpots();
                                      chartBars = getCurrentBars();
                                      List<int> barSizes = [];
                                      chartBars.forEach((bar) {
                                        barSizes.add(bar.barRods.first.toY.toInt());
                                      });
                                      currentMaxAvgValue = ((barSizes.reduce(max)/100).ceil())*100;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20)
                                      ),
                                      side: BorderSide(width: 2,color: selectedNumberOfDays == 2 ? const Color(0xff0099F0) : const Color(0xff4f99F0)),
                                      foregroundColor: Colors.black,
                                      backgroundColor: selectedNumberOfDays == 2 ? const Color(0xff0099F0) : Colors.white,
                                      minimumSize: const Size(60,20)
                                  ),
                                  child: Text(AppLocalizations.of(context)!.last48h,style: TextStyle(
                                      color: selectedNumberOfDays == 2 ? Colors.white : const Color(0xff0099F0)
                                  ),),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 30,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                                child: OutlinedButton(
                                  onPressed: ()=>{
                                    setState((){
                                      stepsIntoPast = 1;
                                      selectedNumberOfDays = 7;
                                      chartSpots = getCurrentSpots();
                                      chartBars = getCurrentBars();
                                      List<int> barSizes = [];
                                      chartBars.forEach((bar) {
                                        barSizes.add(bar.barRods.first.toY.toInt());
                                      });
                                      currentMaxAvgValue = ((barSizes.reduce(max)/100).ceil())*100;
                                    })
                                  },
                                  style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20)
                                      ),
                                      side: BorderSide(width: 2,color: selectedNumberOfDays == 7 ? const Color(0xff0099F0) : const Color(0xff4f99F0)),
                                      foregroundColor: Colors.black,
                                      backgroundColor: selectedNumberOfDays == 7 ? const Color(0xff0099F0) : Colors.white,
                                      minimumSize: const Size(60,20)
                                  ),
                                  child: Text(AppLocalizations.of(context)!.last7d,style: TextStyle(
                                      color: selectedNumberOfDays ==7 ? Colors.white : const Color(0xff0099F0)
                                  ),),
                                ),
                              ),
                            ),
                            Container(
                              height: 30,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                                child: OutlinedButton(
                                  onPressed: ()=>{
                                    setState((){
                                      stepsIntoPast = 1;
                                      selectedNumberOfDays = 30;
                                      chartSpots = getCurrentSpots();
                                      chartBars = getCurrentBars();
                                      List<int> barSizes = [];
                                      chartBars.forEach((bar) {
                                        barSizes.add(bar.barRods.first.toY.toInt());
                                      });
                                      currentMaxAvgValue = ((barSizes.reduce(max)/100).ceil())*100;
                                    })
                                  },
                                  style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20)
                                      ),
                                      side: BorderSide(width: 2,color: selectedNumberOfDays == 30 ? const Color(0xff0099F0) : const Color(0xff4f99F0)),
                                      foregroundColor: Colors.black,
                                      backgroundColor: selectedNumberOfDays == 30 ? const Color(0xff0099F0) : Colors.white,
                                      minimumSize: const Size(60,20)
                                  ),
                                  child:  Text(AppLocalizations.of(context)!.last30d,style: TextStyle(
                                      color: selectedNumberOfDays == 30 ? Colors.white : const Color(0xff0099F0)
                                  ),),
                                ),
                              ),
                            ),
                            Container(
                              height: 30,
                              child: OutlinedButton(
                                onPressed: ()=>{
                                  setState((){
                                    stepsIntoPast = 1;
                                    selectedNumberOfDays = 0;
                                    showAllData = false;
                                    chartSpots = getCurrentSpots();
                                    chartBars = getCurrentBars();
                                  })
                                },
                                style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20)
                                    ),
                                    side: BorderSide(width: 2,color: selectedNumberOfDays == 0 ? const Color(0xff0099F0) : const Color(0xff4f99F0)),
                                    foregroundColor: Colors.black,
                                    backgroundColor: selectedNumberOfDays == 0 ? const Color(0xff0099F0) : Colors.white,
                                    minimumSize: const Size(60,20)
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.completeHistory,
                                  style: TextStyle(
                                      color: selectedNumberOfDays == 0 ? Colors.white : const Color(0xff0099F0)
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20,),
                    SizedBox(
                      height: 60,
                      width: MediaQuery.sizeOf(context).width-20,
                      child: FittedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: !((radonHistoryTimestamps.length == 0) && useBluetoothData) ? [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Min.     \n" + (unit == "Bq/m³" ? "Bq/m³": "pCi/L"),
                                        style: TextStyle(
                                            color: Color(0xff78909C),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400
                                        ),
                                      ),
                                      Text("$currentMinValue ",
                                        style: TextStyle(
                                            color: currentMinValue > 100 ? currentMinValue > 300 ? const Color(0xfffd4c56) : const Color(0xfffdca03) : const Color(0xff0ace84),
                                            fontSize: 42,
                                            fontWeight: FontWeight.w600
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Ø           \n" + (unit == "Bq/m³" ? "Bq/m³": "pCi/L"),
                                        style: TextStyle(
                                            color: Color(0xff78909C),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400
                                        ),
                                      ),
                                      Text("$currentAvgValue ",
                                        style: TextStyle(
                                            color: currentAvgValue > 100 ? currentAvgValue > 300 ? const Color(0xfffd4c56) : const Color(0xfffdca03) : const Color(0xff0ace84),
                                            fontSize: 42,
                                            fontWeight: FontWeight.w600
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Max.     \n" + (unit == "Bq/m³" ? "Bq/m³": "pCi/L"),
                                        style: TextStyle(
                                            color: Color(0xff78909C),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400
                                        ),
                                      ),
                                      Text("$currentMaxValue",
                                        style: TextStyle(
                                            color: currentMaxValue > 100 ? currentMaxValue > 300 ? const Color(0xfffd4c56) : const Color(0xfffdca03) : const Color(0xff0ace84),
                                            fontSize: 42,
                                            fontWeight: FontWeight.w600
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ] : [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Ø 24h       \n" + (unit == "Bq/m³" ? "Bq/m³": "pCi/L"),
                                        style: TextStyle(
                                            color: Color(0xff78909C),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400
                                        ),
                                      ),
                                      Text("$radonDaily ",
                                        style: TextStyle(
                                            color: radonDaily > 100 ? radonDaily > 300 ? const Color(0xfffd4c56) : const Color(0xfffdca03) : const Color(0xff0ace84),
                                            fontSize: 42,
                                            fontWeight: FontWeight.w600
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ]
                        ),
                      ),
                    ),

                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              useBluetoothData ? TextButton(
                                  onPressed: (){
                                    useBtGraph = true;
                                    loaded = false;
                                    futureFuncRunning = false;
                                    setState(() {

                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Text(AppLocalizations.of(context)!.loadHistoryWith,style: TextStyle(color: const Color(0xff0099F0)),),
                                      Icon(Icons.bluetooth,color: const Color(0xff0099F0),)
                                    ],
                                  )
                              ) : Text(""),
                            ],
                          ),
                          Row(
                            children: [
                              /*IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: (){
                                    setState(() {
                                      if(!changeDiagram)showDiagramDots = !showDiagramDots;
                                    });
                                  },
                                  icon: Icon(Icons.circle_outlined,color: showDiagramDots ? const Color(0xff0099F0) : Colors.grey,),
                                tooltip: "Diagram tooltips",
                              ),*/
                              const SizedBox(width: 5,),
                              IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: (){
                                    setState(() {
                                      changeDiagram = !changeDiagram;
                                    });
                                  },
                                  icon: Icon(!changeDiagram ? Icons.bar_chart : Icons.show_chart ,color: const Color(0xff0099F0),),
                                tooltip: AppLocalizations.of(context)!.diagramType,
                              ),
                              const SizedBox(width: 5,),
                              IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: (){
                                    setState(() {
                                      if(!changeDiagram && selectedNumberOfDays != 0)showAllData = !showAllData;
                                      chartSpots = getCurrentSpots();
                                    });
                                  },
                                  icon: Icon(Icons.query_stats,color: showAllData ? const Color(0xff0099F0) : Colors.grey,),
                                tooltip: AppLocalizations.of(context)!.showRealtime,
                              ),
                              const SizedBox(width: 15,),
                            ],
                          )
                        ],
                      ),
                      SizedBox(height: 5,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                              onPressed: (){
                                setState(() {
                                  stepsIntoPast +=1;
                                  chartSpots = getCurrentSpots();
                                  chartBars = getCurrentBars();
                                  List<int> barSizes = [];
                                  for (var bar in chartBars) {
                                    barSizes.add(bar.barRods.first.toY.toInt());
                                  }
                                  currentMaxAvgValue = ((barSizes.reduce(max)/100).ceil())*100;
                                  if(currentMaxAvgValue == 0)currentMaxAvgValue = 100;
                                });
                              },
                              icon: const Icon(Icons.arrow_back,color: Color(0xff0099F0), size: 30,)
                          ),
                          OutlinedButton(
                            onPressed: () async {
                              if(selectedNumberOfDays == 0)return;
                              DateTime? newDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().subtract(Duration(days: 1)),
                                  firstDate: DateTime.now().subtract(Duration(milliseconds: radonHistoryTimestamps != [] ? radonHistoryTimestamps.first.item1 : 0)),
                                  lastDate: DateTime.now().subtract(Duration(days: 1))
                              );
                              if(newDate == null) return;
                              newDate = DateTime(newDate.year,newDate.month, newDate.day, DateTime.fromMillisecondsSinceEpoch(requestMsSinceEpoch).hour, DateTime.fromMillisecondsSinceEpoch(requestMsSinceEpoch).minute);
                              int newStepsIntoPast = 0;
                              while(newDate.isBefore(DateTime.fromMillisecondsSinceEpoch(requestMsSinceEpoch-Duration(days: selectedNumberOfDays).inMilliseconds*(newStepsIntoPast+1)))){
                                newStepsIntoPast++;
                              }
                              setState(() {
                                stepsIntoPast = newStepsIntoPast+1;
                                chartSpots = getCurrentSpots();
                                chartBars = getCurrentBars();
                                List<int> barSizes = [];
                                chartBars.forEach((bar) {
                                  barSizes.add(bar.barRods.first.toY.toInt());
                                });
                                currentMaxAvgValue = ((barSizes.reduce(max)/100).ceil())*100;
                              });
                            },
                            style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(width: 1,color: Color(0xffECEFF1))),
                            child:  Text(
                              " ${DateFormat('dd MMM yyyy').format(selectedNumberOfDays == 0 ? DateTime.fromMillisecondsSinceEpoch( radonHistoryTimestamps.last.item1) : DateTime.fromMillisecondsSinceEpoch(requestMsSinceEpoch - Duration(days: selectedNumberOfDays).inMilliseconds - (Duration(days: selectedNumberOfDays).inMilliseconds * (stepsIntoPast-1))))} - ${DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(requestMsSinceEpoch - (Duration(days: selectedNumberOfDays).inMilliseconds * (stepsIntoPast-1))))} ",
                              style: TextStyle(color: const Color(0xff0099F0)),
                            ),
                          ),
                          IconButton(
                              onPressed: (){
                                setState(() {
                                  if(stepsIntoPast - 1 >= 1)stepsIntoPast -=1;
                                  chartSpots = getCurrentSpots();
                                  chartBars = getCurrentBars();
                                  List<int> barSizes = [];
                                  for (var bar in chartBars) {
                                    barSizes.add(bar.barRods.first.toY.toInt());
                                  }
                                  currentMaxAvgValue = ((barSizes.reduce(max)/100).ceil())*100;
                                  if(currentMaxAvgValue == 0)currentMaxAvgValue = 100;
                                });
                              },
                              icon: const Icon(Icons.arrow_forward,color: Color(0xff0099F0), size: 30,)
                          ),
                        ],
                      ),

                    ],
                  ),
                ),

                Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: AspectRatio(
                        aspectRatio: 2.1,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 30, 0),
                          child: changeDiagram && selectedNumberOfDays != 0 ?
                          BarChart(
                              BarChartData(
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    tooltipPadding: const EdgeInsets.all(1),
                                    tooltipMargin: 1,
                                    tooltipBorder: const BorderSide(color: Colors.black),
                                    getTooltipItem: (
                                        BarChartGroupData group,
                                        int groupIndex,
                                        BarChartRodData rod,
                                        int rodIndex,
                                    ){
                                      return BarTooltipItem(
                                          barChartSpotString(groupIndex+1, rod.toY),
                                          TextStyle(
                                            color: rod.toY > 100 ? rod.toY > 300 ? const Color(0xfffd4c56) : const Color(0xfffdca03) : const Color(0xff0ace84),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                      ));
                                    }
                                  )
                                ),
                                titlesData: FlTitlesData(
                                    show: true,
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          return bottomTitleWidgets(value, meta);
                                        },
                                        reservedSize: 56,
                                      ),
                                      drawBelowEverything: true,
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 50
                                      ),
                                    )
                                ),
                                gridData: FlGridData(
                                    show: true,
                                    getDrawingVerticalLine: (value){
                                      return const FlLine(
                                          color: Color(0x00eceff1),
                                          strokeWidth: 1
                                      );
                                    }
                                ),
                                alignment: BarChartAlignment.spaceAround,
                                maxY: currentMaxValue > 50 ? max(currentMaxValue.toDouble()+100, 300) : 150,
                                barGroups: chartBars,
                                borderData: FlBorderData(
                                    show: false
                                ),
                              )
                          ) : SfCartesianChart(
                            plotAreaBorderWidth: 0,
                            primaryXAxis: DateTimeAxis(
                              dateFormat: selectedNumberOfDays == 1 ? DateFormat.Hm() : selectedNumberOfDays == 2 ? DateFormat("EEE\nHH:mm") : selectedNumberOfDays == 7 ? DateFormat("d MMM\nHH:mm") : selectedNumberOfDays == 30 ? DateFormat("d MMM") : DateFormat("d MMM yy"),
                              intervalType: selectedNumberOfDays == 1 ? DateTimeIntervalType.hours : selectedNumberOfDays == 2 ? DateTimeIntervalType.hours : DateTimeIntervalType.days,
                              interval: selectedNumberOfDays == 1 ? 6 : selectedNumberOfDays == 2 ? 12 : selectedNumberOfDays == 7 ? 7/5 : selectedNumberOfDays == 30 ? 6 : (Duration(milliseconds: DateTime.now().millisecondsSinceEpoch - radonHistoryTimestamps.last.item1 ).inDays.toDouble()/4) != 0 ? (Duration(milliseconds: DateTime.now().millisecondsSinceEpoch - radonHistoryTimestamps.last.item1).inDays.toDouble()/4) : null,
                            ),
                            primaryYAxis: NumericAxis(
                                minimum: 0,
                                maximum: currentMaxValue > 50 ? max(currentMaxValue.toDouble()+100, 300) : 150,
                                axisLine: AxisLine(width: 0),
                                edgeLabelPlacement: EdgeLabelPlacement.shift,
                                majorTickLines: MajorTickLines(size: 0)
                            ),
                            series: getSplineSeries(currentMaxValue > 50 ? max(currentMaxValue.toDouble()+100, 300) : 150),
                            tooltipBehavior: TooltipBehavior(
                                enable: false,
                                format: "point.x  point.y ${unit}",
                                decimalPlaces: 0,
                                header: "",
                                animationDuration: 0,
                                canShowMarker: false
                            ),
                            trackballBehavior: TrackballBehavior(
                              enable: true,
                              tooltipSettings: InteractiveTooltip(
                                enable: true,
                                canShowMarker: false,
                                format: "point.x  point.y ${unit}",
                                decimalPlaces: 0,
                              )
                            ),
                          )
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: changeDiagram ? 30 : 40),
                      child: changeDiagram ? Text(AppLocalizations.of(context)!.valuesShownAre + (selectedNumberOfDays == 1 ? AppLocalizations.of(context)!.hour : selectedNumberOfDays == 2 ? "2 ${AppLocalizations.of(context)!.hours}" : selectedNumberOfDays == 7 ? "6 ${AppLocalizations.of(context)!.hours}" : selectedNumberOfDays == 30 ? AppLocalizations.of(context)!.day : ""), style: TextStyle(fontSize: 12, color: Colors.grey),) : showAllData ? Text(AppLocalizations.of(context)!.valuesShownAre10min, style: TextStyle(fontSize: 12, color: Colors.grey),) : Text(AppLocalizations.of(context)!.valuesShownAre + (selectedNumberOfDays == 1 ? AppLocalizations.of(context)!.hour : selectedNumberOfDays == 2 ? AppLocalizations.of(context)!.hour : selectedNumberOfDays == 7 ? AppLocalizations.of(context)!.hour : selectedNumberOfDays == 30 ? "6 ${AppLocalizations.of(context)!.hours}" : AppLocalizations.of(context)!.day), style: TextStyle(fontSize: 12, color: Colors.grey),),
                    ),
                  ]
                ),
              ],
            ),
            ),
          ),
        )
    ) : Scaffold(
      resizeToAvoidBottomInset: true,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                  height: 30,
                  width: 300,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    children: [
                      Container(
                        height: 20,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                          child: OutlinedButton(
                            onPressed: (){
                              setState((){
                                stepsIntoPast = 1;
                                selectedNumberOfDays = 1;
                                chartSpots = getCurrentSpots();
                                chartBars = getCurrentBars();
                                List<int> barSizes = [];
                                chartBars.forEach((bar) {
                                  barSizes.add(bar.barRods.first.toY.toInt());
                                });
                                currentMaxAvgValue = ((barSizes.reduce(max)/100).ceil())*100;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)
                              ),
                              side: BorderSide(width: 2,color: selectedNumberOfDays == 1 ? const Color(0xff0099F0) : const Color(0xff4f99F0)),
                              foregroundColor: Colors.black,
                              backgroundColor: selectedNumberOfDays == 1 ? const Color(0xff0099F0) : Colors.white,
                            ),
                            child: Text(AppLocalizations.of(context)!.last24h,style: TextStyle(
                                color: selectedNumberOfDays == 1 ? Colors.white : const Color(0xff0099F0)
                            ),),
                          ),
                        ),
                      ),
                      Container(
                        height: 30,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                          child: OutlinedButton(
                            onPressed: (){
                              setState((){
                                stepsIntoPast = 1;
                                selectedNumberOfDays = 2;
                                chartSpots = getCurrentSpots();
                                chartBars = getCurrentBars();
                                List<int> barSizes = [];
                                chartBars.forEach((bar) {
                                  barSizes.add(bar.barRods.first.toY.toInt());
                                });
                                currentMaxAvgValue = ((barSizes.reduce(max)/100).ceil())*100;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)
                                ),
                                side: BorderSide(width: 2,color: selectedNumberOfDays == 2 ? const Color(0xff0099F0) : const Color(0xff4f99F0)),
                                foregroundColor: Colors.black,
                                backgroundColor: selectedNumberOfDays == 2 ? const Color(0xff0099F0) : Colors.white,
                                minimumSize: const Size(60,20)
                            ),
                            child: Text(AppLocalizations.of(context)!.last48h,style: TextStyle(
                                color: selectedNumberOfDays == 2 ? Colors.white : const Color(0xff0099F0)
                            ),),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 30,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                          child: OutlinedButton(
                            onPressed: ()=>{
                              setState((){
                                stepsIntoPast = 1;
                                selectedNumberOfDays = 7;
                                chartSpots = getCurrentSpots();
                                chartBars = getCurrentBars();
                                List<int> barSizes = [];
                                chartBars.forEach((bar) {
                                  barSizes.add(bar.barRods.first.toY.toInt());
                                });
                                currentMaxAvgValue = ((barSizes.reduce(max)/100).ceil())*100;
                              })
                            },
                            style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)
                                ),
                                side: BorderSide(width: 2,color: selectedNumberOfDays == 7 ? const Color(0xff0099F0) : const Color(0xff4f99F0)),
                                foregroundColor: Colors.black,
                                backgroundColor: selectedNumberOfDays == 7 ? const Color(0xff0099F0) : Colors.white,
                                minimumSize: const Size(60,20)
                            ),
                            child: Text(AppLocalizations.of(context)!.last7d,style: TextStyle(
                                color: selectedNumberOfDays ==7 ? Colors.white : const Color(0xff0099F0)
                            ),),
                          ),
                        ),
                      ),
                      Container(
                        height: 30,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                          child: OutlinedButton(
                            onPressed: ()=>{
                              setState((){
                                stepsIntoPast = 1;
                                selectedNumberOfDays = 30;
                                chartSpots = getCurrentSpots();
                                chartBars = getCurrentBars();
                                List<int> barSizes = [];
                                chartBars.forEach((bar) {
                                  barSizes.add(bar.barRods.first.toY.toInt());
                                });
                                currentMaxAvgValue = ((barSizes.reduce(max)/100).ceil())*100;
                              })
                            },
                            style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)
                                ),
                                side: BorderSide(width: 2,color: selectedNumberOfDays == 30 ? const Color(0xff0099F0) : const Color(0xff4f99F0)),
                                foregroundColor: Colors.black,
                                backgroundColor: selectedNumberOfDays == 30 ? const Color(0xff0099F0) : Colors.white,
                                minimumSize: const Size(60,20)
                            ),
                            child:  Text(AppLocalizations.of(context)!.last30d,style: TextStyle(
                                color: selectedNumberOfDays == 30 ? Colors.white : const Color(0xff0099F0)
                            ),),
                          ),
                        ),
                      ),
                      Container(
                        height: 30,
                        child: OutlinedButton(
                          onPressed: ()=>{
                            setState((){
                              stepsIntoPast = 1;
                              selectedNumberOfDays = 0;
                              showAllData = false;
                              chartSpots = getCurrentSpots();
                              chartBars = getCurrentBars();
                            })
                          },
                          style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)
                              ),
                              side: BorderSide(width: 2,color: selectedNumberOfDays == 0 ? const Color(0xff0099F0) : const Color(0xff4f99F0)),
                              foregroundColor: Colors.black,
                              backgroundColor: selectedNumberOfDays == 0 ? const Color(0xff0099F0) : Colors.white,
                              minimumSize: const Size(60,20)
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.completeHistory,
                            style: TextStyle(
                                color: selectedNumberOfDays == 0 ? Colors.white : const Color(0xff0099F0)
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: (){
                          setState(() {
                            stepsIntoPast +=1;
                            chartSpots = getCurrentSpots();
                            chartBars = getCurrentBars();
                            List<int> barSizes = [];
                            for (var bar in chartBars) {
                              barSizes.add(bar.barRods.first.toY.toInt());
                            }
                            currentMaxAvgValue = ((barSizes.reduce(max)/100).ceil())*100;
                            if(currentMaxAvgValue == 0)currentMaxAvgValue = 100;
                          });
                        },
                        icon: const Icon(Icons.arrow_back,color: Color(0xff0099F0), size: 22,)
                    ),
                    Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12, width: 1.5),
                          borderRadius: const BorderRadius.all(Radius.circular(20.0))
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            " ${DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(requestMsSinceEpoch - Duration(days: selectedNumberOfDays).inMilliseconds - (Duration(days: selectedNumberOfDays).inMilliseconds * (stepsIntoPast-1))))} - ${DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(requestMsSinceEpoch - (Duration(days: selectedNumberOfDays).inMilliseconds * (stepsIntoPast-1))))} ",
                          ),
                        ),
                    ),
                    IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: (){
                          setState(() {
                            if(stepsIntoPast - 1 >= 1)stepsIntoPast -=1;
                            chartSpots = getCurrentSpots();
                            chartBars = getCurrentBars();
                            List<int> barSizes = [];
                            for (var bar in chartBars) {
                              barSizes.add(bar.barRods.first.toY.toInt());
                            }
                            currentMaxAvgValue = ((barSizes.reduce(max)/100).ceil())*100;
                            if(currentMaxAvgValue == 0)currentMaxAvgValue = 100;
                          });
                        },
                        icon: const Icon(Icons.arrow_forward,color: Color(0xff0099F0), size: 22,)
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    /*IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: (){
                          setState(() {
                            if(!changeDiagram)showDiagramDots = !showDiagramDots;
                          });
                        },
                        icon: Icon(Icons.circle_outlined,color: showDiagramDots ? const Color(0xff0099F0) : Colors.grey, size: 22,)
                    ),*/
                    const SizedBox(width: 10,),
                    IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: (){
                          setState(() {
                            changeDiagram = !changeDiagram;
                          });
                        },
                        icon: Icon(!changeDiagram ? Icons.bar_chart : Icons.query_stats ,color: const Color(0xff0099F0),)
                    ),
                    const SizedBox(width: 10,),
                    IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: (){
                          if(!changeDiagram && selectedNumberOfDays != 0)showAllData = !showAllData;
                          chartSpots = getCurrentSpots();
                          setState(() {
                          });
                        },
                        icon: Icon(Icons.query_stats,color: showAllData ? const Color(0xff0099F0) : Colors.grey,)
                    ),
                    const SizedBox(width: 20,),
                  ],
                ),
              ],
            ),
            SizedBox(height: 5,),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height-75,
              child: AspectRatio(
                aspectRatio: 16/9,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 50, 0),
                  child: changeDiagram && selectedNumberOfDays != 0 ?
                  BarChart(
                      BarChartData(
                        barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                                tooltipPadding: const EdgeInsets.all(1),
                                tooltipMargin: 1,
                                getTooltipItem: (
                                    BarChartGroupData group,
                                    int groupIndex,
                                    BarChartRodData rod,
                                    int rodIndex,
                                    ){
                                  return BarTooltipItem(
                                      barChartSpotString(groupIndex+1, rod.toY),
                                      TextStyle(
                                        color: rod.toY > 100 ? rod.toY > 300 ? const Color(0xfffd4c56) : const Color(0xfffdca03) : const Color(0xff0ace84),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ));
                                }
                            )
                        ),
                        titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return bottomTitleWidgets(value, meta);
                                },
                                reservedSize: 56,
                              ),
                              drawBelowEverything: true,
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50
                              ),
                            )
                        ),
                        gridData: FlGridData(
                            show: true,
                            getDrawingVerticalLine: (value){
                              return const FlLine(
                                  color: Color(0x00eceff1),
                                  strokeWidth: 1
                              );
                            }
                        ),
                        alignment: BarChartAlignment.spaceAround,
                        maxY: currentMaxValue > 50 ? max(currentMaxValue.toDouble()+100, 300) : 150,
                        barGroups: chartBars,
                        borderData: FlBorderData(
                            show: false
                        ),
                      )
                  ) : SfCartesianChart(
                    plotAreaBorderWidth: 0,
                    primaryXAxis: DateTimeAxis(
                      dateFormat: selectedNumberOfDays == 1 ? DateFormat.Hm() : selectedNumberOfDays == 2 ? DateFormat("EEE\nHH:mm") : selectedNumberOfDays == 7 ? DateFormat("d MMM") : selectedNumberOfDays == 30 ? DateFormat("d MMM") : DateFormat("d MMM yy"),
                      intervalType: selectedNumberOfDays == 1 ? DateTimeIntervalType.hours : selectedNumberOfDays == 2 ? DateTimeIntervalType.hours : DateTimeIntervalType.days,
                      interval: selectedNumberOfDays == 1 ? 6 : selectedNumberOfDays == 2 ? 12 : selectedNumberOfDays == 7 ? 7/5 : selectedNumberOfDays == 30 ? 6 : (Duration(milliseconds: DateTime.now().millisecondsSinceEpoch - radonHistoryTimestamps.last.item1).inDays.toDouble()/4),
                    ),
                    primaryYAxis: NumericAxis(
                        minimum: 0,
                        maximum: currentMaxValue > 50 ? max(currentMaxValue.toDouble()+100, 300) : 150,
                        axisLine: AxisLine(width: 0),
                        edgeLabelPlacement: EdgeLabelPlacement.shift,
                        majorTickLines: MajorTickLines(size: 0)
                    ),
                    series: getSplineSeries(currentMaxValue > 50 ? max(currentMaxValue.toDouble()+100, 300) : 150),
                    tooltipBehavior: TooltipBehavior(
                        enable: false,
                        format: "point.x  point.y ${unit}",
                        decimalPlaces: 0,
                        header: "",
                        animationDuration: 0
                    ),
                    trackballBehavior: TrackballBehavior(
                        enable: true,
                        tooltipSettings: InteractiveTooltip(
                          enable: true,
                          color: Color(0xff0099F0),
                          borderColor: Color(0xff0099F0),
                          canShowMarker: false,
                          format: "point.x  point.y ${unit}",
                          decimalPlaces: 0,
                        )
                    ),
                  )
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AreaSeries<ChartData, DateTime>> getSplineSeries(double max) {
    return <AreaSeries<ChartData, DateTime>>[
      AreaSeries<ChartData, DateTime>(
        emptyPointSettings: EmptyPointSettings(
          mode: EmptyPointMode.gap
        ),
        dataSource: chartSpots,
        xValueMapper: (ChartData spot, _) => spot.x,
        yValueMapper: (ChartData spot, _) => spot.y,
        markerSettings: MarkerSettings(
            isVisible: (showDiagramDots && (showAllData ? false : true)),
          borderColor: Colors.black26,
          color: Colors.black26
        ),
        borderGradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: currentMaxValue>300 ? [
              Color(0xff0ace84).withOpacity(0.5),
              Color(0xff0ace84).withOpacity(0.5),
              Color(0xfffdca03).withOpacity(0.5),
              Color(0xfffdca03).withOpacity(0.5),
              Color(0xfffd4c56).withOpacity(0.5),
              Color(0xfffd4c56).withOpacity(0.5),
            ] : currentMaxValue>100 ?[
              Color(0xff0ace84),
              Color(0xff0ace84),
              Color(0xfffdca03),
              Color(0xfffdca03),
            ] : [
              Color(0xff0ace84),
              Color(0xff0ace84),
            ],
            stops: currentMaxValue>300 ?[0, 100<currentMaxValue ? 90.0/currentMaxValue : 1.0, 100<currentMaxValue ? 110.0/currentMaxValue : 1.0, 300<currentMaxValue ? 290/currentMaxValue : 1.0, 300<currentMaxValue ? 310/currentMaxValue : 3.00,1.0]
                : currentMaxValue>100 ?[0, 100<currentMaxValue ? 90.0/currentMaxValue : 1.0, 100<currentMaxValue ? 110.0/currentMaxValue : 1.0, 300<currentMaxValue ? 290/currentMaxValue : 1.0]
                :[0,1.0]
        ),
        gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: currentMaxValue>300 ? [
              Color(0xff0ace84).withOpacity(0.5),
              Color(0xff0ace84).withOpacity(0.5),
              Color(0xfffdca03).withOpacity(0.5),
              Color(0xfffdca03).withOpacity(0.5),
              Color(0xfffd4c56).withOpacity(0.5),
              Color(0xfffd4c56).withOpacity(0.5),
            ] : currentMaxValue>100 ?[
              Color(0xff0ace84).withOpacity(0.5),
              Color(0xff0ace84).withOpacity(0.5),
              Color(0xfffdca03).withOpacity(0.5),
              Color(0xfffdca03).withOpacity(0.5),
            ] : [
              Color(0xff0ace84).withOpacity(0.5),
              Color(0xff0ace84).withOpacity(0.5),
            ],
            stops: currentMaxValue>300 ?[0, 100<currentMaxValue ? 90.0/currentMaxValue : 1.0, 100<currentMaxValue ? 110.0/currentMaxValue : 1.0, 300<currentMaxValue ? 290/currentMaxValue : 1.0, 300<currentMaxValue ? 310/currentMaxValue : 3.00,1.0]
                : currentMaxValue>100 ?[0, 100<currentMaxValue ? 90.0/currentMaxValue : 1.0, 100<currentMaxValue ? 110.0/currentMaxValue : 1.0, 300<currentMaxValue ? 290/currentMaxValue : 1.0]
                :[0,1.0]
        ),
      )
    ];
  }

  bottomTitleWidgets(double valueUncorrected, TitleMeta meta){
    int value = valueUncorrected.toInt();
    if(value%(changeDiagram ? 6 : 30) != 0 && selectedNumberOfDays == 30 && !(value.toInt() == 0)) return SideTitleWidget(axisSide: meta.axisSide, child: const Text(""));
    if(value%(changeDiagram ? 4 : 24) != 0 && selectedNumberOfDays == 7 && !(value.toInt() == 0)) return SideTitleWidget(axisSide: meta.axisSide, child: const Text(""));
    if(value%6 != 0 && selectedNumberOfDays == 2 && !(value.toInt() == 0)) return SideTitleWidget(axisSide: meta.axisSide, child: const Text(""));
    if(value%6 != 0 && selectedNumberOfDays == 1 && !(value.toInt() == 0)) return SideTitleWidget(axisSide: meta.axisSide, child: const Text(""));
    //if(value != 0 && value != radonHistoryTimestamps.length && selectedNumberOfDays == 0) return SideTitleWidget(axisSide: meta.axisSide, child: const Text(""));
    const style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w400,

    );

    if(selectedNumberOfDays == 7 && (value.toInt() == 0 || (value.toInt() == 168 && !changeDiagram) || (value.toInt() == 28 && changeDiagram))){
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: [
                Text(
                  "${MyLineChartData().convertMsToDateString(requestMsSinceEpoch-((Duration(days: selectedNumberOfDays).inMilliseconds)-(value*6)*3600000).toInt(), selectedNumberOfDays)}\n"
                      "${MyLineChartData().convertMsToDateString(requestMsSinceEpoch-((Duration(days: selectedNumberOfDays).inMilliseconds)-(value*6)*3600000).toInt(), 71)}\n"
                      "${MyLineChartData().convertMsToDateString(requestMsSinceEpoch-((Duration(days: selectedNumberOfDays).inMilliseconds)-(value*6)*3600000).toInt(), 72)}",
                  style: style,
                  textAlign:  TextAlign.center,
                ),
              ],
            )
            ],
        ),
      );
    }

    if(selectedNumberOfDays == 0){
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 16,
        child: Text(MyLineChartData().convertMsToDateString(requestMsSinceEpoch-Duration(milliseconds: requestMsSinceEpoch-radonHistoryTimestamps.last.item1).inMilliseconds+(value*60000).toInt(), selectedNumberOfDays) , style: style, textAlign:  TextAlign.center,),
      );
    }
    if(selectedNumberOfDays == 1){
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 16,
        child: Text(MyLineChartData().convertMsToDateString(requestMsSinceEpoch-((Duration(days: selectedNumberOfDays).inMilliseconds)-(value)*3600000).toInt(), selectedNumberOfDays) , style: style, textAlign:  TextAlign.center,),
      );
    }
    if(selectedNumberOfDays == 2){
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 16,
        child: Text(MyLineChartData().convertMsToDateString(requestMsSinceEpoch-((Duration(days: selectedNumberOfDays).inMilliseconds)-(value*2)*3600000).toInt(), 21) , style: style, textAlign:  TextAlign.center,),
      );
    }
    if(selectedNumberOfDays == 7){
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 16,
        child: Column(
          children: [
            Text(MyLineChartData().convertMsToDateString(requestMsSinceEpoch-((Duration(days: selectedNumberOfDays).inMilliseconds)-(value*(changeDiagram ? 6 : 1))*3600000).toInt(), selectedNumberOfDays) , style: style, textAlign:  TextAlign.center,),
            Text(MyLineChartData().convertMsToDateString(requestMsSinceEpoch-((Duration(days: selectedNumberOfDays).inMilliseconds)-(value*(changeDiagram ? 6 : 1))*3600000).toInt(), 71) , style: style, textAlign:  TextAlign.center,),
          ],
        ),
      );
    }
    if(selectedNumberOfDays == 30){
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 16,
        child: Text(MyLineChartData().convertMsToDateString(requestMsSinceEpoch-((Duration(days: selectedNumberOfDays).inMilliseconds)-(value*24)*3600000).toInt(), selectedNumberOfDays) , style: style, textAlign:  TextAlign.center,),
      );
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16,
      child: Text(MyLineChartData().convertMsToDateString(requestMsSinceEpoch-(selectedNumberOfDays == 0 ? Duration(milliseconds: requestMsSinceEpoch-radonHistoryTimestamps.last.item1).inMilliseconds : (Duration(days: selectedNumberOfDays).inMilliseconds)-(value)*3600000).toInt(), selectedNumberOfDays) , style: style, textAlign:  TextAlign.center,),
    );
  }

  List<LineTooltipItem?> touchedWidgets(List<LineBarSpot> touchedSpots){
    List<LineTooltipItem?> list =  touchedSpots.map((LineBarSpot touchedSpot) {
      final textStyle = TextStyle(
        color: touchedSpot.y > 100 ? touchedSpot.y > 300 ? const Color(0xfffd4c56) : const Color(0xfffdca03) : const Color(0xff0ace84),
        fontWeight: FontWeight.bold,
        fontSize: 14,
      );
      if(selectedNumberOfDays == 0){
        return LineTooltipItem(
          '${MyLineChartData().convertMsToDateString(requestMsSinceEpoch-Duration(milliseconds: requestMsSinceEpoch-radonHistoryTimestamps.last.item1).inMilliseconds , selectedNumberOfDays)}, ${touchedSpot.y.toStringAsFixed(2)} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}',
          textStyle,
        );
      }
      if(selectedNumberOfDays == 1){
        return LineTooltipItem(
          '${MyLineChartData().convertMsToDateString((requestMsSinceEpoch-((48-touchedSpot.x)*0.5*3600000)).toInt(), selectedNumberOfDays)}, ${touchedSpot.y.toStringAsFixed(2)} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}',
          textStyle,
        );
      }
      if(selectedNumberOfDays == 2){
        return LineTooltipItem(
          '${MyLineChartData().convertMsToDateString((requestMsSinceEpoch-((96-touchedSpot.x)*0.5*3600000)).toInt(), selectedNumberOfDays)}, ${touchedSpot.y.toStringAsFixed(2)} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}',
          textStyle,
        );
      }
      if(selectedNumberOfDays == 7){
        return LineTooltipItem(
          '${MyLineChartData().convertMsToDateString((requestMsSinceEpoch-((168-touchedSpot.x)*1*3600000)).toInt(), 73)}, ${touchedSpot.y.toStringAsFixed(2)} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}',
          textStyle,
        );
      }
      if(selectedNumberOfDays == 30){
        return LineTooltipItem(
          '${MyLineChartData().convertMsToDateString((requestMsSinceEpoch-((120-touchedSpot.x)*6*3600000)).toInt(), selectedNumberOfDays)}, ${touchedSpot.y.toStringAsFixed(2)} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}',
          textStyle,
        );
      }
      return LineTooltipItem(
        '${MyLineChartData().convertMsToDateString(requestMsSinceEpoch-((selectedNumberOfDays == 0 ? Duration(milliseconds: requestMsSinceEpoch-radonHistoryTimestamps.last.item1).inMilliseconds : Duration(days: selectedNumberOfDays).inMilliseconds) -touchedSpot.x*3600000).toInt(), selectedNumberOfDays)}, ${touchedSpot.y.toStringAsFixed(2)} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}',
        textStyle,
      );
    }).toList();
    return list;
  }

  String barChartSpotString (int touchedBar, double touchedBarValue){

    if(selectedNumberOfDays == 0){
      return '${MyLineChartData().convertMsToDateString(requestMsSinceEpoch-Duration(milliseconds: requestMsSinceEpoch-radonHistoryTimestamps.last.item1).inMilliseconds , selectedNumberOfDays)}, ${touchedBarValue.toStringAsFixed(2)} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}';
    }
    if(selectedNumberOfDays == 1){
      return '${MyLineChartData().convertMsToDateString((requestMsSinceEpoch-((25-touchedBar)*3600000)).toInt(), 2)}, ${touchedBarValue.toStringAsFixed(2)} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}';
    }
    if(selectedNumberOfDays == 2){
      return '${MyLineChartData().convertMsToDateString((requestMsSinceEpoch-((25-touchedBar)*2*3600000)).toInt(), 2)}, ${touchedBarValue.toStringAsFixed(2)} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}';
    }
    if(selectedNumberOfDays == 7){
      return '${MyLineChartData().convertMsToDateString((requestMsSinceEpoch-((29-touchedBar)*6*3600000)).toInt(), 2)}, ${touchedBarValue.toStringAsFixed(2)} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}';
    }
    if(selectedNumberOfDays == 30){
      return '${MyLineChartData().convertMsToDateString((requestMsSinceEpoch-((31-touchedBar)*24*3600000)).toInt(), 2)}, ${touchedBarValue.toStringAsFixed(2)} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}';
    }
    return '${MyLineChartData().convertMsToDateString(requestMsSinceEpoch-((selectedNumberOfDays == 0 ? Duration(milliseconds: requestMsSinceEpoch-radonHistoryTimestamps.last.item1).inMilliseconds : Duration(days: selectedNumberOfDays).inMilliseconds) -touchedBar*3600000).toInt(), selectedNumberOfDays)}, ${touchedBarValue.toStringAsFixed(2)} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}';
  }

  deviceSettingsScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                setState(() {
                  screenIndex = 1;
                });
              },
            ),
            Text(AppLocalizations.of(context)!.deviceSettingsT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /*GestureDetector(
            onTap: (){
              setState(() {
                screenIndex = 28;
              });
            },
            child: Container(
              height: 50,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16,),
                      Icon(Icons.auto_graph,color: Color(0xaf253238)),
                      const SizedBox(width: 14,),
                      Text("Configure history",style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                    ],
                  ),

                ],
              ),
            ),
          ),*/
          GestureDetector(
            onTap: (){
              setState(() {
                screenIndex = 20;
              });
            },
            child: Container(
              height: 50.0,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16,),
                      const ImageIcon(AssetImage('lib/images/lights.png')),
                      const SizedBox(width: 14,),
                      Text(AppLocalizations.of(context)!.deviceLights,style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                    ],
                  ),

                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: (){
              setState(() {
                screenIndex = 25;
              });
            },
            child: Container(
              height: 50.0,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16,),
                      const Icon(Icons.access_time,color: Color(0xaf253238),),
                      const SizedBox(width: 14,),
                      Text(AppLocalizations.of(context)!.clockAndDate,style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                    ],
                  ),

                ],
              ),
            ),
          ),

          GestureDetector(
            onTap: (){
              checkConnectedWifi();
            },
            child: Container(
              height: 50,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16,),
                      const ImageIcon(AssetImage('lib/images/wifi.png')),
                      const SizedBox(width: 14,),
                      Text(AppLocalizations.of(context)!.wifi,style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                    ],
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: (){
              setState(() {
                screenIndex = 24;
              });
            },
            child: Container(
              height: 50,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16,),
                      const ImageIcon(AssetImage('lib/images/location.png')),
                      const SizedBox(width: 14,),
                      Text(AppLocalizations.of(context)!.location,style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                    ],
                  ),

                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: (){
              setState(() {
                screenIndex = 1;
              });
              renameDeviceDialog();
            },
            child: Container(
              height: 50,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16,),
                      const ImageIcon(AssetImage('lib/images/rename.png')),
                      const SizedBox(width: 14,),
                      Text(AppLocalizations.of(context)!.renameDevice,style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                    ],
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: ()async{
              setState(() {
                screenIndex = 26;
              });
              await sendBTLine(["G54","G55","G56","G57","G58","G59"]);
              setState(() {

              });
            },
            child: Container(
              height: 50,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16,),
                      const Icon(Icons.cloud,color: Color(0xaf253238)),
                      const SizedBox(width: 14,),
                      Text("KNX",style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                    ],
                  ),

                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: ()async{
              setState(() {
                screenIndex = 27;
              });
              await sendBTLine(["G63","G64","G65","G66","G67"]);
              setState(() {

              });
            },
            child: Container(
              height: 50,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16,),

                      const Icon(Icons.cloud,color: Color(0xaf253238)),
                      const SizedBox(width: 14,),
                      Text("Cloud",style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                    ],
                  ),

                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: ()async{
              setState((){
                screenIndex = 28;
              });
              await sendBTLine(["G70","G71","G72","G73","G74","G75"]);
              setState(() {

              });
            },
            child: Container(
              height: 50,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16,),
                      const ImageIcon(AssetImage('lib/images/mqtt.png'),color: Color(0xaf253238)),
                      const SizedBox(width: 14,),
                      Text("MQTT",style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                    ],
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  checkConnectedWifi() async{
    showDialog(context: context, barrierDismissible: false, builder: (context) {
      return PopScope(
        canPop: false,
        child: Scaffold(
            body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.searchingDevice),
                    const SizedBox(height: 36,),
                    const CircularProgressIndicator(color: Colors.black,),
                  ],
                )
            )
        ),
      );
    });
    try{
      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
      }
      var locationEnabled = await location.serviceEnabled();
      if (!locationEnabled) {
        var locationEnabled2 = await location.requestService();
        if (!locationEnabled2) {}
      }
      var permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {}
      }
      FlutterBluePlus.stopScan();
      bool deviceFound = false;
      subscription = FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
          if (!deviceFound) {
            List<int> bluetoothAdvertisementData = [];
            String bluetoothDeviceName = "";
            if (r.advertisementData.manufacturerData.keys.isNotEmpty) {
              if (r.advertisementData.manufacturerData.values.isNotEmpty) {
                bluetoothAdvertisementData =
                    r.advertisementData.manufacturerData.values.first;
              }
              if (r.advertisementData.manufacturerData.keys.first == 3503)
                bluetoothDeviceName +=
                    utf8.decode(bluetoothAdvertisementData.sublist(15, 23));
              if (bluetoothDeviceName == device.values.first.name) {
                deviceFound = true;
                FlutterBluePlus.stopScan();
                subscription!.cancel();
                btDevice = r.device;
                try{
                  await btDevice!.connect();
                }catch(e){
                  Navigator.of(context).pop();
                  setState(() {

                  });
                  return;
                }
                try {
                  if (Platform.isAndroid) {
                    await r.device.requestMtu(300);
                  }
                  bool loginSuccessful = false;
                  List<BluetoothService> services = await r.device
                      .discoverServices();
                  for (var service in services) {
                    for (var characteristic in service.characteristics) {
                      if (characteristic.properties.notify) {
                        await characteristic.setNotifyValue(true);
                        readCharacteristic = characteristic;
                        subscriptionToDevice = readCharacteristic!.lastValueStream.timeout(
                            Duration(seconds: 2),
                            onTimeout: (list)async{
                              await btDevice!.disconnect(timeout: 1);
                              btDevice!.removeBond();
                              subscriptionToDevice?.cancel();
                              loaded = true;
                              Navigator.pop(context);
                              setState(() {
                                screenIndex = 1;
                              });
                              Fluttertoast.showToast(
                                  msg: "Error"
                              );
                            }
                        ).listen((data) async {
                              String message = utf8.decode(data).trim();
                              //logger.d(utf8.decode(data));
                              if(message == "" && !loginSuccessful){
                                await Future<void>.delayed(const Duration(seconds: 1));
                                if(!loginSuccessful){
                                  try{
                                    loginSuccessful = true;
                                    await writeCharacteristic!.write(utf8.encode('k47t58W43Lds8'));
                                  }catch(e){
                                  }
                                }
                              }
                              if (message == 'LOGIN OK') {
                                await writeCharacteristic!.write(utf8.encode('ValsRead'));
                              }
                              if (message.length >= 2 && message.substring(0, 2) == "|A") {
                                if(message.substring(2,4) == "16"){
                                  currentWifiName = message.substring(4,message.length-1);
                                  await btDevice!.disconnect(timeout: 1);
                                  btDevice!.removeBond();
                                  subscriptionToDevice?.cancel();
                                  loaded = true;
                                  setState(() {
                                    screenIndex = 21;
                                  });
                                }
                              }
                            });
                      }
                      if (characteristic.properties.write) {
                        writeCharacteristic = characteristic;
                        await Future<void>.delayed(
                            const Duration(milliseconds: 300));
                        if (!loginSuccessful) {
                          try {
                            loginSuccessful = true;
                            await writeCharacteristic!.write(utf8.encode(
                                'k47t58W43Lds8'));
                          } catch (e) {}
                        }
                      }
                    }
                  }
                } catch (e) {
                  await btDevice!.disconnect(timeout: 1);
                  btDevice!.removeBond();
                  subscriptionToDevice?.cancel();
                  Navigator.pop(context);
                  setState(() {
                    screenIndex = 1;
                  });
                }
              }
            }
          }
        }
      });
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      await Future<void>.delayed(const Duration(seconds: 4));
      if (!deviceFound) {
        subscription!.cancel();
        Navigator.pop(context);
        Fluttertoast.showToast(
            msg: AppLocalizations.of(context)!.deviceNotFound
        );
      }
      Navigator.pop(context);
    }catch(e){
      Navigator.pop(context);
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.deviceNotFound
      );
    }
    setState(() {
      screenIndex = 211;
    });
  }


  deviceWifiScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                setState(() {
                  screenIndex = 2;
                });
              },
            ),
            Text(AppLocalizations.of(context)!.wifiT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${AppLocalizations.of(context)!.currentWifi}: ${currentWifiName}", style: TextStyle(fontSize: 16),),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                    onPressed: connectWithBluetooth,
                    child: Text(AppLocalizations.of(context)!.connectToWifi, style: TextStyle(color: Color(0xff0099f0)),)
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  deviceLightsScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                setState(() {
                  screenIndex = 2;
                });
              },
            ),
            Text(AppLocalizations.of(context)!.deviceLightsT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.sendSettWithBT, textAlign: TextAlign.center, style: TextStyle(fontSize: 12),),
                  Switch(
                      value: transmitionMethodSettings,
                      onChanged: (value){
                        transmitionMethodSettings = value;
                        setState(() {
        
                        });
                      },
                    activeColor: const Color(0xff0099F0),
                    activeTrackColor: const Color(0xffCCEBFC),
                    inactiveTrackColor: Colors.grey,
                    inactiveThumbColor: Colors.white30,
                  ),
                ],
              ),
              Container(
                height: 15,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.indicatorLights,
                    style: const TextStyle(fontSize: 12),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    d_led_t ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Switch(
                          value: d_led_t,
                          activeColor: const Color(0xff0099F0),
                          activeTrackColor: const Color(0xffCCEBFC),
                          inactiveTrackColor: Colors.grey,
                          inactiveThumbColor: Colors.white30,
                          onChanged: (value) async{
                            await sendTelemetry("u_led_t", value ? 1 : 0, "S02:${value ? 1 : 0}");
                            if(sentSuccessfullBTTelemetery) d_led_t = value;
                            sentSuccessfullBTTelemetery = false;
                            setState(() {
                            });
                          },
                        ),
                        const SizedBox(width: 10,)
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.brightness,
                    style: const TextStyle(
                        fontSize: 12
                    ),
                  )
                ],
              ),
              Slider(
                label: d_led_tb.round().toString(),
                activeColor: const Color(0xff0099F0),
                thumbColor: Colors.white,
                inactiveColor: Colors.black12,
                divisions: 16,
                min: 0.0,
                max: 255.0,
                value: d_led_tb,
                onChangeEnd: (value) async{
                  await sendTelemetry("u_led_tb", d_led_tb.toInt(), "S05:${d_led_tb.toInt()}");
                  if(sentSuccessfullBTTelemetery) {
                    d_led_tb = value.round().toDouble();
                    d_led_tb_old = d_led_tb;
                  }
                  if(!sentSuccessfullBTTelemetery)d_led_tb = d_led_tb_old;
                  sentSuccessfullBTTelemetery= false;
                  setState(() {
                  });
                },
                onChanged: (value){
                  setState(() {
                    d_led_tb = value.round().toDouble();
                  });
                },
              ),
              Text(AppLocalizations.of(context)!.indicatorAnimation,style: const TextStyle(fontSize: 12),),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 160,
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
                          await sendTelemetry("u_led_tf", 0, "S06:0");
                          if(sentSuccessfullBTTelemetery) displayAnimation = 0;
                          sentSuccessfullBTTelemetery= false;
                          setState(() {
                          });
                        },
                        style: OutlinedButton.styleFrom(backgroundColor: displayAnimation != 0 ?  Colors.white : const Color(0xff0099F0),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)!.animationOff, style: TextStyle(color: displayAnimation != 0 ?  const Color(0xff0099F0) : Colors.white),),
                          ],
                        )
                    ),
                  ),
                  SizedBox(
                    width: 160,
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
                          await sendTelemetry("u_led_tf", 1, "S06:1");
                          if(sentSuccessfullBTTelemetery) displayAnimation = 1;
                          sentSuccessfullBTTelemetery = false;
                          setState(() {
                          });
                        },
                        style: OutlinedButton.styleFrom(backgroundColor: displayAnimation != 1 ?  Colors.white : const Color(0xff0099F0),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)!.animationOn, style: TextStyle(color: displayAnimation != 1 ?  const Color(0xff0099F0) : Colors.white),),
                          ],
                        )
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 30,
              ),
              Divider(
                  color: Colors.grey[500]
              ),
              SizedBox(
                height: 30,
              ),
              Row(
                children: [
                  Text(AppLocalizations.of(context)!.display, style: const TextStyle(fontSize: 12),)
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    d_led_f ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off,
                    style: const TextStyle(
                        fontSize: 16
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Switch(
                          value: d_led_f,
                          activeColor: const Color(0xff0099F0),
                          activeTrackColor: const Color(0xffCCEBFC),
                          inactiveTrackColor: Colors.grey,
                          inactiveThumbColor: Colors.white30,
                          onChanged: (value) async{
                            await sendTelemetry("u_led_f", value ? 1 : 0, "S03${value ? 1 : 0}");
                            if(sentSuccessfullBTTelemetery) d_led_f = value;
                            sentSuccessfullBTTelemetery = false;
                            setState(() {
                            });
                          },
                        ),
                        const SizedBox(width: 10,)
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.brightness,style: const TextStyle(fontSize: 12),)
                ],
              ),
              Slider(
                label: d_led_fb.round().toString(),
                activeColor: const Color(0xff0099F0),
                thumbColor: Colors.white,
                inactiveColor: Colors.black12,
                divisions: 15,
                min: 0.0,
                max: 15.0,
                value: d_led_fb,
                onChangeEnd: (value) async{
                  await sendTelemetry("u_led_fb", d_led_fb.toInt(), "S04:${d_led_fb.toInt()}");
                  if(sentSuccessfullBTTelemetery) {
                    d_led_fb = value.round().toDouble();
                    d_led_fb_old = d_led_fb;
                  }
                  if(!sentSuccessfullBTTelemetery)d_led_fb = d_led_fb_old;
                  sentSuccessfullBTTelemetery = false;
                  setState(() {
                  });
                },
                onChanged: (value){
                  setState(() {
                    d_led_fb = value.round().toDouble();
                  });
                },
              ),
              Text(AppLocalizations.of(context)!.displayType,style: const TextStyle(fontSize: 12),),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 100,
                    child: OutlinedButton(
                        onPressed: () async{
                          await sendTelemetry("u_view_switch", 0, "S11:0");
                          if(sentSuccessfullBTTelemetery) clock=0;
                          sentSuccessfullBTTelemetery = false;
                          setState(() {
                          });
                        },
                        style: OutlinedButton.styleFrom(backgroundColor: clock != 0 ?  Colors.white : const Color(0xff0099F0),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)!.radon, style: TextStyle(color: clock != 0 ?  const Color(0xff0099F0) : Colors.white),),
                          ],
                        )
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: OutlinedButton(
                        onPressed: () async{
                          await sendTelemetry("u_view_switch", 1, "S11:1");
                          if(sentSuccessfullBTTelemetery) clock=1;
                          sentSuccessfullBTTelemetery = false;
                          setState(() {
                          });
                        },
                        style: OutlinedButton.styleFrom(backgroundColor: clock != 1 ?  Colors.white : const Color(0xff0099F0),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)!.time, style: TextStyle(color: clock != 1 ?  const Color(0xff0099F0) : Colors.white),),
                          ],
                        )
                    ),
                  ),
                  SizedBox(
                    child: OutlinedButton(
                        onPressed: () async{
                          await sendTelemetry("u_view_switch", 2, "S11:2");
                          if(sentSuccessfullBTTelemetery) clock=2;
                          sentSuccessfullBTTelemetery = false;
                          setState(() {
                          });
                        },
                        style: OutlinedButton.styleFrom(backgroundColor: clock != 2 ?  Colors.white : const Color(0xff0099F0),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)!.changing, style: TextStyle(color: clock != 2 ?  const Color(0xff0099F0) : Colors.white),),
                          ],
                        )
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10,),
              Text(AppLocalizations.of(context)!.unit,style: const TextStyle(fontSize: 12),),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 160,
                    child: OutlinedButton(
                        onPressed: () async{
                          await sendTelemetry("u_unit", 1, "S01:1");
                          if(sentSuccessfullBTTelemetery) d_unit = 1;
                          sentSuccessfullBTTelemetery = false;
                          setState(() {
                          });
                        },
                        style: OutlinedButton.styleFrom(backgroundColor: d_unit != 1 ?  Colors.white : const Color(0xff0099F0),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Bq/m³", style: TextStyle(color: d_unit != 1 ?  const Color(0xff0099F0) : Colors.white),),
                          ],
                        )
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: OutlinedButton(
                        onPressed: () async{
                          await sendTelemetry("u_unit", 0, "S01:0");
                          if(sentSuccessfullBTTelemetery) d_unit = 0;
                          sentSuccessfullBTTelemetery = false;
                          setState(() {
                          });
                        },
                        style: OutlinedButton.styleFrom(backgroundColor: d_unit != 0 ?  Colors.white : const Color(0xff0099F0),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("pCi/L", style: TextStyle(color: d_unit != 0 ?  const Color(0xff0099F0) : Colors.white),),
                          ],
                        )
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  deviceClockScreen(){
     List<DropdownMenuItem<String>> tzOfSelectionWidgets = [
      DropdownMenuItem(child: Text(AppLocalizations.of(context)!.noneSelected),value: "None selected",)
    ];
     tzOfSelection.forEach((element){
       tzOfSelectionWidgets.add(
           DropdownMenuItem(
               value: element.split("/").sublist(1).join("-"),
               child: Text(element.split("/").sublist(1).join("-"))
           )
       );
     });
    Map<String,String> tzMap = getTZMap();
    tzLocations = [];
    tzCodes = [];
    tzMap.forEach((location,code){
      tzLocations.add(location);
      tzCodes.add(code);
    });
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                tzOfSelection = [];
                timezoneCountry = "None selected";
                timezoneCity = "None selected";
                setState(() {
                  screenIndex = 2;
                });
              },
            ),
            Text(AppLocalizations.of(context)!.clockAndDateT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(AppLocalizations.of(context)!.sendSettWithBT, textAlign: TextAlign.center, style: TextStyle(fontSize: 12),),
                  Switch(
                    value: transmitionMethodSettings,
                    onChanged: (value){
                      transmitionMethodSettings = value;
                      setState(() {

                      });
                    },
                    activeColor: const Color(0xff0099F0),
                    activeTrackColor: const Color(0xffCCEBFC),
                    inactiveTrackColor: Colors.grey,
                    inactiveThumbColor: Colors.white30,
                  ),
                ],
              ),
              Container(
                height: 15,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),
                ),
              ),
              SizedBox(
                height: 25,
              ),
              Row(
                  children: [
                    Text(AppLocalizations.of(context)!.clockType)
                  ]
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 100,
                    child: OutlinedButton(
                        onPressed: () async{
                          await sendTelemetry("u_clock", 1, "S10:1");
                          if(sentSuccessfullBTTelemetery) clockType = 1;
                          sentSuccessfullBTTelemetery = false;
                          setState(() {
                          });
                        },
                        style: OutlinedButton.styleFrom(backgroundColor: clockType != 1 ?  Colors.white : const Color(0xff0099F0),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("24h", style: TextStyle(color: clockType != 1 ?  const Color(0xff0099F0) : Colors.white),),
                          ],
                        )
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: OutlinedButton(
                        onPressed: () async{
                          await sendTelemetry("u_clock", 2, "S10:2");
                          if(sentSuccessfullBTTelemetery) clockType = 2;
                          sentSuccessfullBTTelemetery = false;
                          setState(() {
                          });
                        },
                        style: OutlinedButton.styleFrom(backgroundColor: clockType != 2 ?  Colors.white : const Color(0xff0099F0),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("12h", style: TextStyle(color: clockType != 2 ?  const Color(0xff0099F0) : Colors.white),),
                          ],
                        )
                    ),
                  ),
                  SizedBox(
                    child: OutlinedButton(
                        onPressed: () async{
                          await sendTelemetry("u_clock", 3, "S10:3");
                          if(sentSuccessfullBTTelemetery) clockType = 3;
                          sentSuccessfullBTTelemetery = false;
                          setState(() {
                          });
                        },
                        style: OutlinedButton.styleFrom(backgroundColor: clockType!= 3 ?  Colors.white : const Color(0xff0099F0),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)!.date, style: TextStyle(color: clockType != 3 ?  const Color(0xff0099F0) : Colors.white),),
                          ],
                        )
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Divider(
                  color: Colors.grey[500]
              ),
              SizedBox(
                height: 20,
              ),
              Text("${AppLocalizations.of(context)!.timezoneCurrent} ${currentTZ}",),
              const SizedBox(
                height: 25,
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.selectTimezone),
                      SizedBox(
                        width: 230,
                        height: 50,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.black,
                                    width: 0.5
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(8))
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton(
                              value: timezoneCountry,
                              items: [
                                DropdownMenuItem(
                                    value: "None selected",
                                    child: Text(AppLocalizations.of(context)!.noneSelected)
                                ),
                                DropdownMenuItem<String>(
                                    value: "Africa",
                                    child: Text("Africa")
                                ),
                                DropdownMenuItem<String>(
                                    value: "America",
                                    child: Text("America")
                                ),
                                DropdownMenuItem<String>(
                                    value: "Antarctica",
                                    child: Text("Antarctica")
                                ),
                                DropdownMenuItem<String>(
                                    value: "Asia",
                                    child: Text("Asia")
                                ),
                                DropdownMenuItem<String>(
                                    value: "Australia",
                                    child: Text("Australia")
                                ),
                                DropdownMenuItem<String>(
                                    value: "Europe",
                                    child: Text("Europe")
                                ),
                                DropdownMenuItem<String>(
                                    value: "Indian",
                                    child: Text("Indian")
                                ),
                                DropdownMenuItem<String>(
                                    value: "Pacific",
                                    child: Text("Pacific")
                                ),
                                DropdownMenuItem<String>(
                                    value: "Etc",
                                    child: Text("ETC")
                                ),
                              ],
                              style: TextStyle(color: Colors.black),
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              onChanged: (obj){
                                tzOfSelection = List.of(tzLocations.where((location){
                                  return location.split("/")[0] == obj.toString();
                                }));
                                tzOfSelectionWidgets = [];
                                tzOfSelectionWidgets = [
                                  DropdownMenuItem(
                                      value: "None selected",
                                      child: Text(AppLocalizations.of(context)!.noneSelected)
                                  )
                                ];

                                timezoneCountry = obj.toString();
                                setState(() {
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ]
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                      ),
                      SizedBox(
                          width: 230,
                          height: 50,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.black,
                                    width: 0.5
                                  ),

                                  borderRadius: BorderRadius.all(Radius.circular(8))
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton(
                                  style: TextStyle(color: Colors.black),
                                  items: tzOfSelectionWidgets,
                                  onChanged: (obj){
                                    timezoneCity = obj.toString();
                                    tzSelected = timezoneCountry+"/"+timezoneCity;
                                    setState(() {
                                    });
                                  },
                                  onTap: (){
                                    print(tzOfSelectionWidgets.length);
                                  },
                                  value: timezoneCity
                              ),
                            ),
                          )
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                      onPressed: (){
                        AlertDialog alert = AlertDialog(
                          title: Text("${AppLocalizations.of(context)!.set} ${tzSelected} ${AppLocalizations.of(context)!.asTimezone}", style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                        setTimezone(tzCodes[tzLocations.indexWhere((element){
                                          return element.contains(tzSelected);
                                        })]);
                                        currentTZ = (tzLocations.firstWhere((element){
                                          return element.contains(tzSelected);
                                        }));
                                        storage.write(key: 'timezone', value: currentTZ);
                                        Navigator.pop(context);
                                        setState(() {
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50)),
                                      child: Text(AppLocalizations.of(context)!.confirm,style: const TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10,),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: (){
                                        Navigator.pop(context);
                                      },
                                      style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50)),
                                      child: Text(AppLocalizations.of(context)!.cancel,style: const TextStyle(color: Colors.black)),
                                    ),
                                  ),
                                ],
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
                      child: Text(AppLocalizations.of(context)!.applyTZ,style: TextStyle(color: const Color(0xff0099F0)),)
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Divider(
                  color: Colors.grey[500]
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(AppLocalizations.of(context)!.changeNtpServer,style: TextStyle(fontSize: 12)),
                  SizedBox(
                    width: 10,
                  ),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      style: TextStyle(fontSize: 12),
                      controller: customNTPServerController,
                      decoration: InputDecoration(
                        hintText: tzServer3
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
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
                        setNTPServer(customNTPServerController.text);
                        tzServer3 = customNTPServerController.text;
                        setState(() {

                        });
                      },
                      style: OutlinedButton.styleFrom(backgroundColor: Colors.white ,shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(AppLocalizations.of(context)!.applyNTP, style: const TextStyle(color: Color(0xff0099F0),)),
                        ],
                      )
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Divider(
                  color: Colors.grey[500]
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                  children: [
                    Text(AppLocalizations.of(context)!.winterSummerTime)
                  ]
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 160,
                    child: OutlinedButton(
                        onPressed: () async{
                          await sendTelemetry("u_mez_ea", 0, "S15:0");
                          if(sentSuccessfullBTTelemetery) mezType = 0;
                          sentSuccessfullBTTelemetery = false;
                          setState(() {
                          });
                        },
                        style: OutlinedButton.styleFrom(backgroundColor: mezType != 0 ?  Colors.white : const Color(0xff0099F0),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)!.withoutChange, style: TextStyle(color: mezType != 0 ?  const Color(0xff0099F0) : Colors.white),),
                          ],
                        )
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: OutlinedButton(
                        onPressed: () async{
                          sendTelemetry("u_mez_ea", 1, "S15:1");
                          if(sentSuccessfullBTTelemetery) mezType = 1;
                          sentSuccessfullBTTelemetery = false;
                          setState(() {
                          });
                        },
                        style: OutlinedButton.styleFrom(backgroundColor: mezType != 1 ?  Colors.white : const Color(0xff0099F0),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)!.withChange, style: TextStyle(color: mezType != 1 ?  const Color(0xff0099F0) : Colors.white),),
                          ],
                        )
                    ),
                  ),

                ],
              ),
              SizedBox(
                height: 50,
              )
            ],
          ),
        ),
      ),
    );
  }

  deviceKNXScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                try{
                  subscriptionToDevice!.cancel();
                  btDevice!.disconnect(timeout: 1);
                  btDevice!.removeBond();
                }catch(e){
                }
                setState(() {
                  screenIndex = 2;
                });
              },
            ),
            Text("KNX",style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),textScaler: MediaQuery.textScalerOf(context),),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: (){
                  sendBTLine(["S53:1"]);
                  setState(() {

                  });
                },
                style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xff0099f0),
                    disabledBackgroundColor: Colors.grey
                ),
                child: Text(AppLocalizations.of(context)!.bootKNX,style: const TextStyle(color: Colors.white), textAlign: TextAlign.center,),
              ),
              SizedBox(
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.knxOnOff),
                  Switch(
                      value: knxOnOff,
                      onChanged: (value)async{
                        AlertDialog alert = AlertDialog(
                          title: Text(AppLocalizations.of(context)!.mqttOnOff, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(AppLocalizations.of(context)!.deviceWillRestart),
                              SizedBox(
                                height: 30,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed:() async{
                                            if(!knxOnOff) await sendBTLine(["S54:1"]);
                                            else await sendBTLine(["S54:0"]);
                                            setState(() {

                                            });
                                          },
                                          style: OutlinedButton.styleFrom(
                                              backgroundColor: const Color(0xff0099f0),
                                              disabledBackgroundColor: Colors.grey,
                                              minimumSize: Size(100, 50)
                                          ),
                                          child: Text(AppLocalizations.of(context)!.apply,style: const TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: (){
                                            Navigator.pop(context);
                                            setState(() {

                                            });
                                          },
                                          style: OutlinedButton.styleFrom(backgroundColor: Colors.white,minimumSize: Size(100, 50)),
                                          child: Text(AppLocalizations.of(context)!.cancel,style: const TextStyle(color: Colors.black)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
                    activeTrackColor: Colors.green,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.red,
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.knxProgMode),
                  Switch(
                      value: knxProgMode,
                      onChanged: (value){
                        if(knxProgMode)return;
                        sendBTLine(["S55"]);
                        setState(() {

                        });
                      },
                    activeTrackColor: Colors.green,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.red,
                  ),
                ],
              ),
              SizedBox(
                height: 15,
              ),
              Divider(
                  color: Colors.grey[500]
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: TextField(
                      controller: knxPhysAddress,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.physID,
                        floatingLabelStyle: TextStyle(color: Colors.black),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        disabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                    
                        hintText: AppLocalizations.of(context)!.physID,
                        hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                        errorText: knxPhysIDError
                      ),
                      onChanged: (text){
                        setState(() {
                          if (text.isEmpty) {
                            knxPhysIDError = AppLocalizations.of(context)!.plsEnterAddress;
                          } else if (!RegExp(r'^((25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\.){2}(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)$').hasMatch(knxPhysAddress.text)) {
                            knxPhysIDError = AppLocalizations.of(context)!.invalidAddress;
                          } else {
                            knxPhysIDError = null;
                          }
                        });
                      },
                    ),
                  ),
                  
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Divider(
                  color: Colors.grey[500]
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: TextField(
                      controller: knxGroup1,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.groupAddress1,
                          floatingLabelStyle: TextStyle(color: Colors.black),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          disabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                    
                          hintText: AppLocalizations.of(context)!.groupAddress1,
                          hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                          errorText: knxGroupError1
                      ),
                      onChanged: (text){
                        setState(() {
                          if (text.isEmpty) {
                            knxGroupError1 = null;
                          } else if (!RegExp(r'^((25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\/){2}(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)$').hasMatch(knxGroup1.text)) {
                            knxGroupError1 = AppLocalizations.of(context)!.invalidAddressBackslash;
                          } else {
                            knxGroupError1 = null;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: TextField(
                      controller: knxGroup2,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.groupAddress2,
                          floatingLabelStyle: TextStyle(color: Colors.black),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          disabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          fillColor: Colors.white,
                          filled: true,
        
                          hintText: AppLocalizations.of(context)!.groupAddress2,
                          hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                          errorText: knxGroupError2
                      ),
                      onChanged: (text){
                        setState(() {
                          if (text.isEmpty) {
                            knxGroupError2 = null;
                          } else if (!RegExp(r'^((25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\/){2}(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)$').hasMatch(knxGroup2.text)) {
                            knxGroupError2 = AppLocalizations.of(context)!.invalidAddressBackslash;
                          } else {
                            knxGroupError2 = null;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: TextField(
                      controller: knxGroup3,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.groupAddress3,
                          floatingLabelStyle: TextStyle(color: Colors.black),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          disabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          fillColor: Colors.white,
                          filled: true,
        
                          hintText: AppLocalizations.of(context)!.groupAddress3,
                          hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                          errorText: knxGroupError3
                      ),
                      onChanged: (text){
                        setState(() {
                          if (text.isEmpty) {
                            knxGroupError3 = null;
                          } else if (!RegExp(r'^((25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\/){2}(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)$').hasMatch(knxGroup3.text)) {
                            knxGroupError3 = AppLocalizations.of(context)!.invalidAddressBackslash;
                          } else {
                            knxGroupError3 = null;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: TextField(
                      controller: knxGroup4,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.groupAddress4,
                          floatingLabelStyle: TextStyle(color: Colors.black),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          disabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          fillColor: Colors.white,
                          filled: true,
        
                          hintText: AppLocalizations.of(context)!.groupAddress4,
                          hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                          errorText: knxGroupError4
                      ),
                      onChanged: (text){
                        setState(() {
                          if (text.isEmpty) {
                            knxGroupError4 = null;
                          } else if (!RegExp(r'^((25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\/){2}(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)$').hasMatch(knxGroup4.text)) {
                            knxGroupError4 = AppLocalizations.of(context)!.invalidAddressBackslash;
                          } else {
                            knxGroupError4 = null;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Divider(
                  color: Colors.grey[500]
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: TextField(
                      controller: knxIP,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.ipAddress,
                          floatingLabelStyle: TextStyle(color: Colors.black),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          disabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          fillColor: Colors.white,
                          filled: true,

                          hintText: AppLocalizations.of(context)!.ipAddress,
                          hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                          errorText: knxIPError
                      ),
                      onChanged: (text){
                        setState(() {
                          if (text.isEmpty) {
                            knxIPError = AppLocalizations.of(context)!.plsEnterAddress;
                          } else if (!RegExp(r'^((25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\.){2}(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)$').hasMatch(knxIP.text)) {
                            knxIPError = AppLocalizations.of(context)!.invalidAddress;
                          } else {
                            knxIPError = null;
                          }
                        });
                      },
                    ),
                  ),

                ],
              ),
              SizedBox(
                height: 15,
              ),
              Divider(
                  color: Colors.grey[500]
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: TextField(
                      controller: knxSubnetMask,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.subnetMask,
                          floatingLabelStyle: TextStyle(color: Colors.black),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          disabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          fillColor: Colors.white,
                          filled: true,

                          hintText: AppLocalizations.of(context)!.subnetMask,
                          hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                          errorText: knxSubnetMaskError
                      ),
                      onChanged: (text){
                        setState(() {
                          if (text.isEmpty) {
                            knxSubnetMaskError = AppLocalizations.of(context)!.plsEnterAddress;
                          } else if (!RegExp(r'^((25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\.){2}(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)$').hasMatch(knxSubnetMask.text)) {
                            knxSubnetMaskError = AppLocalizations.of(context)!.invalidAddress;
                          } else {
                            knxSubnetMaskError = null;
                          }
                        });
                      },
                    ),
                  ),

                ],
              ),
              SizedBox(
                height: 15,
              ),
              Divider(
                  color: Colors.grey[500]
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: TextField(
                      controller: knxGateway,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.gateway,
                          floatingLabelStyle: TextStyle(color: Colors.black),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          disabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          fillColor: Colors.white,
                          filled: true,

                          hintText: AppLocalizations.of(context)!.gateway,
                          hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                          errorText: knxGatewayError
                      ),
                      onChanged: (text){
                        setState(() {
                          if (text.isEmpty) {
                            knxGatewayError = AppLocalizations.of(context)!.plsEnterAddress;
                          } else if (!RegExp(r'^((25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\.){2}(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)$').hasMatch(knxGateway.text)) {
                            knxGatewayError = AppLocalizations.of(context)!.invalidAddress;
                          } else {
                            knxGatewayError = null;
                          }
                        });
                      },
                    ),
                  ),

                ],
              ),
              SizedBox(
                height: 15,
              ),
              Divider(
                  color: Colors.grey[500]
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: TextField(
                      controller: knxMultiCastAddress,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.multiCastAddress,
                          floatingLabelStyle: TextStyle(color: Colors.black),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          disabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                          ),
                          fillColor: Colors.white,
                          filled: true,

                          hintText: AppLocalizations.of(context)!.multiCastAddress,
                          hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                          errorText: knxMultiCastError
                      ),
                      onChanged: (text){
                        setState(() {
                          if (text.isEmpty) {
                            knxMultiCastError = AppLocalizations.of(context)!.plsEnterAddress;
                          } else if (!RegExp(r'^((25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\.){2}(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)$').hasMatch(knxMultiCastAddress.text)) {
                            knxMultiCastError = AppLocalizations.of(context)!.invalidAddress;
                          } else {
                            knxMultiCastError = null;
                          }
                        });
                      },
                    ),
                  ),

                ],
              ),
              SizedBox(
                height: 20,
              ),
              Divider(
                  color: Colors.grey[500]
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.bootTime),
                ],
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: (){
                        knxParam0 = "0";
                        setState(() {

                        });
                      },
                      style: OutlinedButton.styleFrom(
                          backgroundColor: knxParam0 == "0" ? const Color(0xff0099f0) : Colors.grey,
                          disabledBackgroundColor: Colors.grey
                      ),
                      child: Text("5s",style: TextStyle(color: Colors.white)),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    OutlinedButton(
                      onPressed: (){
                        knxParam0 = "1";
                        setState(() {

                        });
                      },
                      style: OutlinedButton.styleFrom(
                          backgroundColor: knxParam0 == "1" ? const Color(0xff0099f0) : Colors.grey,
                          disabledBackgroundColor: Colors.grey
                      ),
                      child: Text("10s",style: const TextStyle(color: Colors.white)),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    OutlinedButton(
                      onPressed: (){
                        knxParam0 = "2";
                        setState(() {

                        });

                      },
                      style: OutlinedButton.styleFrom(
                          backgroundColor: knxParam0 == "2" ? const Color(0xff0099f0) : Colors.grey,
                          disabledBackgroundColor: Colors.grey
                      ),
                      child: Text("15s",style: const TextStyle(color: Colors.white)),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    OutlinedButton(
                      onPressed: (){
                        knxParam0 = "3";
                        setState(() {

                        });
                      },
                      style: OutlinedButton.styleFrom(
                          backgroundColor: knxParam0 == "3" ? const Color(0xff0099f0) : Colors.grey,
                          disabledBackgroundColor: Colors.grey
                      ),
                      child: Text("20s",style: const TextStyle(color: Colors.white)),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    OutlinedButton(
                      onPressed: (){
                        knxParam0 = "4";
                        setState(() {

                        });
                      },
                      style: OutlinedButton.styleFrom(
                          backgroundColor: knxParam0 == "4" ? const Color(0xff0099f0) : Colors.grey,
                          disabledBackgroundColor: Colors.grey
                      ),
                      child: Text("25s",style: const TextStyle(color: Colors.white)),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    OutlinedButton(
                      onPressed: (){
                        knxParam0 = "5";
                        setState(() {

                        });
                      },
                      style: OutlinedButton.styleFrom(
                          backgroundColor: knxParam0 == "5" ? const Color(0xff0099f0) : Colors.grey,
                          disabledBackgroundColor: Colors.grey
                      ),
                      child: Text("30s",style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Divider(
                  color: Colors.grey[500]
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.send),
                ],
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: (){
                        knxParam1 = "0";
                        setState(() {

                        });
                      },
                      style: OutlinedButton.styleFrom(
                          backgroundColor: knxParam1 == "0" ? const Color(0xff0099f0) : Colors.grey,
                          disabledBackgroundColor: Colors.grey
                      ),
                      child: Text(AppLocalizations.of(context)!.deact,style: const TextStyle(color: Colors.white)),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    OutlinedButton(
                      onPressed:(){
                        knxParam1 = "1";
                        setState(() {

                        });
                      },
                      style: OutlinedButton.styleFrom(
                          backgroundColor: knxParam1 == "1" ? const Color(0xff0099f0) : Colors.grey,
                          disabledBackgroundColor: Colors.grey
                      ),
                      child: Text("1min",style: const TextStyle(color: Colors.white)),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    OutlinedButton(
                      onPressed: (){
                        knxParam1 = "2";
                        setState(() {

                        });
                      },
                      style: OutlinedButton.styleFrom(
                          backgroundColor: knxParam1 == "2" ? const Color(0xff0099f0) : Colors.grey,
                          disabledBackgroundColor: Colors.grey
                      ),
                      child: Text("10min",style: const TextStyle(color: Colors.white)),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    OutlinedButton(
                      onPressed: (){
                        knxParam1 = "3";
                        setState(() {

                        });
                      },
                      style: OutlinedButton.styleFrom(
                          backgroundColor: knxParam1 == "3" ? const Color(0xff0099f0) : Colors.grey,
                          disabledBackgroundColor: Colors.grey
                      ),
                      child: Text("60min",style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 15,
              ),
              Divider(
                  color: Colors.grey[500]
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: (){
                      if(knxGroupError1!=null || knxGroupError2!=null || knxGroupError3!=null || knxGroupError4!=null || knxIPError!=null || knxSubnetMaskError!=null || knxGatewayError!=null || knxMultiCastError!=null) return;
                      sendBTLine(["S56:${knxPhysAddress.text}","S57:${knxGroup1.text.replaceAll("/", ".")}&${knxGroup2.text.replaceAll("/", ".")}&${knxGroup3.text.replaceAll("/", ".")}&${knxGroup4.text.replaceAll("/", ".")}", "S58:${knxParam0}", "S59:${knxParam1}", "S52:${knxIP.text}", "S62:${knxSubnetMask.text}", "S61:${knxGateway.text}", "S60:${knxMultiCastAddress.text}"]);
                      setState(() {

                      });
                    },
                    style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xff0099f0),
                        disabledBackgroundColor: Colors.grey
                    ),
                    child: Text(AppLocalizations.of(context)!.apply,style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      )
    );
  }

  deviceCloudScreen() {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                try{
                  subscriptionToDevice!.cancel();
                  btDevice!.disconnect(timeout: 1);
                  btDevice!.removeBond();
                }catch(e){
                }
                setState(() {
                  screenIndex = 2;
                });
              },
            ),
            Text("CLOUD SERVER",style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
          ],
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.cloudOnOff),
                  Switch(
                    value: cloudOnOff,
                    onChanged: (value) async{
                      if(!cloudOnOff) {
                        await sendBTLine(["S66:1"]);
                      } else {
                        await sendBTLine(["S66:0"]);
                      }
                      setState(() {

                      });
                    },
                    activeTrackColor: Colors.green,
                    inactiveTrackColor: Colors.red,
                    inactiveThumbColor: Colors.white,
                  ),
                ],
              ),
              SizedBox(
                height: 30,
              ),
              Row(
                children: [
                  Flexible(
                    child: TextField(
                      controller: cloudServer,
                      decoration: InputDecoration(
                        labelText: "Server",
                        floatingLabelStyle: TextStyle(color: Colors.black),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        disabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        fillColor: Colors.white,
                        filled: true,

                        hintText: "Server",
                        hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Flexible(
                    child: TextField(
                      controller: cloudPage,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.page,
                        floatingLabelStyle: TextStyle(color: Colors.black),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        disabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        fillColor: Colors.white,
                        filled: true,

                        hintText: AppLocalizations.of(context)!.page,
                        hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Flexible(
                    child: TextField(
                      controller: cloudPaChain,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.characters,
                        floatingLabelStyle: TextStyle(color: Colors.black),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        disabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        fillColor: Colors.white,
                        filled: true,

                        hintText: AppLocalizations.of(context)!.characters,
                        hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Flexible(
                    child: TextField(
                      controller: cloudPre,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.prefix,
                        floatingLabelStyle: TextStyle(color: Colors.black),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        disabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        fillColor: Colors.white,
                        filled: true,

                        hintText: AppLocalizations.of(context)!.prefix,
                        hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: (){
                      sendBTLine(["S63:${cloudServer.text}","S64:${cloudPage.text}","S65:${cloudPaChain.text}","S67:${cloudPre.text}"]);
                      setState(() {

                      });
                    },
                    style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xff0099f0),
                        disabledBackgroundColor: Colors.grey
                    ),
                    child: Text(AppLocalizations.of(context)!.apply,style: const TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ],
          ),
        ),
      )
    );
  }

  deviceMQTTScreen() {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                try{
                  subscriptionToDevice!.cancel();
                  btDevice!.disconnect(timeout: 1);
                  btDevice!.removeBond();
                }catch(e){
                }
                setState(() {
                  screenIndex = 2;
                });
              },
            ),
            Text("MQTT",style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
          ],
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  Text("Webserver"),
                  TextButton(onPressed: () async {
                    final Uri url = Uri.parse('https://${device.values.first.name}.local');
                    if (!await launchUrl(url)) {
                      throw Exception('Could not launch $url');
                    }
                  }, child: Text('https://${device.values.first.name}.local'))
                ],
              ),
              const SizedBox(height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.mqttOnOff),
                  Switch(
                      value: mqttOnOff,
                      onChanged: (value){
                        AlertDialog alert = AlertDialog(
                          title: Text(AppLocalizations.of(context)!.mqttOnOff, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(AppLocalizations.of(context)!.deviceWillRestart),
                              SizedBox(
                                height: 30,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed:() async{
                                            if(!mqttOnOff) {
                                              await sendBTLine(["S70:1"]);
                                            } else {
                                              await sendBTLine(["S70:0"]);
                                            }
                                            setState(() {

                                            });
                                          },
                                          style: OutlinedButton.styleFrom(
                                              backgroundColor: const Color(0xff0099f0),
                                              disabledBackgroundColor: Colors.grey,
                                              minimumSize: Size(100, 50)
                                          ),
                                          child: Text(AppLocalizations.of(context)!.apply,style: const TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: (){
                                            Navigator.pop(context);
                                            setState(() {

                                            });
                                          },
                                          style: OutlinedButton.styleFrom(backgroundColor: Colors.white,minimumSize: Size(100, 50)),
                                          child: Text(AppLocalizations.of(context)!.cancel,style: const TextStyle(color: Colors.black)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
                    activeTrackColor: Colors.green,
                    inactiveTrackColor: Colors.red,
                    inactiveThumbColor: Colors.white,
                  ),
                ],
              ),
              SizedBox(
                height: 30,
              ),
              Row(
                children: [
                  Flexible(
                    child: TextField(
                      controller: mqttClient,
                      decoration: InputDecoration(
                        labelText: "Client",
                        floatingLabelStyle: TextStyle(color: Colors.black),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        disabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        fillColor: Colors.white,
                        filled: true,

                        hintText: "Client",
                        hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Flexible(
                    child: TextField(
                      controller: mqttServer,
                      decoration: InputDecoration(
                        labelText: "Server",
                        floatingLabelStyle: TextStyle(color: Colors.black),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        disabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        fillColor: Colors.white,
                        filled: true,

                        hintText: "Server",
                        hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Flexible(
                    child: TextField(
                      controller: mqttUser,
                      decoration: InputDecoration(
                        labelText: "User",
                        floatingLabelStyle: TextStyle(color: Colors.black),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        disabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        fillColor: Colors.white,
                        filled: true,

                        hintText: "User",
                        hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Flexible(
                    child: TextField(
                      controller: mqttPort,
                      decoration: InputDecoration(
                        labelText: "Port",
                        floatingLabelStyle: TextStyle(color: Colors.black),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        disabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        fillColor: Colors.white,
                        filled: true,

                        hintText: "Port",
                        hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Flexible(
                    child: TextField(
                      controller: mqttTopic,
                      decoration: InputDecoration(
                        labelText: "Topic",
                        floatingLabelStyle: TextStyle(color: Colors.black),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        disabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        fillColor: Colors.white,
                        filled: true,

                        hintText: "Topic",
                        hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                      onPressed: (){
                        sendBTLine(["S71:${mqttClient.text}","S72:${mqttServer.text}","S73:${mqttUser.text}","S74:${mqttPort.text}","S75:${mqttTopic.text}"]);
                        setState(() {

                        });
                      },
                    style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xff0099f0),
                        disabledBackgroundColor: Colors.grey
                    ),
                      child: Text(AppLocalizations.of(context)!.apply,style: const TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ],
          ),
        ),
      )
    );

  }
  
  sendBTLine(List<String> lines) async{
    try{
      showDialog(context: context, builder: (context) {
        return Scaffold(
            body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.searchingDevice),
                    const SizedBox(height: 36,),
                    const CircularProgressIndicator(color: Colors.black,),
                  ],
                )
            )
        );
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
      bool sentSuccessfully = false;
      bool loginSuccessful = false;
      subscription = FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
          if (!deviceFound) {
            List<int> bluetoothAdvertisementData = [];
            String bluetoothDeviceName = "";
            if(r.advertisementData.manufacturerData.keys.isNotEmpty){
              if(r.advertisementData.manufacturerData.values.isNotEmpty){
                bluetoothAdvertisementData = r.advertisementData.manufacturerData.values.first;
              }
              if(r.advertisementData.manufacturerData.keys.first == 3503) bluetoothDeviceName += utf8.decode(bluetoothAdvertisementData.sublist(15,23));
              if(bluetoothDeviceName == device.values.first.name){
                radonValue = bluetoothAdvertisementData.elementAt(1).toString();
                radonCurrent = bluetoothAdvertisementData.elementAt(1);
                radonDaily = bluetoothAdvertisementData.elementAt(5);
                currentAvgValue = bluetoothAdvertisementData.elementAt(5);
                radonEver = bluetoothAdvertisementData.elementAt(9);
                deviceFound = true;
                FlutterBluePlus.stopScan();
                subscription!.cancel();
                btDevice = r.device;
                try{
                  await btDevice!.connect();
                }catch(e){
                  Navigator.of(context).pop();
                  setState(() {

                  });
                  return;
                }
                try{
                  if (Platform.isAndroid) {
                    await r.device.requestMtu(300);
                  }
                  List<BluetoothService> services = await r.device.discoverServices();
                  for (var service in services){
                    for(var characteristic in service.characteristics){
                      if(characteristic.properties.notify){
                        await characteristic.setNotifyValue(true);
                        readCharacteristic = characteristic;
                        subscriptionToDevice = readCharacteristic!.lastValueStream.timeout(
                            Duration(seconds: 2),
                            onTimeout: (list)async{
                              await btDevice!.disconnect(timeout: 1);
                              btDevice!.removeBond();
                              subscriptionToDevice?.cancel();
                              loaded = true;
                              setState(() {
                                screenIndex = 1;
                                Navigator.pop(context);
                              });
                              Fluttertoast.showToast(
                                  msg: "Error"
                              );
                            }
                        ).listen((data) async{
                          String message = utf8.decode(data).trim();
                          //logger.d(utf8.decode(data));
                          if(message == "" && !loginSuccessful){
                            await Future<void>.delayed(const Duration(seconds: 1));
                            if(!loginSuccessful){
                              try{
                                loginSuccessful = true;
                                await writeCharacteristic!.write(utf8.encode('k47t58W43Lds8'));
                              }catch(e){
                              }
                            }
                          }
                          if(message == 'LOGIN OK'){
                            sentSuccessfully = true;
                            lines.forEach((line)async{
                              await writeCharacteristic!.write(utf8.encode(line));
                              await Future<void>.delayed( const Duration(milliseconds: 50));
                            });
                            await btDevice!.disconnect(timeout: 1);
                            btDevice!.removeBond();
                            subscriptionToDevice?.cancel();
                            Navigator.pop(context);
                          }
                          if((message.split(":").first == "G63") || (message.split(":").first ==  "S63")){
                            cloudServer.text = message.split(":").last;
                          }
                          if((message.split(":").first == "G64") || (message.split(":").first ==  "S64")){
                            cloudPage.text = message.split(":").last;
                          }
                          if((message.split(":").first == "G65") || (message.split(":").first ==  "S65")){
                            cloudPaChain.text = message.split(":").last;
                          }
                          if((message.split(":").first == "G66") || (message.split(":").first ==  "S66")){
                            cloudOnOff = "1" == message.split(":").last ? true : false;
                          }
                          if((message.split(":").first == "G67") || (message.split(":").first ==  "S67")){
                            cloudPre.text = message.split(":").last;
                          }
                          if((message.split(":").first == "G54")  || (message.split(":").first ==  "S54")){
                            knxOnOff = "1" == message.split(":").last ? true : false;
                          }
                          if((message.split(":").first == "G55")  || (message.split(":").first ==  "S55")){
                            knxProgMode = "1" == message.split(":").last ? true : false;
                          }
                          if((message.split(":").first == "G56") || (message.split(":").first ==  "S56")){
                            knxPhysAddress.text = message.split(":").last;
                          }
                          if((message.split(":").first == "G57") || (message.split(":").first ==  "S57")){
                            knxGroup1.text = message.split(":").last.split(",")[0].replaceAll(".", "/");
                          }
                          if((message.split(":").first == "G57")  || (message.split(":").first ==  "S57")){
                            knxGroup2.text = message.split(":").last.split(",")[1].replaceAll(".", "/");
                          }
                          if((message.split(":").first == "G57") || (message.split(":").first ==  "S57")){
                            knxGroup3.text = message.split(":").last.split(",")[2].replaceAll(".", "/");
                          }
                          if((message.split(":").first == "G57") || (message.split(":").first ==  "S57")){
                            knxGroup4.text = message.split(":").last.split(",")[3].replaceAll(".", "/");
                          }
                          if((message.split(":").first == "G58") || (message.split(":").first ==  "S58")){
                            knxParam0 = message.split(":").last;
                          }
                          if((message.split(":").first == "G59" ) || (message.split(":").first ==  "S59")){
                            knxParam1 = message.split(":").last;
                          }
                          if((message.split(":").first == "G52" ) || (message.split(":").first ==  "S52")){
                            knxIP.text = message.split(":").last;
                          }
                          if((message.split(":").first == "G62" ) || (message.split(":").first ==  "S62")){
                            knxSubnetMask.text = message.split(":").last;
                          }
                          if((message.split(":").first == "G61" ) || (message.split(":").first ==  "S61")){
                            knxGateway.text = message.split(":").last;
                          }
                          if((message.split(":").first == "G60" ) || (message.split(":").first ==  "S60")){
                            knxMultiCastAddress.text = message.split(":").last;
                          }
                          if((message.split(":").first == "G70") || (message.split(":").first ==  "S70")){
                            mqttOnOff = "1" == message.split(":").last ? true : false;
                          }
                          if((message.split(":").first == "G71" ) || ((message.split(":").first ==  "S71"))){
                            mqttClient.text = message.split(":").last;
                          }
                          if((message.split(":").first == "G72")  || ((message.split(":").first ==  "S72"))){
                            mqttServer.text = message.split(":").last;
                          }
                          if((message.split(":").first == "G73")  || (message.split(":").first ==  "S73")){
                            mqttUser.text = message.split(":").last;
                          }
                          if((message.split(":").first == "G74") || (message.split(":").first ==  "S74")){
                            mqttPort.text = message.split(":").last;
                          }
                          if((message.split(":").first == "G75")  || (message.split(":").first ==  "S75")){
                            mqttTopic.text = message.split(":").last;
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
                            await btDevice!.disconnect(timeout: 1);
                            btDevice!.removeBond();
                            subscriptionToDevice?.cancel();
                            Navigator.pop(context);
                          }
                        }
                      }
                    }
                  }
                }catch(e){
                  await btDevice!.disconnect(timeout: 1);
                  btDevice!.removeBond();
                  subscriptionToDevice?.cancel();
                  Navigator.pop(context);
                }
              }
            }
          }
        }
      });
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 3));
      await Future<void>.delayed( const Duration(seconds: 3));
      if(!deviceFound){
        subscription!.cancel();
        screenIndex = 1;
        Navigator.pop(context);
        Fluttertoast.showToast(
            msg: AppLocalizations.of(context)!.deviceNotFound
        );
      }
      if(!sentSuccessfully && loginSuccessful){
        subscription!.cancel();
        await btDevice!.disconnect(timeout: 1);
        btDevice!.removeBond();
        subscriptionToDevice?.cancel();
        Navigator.pop(context);
      }
    }catch(e){
      try{
        subscription!.cancel();
        await btDevice!.disconnect(timeout: 1);
        btDevice!.removeBond();
        subscriptionToDevice?.cancel();
        screenIndex = 1;
        Navigator.pop(context);
      }catch(e){
      }
    }
  }

  deviceWifiSelectScreen() {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                try{
                  subscriptionToDevice!.cancel();
                  btDevice!.disconnect(timeout: 1);
                  btDevice!.removeBond();
                }catch(e){
                }
                setState(() {
                  screenIndex = 2;
                });
              },
            ),
            Text(AppLocalizations.of(context)!.connectToWifiT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10,),
          Row(
            children: [
              const SizedBox(width: 16,),
              Text(AppLocalizations.of(context)!.availableNetworks)
            ],
          ),
          const SizedBox(height: 2,),
          Expanded(
            child: ListView.separated(
                itemBuilder: (BuildContext context, int index){
                  return OutlinedButton(
                      onPressed: () {
                        setState(() {
                          screenIndex = 22;
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
          )
        ],
      ),
    );
  }

  deviceWifiPasswordScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                try{
                  subscriptionToDevice!.cancel();
                  btDevice!.disconnect(timeout: 1);
                  btDevice!.removeBond();
                }catch(e){
                }
                setState(() {
                  screenIndex = 2;
                });
              },
            ),
            Text(AppLocalizations.of(context)!.connectToWifiT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
          ],
        ),
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
                  borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
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
                          foregroundColor: const Color(0xff0099f0),
                          backgroundColor: const Color(0xff0099f0),
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

  connectWithBluetooth() async{
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
                  Text(AppLocalizations.of(context)!.searchingDevAndWifi1),
                  Text(AppLocalizations.of(context)!.searchingDevAndWifi2),
                  const SizedBox(height: 36,),
                  const CircularProgressIndicator(color: Colors.black,),
                ],
              )
          )
        ),
      );
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
    bool loginSuccessful = false;
    bool hasScanned = false;
    subscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (!deviceFound) {
          List<int> bluetoothAdvertisementData = [];
          String bluetoothDeviceName = "";
          if(r.advertisementData.manufacturerData.keys.isNotEmpty){
            if(r.advertisementData.manufacturerData.values.isNotEmpty){
              bluetoothAdvertisementData = r.advertisementData.manufacturerData.values.first;
            }
            if(r.advertisementData.manufacturerData.keys.first == 3503) bluetoothDeviceName += utf8.decode(bluetoothAdvertisementData.sublist(15,23));
          }
          if(bluetoothDeviceName == device.values.first.name) {
            deviceFound = true;
            btDevice = r.device;
            try{
              await btDevice!.connect();
            }catch(e){
              Navigator.of(context).pop();
              setState(() {

              });
              return;
            }
            if (Platform.isAndroid) {
              await r.device.requestMtu(100);
            }
            List<BluetoothService> services = await r.device.discoverServices();
            for (var service in services){
              for(var characteristic in service.characteristics){
                if(characteristic.properties.notify){
                  await characteristic.setNotifyValue(true);
                  readCharacteristic = characteristic;
                  subscriptionToDevice = readCharacteristic!.lastValueStream.timeout(
                      Duration(seconds: 8),
                      onTimeout: (list)async{
                        if(hasScanned)return;
                        await btDevice!.disconnect(timeout: 1);
                        btDevice!.removeBond();
                        subscriptionToDevice?.cancel();
                        loaded = true;
                        setState(() {
                          screenIndex = 1;
                          Navigator.pop(context);
                        });
                        Fluttertoast.showToast(
                            msg: "Error"
                        );
                      }
                  ).listen((data) async{
                    String message = utf8.decode(data).trim();
                    //logger.d(utf8.decode(data));
                    if(message == "" && !loginSuccessful){
                      await Future<void>.delayed(const Duration(seconds: 1));
                      if(!loginSuccessful){
                        try{
                          loginSuccessful = true;
                          await writeCharacteristic!.write(utf8.encode('k47t58W43Lds8'));
                        }catch(e){
                        }
                      }
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
                            screenIndex = 1;
                          });
                          Fluttertoast.showToast(
                              msg: AppLocalizations.of(context)!.noAPFound
                          );
                        }
                        Navigator.pop(context);
                        setState(() {
                          screenIndex = 21;
                        });
                      }
                    }
                    if(message == 'Connect Success'){
                      await btDevice!.disconnect(timeout: 1);
                      btDevice!.removeBond();
                      subscriptionToDevice?.cancel();
                      setState(() {
                        screenIndex = 1;
                      });
                      Navigator.pop(context);
                      Fluttertoast.showToast(
                          msg: AppLocalizations.of(context)!.deviceSuccConnected
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
        }
      }
    });
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 3));
    await Future<void>.delayed( const Duration(seconds: 3));
    if(!loginSuccessful){
      try{
        await btDevice!.disconnect(timeout: 1);
        btDevice!.removeBond();
        subscriptionToDevice?.cancel();
        loaded = true;
        setState(() {
          screenIndex = 1;
          Navigator.pop(context);
        });
        Fluttertoast.showToast(
            msg: "Error"
        );
      }catch(e){
      }
    }
    if(!deviceFound){
      subscription!.cancel();
      Navigator.pop(context);
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.deviceNotFound
      );
    }
  }

  Future<dynamic> readOfflineData() async{
    if(futureFuncRunning)return;
    requestMsSinceEpoch = DateTime.now().millisecondsSinceEpoch;
    futureFuncRunning = true;
    radonHistory = [];
    radonHistoryTimestamps = [];
    currentMinValue = 0;
    currentMaxValue = 0;
    foundAccessPoints = {};
    if(!useBluetoothData){
      showDialog(context: context, builder: (context) {
        return Scaffold(
            body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.searchingDevice),
                    const SizedBox(height: 36,),
                    const CircularProgressIndicator(color: Colors.black,),
                  ],
                )
            )
        );
      });
    }
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
    subscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (!deviceFound) {
          List<int> bluetoothAdvertisementData = [];
          String bluetoothDeviceName = "";
          if(r.advertisementData.manufacturerData.keys.isNotEmpty){
            if(r.advertisementData.manufacturerData.values.isNotEmpty){
              bluetoothAdvertisementData = r.advertisementData.manufacturerData.values.first;
            }
            if(r.advertisementData.manufacturerData.keys.first == 3503) bluetoothDeviceName += utf8.decode(bluetoothAdvertisementData.sublist(15,23));
            if(bluetoothDeviceName == device.values.first.name){
              radonValue = bluetoothAdvertisementData.elementAt(1).toString();
              radonCurrent = bluetoothAdvertisementData.elementAt(1);
              radonDaily = bluetoothAdvertisementData.elementAt(5);
              currentAvgValue = bluetoothAdvertisementData.elementAt(5);
              radonEver = bluetoothAdvertisementData.elementAt(9);
              deviceFound = true;
              FlutterBluePlus.stopScan();
              subscription!.cancel();
              btDevice = r.device;
              try{
                await btDevice!.connect();
              }catch(e){
                setState(() {

                });
                return;
              }
              try{
                if (Platform.isAndroid) {
                  await r.device.requestMtu(300);
                }
                bool loginSuccessful = false;
                List<BluetoothService> services = await r.device.discoverServices();
                for (var service in services){
                  for(var characteristic in service.characteristics){
                    if(characteristic.properties.notify){
                      await characteristic.setNotifyValue(true);
                      readCharacteristic = characteristic;
                      subscriptionToDevice = readCharacteristic!.lastValueStream.timeout(
                          Duration(seconds: 2),
                          onTimeout: (list)async{
                            bool hasData = false;
                            if(currentBtTimestampCount != -1){
                              radonHistoryTimestamps = radonHistoryTimestamps.reversed.toList();
                              chartSpots = getCurrentSpots();
                              chartBars = getCurrentBars();
                              List<int> barSizes = [];
                              chartBars.forEach((bar) {
                                barSizes.add(bar.barRods.first.toY.toInt());
                              });
                              currentMaxAvgValue = ((barSizes.reduce(max) / 100).ceil()) * 100;
                              BtTimestampCount = -1;
                              currentBtTimestampCount = -1;
                              hasData = true;
                            }
                            await btDevice!.disconnect(timeout: 1);
                            btDevice!.removeBond();
                            subscriptionToDevice?.cancel();
                            loaded = true;
                            setState(() {
                              screenIndex = 1;
                            });
                            if(!hasData){
                              Fluttertoast.showToast(
                                  msg: "Connection Lost"
                              );
                            }
                          }
                      ).listen((data) async{
                        String message = utf8.decode(data).trim();
                        //logger.d(utf8.decode(data));
                        if(message == "" && !loginSuccessful){
                        }
                        if(message == 'LOGIN OK'){
                          loginSuccessful = true;
                          await writeCharacteristic!.write(utf8.encode('ValsRead'));
                          await Future<void>.delayed( const Duration(milliseconds: 200));
                          if(useBtGraph){
                            readGraph = true;
                            await writeCharacteristic!.write(utf8.encode('READGRAPH'));
                            useBtGraph = false;
                          }else{
                            chartSpots = getCurrentSpots();
                            chartBars = getCurrentBars();
                            List<int> barSizes = [];
                            chartBars.forEach((bar) {
                              barSizes.add(bar.barRods.first.toY.toInt());
                            });
                            currentAvgValue = bluetoothAdvertisementData.elementAt(5);
                            await btDevice!.disconnect(timeout: 1);
                            btDevice!.removeBond();
                            subscriptionToDevice?.cancel();
                            loaded = true;
                            setState(() {
                              screenIndex = 1;
                            });
                          }
                        }
                        if(message.contains("{ts-")){
                          BtTimestampCount = int.parse(message.substring(4, message.length-1));
                        }
                        if(message.length >= 2 && message.substring(0,2)=="|A"){
                          if(message.substring(2,4) == "01")  d_unit = int.parse(message.substring(4,message.length-1));
                          if(message.substring(2,4) == "02")  d_led_t = message.substring(4,message.length-1) == "1";
                          if(message.substring(2,4) == "03")  d_led_f = message.substring(4,message.length-1) == "1";
                          if(message.substring(2,4) == "04")  d_led_fb = double.parse(message.substring(4,message.length-1));
                          if(message.substring(2,4) == "05")  d_led_tb = double.parse(message.substring(4,message.length-1));
                          if(message.substring(2,4) == "03")  currentWifiName = message.substring(4,message.length-1);
                        }
                        if(readGraph &&BtTimestampCount>0){
                          var bluetoothRadonHistory = message.split(";");
                          for (var timestamp in bluetoothRadonHistory) {
                            currentBtTimestampCount++;
                            try{
                              String dateString = timestamp.split(" ")[0];
                              int year = int.parse(dateString.split(".")[0])+2000;
                              int month = int.parse(dateString.split(".")[1]);
                              int day = int.parse(dateString.split(".")[2]);
                              int hour = int.parse(timestamp.split(" ")[1].split(",")[0]);
                              int radon = int.parse(timestamp.split(" ")[1].split(",")[1]);
                              Tuple2<int,int> singleTimestamp = Tuple2<int,int> (DateTime(year,month,day,hour).millisecondsSinceEpoch, unit == "Bq/m³" ? radon : radon*27);
                              radonHistoryTimestamps.add(singleTimestamp);
                            }catch(e){
                            }
                          }
                          setState(() {
                          });
                          currentBtTimestampCount--;
                          if((BtTimestampCount == currentBtTimestampCount+1) && (BtTimestampCount != -1)){
                            radonHistoryTimestamps = radonHistoryTimestamps.reversed.toList();
                            chartSpots = getCurrentSpots();
                            chartBars = getCurrentBars();
                            List<int> barSizes = [];
                            chartBars.forEach((bar) {
                              barSizes.add(bar.barRods.first.toY.toInt());
                            });
                            currentMaxAvgValue = ((barSizes.reduce(max) / 100).ceil()) * 100;
                            await btDevice!.disconnect(timeout: 1);
                            btDevice!.removeBond();
                            subscriptionToDevice?.cancel();
                            loaded = true;
                            BtTimestampCount = -1;
                            currentBtTimestampCount = -1;
                            setState(() {
                              screenIndex = 1;
                            });
                          }
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
              }catch(e){
                chartSpots = getCurrentSpots();
                chartBars = getCurrentBars();
                List<int> barSizes = [];
                chartBars.forEach((bar) {
                  barSizes.add(bar.barRods.first.toY.toInt());
                });
                currentAvgValue = bluetoothAdvertisementData.elementAt(5);
                Navigator.pop(context);
                await btDevice!.disconnect(timeout: 1);
                btDevice!.removeBond();
                subscriptionToDevice?.cancel();
                loaded = true;
                Fluttertoast.showToast(
                    msg: "Connection Error"
                );
                setState(() {
                  screenIndex = 1;
                });
              }
            }
          }
        }
      }
    });
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 3));
    await Future<void>.delayed( const Duration(seconds: 3));
    if(!deviceFound){
      subscription!.cancel();
      Navigator.pop(context);
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.deviceNotFound
      );
    }
  }

  changeLocationScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: (){
            setState(() {
              screenIndex = 2;
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              ),
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
                        changeLocation();
                      },
                      style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50)),
                      child: Text(AppLocalizations.of(context)!.apply,style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ]
        ),
      ),
    );
  }

  changeLocation() async{
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
      dio.post('https://dashboard.livair.io/api/plugins/telemetry/${device.keys.first}/SHARED_SCOPE',data: {
        "location": deviceLocationController.text
      });
    }catch(e){
      setState(() {
        Navigator.pop(context);
      });
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.failedNewLocationM
      );
      return;
    }
    setState(() {
      screenIndex = 1;
    });
    Fluttertoast.showToast(
        msg: AppLocalizations.of(context)!.successNewLocationM
    );
  }

  deviceModifyHistoryScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                try{
                  subscriptionToDevice!.cancel();
                  btDevice!.disconnect(timeout: 1);
                  btDevice!.removeBond();
                }catch(e){
                }
                setState(() {
                  screenIndex = 2;
                });
              },
            ),
            Text("MODIFY HISTORY",style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
          ],
        ),
      ),
      body: Column(
        children: [

        ],
      )
    );
  }

  postTimeseries() async{
    Map<String,dynamic> newTimeseries = {};
    radonHistoryTimestamps.forEach((element){


    });
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
      dio.post('https://dashboard.livair.io/api/plugins/telemetry/DEVICE/${device.keys.first}/SHARED_SCOPE',data: {

      });
    }catch(e){
      setState(() {
        Navigator.pop(context);
      });
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.failedNewLocationM
      );
      return;
    }
    setState(() {
      screenIndex = 1;
    });
    Fluttertoast.showToast(
        msg: AppLocalizations.of(context)!.successNewLocationM
    );
  }


  dataExportScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                setState(() {
                  screenIndex = 1;
                });
              },
            ),
            Text(AppLocalizations.of(context)!.exportDataT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
          ],
        ),
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),

      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 10,
                ),
                Text(AppLocalizations.of(context)!.exportDialog, style: const TextStyle(fontSize: 18),),
                const SizedBox(
                  height: 30,
                ),
                Text(AppLocalizations.of(context)!.timeFrame, style: const TextStyle(fontSize: 14),),
                const SizedBox(
                  height: 8,
                ),
                SizedBox(
                  height: 35,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Container(
                        height: 30,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                          child: OutlinedButton(
                            onPressed: (){
                              setState((){
                                customTimeseriesSelected = false;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)
                                ),
                                side: const BorderSide(width: 2,color: Color(0xff0099f0)),
                                foregroundColor: Colors.black,
                                backgroundColor: customTimeseriesSelected ? Colors.white : const Color(0xff0099f0),
                                minimumSize: const Size(60,20)
                            ),
                            child: Text(AppLocalizations.of(context)!.allData,style: TextStyle(
                                color: customTimeseriesSelected ? const Color(0xff0099f0) : Colors.white
                            ),),
                          ),
                        ),
                      ),
                      Container(
                        height: 30,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                          child: OutlinedButton(
                            onPressed: (){
                              setState((){
                                customTimeseriesSelected = true;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)
                                ),
                                side: const BorderSide(width: 2,color: Color(0xff0099f0)),
                                foregroundColor: Colors.black,
                                backgroundColor: customTimeseriesSelected ? const Color(0xff0099f0) : Colors.white ,
                                minimumSize: const Size(60,20)
                            ),
                            child: Text(AppLocalizations.of(context)!.custom,style: TextStyle(
                                color: customTimeseriesSelected ? Colors.white : const Color(0xff0099f0)
                            ),),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20,),
                Text(
                  AppLocalizations.of(context)!.timePeriod,
                  style: const TextStyle(
                      fontSize: 14
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        DateTime? newDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().subtract(Duration(milliseconds: radonHistoryTimestamps != [] ? radonHistoryTimestamps.first.item1 : 0)),
                            lastDate: DateTime.now()
                        );

                        if(newDate == null) return;

                        setState(() => customTimeseriesStart = newDate);
                      },
                      style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(width: 1,color: Color(0xffECEFF1))),
                      child: Text("${AppLocalizations.of(context)!.from} ${DateFormat('yyyy-MM-dd').format(customTimeseriesStart)}", style: TextStyle(color: const Color(0xff0099f0)),),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        DateTime? newDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().subtract(Duration(milliseconds: radonHistoryTimestamps != [] ? radonHistoryTimestamps.first.item1 : 0)),
                            lastDate: DateTime.now()
                        );

                        if(newDate == null) return;
                        if(newDate.year == DateTime.now().year && newDate.month == DateTime.now().month && newDate.day == DateTime.now().day) {
                          setState(() => customTimeseriesEnd = DateTime.now());
                          return;
                        }
                        setState(() => customTimeseriesEnd = newDate);
                      },
                      style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(width: 1,color: Color(0xffECEFF1))),
                      child: Text("${AppLocalizations.of(context)!.until} ${DateFormat('yyyy-MM-dd').format(customTimeseriesEnd)}", style: TextStyle(color: const Color(0xff0099f0)),),
                    ),
                  ],
                )
              ],
            ),
            Column(
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
                          exportData();
                        },
                        style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50)),
                        child: Text(AppLocalizations.of(context)!.export,style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15,),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: saveData,
                        style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50),side: const BorderSide(color: Color(0xff0099f0))),
                        child: Text(AppLocalizations.of(context)!.saveToDownloads,style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  exportData() async{
    final path = await _localPath;
    File file = File('$path/Device_details.txt');
    file.writeAsString("\ndevice name   timestamp   radon");
    for (var element in radonHistoryTimestamps) {
      if(DateTime.fromMillisecondsSinceEpoch(element.item1).compareTo(customTimeseriesStart) >= 0){
        if(DateTime.fromMillisecondsSinceEpoch(element.item1).compareTo(customTimeseriesEnd) <= 0){
          await file.writeAsString("\n${device.values.first.name}   ${DateFormat('yyyy-MM-dd hh:mm').format(DateTime.fromMillisecondsSinceEpoch(element.item1))}   ${element.item2}",mode: FileMode.append);
        }
      }
    }

    final result = await Share.shareXFiles([XFile('$path/Device_details.txt')], text: "Shared with LivAir App");
    if(result.status == ShareResultStatus.success){
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.successExportShareM
      );
    }
  }

  saveData () async{
    File file = File('/storage/emulated/0/Download/Device_details.txt');
    await file.writeAsString("\ndevice name   timestamp   radon");
    for (var element in radonHistoryTimestamps) {
      if(DateTime.fromMillisecondsSinceEpoch(element.item1).compareTo(customTimeseriesStart) >= 0){
        if(DateTime.fromMillisecondsSinceEpoch(element.item1).compareTo(customTimeseriesEnd) <= 0){
          await file.writeAsString("\n${device.values.first.name}   ${DateFormat('yyyy-MM-dd hh:mm').format(DateTime.fromMillisecondsSinceEpoch(element.item1))}   ${element.item2}",mode: FileMode.append);
        }
      }
    }
    Fluttertoast.showToast(
        msg: AppLocalizations.of(context)!.successSavedM
    );
  }

  renameDevice () async{
    try{ dio.options.headers['content-Type'] = 'application/json';
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
      await dio.post('https://dashboard.livair.io/api/livAir/renameDevice/${device.keys.first}/${renameController.text}',);
    }on DioException catch(e){
      setState(() {
        Navigator.pop(context);
      });
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.failedRenameM
      );
    }
    Navigator.pop(context);
    setState(() {
      device.values.first.label = renameController.text;
      screenIndex = 1;
    });
    Fluttertoast.showToast(
        msg: AppLocalizations.of(context)!.successRenameM
    );
  }

  renameDeviceDialog () async{
    renameController.text = device.values.first.label!;
    await Future.delayed(const Duration(milliseconds: 100));
    AlertDialog alert = AlertDialog(
      title: Text(AppLocalizations.of(context)!.rename, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: renameController,
            decoration: InputDecoration(
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
              ),
              fillColor: Colors.white,
              filled: true,

              hintText: "${device.values.first.label}",
              hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
            ),
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
                    renameDevice();
                  },
                  style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50)),
                  child: Text(AppLocalizations.of(context)!.rename,style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10,),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50)),
                  child: Text(AppLocalizations.of(context)!.cancel,style: const TextStyle(color: Colors.black)),
                ),
              ),
            ],
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
  }
  
  shareDeviceScreen(){
    return FutureBuilder(
      future: getViewers(), 
        builder: (context,snapshot){
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                setState(() {
                  screenIndex = 1;
                });
              },
            ),
            backgroundColor: Colors.white,
            titleSpacing: 0,
            iconTheme: const IconThemeData(
              color: Colors.black,
            ),
            title: Text(AppLocalizations.of(context)!.manageUsersT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
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
                      screenIndex = 7;
                    });
                  },
                  color: const Color(0xff0099f0),
                  icon: const Icon(MaterialSymbols.add)
              ),
            ],
          ),
          body: viewerData.isEmpty ?
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const ImageIcon(AssetImage('lib/images/users.png'),size: 55,),
                  const SizedBox(height: 15,),
                  Text(AppLocalizations.of(context)!.noUsersYet,style: const TextStyle(fontSize: 20),),
                  const SizedBox(height: 5,),
                  Text(AppLocalizations.of(context)!.addUserDialog,style: const TextStyle(fontSize: 16),textAlign: TextAlign.center,),
                  const SizedBox(height: 30,),
                  OutlinedButton(
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
                        screenIndex = 7;
                      });
                    },
                    style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0)),
                    child: Text(AppLocalizations.of(context)!.addUser,style: const TextStyle(color: Colors.white),),
                  )
                ],
              ),
            ),
          ):
          Column(
            children: [
              Expanded(
                child: ListView.separated(
                    itemBuilder: (BuildContext context, int index){
                      return GestureDetector(
                        onTap: (){

                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Container(
                            height: 80,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("${viewerData.elementAt(index).values.elementAt(0)}",style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),),
                                viewerData.elementAt(index).values.elementAt(1) == true ?
                                SizedBox(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xffA5E658)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Text(AppLocalizations.of(context)!.active,style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xffA5E658),))
                                    ),
                                  )
                                ) :
                                SizedBox(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.grey),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Text(AppLocalizations.of(context)!.pendingInvite,style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                                      ),
                                    )
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
                                      emailToRemove = viewerData.elementAt(index).values.elementAt(0);
                                      removeViewerDialog();
                                    },
                                    icon: const ImageIcon(AssetImage('lib/images/TrashbinButton.png'))
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const SizedBox(height: 1),
                    itemCount: viewerData.length,
                ),
              )
            ],
          ),
        );
        },
    );
  }

  addViewerScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: (){
            setState(() {
              screenIndex = 6;
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
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black
                      ),
                      children: <TextSpan>[
                        TextSpan(text: AppLocalizations.of(context)!.addViewerDialog1),
                        TextSpan(text: "${device.values.first.label}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: AppLocalizations.of(context)!.addViewerDialog2)
                      ]
                  ),
                ),
                const SizedBox(height: 36,),
                Text(AppLocalizations.of(context)!.inviteViewer),
                const SizedBox(height: 36,),
                TextField(
                  textAlign: TextAlign.start,
                  controller: emailController,
                  decoration: InputDecoration(
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    hintText: AppLocalizations.of(context)!.email,
                    hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36,),
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
                        isValidEmail() == true ? sendShareInvite() : null;
                      },
                      style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50)),
                      child: Text(AppLocalizations.of(context)!.invite, style: const TextStyle(color: Colors.white),)
                  ),
                ),
              ],
            )
          ]
          ),

      ),
    );
  }

  sendShareInvite() async {
    if(!isValidEmail())return;
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
      await dio.post(
          'https://dashboard.livair.io/api/livAir/share',
        data: jsonEncode(
            {
              "deviceIds": [device.keys.elementAt(0)],
              "email": emailController.text
            }
        )
      );
    }on DioException catch (e){
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.failedSendData
      );
    }
    setState(() {
      screenIndex = 6;
    });
  }

  getViewers() async {
    Response response;
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
      response = await dio.get(
          'https://dashboard.livair.io/api/livAir/viewers/${device.keys.elementAt(0)}',
      );
      viewerData = response.data;
    }catch(e){
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.failedLoadData
      );
    }
  }

  removeViewerDialog(){
    AlertDialog alert = AlertDialog(
      title: Text(AppLocalizations.of(context)!.removeUserFromDevs, style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20),),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.removeUserDialog,
            style: const TextStyle(fontSize: 14),
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
                    removeViewer();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50)),
                  child: Text(AppLocalizations.of(context)!.removeUser,style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10,),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white,minimumSize: Size(100, 50)),
                  child: Text(AppLocalizations.of(context)!.cancel,style: const TextStyle(color: Colors.black)),
                ),
              ),
            ],
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
  }

  removeViewer() async{
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";
    Response response;
    try{
      await dio.delete(
        'https://dashboard.livair.io/api/livAir/unshare',
        data: jsonEncode({
          "deviceIds": [device.keys.first],
          "email": emailToRemove
        })
      );
    }on DioError catch(e){
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.failedLoadData
      );
    }
    emailToRemove = "";
    setState(() {

    });
  }

  showSelectThresholdScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
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
        title: Text(AppLocalizations.of(context)!.selectThresholdT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
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
                  controller: thresHoldController,
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
                Text("${AppLocalizations.of(context)!.selectThresholdDialog2} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"},${AppLocalizations.of(context)!.selectThresholdDialog3}"
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: (){
                        setState(() {
                          screenIndex = 81;
                        });
                      },
                      style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50)),
                      child: Text(AppLocalizations.of(context)!.selectThreshold,style: const TextStyle(color: Colors.white),)
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }

  showSelectDurationScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
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
        title: Text(AppLocalizations.of(context)!.selectDurationT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
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
                const SizedBox(width: 20,),
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
                        setState(() {
                          updateWarning();
                          screenIndex = 1;
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
              "deviceId": device.keys.first,
              "radonUpperThreshold": int.parse(thresHoldController.text),
              "radonAlarmDuration": selectedHours*60+selectedMinutes
            }
        ),
      );
    }catch(e){
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.failedSendData
      );
    }
    selectedMinutes = 0;
    selectedHours = 0;
    thresHoldController.text = "";
    await Future<void>.delayed( const Duration(seconds: 1));
    setState(() {

    });
  }

  showDeviceInfoScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                setState(() {
                  screenIndex = 1;
                });
              },
            ),
            Text(AppLocalizations.of(context)!.deviceInfoT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.deviceId),
            const SizedBox(height: 10,),
            Text(device.values.first.name, style: const TextStyle(fontWeight: FontWeight.w600),),
            const SizedBox(height: 20,),
            Text(AppLocalizations.of(context)!.firmwareVersion),
            const SizedBox(height: 10,),
            Text(firmwareVersion, style: const TextStyle(fontWeight: FontWeight.w600),),
            const SizedBox(height: 20,),
            Text(AppLocalizations.of(context)!.calibrationDate),
            const SizedBox(height: 10,),
            Text(DateTime.fromMillisecondsSinceEpoch(calibrationDate).toIso8601String().split("T").first, style: const TextStyle(fontWeight: FontWeight.w600),),
            const SizedBox(height: 20,),
            device.values.elementAt(0).floor != "viewer" ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Internet IP"),
                const SizedBox(height: 10,),
                Text("$deviceInternetIP", style: const TextStyle(fontWeight: FontWeight.w600),),
                const SizedBox(height: 20,),
                Text(AppLocalizations.of(context)!.currentWifi),
                const SizedBox(height: 10,),
                Text(currentWifiName, style: const TextStyle(fontWeight: FontWeight.w600),),
                const SizedBox(height: 20,),
                Text("Webserver"),
                const SizedBox(height: 10,),
                TextButton(
                    onPressed: () async {
                      final Uri url = Uri.parse('http://${device.values.first.name}.local');
                      if (!await launchUrl(url, webViewConfiguration: WebViewConfiguration())) {
                        Fluttertoast.showToast(
                            msg: "Error"
                        );
                      }
                    },
                    child: Text('http://${device.values.first.name}.local',style: TextStyle(color: Colors.black),)),
                const SizedBox(height: 10,),
                TextButton(
                    onPressed: () async {
                      final Uri url = Uri.parse('http://${device.values.first.name}.local/xml');
                      if (!await launchUrl(url)) {
                        Fluttertoast.showToast(
                            msg: "Error"
                        );
                      }
                    },
                    child: Text('http://${device.values.first.name}.local/xml',style: TextStyle(color: Colors.black),)),
                const SizedBox(height: 10,),
                TextButton(
                    onPressed: () async {
                      final Uri url = Uri.parse('http://${device.values.first.name}.local/json');
                      if (!await launchUrl(url)) {
                        Fluttertoast.showToast(
                            msg: "Error"
                        );
                      }
                    },
                    child: Text('http://${device.values.first.name}.local/json',style: TextStyle(color: Colors.black),)),
              ],
            )
            : SizedBox(),
          ],
        ),
      ),
    );
  }

  identifyDevice() async{
    await Future<void>.delayed( const Duration(milliseconds: 100));
    AlertDialog alert = AlertDialog(
      title: Text(AppLocalizations.of(context)!.identifying, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.identifyingDialog)
        ],
      ),
    );
    showDialog(
      context: context,
      builder: (BuildContext context){
        return alert;
      },
    );
    String id = device.keys.elementAt(0);
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
      dio.post('https://dashboard.livair.io/api/plugins/telemetry/DEVICE/$id/SHARED_SCOPE',
        data: jsonEncode(
            {
              "u_identify": 1,
            }
        ),
      );
      await Future<void>.delayed( const Duration(seconds: 10));
      dio.post('https://dashboard.livair.io/api/plugins/telemetry/DEVICE/$id/SHARED_SCOPE',
        data: jsonEncode(
            {
              "u_identify": 0,
            }
        ),
      );
      Navigator.pop(context);
    }catch(e){
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.failedSendData
      );
    }
    telemetryRunning = false;
  }

  deleteDevice() async {
    await Future<void>.delayed( const Duration(milliseconds: 100));
    AlertDialog alert = AlertDialog(
      title: Text(AppLocalizations.of(context)!.deleteDev, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.deleteDevDialog),
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
                      String id = device.keys.elementAt(0);
                      dio.options.headers['content-Type'] = 'application/json';
                      dio.options.headers['Accept'] = "application/json";
                      dio.options.headers['Authorization'] = "Bearer $token";
                      await dio.delete("https://dashboard.livair.io/api/livAir/unclaim/$id");
                      await Future<void>.delayed( const Duration(milliseconds: 100));
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50),side: const BorderSide(color: Color(0xff0099f0))),
                    child: Text(AppLocalizations.of(context)!.deleteDev,style: const TextStyle(color: Colors.white),)
                ),
              ),

            ],
          ),
          const SizedBox(height: 10,),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: ()=> setState(() {
                      Navigator.pop(context);
                    }),
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
  }

  stopViewingDialog() async{
    AlertDialog alert = AlertDialog(
      title: Text(AppLocalizations.of(context)!.stopViewing, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.stopViewingM),
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
                    try{
                      dio.options.headers['content-Type'] = 'application/json';
                      dio.options.headers['Accept'] = "application/json";
                      dio.options.headers['Authorization'] = "Bearer $token";
                      await dio.delete("https://dashboard.livair.io/api/livAir/stopViewing",
                          data:
                          {
                            "deviceIds": [device.keys.first]
                          }
                      );
                    }on DioException catch(e){
                      Fluttertoast.showToast(
                          msg: "Error"
                      );
                    }
                    Navigator.pop(context);
                    Navigator.pop(context);
                    setState(() {

                    });
                  },
                  style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50),side: const BorderSide(color: Color(0xff0099f0))),
                  child: Text(AppLocalizations.of(context)!.stopViewing,style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10,),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white,minimumSize: const Size(100, 50),side: const BorderSide(color: Color(0xff0099f0))),
                  child: Text(AppLocalizations.of(context)!.cancel,style: const TextStyle(color: Color(0xff0099f0))),
                ),
              ),
            ],
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
  }

  setPage(int index, bool isWide){
    switch(index) {
      case 0: return const Column();
      case 1: return deviceDetailScreen(isWide);
      case 2: return deviceSettingsScreen();
      case 20: return deviceLightsScreen();
      case 211: return deviceWifiScreen();
      case 21: return deviceWifiSelectScreen();
      case 22: return deviceWifiPasswordScreen();
      case 24: return changeLocationScreen();
      case 25: return deviceClockScreen();
      case 26: return deviceKNXScreen();
      case 27: return deviceCloudScreen();
      case 28: return deviceMQTTScreen();
      case 3: return showDeviceInfoScreen();
      case 4: return deviceModifyHistoryScreen();
      case 5: return dataExportScreen();
      case 6: return shareDeviceScreen();
      case 7: return addViewerScreen();
      case 8: return showSelectThresholdScreen();
      case 81: return showSelectDurationScreen();
      default: return;
    }
  }

  bool isValidEmail() {
    return RegExp(
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).orientation != Orientation.landscape;
    return WillPopScope(
        onWillPop: () async{
          if(screenIndex == 1){
            Navigator.of(context).pop();
            return false;
          }
          if(screenIndex == 20 || screenIndex == 21 || screenIndex == 211 || screenIndex == 22 || screenIndex == 24 || screenIndex == 25 || screenIndex == 26 || screenIndex == 27 || screenIndex == 28 ){
            if(screenIndex == 25){
              tzOfSelection = [];
              timezoneCountry = "None selected";
              timezoneCity = "None selected";
            }

            setState(() {
              screenIndex = 2;
            });
            return false;
          }else{
            screenIndex = 1;
            setState(() {

            });
            return false;
          }
        },
        child: useBluetoothData ? FutureBuilder(
            future: readOfflineData(),
            builder: (context, projectSnap){
              return loaded ? setPage(screenIndex, isWide) : Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.loadingOverBT,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 36,),
                      currentBtTimestampCount == -1 ? CircularProgressIndicator(
                        color: Colors.black,
                      ) : Column(
                        children: [
                          SizedBox(
                            width: 300,
                            child: LinearProgressIndicator(
                              value: BtTimestampCount != 0 ? currentBtTimestampCount/BtTimestampCount : 0,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          ),
                          //Text("${currentBtTimestampCount} / ${BtTimestampCount}")
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
        ) :  FutureBuilder(
          future: futureFunc(),
          builder: (context, projectSnap){
            return loadedInternet ? setPage(screenIndex, isWide)  : Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.loadingData,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 36,),
                    CircularProgressIndicator(
                      color: Colors.black,
                    )
                  ],
                ),
              ),
            );
          },
        )
    );
  }

  Map<String,String> getTZMap(){
    return {
      "Africa/Abidjan":"GMT0",
      "Africa/Accra":"GMT0",
      "Africa/Addis_Ababa":"EAT-3",
      "Africa/Algiers":"CET-1",
      "Africa/Asmara":"EAT-3",
      "Africa/Bamako":"GMT0",
      "Africa/Bangui":"WAT-1",
      "Africa/Banjul":"GMT0",
      "Africa/Bissau":"GMT0",
      "Africa/Blantyre":"CAT-2",
      "Africa/Brazzaville":"WAT-1",
      "Africa/Bujumbura":"CAT-2",
      "Africa/Cairo":"EET-2EEST,M4.5.5/0,M10.5.4/24",
      "Africa/Casablanca":"<+01>-1",
      "Africa/Ceuta":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Africa/Conakry":"GMT0",
      "Africa/Dakar":"GMT0",
      "Africa/Dar_es_Salaam":"EAT-3",
      "Africa/Djibouti":"EAT-3",
      "Africa/Douala":"WAT-1",
      "Africa/El_Aaiun":"<+01>-1",
      "Africa/Freetown":"GMT0",
      "Africa/Gaborone":"CAT-2",
      "Africa/Harare":"CAT-2",
      "Africa/Johannesburg":"SAST-2",
      "Africa/Juba":"CAT-2",
      "Africa/Kampala":"EAT-3",
      "Africa/Khartoum":"CAT-2",
      "Africa/Kigali":"CAT-2",
      "Africa/Kinshasa":"WAT-1",
      "Africa/Lagos":"WAT-1",
      "Africa/Libreville":"WAT-1",
      "Africa/Lome":"GMT0",
      "Africa/Luanda":"WAT-1",
      "Africa/Lubumbashi":"CAT-2",
      "Africa/Lusaka":"CAT-2",
      "Africa/Malabo":"WAT-1",
      "Africa/Maputo":"CAT-2",
      "Africa/Maseru":"SAST-2",
      "Africa/Mbabane":"SAST-2",
      "Africa/Mogadishu":"EAT-3",
      "Africa/Monrovia":"GMT0",
      "Africa/Nairobi":"EAT-3",
      "Africa/Ndjamena":"WAT-1",
      "Africa/Niamey":"WAT-1",
      "Africa/Nouakchott":"GMT0",
      "Africa/Ouagadougou":"GMT0",
      "Africa/Porto-Novo":"WAT-1",
      "Africa/Sao_Tome":"GMT0",
      "Africa/Tripoli":"EET-2",
      "Africa/Tunis":"CET-1",
      "Africa/Windhoek":"CAT-2",
      "America/Adak":"HST10HDT,M3.2.0,M11.1.0",
      "America/Anchorage":"AKST9AKDT,M3.2.0,M11.1.0",
      "America/Anguilla":"AST4",
      "America/Antigua":"AST4",
      "America/Araguaina":"<-03>3",
      "America/Argentina/Buenos_Aires":"<-03>3",
      "America/Argentina/Catamarca":"<-03>3",
      "America/Argentina/Cordoba":"<-03>3",
      "America/Argentina/Jujuy":"<-03>3",
      "America/Argentina/La_Rioja":"<-03>3",
      "America/Argentina/Mendoza":"<-03>3",
      "America/Argentina/Rio_Gallegos":"<-03>3",
      "America/Argentina/Salta":"<-03>3",
      "America/Argentina/San_Juan":"<-03>3",
      "America/Argentina/San_Luis":"<-03>3",
      "America/Argentina/Tucuman":"<-03>3",
      "America/Argentina/Ushuaia":"<-03>3",
      "America/Aruba":"AST4",
      "America/Asuncion":"<-04>4<-03>,M10.1.0/0,M3.4.0/0",
      "America/Atikokan":"EST5",
      "America/Bahia":"<-03>3",
      "America/Bahia_Banderas":"CST6",
      "America/Barbados":"AST4",
      "America/Belem":"<-03>3",
      "America/Belize":"CST6",
      "America/Blanc-Sablon":"AST4",
      "America/Boa_Vista":"<-04>4",
      "America/Bogota":"<-05>5",
      "America/Boise":"MST7MDT,M3.2.0,M11.1.0",
      "America/Cambridge_Bay":"MST7MDT,M3.2.0,M11.1.0",
      "America/Campo_Grande":"<-04>4",
      "America/Cancun":"EST5",
      "America/Caracas":"<-04>4",
      "America/Cayenne":"<-03>3",
      "America/Cayman":"EST5",
      "America/Chicago":"CST6CDT,M3.2.0,M11.1.0",
      "America/Chihuahua":"CST6",
      "America/Costa_Rica":"CST6",
      "America/Creston":"MST7",
      "America/Cuiaba":"<-04>4",
      "America/Curacao":"AST4",
      "America/Danmarkshavn":"GMT0",
      "America/Dawson":"MST7",
      "America/Dawson_Creek":"MST7",
      "America/Denver":"MST7MDT,M3.2.0,M11.1.0",
      "America/Detroit":"EST5EDT,M3.2.0,M11.1.0",
      "America/Dominica":"AST4",
      "America/Edmonton":"MST7MDT,M3.2.0,M11.1.0",
      "America/Eirunepe":"<-05>5",
      "America/El_Salvador":"CST6",
      "America/Fortaleza":"<-03>3",
      "America/Fort_Nelson":"MST7",
      "America/Glace_Bay":"AST4ADT,M3.2.0,M11.1.0",
      "America/Godthab":"<-02>2<-01>,M3.5.0/-1,M10.5.0/0",
      "America/Goose_Bay":"AST4ADT,M3.2.0,M11.1.0",
      "America/Grand_Turk":"EST5EDT,M3.2.0,M11.1.0",
      "America/Grenada":"AST4",
      "America/Guadeloupe":"AST4",
      "America/Guatemala":"CST6",
      "America/Guayaquil":"<-05>5",
      "America/Guyana":"<-04>4",
      "America/Halifax":"AST4ADT,M3.2.0,M11.1.0",
      "America/Havana":"CST5CDT,M3.2.0/0,M11.1.0/1",
      "America/Hermosillo":"MST7",
      "America/Indiana/Indianapolis":"EST5EDT,M3.2.0,M11.1.0",
      "America/Indiana/Knox":"CST6CDT,M3.2.0,M11.1.0",
      "America/Indiana/Marengo":"EST5EDT,M3.2.0,M11.1.0",
      "America/Indiana/Petersburg":"EST5EDT,M3.2.0,M11.1.0",
      "America/Indiana/Tell_City":"CST6CDT,M3.2.0,M11.1.0",
      "America/Indiana/Vevay":"EST5EDT,M3.2.0,M11.1.0",
      "America/Indiana/Vincennes":"EST5EDT,M3.2.0,M11.1.0",
      "America/Indiana/Winamac":"EST5EDT,M3.2.0,M11.1.0",
      "America/Inuvik":"MST7MDT,M3.2.0,M11.1.0",
      "America/Iqaluit":"EST5EDT,M3.2.0,M11.1.0",
      "America/Jamaica":"EST5",
      "America/Juneau":"AKST9AKDT,M3.2.0,M11.1.0",
      "America/Kentucky/Louisville":"EST5EDT,M3.2.0,M11.1.0",
      "America/Kentucky/Monticello":"EST5EDT,M3.2.0,M11.1.0",
      "America/Kralendijk":"AST4",
      "America/La_Paz":"<-04>4",
      "America/Lima":"<-05>5",
      "America/Los_Angeles":"PST8PDT,M3.2.0,M11.1.0",
      "America/Lower_Princes":"AST4",
      "America/Maceio":"<-03>3",
      "America/Managua":"CST6",
      "America/Manaus":"<-04>4",
      "America/Marigot":"AST4",
      "America/Martinique":"AST4",
      "America/Matamoros":"CST6CDT,M3.2.0,M11.1.0",
      "America/Mazatlan":"MST7",
      "America/Menominee":"CST6CDT,M3.2.0,M11.1.0",
      "America/Merida":"CST6",
      "America/Metlakatla":"AKST9AKDT,M3.2.0,M11.1.0",
      "America/Mexico_City":"CST6",
      "America/Miquelon":"<-03>3<-02>,M3.2.0,M11.1.0",
      "America/Moncton":"AST4ADT,M3.2.0,M11.1.0",
      "America/Monterrey":"CST6",
      "America/Montevideo":"<-03>3",
      "America/Montreal":"EST5EDT,M3.2.0,M11.1.0",
      "America/Montserrat":"AST4",
      "America/Nassau":"EST5EDT,M3.2.0,M11.1.0",
      "America/New_York":"EST5EDT,M3.2.0,M11.1.0",
      "America/Nipigon":"EST5EDT,M3.2.0,M11.1.0",
      "America/Nome":"AKST9AKDT,M3.2.0,M11.1.0",
      "America/Noronha":"<-02>2",
      "America/North_Dakota/Center":"CST6CDT,M3.2.0,M11.1.0",
      "America/Nuuk":"<-02>2<-01>,M3.5.0/-1,M10.5.0/0",
      "America/Ojinaga":"CST6CDT,M3.2.0,M11.1.0",
      "America/Panama":"EST5",
      "America/Pangnirtung":"EST5EDT,M3.2.0,M11.1.0",
      "America/Paramaribo":"<-03>3",
      "America/Phoenix":"MST7",
      "America/Port-au-Prince":"EST5EDT,M3.2.0,M11.1.0",
      "America/Port_of_Spain":"AST4",
      "America/Porto_Velho":"<-04>4",
      "America/Puerto_Rico":"AST4",
      "America/Punta_Arenas":"<-03>3",
      "America/Rainy_River":"CST6CDT,M3.2.0,M11.1.0",
      "America/Rankin_Inlet":"CST6CDT,M3.2.0,M11.1.0",
      "America/Recife":"<-03>3",
      "America/Regina":"CST6",
      "America/Resolute":"CST6CDT,M3.2.0,M11.1.0",
      "America/Rio_Branco":"<-05>5",
      "America/Santarem":"<-03>3",
      "America/Santiago":"<-04>4<-03>,M9.1.6/24,M4.1.6/24",
      "America/Santo_Domingo":"AST4",
      "America/Sao_Paulo":"<-03>3",
      "America/Scoresbysund":"<-02>2<-01>,M3.5.0/-1,M10.5.0/0",
      "America/Sitka":"AKST9AKDT,M3.2.0,M11.1.0",
      "America/St_Barthelemy":"AST4",
      "America/St_Kitts":"AST4",
      "America/St_Lucia":"AST4",
      "America/St_Thomas":"AST4",
      "America/St_Vincent":"AST4",
      "America/Swift_Current":"CST6",
      "America/Tegucigalpa":"CST6",
      "America/Thule":"AST4ADT,M3.2.0,M11.1.0",
      "America/Thunder_Bay":"EST5EDT,M3.2.0,M11.1.0",
      "America/Tijuana":"PST8PDT,M3.2.0,M11.1.0",
      "America/Toronto":"EST5EDT,M3.2.0,M11.1.0",
      "America/Tortola":"AST4",
      "America/Vancouver":"PST8PDT,M3.2.0,M11.1.0",
      "America/Whitehorse":"MST7",
      "America/Winnipeg":"CST6CDT,M3.2.0,M11.1.0",
      "America/Yakutat":"AKST9AKDT:M3.2.0,M11.1.0",
      "America/Yellowknife":"MST7MDT,M3.2.0,M11.1.0",
      "Antarctica/Casey":"<+08>-8",
      "Antarctica/Davis":"<+07>-7",
      "Antarctica/DumontDUrville":"<+10>-10",
      "Antarctica/Macquarie":"AEST-10AEDT,M10.1.0,M4.1.0/3",
      "Antarctica/Mawson":"<+05>-5",
      "Antarctica/Palmer":"<-03>3",
      "Antarctica/Rothera":"<-03>3",
      "Antarctica/Syowa":"<+03>-3",
      "Antarctica/Vostok":"<+05>-5",
      "Asia/Aden":"<+03>-3",
      "Asia/Almaty":"<+05>-5",
      "Asia/Amman":"<+03>-3",
      "Asia/Anadyr":"<+12>-12",
      "Asia/Aqtau":"<+05>-5",
      "Asia/Aqtobe":"<+05>-5",
      "Asia/Ashgabat":"<+05>-5",
      "Asia/Atyrau":"<+05>-5",
      "Asia/Baghdad":"<+03>-3",
      "Asia/Bahrain":"<+03>-3",
      "Asia/Baku":"<+04>-4",
      "Asia/Bangkok":"<+07>-7",
      "Asia/Barnaul":"<+07>-7",
      "Asia/Beirut":"EET-2EEST,M3.5.0/0,M10.5.0/0",
      "Asia/Bishkek":"<+06>-6",
      "Asia/Brunei":"<+08>-8",
      "Asia/Chita":"<+09>-9",
      "Asia/Choibalsan":"<+08>-8",
      "Asia/Colombo":"<+0530>-5,30",
      "Asia/Damascus":"<+03>-3",
      "Asia/Dhaka":"<+06>-6",
      "Asia/Dili":"<+09>-9",
      "Asia/Dubai":"<+04>-4",
      "Asia/Dushanbe":"<+05>-5",
      "Asia/Famagusta":"EET-2EEST,M3.5.0/3,M10.5.0/4",
      "Asia/Gaza":"EET-2EEST,M3.4.4/50,M10.4.4/50",
      "Asia/Hebron":"EET-2EEST,M3.4.4/50,M10.4.4/50",
      "Asia/Ho_Chi_Minh":"<+07>-7",
      "Asia/Hong_Kong":"HKT-8",
      "Asia/Hovd":"<+07>-7",
      "Asia/Irkutsk":"<+08>-8",
      "Asia/Jakarta":"WIB-7",
      "Asia/Jayapura":"WIT-9",
      "Asia/Jerusalem":"IST-2IDT,M3.4.4/26,M10.5.0",
      "Asia/Kabul":"<+0430>-4:30",
      "Asia/Kamchatka":"<+12>-12",
      "Asia/Karachi":"PKT-5",
      "Asia/Kathmandu":"<+0545>-5,45",
      "Asia/Khandyga":"<+09>-9",
      "Asia/Kolkata":"IST-5:30",
      "Asia/Krasnoyarsk":"<+07>-7",
      "Asia/Kuala_Lumpur":"<+08>-8",
      "Asia/Kuching":"<+08>-8",
      "Asia/Kuwait":"<+03>-3",
      "Asia/Macau":"CST-8",
      "Asia/Magadan":"<+11>-11",
      "Asia/Makassar":"WITA-8",
      "Asia/Manila":"PST-8",
      "Asia/Muscat":"<+04>-4",
      "Asia/Nicosia":"EET-2EEST,M3.5.0/3,M10.5.0/4",
      "Asia/Novokuznetsk":"<+07>-7",
      "Asia/Novosibirsk":"<+07>-7",
      "Asia/Omsk":"<+06>-6",
      "Asia/Oral":"<+05>-5",
      "Asia/Phnom_Penh":"<+07>-7",
      "Asia/Pontianak":"WIB-7",
      "Asia/Pyongyang":"KST-9",
      "Asia/Qatar":"<+03>-3",
      "Asia/Qyzylorda":"<+05>-5",
      "Asia/Riyadh":"<+03>-3",
      "Asia/Sakhalin":"<+11>-11",
      "Asia/Samarkand":"<+05>-5",
      "Asia/Seoul":"KST-9",
      "Asia/Shanghai":"CST-8",
      "Asia/Singapore":"<+08>-8",
      "Asia/Srednekolymsk":"<+11>-11",
      "Asia/Taipei":"CST-8",
      "Asia/Tashkent":"<+05>-5",
      "Asia/Tbilisi":"<+04>-4",
      "Asia/Tehran":"<+0330>-3,30",
      "Asia/Thimphu":"<+06>-6",
      "Asia/Tokyo":"JST-9",
      "Asia/Tomsk":"<+07>-7",
      "Asia/Ulaanbaatar":"<+08>-8",
      "Asia/Urumqi":"<+06>-6",
      "Asia/Ust-Nera":"<+10>-10",
      "Asia/Vientiane":"<+07>-7",
      "Asia/Vladivostok":"<+10>-10",
      "Asia/Yakutsk":"<+09>-9",
      "Asia/Yangon":"<+0630>-6,30",
      "Asia/Yekaterinburg":"<+05>-5",
      "Asia/Yerevan":"<+04>-4",
      "Atlantic/Azores":"<-01>1<+00>,M3.5.0/0,M10.5.0/1",
      "Atlantic/Bermuda":"AST4ADT,M3.2.0,M11.1.0",
      "Atlantic/Canary":"WET0WEST,M3.5.0/1,M10.5.0",
      "Atlantic/Cape_Verde":"<-01>1",
      "Atlantic/Faroe":"WET0WEST,M3.5.0/1,M10.5.0",
      "Atlantic/Madeira":"WET0WEST,M3.5.0/1,M10.5.0",
      "Atlantic/Reykjavik":"GMT0",
      "Atlantic/South_Georgia":"<-02>2",
      "Atlantic/Stanley":"<-03>3",
      "Atlantic/St_Helena":"GMT0",
      "Australia/Adelaide":"ACST-9,30ACDT,M10.1.0,M4.1.0/3",
      "Australia/Brisbane":"AEST-10",
      "Australia/Currie":"AEST-10AEDT,M10.1.0,M4.1.0/3",
      "Australia/Darwin":"ACST-9,30",
      "Australia/Eucla":"<+0845>-8,45",
      "Australia/Hobart":"AEST-10AEDT,M10.1.0,M4.1.0/3",
      "Australia/Lindeman":"AEST-10",
      "Australia/Lord_Howe":"<+1030>-10,30<+11>-11,M10.1.0,M4.1.0",
      "Australia/Melbourne":"AEST-10AEDT,M10.1.0,M4.1.0/3",
      "Australia/Perth":"AWST-8",
      "Australia/Sydney":"AEST-10AEDT,M10.1.0,M4.1.0/3",
      "Europe/Amsterdam":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Andorra":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Astrakhan":"<+04>-4",
      "Europe/Athens":"EET-2EEST,M3.5.0/3,M10.5.0/4",
      "Europe/Belgrade":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Berlin":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Bratislava":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Brussels":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Bucharest":"EET-2EEST,M3.5.0/3,M10.5.0/4",
      "Europe/Budapest":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Busingen":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Chisinau":"EET-2EEST,M3.5.0,M10.5.0/3",
      "Europe/Copenhagen":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Dublin":"IST-1GMT0,M10.5.0,M3.5.0/1",
      "Europe/Gibraltar":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Guernsey":"GMT0BST,M3.5.0/1,M10.5.0",
      "Europe/Helsinki":"EET-2EEST,M3.5.0/3,M10.5.0/4",
      "Europe/Isle_of_Man":"GMT0BST,M3.5.0/1,M10.5.0",
      "Europe/Istanbul":"<+03>-3",
      "Europe/Jersey":"GMT0BST,M3.5.0/1,M10.5.0",
      "Europe/Kaliningrad":"EET-2",
      "Europe/Kiev":"EET-2EEST,M3.5.0/3,M10.5.0/4",
      "Europe/Kirov":"MSK-3",
      "Europe/Lisbon":"WET0WEST,M3.5.0/1,M10.5.0",
      "Europe/Ljubljana":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/London":"GMT0BST,M3.5.0/1,M10.5.0",
      "Europe/Luxembourg":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Madrid":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Malta":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Mariehamn":"EET-2EEST,M3.5.0/3,M10.5.0/4",
      "Europe/Minsk":"<+03>-3",
      "Europe/Monaco":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Moscow":"MSK-3",
      "Europe/Oslo":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Paris":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Podgorica":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Prague":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Riga":"EET-2EEST,M3.5.0/3,M10.5.0/4",
      "Europe/Rome":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Samara":"<+04>-4",
      "Europe/San_Marino":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Sarajevo":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Saratov":"<+04>-4",
      "Europe/Simferopol":"MSK-3",
      "Europe/Skopje":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Sofia":"EET-2EEST,M3.5.0/3,M10.5.0/4",
      "Europe/Stockholm":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Tallinn":"EET-2EEST,M3.5.0/3,M10.5.0/4",
      "Europe/Tirane":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Ulyanovsk":"<+04>-4",
      "Europe/Uzhgorod":"EET-2EEST,M3.5.0/3,M10.5.0/4",
      "Europe/Vaduz":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Vatican":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Vienna":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Vilnius":"EET-2EEST,M3.5.0/3,M10.5.0/4",
      "Europe/Volgograd":"MSK-3",
      "Europe/Warsaw":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Zagreb":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Europe/Zaporozhye":"EET-2EEST,M3.5.0/3,M10.5.0/4",
      "Europe/Zurich":"CET-1CEST,M3.5.0,M10.5.0/3",
      "Indian/Antananarivo":"EAT-3",
      "Indian/Chagos":"<+06>-6",
      "Indian/Christmas":"<+07>-7",
      "Indian/Cocos":"<+0630>-6,30",
      "Indian/Comoro":"EAT-3",
      "Indian/Kerguelen":"<+05>-5",
      "Indian/Mahe":"<+04>-4",
      "Indian/Maldives":"<+05>-5",
      "Indian/Mauritius":"<+04>-4",
      "Indian/Mayotte":"EAT-3",
      "Indian/Reunion":"<+04>-4",
      "Pacific/Apia":"<+13>-13",
      "Pacific/Auckland":"NZST-12NZDT,M9.5.0,M4.1.0/3",
      "Pacific/Bougainville":"<+11>-11",
      "Pacific/Chatham":"<+1245>-12,45<+1345>,M9.5.0/2:45,M4.1.0/3:45",
      "Pacific/Chuuk":"<+10>-10",
      "Pacific/Easter":"<-06>6<-05>,M9.1.6/22,M4.1.6/22",
      "Pacific/Efate":"<+11>-11",
      "Pacific/Enderbury":"<+13>-13",
      "Pacific/Fakaofo":"<+13>-13",
      "Pacific/Fiji":"<+12>-12",
      "Pacific/Funafuti":"<+12>-12",
      "Pacific/Galapagos":"<-06>6",
      "Pacific/Gambier":"<-09>9",
      "Pacific/Guadalcanal":"<+11>-11",
      "Pacific/Guam":"ChST-10",
      "Pacific/Honolulu":"HST10",
      "Pacific/Kiritimati":"<+14>-14",
      "Pacific/Kosrae":"<+11>-11",
      "Pacific/Kwajalein":"<+12>-12",
      "Pacific/Majuro":"<+12>-12",
      "Pacific/Marquesas":"<-0930>9,30",
      "Pacific/Midway":"SST11",
      "Pacific/Nauru":"<+12>-12",
      "Pacific/Niue":"<-11>11",
      "Pacific/Noumea":"<+11>-11",
      "Pacific/Pago_Pago":"SST11",
      "Pacific/Palau":"<+09>-9",
      "Pacific/Pitcairn":"<-08>8",
      "Pacific/Pohnpei":"<+11>-11",
      "Pacific/Port_Moresby":"<+10>-10",
      "Pacific/Rarotonga":"<-10>10",
      "Pacific/Saipan":"ChST-10",
      "Pacific/Tahiti":"<-10>10",
      "Pacific/Tarawa":"<+12>-12",
      "Pacific/Tongatapu":"<+13>-13",
      "Pacific/Wake":"<+12>-12",
      "Pacific/Wallis":"<+12>-12",
      "Etc/GMT":"GMT0",
      "Etc/GMT-0":"GMT0",
      "Etc/GMT-1":"<+01>-1",
      "Etc/GMT-2":"<+02>-2",
      "Etc/GMT-3":"<+03>-3",
      "Etc/GMT-4":"<+04>-4",
      "Etc/GMT-5":"<+05>-5",
      "Etc/GMT-6":"<+06>-6",
      "Etc/GMT-7":"<+07>-7",
      "Etc/GMT-8":"<+08>-8",
      "Etc/GMT-9":"<+09>-9",
      "Etc/GMT-10":"<+10>-10",
      "Etc/GMT-11":"<+11>-11",
      "Etc/GMT-12":"<+12>-12",
      "Etc/GMT-13":"<+13>-13",
      "Etc/GMT-14":"<+14>-14",
      "Etc/GMT0":"GMT0",
      "Etc/GMT+0":"GMT0",
      "Etc/GMT+1":"<-01>1",
      "Etc/GMT+2":"<-02>2",
      "Etc/GMT+3":"<-03>3",
      "Etc/GMT+4":"<-04>4",
      "Etc/GMT+5":"<-05>5",
      "Etc/GMT+6":"<-06>6",
      "Etc/GMT+7":"<-07>7",
      "Etc/GMT+8":"<-08>8",
      "Etc/GMT+9":"<-09>9",
      "Etc/GMT+10":"<-10>10",
      "Etc/GMT+11":"<-11>11",
      "Etc/GMT+12":"<-12>12",
      "Etc/UCT":"UTC0",
      "Etc/UTC":"UTC0",
      "Etc/Greenwich":"GMT0",
      "Etc/Universal":"UTC0",
      "Etc/Zulu":"UTC0",
    };
  }



}

class DetailResponse {
  final Map<String, dynamic> data;

  DetailResponse(this.data);

  DetailResponse.fromJson(List<dynamic> json)
      : data = json[0];
}

class Details {
  final String key;
  final String value;
  final String color;
  final String rating;

  Details({
    required this.key,
    required this.value,
    required this.color,
    required this.rating,
  });

  factory Details.fromJson(Map<String, dynamic> json) => Details(
    key: json["key"].toString(),
    value: json["value"].toString(),
    color: json["color"].toString(),
    rating: json["rating"].toString(),
  );
}

class ChartData {
  ChartData(this.x, this.y);
  final DateTime x;
  final double? y;
}

