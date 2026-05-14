import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reactive_theme/reactive_theme.dart';
import '../../../../core/app_colors.dart';
import '../../cubit/simulation_cubit.dart';
import '../../cubit/simulation_state.dart';
import 'simulation_live_page.dart';

class SimulationSelectionPage extends StatefulWidget {
  const SimulationSelectionPage({super.key});

  @override
  State<SimulationSelectionPage> createState() =>
      _SimulationSelectionPageState();
}

class _SimulationSelectionPageState extends State<SimulationSelectionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    context.read<SimulationCubit>().fetchAcceptedOffers();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 16, color: AppColors.orange),
                          SizedBox(width: 8),
                          Text(
                            'Pré-entraînement IA',
                            style: TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Simulation d\'entretien',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.navy,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Préparez-vous à vos vrais entretiens pour les offres où vous avez été accepté.\nNotre recruteuse IA adapte ses questions au poste !',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white70 : AppColors.textGray,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    Expanded(
                      child: BlocBuilder<SimulationCubit, SimulationState>(
                        builder: (context, state) {
                          if (state is SimulationLoading) {
                            return const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.orange));
                          } else if (state is SimulationError) {
                            return Center(
                                child: Text(state.message,
                                    style: const TextStyle(color: Colors.red)));
                          } else if (state is SimulationLoaded) {
                            if (state.acceptedOffers.isEmpty) {
                              return Center(
                                child: Container(
                                  padding: const EdgeInsets.all(40),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.surfaceDark
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                        color: isDark
                                            ? AppColors.borderDark
                                            : AppColors.border),
                                    boxShadow: [
                                      if (!isDark)
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.work_off_outlined,
                                          size: 64, color: isDark ? Colors.white30 : AppColors.textGray),
                                      const SizedBox(height: 20),
                                      Text(
                                          'Aucune offre acceptée pour le moment.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: isDark ? Colors.white70 : AppColors.textGray,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 8),
                                      Text(
                                          'Les simulations seront disponibles dès qu\'une entreprise acceptera votre candidature.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: isDark ? Colors.white38 : AppColors.textGray.withOpacity(0.6),
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: state.acceptedOffers.length,
                              itemBuilder: (context, index) {
                                final offer = state.acceptedOffers[index];
                                final String title = offer['title'] ?? 'Poste';
                                final String company =
                                    offer['company'] ?? 'Entreprise';
                                final List<dynamic> requirements =
                                    offer['requirements'] ?? [];
                                final String promptContext =
                                    "$title chez $company. Compétences requises : ${requirements.join(', ')}";

                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: Duration(
                                      milliseconds: 600 + (index * 100)),
                                  curve: Curves.easeOutBack,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: Opacity(
                                        opacity: value.clamp(0.0, 1.0),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => SimulationLivePage(
                                              roleTitle: promptContext,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 24),
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.surfaceDark
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          border: Border.all(
                                              color: isDark
                                                  ? AppColors.borderDark
                                                  : AppColors.border),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                  isDark ? 0.1 : 0.03),
                                              blurRadius: 15,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.white
                                                        .withOpacity(0.05)
                                                    : AppColors.navy
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Icon(Icons.work,
                                                  color: isDark
                                                      ? Colors.white70
                                                      : AppColors.navy,
                                                  size: 32),
                                            ),
                                            const SizedBox(width: 24),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    title,
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isDark
                                                          ? Colors.white
                                                          : AppColors.navy,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.business,
                                                          size: 16,
                                                          color: AppColors
                                                              .textGray),
                                                      const SizedBox(width: 6),
                                                      Text(company,
                                                          style: const TextStyle(
                                                              color: AppColors
                                                                  .textGray,
                                                              fontSize: 14)),
                                                      const SizedBox(width: 16),
                                                      const Icon(
                                                          Icons.check_circle,
                                                          size: 16,
                                                          color: Colors.green),
                                                      const SizedBox(width: 6),
                                                      const Text(
                                                          'Candidature Acceptée',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.green,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children: requirements
                                                        .take(3)
                                                        .map((req) => Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          4),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: isDark
                                                                    ? Colors
                                                                        .white
                                                                        .withOpacity(
                                                                            0.05)
                                                                    : AppColors
                                                                        .bg,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                                border: Border.all(
                                                                    color: isDark
                                                                        ? AppColors
                                                                            .borderDark
                                                                        : AppColors
                                                                            .border),
                                                              ),
                                                              child: Text(
                                                                  req
                                                                      .toString(),
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color: AppColors
                                                                          .textGray)),
                                                            ))
                                                        .toList(),
                                                  )
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 12),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                    colors: [
                                                      AppColors.orange,
                                                      Color(0xFFFF9E66)
                                                    ]),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.play_arrow,
                                                      color: Colors.white,
                                                      size: 20),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Faire un entretien virtuel',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
