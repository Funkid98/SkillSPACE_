import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:reactive_theme/reactive_theme.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import '../cubits/expertise_cubit.dart';
import '../services/formateur_service.dart';
import '../models/formateur_model.dart';
import '../cubits/trainer_cubit.dart';
import '../cubits/trainer_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:flutter/foundation.dart';

class FormateurProfileScreen extends StatefulWidget {
  const FormateurProfileScreen({super.key});

  @override
  State<FormateurProfileScreen> createState() => _FormateurProfileScreenState();
}

// Wrap in BlocProvider so ExpertiseCubit is scoped to this screen only
class FormateurProfileScreenWrapper extends StatelessWidget {
  const FormateurProfileScreenWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExpertiseCubit(FormateurService()),
      child: const FormateurProfileScreen(),
    );
  }
}

class _FormateurProfileScreenState extends State<FormateurProfileScreen> {
  final FormateurService _formateurService = FormateurService();
  bool _isLoading = true;
  bool _isGeneratingBio = false;
  String? _lastValidatedPortfolioUrl;
  Map<String, String> _originalProfile =
      {}; // tracks what was loaded from server

  String _profilePictureBase64 = '';
  List<Certification> certificationsList = [];
  PhoneNumber _number = PhoneNumber(isoCode: 'TN');

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

  final Color primaryColor = const Color(0xFFE9652B);
  final Color darkColor = const Color(0xFF1A1C1E);

