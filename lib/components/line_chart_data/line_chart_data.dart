import 'package:intl/intl.dart';

class MyLineChartData {

  String convertMsToDateString(int ms,int days){
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(ms);
    if(days == 1){
      return "${dateTime.hour.toString().padLeft(2,"0")}:${dateTime.minute.toString().padLeft(2,"0")}";
    }
    if(days == 2){
      return "${DateFormat('EEEE').format(dateTime).substring(0,2)} ${dateTime.hour.toString().padLeft(2,"0")}:${dateTime.minute.toString().padLeft(2,"0")}";
    }
    if(days == 21){
      return "${DateFormat('EEEE').format(dateTime).substring(0,2)}\n${dateTime.hour.toString().padLeft(2,"0")}:${dateTime.minute.toString().padLeft(2,"0")}";
    }
    if(days == 7){
      return "${DateFormat('EEEE').format(dateTime).substring(0,2)}";
    }
    if(days == 30){
      return "${DateFormat('d MMM').format(dateTime)}";
    }
    if(days == 0){
      return "${DateFormat('MMM yyyy').format(dateTime)}";
    }
    if(days == 71){
      return "${DateFormat('d').format(dateTime)}";
    }
    if(days == 72){
      return "${DateFormat('MMM').format(dateTime)}";
    }
    if(days == 73){
      return "${DateFormat('EEEE').format(dateTime).substring(0,2)} ${DateFormat('d').format(dateTime)}, ${dateTime.hour.toString().padLeft(2,"0")}:${dateTime.minute.toString().padLeft(2,"0")}";
    }
    return "Error";
    return "${dateTime.day}.${dateTime.month}.${dateTime.year}  ${dateTime.hour}:${dateTime.minute}";
  }


}