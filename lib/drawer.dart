import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'assistant_virtual.dart';
import 'auth_service.dart';
import 'object_detection.dart';
import 'génerateur_image.dart';

// Constantes de couleurs pour une meilleure maintenabilité
class AppColors {
  static const Color primaryDark = Color(0xFF1A1A1A);
  static const Color secondaryDark = Color(0xFF2A2A2A);
  static const Color backgroundDark = Color(0xFF0F0F0F);
  static const Color itemBackground = Color(0xFF1E1E1E);
  static const Color accent = Color(0xFFFFD700);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color border = Color(0xFF404040);
  static const Color error = Color(0xFFFF4444);
}

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  String userEmail = '';
  String userName = '';
  bool isLoading = true;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        // Utilisateur déconnecté, rediriger vers la page de connexion
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (route) => false,
          );
        }
      } else {
        _loadUserData();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('clients')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          if (mounted) {
            setState(() {
              userEmail = userData['email'] ?? currentUser.email ?? 'Email non disponible';
              userName = userData['name'] ?? '';
              isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              userEmail = currentUser.email ?? 'Email non disponible';
              userName = currentUser.displayName ?? '';
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            userEmail = 'Non connecté';
            userName = '';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des données utilisateur: $e');
      if (mounted) {
        setState(() {
          userEmail = 'Erreur de chargement';
          userName = '';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.primaryDark,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.secondaryDark,
                  AppColors.primaryDark,
                  AppColors.backgroundDark,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent,
                  blurRadius: 15,
                  spreadRadius: -5,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundImage: const AssetImage('images/profil.jpg'),
                    backgroundColor: AppColors.secondaryDark,
                    radius: 30,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                            ),
                          )
                        : null,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (userName.isNotEmpty && userName != 'Nom non disponible')
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          userEmail.isEmpty ? 'Chargement...' : userEmail,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: userName.isNotEmpty && userName != 'Nom non disponible' ? 12 : 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryDark,
                    AppColors.backgroundDark,
                    AppColors.primaryDark,
                  ],
                ),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 10),
                  _buildMenuItem(
                    icon: Icons.home_rounded,
                    title: 'Accueil',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.smart_toy_rounded,
                    title: 'Assistant Virtual',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AssistantVirtuel(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.category_rounded,
                    title: 'Œil Parlant',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SimpleObjectDetection(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.image_rounded,
                    title: 'Génération des images',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GenerateurImage(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildLogoutButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSubItem = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSubItem ? 4 : 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.itemBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.accent,
          size: isSubItem ? 20 : 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSubItem ? 13 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        hoverColor: AppColors.secondaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        trailing: null,
      ),
    );
  }

  Widget _buildDivider() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.accent.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.itemBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.logout_rounded,
          color: AppColors.error,
          size: 22,
        ),
        title: const Text(
          'Déconnexion',
          style: TextStyle(
            color: AppColors.error,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () => _showLogoutDialog(),
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.itemBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(
              color: AppColors.accent,
              width: 1,
            ),
          ),
          title: const Text(
            'Déconnexion',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _performLogout();
    }
  }

  Future<void> _performLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await AuthService().signOut();
      
      if (mounted) {
        Navigator.pop(context);
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}