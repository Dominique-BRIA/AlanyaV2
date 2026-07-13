import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/back_app_bar.dart';
import '../meetings/meetings_repository.dart';
import '../../models/meeting.dart';

class MeetingDetailsScreen extends StatefulWidget {
  final Meeting meeting;
  const MeetingDetailsScreen({super.key, required this.meeting});

  @override
  State<MeetingDetailsScreen> createState() => _MeetingDetailsScreenState();
}

class _MeetingDetailsScreenState extends State<MeetingDetailsScreen> {
  bool _loading = false;

  Future<void> _updateStatus(int status) async {
    setState(() => _loading = true);
    try {
      await context.read<MeetingRepository>().updateStatus(widget.meeting.id, status);
      // On pourrait recharger les données ici ou retourner en arrière
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de la mise à jour")));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.meeting;
    final isOrganiser = m.organiserId == context.read<AuthController>().user?.id;

    return Scaffold(
      appBar: backAppBar(context, tr(context, 'meeting_details')),
      body: MotifBackground(
        overlayOpacity: 0.9,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _premiumInfoCard(m),
              const SizedBox(height: 32),
              const Text(
                "Participants",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.chocolate),
              ),
              const SizedBox(height: 16),
              ...m.participants.map((p) => _participantDetailTile(p)),
              if (!isOrganiser && !m.isEnd) ...[
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _actionButton(
                      label: "Refuser",
                      color: Colors.redAccent,
                      onPressed: _loading ? null : () => _updateStatus(3),
                    ),
                    _actionButton(
                      label: "Accepter",
                      color: AppColors.forest,
                      onPressed: _loading ? null : () => _updateStatus(2),
                    ),
                  ],
                ),
              ],
              if (isOrganiser && !m.isEnd) ...[
                const SizedBox(height: 40),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () async {
                      await context.read<MeetingRepository>().endMeeting(m.id);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Clore la réunion", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _premiumInfoCard(Meeting m) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.objet ?? "Sans objet",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.chocolate),
          ),
          const SizedBox(height: 20),
          _infoRow(Icons.calendar_today, "Date", m.startTime.toString().split('T')[0]),
          const SizedBox(height: 12),
          _infoRow(Icons.timer, "Durée", "${m.duration} min"),
          const SizedBox(height: 12),
          _infoRow(Icons.room, "Salle", m.room ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.terracotta),
        const SizedBox(width: 12),
        Text("$label: ", style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _participantDetailTile(dynamic p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.clay,
          child: Text(p.userName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
        ),
        title: Text(p.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          "Statut: ${p.status == 1 ? 'En attente' : p.status == 2 ? 'Accepté' : 'Refusé'}",
          style: TextStyle(
            color: p.status == 2 ? Colors.green : (p.status == 3 ? Colors.redAccent : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({required String label, required Color color, required VoidCallback? onPressed}) {
    return SizedBox(
      width: 140,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

