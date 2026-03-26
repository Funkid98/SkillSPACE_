import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/string_extension.dart';
import '../../../../core/utils/app_toast.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/cv_extraction_cubit.dart';
import '../../data/models/profile_model.dart';
import '../../../../core/app_colors.dart';
import '../../../../shared/widgets/animated_reveal.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/responsive.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileError) {
          AppToast.showError(context, state.message);
        }
      },
      child: BlocBuilder<ProfileCubit, ProfileState>(
        buildWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.orange));
          }
          if (state is ProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ProfileCubit>().loadProfile(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }
          return const _ProfileContent();
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hPad = Responsive.hPad(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          AnimatedReveal(
            delay: const Duration(milliseconds: 100),
            direction: RevealDirection.fromTop,
            child: Text(
              l10n.profile,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedReveal(
            delay: const Duration(milliseconds: 200),
            direction: RevealDirection.fromTop,
            child: Text(
              l10n.manageProfile,
              style: const TextStyle(fontSize: 15, color: AppColors.textGray),
            ),
          ),
          const SizedBox(height: 32),

          // Completion bar
          const AnimatedReveal(
            delay: Duration(milliseconds: 300),
            child: _CompletionCard(),
          ),

          // Main Content Grid
          Responsive.isMobile(context)
              ? Column(
                  children: [
                    const AnimatedReveal(
                      delay: Duration(milliseconds: 400),
                      child: _PersonalInfoCard(),
                    ),
                    const SizedBox(height: 24),
                    _buildCvAndSkills(context),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      flex: 3,
                      child: AnimatedReveal(
                        delay: Duration(milliseconds: 400),
                        child: _PersonalInfoCard(),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: _buildCvAndSkills(context),
                    ),
                  ],
                ),

          const SizedBox(height: 48),

          // Save button
          AnimatedReveal(
            delay: const Duration(milliseconds: 700),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () async {
                  await context.read<ProfileCubit>().saveProfile();
                  if (context.mounted) {
                    AppToast.showSuccess(context, 'Profil mis à jour !');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.saveChanges,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCvAndSkills(BuildContext context) {
    return Column(
      children: [
        // CV upload
        AnimatedReveal(
          delay: const Duration(milliseconds: 500),
          child: BlocProvider(
            create: (_) => CvExtractionCubit(),
            child: BlocBuilder<ProfileCubit, ProfileState>(
              buildWhen: (prev, curr) =>
                  curr is ProfileLoaded &&
                  (prev is! ProfileLoaded ||
                      prev.data.hasCv != curr.data.hasCv),
              builder: (context, state) {
                final hasCv = state is ProfileLoaded ? state.data.hasCv : false;
                return _CvCard(hasCv: hasCv);
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Skills
        const AnimatedReveal(
          delay: Duration(milliseconds: 600),
          child: _SkillsCard(),
        ),
      ],
    );
  }
}

// ─── Completion Card
class _CompletionCard extends StatelessWidget {
  const _CompletionCard();

  String _getHint(BuildContext context, ProfileData data, bool isSaved) {
    if (data.completionPercent == 100 && isSaved) {
      return 'Votre profil est complété !';
    }

    final List<String> missing = [];
    if (data.phone.isEmpty) missing.add('un numéro de téléphone');
    if (data.location.isEmpty) missing.add('une localisation');
    if (data.bio.isEmpty) missing.add('une bio');
    if (data.skills.isEmpty) missing.add('des compétences');
    if (!data.hasCv) missing.add('un CV');

    if (missing.isEmpty) return 'Complétez votre profil pour atteindre 100%';
    return 'Ajouter ${missing.first} pour compléter votre profil';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<ProfileCubit, ProfileState>(
      buildWhen: (prev, curr) =>
          curr is ProfileLoaded &&
          (prev is! ProfileLoaded ||
              prev.data.completionPercent != curr.data.completionPercent ||
              prev.isSaved != curr.isSaved),
      builder: (context, state) {
        final data = state is ProfileLoaded ? state.data : null;
        final isSaved = state is ProfileLoaded ? state.isSaved : false;
        final percent = data?.completionPercent ?? 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.profileCompleted,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 10,
                  backgroundColor: AppColors.border,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.navy),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                data != null
                    ? _getHint(context, data, isSaved)
                    : l10n.completeProfileHint,
                style: TextStyle(
                  fontSize: 13,
                  color: (percent == 100 && isSaved)
                      ? Colors.green
                      : AppColors.textGray,
                  fontWeight: (percent == 100 && isSaved)
                      ? FontWeight.bold
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

//Personal Info Card
class _PersonalInfoCard extends StatefulWidget {
  const _PersonalInfoCard();

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
  late final TextEditingController _poste;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ProfileCubit>();
    final data = cubit.state is ProfileLoaded
        ? (cubit.state as ProfileLoaded).data
        : null;

    _firstName = TextEditingController(text: data?.firstName ?? '');
    _lastName = TextEditingController(text: data?.lastName ?? '');
    _email = TextEditingController(text: data?.email ?? '');
    _phone = TextEditingController(text: data?.phone ?? '');
    _location = TextEditingController(text: data?.location ?? '');
    _bio = TextEditingController(text: data?.bio ?? '');
    _poste = TextEditingController(text: data?.poste ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _location.dispose();
    _bio.dispose();
    _poste.dispose();
    super.dispose();
  }

  void _updateCubit() {
    final cubit = context.read<ProfileCubit>();
    final currentData = (cubit.state as ProfileLoaded).data;
    cubit.updateField(currentData.copyWith(
      firstName: _firstName.text,
      lastName: _lastName.text,
      email: _email.text,
      phone: _phone.text,
      location: _location.text,
      bio: _bio.text,
      poste: _poste.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMobile = Responsive.isMobile(context);

    return BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            // Update controllers only if text is different to avoid cursor reset
            if (_firstName.text != state.data.firstName) {
              _firstName.text = state.data.firstName;
            }
            if (_lastName.text != state.data.lastName) {
              _lastName.text = state.data.lastName;
            }
            if (_email.text != state.data.email) _email.text = state.data.email;
            if (_phone.text != state.data.phone) _phone.text = state.data.phone;
            if (_location.text != state.data.location) {
              _location.text = state.data.location;
            }
            if (_bio.text != state.data.bio) _bio.text = state.data.bio;
            if (_poste.text != state.data.poste) {
              _poste.text = state.data.poste ?? '';
            }
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.personalInfo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 24),
              BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, state) {
                  final isRecruiter = state is ProfileLoaded &&
                      (state.data.role == 'recruteur' ||
                          state.data.role == 'recruiter');
                  if (isRecruiter) return const SizedBox.shrink();

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Field(
                            label: l10n.firstName,
                            controller: _firstName,
                            readOnly: true,
                            onChanged: (_) => _updateCubit()),
                        const SizedBox(height: 16),
                        _Field(
                            label: l10n.lastName,
                            controller: _lastName,
                            readOnly: true,
                            onChanged: (_) => _updateCubit()),
                        const SizedBox(height: 16),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: _Field(
                                  label: l10n.firstName,
                                  controller: _firstName,
                                  readOnly: true,
                                  onChanged: (_) => _updateCubit())),
                          const SizedBox(width: 20),
                          Expanded(
                              child: _Field(
                                  label: l10n.lastName,
                                  controller: _lastName,
                                  readOnly: true,
                                  onChanged: (_) => _updateCubit())),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
              if (isMobile) ...[
                _Field(
                  label: l10n.email,
                  controller: _email,
                  readOnly: true,
                  onChanged: (_) => _updateCubit(),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _Field(
                  label: l10n.phone,
                  controller: _phone,
                  readOnly: true,
                  onChanged: (_) => _updateCubit(),
                  keyboardType: TextInputType.phone,
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label: l10n.email,
                        controller: _email,
                        readOnly: true,
                        onChanged: (_) => _updateCubit(),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _Field(
                        label: l10n.phone,
                        controller: _phone,
                        readOnly: true,
                        onChanged: (_) => _updateCubit(),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              _Field(
                  label: l10n.location,
                  controller: _location,
                  readOnly: true,
                  onChanged: (_) => _updateCubit()),
              const SizedBox(height: 16),
              BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      _Field(
                        label: 'Poste',
                        controller: _poste,
                        readOnly: false,
                        onChanged: (_) => _updateCubit(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
              _Field(
                  label: l10n.bio,
                  controller: _bio,
                  maxLines: 4,
                  readOnly: true,
                  onChanged: (_) => _updateCubit()),
            ],
          ),
        ));
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          readOnly: readOnly,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: readOnly ? AppColors.textGray : AppColors.textDark,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? AppColors.bgAlt : AppColors.bg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: readOnly
                ? const Icon(Icons.lock_outline_rounded,
                    size: 16, color: AppColors.textGray)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: readOnly ? Colors.transparent : AppColors.navy,
                  width: 1.5),
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
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<CvExtractionCubit, CvExtractionState>(
      listener: (context, cvState) {
        if (cvState is CvExtractionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(cvState.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        if (cvState is CvExtractionSuccess) {
          context.read<ProfileCubit>().updateFromExtractedData(cvState.data);
          AppToast.showSuccess(context, 'CV analysé avec succès !');
        }
      },
      builder: (context, cvState) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.myCv,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),
              if (cvState is CvExtractionLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: AppColors.orange),
                        SizedBox(height: 16),
                        Text(
                          'Analyse du CV en cours…',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (cvState is CvExtractionSuccess)
                _CvSuccessView(data: cvState.data, l10n: l10n)
              else if (hasCv)
                _CvUploadedView(
                  l10n: l10n,
                  onReplace: () => _triggerUpload(context),
                )
              else
                _CvUploadArea(
                  l10n: l10n,
                  onTap: () => _triggerUpload(context),
                ),
            ],
          ),
        );
      },
    );
  }

  void _triggerUpload(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    if (!context.mounted) return;
    context.read<CvExtractionCubit>().pickAndUploadCv(token: token);
  }
}

class _CvUploadArea extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onTap;
  const _CvUploadArea({required this.l10n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          color: AppColors.bg.withOpacity(0.5),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_upload_rounded,
                size: 40, color: AppColors.textGray),
            const SizedBox(height: 12),
            Text(
              l10n.uploadHint,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.uploadFormatHint,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CvUploadedView extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onReplace;
  const _CvUploadedView({required this.l10n, required this.onReplace});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.picture_as_pdf_rounded,
                color: AppColors.orange, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'CV uploaded',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          TextButton(
            onPressed: onReplace,
            child: Text(
              l10n.replace,
              style: const TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CvSuccessView extends StatelessWidget {
  final Map<String, dynamic> data;
  final AppLocalizations l10n;
  const _CvSuccessView({required this.data, required this.l10n});
  @override
  Widget build(BuildContext context) {
    final skillsList = data['skills'] as List? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'CV analysé — ${(data['prenom'] ?? '').toString().capitalize()} ${(data['nom'] ?? '').toString().capitalize()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (skillsList.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skillsList.map((s) {
              String name = '';
              if (s is String) {
                name = s;
              } else if (s is Map) {
                name = s['name']?.toString() ?? '';
              }
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  name.capitalize(),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

// ─── Skills Card ───────────────────────────────────────────────────────────
class _SkillsCard extends StatefulWidget {
  const _SkillsCard();

  @override
  State<_SkillsCard> createState() => _SkillsCardState();
}

class _SkillsCardState extends State<_SkillsCard> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ProfileCubit, ProfileState>(
      buildWhen: (prev, curr) =>
          curr is ProfileLoaded &&
          (prev is! ProfileLoaded ||
              !listEquals(prev.data.skills, curr.data.skills)),
      builder: (context, state) {
        final rawSkills =
            state is ProfileLoaded ? state.data.skills : <ProfileSkill>[];

        // Sort skills by percentage descending
        final skills = List<ProfileSkill>.from(rawSkills)
          ..sort((a, b) => b.percent.compareTo(a.percent));
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.skills,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _editing = !_editing),
                    child: Text(
                      _editing ? 'Terminé' : l10n.edit,
                      style: TextStyle(
                          color: _editing ? AppColors.navy : AppColors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (skills.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('Aucune compétence ajoutée',
                        style:
                            TextStyle(color: AppColors.textGray, fontSize: 13)),
                  ),
                )
              else
                ...skills.asMap().entries.map((entry) => _SkillRow(
                      skill: entry.value,
                      index: entry.key,
                      editing: _editing,
                    )),
            ],
          ),
        );
      },
    );
  }
}

class _SkillRow extends StatelessWidget {
  final ProfileSkill skill;
  final int index;
  final bool editing;
  const _SkillRow(
      {required this.skill, required this.index, required this.editing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                skill.name.capitalize(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${skill.percent}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (editing)
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.navy,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.orange,
                overlayColor: AppColors.orange.withOpacity(0.15),
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: skill.percent.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                onChanged: (val) {
                  context
                      .read<ProfileCubit>()
                      .updateSkillPercent(index, val.round());
                },
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: skill.percent / 100,
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.navy),
              ),
            ),
        ],
      ),
    );
  }
}
