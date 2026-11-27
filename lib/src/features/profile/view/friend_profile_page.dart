import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../model/profile_model.dart';
import '../viewmodel/profile_ui_state.dart';
import '../viewmodel/profile_viewmodel.dart';
import 'profile_avatar.dart';

/// Read-only profile of a friend: photo, name, streak and pet.
class FriendProfilePage extends StatelessWidget {
  const FriendProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfileViewModel>().state;
    final profile = state.profile;

    return Scaffold(
      backgroundColor: AppColors.snow,
      body: Column(
        children: [
          _buildTopBar(context, state),
          Expanded(
            child: profile == null
                ? _buildEmpty(context, state)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      Center(
                        child: ProfileAvatar(
                          displayName: profile.displayName,
                          photoUrl: profile.photoUrl,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile.displayName.isEmpty ? 'Friend' : profile.displayName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      _buildStreakCard(context, profile),
                      const SizedBox(height: 16),
                      _buildPetCard(context, profile),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          state.errorMessage!,
                          textAlign: TextAlign.center,
                          style: _footerStyle(context).copyWith(color: AppColors.spicyPaprika),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  //Back on the left, connection and last update on the right
  Widget _buildTopBar(BuildContext context, ProfileUiState state) {
    final lastUpdated = state.lastUpdated;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.darkCoffee),
            tooltip: 'Back',
            onPressed: () => context.pop(),
          ),
          Expanded(child: Text('BUDDY', style: AppTextStyles.monoLabel)),
          if (state.isOffline) ...[
            const Icon(Icons.wifi_off, size: 16, color: AppColors.spicyPaprika),
            const SizedBox(width: 4),
          ],
          if (lastUpdated != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('Updated ${_formatUpdated(lastUpdated)}', style: _footerStyle(context)),
            ),
        ],
      ),
    );
  }

  //Loading, or the message that explains why there is nothing to show
  Widget _buildEmpty(BuildContext context, ProfileUiState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.spicyPaprika));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.isOffline) ...[
              const Icon(Icons.wifi_off, size: 40, color: AppColors.spicyPaprika),
              const SizedBox(height: 12),
            ],
            Text(
              state.errorMessage ?? '',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, ProfileModel profile) {
    return AppCard(
      color: Colors.white,
      shadowOffset: const Offset(0, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current streak', style: _footerStyle(context)),
              Text(
                '${profile.streak} ${profile.streak == 1 ? 'day' : 'days'}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(BuildContext context, ProfileModel profile) {
    return AppCard(
      color: AppColors.inputFill,
      shadowOffset: const Offset(0, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkCoffee, width: 2),
            ),
            child: const Icon(Icons.pets, size: 26, color: AppColors.spicyPaprika),
          ),
          const SizedBox(width: 12),
          Text(
            'Pet · Stage ${profile.petLevel}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13, letterSpacing: 0),
          ),
        ],
      ),
    );
  }

  TextStyle _footerStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 12, fontWeight: FontWeight.w600);
  }

  //Format the last update as "just now", "X min ago", "X h ago" or "X d ago"
  String _formatUpdated(DateTime lastUpdated) {
    final difference = DateTime.now().difference(lastUpdated);
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} h ago';
    } else {
      return '${difference.inDays} d ago';
    }
  }
}