  @override
  void initState() {
    super.initState();
    _loadProfile();
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

  Future<void> _initPhoneNumber(String text) async {
    try {
      final number = await PhoneNumber.getRegionInfoFromPhoneNumber(text, 'TN');
      setState(() {
        _number = number;
        if (number.dialCode != null && text.contains(number.dialCode!)) {
          final national =
              text.replaceAll(number.dialCode!, '').replaceAll('+', '').trim();
          _phoneController.text = national;
        }
      });
    } catch (e) {
      if (kDebugMode) print('Error parsing phone number: $e');
    }
  }

  Future<void> _loadProfile() async {
    final userId = context.read<AuthCubit>().state.loggedInUser?['id'] ?? '';
    if (userId.isEmpty) return;

    // Check if we already have it in TrainerCubit
    final trainerState = context.read<TrainerCubit>().state;
    FormateurModel? profile;

    if (trainerState.profileData != null) {
      profile = trainerState.profileData;
      _isLoading = false; // Don't show spinner if we have cache
    } else {
      setState(() => _isLoading = true);
      profile = await _formateurService.getProfile(userId);
    }

    if (!mounted) return;

    if (profile != null) {
      context.read<ExpertiseCubit>().setInitialTags(profile.expertise.toList());
      _lastValidatedPortfolioUrl = profile.portfolio; // Initial cache
      if (!mounted) return;
      setState(() {
        _firstNameController.text = profile!.firstName;
        _lastNameController.text = profile.lastName;
        _emailController.text = profile.email;
        _initPhoneNumber(profile.phone);
        _jobTitleController.text = profile.jobTitle;
        _locationController.text = profile.location;
        _bioController.text = profile.bio;
        _linkedInController.text = profile.linkedIn;
        _portfolioController.text = profile.portfolio;
        _profilePictureBase64 = profile.profilePicture;
        certificationsList = profile.certifications;
        _isLoading = false;
        // Snapshot original values for change detection
        _originalProfile = {
          'firstName': profile.firstName,
          'lastName': profile.lastName,
          'phone': profile.phone,
          'jobTitle': profile.jobTitle,
          'location': profile.location,
          'bio': profile.bio,
          'linkedIn': profile.linkedIn,
          'portfolio': profile.portfolio,
        };
      });
    } else {
      // Defaults if not found
      context.read<ExpertiseCubit>().setInitialTags(
          ["React", "JavaScript", "Python", "Data Science", "UX Design"]);
      setState(() {
        final authState = context.read<AuthCubit>().state.loggedInUser;
        _firstNameController.text = authState?['firstName'] ?? '';
        _lastNameController.text = authState?['lastName'] ?? '';
        _emailController.text = authState?['email'] ?? '';
        _phoneController.text = '';
        _jobTitleController.text = 'Formatrice senior en développement web';
        _locationController.text = '';
        _bioController.text =
            "Formatrice passionnée avec 8 ans d'expérience dans le développement web et la data science. J'accompagne les jeunes diplômés dans leur montée en compétences pour faciliter leur insertion professionnelle.";
        _linkedInController.text = '';
        _portfolioController.text = '';
        certificationsList = [
          Certification(
              name: 'Certified Scrum Master (CSM)',
              issuer: 'Scrum Alliance',
              year: '2023'),
          Certification(
              name: 'Google Professional Data Engineer',
              issuer: 'Google Cloud',
              year: '2022')
        ];
        _isLoading = false;
      });
    }
  }

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
      if (!mounted) return;
      setState(() {
        _profilePictureBase64 = base64Encode(bytes);
      });
    }
  }

  void _showFilePreview(Certification c) {
    if (c.fullFile == null && (c.image == null || c.image!.isEmpty)) return;

    final bytes = base64Decode(c.fullFile ?? c.image!);
    final isPdf = c.fileType == 'pdf';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                            overflow: TextOverflow.ellipsis),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: isPdf
                        ? _PdfViewer(pdfBytes: bytes)
                        : InteractiveViewer(
                            child: Image.memory(
                              bytes,
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    isPdf
                        ? 'Visualisation PDF multi-pages'
                        : 'Visualisation Image',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _generateThumbnailFromPdf(Uint8List pdfBytes) async {
    if (pdfBytes.isEmpty) return null;
    try {
      final document = await PdfDocument.openData(pdfBytes);
      final page = await document.getPage(1);

      // Smaller thumbnail for faster upload
      final double renderWidth = 220.0;
      final double renderHeight = page.width > 0
          ? (page.height / page.width * renderWidth)
          : renderWidth;

      final pageImage = await page.render(
        width: renderWidth,
        height: renderHeight,
        format: PdfPageImageFormat.png,
        quality: 80,
      );

      await page.close();
      await document.close();

      return pageImage != null ? base64Encode(pageImage.bytes) : null;
    } catch (e) {
      debugPrint('Pdf thumbnail error: $e');
      return null;
    }
  }

  Future<void> _handleGenerateBio() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final jobTitle = _jobTitleController.text.trim();
    final expertise = context.read<ExpertiseCubit>().state.tags;

    if (firstName.isEmpty || jobTitle.isEmpty) {
      Fluttertoast.showToast(
          msg: "Veuillez d'abord remplir votre prénom et titre professionnel",
          backgroundColor: Colors.orange);
      return;
    }

    setState(() => _isGeneratingBio = true);

    final generatedBio = await _formateurService.generateBio(
      "$firstName $lastName",
      jobTitle,
      expertise,
    );

    if (!mounted) return;
    setState(() {
      _isGeneratingBio = false;
      if (generatedBio != null && generatedBio.isNotEmpty) {
        _bioController.text = generatedBio;
        Fluttertoast.showToast(
            msg: "Bio générée ! Vous pouvez la modifier.",
            backgroundColor: Colors.blue);
      } else {
        Fluttertoast.showToast(
            msg: "Échec de la génération de la bio",
            backgroundColor: Colors.red);
      }
    });
  }

  int _calculateCompleteness() {
    int score = 0;
    // Basic fields (8 fields * 10% = 80%)
    if (_firstNameController.text.trim().isNotEmpty) score += 10;
    if (_lastNameController.text.trim().isNotEmpty) score += 10;
    if (_emailController.text.trim().isNotEmpty) score += 10;
    if (_phoneController.text.trim().isNotEmpty) score += 10;
    if (_jobTitleController.text.trim().isNotEmpty) score += 10;
    if (_locationController.text.trim().isNotEmpty) score += 10;
    if (_bioController.text.trim().isNotEmpty) score += 10;
    if (_linkedInController.text.trim().isNotEmpty) score += 10;

    // Photo (10%)
    if (_profilePictureBase64.isNotEmpty) score += 10;

    // Expertise (10%)
    // Since expertise is in Cubit, it's safer to check the cubit state or the local list if you have one
    if (context.read<ExpertiseCubit>().state.tags.isNotEmpty) score += 10;

    return score > 100 ? 100 : score;
  }

  /// Returns only the simple text fields that differ from the original snapshot.
  /// Returns null if anything heavy changed (picture, certifications, expertise).
  Map<String, String>? _getChangedSimpleFields() {
    final current = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phone': _number.phoneNumber ?? _phoneController.text.trim(),
      'jobTitle': _jobTitleController.text.trim(),
      'location': _locationController.text.trim(),
      'bio': _bioController.text.trim(),
      'linkedIn': _linkedInController.text.trim(),
      'portfolio': _portfolioController.text.trim(),
    };

    final changed = <String, String>{};
    current.forEach((key, value) {
      if (_originalProfile[key] != value) changed[key] = value;
    });

    return changed.isEmpty ? {} : changed;
  }

  Future<void> _saveProfile() async {
    if (_isLoading) return;
    final userId = context.read<AuthCubit>().state.loggedInUser?['id'] ?? '';
    if (userId.isEmpty) return;

    final expertiseTags = context.read<ExpertiseCubit>().state.tags;

    // --- Fast path: only simple text fields changed ---
    final changedFields = _getChangedSimpleFields();
    final expertiseChanged =
        expertiseTags.join(',') != (_originalProfile['expertise'] ?? '');
    final pictureChanged =
        _profilePictureBase64 != (_originalProfile['profilePicture'] ?? '');
    final certsChanged = certificationsList.length.toString() !=
        (_originalProfile['certCount'] ?? '0');

    if (changedFields != null &&
        !expertiseChanged &&
        !pictureChanged &&
        !certsChanged) {
      if (changedFields.isEmpty) {
        Fluttertoast.showToast(
            msg: "Aucune modification détectée", backgroundColor: Colors.grey);
        return;
      }

      // Validate LinkedIn only if it was changed
      if (changedFields.containsKey('linkedIn')) {
        final linkedInRegex = RegExp(
            r'^https:\/\/(www\.|[a-z]{2}\.)?linkedin\.com\/in\/[a-zA-Z0-9_-]+\/?$');
        if (!linkedInRegex.hasMatch(changedFields['linkedIn']!)) {
          Fluttertoast.showToast(
              msg: "Veuillez entrer un lien LinkedIn valide",
              backgroundColor: Colors.red);
          return;
        }
      }

      setState(() => _isLoading = true);
      final patched =
          await _formateurService.patchProfile(userId, changedFields);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (patched != null) {
        // Update snapshot
        changedFields.forEach((k, v) => _originalProfile[k] = v);
        context.read<TrainerCubit>().syncProfileWithDashboard(patched);
        Fluttertoast.showToast(
            msg: "Profil mis à jour !", backgroundColor: Colors.green);
      } else {
        Fluttertoast.showToast(
            msg: "Échec de la mise à jour", backgroundColor: Colors.red);
      }
      return;
    }

    // --- Full path: expertise / picture / certifications changed ---
    final currentCompleteness = _calculateCompleteness();

    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _jobTitleController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _bioController.text.trim().isEmpty ||
        _linkedInController.text.trim().isEmpty ||
        expertiseTags.isEmpty) {
      Fluttertoast.showToast(
          msg: "Veuillez remplir tous les champs obligatoires (*)",
          backgroundColor: Colors.red);
      return;
    }

    // 1. Basic LinkedIn Validation (Regex)
    final linkedInUrl = _linkedInController.text.trim();
    final linkedInRegex = RegExp(
        r'^https:\/\/(www\.|[a-z]{2}\.)?linkedin\.com\/in\/[a-zA-Z0-9_-]+\/?$');
    if (!linkedInRegex.hasMatch(linkedInUrl)) {
      Fluttertoast.showToast(
          msg:
              "Veuillez entrer un lien LinkedIn valide (https://linkedin.com/in/...)",
          backgroundColor: Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    // 2. Smart Portfolio Validation (AI)
    final portfolioUrl = _portfolioController.text.trim();
    if (portfolioUrl.isNotEmpty) {
      if (!portfolioUrl.startsWith('http')) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
            msg: "Le portfolio doit commencer par http:// ou https://",
            backgroundColor: Colors.red);
        return;
      }

      // Call AI Validation only if URL changed
      if (portfolioUrl != _lastValidatedPortfolioUrl) {
        final validation = await _formateurService.validateUrl(portfolioUrl);
        if (!mounted) return;

        if (validation['isValid'] == false) {
          setState(() => _isLoading = false);
          Fluttertoast.showToast(
              msg: validation['reason'] ??
                  "Lien de portfolio invalide ou générique.",
              backgroundColor: Colors.orange,
              toastLength: Toast.LENGTH_LONG);
          return;
        }
        _lastValidatedPortfolioUrl = portfolioUrl; // Cache result
      }
    }

    final newProfile = FormateurModel(
      id: '',
      userId: userId,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      phone: _number.phoneNumber ?? _phoneController.text,
      jobTitle: _jobTitleController.text,
      location: _locationController.text,
      bio: _bioController.text,
      profilePicture: _profilePictureBase64,
      profileCompleteness: currentCompleteness,
      expertise: expertiseTags,
      certifications: certificationsList,
      linkedIn: linkedInUrl,
      portfolio: portfolioUrl,
    );

    final updatedProfile =
        await _formateurService.updateProfile(userId, newProfile);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (updatedProfile != null) {
      // Update the snapshot for future change detection
      _originalProfile = {
        'firstName': updatedProfile.firstName,
        'lastName': updatedProfile.lastName,
        'phone': updatedProfile.phone,
        'jobTitle': updatedProfile.jobTitle,
        'location': updatedProfile.location,
        'bio': updatedProfile.bio,
        'linkedIn': updatedProfile.linkedIn,
        'portfolio': updatedProfile.portfolio,
        'expertise': updatedProfile.expertise.join(','),
        'profilePicture': updatedProfile.profilePicture,
        'certCount': updatedProfile.certifications.length.toString(),
      };

      // Sync with TrainerCubit
      context.read<TrainerCubit>().syncProfileWithDashboard(updatedProfile);

      context.read<AuthCubit>().updateUserLocal({
        'firstName': updatedProfile.firstName,
        'lastName': updatedProfile.lastName,
        'email': updatedProfile.email,
        'profilePicture': updatedProfile.profilePicture,
      });
      Fluttertoast.showToast(
          msg: "Profil mis à jour !", backgroundColor: Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ReactiveMode.isDarkMode(context);

    return BlocBuilder<TrainerCubit, TrainerState>(
      builder: (context, state) {
        if (_isLoading && state.profileData == null) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE9652B)));
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    child: Text('Mon profil formateur',
                        style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : darkColor)),
                  ),
                  const SizedBox(height: 8),
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                        'Gérez vos informations et domaines d\'expertise',
                        style: GoogleFonts.outfit(color: Colors.grey[600])),
                  ),
                  const SizedBox(height: 32),
                  FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: _buildCompletenessCard()),
                  const SizedBox(height: 32),
                  _buildSectionCard('Informations personnelles', [
                    _buildResponsiveRow([
                      _buildInputField('Prénom', _firstNameController),
                      _buildInputField('Nom', _lastNameController),
                    ]),
                    _buildResponsiveRow([
                      _buildInputField('Email', _emailController,
                          keyboardType: TextInputType.emailAddress),
                      _PhoneField(
                        label: 'Téléphone',
                        controller: _phoneController,
                        initialNumber: _number,
                        onChanged: (PhoneNumber number) {
                          setState(() {
                            _number = number;
                          });
                        },
                      ),
                    ]),
                    _buildResponsiveRow([
                      _buildInputField(
                          'Titre professionnel', _jobTitleController),
                      _buildInputField('Localisation', _locationController),
                    ]),
                    _buildInputField(
                      'Bio',
                      _bioController,
                      maxLines: 4,
                      labelSuffix: GestureDetector(
                        onTap: _isGeneratingBio ? null : _handleGenerateBio,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isGeneratingBio)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Color(0xFFE9652B)),
                              )
                            else
                              const Icon(Icons.auto_awesome,
                                  size: 14, color: Color(0xFFE9652B)),
                            const SizedBox(width: 4),
                            Text(
                              _isGeneratingBio
                                  ? 'Génération...'
                                  : 'Générer avec IA',
                              style: const TextStyle(
                                color: Color(0xFFE9652B),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionCard('Photo de profil', [
                    _buildPhotoUpload(),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionCard('Domaines d\'expertise', [
                    const SizedBox(height: 8),
                    BlocBuilder<ExpertiseCubit, ExpertiseState>(
                      builder: (context, expertiseState) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: expertiseState.tags
                                  .map((e) => _buildExpertiseTag(e))
                                  .toList(),
                            ),
                            const SizedBox(height: 24),
                            _buildAddExpertiseField(expertiseState),
                          ],
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionCard('Certifications & Diplômes', [
                    ...certificationsList
                        .map((c) => _buildCertificationItem(c)),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _showAddCertificationDialog,
                      icon: const Icon(Icons.add,
                          size: 20, color: Color(0xFFE9652B)),
                      label: Text('Ajouter une certification',
                          style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold)),
                    )
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionCard('Liens professionnels', [
                    _buildResponsiveRow([
                      _buildInputField('LinkedIn', _linkedInController),
                      _buildInputField(
                          'Portfolio / Site web', _portfolioController,
                          isRequired: false),
                    ]),
                  ]),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Color(0xFF1E293B)),
                        ),
                        child: const Text('Annuler',
                            style: TextStyle(
                                color: Color(0xFF1E293B),
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              primaryColor.withOpacity(0.6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Enregistrer',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletenessCard() {
    final currentScore = _calculateCompleteness();
    final isDark = ReactiveMode.isDarkMode(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: currentScore.toDouble()),
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

  Widget _buildInputField(String label, TextEditingController controller,
      {int maxLines = 1,
      bool isRequired = true,
      Widget? labelSuffix,
      TextInputType keyboardType = TextInputType.text,
      List<TextInputFormatter>? inputFormatters}) {
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

  Widget _buildPhotoUpload() {
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
                offset: const Offset(0, 4),
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: _profilePictureBase64.isNotEmpty
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      base64Decode(_profilePictureBase64),
                      fit: BoxFit.cover,
                    ),
                    Container(color: Colors.black.withValues(alpha: 0.3)),
                    const Center(
                      child:
                          Icon(Icons.camera_alt, color: Colors.white, size: 36),
                    ),
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

  Widget _buildExpertiseTag(String tag) {
    return GestureDetector(
      onTap: () => context.read<ExpertiseCubit>().removeTag(tag),
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

  Widget _buildAddExpertiseField(ExpertiseState expertiseState) {
    final cubit = context.read<ExpertiseCubit>();
    final isDark = ReactiveMode.isDarkMode(context);
    return StatefulBuilder(
      builder: (context, localSetState) {
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
                    onChanged: (value) => cubit.fetchSuggestions(value),
                    onSubmitted: (value) {
                      cubit.addTag(value);
                      _expertiseController.clear();
                    },
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
                                      color: Color(0xFFE9652B))),
                            )
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
                  onTap: () {
                    cubit.addTag(_expertiseController.text);
                    _expertiseController.clear();
                  },
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
                          onTap: () => cubit.addTag(s),
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

  Widget _buildCertificationItem(Certification c) {
    bool isPdf = c.fileType == 'pdf';

    final isDark = ReactiveMode.isDarkMode(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[100]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Preview/Icon Area
              Container(
                width: 100,
                decoration: BoxDecoration(
                  color: isPdf ? const Color(0xFFFEF2F2) : Colors.grey[50]!,
                  border: Border(right: BorderSide(color: Colors.grey[100]!)),
                ),
                child: Center(
                  child: c.image != null && c.image!.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              base64Decode(c.image!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child: Icon(Icons.workspace_premium,
                                    color: Color(0xFFE9652B), size: 32),
                              ),
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
                        )
                      : const Icon(Icons.workspace_premium,
                          color: Color(0xFFE9652B), size: 32),
                ),
              ),
              // Content Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        c.name,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${c.issuer} • ${c.year}',
                        style: GoogleFonts.outfit(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Action Area
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined,
                        color: Color(0xFFE9652B), size: 22),
                    onPressed: () {
                      _showFilePreview(c);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 22),
                    onPressed: () {
                      setState(() {
                        certificationsList.remove(c);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCertificationDialog() {
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
                width: 500, // Fixed width helps IntrinsicWidth in AlertDialog
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
                                allowedExtensions: ['jpg', 'png', 'pdf'],
                              );

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
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      const Icon(
                                                          Icons
                                                              .workspace_premium,
                                                          color:
                                                              Color(0xFFE9652B),
                                                          size: 32),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.edit,
                                                    color: Colors.white,
                                                    size: 14),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.check,
                                                    color: Colors.green,
                                                    size: 16),
                                              ),
                                            ),
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
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty ||
                        issuerController.text.trim().isEmpty ||
                        yearController.text.trim().isEmpty) {
                      return;
                    }
                    setState(() {
                      certificationsList.add(Certification(
                        name: nameController.text.trim(),
                        issuer: issuerController.text.trim(),
                        year: yearController.text.trim(),
                        image: selectedThumbnailBase64,
                        fileType: fileType,
                        fullFile: selectedFullFileBase64,
                      ));
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE9652B),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
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
      if (constraints.maxWidth < 600) {
        return Column(children: children);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .expand((w) => [
                  Expanded(child: w),
                  if (w != children.last) const SizedBox(width: 24),
                ])
            .toList(),
      );
    });
  }
}

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
      _pdfController = PdfController(
        document: PdfDocument.openData(widget.pdfBytes),
      );
    } catch (e) {
      debugPrint('Error initializing PDF viewer: $e');
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    if (!_hasError) {
      _pdfController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(child: Text("Erreur lors de l'ouverture du PDF"));
    }
    return LayoutBuilder(builder: (context, constraints) {
      // Force finite dimensions for Web renderer
      final width = constraints.maxWidth > 0 ? constraints.maxWidth : 400.0;
      final height = constraints.maxHeight > 0 ? constraints.maxHeight : 600.0;

      return RepaintBoundary(
        child: SizedBox(
          width: width,
          height: height,
          child: PdfView(
            controller: _pdfController,
          ),
        ),
      );
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
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
              ),
            ),
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
                leadingPadding: 0,
              ),
              ignoreBlank: false,
              autoValidateMode: AutovalidateMode.onUserInteraction,
              selectorTextStyle: GoogleFonts.outfit(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textStyle: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              inputDecoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                fillColor: Colors.transparent,
                filled: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
