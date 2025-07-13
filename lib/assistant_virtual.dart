import 'package:flutter/material.dart';
import 'drawer.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// AJOUT DU PACKAGE TEXT TO SPEECH
import 'package:flutter_tts/flutter_tts.dart';

class AssistantVirtuel extends StatefulWidget {
  const AssistantVirtuel({super.key});

  @override
  State<AssistantVirtuel> createState() => _AssistantVirtuelState();
}

class _AssistantVirtuelState extends State<AssistantVirtuel> with TickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // AJOUT: INSTANCE DE TEXT TO SPEECH
  final FlutterTts _flutterTts = FlutterTts();

  bool _speechEnabled = false;
  String _lastWords = '';
  List<Map<String, dynamic>> messages = [];
  late AnimationController _buttonController;
  late AnimationController _pulseController;
  bool _isLoading = false;
  File? _selectedImage;
  Uint8List? _webImage;
  String? _imageName;
  String? _currentUserId;

  static const String _geminiApiKey = '';
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts(); // Initialiser TTS
    _buttonController = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat();

    _initializeUser();
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _flutterTts.stop(); // Arrêter TTS à la fermeture
    super.dispose();
  }

  // INITIALISATION TTS
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("fr-FR");
    await _flutterTts.setSpeechRate(0.44);
    await _flutterTts.setPitch(1.0);
    // Optionnel : adapter la voix pour iOS/Android/Web ici
  }

  // FONCTION POUR LIRE LE TEXTE (voix robot)
  Future<void> _speak(String text) async {
    await _flutterTts.stop(); // Stopper toute lecture précédente
    await _flutterTts.speak(text);
  }

  Future<void> _initializeUser() async {
    try {
      if (_auth.currentUser == null) {
        // await _auth.signInAnonymously();
      }

      _currentUserId = _auth.currentUser?.uid;

      if (_currentUserId != null) {
        await _loadMessagesFromFirestore();
      } else {
        _addWelcomeMessage();
      }
    } catch (e) {
      print('Erreur initialisation utilisateur: $e');
      _addWelcomeMessage();
      _showMessage('Impossible de se connecter au service de sauvegarde', const Color(0xFFFF4444));
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      messages.add({
        'text': 'Bonjour ! Je suis votre assistant virtuel alimenté par Gemini. Comment puis-je vous aider ?',
        'isUser': false,
        'timestamp': DateTime.now(),
      });
    });
  }

  Future<void> _loadMessagesFromFirestore() async {
    if (_currentUserId == null) return;

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      if (querySnapshot.docs.isEmpty) {
        await _saveWelcomeMessage();
      } else {
        setState(() {
          messages = querySnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'text': data['text'] ?? '',
              'isUser': data['sender'] == 'user',
              'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'messageId': doc.id,
            };
          }).toList();
        });
      }

      _scrollToBottom();
    } catch (e) {
      print('Erreur chargement messages: $e');
      _addWelcomeMessage();
      _showMessage('Erreur lors du chargement des messages', const Color(0xFFFF4444));
    }
  }

  Future<void> _saveWelcomeMessage() async {
    if (_currentUserId == null) return;

    try {
      const welcomeText = 'Bonjour ! Je suis votre assistant virtuel alimenté par Gemini. Comment puis-je vous aider ?';

      final docRef = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('messages')
          .add({
        'text': welcomeText,
        'sender': 'bot',
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        messages.add({
          'text': welcomeText,
          'isUser': false,
          'timestamp': DateTime.now(),
          'messageId': docRef.id,
        });
      });
    } catch (e) {
      print('Erreur sauvegarde message d\'accueil: $e');
      _addWelcomeMessage();
    }
  }

  Future<String?> _saveMessageToFirestore({
    required String text,
    required String sender,
  }) async {
    if (_currentUserId == null) return null;

    try {
      final docRef = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('messages')
          .add({
        'text': text,
        'sender': sender,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Message sauvegardé avec ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Erreur sauvegarde message: $e');
      _showMessage('Erreur lors de la sauvegarde', const Color(0xFFFF4444));
      return null;
    }
  }

  Future<void> _clearConversation() async {
    if (_currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('messages')
          .get();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      setState(() {
        messages.clear();
      });

      await _saveWelcomeMessage();
      _showMessage('Conversation effacée', const Color(0xFF4CAF50));
    } catch (e) {
      print('Erreur suppression messages: $e');
      _showMessage('Erreur lors de la suppression', const Color(0xFFFF4444));
    }
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          print('Erreur Speech-to-Text: ${error.errorMsg}');
          _showMessage('Erreur vocale: ${error.errorMsg}', const Color(0xFFFF4444));
        },
        onStatus: (status) => print('Speech status: $status'),
      );
      setState(() {});
    } catch (e) {
      print('Erreur initialisation speech: $e');
      _showMessage('Impossible d\'initialiser la reconnaissance vocale', const Color(0xFFFF4444));
    }
  }

  void _startListening() async {
    if (!_speechEnabled) {
      _showMessage('Reconnaissance vocale non disponible', const Color(0xFFFF4444));
      return;
    }

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'fr_FR',
        cancelOnError: true,
      );
      setState(() {});
    } catch (e) {
      print('Erreur démarrage écoute: $e');
      _showMessage('Erreur lors du démarrage de l\'écoute', const Color(0xFFFF4444));
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    print('Speech result: "${result.recognizedWords}"');
    print('Is final: ${result.finalResult}');
    print('Confidence: ${result.confidence}');

    setState(() => _lastWords = result.recognizedWords);

    if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
      final recognizedText = result.recognizedWords.trim();
      print('Envoi du message vocal: "$recognizedText"');

      _addUserMessage(recognizedText, image: _selectedImage, webImage: _webImage);
      _sendToGemini(recognizedText, image: _selectedImage, webImage: _webImage);

      setState(() {
        _selectedImage = null;
        _webImage = null;
        _imageName = null;
      });

      _scrollToBottom();
    }
  }

  Future<void> _addUserMessage(String text, {File? image, Uint8List? webImage}) async {
    final messageId = await _saveMessageToFirestore(text: text, sender: 'user');

    setState(() {
      messages.add({
        'text': text,
        'isUser': true,
        'timestamp': DateTime.now(),
        'messageId': messageId,
        'image': image,
        'webImage': webImage,
      });
      _lastWords = '';
    });
  }

  // AJOUT : Ajout d'un bouton pour lire la réponse générée
  Future<void> _addBotMessage(String text) async {
    final messageId = await _saveMessageToFirestore(text: text, sender: 'bot');

    setState(() {
      messages.add({
        'text': text,
        'isUser': false,
        'timestamp': DateTime.now(),
        'messageId': messageId,
      });
    });

    // Lecture automatique de la réponse générée (optionnel, vous pouvez mettre sous condition)
    // await _speak(text);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (image != null) {
        await _processPickedImage(image);
      }
    } catch (e) {
      print('Erreur sélection image: $e');
      _showMessage('Erreur lors de la sélection d\'image: $e', const Color(0xFFFF4444));
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (image != null) {
        await _processPickedImage(image);
      }
    } catch (e) {
      print('Erreur prise photo: $e');
      _showMessage('Erreur lors de la prise de photo: $e', const Color(0xFFFF4444));
    }
  }

  Future<void> _processPickedImage(XFile image) async {
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      setState(() {
        _webImage = bytes;
        _imageName = image.name;
        _selectedImage = null;
      });
    } else {
      setState(() {
        _selectedImage = File(image.path);
        _webImage = null;
        _imageName = image.name;
      });
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _buildImageOption(Icons.photo_library_rounded, 'Galerie', _pickImage),
              const SizedBox(height: 12),
              _buildImageOption(Icons.photo_camera_rounded, 'Appareil photo', _takePhoto),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageOption(IconData icon, String title, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFFFD700), size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        onTap: () {
          Navigator.of(context).pop();
          onTap();
        },
      ),
    );
  }

  void _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null && _webImage == null) return;

    final messageText = text.isNotEmpty ? text : 'Image envoyée';
    await _addUserMessage(messageText, image: _selectedImage, webImage: _webImage);

    _sendToGemini(text, image: _selectedImage, webImage: _webImage);
    _textController.clear();
    setState(() {
      _selectedImage = null;
      _webImage = null;
      _imageName = null;
    });
    _scrollToBottom();
  }

  Future<String> _encodeImageToBase64(File? imageFile, Uint8List? webImage) async {
    if (kIsWeb && webImage != null) {
      return base64Encode(webImage);
    } else if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    }
    throw Exception('Aucune image à encoder');
  }

  Future<void> _sendToGemini(String userMessage, {File? image, Uint8List? webImage}) async {
    if (userMessage.trim().isEmpty && image == null && webImage == null) {
      print('Aucun contenu à envoyer - message vide');
      _showMessage('Aucun contenu à envoyer', const Color(0xFFFF4444));
      return;
    }

    print('Envoi à Gemini: "$userMessage"');
    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse(_geminiApiUrl).replace(queryParameters: {'key': _geminiApiKey});

      Map<String, dynamic> requestBody = {
        'contents': [{'parts': []}],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        }
      };

      if (userMessage.trim().isNotEmpty) {
        requestBody['contents'][0]['parts'].add({'text': userMessage.trim()});
      }

      if (image != null || webImage != null) {
        final base64Image = await _encodeImageToBase64(image, webImage);
        requestBody['contents'][0]['parts'].add({
          'inline_data': {
            'mime_type': 'image/jpeg',
            'data': base64Image,
          }
        });
      }

      if (requestBody['contents'][0]['parts'].isEmpty) {
        throw Exception('Aucun contenu à envoyer dans la requête');
      }

      print('Requête envoyée: ${requestBody['contents'][0]['parts'].length} partie(s)');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('Réponse reçue: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates']?.isNotEmpty == true) {
          final geminiResponse = data['candidates'][0]['content']['parts'][0]['text'];
          await _addBotMessage(geminiResponse);
          setState(() => _isLoading = false);
        } else {
          throw Exception('Aucune réponse de Gemini');
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Erreur inconnue';
        print('Erreur API: $errorMessage');
        await _addBotMessage('Erreur ${response.statusCode}: $errorMessage');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Erreur connexion: $e');
      await _addBotMessage('Erreur de connexion: ${e.toString()}');
      setState(() => _isLoading = false);
    }

    _scrollToBottom();
  }

  Widget _buildMessage(Map<String, dynamic> message, int index) {
    final isUser = message['isUser'];
    final image = message['image'] as File?;
    final webImage = message['webImage'] as Uint8List?;

    // AJOUT : IconButton pour lire la réponse générée si c'est un message du bot
    return Container(
      margin: EdgeInsets.only(
        bottom: 16,
        left: isUser ? 50 : 0,
        right: isUser ? 0 : 50,
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isUser
                ? const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFE55C)],
                  )
                : null,
            color: isUser ? null : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUser
                  ? Colors.transparent
                  : const Color(0xFFFFD700).withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: isUser
                    ? const Color(0xFFFFD700).withOpacity(0.3)
                    : Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (image != null || webImage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb && webImage != null
                        ? Image.memory(
                            webImage,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover)
                        : image != null
                            ? Image.file(
                                image,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover)
                            : Container(),
                  ),
                ),
              if (message['text'].isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        message['text'],
                        style: TextStyle(
                          color: isUser ? const Color(0xFF1A1A1A) : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (!isUser)
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded,
                            color: Color(0xFFFFD700)),
                        tooltip: "Lire cette réponse",
                        onPressed: () => _speak(message['text']),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 50),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        const Color(0xFFFFD700).withOpacity(0.3),
                        const Color(0xFFFFD700),
                        _pulseController.value,
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              const Text(
                'Gemini réfléchit...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb && _webImage != null
                ? Image.memory(_webImage!, width: 60, height: 60, fit: BoxFit.cover)
                : _selectedImage != null
                    ? Image.file(_selectedImage!, width: 60, height: 60, fit: BoxFit.cover)
                    : Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.image_rounded, color: Color(0xFFFFD700)),
                      ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _imageName ?? 'Image sélectionnée',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFFFFD700)),
            onPressed: () {
              setState(() {
                _selectedImage = null;
                _webImage = null;
                _imageName = null;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text(
          'Assistant Virtuel',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1E1E1E),
            onSelected: (value) {
              if (value == 'clear') {
                _showClearConversationDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Color(0xFFFF4444)),
                    SizedBox(width: 8),
                    Text('Effacer la conversation', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: const Menu(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length && _isLoading) {
                    return _buildLoadingIndicator();
                  }
                  return _buildMessage(messages[index], index);
                },
              ),
            ),

            if (_speechToText.isListening && _lastWords.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                ),
                child: Text(
                  'En cours... $_lastWords',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            if (_selectedImage != null || _webImage != null) _buildImagePreview(),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.image_rounded, color: Color(0xFFFFD700)),
                      onPressed: _showImagePicker,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Tapez votre message...',
                        hintStyle: const TextStyle(color: Color(0xFF808080)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(color: Color(0xFF404040)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(color: Color(0xFF404040)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2A2A2A),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendTextMessage(),
                    ),
                  ),

                  const SizedBox(width: 12),

                  GestureDetector(
                    onTapDown: (_) => _buttonController.forward(),
                    onTapUp: (_) {
                      _buttonController.reverse();
                      Future.delayed(const Duration(milliseconds: 50), () {
                        if (_speechToText.isNotListening && !_isLoading) {
                          _startListening();
                        } else if (_speechToText.isListening) {
                          _stopListening();
                        }
                      });
                    },
                    onTapCancel: () => _buttonController.reverse(),
                    child: AnimatedBuilder(
                      animation: _buttonController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 - (_buttonController.value * 0.1),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: _speechToText.isListening
                                  ? const LinearGradient(colors: [Color(0xFFFF4444), Color(0xFFFF6666)])
                                  : _isLoading
                                      ? const LinearGradient(colors: [Color(0xFF666666), Color(0xFF888888)])
                                      : const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFE55C)]),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_speechToText.isListening
                                          ? const Color(0xFFFF4444)
                                          : _isLoading
                                              ? const Color(0xFF666666)
                                              : const Color(0xFFFFD700))
                                      .withOpacity(0.4 + (_buttonController.value * 0.2)),
                                  blurRadius: 12 + (_buttonController.value * 8),
                                  offset: Offset(0, 4 + (_buttonController.value * 4)),
                                ),
                              ],
                            ),
                            child: Icon(
                              _speechToText.isNotListening
                                  ? (_isLoading ? Icons.hourglass_empty_rounded : Icons.mic_rounded)
                                  : Icons.stop_rounded,
                              color: const Color(0xFF1A1A1A),
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Color(0xFFFFD700)),
                      onPressed: _isLoading ? null : _sendTextMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConversationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Effacer la conversation',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir effacer toute la conversation ? Cette action est irréversible.',
            style: TextStyle(color: Color(0xFFB0B0B0)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Color(0xFFFFD700)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearConversation();
              },
              child: const Text(
                'Effacer',
                style: TextStyle(color: Color(0xFFFF4444)),
              ),
            ),
          ],
        );
      },
    );
  }
}
