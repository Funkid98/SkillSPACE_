import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';

enum ContractType { cdi, cdd, freelance, stage }

extension ContractTypeLabel on ContractType {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case ContractType.cdi:
        return l10n.contractCdi;
      case ContractType.cdd:
        return l10n.contractCdd;
      case ContractType.freelance:
        return l10n.contractFreelance;
      case ContractType.stage:
        return l10n.contractStage;
    }
  }
}

class JobOffer {
  final String id;
  final String title;
  final String company;
  final String city;
  final ContractType contractType;
  final String salaryRange;
  final String postedAgo;
  final int compatibilityPercent;
  final int matchingSkills;
  final int totalSkills;
  final bool isSaved;

  const JobOffer({
    required this.id,
    required this.title,
    required this.company,
    required this.city,
    required this.contractType,
    required this.salaryRange,
    required this.postedAgo,
    required this.compatibilityPercent,
    required this.matchingSkills,
    required this.totalSkills,
    this.isSaved = false,
  });

  JobOffer copyWith({bool? isSaved}) {
    return JobOffer(
      id: id,
      title: title,
      company: company,
      city: city,
      contractType: contractType,
      salaryRange: salaryRange,
      postedAgo: postedAgo,
      compatibilityPercent: compatibilityPercent,
      matchingSkills: matchingSkills,
      totalSkills: totalSkills,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  static Future<List<JobOffer>> fetchAll() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return const [
      JobOffer(
        id: '1',
        title: 'Développeur Frontend React',
        company: 'TechCorp',
        city: 'Paris',
        contractType: ContractType.cdi,
        salaryRange: '35–42k€',
        postedAgo: 'Il y a 2 jours',
        compatibilityPercent: 92,
        matchingSkills: 5,
        totalSkills: 5,
      ),
      JobOffer(
        id: '2',
        title: 'Data Analyst Junior',
        company: 'DataFlow',
        city: 'Lyon',
        contractType: ContractType.cdi,
        salaryRange: '30–36k€',
        postedAgo: 'Il y a 3 jours',
        compatibilityPercent: 85,
        matchingSkills: 3,
        totalSkills: 4,
      ),
      JobOffer(
        id: '3',
        title: 'UX/UI Designer',
        company: 'DesignStudio',
        city: 'Remote',
        contractType: ContractType.cdd,
        salaryRange: '28–34k€',
        postedAgo: 'Il y a 5 jours',
        compatibilityPercent: 78,
        matchingSkills: 2,
        totalSkills: 4,
      ),
      JobOffer(
        id: '4',
        title: 'Ingénieur DevOps',
        company: 'CloudNine',
        city: 'Toulouse',
        contractType: ContractType.cdi,
        salaryRange: '40–50k€',
        postedAgo: 'Il y a 1 jour',
        compatibilityPercent: 65,
        matchingSkills: 2,
        totalSkills: 5,
      ),
      JobOffer(
        id: '5',
        title: 'Chef de projet IT Junior',
        company: 'ConsultPro',
        city: 'Marseille',
        contractType: ContractType.cdi,
        salaryRange: '32–38k€',
        postedAgo: 'Il y a 4 jours',
        compatibilityPercent: 71,
        matchingSkills: 3,
        totalSkills: 5,
      ),
    ];
  }
}
