import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';

/// Login screen with ESEO credentials
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mfaCodeController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _mfaCodeController.dispose();
    super.dispose();
  }

  Future<void> _navigateToHome() async {
    TextInput.finishAutofillContext();

    try {
      await NotificationService.initialize();
    } catch (e) {
      print('Notification initialization failed: $e');
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      await _navigateToHome();
    } else if (authProvider.mfaRequired) {
      // MFA required — UI will switch automatically via Consumer
      _mfaCodeController.clear();
      if (authProvider.mfaType == 'push') {
        _waitForPush();
      }
    } else if (authProvider.error != null) {
      _showError(authProvider.error!);
    }
  }

  Future<void> _verifyMfaCode() async {
    final code = _mfaCodeController.text.trim();
    if (code.length != 6) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyMfa(code);

    if (!mounted) return;

    if (success) {
      await _navigateToHome();
    } else if (authProvider.error != null) {
      _showError(authProvider.error!);
      // Keep MFA screen open so user can retry
    }
  }

  Future<void> _waitForPush() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.waitForPushApproval();

    if (!mounted) return;

    if (success) {
      await _navigateToHome();
    } else if (authProvider.error != null) {
      _showError(authProvider.error!);
    }
  }

  void _cancelMfa() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.cancelMfa();
    _mfaCodeController.clear();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.mfaRequired) {
                  return _buildMfaView(auth);
                }
                return _buildLoginView(auth);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginView(AuthProvider auth) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo
            Image.asset(
              'assets/ESEO-App.png',
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'ESEO App',
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Connectez-vous avec vos identifiants ESEO',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Email field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre email';
                }
                if (!value.contains('@')) {
                  return 'Email invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre mot de passe';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Login button
            if (auth.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _login,
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('Se connecter'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMfaView(AuthProvider auth) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icon
        Icon(
          Icons.security,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          'Vérification requise',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        if (auth.mfaType == 'totp') ...[
          // TOTP — code 6 chiffres
          Text(
            'Entrez le code à 6 chiffres de votre application d\'authentification',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Code input
          TextFormField(
            controller: _mfaCodeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: theme.textTheme.headlineMedium?.copyWith(
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: '000000',
              counterText: '',
              prefixIcon: Icon(Icons.pin_outlined),
            ),
            onChanged: (value) {
              if (value.length == 6) {
                _verifyMfaCode();
              }
            },
          ),
          const SizedBox(height: 24),

          if (auth.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton(
              onPressed: _verifyMfaCode,
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Vérifier'),
              ),
            ),
        ] else if (auth.mfaType == 'push') ...[
          // Push — attente d'approbation
          Text(
            'Approuvez la connexion sur votre téléphone',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (auth.mfaData != null) ...[
            const SizedBox(height: 8),
            Text(
              'Numéro : ${auth.mfaData}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),

          if (auth.isLoading)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('En attente d\'approbation...'),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: _waitForPush,
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Réessayer'),
              ),
            ),
        ],

        const SizedBox(height: 16),

        // Cancel button
        TextButton(
          onPressed: auth.isLoading ? null : _cancelMfa,
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}
