
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../core/network/network_checker.dart';
import '../data/pet_repository.dart';
import '../model/calculate_pet_mood_use_case.dart';
import '../model/pet_dto.dart';
import '../model/pet_mood.dart';

class PetViewModel extends ChangeNotifier {
  PetViewModel({
    required this._repository,
    required Stream<int> Function(DateTime startOfDay) observeActivityXpSince,
    required Stream<int> Function(DateTime startOfDay) observeFocusXpSince,
    this._calculateMood = const CalculatePetMoodUseCase(),
  })  : _observeActivityXp = observeActivityXpSince,
        _observeFocusXp = observeFocusXpSince {
    loadCatalog();
    _observePet();
    _observeXpToday();
    _repository.startListeningToBackground();
    _repository.scheduleSync();
  }

  final PetRepository _repository;
  final Stream<int> Function(DateTime) _observeActivityXp;
  final Stream<int> Function(DateTime) _observeFocusXp;
  final CalculatePetMoodUseCase _calculateMood;

  StreamSubscription<dynamic>? _stateSub;
  final List<StreamSubscription<int>> _xpSubs = [];
  DateTime? _xpDay;
  int _stateRequestId = 0;
  bool _disposed = false;

  // Estado de UI (equivale a PetUiState)
  String? currentPetId;
  String? pendingPetId;
  PetMood mood = PetMood.sad;
  Uint8List? image;
  int xpToday = 0;
  int get xpGoal => CalculatePetMoodUseCase.dailyXpGoal;
  List<PetDto> catalog = const [];

  bool get hasPet => currentPetId != null || pendingPetId != null;

  String nameOf(String? petId) {
    for (final pet in catalog) {
      if (pet.id == petId) return pet.name;
    }
    return petId ?? '';
  }

  Future<void> loadCatalog() async {
    final pets = await _repository.getCatalog();
    if (_disposed) return;
    catalog = pets;
    notifyListeners();
  }

  /// Devuelve false si no hay conexión (la vista muestra el aviso, antes era un Toast).
  Future<bool> changePet(String petId) async {
    await _repository.changePet(petId);
    return NetworkChecker.isOnline();
  }

  /// Llamar cuando la app vuelve a primer plano.
  void onAppResumed() {
    _repository.notifyExternalChange(); // por si el worker escribió y el aviso no llegó
    if (_startOfToday() != _xpDay) _observeXpToday(); // cruzó la medianoche
  }

  // Reacciona a cada cambio guardado (mascota nueva, mood, elección pendiente).
  void _observePet() {
    _stateSub = _repository.observeState().listen((state) async {
      final requestId = ++_stateRequestId;
      final bytes = await _repository.getImageBytes(state.mood);
      if (_disposed || requestId != _stateRequestId) return; // llegó uno más reciente
      currentPetId = state.currentPetId;
      pendingPetId = state.pendingPetId;
      mood = state.mood;
      image = bytes;
      notifyListeners();
    });
  }

  // Suma el XP de hoy (actividades offline + sesiones de foco) y actualiza el mood.
  void _observeXpToday() {
    for (final sub in _xpSubs) {
      sub.cancel();
    }
    _xpSubs.clear();

    final startOfDay = _startOfToday();
    _xpDay = startOfDay;
    int? activityXp;
    int? focusXp;

    void onChanged() {
      if (activityXp == null || focusXp == null) return; // como combine: espera ambos
      xpToday = activityXp! + focusXp!;
      notifyListeners();
      unawaited(_repository.updateMood(_calculateMood.calculate(xpToday)));
    }

    _xpSubs.add(_observeActivityXp(startOfDay).listen((v) {
      activityXp = v;
      onChanged();
    }));
    _xpSubs.add(_observeFocusXp(startOfDay).listen((v) {
      focusXp = v;
      onChanged();
    }));
  }

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _disposed = true;
    _stateSub?.cancel();
    for (final sub in _xpSubs) {
      sub.cancel();
    }
    _repository.dispose();
    super.dispose();
  }
}