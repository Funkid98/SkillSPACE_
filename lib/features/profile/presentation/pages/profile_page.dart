import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/profile_cubit.dart';
import '../../data/models/profile_model.dart';
import '../../../../core/app_colors.dart';
import '../../../../shared/widgets/animated_reveal.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading || state is ProfileInitial) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.orange));
        }
        if (state is ProfileError) {
          return Center(child: Text(state.message));
        }
        final data = (state as ProfileLoaded).data;
        return _ProfileContent(data: data);
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final ProfileData data;
  const _ProfileContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(36, 32, 36, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const AnimatedReveal(
            delay: Duration(milliseconds: 100),
            direction: RevealDirection.fromTop,
            child: Text(
              'Mon profil',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark),
            ),
          ),
          const SizedBox(height: 4),
          const AnimatedReveal(
            delay: Duration(milliseconds: 200),
            direction: RevealDirection.fromTop,
            child: Text(
              'Gérez vos informations et compétences',
              style: TextStyle(fontSize: 14, color: AppColors.textGray),
            ),
          ),

          const SizedBox(height: 28),

          // Completion bar
          AnimatedReveal(
            delay: const Duration(milliseconds: 300),
            child: _CompletionCard(percent: data.completionPercent),
          ),

          const SizedBox(height: 20),

          // Personal info form
          AnimatedReveal(
            delay: const Duration(milliseconds: 400),
            child: _PersonalInfoCard(data: data),
          ),

          const SizedBox(height: 20),

          // CV upload
          AnimatedReveal(
            delay: const Duration(milliseconds: 500),
            child: _CvCard(hasCv: data.hasCv),
          ),

          const SizedBox(height: 20),

          // Skills
          AnimatedReveal(
            delay: const Duration(milliseconds: 600),
            child: _SkillsCard(skills: data.skills),
          ),

          const SizedBox(height: 32),

          // Save button
          AnimatedReveal(
            delay: const Duration(milliseconds: 700),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Enregistrer les modifications',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Completion Card ───────────────────────────────────────────────────────
class _CompletionCard extends StatelessWidget {
  final int percent;
  const _CompletionCard({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profil complété à',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.navy),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez un CV et une photo pour compléter votre profil',
            style: TextStyle(fontSize: 12, color: AppColors.textGray),
          ),
        ],
      ),
    );
  }
}

// ─── Personal Info Card ────────────────────────────────────────────────────
class _PersonalInfoCard extends StatefulWidget {
  final ProfileData data;
  const _PersonalInfoCard({required this.data});

  @override
  State<_PersonalInfoCard> createState() => _PersonalInfoCardState();
}

class _PersonalInfoCardState extends State<_PersonalInfoCard> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _location;
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: widget.data.firstName);
    _lastName = TextEditingController(text: widget.data.lastName);
    _email = TextEditingController(text: widget.data.email);
    _phone = TextEditingController(text: widget.data.phone);
    _location = TextEditingController(text: widget.data.location);
    _bio = TextEditingController(text: widget.data.bio);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _location.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations personnelles',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _Field(label: 'Prénom', controller: _firstName)),
              const SizedBox(width: 16),
              Expanded(child: _Field(label: 'Nom', controller: _lastName)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _Field(
                      label: 'Email',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress)),
              const SizedBox(width: 16),
              Expanded(
                  child: _Field(
                      label: 'Téléphone',
                      controller: _phone,
                      keyboardType: TextInputType.phone)),
            ],
          ),
          const SizedBox(height: 16),
          _Field(label: 'Localisation', controller: _location),
          const SizedBox(height: 16),
          _Field(label: 'Bio', controller: _bio, maxLines: 3),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDDD8D0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDDD8D0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── CV Card ───────────────────────────────────────────────────────────────
class _CvCard extends StatelessWidget {
  final bool hasCv;
  const _CvCard({required this.hasCv});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mon CV',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 16),
          hasCv
              ? Row(
                  children: [
                    const Icon(Icons.picture_as_pdf,
                        color: AppColors.orange, size: 24),
                    const SizedBox(width: 10),
                    const Text('CV_Jean_Dupont.pdf',
                        style:
                            TextStyle(fontSize: 14, color: AppColors.textDark)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Remplacer',
                          style: TextStyle(color: AppColors.orange)),
                    ),
                  ],
                )
              : InkWell(
                  onTap: () => context.read<ProfileCubit>().markCvUploaded(),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFFDDD8D0),
                          style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.upload_outlined,
                            size: 32, color: AppColors.textGray),
                        SizedBox(height: 8),
                        Text(
                          'Cliquez ou glissez pour téléverser',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textGray),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'PDF, DOC — max 5 MB',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textGray),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ─── Skills Card ───────────────────────────────────────────────────────────
class _SkillsCard extends StatelessWidget {
  final List<ProfileSkill> skills;
  const _SkillsCard({required this.skills});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Compétences',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16, color: AppColors.orange),
                label: const Text('Ajouter',
                    style: TextStyle(color: AppColors.orange, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: skills.map((s) => _SkillChip(skill: s)).toList(),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final ProfileSkill skill;
  const _SkillChip({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.iconBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF5D5C8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(skill.name,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark)),
          const SizedBox(width: 6),
          Text(
            '· ${skill.level}',
            style: const TextStyle(fontSize: 12, color: AppColors.orange),
          ),
        ],
      ),
    );
  }
}
