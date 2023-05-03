import 'dart:convert';

import 'package:dart_openai/openai.dart';
import 'package:flutter/material.dart';

void main() {
  OpenAI.apiKey = "KEY";
  OpenAI.organization = "ORG";

  runApp(App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final cityNameController = TextEditingController();
  bool isLoading = false;
  String? headerPhotoUrl;
  dynamic cityData;

  void onGenerateCityData() async {
    final inputText = cityNameController.text.trim();
    setState(() => isLoading = true);

    final chatCompletion = await OpenAI.instance.chat.create(
      model: "gpt-3.5-turbo",
      temperature: 0,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: """
            Sei un bot generatore di dati.
            I dati prodotti sono in formato JSON.
            I dati sono in ambito viaggi.
            Io ti do in input il nome di una città, e tu mi rispondi con un JSON in un formato preciso specificato sotto.
            Elimina ogni prosa. Rispondi sempre e solo con il JSON.
            Il testo deve essere in italiano.

            Torino
            {
                "population": "886k",
                "country": "🇮🇹 Italia",
                "currency": "Euro",
                "pointsOfInterest": [
                    {
                        name: "Mole Antoneliana",
                        description: "La Mole Antonelliana è un edificio monumentale di Torino, situato nel centro storico, simbolo della città e uno dei simboli d'Italia."
                    },
                    {
                        name: "Museo Egizio",
                        description: "Il Museo Egizio di Torino è il museo più antico, a livello mondiale, interamente dedicato alla civiltà nilotica."
                    },
                ]
            }

            Il JSON ha questi attributi:
            population: popolazione della città, sempre un numero. Esempi: 500 -> 500. 10000 -> "10k". 1200000 -> "1.2M"
            country: paese in cui si trova la città. Formato: emoji bandiera del paese, uno spazio e dopo il nome del paese in italiano.
            currency: nome della moneta del paese in cui si trova la città (esempio: Euro, Dollaro)
            pointsOfInterest: un array di 10 oggetti. Ogni oggetto ha: name: Il nome del punto di interesse. description: una descrizione di massimo 40 caratteri del punto di interesse.
          """,
        ),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: inputText,
        ),
      ],
    );

    final cityDataJSON = jsonDecode(chatCompletion.choices[0].message.content);

    final query = "Aerial view, hyper realistic. " + inputText + " " + cityDataJSON["pointsOfInterest"][0]["name"];
    final image = await OpenAI.instance.image.create(
      prompt: query,
      n: 1,
      size: OpenAIImageSize.size512,
      responseFormat: OpenAIImageResponseFormat.url,
    );
    final photoUrl = image.data[0].url;

    setState(() {
      isLoading = false;
      headerPhotoUrl = photoUrl;
      cityData = cityDataJSON;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          header(),
          cityData == null
              ? SizedBox()
              : Column(
                  children: [
                    SizedBox(height: 32),
                    stats(),
                    SizedBox(height: 32),
                    pointsOfInterest(),
                  ],
                )
        ]),
      ),
    );
  }

  Widget header() => Stack(
        children: [
          Container(
            width: double.infinity,
            height: 400,
            margin: EdgeInsets.only(bottom: 30),
            child: Image.network(
              headerPhotoUrl ??
                  "https://images.unsplash.com/photo-1574681332110-c45ff35a5e09?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1035&q=80",
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 60,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 5,
                            spreadRadius: 0,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                      child: Center(
                        child: TextField(
                          controller: cityNameController,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            hintText: "Nome città...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  FloatingActionButton(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    onPressed: onGenerateCityData,
                    child: isLoading
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                        : Icon(Icons.search),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget stats() => Row(
        children: [
          CityStat(label: "Paese", value: cityData["country"]),
          CityStat(label: "Popolazione", value: cityData["population"]),
          CityStat(label: "Moneta", value: cityData["currency"]),
        ]
            .map((stat) => Expanded(
                  child: Column(
                    children: [
                      Text(
                        stat.label.toUpperCase(),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                      ),
                      SizedBox(height: 4),
                      Text(
                        stat.value,
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ))
            .toList(),
      );

  Widget pointsOfInterest() => Column(
        children: (cityData["pointsOfInterest"] as List<dynamic>)
            .map((pointOfInterest) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.map),
                    title: Text(pointOfInterest["name"]),
                    subtitle: Text(pointOfInterest["description"]),
                  ),
                ))
            .toList(),
      );
}

class CityStat {
  final String label;
  final String value;

  const CityStat({
    required this.label,
    required this.value,
  });
}
