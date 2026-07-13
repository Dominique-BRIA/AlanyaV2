import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';

import '../../../core/connectivity_service.dart';
import '../../../core/conversation_cache.dart';
import '../../../core/push_service.dart';
import '../../../core/realtime_client.dart';
import '../../../models/ai_message.dart';
import '../../../models/conversation.dart';
import '../../../models/status.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/avatar_circle.dart';
import '../../../widgets/motif_background.dart';
import '../account/screens/avatar_viewer_screen.dart';
import '../account/screens/profile_screen.dart';
import '../ai/screens/ai_chat_screen.dart';

// ... existing imports ...
import '../auth/auth_controller.dart';
import '../chat/chat_repository.dart';
import '../chat/screens/chat_screen.dart';
import '../contacts/screens/contacts_screen.dart';
import '../chat/screens/new_group_screen.dart';
import '../contacts/screens/add_contact_screen.dart';
import '../contacts/screens/new_chat_screen.dart';
import '../calls/call_controller.dart';
import '../calls/call_listener.dart';
import '../calls/screens/calls_screen.dart';
import '../status/screens/status_feed_screen.dart';
import '../status/screens/create_status_screen.dart';
import '../status/status_repository.dart';
import '../meetings/screens/meetings_screen.dart';
import '../meetings/screens/create_meeting_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RealtimeClient>().connect();
      final user = context.read<AuthController>().user;
      if (user != null) {
        context.read<CallController>().bindUser(
              user.id,
              user.pseudo ?? user.publicNumber,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final theme = Theme.of(context);

    // Définition des contenus pour chaque tab
    final tabs = [
      _ChatDashboard(userId: user?.id),
      const StatusFeedScreen(),
      const CallsScreen(),
      const _AiTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.sand,
      body: Stack(
        children: [
          // Fond décoratif global
          // MotifBackground est déjà utilisé dans les tabs, on peut le mettre ici pour éviter les rebuilds
          Positioned.fill(child: MotifBackground(overlayOpacity: 0.8)),
          
          // Contenu principal avec transition fluide
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: tabs[_tab],
          ),
        ],
      ),
      
      // Navigation Bar Premium - Flottante, élégante et accessible
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.chocolate.withValues(alpha: 0.12),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              backgroundColor: AppColors.surface.withValues(alpha: 0.95),
              indicatorColor: AppColors.terracotta.withValues(alpha: 0.15),
              elevation: 0,
              destinations: [
                _buildNavDest(Icons.chat_bubble_outline, Icons.chat_bubble, tr(context, 'chats'), 0),
                _buildNavDest(Icons.donut_large_outlined, Icons.donut_large, tr(context, 'status'), 1),
                _buildNavDest(Icons.call_outlined, Icons.call, tr(context, 'calls'), 2),
                _buildNavDest(Icons.auto_awesome_outlined, Icons.auto_awesome, "IA", 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavDest(IconData iconOutlined, IconData iconFilled, String label, int index) {
    return NavigationDestination(
      icon: Icon(iconOutlined, color: AppColors.textSecondary),
      selectedIcon: Icon(iconFilled, color: AppColors.terracotta),
      label: label,
    );
  }
}

/// Dashboard des conversations : mélange de Stories, Raccourcis et Liste de Chats
class _ChatDashboard extends StatefulWidget {
  final String? userId;
  const _ChatDashboard({this.userId});

  @override
  State<_ChatDashboard> createState() => _ChatDashboardState();
}

class _ChatDashboardState extends State<_ChatDashboard> {
  List<Conversation>? _convs;
  StatusFeed? _statusFeed;
  bool _loading = true;
  Timer? _pollTimer;
  StreamSubscription<Map<String, dynamic>>? _rtSub;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _rtSub = context.read<RealtimeClient>().events.listen((e) {
      if (e["type"] == "message" || e["type"] == "read") {
        _poll();
      }
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _rtSub?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final convsFuture = context.read<ChatRepository>().listConversations();
      final statusFuture = context.read<StatusRepository>().feed();
      
      final results = await Future.wait([convsFuture, statusFuture]);
      
      if (mounted) {
        setState(() {
          _convs = results[0] as List<Conversation>;
          _statusFeed = results[1] as StatusFeed;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _poll() async {
    if (!mounted) return;
    try {
      final convs = await context.read<ChatRepository>().listConversations();
      final feed = await context.read<StatusRepository>().feed();
      if (mounted) {
        setState(() {
          _convs = convs;
          _statusFeed = feed;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final theme = Theme.of(context);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // 1. Header Premium
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 120,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.chocolate.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            title: Text("Alanya", style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.chocolate)),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () {},
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AvatarCircle(
                    name: user?.pseudo ?? "?",
                    avatarUrl: user?.avatarUrl,
                    radius: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),

          // 2. Contenu du Dashboard
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Stories
                if (_statusFeed != null) _buildStoriesSection(),
                
                const SizedBox(height: 32),
                
                // Section Actions Rapides
                _buildQuickActions(),
                
                const SizedBox(height: 32),
                
                // Titre des discussions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Messages", style: theme.textTheme.titleLarge),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContactsScreen())),
                        child: const Text("Voir tout"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Liste des conversations optimisée
          _buildConversationSlivers(),
        ],
      ),
    );
  }


  Widget _buildStoriesSection() {
    final feed = _statusFeed!;
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Mon statut
          _storyTile(userId: widget.userId ?? "", isMine: true, group: feed.me),
          ...feed.others.map((g) => _storyTile(userId: g.userId, isMine: false, group: g)),
        ],
      ),
    );
  }

  Widget _storyTile({required String userId, required bool isMine, StatusGroup? group}) {
    return GestureDetector(
      onTap: () {
        if (isMine) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateStatusScreen()));
        } else if (group != null) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => StatusViewerScreen(group: group, isMine: false)));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (group?.hasUnviewed ?? false) ? AppColors.forest : AppColors.outline,
                  width: 2.5,
                ),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.clay,
                child: Text(group?.displayName[0].toUpperCase() ?? "?", style: const TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
            Text(group?.displayName ?? "Utilisateur", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _actionButton(Icons.add_circle_outline, "Statut", AppColors.terracotta, () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateStatusScreen()));
          }),
          _actionButton(Icons.calendar_month_outlined, "Réunion", AppColors.forest, () {
            Navigator.of(//L'écran de création de réunion
              context).push(MaterialPageRoute(builder: (_) => const CreateMeetingScreen())),
          }),
          _actionButton(Icons.auto_awesome, "Assistant IA", AppColors.chocolate, () {
             setState(() => _tab = 3); // Switch to AI tab
          }),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildConversationSlivers() {
    if (_loading) return constHedge: const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
    if (_convs == null || _convs!.isEmpty) {
      return const SliverFillRemaining(child: Center(child: Text("Aucune discussion")));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final c = _convs![i];
          final user = context.watch<AuthController>().user;
          final myId = user?.id;
          final other = c.isGroup ? null : c.members.firstWhere((m) => m.id != myId, orElse: () => c.members.first);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: c.isGroup 
              ? CircleAvatar(backgroundColor: AppColors.forest, child: const Icon(Icons.groups, color: Colors.white))
              : AvatarCircle(name: c.title, avatarUrl: c.avatarUrl, radius: 24),
            title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(c.lastMessage ?? "Démarrer la discussion", maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: c.unread > 0 
              ? CircleAvatar(radius: 10, backgroundColor: AppColors.terracotta, child: Text("${c.unread}", style: const TextStyle(color: Colors.white, fontSize: 10)))
              : null,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(
              convId: c.id, title: c.title, isGroup: c.isGroup, memberNames: c.memberNames, avatarUrl: c.avatarUrl, otherUserId: other?.id, otherPublicNumber: other?.publicNumber,
            ))),
          );
        },
        childCount: _convs!.length,
      ),
    );
  }
}

// Suppression de la classe _StatusTab car elle est remplacée par StatusFeedScreen
class _AiTab extends StatelessWidget {
  const _AiTab();
  @override
  Widget build(BuildContext context) {
    return const AiChatScreen();
  }
}

