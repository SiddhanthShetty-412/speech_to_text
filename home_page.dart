import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SpeechToText _speechToText = SpeechToText();

  bool _speechEnabled = false;
  String _wordsSpoken = "";
  double _confidenceLevel = 0;
  bool _isLoading = true;
  String _selectedLanguage = 'en-US'; // Default to English
  bool _isListening = false; // ✅ track mic state reliably

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      initSpeech();
    } else {
      setState(() {
        _isLoading = false;
        _speechEnabled = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone permission denied")),
      );
    }
  }

  void initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          // ✅ keeps track when mic starts/stops
          setState(() {
            _isListening = status == "listening";
          });
        },
        onError: (error) {
          debugPrint("Speech error: $error");
          setState(() {
            _isListening = false;
          });
        },
      );
      if (!_speechEnabled) {
        throw Exception('Speech recognition not available');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: _selectedLanguage,
    );
    setState(() {
      _confidenceLevel = 0;
      _isListening = true;
    });
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(result) {
    setState(() {
      _wordsSpoken = result.recognizedWords;
      _confidenceLevel = result.confidence;
    });
  }

  void _changeLanguage(String? language) {
    if (language != null) {
      setState(() {
        _selectedLanguage = language;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'Speech Demo',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _isListening
                      ? "Listening..."
                      : _speechEnabled
                      ? "Tap the microphone to start listening..."
                      : "Speech not available",
                  style: const TextStyle(fontSize: 20.0),
                ),
              ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _wordsSpoken,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            if (!_isListening && _confidenceLevel > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: Text(
                  "Confidence: ${(_confidenceLevel * 100).toStringAsFixed(1)}%",
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w200,
                  ),
                ),
              ),
            DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: _changeLanguage,
              items: const [
                DropdownMenuItem(
                  value: 'en-US',
                  child: Text("English"),
                ),
                DropdownMenuItem(
                  value: 'hi-IN',
                  child: Text("Hindi"),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isListening ? _stopListening : _startListening,
        tooltip: 'Listen',
        backgroundColor: Colors.red,
        child: Icon(
          _isListening ? Icons.mic : Icons.mic_off, // ✅ now works properly
          color: Colors.white,
        ),
      ),
    );
  }
}
