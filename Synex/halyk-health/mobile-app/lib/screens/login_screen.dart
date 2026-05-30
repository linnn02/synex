import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.apiService,
    required this.onLoggedIn,
  });

  final ApiService apiService;
  final ValueChanged<AppUser> onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'patient@test.kz');
  final _passwordController = TextEditingController(text: '123456');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await widget.apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      widget.onLoggedIn(user);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A884),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'HH',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Halyk Health', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                            Text('Раздел здоровья в Halyk Super App'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Пароль'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, style: const TextStyle(color: Color(0xFF9E2A1B))),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _login,
                      icon: const Icon(Icons.login),
                      label: Text(_loading ? 'Вход...' : 'Войти'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ИИ-агент не заменяет врача. Он объясняет назначение, созданное врачом. Перед заменой препарата проконсультируйтесь с врачом или фармацевтом.',
                    style: TextStyle(color: Color(0xFF60727F), height: 1.45),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

