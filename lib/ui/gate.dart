import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../app/core_state.dart';
import 'home.dart';


class Gate extends StatelessWidget {
  const Gate({super.key});

  @override
  Widget build(BuildContext context) {
    final coreState = context.watch<CoreState>();

    if (coreState.useGuestMode) {
      return const Root();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0B0B10),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const Root();
        }

        return const LoginScreen();
      },
    );
  }
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CoreState>();
    return state.onboarded ? const Home() : const OnboardScreen();
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CoreState>();
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B10),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, size: 98, color: Color(0xFFA3E635)),
                const SizedBox(height: 18),
                const Text(
                  'Sign in to sync your 1% Better progress',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Use your Google account to keep tasks, streaks, gems, and VIP progress safe in Firebase.',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 18),
                  Text(state.error!, style: const TextStyle(color: Colors.redAccent)),
                ],
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: state.busy || !state.canLoginWithGoogle ? null : () => state.login(),
                  icon: const Icon(Icons.login),
                  label: Text(
                    state.busy
                        ? 'Signing in…'
                        : state.canLoginWithGoogle
                            ? 'Sign in with Google'
                            : 'Google Sign-In unavailable',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                    backgroundColor: const Color(0xFFA3E635),
                    foregroundColor: const Color(0xFF0B0B10),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: state.busy
                      ? null
                      : () async {
                          state.continueAsGuest();
                          await state.onboard();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🚀 Welcome to 1% Better! Start building your streak.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFA3E635), width: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  ),
                  child: const Text(
                    'CONTINUE AS GUEST',
                    style: TextStyle(color: Color(0xFFA3E635), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Guest mode: Use the app locally without signing in. Your progress will not be backed up to the cloud.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardScreen extends StatefulWidget {
  const OnboardScreen({super.key});

  @override
  State<OnboardScreen> createState() => _OnboardScreenState();
}

class _OnboardScreenState extends State<OnboardScreen> {
  Future<void> _showTimePickerDialog() async {
    if (!mounted) return;

    final selected = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );

    if (!mounted) return;

    final coreState = context.read<CoreState>();

    if (selected != null) {
      await coreState.setDailyReminder(selected);
    } else {
      await coreState.setDailyReminder(const TimeOfDay(hour: 8, minute: 0));
    }

    if (!mounted) return;
    await coreState.onboard();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Home()));
  }

  Future<void> _skipOnboarding() async {
    final coreState = context.read<CoreState>();
    await coreState.onboard();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Home()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B10),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, size: 64, color: Color(0xFFA3E635)),
                const SizedBox(height: 20),
                const Text(
                  'Welcome to 1% Better',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Build strong daily habits, earn XP, collect gems, and keep your streak alive.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                const Text(
                  'Select your daily reminder time to get motivated every day!',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _showTimePickerDialog,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                    backgroundColor: const Color(0xFFA3E635),
                  ),
                  child: const Text(
                    'PICK REMINDER TIME',
                    style: TextStyle(color: Color(0xFF0B0B10), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _skipOnboarding,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: Color(0xFFA3E635)),
                  ),
                  child: const Text(
                    'SKIP FOR NOW',
                    style: TextStyle(color: Color(0xFFA3E635)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




