
import 'package:flutter/material.dart';

import '../model/pet_dto.dart';

class PetPickerDialog extends StatelessWidget {
  const PetPickerDialog({
    super.key,
    required this.pets,
    required this.onPick,
    required this.onDismiss,
  });

  final List<PetDto> pets;
  final void Function(String petId) onPick;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose your pet'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pets.isEmpty)
            const Text('Connect to the internet once to see the available pets.'),
          for (final pet in pets)
            TextButton(onPressed: () => onPick(pet.id), child: Text(pet.name)),
        ],
      ),
      actions: [TextButton(onPressed: onDismiss, child: const Text('Cancel'))],
    );
  }
}