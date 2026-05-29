import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/entitlement_service.dart';
import '../services/firestore_service.dart';
import 'onboarding_screen.dart';
import 'today_screen.dart';

class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  late Future<_BootstrapState> _future;
  bool _completedOnboardingThisSession = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_BootstrapState> _load() async {
    final user = await _trySignIn();

    if (user == null) {
      return const _BootstrapState.localOnly();
    }

    try {
      await EntitlementService.instance.configure(appUserId: user.uid);
    } catch (_) {
      // Purchase status should not block the core learning flow.
    }

    var profileUnavailable = false;
    final profile = await FirestoreService.instance.getProfile(user.uid)
        .catchError((Object error) {
          profileUnavailable = true;
          debugPrint('Sivra startup profile unavailable: $error');
          return null;
        });

    return _BootstrapState(
      uid: user.uid,
      hasProfile: profile?.focusAreas.isNotEmpty ?? false,
      localOnly: profileUnavailable,
    );
  }

  Future<User?> _trySignIn() async {
    try {
      return await AuthService.instance.ensureSignedIn();
    } catch (error) {
      debugPrint('Sivra startup auth unavailable: $error');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapState>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final state = snapshot.data;
        if (state == null) {
          return const Scaffold(body: Center(child: Text('Unable to start')));
        }

        if (state.hasProfile && _completedOnboardingThisSession) {
          return const TodayScreen();
        }

        return OnboardingScreen(
          uid: state.uid,
          allowLocalCompletion: state.localOnly,
          analyticsEnabled: !state.localOnly,
          onCompleted: () {
            _completedOnboardingThisSession = true;
            setState(() {
              _future = Future.value(
                _BootstrapState(uid: state.uid, hasProfile: true),
              );
            });
          },
          onCompletedWithFocus: state.localOnly
              ? (focusAreas) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => TodayScreen(
                        initialFocusAreas: focusAreas,
                        loadRemote: false,
                      ),
                    ),
                  );
                }
              : null,
        );
      },
    );
  }
}

class _BootstrapState {
  final String uid;
  final bool hasProfile;
  final bool localOnly;

  const _BootstrapState({
    required this.uid,
    required this.hasProfile,
    this.localOnly = false,
  });

  const _BootstrapState.localOnly()
    : uid = 'local-startup',
      hasProfile = false,
      localOnly = true;
}
