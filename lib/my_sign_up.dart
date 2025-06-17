import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MySignUp extends StatefulWidget {
  const MySignUp({super.key});

  @override
  State<MySignUp> createState() => _MySignUpState();
}

class _MySignUpState extends State<MySignUp> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateField(String? value, String fieldName, {String? pattern}) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir $fieldName';
    }
    if (fieldName == 'votre mot de passe' && value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    if (pattern != null && !RegExp(pattern).hasMatch(value)) {
      return 'Veuillez saisir un email valide';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_acceptTerms) {
      _showMessage('Veuillez accepter les conditions d\'utilisation', const Color(0xFFFF8800));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Créer le compte
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Sauvegarder dans Firestore - Collection "clients"
      await FirebaseFirestore.instance
          .collection('clients')
          .doc(userCredential.user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showMessage('Compte créé avec succès!', const Color(0xFF00C853));
      Navigator.pop(context);

    } catch (e) {
      _showMessage('Erreur: $e', const Color(0xFFFF4444));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required String? Function(String?) validator,
    bool obscureText = false,
    bool hasToggle = false,
    VoidCallback? onToggle,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 10), // Réduit de 11 à 10
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFFFD700), size: 16), // Réduit de 18 à 16
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 13), // Réduit de 12,15 à 11,13
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Réduit de 9 à 8
          borderSide: const BorderSide(color: Color(0xFF404040), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF404040), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFF4444), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFF4444), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 9), // Réduit de 10 à 9
        hintStyle: const TextStyle(color: Color(0xFF808080), fontSize: 9), // Réduit de 10 à 9
        suffixIcon: hasToggle
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: const Color(0xFFB0B0B0),
                  size: 16, // Réduit de 18 à 16
                ),
                onPressed: onToggle,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              Color(0xFF2A2A2A),
              Color(0xFF1A1A1A),
              Color(0xFF0F0F0F),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18), // Réduit de 20 à 18
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 257), // Réduit de 285 à 257 (10% de moins)
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 20), // Réduit de 22 à 20
                      // En-tête avec bouton retour et logo
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(8), // Réduit de 9 à 8
                              border: Border.all(
                                color: const Color(0xFFFFD700).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFFFD700), size: 16), // Réduit de 18 à 16
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: const EdgeInsets.all(7), // Réduit de 8 à 7
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 54, // Réduit de 60 à 54
                                height: 54, // Réduit de 60 à 54
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFD700), Color(0xFFFFE55C)],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withOpacity(0.3),
                                      blurRadius: 13, // Réduit de 15 à 13
                                      spreadRadius: 1.3, // Réduit de 1.5 à 1.3
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.person_add_rounded,
                                    size: 27, // Réduit de 30 à 27
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 32), // Réduit de 36 à 32
                        ],
                      ),
                      const SizedBox(height: 27), // Réduit de 30 à 27
                      // Card d'inscription
                      Container(
                        padding: const EdgeInsets.all(20), // Réduit de 22 à 20
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(13), // Réduit de 15 à 13
                          border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 16, // Réduit de 18 à 16
                              offset: const Offset(0, 6), // Réduit de 7 à 6
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Créer un compte',
                              style: TextStyle(
                                fontSize: 19, // Réduit de 21 à 19
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.35, // Réduit de 0.4 à 0.35
                              ),
                            ),
                            const SizedBox(height: 5), // Réduit de 6 à 5
                            Text(
                              'Rejoignez-nous dès maintenant',
                              style: TextStyle(
                                fontSize: 9, // Réduit de 10 à 9
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 20), // Réduit de 22 à 20
                            
                            // Champs de saisie
                            _buildTextField(
                              controller: _nameController,
                              label: 'Nom complet',
                              icon: Icons.person_rounded,
                              hint: 'Votre nom et prénom',
                              validator: (value) => _validateField(value, 'votre nom'),
                            ),
                            const SizedBox(height: 13), // Réduit de 15 à 13
                            
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_rounded,
                              hint: 'exemple@email.com',
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) => _validateField(
                                value, 
                                'votre email', 
                                pattern: r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'
                              ),
                            ),
                            const SizedBox(height: 13),
                            
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Mot de passe',
                              icon: Icons.lock_rounded,
                              hint: '••••••••',
                              obscureText: _obscurePassword,
                              hasToggle: true,
                              onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                              validator: (value) => _validateField(value, 'votre mot de passe'),
                            ),
                            const SizedBox(height: 13),
                            
                            _buildTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirmer le mot de passe',
                              icon: Icons.lock_rounded,
                              hint: '••••••••',
                              obscureText: _obscureConfirmPassword,
                              hasToggle: true,
                              onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              validator: _validateConfirmPassword,
                            ),
                            const SizedBox(height: 13),
                            
                            // Conditions d'utilisation
                            Container(
                              padding: const EdgeInsets.all(10), // Réduit de 11 à 10
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(8), // Réduit de 9 à 8
                                border: Border.all(
                                  color: _acceptTerms 
                                    ? const Color(0xFFFFD700).withOpacity(0.5)
                                    : const Color(0xFF404040),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Transform.scale(
                                    scale: 0.7, // Réduit de 0.8 à 0.7
                                    child: Checkbox(
                                      value: _acceptTerms,
                                      onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                                      activeColor: const Color(0xFFFFD700),
                                      checkColor: const Color(0xFF1A1A1A),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                      side: const BorderSide(color: Color(0xFF404040)),
                                    ),
                                  ),
                                  const SizedBox(width: 5), // Réduit de 6 à 5
                                  Expanded(
                                    child: RichText(
                                      text: const TextSpan(
                                        style: TextStyle(fontSize: 9, color: Color(0xFFB0B0B0)), // Réduit de 10 à 9
                                        children: [
                                          TextSpan(text: 'J\'accepte les '),
                                          TextSpan(
                                            text: 'conditions d\'utilisation',
                                            style: TextStyle(
                                              color: Color(0xFFFFD700),
                                              fontWeight: FontWeight.w500,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20), // Réduit de 22 à 20
                            
                            // Bouton d'inscription
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A1A1A),
                                  foregroundColor: Colors.white,
                                  elevation: 5, // Réduit de 6 à 5
                                  shadowColor: const Color(0xFFFFD700).withOpacity(0.3),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Réduit de 9 à 8
                                  padding: const EdgeInsets.symmetric(vertical: 12), // Réduit de 13 à 12
                                  side: const BorderSide(color: Color(0xFFFFD700), width: 1),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 13, // Réduit de 15 à 13
                                        width: 13, // Réduit de 15 à 13
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.3, // Réduit de 1.5 à 1.3
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.account_circle_rounded, size: 13), // Réduit de 15 à 13
                                          SizedBox(width: 6), // Réduit de 7 à 6
                                          Text(
                                            'CRÉER MON COMPTE',
                                            style: TextStyle(
                                              fontSize: 10, // Réduit de 11 à 10
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8, // Réduit de 0.9 à 0.8
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 13), // Réduit de 15 à 13
                            
                            // Séparateur élégant
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          const Color(0xFFFFD700).withOpacity(0.3),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10), // Réduit de 11 à 10
                                  child: Text(
                                    'OU',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 8, // Réduit de 9 à 8
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          const Color(0xFFFFD700).withOpacity(0.3),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 13), // Réduit de 15 à 13
                            
                            // Option de connexion
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 10), // Réduit de 11 à 10
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(8), // Réduit de 9 à 8
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Déjà un compte? ',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 9), // Réduit de 10 à 9
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Text(
                                      'Se connecter',
                                      style: TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9, // Réduit de 10 à 9
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 13), // Réduit de 15 à 13
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}