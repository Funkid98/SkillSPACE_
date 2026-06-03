import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:reactive_theme/reactive_theme.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:flutter/foundation.dart';
import 'package:pfe/core/network/cookie_service.dart';

import '../cubits/expertise_cubit.dart';
import '../cubits/profile_cubit.dart';
import '../cubits/profile_state.dart';
import '../cubits/trainer_cubit.dart';
import '../services/formateur_service.dart';
import '../models/formateur_model.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/delete_account_dialog.dart';

class FormateurProfileScreen extends StatefulWidget {
  const FormateurProfileScreen({super.key});

  @override
  State<FormateurProfileScreen> createState() => _FormateurProfileScreenState();
}

// ─── Wrapper to provide scoped Cubits ───────────────────────────────────────
class FormateurProfileScreenWrapper extends StatelessWidget {
  const FormateurProfileScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ExpertiseCubit(FormateurService())),
        BlocProvider(create: (_) => ProfileCubit(FormateurService())),
      ],
      child: const FormateurProfileScreen(),
    );
  }
}

class _FormateurProfileScreenState extends State<FormateurProfileScreen> {
  final FormateurService _formateurService = FormateurService();

  // Controllers for Text Inputs
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _portfolioController = TextEditingController();
  final _expertiseController = TextEditingController();

  PhoneNumber _number = PhoneNumber(isoCode: 'TN');
  String? _lastValidatedPortfolioUrl;
  bool _isInitialized = false;

  final Color primaryColor = const Color(0xFFE9652B);
  final Color darkColor = const Color(0xFF1A1C1E);

  @override
  void initState() {
    super.initState();
    _loadInitialProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _jobTitleController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _linkedInController.dispose();
    _portfolioController.dispose();
    _expertiseController.dispose();
    super.dispose();
  }

  // ─── Initialization ────────────────────────────────────────────────────────
  void _loadInitialProfile() {
    final userId = context.read<AuthCubit>().state.loggedInUser?['id'] ?? '';
    if (userId.isEmpty) return;

    final cachedProfile = context.read<TrainerCubit>().state.profileData;
    final profileCubit = context.read<ProfileCubit>();
    profileCubit.loadProfile(userId, cached: cachedProfile);

    if (profileCubit.state.status == ProfileStatus.loaded) {
      _populateControllers(profileCubit.state);
    }
  }

