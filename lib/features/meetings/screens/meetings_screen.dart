import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/back_app_bar.dart';
import '../../../widgets/motif_background.dart';
import '../meetings/meetings_repository.dart';
import '../../models/meeting.dart';
import 'create_meeting_screen.dart';
import 'meeting_details_screen.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  bool _loading = true;
  List<Meeting> _meetings = [];

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    setState(() => _loading = true);
    try {
      final repo = context.read<MeetingRepository>();
      final list = await repo.list();
      setState(() => _meetings = list);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement des réunions")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MotifBackground(
        overlayOpacity: 0.9,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  tr(context, 'meetings'),
                  style: const TextStyle(
                    color: AppColors.chocolate,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.chocolate),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.terracotta)),
              )
            else if (_meetings.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          tr(context, 'no_meetings'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final m = _meetings[index];
                      return _MeetingCard(meeting: m, onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => MeetingDetailsScreen(meeting: m)),
                      ));
                    },
                    childCount: _meetings.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.terracotta,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(tr(context, 'create_meeting'), style: const TextStyle(color: Colors.white)),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateMeetingScreen()),
        ).then((_) => _loadMeetings()),
      ),
    );
  }

  Widget _MeetingCard({required Meeting meeting, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        title: Text(
          meeting.objet ?? "Sans objet",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                "${meeting.startTime.toString().split('T')[0]}",
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.timer, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                "${meeting.duration} min",
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: meeting.isEnd
                ? Colors.green.withOpacity(0.1)
                : AppColors.terracotta.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            meeting.isEnd ? Icons.check_circle : Icons.schedule,
            color: meeting.isEnd ? Colors.green : AppColors.terracotta,
            size: 24,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

