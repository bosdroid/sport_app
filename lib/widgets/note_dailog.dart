import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class NoteDialog extends StatefulWidget {
  final String initialNote;
  final Function(String) onSave;

  const NoteDialog({
    super.key,
    required this.initialNote,
    required this.onSave,
  });

  @override
  _NoteDialogState createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  late TextEditingController _controller;
  final SpeechToText _speechToText = SpeechToText();
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
    _initSpeechToText();
  }

  Future<void> _initSpeechToText() async {
    bool available = await _speechToText.initialize(
      onError: (error) => print("SpeechToText Error: $error"),
      onStatus: (status) => print("SpeechToText Status: $status"),
    );
    if (!available) {
      print('Speech recognition is not available');
    }
  }

  Future<void> _startListening() async {
    var micPermission = await Permission.microphone.request();
    if (micPermission.isGranted) {
      bool available = await _speechToText.initialize(
        onError: (error) => print("SpeechToText Error: $error"),
        onStatus: (status) => print("SpeechToText Status: $status"),
      );

      if (available) {
        _speechToText.listen(
          onResult: (result) {
            setState(() {
              _controller.text = "${_controller.text} ${result.recognizedWords}";
            });
          },
        );
        setState(() {
          isListening = true;
        });
      } else {
        print("Speech recognition not available");
      }
    } else {
      print("Microphone permission denied");
    }
  }


  void _stopListening() {
    _speechToText.stop();
    setState(() {
      isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        title: Text(widget.initialNote.isNotEmpty ? "Edit Note" : "Add Note"),
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textAlignVertical: TextAlignVertical.top,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: "Enter your note...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  GestureDetector(
                    onLongPressStart: (_) {
                      _startListening();
                    },
                    onLongPressEnd: (_) {
                      _stopListening();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        color: isListening ? Colors.red : Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mic, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            isListening ? "Listening..." : "Hold to Talk",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10,),
                  Visibility(
                    visible: false,
                    child: GestureDetector(
                      onTap: null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.red ,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_fix_high, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              "AI Organize",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onSave(_controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
