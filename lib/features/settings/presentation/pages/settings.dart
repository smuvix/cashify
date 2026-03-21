import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/presentation/widgets/app_scaffold.dart';
import '../../../../core/presentation/widgets/reusable_dialog.dart';
import '../../../theme/presentation/provider/theme_provider.dart';
import '../../../theme/presentation/widgets/theme_dialog.dart';
import '../providers/user_settings_providers.dart';
import '../widgets/username_dialog.dart';
import '../widgets/date_format_dialog.dart';
import '../widgets/currency_dialog.dart';

class Settings extends ConsumerWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider).mode;
    final settingsAsync = ref.watch(userSettingsProvider);

    return AppScaffold(
      title: Text('Settings'),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                'Failed to load settings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text('$e', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(userSettingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (settings) {
          final firebaseUser = FirebaseAuth.instance.currentUser;
          final email = firebaseUser?.email ?? '';
          final fallbackName =
              firebaseUser?.displayName ?? email.split('@').first;
          final displayUsername = settings.username.isNotEmpty
              ? settings.username
              : fallbackName;
          final avatarLetter = displayUsername.isNotEmpty
              ? displayUsername[0].toUpperCase()
              : '?';

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
            children: [
              _ProfileHeader(
                avatarLetter: avatarLetter,
                username: displayUsername,
                email: email,
                onEditTap: () => showUsernameDialog(
                  context,
                  ref,
                  settings.username.isNotEmpty
                      ? settings.username
                      : fallbackName,
                ),
              ),
              const SizedBox(height: 28),

              const _SectionLabel(label: 'Profile'),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.edit_outlined,
                    title: 'Username',
                    value: settings.username.isNotEmpty
                        ? settings.username
                        : fallbackName,
                    onTap: () => showUsernameDialog(
                      context,
                      ref,
                      settings.username.isNotEmpty
                          ? settings.username
                          : fallbackName,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const _SectionLabel(label: 'Preferences'),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.calendar_today_outlined,
                    title: 'Date format',
                    value: settings.dateFormat,
                    onTap: () =>
                        showDateFormatDialog(context, ref, settings.dateFormat),
                  ),
                  const _TileDivider(),
                  _SettingsTile(
                    icon: Icons.attach_money_outlined,
                    title: 'Currency',
                    value: settings.currency,
                    onTap: () =>
                        showCurrencyDialog(context, ref, settings.currency),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const _SectionLabel(label: 'Appearance'),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.brightness_6_outlined,
                    title: 'Theme',
                    value: _themeLabel(themeMode),
                    onTap: () => showThemeDialog(context, ref, themeMode),
                    trailing: _ThemeModeIcon(mode: themeMode),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const _SectionLabel(label: 'Account'),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _LogoutTile(onTap: () => _showLogoutDialog(context)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
    ThemeMode.system => 'Follow system',
  };

  Future<void> _showLogoutDialog(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => ReusableDialog<bool>(
        title: 'Log out',
        initialValue: false,
        confirmText: 'Log out',
        cancelText: 'Cancel',
        confirmColor: Theme.of(context).colorScheme.error,
        cancelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        builder: (context, value, onChanged) => Text(
          'Are you sure you want to log out of your account?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        onConfirm: (_) async {
          await FirebaseAuth.instance.signOut();
          return true;
        },
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withAlpha(80),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.error.withAlpha(40)),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Log out',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.avatarLetter,
    required this.username,
    required this.email,
    required this.onEditTap,
  });

  final String avatarLetter;
  final String username;
  final String email;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(60),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary,
            ),
            child: Center(
              child: Text(
                avatarLetter,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username.isNotEmpty ? username : 'No username',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onEditTap,
            icon: Icon(
              Icons.edit_outlined,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surface.withAlpha(120),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withAlpha(80),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withAlpha(60),
      indent: 16,
      endIndent: 16,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _ThemeModeIcon extends StatelessWidget {
  const _ThemeModeIcon({required this.mode});
  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = switch (mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };
    return Icon(icon, size: 20, color: colorScheme.onSurfaceVariant);
  }
}
