import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class MyDeviceWidget extends StatelessWidget {
  final String name;
  final Function() onTap;
  bool isOnline;
  final String radonValue;
  final String unit;
  final int lastSync;
  final bool isViewer;
  bool? isBtAvailable;


  MyDeviceWidget({
    super.key,
    required this.onTap,
    required this.name,
    required this.isOnline,
    required this.radonValue,
    required this.unit,
    required this.lastSync,
    required this.isViewer,
    this.isBtAvailable
  });

  setIsOnline(bool onlineStatus){
    this.isOnline = onlineStatus;
  }

  setIsBtAvailable(bool onlineStatus){
    this.isBtAvailable = onlineStatus;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 85,
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xffe5e5e5),width: 1.0),top: BorderSide(color: Color(0xffe5e5e5),width: 1.0))
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width-150,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(
                              name,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 20
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      radonValue != "-1" ? RichText(
                          text: TextSpan(
                              text: (lastSync<3600000 || lastSync == -1) ? radonValue : "0",
                              style: TextStyle(
                                  color: int.parse(radonValue) > 100 ? int.parse(radonValue) > 300 ? const Color(0xfffd4c56) : const Color(0xfffdca03) : const Color(0xff0ace84),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600
                              ),
                              children: [
                                TextSpan(
                                  text: " $unit",
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400
                                  ),
                                )
                              ]
                          )
                      ) : const Text(""),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  isBtAvailable != null ? isBtAvailable! ? (Duration(milliseconds: lastSync).inMinutes<=10) && (lastSync !=-1) ? Row(children: [const Icon(Icons.bluetooth, color: Color(0xff0099F0),),const ImageIcon(AssetImage('lib/images/isOnline.png'),color: Color(0xff0099F0),)],) : const Icon(Icons.bluetooth, color: Color(0xff0099F0),) : const ImageIcon(AssetImage('lib/images/isOnline.png'),color: Color(0xff0099F0),) : ((Duration(milliseconds: lastSync).inMinutes>10) || (lastSync ==-1)) ? const ImageIcon(AssetImage('lib/images/isOnline.png'),color: Color(0xffCFD8DC),) : const ImageIcon(AssetImage('lib/images/isOnline.png'),color: Color(0xff0099F0)),
                  const SizedBox(width: 10),
                  lastSync == -1 ? isViewer ? Text("Status not visible as viewer") : Text("Not synced yet") : lastSync<3600000 ? Text("Last sync: ${Duration(milliseconds: lastSync).inMinutes} ${AppLocalizations.of(context)!.minsAgo}") : lastSync<3600000*3 ? Text("Last sync: ${Duration(milliseconds: lastSync).inHours}h ${Duration(milliseconds: lastSync).inMinutes} ${AppLocalizations.of(context)!.minsAgo}") : lastSync<86400000 ? Text("Last sync: ${Duration(milliseconds: lastSync).inHours} ${AppLocalizations.of(context)!.hoursAgo}") : Text("Last sync: ${Duration(milliseconds: lastSync).inDays} ${AppLocalizations.of(context)!.daysAgo}")
                ]
              ),
            ],
          ),
        ),
      ),
    );
  }
}