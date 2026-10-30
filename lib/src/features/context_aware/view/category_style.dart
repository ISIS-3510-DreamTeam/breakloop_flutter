import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/activity_category.dart';

//Text, color and icon used to show each category in the views
String categoryLabel(ActivityCategory category) {
  switch (category) {
    case ActivityCategory.move:
      return 'Move';
    case ActivityCategory.create:
      return 'Create';
    case ActivityCategory.relax:
      return 'Relax';
    case ActivityCategory.socialize:
      return 'Socialize';
  }
}

Color categoryColor(ActivityCategory category) {
  switch (category) {
    case ActivityCategory.move:
      return AppColors.fern100;
    case ActivityCategory.create:
      return AppColors.paprika100;
    case ActivityCategory.relax:
      return AppColors.golden100;
    case ActivityCategory.socialize:
      return AppColors.neutral100;
  }
}

IconData categoryIcon(ActivityCategory category) {
  switch (category) {
    case ActivityCategory.move:
      return Icons.directions_run_outlined;
    case ActivityCategory.create:
      return Icons.brush_outlined;
    case ActivityCategory.relax:
      return Icons.self_improvement_outlined;
    case ActivityCategory.socialize:
      return Icons.groups_outlined;
  }
}
