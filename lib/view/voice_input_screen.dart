import 'package:bjj_dairy/providers/ai_analyzer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

import '../widgets/primary_button.dart';

class VoiceInputScreen extends StatefulWidget {
  const VoiceInputScreen({super.key});

  @override
  _VoiceInputScreenState createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends State<VoiceInputScreen>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isLocked = false;
  String _recordedText = "";
  List<String> words = [];
  late AnimationController _animationController;
  Offset? _initialPosition;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _initSpeechToText();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  Future<void> _initSpeechToText() async {
    bool available = await _speech.initialize(
      onError: (error) => print("SpeechToText Error: $error"),
      onStatus: (status) => print("SpeechToText Status: $status"),
    );
    if (!available) {
      print('Speech recognition is not available');
    }
  }

  Future<void> _checkPermissions() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      print("Microphone permission denied");
    }
  }

  Future<void> _startRecording() async {
    if (!_isListening) {
      setState(() {
        _isListening = true;
      });
      HapticFeedback.vibrate();
      _speech.listen(
        onResult: (result) {
          // if (result.recognizedWords.isNotEmpty) {
            setState(() {
              _recordedText = "$_recordedText ${result.recognizedWords}";
              words = _recordedText.split(" ");
            });
          // }
        },
        listenFor: Duration(minutes: 5), // Keep listening for a long time
        pauseFor: Duration(seconds: 3), // Allow short pauses
        onSoundLevelChange: (level) {
          if (level == 0.0) {
            // Restart listening if silence is detected
            _restartListening();
          }
        },
        partialResults: false,
      );
    }
  }

  Future<void> _stopRecording() async {
    if (_isListening) {
      setState(() {
        _isLocked = false;
        _isListening = false;
      });
      _speech.stop();
    }
  }

  void _lockRecording() {
    setState(() {
      _isLocked = true;
    });

    // Restart speech recognition to continue capturing text
    if (!_speech.isListening) {
      _speech.listen(
        onResult: (result) {
          // if (result.recognizedWords.isNotEmpty) {
            setState(() {
              _recordedText = "$_recordedText ${result.recognizedWords}"; // Avoid appending duplicate words
              words = _recordedText.split(" ");
            });
          // }
        },
        listenFor: Duration(minutes: 5), // Keep listening for a long time
        pauseFor: Duration(seconds: 3), // Allow short pauses
        onSoundLevelChange: (level) {
          if (level == 0.0) {
            // Restart listening if silence is detected
            _restartListening();
          }
        },
        partialResults: false, // Ensures only final results are added
      );
    }
  }

  Future<void> _restartListening() async {
    if (_isListening && !_speech.isListening) {
      await Future.delayed(Duration(seconds: 1)); // Small delay to prevent spam listening
      _speech.listen(
        onResult: (result) {
          setState(() {
            _recordedText = "$_recordedText ${result.recognizedWords}".trim();
            words = _recordedText.split(" ");
          });
        },
        listenFor: Duration(minutes: 5), // Keep listening
        pauseFor: Duration(seconds: 3), // Allow pauses
      );
    }
  }


  void _editWord(int index) {
    TextEditingController controller =
    TextEditingController(text: words[index]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Word"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                words[index] = controller.text;
                _recordedText = words.join(" ").trim();
              });
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AiAnalyzerProvider aiAnalyzerProvider = Provider.of<AiAnalyzerProvider>(context, listen: true);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
          iconTheme: IconThemeData().copyWith(color: Colors.white),
          title: Text("AI Voice Input",style: TextStyle(
              color: Colors.white
          ))
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(8),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: aiAnalyzerProvider.isLoading ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16,),
              Text('Please wait...',style: TextStyle(
                color: Theme.of(context).primaryColor,fontSize: 20,fontWeight: FontWeight.bold
              ),)
            ],
          ) : aiAnalyzerProvider.aiResponse.isNotEmpty ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(aiAnalyzerProvider.aiResponse,style: TextStyle(
                            color: Colors.black,fontSize: 16,fontWeight: FontWeight.bold
                        ),),
                      ),
                    ),
                  ),
              ),
              const SizedBox(height: 10,),
              PrimaryButton(
                text: 'Go Back',
                onPressed: () async {
                  aiAnalyzerProvider.resetResponse();
                },
              ),
            ],
          ) : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: _recordedText.isNotEmpty ? 250:null,
                child: SingleChildScrollView(
                  child: Text(
                    _recordedText,
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                height:words.isNotEmpty ? 300:null,
                child: SingleChildScrollView(
                  child: Wrap(
                    children: words.asMap().entries.map((entry) {
                      int idx = entry.key;
                      return GestureDetector(
                        onTap: () => _editWord(idx),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Chip(label: Text(entry.value)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onLongPressStart: (details) {
                  _initialPosition = details.globalPosition;
                  _startRecording();
                },
                onLongPressMoveUpdate: (details) {
                  if (_initialPosition != null &&
                      details.globalPosition.dy < _initialPosition!.dy - 50) {
                    _lockRecording();
                  }
                },
                onLongPressEnd: (_) {
                  if (!_isLocked) { // Prevent stopping if locked
                    _stopRecording();
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      width: _isListening ? 80 : 60,
                      height: _isListening ? 80 : 60,
                      decoration: BoxDecoration(
                        color: _isLocked ? Colors.redAccent : Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Icon(Icons.mic, color: Colors.white, size: 30),
                  ],
                ),
              ),
              SizedBox(height: 10),
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _animationController.value,
                    child: Text(
                      _isListening && !_isLocked ? "Recording..." : _isListening && _isLocked ? "Recording Locked...": "Press & Hold to Record",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
              if (_isLocked) ...[
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _stopRecording,
                  child: Text("Stop Recording"),
                ),
              ],
              SizedBox(height: 20),
              _recordedText.isNotEmpty && !_isListening ?
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      print("Final Submission: $_recordedText");
                      aiAnalyzerProvider.analyzeText(words.join(" ").trim(),context);
                    },
                    child: Text("Submit"),
                  ),
                  const SizedBox(width: 20,),
                 ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red, // Use styleFrom for simple styling
                    ),
                    onPressed: () {
                     setState(() {
                       _recordedText = "";
                       words.clear();
                     });
                    },
                    child: Text("Reset"),
                  ),
                ],
              ):const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}
