import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pill.dart';
import '../../pet/view/pet_thumbnail.dart';
import '../viewmodel/profile_ui_state.dart';
import '../viewmodel/profile_viewmodel.dart';
import 'profile_avatar.dart';

/// Own profile. The same screen shows the profile and, in edit mode,
/// lets the user change the name and the photo.
class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final _nameController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final state = vm.state;
    final profile = state.profile;

    return Scaffold(
      backgroundColor: AppColors.snow,
      body: Column(
        children: [
          _buildTopBar(vm, state),
          Expanded(
            child: profile == null
                ? _buildEmpty(state)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      Center(child: _buildAvatar(state)),
                      const SizedBox(height: 12),
                      if (_isEditing) ..._buildEditForm(state) else ..._buildDetails(state),
                      if (state.hasPendingChanges) ...[
                        const SizedBox(height: 16),
                        const Center(child: AppPill(label: 'Pending sync', small: true)),
                      ],
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          state.errorMessage!,
                          textAlign: TextAlign.center,
                          style: _footerStyle().copyWith(color: AppColors.spicyPaprika),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  //Back or cancel on the left, Edit or Save on the right
  Widget _buildTopBar(ProfileViewModel vm, ProfileUiState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.arrow_back, color: AppColors.darkCoffee),
            tooltip: _isEditing ? 'Cancel' : 'Back',
            onPressed: () => _isEditing ? setState(() => _isEditing = false) : context.pop(),
          ),
          Expanded(
            child: Text(_isEditing ? 'EDIT PROFILE' : 'PROFILE', style: AppTextStyles.monoLabel),
          ),
          if (state.isOffline) ...[
            const Icon(Icons.wifi_off, size: 16, color: AppColors.spicyPaprika),
            const SizedBox(width: 8),
          ],
          if (state.profile != null)
            _isEditing
                ? TextButton(
                    onPressed: state.isLoading ? null : () => _saveName(vm),
                    child: Text('SAVE', style: AppTextStyles.monoLabel.copyWith(color: AppColors.spicyPaprika)),
                  )
                : Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppPill(label: '✎ Edit', small: true, onTap: _startEditing),
                  ),
        ],
      ),
    );
  }

  //Shown until a profile is loaded or saved on the device
  Widget _buildEmpty(ProfileUiState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.spicyPaprika));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          state.errorMessage ?? '',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildAvatar(ProfileUiState state) {
    final profile = state.profile!;
    final avatar = Stack(
      children: [
        ProfileAvatar(
          displayName: profile.displayName,
          photoUrl: profile.photoUrl,
          localPhoto: state.localPhoto,
        ),
        if (state.isUploadingPhoto)
          const Positioned.fill(
            child: Center(child: CircularProgressIndicator(color: AppColors.spicyPaprika)),
          ),
        //Camera badge, only in edit mode
        if (_isEditing)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.spicyPaprika,
                border: Border.all(color: AppColors.darkCoffee, width: 2),
              ),
              child: const Icon(Icons.photo_camera, size: 16, color: AppColors.snow),
            ),
          ),
      ],
    );

    if (!_isEditing) return avatar;
    return GestureDetector(onTap: _showPhotoSheet, child: avatar);
  }

  List<Widget> _buildDetails(ProfileUiState state) {
    final profile = state.profile!;
    final textTheme = Theme.of(context).textTheme;

    return [
      Text(
        profile.displayName,
        textAlign: TextAlign.center,
        style: textTheme.titleLarge,
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Streak',
              Text(
                '🔥 ${profile.streak}d',
                style: textTheme.titleLarge?.copyWith(color: AppColors.spicyPaprika),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Your code',
              Text(
                profile.friendCode.isEmpty ? '—' : profile.friendCode,
                style: textTheme.headlineSmall?.copyWith(letterSpacing: 3),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildPetCard(profile.petId, profile.petMood),
    ];
  }

  List<Widget> _buildEditForm(ProfileUiState state) {
    return [
      Text(
        'Tap the photo to change it',
        textAlign: TextAlign.center,
        style: _footerStyle().copyWith(color: AppColors.spicyPaprika),
      ),
      const SizedBox(height: 16),
      AppCard(
        color: AppColors.inputFill,
        shadowOffset: const Offset(0, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Display name', style: _labelStyle()),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              maxLength: ProfileViewModel.maxNameLength,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildStatCard(String label, Widget value) {
    return AppCard(
      color: Colors.white,
      shadowOffset: const Offset(0, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: [
          Text(label, style: _footerStyle()),
          const SizedBox(height: 4),
          value,
        ],
      ),
    );
  }

  Widget _buildPetCard(String? petId, String? petMood) {
    return AppCard(
      color: AppColors.inputFill,
      shadowOffset: const Offset(0, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          PetThumbnail(petId: petId, petMood: petMood, size: 64),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your pet', style: _labelStyle()),
              Text(petLabel(petId, petMood), style: _footerStyle()),
            ],
          ),
        ],
      ),
    );
  }

  void _startEditing() {
    _nameController.text = context.read<ProfileViewModel>().state.profile?.displayName ?? '';
    setState(() => _isEditing = true);
  }

  Future<void> _saveName(ProfileViewModel vm) async {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    await vm.updateDisplayName(name);

    //Leave edit mode when the name was saved or queued to be sent later
    if (mounted && vm.state.profile?.displayName == name) {
      setState(() => _isEditing = false);
    }
  }

  Future<void> _showPhotoSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.snow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: AppColors.darkCoffee, width: 2),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PROFILE PHOTO', style: AppTextStyles.monoLabel),
              const SizedBox(height: 12),
              _buildSheetOption(sheetContext, Icons.photo_camera, 'Take photo', ImageSource.camera),
              const SizedBox(height: 12),
              _buildSheetOption(sheetContext, Icons.photo_library, 'Choose from gallery', ImageSource.gallery),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    //The full photo is sent to the ViewModel, which compresses it in an Isolate
    final Uint8List bytes;
    try {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked == null) return;
      bytes = await picked.readAsBytes();
    } catch (e) {
      //No camera app, the picker was already open, or the file could not be read
      debugPrint('[MyProfilePage] pickImage failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(source == ImageSource.camera
              ? "We couldn't open the camera"
              : "We couldn't open your photos"),
        ),
      );
      return;
    }
    if (!mounted) return;

    await context.read<ProfileViewModel>().changePhoto(bytes);
  }

  Widget _buildSheetOption(BuildContext sheetContext, IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () => Navigator.pop(sheetContext, source),
      child: AppCard(
        color: Colors.white,
        shadowOffset: const Offset(0, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.spicyPaprika),
            const SizedBox(width: 12),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  TextStyle? _labelStyle() {
    return Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13, letterSpacing: 0);
  }

  TextStyle _footerStyle() {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 12, fontWeight: FontWeight.w600);
  }
}
