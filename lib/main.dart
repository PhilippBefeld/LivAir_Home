
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:livair_home/pages/sign_in_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'l10n/l10n.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  runApp(LivAirHome()); // Wrap your app
}

class LivAirHome extends StatefulWidget {

  @override
  LivAirHomeState createState() => LivAirHomeState();

  static LivAirHomeState? of(BuildContext context) => context.findAncestorStateOfType<LivAirHomeState>();
}


class LivAirHomeState extends State<LivAirHome>{

  Locale _locale = const Locale('en');



  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }


  @override
  Widget build(BuildContext context){
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(// navigation bar color
      statusBarColor: Colors.white, // status bar color
    ));
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: L10n.all,
      debugShowCheckedModeBanner: false,
      home: SignInPage(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child!,
        );
      },
    );
  }
}

