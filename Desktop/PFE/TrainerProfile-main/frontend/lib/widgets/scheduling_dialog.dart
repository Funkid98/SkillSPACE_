import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reactive_theme/reactive_theme.dart';
import 'package:pfe/core/app_colors.dart';

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
  final _formKey = GlobalKey<FormState>();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final linkController = TextEditingController();

  Future<void> _selectDate() async {
    final isDark = ReactiveMode.isDarkMode(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.orange,
                    onPrimary: Colors.white,
                    surface: AppColors.surfaceDark,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: AppColors.navy,
                    onPrimary: Colors.white,
                    onSurface: AppColors.textDark,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    final isDark = ReactiveMode.isDarkMode(context);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 14, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.orange,
                    onPrimary: Colors.white,
                    surface: AppColors.surfaceDark,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: AppColors.navy,
                    onPrimary: Colors.white,
                    onSurface: AppColors.textDark,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        timeController.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ReactiveMode.isDarkMode(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      surfaceTintColor: isDark ? AppColors.surfaceDark : Colors.white,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_available_rounded,
                    color: AppColors.orange, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Planifier un entretien',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Proposez une date et un lien Meet pour rencontrer ${widget.candidateName}.',
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textGray,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildPickerField(
                controller: dateController,
                label: 'Date de l\'entretien',
                hint: 'Choisir une date',
                icon: Icons.calendar_today_rounded,
                onTap: _selectDate,
                isDark: isDark,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Veuillez choisir une date' : null,
              ),
              const SizedBox(height: 16),
              _buildPickerField(
                controller: timeController,
                label: 'Heure',
                hint: 'Choisir l\'heure',
                icon: Icons.access_time_rounded,
                onTap: _selectTime,
                isDark: isDark,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Veuillez choisir l\'heure' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: linkController,
                label: 'Lien de la réunion',
                hint: 'https://meet.google.com/xxx-xxxx-xxx',
                icon: Icons.videocam_rounded,
                isDark: isDark,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Veuillez saisir un lien';
                  }
                  if (!val.startsWith('http')) {
                    return 'Lien invalide (ex: https://...)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Annuler',
            style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textGray,
                fontWeight: FontWeight.w600,
                fontSize: 15),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onConfirm(
                dateController.text,
                timeController.text,
                linkController.text,
              );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.orange : AppColors.navy,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text(
            'Confirmer',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    );
  }

  Widget _buildPickerField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          validator: validator,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppColors.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: (isDark ? Colors.white30 : AppColors.textGray)
                    .withOpacity(0.5)),
            prefixIcon: Icon(icon,
                size: 20, color: isDark ? AppColors.orange : AppColors.navy),
            suffixIcon: Icon(Icons.arrow_drop_down_rounded,
                color: isDark ? Colors.white30 : AppColors.textGray),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.bg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: isDark ? AppColors.orange : AppColors.navy,
                  width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppColors.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: (isDark ? Colors.white30 : AppColors.textGray)
                    .withOpacity(0.5)),
            prefixIcon: Icon(icon,
                size: 20, color: isDark ? AppColors.orange : AppColors.navy),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.bg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: isDark ? AppColors.orange : AppColors.navy,
                  width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