  void _populateControllers(ProfileState state) async {
    if (_isInitialized) return;
    _isInitialized = true;

    _firstNameController.text = state.firstName;
    _lastNameController.text = state.lastName;
    _emailController.text = state.email;
    _jobTitleController.text = state.jobTitle;
    _locationController.text = state.location;
    _bioController.text = state.bio;
    _linkedInController.text = state.linkedIn;
    _portfolioController.text = state.portfolio;

    try {
      if (state.phone.isNotEmpty) {
        final number =
            await PhoneNumber.getRegionInfoFromPhoneNumber(state.phone, 'TN');
        if (mounted) {
          setState(() {
            _number = number;
            if (number.dialCode != null &&
                state.phone.contains(number.dialCode!)) {
              _phoneController.text = state.phone
                  .replaceAll(number.dialCode!, '')
                  .replaceAll('+', '')
                  .trim();
            }
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error parsing phone number: $e');
    }
  }

  // ─── Actions ───────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 400,
      maxHeight: 400,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      if (mounted) {
        context.read<ProfileCubit>().updatePicture(bytes);
      }
    }
  }

  Future<void> _handleSaveProfile() async {
    final cubit = context.read<ProfileCubit>();
    final state = cubit.state;

    // Basic required fields validation
    if (state.firstName.isEmpty ||
        state.lastName.isEmpty ||
        state.email.isEmpty ||
        state.phone.isEmpty ||
        state.jobTitle.isEmpty ||
        state.location.isEmpty ||
        state.bio.isEmpty ||
        state.linkedIn.isEmpty ||
        state.expertise.isEmpty) {
      Fluttertoast.showToast(
          msg: "Veuillez remplir tous les champs obligatoires (*)",
          backgroundColor: Colors.red);
      return;
    }

    // LinkedIn Validation
    final linkedInRegex = RegExp(
        r'^https:\/\/(www\.|[a-z]{2}\.)?linkedin\.com\/in\/[a-zA-Z0-9_-]+\/?$');
    if (!linkedInRegex.hasMatch(state.linkedIn)) {
      Fluttertoast.showToast(
          msg:
              "Veuillez entrer un lien LinkedIn valide (https://linkedin.com/in/...)",
          backgroundColor: Colors.red);
      return;
    }

    // Smart Portfolio Validation
    final portfolioUrl = state.portfolio;
    if (portfolioUrl.isNotEmpty) {
      if (!portfolioUrl.startsWith('http')) {
        Fluttertoast.showToast(
            msg: "Le portfolio doit commencer par http:// ou https://",
            backgroundColor: Colors.red);
        return;
      }
      if (portfolioUrl != _lastValidatedPortfolioUrl) {
        final validation = await _formateurService.validateUrl(portfolioUrl);
        if (!mounted) return;

        if (validation['isValid'] == false) {
          Fluttertoast.showToast(
              msg: validation['reason'] ??
                  "Lien de portfolio invalide ou générique.",
              backgroundColor: Colors.orange,
              toastLength: Toast.LENGTH_LONG);
          return;
        }
        _lastValidatedPortfolioUrl = portfolioUrl;
      }
    }

    // Save using Cubit
    final success = await cubit.saveProfile();

    if (success && mounted) {
      final updatedModel = cubit.state.toModel();

      // Sync with global states
      context.read<TrainerCubit>().syncProfileWithDashboard(updatedModel);
      context.read<AuthCubit>().updateUserLocal({
        'firstName': updatedModel.firstName,
        'lastName': updatedModel.lastName,
        'email': updatedModel.email,
        'profilePicture': updatedModel.profilePicture,
      });

      Fluttertoast.showToast(
          msg: "Profil mis à jour !", backgroundColor: Colors.green);
    }
  }

  // ─── UI Builders ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = ReactiveMode.isDarkMode(context);

    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (previous, current) {
        return previous.status != current.status ||
            previous.bio != current.bio ||
            previous.errorMessage != current.errorMessage;
      },
      listener: (context, state) {
        if (state.status == ProfileStatus.loaded) {
          _populateControllers(state);
        }

        // Auto-update bio controller if generated by AI
        if (state.bio != _bioController.text && !state.isGeneratingBio) {
          _bioController.text = state.bio;
        }

        if (state.status == ProfileStatus.failure &&
            state.errorMessage != null) {
          Fluttertoast.showToast(
              msg: state.errorMessage!, backgroundColor: Colors.red);
        }
      },
      builder: (context, state) {
        if (state.status == ProfileStatus.loading && !_isInitialized) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE9652B)));
        }

        final isSaving = state.status == ProfileStatus.saving;
        final cubit = context.read<ProfileCubit>();

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mon profil formateur',
                    style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : darkColor)),
                const SizedBox(height: 8),
                Text('Gérez vos informations et domaines d\'expertise',
                    style: GoogleFonts.outfit(color: Colors.grey[600])),
                const SizedBox(height: 32),
                _buildCompletenessCard(state.profileCompleteness),
                const SizedBox(height: 32),
                _buildSectionCard('Informations personnelles', [
                  _buildResponsiveRow([
                    _buildInputField('Prénom', _firstNameController,
                        onChanged: cubit.updateFirstName),
                    _buildInputField('Nom', _lastNameController,
                        onChanged: cubit.updateLastName),
                  ]),
                  _buildResponsiveRow([
                    _buildInputField('Email', _emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: cubit.updateEmail),
                    _PhoneField(
                      label: 'Téléphone',
                      controller: _phoneController,
                      initialNumber: _number,
                      onChanged: (PhoneNumber number) {
                        cubit.updatePhone(number.phoneNumber ?? '');
                      },
                    ),
                  ]),
                  _buildResponsiveRow([
                    _buildInputField('Titre professionnel', _jobTitleController,
                        onChanged: cubit.updateJobTitle),
                    _buildInputField('Localisation', _locationController,
                        onChanged: cubit.updateLocation),
                  ]),
                  _buildInputField(
                    'Bio',
                    _bioController,
                    maxLines: 4,
                    onChanged: cubit.updateBio,
                    labelSuffix: GestureDetector(
                      onTap: state.isGeneratingBio
                          ? null
                          : () {
                              if (state.firstName.isEmpty ||
                                  state.jobTitle.isEmpty) {
                                Fluttertoast.showToast(
                                    msg:
                                        "Veuillez d'abord remplir votre prénom et titre professionnel",
                                    backgroundColor: Colors.orange);
                                return;
                              }
                              cubit.generateBio();
                            },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.isGeneratingBio)
                            const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Color(0xFFE9652B)))
                          else
                            const Icon(Icons.auto_awesome,
                                size: 14, color: Color(0xFFE9652B)),
                          const SizedBox(width: 4),
                          Text(
                            state.isGeneratingBio
                                ? 'Génération...'
                                : 'Générer avec IA',
                            style: const TextStyle(
                                color: Color(0xFFE9652B),
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 32),
                _buildSectionCard('Photo de profil', [
                  _buildPhotoUpload(
                      state.profilePictureBytes, state.profilePicture),
                ]),
                const SizedBox(height: 32),
                _buildSectionCard('Domaines d\'expertise', [
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: state.expertise
                            .map((e) =>
                                _buildExpertiseTag(e, cubit, state.expertise))
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                      _buildAddExpertiseField(cubit, state.expertise),
                    ],
                  ),
                ]),
                const SizedBox(height: 32),
                _buildSectionCard('Certifications & Diplômes', [
                  ...state.certifications
                      .map((c) => _buildCertificationItem(c, cubit)),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => _showAddCertificationDialog(cubit),
                    icon: const Icon(Icons.add,
                        size: 20, color: Color(0xFFE9652B)),
                    label: Text('Ajouter une certification',
                        style: TextStyle(
                            color: primaryColor, fontWeight: FontWeight.bold)),
                  )
                ]),
                const SizedBox(height: 32),
                _buildSectionCard('Liens professionnels', [
                  _buildResponsiveRow([
                    _buildInputField('LinkedIn', _linkedInController,
                        onChanged: cubit.updateLinkedIn),
                    _buildInputField(
                        'Portfolio / Site web', _portfolioController,
                        isRequired: false, onChanged: cubit.updatePortfolio),
                  ]),
                ]),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => BlocProvider.value(
                            value: context.read<TrainerCubit>(),
                            child: const DeleteAccountDialog(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Colors.red, width: 2),
                      ),
                      child: const Text('Supprimer le compte',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    if (CookieService.getString('auth_provider') != 'google' &&
                        CookieService.getString('auth_provider') !=
                            'github') ...[
                      OutlinedButton(
                        onPressed: () {
                          if (state.email.isNotEmpty) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) => ChangePasswordDialog(
                                email: state.email,
                                apiUrl: 'http://localhost:8088/api/formateur',
                              ),
                            );
                          } else {
                            Fluttertoast.showToast(
                                msg:
                                    "Email requis pour changer le mot de passe",
                                backgroundColor: Colors.red);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: primaryColor, width: 2),
                        ),
                        child: Text('Changer mot de passe',
                            style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                    ],
                    ElevatedButton(
                      onPressed: isSaving ? null : _handleSaveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: primaryColor.withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Enregistrer',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Component Extractors ──────────────────────────────────────────────────
  Widget _buildCompletenessCard(int score) {
    final isDark = ReactiveMode.isDarkMode(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: score.toDouble()),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withOpacity(0.5)
                  : Colors.white,
              borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Profil complété à',
                      style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF1E293B))),
                  Text('${value.toInt()}%',
                      style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor)),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: value / 100,
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey[100],
                  color: primaryColor,
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                  'Ajoutez une photo et des certifications pour renforcer votre crédibilité',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color:
              isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white,
          borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B))),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool isRequired = true,
    Widget? labelSuffix,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
  }) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color:
                          isDark ? Colors.white70 : const Color(0xFF1E293B))),
              if (isRequired)
                Text(' *',
                    style: GoogleFonts.outfit(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                        fontSize: 15)),
              if (labelSuffix != null) ...[
                const Spacer(),
                labelSuffix,
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B)),
            decoration: InputDecoration(
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark ? Colors.white10 : Colors.grey[200]!)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark ? Colors.white10 : Colors.grey[200]!)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFE9652B), width: 2)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUpload(Uint8List? bytes, String fallbackBase64) {
    final imageProvider = bytes != null
        ? MemoryImage(bytes)
        : (fallbackBase64.isNotEmpty
            ? MemoryImage(base64Decode(fallbackBase64))
            : null);

    return Center(
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 2),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: imageProvider != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image(image: imageProvider, fit: BoxFit.cover),
                    Container(color: Colors.black.withValues(alpha: 0.3)),
                    const Center(
                        child: Icon(Icons.camera_alt,
                            color: Colors.white, size: 36)),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        size: 36, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('Photo',
                        style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildExpertiseTag(
      String tag, ProfileCubit profileCubit, List<String> currentTags) {
    return GestureDetector(
      onTap: () {
        final newTags = currentTags.where((t) => t != tag).toList();
        profileCubit.updateExpertise(newTags);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tag,
                style: const TextStyle(
                    color: Color(0xFF4F46E5), fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            const Icon(Icons.close, size: 14, color: Color(0xFF4F46E5)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddExpertiseField(
      ProfileCubit profileCubit, List<String> currentTags) {
    final isDark = ReactiveMode.isDarkMode(context);
    final expertiseCubit = context.read<
        ExpertiseCubit>(); // We still use this purely for fetching AI suggestions

    void addTag(String tag) {
      if (tag.trim().isNotEmpty && !currentTags.contains(tag.trim())) {
        profileCubit.updateExpertise([...currentTags, tag.trim()]);
      }
      _expertiseController.clear();
      expertiseCubit.setInitialTags([]); // Clear suggestions visually
    }

    return BlocBuilder<ExpertiseCubit, ExpertiseState>(
      builder: (context, expertiseState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expertiseController,
                    style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B)),
                    onChanged: (value) =>
                        expertiseCubit.fetchSuggestions(value),
                    onSubmitted: addTag,
                    decoration: InputDecoration(
                      hintText: 'Saisir Votre Expertise ...',
                      hintStyle: TextStyle(
                          color: isDark ? Colors.white30 : Colors.grey[400],
                          fontSize: 14),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF9FAFB),
                      prefixIcon: const Icon(Icons.auto_awesome,
                          color: Color(0xFFE9652B), size: 20),
                      suffixIcon: expertiseState.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFE9652B))))
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color:
                                  isDark ? Colors.white10 : Colors.grey[200]!)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color:
                                  isDark ? Colors.white10 : Colors.grey[200]!)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFE9652B), width: 2)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => addTag(_expertiseController.text),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: const Color(0xFFE9652B),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
            if (expertiseState.showSuggestions &&
                expertiseState.suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              size: 14, color: Color(0xFFE9652B)),
                          const SizedBox(width: 6),
                          Text('Suggestions IA',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ...expertiseState.suggestions.map((s) => InkWell(
                          onTap: () => addTag(s),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.add_circle_outline,
                                    size: 16, color: Color(0xFF4F46E5)),
                                const SizedBox(width: 10),
                                Text(s,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCertificationItem(Certification c, ProfileCubit cubit) {
    final bool isPdf = c.fileType == 'pdf';
    final isDark = ReactiveMode.isDarkMode(context);
    // Use thumbnail first; for image-type certs fall back to fullFile
    final String? imageData = (c.image != null && c.image!.isNotEmpty)
        ? c.image
        : (!isPdf && c.fullFile != null && c.fullFile!.isNotEmpty)
            ? c.fullFile
            : null;

    Uint8List? decodedImage;
    if (imageData != null) {
      try {
        final cleanData =
            imageData.contains(',') ? imageData.split(',').last : imageData;
        final normalized = cleanData.replaceAll(RegExp(r'\s+'), '');
        final padded = normalized.padRight(
            normalized.length + (4 - normalized.length % 4) % 4, '=');
        decodedImage = base64Decode(padded);
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 6))
        ],
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[100]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 100,
                decoration: BoxDecoration(
                  color: isPdf ? const Color(0xFFFEF2F2) : Colors.grey[50]!,
                  border: Border(right: BorderSide(color: Colors.grey[100]!)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: decodedImage != null
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.memory(
                                decodedImage,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                        isPdf
                                            ? Icons.description
                                            : Icons.workspace_premium,
                                        color: isPdf
                                            ? Colors.redAccent.withOpacity(0.5)
                                            : const Color(0xFFE9652B),
                                        size: 32),
                              ),
                            )
                          : Icon(
                              isPdf
                                  ? Icons.description
                                  : Icons.workspace_premium,
                              color: isPdf
                                  ? Colors.redAccent.withOpacity(0.5)
                                  : const Color(0xFFE9652B),
                              size: 32),
                    ),
                    if (isPdf)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(4)),
                          child: const Icon(Icons.picture_as_pdf,
                              color: Colors.white, size: 10),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c.name,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text('${c.issuer} • ${c.year}',
                          style: GoogleFonts.outfit(
                              color: Colors.grey[500], fontSize: 14)),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                      icon: const Icon(Icons.visibility_outlined,
                          color: Color(0xFFE9652B), size: 22),
                      onPressed: () => _showFilePreview(c)),
                  IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 22),
                      onPressed: () => cubit.removeCertification(c)),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Dialogs & Modals ──────────────────────────────────────────────────────
  void _showFilePreview(Certification c) {
    if (c.fullFile == null && (c.image == null || c.image!.isEmpty)) return;
    final bytes = base64Decode(c.fullFile ?? c.image!);
    final isPdf = c.fileType == 'pdf';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(c.name,
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold, fontSize: 18),
                            overflow: TextOverflow.ellipsis)),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: isPdf
                      ? _PdfViewer(pdfBytes: bytes)
                      : InteractiveViewer(
                          child: Image.memory(bytes,
                              fit: BoxFit.contain, width: double.infinity)),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                    isPdf
                        ? 'Visualisation PDF multi-pages'
                        : 'Visualisation Image',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _generateThumbnailFromPdf(Uint8List pdfBytes) async {
    if (pdfBytes.isEmpty) return null;
    try {
      final document = await PdfDocument.openData(pdfBytes);
      final page = await document.getPage(1);
      final double renderWidth = 220.0;
      final double renderHeight = page.width > 0
          ? (page.height / page.width * renderWidth)
          : renderWidth;

      final pageImage = await page.render(
          width: renderWidth,
          height: renderHeight,
          format: PdfPageImageFormat.png,
          quality: 80);
      await page.close();
      await document.close();

      return pageImage != null ? base64Encode(pageImage.bytes) : null;
    } catch (e) {
      debugPrint('Pdf thumbnail error: $e');
      return null;
    }
  }

  void _showAddCertificationDialog(ProfileCubit cubit) {
    final nameController = TextEditingController();
    final issuerController = TextEditingController();
    final yearController = TextEditingController();
    String? selectedThumbnailBase64;
    String? selectedFullFileBase64;
    String fileType = 'image';
    bool isGeneratingThumbnail = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  const Icon(Icons.add_moderator, color: Color(0xFFE9652B)),
                  const SizedBox(width: 12),
                  Text('Certification / Diplôme',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPopupField(
                          'Nom', nameController, 'ex: Master Cloud'),
                      _buildPopupField(
                          'Organisme', issuerController, 'ex: AWS'),
                      _buildPopupField('Année', yearController, 'ex: 2024',
                          keyboard: TextInputType.number),
                      const SizedBox(height: 16),
                      RepaintBoundary(
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: GestureDetector(
                            onTap: () async {
                              FilePickerResult? result =
                                  await FilePicker.platform.pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: ['jpg', 'png', 'pdf']);
                              if (result != null) {
                                final file = result.files.first;
                                Uint8List? actualBytes = file.bytes;
                                if (actualBytes != null) {
                                  setDialogState(() {
                                    isGeneratingThumbnail = true;
                                    selectedFullFileBase64 =
                                        base64Encode(actualBytes);
                                    fileType = file.extension == 'pdf'
                                        ? 'pdf'
                                        : 'image';
                                  });

                                  if (fileType == 'pdf') {
                                    final thumb =
                                        await _generateThumbnailFromPdf(
                                            actualBytes);
                                    setDialogState(() {
                                      selectedThumbnailBase64 = thumb;
                                      isGeneratingThumbnail = false;
                                    });
                                  } else {
                                    setDialogState(() {
                                      selectedThumbnailBase64 =
                                          selectedFullFileBase64;
                                      isGeneratingThumbnail = false;
                                    });
                                  }
                                }
                              }
                            },
                            child: Center(
                              child: isGeneratingThumbnail
                                  ? const CircularProgressIndicator(
                                      color: Color(0xFFE9652B))
                                  : selectedThumbnailBase64 != null
                                      ? Stack(
                                          children: [
                                            Center(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Image.memory(
                                                    base64Decode(
                                                        selectedThumbnailBase64!),
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: 140,
                                                    errorBuilder: (context,
                                                            error,
                                                            stackTrace) =>
                                                        const Icon(
                                                            Icons
                                                                .workspace_premium,
                                                            color: Color(
                                                                0xFFE9652B),
                                                            size: 32)),
                                              ),
                                            ),
                                            Positioned(
                                                top: 8,
                                                right: 8,
                                                child: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration:
                                                        const BoxDecoration(
                                                            color:
                                                                Colors.black54,
                                                            shape: BoxShape
                                                                .circle),
                                                    child: const Icon(
                                                        Icons.edit,
                                                        color: Colors.white,
                                                        size: 14))),
                                            Positioned(
                                                bottom: 8,
                                                right: 8,
                                                child: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration:
                                                        const BoxDecoration(
                                                            color: Colors.white,
                                                            shape: BoxShape
                                                                .circle),
                                                    child: const Icon(
                                                        Icons.check,
                                                        color: Colors.green,
                                                        size: 16))),
                                          ],
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.cloud_upload_outlined,
                                                color: Colors.grey[400],
                                                size: 32),
                                            const SizedBox(height: 8),
                                            Text('Cliquer pour télécharger',
                                                style: GoogleFonts.outfit(
                                                    color: Colors.grey[700],
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            Text('JPG, PNG, PDF (max 10MB)',
                                                style: TextStyle(
                                                    color: Colors.grey[500],
                                                    fontSize: 12)),
                                          ],
                                        ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler',
                        style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty ||
                        issuerController.text.trim().isEmpty ||
                        yearController.text.trim().isEmpty) {
                      return;
                    }
                    cubit.addCertification(Certification(
                      name: nameController.text.trim(),
                      issuer: issuerController.text.trim(),
                      year: yearController.text.trim(),
                      image: selectedThumbnailBase64,
                      fileType: fileType,
                      fullFile: selectedFullFileBase64,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE9652B),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Ajouter',
                      style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 8),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPopupField(
      String label, TextEditingController controller, String hint,
      {TextInputType keyboard = TextInputType.text}) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.grey[700])),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: isDark ? Colors.white30 : Colors.grey[400],
                  fontSize: 14),
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark ? Colors.white10 : Colors.grey[200]!)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark ? Colors.white10 : Colors.grey[200]!)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFE9652B), width: 2)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveRow(List<Widget> children) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 600) return Column(children: children);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .expand((w) => [
                  Expanded(child: w),
                  if (w != children.last) const SizedBox(width: 24)
                ])
            .toList(),
      );
    });
  }
}

