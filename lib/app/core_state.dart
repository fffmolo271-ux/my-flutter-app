import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../services/notification_service.dart';

class CoreState extends ChangeNotifier {
  final bool firebaseEnabled;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final Box _box;
  final GoogleSignIn _googleSignIn;

  List<Map<String, dynamic>> tasks = [];
  int xp = 0;
  int level = 1;
  int gems = 50;
  bool vip = false;
  int streak = 0;
  int achievements = 0;
  int reminderHour = 8;
  int reminderMinute = 0;
  bool onboarded = false;
  DateTime? lastDaily;
  bool busy = false;
  bool useGuestMode = false;
  bool hasStreakArmor = false;
  String? error;
  DateTime? _lastMidnightReset;
  Timer? _midnightResetTimer;

  bool _mutationInProgress = false;
  final Set<String> _toggleInFlightTaskIds = <String>{};

  AudioPlayer? _audioPlayer;

  CoreState(
    this.firebaseEnabled, {
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    Box? box,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
        _box = box ?? Hive.box('vault'),
        // google_sign_in v6: avoid `GoogleSignIn.instance` deprecated/static accessor.
        _googleSignIn = googleSignIn ?? GoogleSignIn() {

    _loadLocalData();
    _initializeMidnightReset();

    if (firebaseEnabled && !useGuestMode) {
      _auth.authStateChanges().listen((user) {
        if (user != null) {
          _mergeRemoteData();
        }
      });
    }
  }

  bool get isSignedIn => firebaseEnabled && _auth.currentUser != null && !useGuestMode;

  bool get canLoginWithGoogle {
    if (!firebaseEnabled) return false;
    return kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
  }

  String get userName => useGuestMode ? 'Guest User' : (_auth.currentUser?.displayName ?? 'Guest');
  String get userEmail => useGuestMode ? 'local-only' : (_auth.currentUser?.email ?? '');

  int get xpNeed => max(1, (100 * pow(level, 1.35)).toInt());

  TimeOfDay get reminderTime => TimeOfDay(hour: reminderHour, minute: reminderMinute);

  String get rank {
    if (level < 5) return 'Novice';
    if (level < 15) return 'Warrior';
    if (level < 30) return 'Elite';
    return 'Legend';
  }

  void _initializeMidnightReset() {
    _checkAndResetAtMidnight();
    _midnightResetTimer?.cancel();
    _midnightResetTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAndResetAtMidnight();
    });
  }

  Future<void> _checkAndResetAtMidnight() async {
    if (_mutationInProgress) return;

    final now = DateTime.now();

    if (_lastMidnightReset == null || _lastMidnightReset!.day != now.day) {
      if (lastDaily != null && now.difference(lastDaily!).inDays >= 1) {
        if (!hasStreakArmor) {
          streak = 0;
        } else {
          hasStreakArmor = false;
        }
      }

      for (var task in tasks) {
        task['done'] = false;
      }

      _lastMidnightReset = now;
      await _saveData();
      notifyListeners();
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      debugPrint('Google signIn() failed: $e');
      return null;
    }
  }


