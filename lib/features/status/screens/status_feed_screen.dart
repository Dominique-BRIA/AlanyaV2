import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/avatar_circle.dart';
import '../../../widgets/motif_background.dart';
import '../../../models/status.dart';
import '../status_repository.dart';
import 'create_status_screen.dart';
import 'status_viewer_screen.dart';

class StatusFeedScreen extends StatefulWidget {
  const StatusFeedScreen({super.key});

  @override
  State<StatusFeedScreen> createState() => _StatusFeedScreenState();
}

class _StatusFeedScreenState extends State<StatusFeedScreen> {
  StatusFeed? _feed;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final feed = await context.read<StatusRepository>().feed();
      if (mounted) {
        setState(() {
          _feed = feed;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MotifBackground(
      overlayOpacity: 0.9,
      child: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
            : _feed == null
                ? Center(child: Text("Aucun statut disponible", style: theme.textTheme.bodyMedium))
                : CustomScrollView(
                    slivers: [
                      // Header élégant
                      SliverAppBar(
                        floating: true,
                        pinned: true,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        title: Text(
                          "Statuts",
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.chocolate,
                          ),
                        ),
                        centerTitle: false,
                      ),
                      
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Mon Statut : Carte Premium
                              _buildMyStatusCard(),
                              const SizedBox(height: 32),
                              Text(
                                "Mises à jour récentes",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),

                      // Liste des autres statuts
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final group = _feed!.others[i];
                              return _StatusTile(group: group);
                            },
                            childCount: _feed!.others.length,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildMyStatusCard() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreateStatusScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.chocolate.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                AvatarCircle(
                  name: "Moi",
                  radius: 30,
                  backgroundColor: AppColors.terracotta,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: AppColors.sand, shape: BoxShape.circle),
                    child: const CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.terracotta,
                      child: Icon(Icons.add, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Mon statut",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    "Appuyez pour ajouter une mise à jour",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final StatusGroup group;
  const _StatusTile({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnviewed = group.hasUnviewed;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => StatusViewerScreen(group: group, isMine: false)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasUnviewed ? AppColors.terracotta.withValues(alpha: 0.3) : AppColors.outline,
            width: hasUnviewed ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasUnviewed ? AppColors.terracotta : AppColors.outline,
                  width: 2,
                ),
              ),
              child: AvatarCircle(
                name: group.displayName,
                radius: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    group.statuses.isNotEmpty 
                        ? "Toucher pour voir le statut" 
                        : "Aucun statut",
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (group.statuses.isNotEmpty)
              const Icon(Icons.chevron_right, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}
