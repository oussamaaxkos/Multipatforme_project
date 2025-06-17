import 'package:flutter/material.dart';
// import 'dart:convert';
import 'package:http/http.dart' as http;

class GenerateurImage extends StatefulWidget {
  const GenerateurImage({super.key});

  @override
  State<GenerateurImage> createState() => _GenerateurImageState();
}

class _GenerateurImageState extends State<GenerateurImage> {
  final TextEditingController _promptController = TextEditingController();
  String? _imageUrl;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> generateImage(String prompt) async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _imageUrl = null;
      _errorMessage = null;
    });

    try {
      String? imageUrl = await _generateWithPollinations(prompt);

      if (mounted) {
        if (imageUrl != null) {
          setState(() {
            _imageUrl = imageUrl;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _errorMessage = "Impossible de générer l'image. Vérifiez votre connexion internet.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Erreur de génération: ${e.toString()}";
        });
      }
      debugPrint("Erreur génération image: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<String?> _generateWithPollinations(String prompt) async {
    try {
      final cleanPrompt = prompt.trim().replaceAll(RegExp(r'[^\w\s\-.,!?]'), '');
      if (cleanPrompt.isEmpty) {
        throw Exception("Le prompt ne peut pas être vide");
      }

      final encodedPrompt = Uri.encodeComponent(cleanPrompt);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Génère bien une image carrée 512x512
      final url = "https://image.pollinations.ai/prompt/$encodedPrompt?width=512&height=512&seed=$timestamp&model=flux";

      debugPrint("URL Pollinations: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception("Timeout - L'API met trop de temps à répondre"),
      );

      if (response.statusCode == 200) {
        return url;
      } else {
        throw Exception("Erreur HTTP ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erreur Pollinations: $e");
      throw Exception("Pollinations.ai non disponible: $e");
    }
  }

  Widget _buildGeneratedImage() {
    const double imageSize = 400; // Taille carrée

    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFFFD700),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Génération en cours...',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : _imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        _imageUrl!,
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFFD700),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Erreur de chargement',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_camera_outlined,
                            size: 64,
                            color: Color(0xFFFFD700),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Votre image générée\napparaîtra ici',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildPromptSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFFFD700),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Décrivez votre image',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _promptController,
            maxLines: 4,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: "Ex: Un chat astronaute flottant dans l'espace étoilé, style réaliste, éclairage cinématographique, haute qualité, 4K",
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: const Color(0xFFFFD700).withOpacity(0.5),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Color(0xFFFFD700),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                shadowColor: const Color(0xFFFFD700).withOpacity(0.3),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Icon(Icons.auto_awesome, size: 24),
              label: Text(
                _loading ? "Génération en cours..." : "Générer l'image",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _loading
                  ? null
                  : () {
                      final prompt = _promptController.text.trim();
                      if (prompt.isNotEmpty) {
                        generateImage(prompt);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Veuillez entrer une description'),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_imageUrl == null || _loading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFD700),
                side: const BorderSide(
                  color: Color(0xFFFFD700),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text(
                "Nouvelle image",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                final prompt = _promptController.text.trim();
                if (prompt.isNotEmpty) {
                  generateImage(prompt);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Veuillez entrer une description pour générer une nouvelle image'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          'Générateur d\'Images IA',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 900;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isWide ? 32.0 : 20.0),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section gauche - Formulaire
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildPromptSection(),
                            const SizedBox(height: 24),
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Section droite - Image
                      Expanded(
                        flex: 3,
                        child: Center(child: _buildGeneratedImage()),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildPromptSection(),
                      const SizedBox(height: 24),
                      _buildGeneratedImage(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
          );
        },
      ),
    );
  }
}