  Future<void> login() async {
    if (busy) return;
    if (!canLoginWithGoogle) {
      error = 'Google Sign-In is not supported on this platform.';
      notifyListeners();
      return;
    }

    busy = true;
    error = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      // google_sign_in v6 uses an async auth object; idToken may be null unless requested by server/client config.



      if (idToken == null) {
        error = 'Google authentication failed. Please try again.';
        return;
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      await _auth.signInWithCredential(credential);
      await _mergeRemoteData();
    } catch (e) {
      error = 'Unable to sign in. Please try again.';
      debugPrint('Login error: $e');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (busy) return;
    busy = true;
    notifyListeners();

    try {
      if (firebaseEnabled) {
        await _googleSignIn.signOut();
        await _auth.signOut();
      }
      useGuestMode = false;
    } catch (e) {
      debugPrint('Sign out error: $e');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void continueAsGuest() {
    useGuestMode = true;
    notifyListeners();
  }

  Future<void> onboard() async {
    onboarded = true;
    await _saveData();
    notifyListeners();
  }

  void addTask(String title) {
    final text = title.trim();
    if (text.isEmpty) return;

    tasks.insert(
      0,
      {
        'id': const Uuid().v4(),
        'title': text,
        'done': false,
      },
    );
    notifyListeners();
    unawaited(_saveData());
  }

  Future<void> _ensureAudioPlayer() async {
    _audioPlayer ??= AudioPlayer();
  }

  Future<void> playClickBass() async {
    try {
      await _ensureAudioPlayer();
      await _audioPlayer?.play(AssetSource('assets/sounds/click_bass.mp3'));
    } catch (e) {
      debugPrint('Audio play failed: $e');
    }
  }

  Future<void> toggleTask(String id) async {
    final index = tasks.indexWhere((task) => task['id'] == id);
    if (index == -1) return;

    if (_toggleInFlightTaskIds.contains(id)) return;
    _toggleInFlightTaskIds.add(id);

    _mutationInProgress = true;
    try {
      final prevDone = tasks[index]['done'] == true;
      final newDone = !prevDone;
      tasks[index]['done'] = newDone;

      final delta = vip ? 50 : 25;
      if (newDone) {
        xp += delta;
        achievements = (achievements + 1).clamp(0, 999999);
        _updateDailyProgress();
        _levelUp();
        unawaited(NotificationService.showTaskCompletedNotification(delta));
        unawaited(playClickBass());
      } else {
        xp = (xp - delta).clamp(0, 999999);
        achievements = (achievements - 1).clamp(0, 999999);
      }

      // Update UI immediately; persist changes off the critical interaction path.
      notifyListeners();
      await _saveLocal(notify: false);
      unawaited(_saveRemote());
    } finally {
      _mutationInProgress = false;
      _toggleInFlightTaskIds.remove(id);
    }
  }

  void activateVip() {
    if (vip) return;
    vip = true;
    notifyListeners();
    unawaited(_saveData());
  }

  void reward(int value) {
    gems = (gems + value).clamp(0, 999999);
    notifyListeners();
    unawaited(_saveData());
  }

  void purchaseStreakArmor() {
    hasStreakArmor = true;
    notifyListeners();
    unawaited(_saveData());
  }

  void purchaseGodModePack() {
    _box.put('godModeActive', true);
    gems += 50;
    notifyListeners();
    unawaited(_saveData());
  }

  void purchaseGemPack(int gemAmount) {
    gems += gemAmount;
    notifyListeners();
    unawaited(_saveData());
  }

  void _levelUp() {
    while (xp >= xpNeed) {
      xp -= xpNeed;
      level += 1;
      gems += 10;
    }
  }

  void _updateDailyProgress() {
    final now = DateTime.now();
    final isSameDay = lastDaily != null && now.year == lastDaily!.year && now.month == lastDaily!.month && now.day == lastDaily!.day;

    if (!isSameDay) {
      if (lastDaily != null && now.difference(lastDaily!).inDays == 1) {
        streak += 1;
      } else {
        streak = 1;
      }
      gems += 5;
    }

    lastDaily = now;
  }

  List<Map<String, dynamic>> _normalizeTasks(dynamic raw) {
    if (raw is! Iterable) return [];
    return raw.whereType<Map<dynamic, dynamic>>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<void> _mergeRemoteData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _db.collection('users').doc(user.uid).get();
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;

      final remoteTasks = _normalizeTasks(data['tasks']);
      if (remoteTasks.isNotEmpty && tasks.isEmpty) {
        tasks = remoteTasks;
      }

      xp = data['xp'] is int ? data['xp'] as int : xp;
      level = data['level'] is int ? data['level'] as int : level;
      gems = data['gems'] is int ? data['gems'] as int : gems;
      vip = data['vip'] is bool ? data['vip'] as bool : vip;
      streak = data['streak'] is int ? data['streak'] as int : streak;
      achievements = data['achievements'] is int ? data['achievements'] as int : achievements;
      reminderHour = data['dailyReminderHour'] is int ? data['dailyReminderHour'] as int : reminderHour;
      reminderMinute = data['dailyReminderMinute'] is int ? data['dailyReminderMinute'] as int : reminderMinute;
      useGuestMode = data['useGuestMode'] is bool ? data['useGuestMode'] as bool : useGuestMode;
      hasStreakArmor = data['hasStreakArmor'] is bool ? data['hasStreakArmor'] as bool : hasStreakArmor;

      final lastDailyValue = data['lastDaily'] as String?;
      lastDaily = lastDailyValue != null ? DateTime.tryParse(lastDailyValue) : lastDaily;

      onboarded = data['onboarded'] is bool ? data['onboarded'] as bool : onboarded;

      await _saveLocal(notify: false);
      await _saveRemote();
      notifyListeners();
    } catch (e) {
      debugPrint('Remote merge failed: $e');
    }
  }

  Future<void> _saveData() async {
    await _saveLocal();
    await _saveRemote();
  }

  Future<void> setDailyReminder(TimeOfDay time) async {
    reminderHour = time.hour;
    reminderMinute = time.minute;
    await _saveLocal();
    await NotificationService.scheduleDailyMotivation(hour: reminderHour, minute: reminderMinute);
  }

  Future<void> _saveLocal({bool notify = true}) async {
    final data = {
      'tasks': tasks,
      'xp': xp,
      'level': level,
      'gems': gems,
      'vip': vip,
      'streak': streak,
      'achievements': achievements,
      'lastDaily': lastDaily?.toIso8601String(),
      'onboarded': onboarded,
      'dailyReminderHour': reminderHour,
      'dailyReminderMinute': reminderMinute,
      'useGuestMode': useGuestMode,
      'hasStreakArmor': hasStreakArmor,
      'lastMidnightReset': _lastMidnightReset?.toIso8601String(),
    };
    await _box.putAll(data);
    if (notify) notifyListeners();
  }

  Future<void> _saveRemote() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db.collection('users').doc(user.uid).set(
            {
              'tasks': tasks,
              'xp': xp,
              'level': level,
              'gems': gems,
              'vip': vip,
              'streak': streak,
              'achievements': achievements,
              'lastDaily': lastDaily?.toIso8601String(),
              'onboarded': onboarded,
              'dailyReminderHour': reminderHour,
              'dailyReminderMinute': reminderMinute,
              'useGuestMode': useGuestMode,
              'hasStreakArmor': hasStreakArmor,
            },
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('Firestore sync failed: $e');
    }
  }

  void _loadLocalData() {
    final rawTasks = _box.get('tasks', defaultValue: []);
    tasks = _normalizeTasks(rawTasks);

    xp = _box.get('xp', defaultValue: 0) as int;
    level = _box.get('level', defaultValue: 1) as int;
    gems = _box.get('gems', defaultValue: 50) as int;
    vip = _box.get('vip', defaultValue: false) as bool;
    streak = _box.get('streak', defaultValue: 0) as int;
    achievements = _box.get('achievements', defaultValue: 0) as int;
    onboarded = _box.get('onboarded', defaultValue: false) as bool;
    reminderHour = _box.get('dailyReminderHour', defaultValue: 8) as int;
    reminderMinute = _box.get('dailyReminderMinute', defaultValue: 0) as int;
    useGuestMode = _box.get('useGuestMode', defaultValue: false) as bool;
    hasStreakArmor = _box.get('hasStreakArmor', defaultValue: false) as bool;

    final lastDailyString = _box.get('lastDaily') as String?;
    lastDaily = lastDailyString != null ? DateTime.tryParse(lastDailyString) : null;

    final lastResetString = _box.get('lastMidnightReset') as String?;
    _lastMidnightReset = lastResetString != null ? DateTime.tryParse(lastResetString) : null;

    notifyListeners();
  }

  @override
  void dispose() {
    _midnightResetTimer?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }
}

