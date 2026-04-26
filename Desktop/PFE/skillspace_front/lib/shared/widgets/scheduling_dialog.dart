import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class SchedulingDialog extends StatefulWidget {
  final String candidateName;
  final Function(String date, String time, String link) onConfirm;

  const SchedulingDialog({
    super.key,
    required this.candidateName,
    required this.onConfirm,
  });

  @override
  State<SchedulingDialog> createState() => _SchedulingDialogState();
}

class _SchedulingDialogState extends State<SchedulingDialog> {
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final linkController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_available_rounded,
                color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Planifier un entretien',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Proposez une date et un lien Meet pour rencontrer ${widget.candidateName}.',
              style: const TextStyle(color: AppColors.textGray, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: dateController,
              label: 'Date de l\'entretien',
              hint: 'ex: Lun. 30 Avril',
              icon: Icons.calendar_today_rounded,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: timeController,
              label: 'Heure',
              hint: 'ex: 14:30',
              icon: Icons.access_time_rounded,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: linkController,
              label: 'Lien Google Meet',
              hint: 'https://meet.google.com/xxx-xxxx-xxx',
              icon: Icons.videocam_rounded,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Annuler',
            style: TextStyle(
                color: AppColors.textGray, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            if (dateController.text.isNotEmpty && timeController.text.isNotEmpty) {
              widget.onConfirm(
                dateController.text,
                timeController.text,
                linkController.text,
              );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'Confirmer',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textGray.withValues(alpha: 0.5)),
            prefixIcon: Icon(icon, size: 20, color: AppColors.navy),
            filled: true,
            fillColor: AppColors.bg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
