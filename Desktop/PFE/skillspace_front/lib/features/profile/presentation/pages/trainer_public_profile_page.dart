import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_theme/reactive_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/profile_api.dart';
import '../../../../core/app_colors.dart';

class TrainerPublicProfilePage extends StatefulWidget {
  final String trainerId;

  const TrainerPublicProfilePage({super.key, required this.trainerId});

  @override
  State<TrainerPublicProfilePage> createState() =>
      _TrainerPublicProfilePageState();
}

class _TrainerPublicProfilePageState extends State<TrainerPublicProfilePage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _trainerProfile;
  String? _errorMessage;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _fetchTrainerProfile();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchTrainerProfile() async {
    try {
      final data = await ProfileApi.getTrainerPublicProfile(widget.trainerId);
      if (mounted) {
        setState(() {
          _trainerProfile = data;
          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Impossible de charger le profil du formateur.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    String fullUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      fullUrl = 'https://$url';
    }
    final uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    await Clipboard.setData(ClipboardData(text: email));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text('Email copié : $email'),
            ],
          ),
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ReactiveMode.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF2F0EB),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.orange))
          : _errorMessage != null
              ? _buildError()
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildContent(isDark),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(_errorMessage!,
              style: const TextStyle(color: AppColors.textGray)),
          const SizedBox(height: 20),
          TextButton(
              onPressed: _fetchTrainerProfile, child: const Text('Réessayer')),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final profile = _trainerProfile!;
    final fullName =
        '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim();
    final jobTitle = profile['jobTitle'] ?? 'Formateur Professionnel';
    final bio = profile['bio'] ?? 'Aucune biographie disponible.';
    final expertise = (profile['expertise'] as List?)?.cast<String>() ?? [];
    final location = profile['location'];
    final email = profile['email'];
    final certifications =
        (profile['certifications'] as List?)?.cast<Map<String, dynamic>>() ??
            [];
    final socialLinks = profile['socialLinks'] as Map<String, dynamic>?;
    final linkedin = socialLinks?['linkedIn'];
    final portfolio = socialLinks?['portfolio'];
    final avgRating = (profile['averageRating'] as num?)?.toDouble() ?? 0.0;
    final totalReviews = profile['totalReviews'] ?? 0;
    final profilePicture = profile['profilePicture'];

    return CustomScrollView(
      slivers: [
        // ── Hero App Bar ────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor:
                  isDark ? Colors.white.withOpacity(0.1) : Colors.white,
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: isDark ? Colors.white : AppColors.textDark),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Gradient background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF1A1F3C),
                              const Color(0xFF0D1128),
                            ]
                          : [
                              AppColors.navy,
                              const Color(0xFF1a3a6b),
                            ],
                    ),
                  ),
                ),
                // Decorative circles
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.orange.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: -30,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                    ),
                  ),
                ),
                // Profile content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Avatar with glow
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.orange.withOpacity(0.3),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: Colors.white.withOpacity(0.15),
                            backgroundImage: profilePicture != null &&
                                    profilePicture.isNotEmpty
                                ? (profilePicture.startsWith('http')
                                    ? NetworkImage(profilePicture)
                                    : MemoryImage(base64Decode(profilePicture))
                                        as ImageProvider)
                                : null,
                            child: (profilePicture == null ||
                                    profilePicture.isEmpty)
                                ? const Icon(Icons.person_rounded,
                                    size: 54, color: Colors.white70)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          fullName.isNotEmpty ? fullName : 'Formateur',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.orange.withOpacity(0.4)),
                          ),
                          child: Text(
                            jobTitle,
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (location != null && location.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 13, color: Colors.white54),
                              const SizedBox(width: 4),
                              Text(location,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 13)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Body ────────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Stats row ──────────────────────────────────────────────
                _buildStatsRow(
                    avgRating, totalReviews, expertise.length, isDark),
                const SizedBox(height: 20),

                // ── Contact buttons ─────────────────────────────────────────
                if (email != null || linkedin != null || portfolio != null) ...[
                  _buildSectionTitle(
                      'Contact', Icons.contact_mail_rounded, isDark),
                  const SizedBox(height: 12),
                  _buildContactButtons(email, linkedin, portfolio, isDark),
                  const SizedBox(height: 24),
                ],

                // ── Bio ─────────────────────────────────────────────────────
                _buildSectionTitle(
                    'À propos', Icons.person_outline_rounded, isDark),
                const SizedBox(height: 12),
                _buildCard(
                  isDark,
                  child: Text(
                    bio,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.7,
                      color: isDark ? Colors.white70 : AppColors.textGray,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Expertise ───────────────────────────────────────────────
                if (expertise.isNotEmpty) ...[
                  _buildSectionTitle(
                      'Domaines d\'expertise', Icons.school_rounded, isDark),
                  const SizedBox(height: 12),
                  _buildCard(
                    isDark,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: expertise.map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      AppColors.navy.withOpacity(0.6),
                                      AppColors.navy.withOpacity(0.3),
                                    ]
                                  : [
                                      AppColors.navy.withOpacity(0.08),
                                      AppColors.navy.withOpacity(0.04),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.navy.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                skill,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.navy,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Certifications ─────────────────────────────────────────
                if (certifications.isNotEmpty) ...[
                  _buildSectionTitle(
                      'Certifications', Icons.verified_rounded, isDark),
                  const SizedBox(height: 12),
                  ...certifications
                      .map((cert) => _buildCertCard(cert, isDark))
                      ,
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(
      double rating, int reviews, int expertiseCount, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFFFB300),
            value: rating > 0 ? rating.toStringAsFixed(1) : '–',
            label: 'Note',
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildStat(
            icon: Icons.reviews_rounded,
            iconColor: AppColors.navy,
            value: reviews.toString(),
            label: 'Avis',
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildStat(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.orange,
            value: expertiseCount.toString(),
            label: 'Expertises',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 36,
      width: 1,
      color: isDark ? AppColors.borderDark : AppColors.border,
    );
  }

  Widget _buildStat({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : AppColors.textGray,
          ),
        ),
      ],
    );
  }

  Widget _buildContactButtons(
      String? email, String? linkedin, String? portfolio, bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (email != null && email.isNotEmpty)
          _buildContactChip(
            icon: Icons.email_rounded,
            label: email,
            color: AppColors.navy,
            isDark: isDark,
            onTap: () => _launchEmail(email),
          ),
        if (linkedin != null && linkedin.isNotEmpty)
          _buildContactChip(
            icon: Icons.link_rounded,
            label: 'LinkedIn',
            color: const Color(0xFF0077B5),
            isDark: isDark,
            onTap: () => _launchUrl(linkedin),
          ),
        if (portfolio != null && portfolio.isNotEmpty)
          _buildContactChip(
            icon: Icons.language_rounded,
            label: 'Portfolio',
            color: AppColors.orange,
            isDark: isDark,
            onTap: () => _launchUrl(portfolio),
          ),
      ],
    );
  }

  Widget _buildContactChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.orange),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(bool isDark, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: child,
    );
  }

  Widget _buildCertCard(Map<String, dynamic> cert, bool isDark) {
    final name = cert['name'] ?? 'Certification';
    final issuer = cert['issuer'] ?? '';
    final year = cert['year'] ?? '';
    final image = cert['image'];

    return GestureDetector(
      onTap: () {
        if (image != null) _showCertPreview(cert, isDark);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Cert thumbnail or icon
            Container(
              width: 100,
              height: 75,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.orange.withOpacity(0.15),
                    AppColors.orange.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.orange.withOpacity(0.25)),
              ),
              child: image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.memory(
                        base64Decode(image),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.orange,
                          size: 26,
                        ),
                      ),
                    )
                  : const Icon(Icons.workspace_premium_rounded,
                      color: AppColors.orange, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    issuer,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Text(
                year,
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (image != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.zoom_in_rounded,
                  size: 16,
                  color: isDark ? Colors.white30 : AppColors.textGray),
            ],
          ],
        ),
      ),
    );
  }

  void _showCertPreview(Map<String, dynamic> cert, bool isDark) {
    final String? fileType = cert['fileType'];
    final String? fullFile = cert['fullFile'];
    final String? thumbnail = cert['image'];

    // Prioritize high-resolution fullFile if it's an image.
    // Fall back to thumbnail if fullFile is missing or if it's a PDF (since Image.memory can't render PDF bytes).
    String? displayImage = thumbnail;

    final bool isPdf = fileType == 'pdf';

    if (fullFile != null && fullFile.isNotEmpty && !isPdf) {
      displayImage = fullFile;
    }

    if (displayImage == null) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                constraints:
                    const BoxConstraints(maxWidth: 500, maxHeight: 400),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Image.memory(
                      base64Decode(displayImage!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image, size: 64),
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text('Fermer',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
