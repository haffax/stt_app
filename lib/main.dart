import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text_provider.dart';

void main() => runApp(const SttApp());

class SttApp extends StatefulWidget {
  const SttApp({Key? key}) : super(key: key);

  @override
  State<SttApp> createState() => _SttAppState();
}

class _SttAppState extends State<SttApp> {
  final SpeechToText speech = SpeechToText();
  late SpeechToTextProvider speechProvider;

  @override
  void initState() {
    super.initState();
    speechProvider = SpeechToTextProvider(speech);
    initSpeechState();
  }

  // TODO reset state when finished.
  // Seems to finish before rendering but no guarantee
  Future<void> initSpeechState() async => await speechProvider.initialize();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SpeechToTextProvider>.value(
      value: speechProvider,
      child: const MaterialApp(
        home: Scaffold(
          body: SttPage(),
        ),
      ),
    );
  }
}

class SttPage extends StatefulWidget {
  const SttPage({Key? key}) : super(key: key);

  @override
  SttPageState createState() => SttPageState();
}

class SttPageState extends State<SttPage> {
  String _currentLocaleId = '';

  void _setCurrentLocale(SpeechToTextProvider speechProvider) {
    if (speechProvider.isAvailable && _currentLocaleId.isEmpty) {
      _currentLocaleId = speechProvider.systemLocale?.localeId ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    var speechProvider = Provider.of<SpeechToTextProvider>(context);

    _setCurrentLocale(speechProvider);

    return speechProvider.isNotAvailable
        ? Container(
            decoration: const BoxDecoration(color: Colors.red),
            width: double.infinity,
            height: double.infinity,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  "Not initialized!\n\n Permissions granted?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
        : SafeArea(
            child: Column(children: [
              const SizedBox(height: 16),
              IconButton.filled(
                color:
                    speechProvider.isListening ? Colors.blue : Colors.black87,
                iconSize: 96,
                icon: const Icon(Icons.mic),
                isSelected: speechProvider.isListening,
                onPressed: () {
                  if (speechProvider.isAvailable &&
                      !speechProvider.isListening) {
                    setState(() {
                      speechProvider.listen(
                          partialResults: true, localeId: _currentLocaleId);
                    });
                  } else if (speechProvider.isListening) {
                    setState(() {
                      speechProvider.stop();
                    });
                  }
                },
              ),
              Center(
                child: Text(
                  speechProvider.isListening
                      ? "Listening..."
                      : 'Press mic-icon to start listening',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const Divider(),
              DropdownButton(
                onChanged: (selectedVal) => _switchLang(selectedVal),
                value: _currentLocaleId,
                items: speechProvider.locales
                    .map(
                      (localeName) => DropdownMenuItem(
                        value: localeName.localeId,
                        child: Text(localeName.name),
                      ),
                    )
                    .toList(),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      color: Colors.amberAccent,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            speechProvider.lastResult?.recognizedWords ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    color: speechProvider.hasError ? Colors.red : Colors.green),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: Text(
                  speechProvider.hasError
                      ? speechProvider.lastError!.errorMsg
                      : "No error. All good.",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ]),
          );
  }

  void _switchLang(selectedVal) {
    setState(() {
      _currentLocaleId = selectedVal;
    });
    debugPrint(selectedVal);
  }
}
