import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/media/media_provider_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import 'scam_shield_sheet.dart';

/// Tab 5 — Device Integrations & Companion Tools (PRD §3.1.4). Hosts the theme
/// controller override, media provider linkage (design §4.7), smart checklists,
/// the Scam Shield (§4.8), and offline-download entry.
class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tools & Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _SectionLabel('Companion Tools'),
          _ToolTile(
            icon: Icons.shield_outlined,
            color: KashiColors.terracotta,
            title: 'Scam Shield',
            subtitle: 'Fair rates + active scam advisories',
            onTap: () => _openScamShield(context),
          ),
          _ToolTile(
            icon: Icons.checklist,
            color: KashiColors.saffronGold,
            title: 'Temple Checklist',
            subtitle: 'Leather, head cover, cash, shoes',
            onTap: () => _showChecklist(context),
          ),
          _ToolTile(
            icon: Icons.download_for_offline,
            color: KashiColors.riverJade,
            title: 'Offline Bundle',
            subtitle: 'Pre-download Varanasi map + audio guides',
            onTap: () => _toast(context, 'Offline bundle download queued (Wi-Fi recommended).'),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Media Providers'),
          const _SpotifyCard(),
          const SizedBox(height: 10),
          const _AppleMusicCard(),
          const SizedBox(height: 10),
          const _FallbackToggle(),
          const SizedBox(height: 16),
          const _SectionLabel('Theme'),
          const _ThemeControllerCard(),
          const SizedBox(height: 16),
          const _SectionLabel('About'),
          _ToolTile(
            icon: Icons.info_outline,
            color: KashiColors.slateGrey,
            title: 'Kashi Nav',
            subtitle: 'v0.1.0 · local-first · OSM + Firebase',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _openScamShield(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ScamShieldSheet(),
    );
  }

  void _showChecklist(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChecklistSheet(),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: KashiColors.saffronGold,
                letterSpacing: 1)),
      );
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _SpotifyCard extends ConsumerWidget {
  const _SpotifyCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaProviderManagerProvider);
    final spotifyProvider = mediaState.availableProviders
        .where((p) => p.providerName == 'Spotify')
        .firstOrNull;
    final isConnected = spotifyProvider?.isConnected ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KashiColors.saffronGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KashiColors.saffronGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🎵', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text('Link Spotify Premium',
                style: Theme.of(context).textTheme.titleMedium),
          ]),
          const SizedBox(height: 4),
          Text(
            'Lets the Brain wake you with any stotra, raga or playlist.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isConnected
                  ? () async {
                      await ref.read(mediaProviderManagerProvider.notifier).disconnectActive();
                    }
                  : () async {
                      if (spotifyProvider != null) {
                        await ref.read(mediaProviderManagerProvider.notifier).connectProvider(spotifyProvider);
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: isConnected ? KashiColors.riverJade : KashiColors.saffronGold,
              ),
              child: Text(isConnected ? 'Connected (Premium)' : 'Connect Spotify Account'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppleMusicCard extends ConsumerWidget {
  const _AppleMusicCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaProviderManagerProvider);
    final appleProvider = mediaState.availableProviders
        .where((p) => p.providerName == 'Apple Music')
        .firstOrNull;
    final isConnected = appleProvider?.isConnected ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KashiColors.terracotta.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KashiColors.terracotta.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🍎', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text('Link Apple Music',
                style: Theme.of(context).textTheme.titleMedium),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isConnected
                  ? () async {
                      await ref.read(mediaProviderManagerProvider.notifier).disconnectActive();
                    }
                  : () async {
                      if (appleProvider != null) {
                        await ref.read(mediaProviderManagerProvider.notifier).connectProvider(appleProvider);
                      }
                    },
              child: Text(isConnected ? 'Signed in (MusicKit)' : 'Sign In with Apple ID'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackToggle extends ConsumerWidget {
  const _FallbackToggle();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaProviderManagerProvider);
    final youtubeProvider = mediaState.availableProviders
        .where((p) => p.providerName == 'YouTube')
        .firstOrNull;
    final isYoutubeConnected = youtubeProvider?.isConnected ?? false;

    return Card(
      child: SwitchListTile(
        value: isYoutubeConnected,
        onChanged: (v) async {
          if (v && youtubeProvider != null) {
            await ref.read(mediaProviderManagerProvider.notifier).connectProvider(youtubeProvider);
          } else if (!v && isYoutubeConnected) {
            await ref.read(mediaProviderManagerProvider.notifier).disconnectActive();
          }
        },
        title: const Text('YouTube Fallback'),
        subtitle: Text(
          'Used when premium providers are offline.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

/// Theme override card (design §4.11). Lets the user preview each phase or
/// follow the sun.
class _ThemeControllerCard extends ConsumerWidget {
  const _ThemeControllerCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeOverrideProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dynamic Theme', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Morphs with the sun over Varanasi + monsoon override.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final o in ThemeOverride.values)
                  ChoiceChip(
                    label: Text(_label(o)),
                    selected: current == o,
                    selectedColor: KashiColors.saffronGold.withValues(alpha: 0.3),
                    onSelected: (_) =>
                        ref.read(themeOverrideProvider.notifier).state = o,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _label(ThemeOverride o) => switch (o) {
        ThemeOverride.system => '☀️ Follow Sun',
        ThemeOverride.sunrise => '🌅 Sunrise',
        ThemeOverride.daytime => '🌞 Day',
        ThemeOverride.twilight => '🌇 Twilight',
        ThemeOverride.night => '🌌 Night',
        ThemeOverride.monsoon => '🌧️ Monsoon',
      };
}

class _ChecklistSheet extends StatelessWidget {
  const _ChecklistSheet();
  @override
  Widget build(BuildContext context) {
    const items = [
      ('Remove Leather Items', 'Belts, wallets, bags go to lockboxes before the queue.'),
      ('Head Cover / Scarf', 'Required. Use a head scarf or handkerchief.'),
      ('Shoes Drop-off', 'Counter ~40m ahead on the left (free).'),
      ('Carry Small Change', 'Coins/₹100 notes for flowers, coconut, charity boxes.'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KashiColors.saffronGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Kashi Vishwanath Checklist',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final (title, detail) in items)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: false,
                onChanged: (_) {},
                title: Text(title),
                subtitle: Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}
