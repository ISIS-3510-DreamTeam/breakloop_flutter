
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../model/pet_mood.dart';
import '../viewmodel/pet_viewmodel.dart';
import 'pet_picker_dialog.dart';

class PetCard extends StatefulWidget {
  const PetCard({super.key});

  @override
  State<PetCard> createState() => _PetCardState();
}

class _PetCardState extends State<PetCard> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) context.read<PetViewModel>().onAppResumed();
  }

  Future<void> _openPicker() async {
    final vm = context.read<PetViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    vm.loadCatalog(); // refresca por si antes no había internet

    final petId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => ListenableBuilder(
        listenable: vm,
        builder: (_, __) => PetPickerDialog(
          pets: vm.catalog,
          onPick: (id) => Navigator.pop(dialogContext, id),
          onDismiss: () => Navigator.pop(dialogContext),
        ),
      ),
    );
    if (petId == null) return;

    final online = await vm.changePet(petId);
    if (!online) {
      messenger.showSnackBar(const SnackBar(
        content: Text("You're offline. Your pet will change when your connection is back."),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PetViewModel>();
    final textTheme = Theme.of(context).textTheme;
    final name = vm.nameOf(vm.currentPetId ?? vm.pendingPetId);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('YOUR PET', style: textTheme.labelLarge), // texto provisional
              GestureDetector(
                onTap: _openPicker,
                child: const Icon(Icons.pets_outlined, size: 18, color: AppColors.darkCoffee),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!vm.hasPet)
            TextButton(onPressed: _openPicker, child: const Text('Choose your pet')) // provisional
          else ...[
            if (vm.image != null)
              Center(
                child: SizedBox(
                  height: 140,
                  child: _AnimatedPet(image: vm.image!, mood: vm.mood),
                ),
              ),
            const SizedBox(height: 8),
            if (vm.mood == PetMood.happy)
              Text('$name is happy! Keep it up.', style: textTheme.bodyLarge) // provisional
            else
              Text(
                'Earn ${vm.xpGoal - vm.xpToday} more XP today to cheer $name up.',
                style: textTheme.bodyLarge,
              ),
            Text(
              'XP today: ${vm.xpToday} / ${vm.xpGoal}',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.darkCoffee),
            ),
            if (vm.pendingPetId != null) ...[
              const SizedBox(height: 8),
              Text(
                "${vm.nameOf(vm.pendingPetId)} will arrive as soon as you're online.",
                style: textTheme.bodyMedium?.copyWith(color: AppColors.goldenOrange),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Animación idle: happy = salto rápido con estiramiento; sad = hundimiento lento con vaivén.
class _AnimatedPet extends StatefulWidget {
  const _AnimatedPet({required this.image, required this.mood});

  final Uint8List image;
  final PetMood mood;

  @override
  State<_AnimatedPet> createState() => _AnimatedPetState();
}

class _AnimatedPetState extends State<_AnimatedPet> with TickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(vsync: this); // offsetY + stretch
  late final AnimationController _sway = AnimationController(vsync: this); // tilt

  bool get _happy => widget.mood == PetMood.happy;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant _AnimatedPet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) _start();
  }

  void _start() {
    _bounce
      ..duration = Duration(milliseconds: _happy ? 450 : 1600)
      ..value = 0
      ..repeat(reverse: true);
    _sway
      ..duration = const Duration(milliseconds: 2200)
      ..value = 0
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounce.dispose();
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bounce, _sway]),
      builder: (context, child) {
        final eased = Curves.fastOutSlowIn.transform(_bounce.value);
        final offsetY = lerpDouble(0, _happy ? -10 : 4, eased)!;
        final stretch = lerpDouble(1, _happy ? 1.05 : 0.97, eased)!;
        final tiltDeg = _happy ? 0.0 : lerpDouble(-3, 3, _sway.value)!; // lineal

        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Transform(
            alignment: Alignment.bottomCenter, // se comprime desde los pies
            transform: Matrix4.rotationZ(tiltDeg * math.pi / 180)
              ..multiply(Matrix4.diagonal3Values(1, stretch, 1)),
            child: child,
          ),
        );
      },
      child: Image.memory(
        widget.image,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none, // mantiene nítido el pixel art
        gaplessPlayback: true,
        semanticLabel: 'Your pet is ${widget.mood.name}',
      ),
    );
  }
}