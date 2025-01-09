
import 'package:flutter/cupertino.dart';

class ImprintText extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'en' ? Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Contact Info",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),),
            const Text("LivAir GmbH\n89426 Wittislingen\nGermany\n",style: TextStyle(fontSize: 16)),
            const Text("Telephone: +49 (0) 9076 9199835\nE-Mail: info@livair.io\n",style: TextStyle(fontSize: 16)),
            const Text("CEO: Martin Waltl, Rudolf Waltl",style: TextStyle(fontSize: 16)),
            const Text("VAT-IdNr: DE360338631\nCommercial registration number: HRB 281464\n",style: TextStyle(fontSize: 16)),
            const Text("Alternative dispute resolution:",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),),
            const Text("The European Commission provides a platform for out-of-court online dispute resolution (OS platform), which can be found at https://ec.europa.eu/odr.",style: TextStyle(fontSize: 16)),
            const Text("We have been a member of the 'FairCommerce' initiative since June 8th, 2018. You can find more information about this at www.fair-commerce.de.",style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    ) :
    Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Kontaktinfo",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),),
            const Text("LivAir GmbH\n89426 Wittislingen\nDeutschland\n",style: TextStyle(fontSize: 16)),
            const Text("Telefon: +49 (0) 9076 9199835\nE-Mail: info@livair.io\n",style: TextStyle(fontSize: 16)),
            const Text("Geschäftsführer: Martin Waltl, Rudolf Waltl",style: TextStyle(fontSize: 16)),
            const Text("USt-IdNr: DE360338631\nHandelsregisternummer: HRB 281464\n",style: TextStyle(fontSize: 16)),
            const Text("Alternative Streitbeilegung:",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),),
            const Text("Die Europäische Kommission stellt eine Plattform für die außergerichtliche Online-Streitbeilegung (OS-Plattform) bereit, die unter https://ec.europa.eu/odr zu finden ist.",style: TextStyle(fontSize: 16)),
            const Text("Wir sind seit dem 08.06.2018 Mitglied der Initiative 'FairCommerce'. Mehr Informationen dazu findest du unter www.fair-commerce.de.",style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }}

/*
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Contact Info",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),),
            const Text("LivAir GmbH\n89426 Wittislingen\nGermany\n",style: TextStyle(fontSize: 16)),
            const Text("Telephone: +49 (0) 9076 9199835\nE-Mail: info@livair.io\n",style: TextStyle(fontSize: 16)),
            const Text("CEO: Martin Waltl, Rudolf Waltl",style: TextStyle(fontSize: 16)),
            const Text("VAT-IdNr: DE360338631\nCommercial registration number: HRB 281464\n",style: TextStyle(fontSize: 16)),
            const Text("Alternative Streitbeilegung:",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),),
            const Text("Die Europäische Kommission stellt eine Plattform für die außergerichtliche Online-Streitbeilegung (OS-Plattform) bereit, die unter https://ec.europa.eu/odr zu finden ist.",style: TextStyle(fontSize: 16)),
            const Text("Wir sind seit dem 08.06.2018 Mitglied der Initiative 'FairCommerce'. Mehr Informationen dazu findest du unter www.fair-commerce.de.",style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );

 */