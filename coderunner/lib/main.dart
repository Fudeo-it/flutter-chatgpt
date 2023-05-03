import 'package:dart_openai/openai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';

void main() {
  OpenAI.apiKey = "KEY";
  OpenAI.organization = "ORG";

  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorScheme: ColorScheme.dark(secondary: Colors.yellow)),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final controller = CodeController(text: "", language: dart);
  String consoleOutput = "";
  bool isLoading = false;

  void onRunCode() async {
    final code = controller.fullText;
    setState(() => isLoading = true);

    final chatCompletition = await OpenAI.instance.chat.create(
      model: "gpt-3.5-turbo",
      temperature: 0,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: """
            Sei una macchina virtuale per eseguire codice di programmazione.
            Comportati come una repl, io ti do un pezzo di codice in linguaggio Dart, tu lo esegui e stampi solamente l'output da console.
            Salta tutta la prosa, ritorna sempre e solo l'output della console.

            Esempi:

            print("Hello");
            > Hello

            void print(String s) { print("Hello \${s}"); }
            print("Gabriel");
            > Hello Gabriel
          """,
        ),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: code,
        ),
      ],
    );

    final output = chatCompletition.choices[0].message.content;
    setState(() {
      isLoading = false;
      consoleOutput = output;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        codeEditor(),
        playButton(),
        console(),
      ],
    ));
  }

  Widget codeEditor() => Expanded(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CodeTheme(
            data: CodeThemeData(styles: monokaiSublimeTheme),
            child: TextField(
              controller: controller,
              maxLines: null,
              decoration: InputDecoration(
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      );

  Widget playButton() => Column(
        children: [
          Expanded(
            child: Container(
              width: 1,
              height: double.infinity,
              color: Colors.grey.shade700,
            ),
          ),
          FloatingActionButton(
            onPressed: onRunCode,
            child: isLoading ? CircularProgressIndicator() : Icon(Icons.play_arrow, size: 30),
          ),
          Expanded(
            child: Container(
              width: 1,
              height: double.infinity,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      );

  Widget console() => Expanded(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(consoleOutput),
        ),
      );
}
