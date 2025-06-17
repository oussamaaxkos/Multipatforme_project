import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'my_sign_up.dart'; // Votre fichier d'inscription simplifié
import 'drawer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VisionCore ',
      theme: _buildTheme(),
      home: const AuthWrapper(),
    );
  }

  ThemeData _buildTheme() {
    const primaryColor = Color(0xFF1A1A1A); // Noir principal
    //const accentColor = Color(0xFF333333); // Gris foncé pour les accents
    const goldAccent = Color(0xFFFFD700); // Or pour les touches élégantes
    
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: goldAccent,
        surface: const Color(0xFF1E1E1E),
        onSurface: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9), // 12 * 0.75
          borderSide: const BorderSide(color: Color(0xFF404040), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9), // 12 * 0.75
          borderSide: const BorderSide(color: Color(0xFF404040), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9), // 12 * 0.75
          borderSide: const BorderSide(color: goldAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9), // 12 * 0.75
          borderSide: const BorderSide(color: Color(0xFFFF4444), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9), // 12 * 0.75
          borderSide: const BorderSide(color: Color(0xFFFF4444), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
        hintStyle: const TextStyle(color: Color(0xFF808080)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)), // 12 * 0.75
          padding: const EdgeInsets.symmetric(vertical: 12), // 16 * 0.75
          side: const BorderSide(color: Color(0xFFFFD700), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0F0F),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFD700),
                strokeWidth: 3,
              ),
            ),
          );
        }
        return snapshot.hasData ? const HomeScreen() : const AuthScreen();
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('VisionCore', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => _signOut(context),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF2A2A2A),
                foregroundColor: const Color(0xFFFFD700),
              ),
            ),
          ),
        ],
      ),
      drawer: const Menu(),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F0F),
              Color(0xFF1A1A1A),
              Color(0xFF0F0F0F),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD700).withOpacity(0.1),
                      const Color(0xFF1E1E1E),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.waving_hand_rounded,
                            color: Color(0xFF1A1A1A),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bienvenue !',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? 'Utilisateur',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFB0B0B0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Explorez nos services intelligents',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFB0B0B0),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Services Title
              const Text(
                'Nos Services',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              
              // Services Grid
              GridView.count(
                crossAxisCount: 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
                children: [
                  _buildServiceCard(
                    icon: Icons.smart_toy_rounded,
                    title: 'Assistant Virtuel',
                    description: 'IA conversationnelle avancée pour répondre à toutes vos questions',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  _buildServiceCard(
                    icon: Icons.visibility_rounded,
                    title: 'Œil Parlant',
                    description: 'Reconnaissance intelligente d\'objets dans vos images',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  _buildServiceCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Génération d\'Images',
                    description: 'Créez des images uniques avec notre IA générative',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Quick Stats
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF404040),
                    width: 1,
                  ),
                ),
          
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String description,
    required LinearGradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.transparent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.3,
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

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFD700),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFB0B0B0),
          ),
        ),
      ],
    );
  }

  void _navigateToService(BuildContext context, String service) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigation vers $service'),
        backgroundColor: const Color(0xFFFFD700),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    // TODO: Implement navigation to specific service pages
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await AuthService().signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFFF4444),
        ),
      );
    }
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // 10 * 0.75 ≈ 8
      ),
    );
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );
    } catch (e) {
      _showMessage(e.toString(), const Color(0xFFFF4444));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MySignUp()),
    );
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      _showMessage('Veuillez saisir votre email d\'abord', const Color(0xFFFF8800));
      return;
    }

    try {
      await _authService.resetPassword(_emailController.text);
      _showMessage('Email de réinitialisation envoyé !', const Color(0xFF00C853));
    } catch (e) {
      _showMessage(e.toString(), const Color(0xFFFF4444));
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
      style: const TextStyle(color: Colors.white, fontSize: 11), // 15 * 0.75 ≈ 11
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFFFD700), size: 18), // 24 * 0.75 = 18
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15), // 16*0.75=12, 20*0.75=15
        suffixIcon: hasToggle
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: const Color(0xFFB0B0B0),
                  size: 18, // 24 * 0.75 = 18
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
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
            padding: const EdgeInsets.symmetric(horizontal: 15), // 20 * 0.75 = 15
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 285), // 380 * 0.75 ≈ 285
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 30), // 40 * 0.75 = 30
                      // Logo élégant
                      Container(
                        width: 60, // 80 * 0.75 = 60
                        height: 60, // 80 * 0.75 = 60
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFE55C)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.3),
                              blurRadius: 15, // 20 * 0.75 = 15
                              spreadRadius: 1.5, // 2 * 0.75 = 1.5
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock_rounded,
                            size: 30, // 40 * 0.75 = 30
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30), // 40 * 0.75 = 30
                      // Card d'authentification
                      Container(
                        padding: const EdgeInsets.all(23), // 30 * 0.75 ≈ 23
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(15), // 20 * 0.75 = 15
                          border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 19, // 25 * 0.75 ≈ 19
                              offset: const Offset(0, 8), // 10 * 0.75 ≈ 8
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bienvenue',
                              style: TextStyle(
                                fontSize: 21, // 28 * 0.75 = 21
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6), // 8 * 0.75 = 6
                            Text(
                              'Connectez-vous pour continuer',
                              style: TextStyle(
                                fontSize: 11, // 14 * 0.75 ≈ 11
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 23), // 30 * 0.75 ≈ 23
                            
                            // Champs de saisie
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
                            const SizedBox(height: 15), // 20 * 0.75 = 15
                            
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
                            const SizedBox(height: 8), // 10 * 0.75 ≈ 8
                            
                            // Options supplémentaires
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Transform.scale(
                                      scale: 0.85, // 1.1 * 0.75 ≈ 0.85
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) => setState(() => _rememberMe = value ?? false),
                                        activeColor: const Color(0xFFFFD700),
                                        checkColor: const Color(0xFF1A1A1A),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)), // 4 * 0.75 = 3
                                        side: const BorderSide(color: Color(0xFF404040)),
                                      ),
                                    ),
                                    const Text(
                                      'Se souvenir de moi',
                                      style: TextStyle(fontSize: 11, color: Color(0xFFB0B0B0)), // 14 * 0.75 ≈ 11
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: _resetPassword,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(8, 8), // 10 * 0.75 = 8
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Mot de passe oublié?',
                                    style: TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontSize: 11, // 14 * 0.75 ≈ 11
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 23), // 30 * 0.75 ≈ 23
                            
                            // Bouton de connexion
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A1A1A),
                                  foregroundColor: Colors.white,
                                  elevation: 6, // 8 * 0.75 = 6
                                  shadowColor: const Color(0xFFFFD700).withOpacity(0.3),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)), // 12 * 0.75 = 9
                                  padding: const EdgeInsets.symmetric(vertical: 14), // 18 * 0.75 ≈ 14
                                  side: const BorderSide(color: Color(0xFFFFD700), width: 1),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 15, // 20 * 0.75 = 15
                                        width: 15, // 20 * 0.75 = 15
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5, // 2 * 0.75 = 1.5
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                                        ),
                                      )
                                    : const Text(
                                        'SE CONNECTER',
                                        style: TextStyle(
                                          fontSize: 11, // 15 * 0.75 ≈ 11
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.9, // 1.2 * 0.75 = 0.9
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 15), // 20 * 0.75 = 15
                            
                            // Option d'inscription
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Pas encore de compte? ',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 11), // 14 * 0.75 ≈ 11
                                ),
                                TextButton(
                                  onPressed: _navigateToSignUp,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(8, 8), // 10 * 0.75 = 8
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'S\'inscrire',
                                    style: TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11, // 14 * 0.75 ≈ 11
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15), // 20 * 0.75 = 15
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