// ─── Extracted Widgets ───────────────────────────────────────────────────────
class _PdfViewer extends StatefulWidget {
  final Uint8List pdfBytes;
  const _PdfViewer({required this.pdfBytes});

  @override
  State<_PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<_PdfViewer> {
  late PdfController _pdfController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    try {
      _pdfController =
          PdfController(document: PdfDocument.openData(widget.pdfBytes));
    } catch (e) {
      debugPrint('Error initializing PDF viewer: $e');
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    if (!_hasError) _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(child: Text("Erreur lors de l'ouverture du PDF"));
    }
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth > 0 ? constraints.maxWidth : 400.0;
      final height = constraints.maxHeight > 0 ? constraints.maxHeight : 600.0;
      return RepaintBoundary(
          child: SizedBox(
              width: width,
              height: height,
              child: PdfView(controller: _pdfController)));
    });
  }
}

class _PhoneField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final PhoneNumber initialNumber;
  final ValueChanged<PhoneNumber> onChanged;

  const _PhoneField({
    required this.label,
    required this.controller,
    required this.initialNumber,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : const Color(0xFF1E293B))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey[200]!, width: 1),
            ),
            child: InternationalPhoneNumberInput(
              onInputChanged: onChanged,
              textFieldController: controller,
              initialValue: initialNumber,
              formatInput: false,
              selectorConfig: const SelectorConfig(
                  selectorType: PhoneInputSelectorType.DIALOG,
                  setSelectorButtonAsPrefixIcon: true,
                  leadingPadding: 0),
              ignoreBlank: false,
              autoValidateMode: AutovalidateMode.onUserInteraction,
              selectorTextStyle: GoogleFonts.outfit(
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
              textStyle: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF1E293B)),
              inputDecoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  fillColor: Colors.transparent,
                  filled: true),
            ),
          ),
        ],
      ),
    );
  }
}
