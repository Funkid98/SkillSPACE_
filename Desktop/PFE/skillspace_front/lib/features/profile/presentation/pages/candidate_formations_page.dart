import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../cubit/formations_cubit.dart';

class CandidateFormationsPage extends StatelessWidget {
  const CandidateFormationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.hPad(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<FormationsCubit, FormationsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mes Formations',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Gérez vos formations et suivez votre apprentissage.',
                  style: TextStyle(fontSize: 15, color: AppColors.textGray),
                ),
                const SizedBox(height: 32),
                if (state is FormationsLoading)
                  const Center(
                      child: CircularProgressIndicator(color: AppColors.orange))
                else if (state is FormationsError)
                  Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                else if (state is FormationsLoaded) ...[
                  if (state.formations.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 48),
                          Icon(Icons.school_outlined,
                              size: 64,
                              color: AppColors.textGray.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          const Text('Vous n\'êtes inscrit à aucune formation.',
                              style: TextStyle(
                                  color: AppColors.textGray, fontSize: 16)),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.formations.length,
                      itemBuilder: (context, index) {
                        final f = state.formations[index];
                        final title = f['title'] ?? 'Formation';
                        final trainer = f['trainerId'] != null
                            ? '${f['trainerId']['firstName'] ?? ''} ${f['trainerId']['lastName'] ?? ''}'
                            : 'Formatteur';
                        final aiReason = f['aiReason'] ?? '';

                        final status = f['status'] ?? 'ENROLLED';
                        final isCompleted = status == 'COMPLETED';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.navy.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                        isCompleted
                                            ? Icons.check_circle_outline
                                            : Icons.menu_book,
                                        color: isCompleted
                                            ? Colors.green
                                            : AppColors.navy,
                                        size: 32),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18)),
                                        const SizedBox(height: 8),
                                        Text('Par $trainer',
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: AppColors.textGray)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: (isCompleted ? Colors.green : Colors.blue)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                        isCompleted ? 'Terminée' : 'En cours',
                                        style: TextStyle(
                                            color: isCompleted
                                                ? Colors.green
                                                : Colors.blue,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                              if (aiReason.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.orange
                                        .withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.orange
                                            .withValues(alpha: 0.1)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.auto_awesome,
                                          color: AppColors.orange, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Pourquoi cette formation ?',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textDark,
                                                  fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              aiReason,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.textDark,
                                                  height: 1.5),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                ] else
                  const SizedBox.shrink(),
              ],
            ),
          );
        },
      ),
    );
  }
}
