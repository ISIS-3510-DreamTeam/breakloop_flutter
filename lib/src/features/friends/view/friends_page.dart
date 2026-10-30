import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../model/friend_model.dart';
import '../viewmodel/friends_ui_state.dart';
import '../viewmodel/friends_viewmodel.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pill.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FriendsViewModel>();
    final state = vm.state;

    return Scaffold(
      backgroundColor: AppColors.snow,
      body: RefreshIndicator(
        color: AppColors.spicyPaprika,
        //Pull to refresh always goes to Firestore, skipping the cache
        onRefresh: () => vm.loadFriends(forceRefresh: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            _buildTitle(state),
            const SizedBox(height: 20),
            _buildAddFriendCard(vm, state),
            const SizedBox(height: 24),
            _buildFriendsHeader(state),
            const SizedBox(height: 12),
            ..._buildFriendsList(state),
          ],
        ),
      ),
    );
  }

  //Title on the left and the user's code on the right
  Widget _buildTitle(FriendsUiState state) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOUR CIRCLE', style: textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Encouragement, not race',
                style: textTheme.bodyMedium?.copyWith(fontSize: 13, color: AppColors.spicyPaprika),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildFriendCodeCard(state),
      ],
    );
  }

  Widget _buildError(String message) {
    return Text(
      message,
      style: _footerStyle().copyWith(color: AppColors.spicyPaprika),
    );
  }

  //Highlighted card, the main action of the screen
  Widget _buildAddFriendCard(FriendsViewModel vm, FriendsUiState state) {
    return AppCard(
      color: AppColors.inputFill,
      shadowOffset: const Offset(0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add a friend', style: _labelStyle()),
          const SizedBox(height: 4),
          Text('Enter the code your friend shared with you', style: _footerStyle()),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'ABC123',
              prefixIcon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 8),
            _buildError(state.errorMessage!),
          ],
          const SizedBox(height: 12),
          AppButton(
            label: 'ADD FRIEND',
            height: 46,
            loading: state.isLoading,
            onPressed: () => _addFriend(vm),
          ),
          //Codes added offline, so the user knows they were not lost
          if (state.pendingCodes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final code in state.pendingCodes) AppPill(label: 'Pending · $code'),
              ],
            ),
            const SizedBox(height: 8),
            Text("We'll add them when you're back online", style: _footerStyle()),
          ],
        ],
      ),
    );
  }

  Future<void> _addFriend(FriendsViewModel vm) async {
    FocusScope.of(context).unfocus();
    await vm.addFriend(_codeController.text);

    //Keep the code in the field if it failed so the user can fix it
    if (vm.state.errorMessage == null) {
      _codeController.clear();
    }
  }

  //Small card with the user's code and the copy button below
  Widget _buildFriendCodeCard(FriendsUiState state) {
    final code = state.myFriendCode;

    return AppCard(
      color: Colors.white,
      shadowOffset: const Offset(0, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: [
          //Without connection the code may not exist yet
          Text('Your code', style: _labelStyle()),
          Text(
            code ?? '—',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(letterSpacing: 3),
          ),
          if (code != null) ...[
            const SizedBox(height: 4),
            AppPill(label: 'Copy', small: true, onTap: () => _copyCode(code)),
          ],
        ],
      ),
    );
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied'),
        backgroundColor: Color.fromARGB(255, 241, 193, 168),
      ),
    );
  }

  Widget _buildFriendsHeader(FriendsUiState state) {
    final lastUpdated = state.lastUpdated;

    return Row(
      children: [
        Expanded(
          child: Text('Buddies · ${state.friends.length}', style: _labelStyle()),
        ),
        if (state.isOffline) ...[
          const Icon(Icons.wifi_off, size: 16, color: AppColors.spicyPaprika),
          const SizedBox(width: 4),
        ],
        if (lastUpdated != null)
          Text('Updated ${_formatUpdated(lastUpdated)}', style: _footerStyle()),
      ],
    );
  }

  List<Widget> _buildFriendsList(FriendsUiState state) {
    if (state.friends.isEmpty) {
      //Loading for the first time, there is nothing saved yet
      if (state.isLoading) {
        return [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppColors.spicyPaprika)),
          ),
        ];
      }
      //Only say the list is empty when it was really downloaded
      if (state.lastUpdated != null) {
        return [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No friends yet. Share your code to get started',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ];
      }
      return [];
    }

    return [
      for (final friend in state.friends)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildFriendCard(friend),
        ),
    ];
  }

  Widget _buildFriendCard(FriendModel friend) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      color: Colors.white,
      shadowOffset: const Offset(0, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          //Generic pet icon until the pet contract defines a sprite per stage
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.darkCoffee, width: 2),
            ),
            child: const Icon(Icons.pets, color: AppColors.spicyPaprika),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.displayName.isEmpty ? 'Friend' : friend.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text('Stage ${friend.petLevel}', style: _footerStyle()),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '🔥 ${friend.streak}d',
            style: _labelStyle()?.copyWith(color: AppColors.spicyPaprika),
          ),
        ],
      ),
    );
  }

  TextStyle? _labelStyle() {
    return Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13, letterSpacing: 0);
  }

  TextStyle _footerStyle() {
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
