import 'package:dart_openai/openai.dart';
import 'package:flutter/material.dart';

void main() {
  OpenAI.apiKey = "KEY";
  OpenAI.organization = "ORG";

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.teal,
        appBarTheme: AppBarTheme(
          elevation: 0,
        ),
        scaffoldBackgroundColor: Colors.teal,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final inputController = TextEditingController();
  final outputController = TextEditingController();
  bool isLoading = false;

  void onTranslate() async {
    final inputText = inputController.text.trim();
    setState(() {
      isLoading = true;
    });

    final chatCompletion = await OpenAI.instance.chat.create(
      model: "gpt-3.5-turbo",
      temperature: 0,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: """
            Sei un traduttore di lingua Furbish, parlata dai giocattoli Furbys.
            Comportati come google translate, prendi una frase da tradurre e la traduci.
            L'utente ti da come input il testo da tradurre, in italiano, e come risposta ritorni la frase tradotta in lingua Furbish.
            Salta tutta la prosa, ritorna sempre e solo la frase tradotta.

            Esempi:

            Dimmi una barzelletta
            Wee-tah kah loo-loo

            Sono molto felice
            Kah mee-mee noo-loo

            Mi piace la musica
            Kah toh-loo ee-kah lee-koo
          """,
        ),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: inputText,
        ),
      ],
    );

    outputController.text = chatCompletion.choices[0].message.content;
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Furbish"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                languageInputBox(
                  placeholder: "Il tuo testo in italiano da tradurre",
                  controller: inputController,
                ),
                languageInputBox(
                  placeholder: "Un Furby sta per parlarti nella sua lingua...",
                  controller: outputController,
                ),
              ],
            ),
            Center(
              child: SizedBox(
                width: 65,
                height: 65,
                child: FloatingActionButton(
                  backgroundColor: Colors.teal.shade900,
                  onPressed: onTranslate,
                  child: isLoading ? CircularProgressIndicator() : Icon(Icons.arrow_downward, size: 30),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget languageInputBox({
    required String placeholder,
    required TextEditingController controller,
  }) =>
      Expanded(
        child: Container(
          margin: EdgeInsets.all(5),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: controller,
            minLines: 5,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: placeholder,
              border: InputBorder.none,
            ),
          ),
        ),
      );
}
