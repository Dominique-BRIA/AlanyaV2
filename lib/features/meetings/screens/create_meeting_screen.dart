import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/back_app_bar.dart';
import '../meetings/meetings_repository.dart';

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _objetCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _duration = 30;
  int _typeMedia = 1;
  List<String> _selectedParticipants = [];
  bool _loading = false;

  // Mock de participants pour l'exemple (dans l'app réelle, on chargerait la liste des contacts)
  final List<Map<String, String>> _availableParticipants = [
    {"id": "user-1", "name": "Alice"},
    {"id": "user-2", "name": "Bob"},
    {"id": "user-3", "name": "Charlie"},
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = context.read<MeetingRepository>();
      await repo.create(
        startTime: _selectedDate,
        duration: _duration,
        objet: _objetCtrl.text.trim(),
        room: _roomCtrl.text.trim(),
        typeMedia: _typeMedia,
        participantIds: _selectedParticipants,
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la création")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: backAppBar(context, tr(context, 'create_meeting')),
      body: MotifBackground(
        overlayOpacity: 0.9,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle("Informations Générales"),
                const SizedBox(height: 16),
                _premiumTextField(
                  controller: _objetCtrl,
                  label: tr(context, 'meeting_subject'),
                  icon: Icons.title,
                ),
                const SizedBox(height: 20),
                _premiumTextField(
                  controller: _roomCtrl,
                  label: tr(context, 'meeting_room'),
                  icon: Icons.room,
                ),
                const SizedBox(height: 24),
                _sectionTitle("Planification"),
                const SizedBox(height: 16),
                _premiumTile(
                  label: "Date et Heure",
                  value: _selectedDate.toString().split('.')[0],
                  icon: Icons.calendar_today,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                ),
                const SizedBox(height: 16),
                _premiumDropdown<int>(
                  label: "Durée",
                  value: _duration,
                  items: [30, 60, 90, 120].map((d) => DropdownMenuItem(value: d, child: Text("$d minutes"))).toList(),
                  onChanged: (v) => setState(() => _duration = v!),
                ),
                const SizedBox(height: 16),
                _premiumDropdown<int>(
                  label: "Type de média",
                  value: _typeMedia,
                  items: [
                    DropdownMenuItem(value: 1, child: Text("Audio")),
                    DropdownMenuItem(value: 2, child: Text("Vidéo")),
                    DropdownMenuItem(value: 3, child: Text("Mixte")),
                  ],
                  onChanged: (v) => setState(() => _typeMedia = v!),
                ),
                const SizedBox(height: 32),
                _sectionTitle("Participants"),
                const SizedBox(height: 16),
                ..._availableParticipants.map((p) => _participantTile(p)),
                const SizedBox(height: 40),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _loading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text("Créer la réunion", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.chocolate,
      ),
    );
  }

  Widget _premiumTextField({required TextEditingController controller, required String label, required IconData icon}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.terracotta),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.terracotta, width: 1.5),
        ),
      ),
    );
  }

  Widget _premiumTile({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.terracotta),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _premiumDropdown<T>({required String label, required T value, required List<DropdownMenuItem<T>> items, required ValueChanged<T> onChanged}) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.terracotta, width: 1.5),
        ),
      ),
    );
  }

  Widget _participantTile(Map<String, String> p) {
    final isSelected = _selectedParticipants.contains(p["id"]);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.terracotta.withOpacity(0.1) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? AppColors.terracotta : Colors.transparent),
      ),
      child: CheckboxListTile(
        title: Text(p["name"]!, style: const TextStyle(fontWeight: FontWeight.w500)),
        value: isSelected,
        activeColor: AppColors.terracotta,
        checkColor: Colors.white,
        onChanged: (val) {
          setState(() {
            val! ? _selectedParticipants.add(p["id"]!) : _selectedParticipants.remove(p["id"]);
          });
        },
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}

