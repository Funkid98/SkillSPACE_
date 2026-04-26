import 'package:flutter/material.dart';
import 'package:pfe/core/network/api_client.dart';
import 'dart:convert';
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
  final String? recruiterId;
  final ContractType contractType;
  final String salaryRange;
  final String postedAgo;
  final int compatibilityPercent;
  final int matchingSkills;
  final int totalSkills;
  final String description;
  final String matchingAnalysis;
  final String recommendation;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final String status;
  final bool isSaved;

  const JobOffer({
    required this.id,
    required this.title,
    required this.company,
    required this.city,
    this.recruiterId,
    required this.contractType,
    required this.salaryRange,
    required this.postedAgo,
    required this.compatibilityPercent,
    required this.matchingSkills,
    required this.totalSkills,
    required this.description,
    this.matchingAnalysis = '',
    this.recommendation = '',
    this.matchedSkills = const [],
    this.missingSkills = const [],
    this.status = 'COMPLETED',
    this.isSaved = false,
  });

  JobOffer copyWith({bool? isSaved}) {
    return JobOffer(
      id: id,
      title: title,
      company: company,
      city: city,
      recruiterId: recruiterId,
      contractType: contractType,
      salaryRange: salaryRange,
      postedAgo: postedAgo,
      compatibilityPercent: compatibilityPercent,
      matchingSkills: matchingSkills,
      totalSkills: totalSkills,
      description: description,
      matchingAnalysis: matchingAnalysis,
      recommendation: recommendation,
      matchedSkills: matchedSkills,
      missingSkills: missingSkills,
      status: status,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  static Future<List<JobOffer>> fetchAll() async {
    try {
      final client = ApiClient();
      final response = await client.get('/candidat/matching-offers');

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) {
          final contractStr = json['type'] ?? 'Full-time';
          ContractType mappedType;
          if (contractStr.toLowerCase().contains('cdd')) {
            mappedType = ContractType.cdd;
          } else if (contractStr.toLowerCase().contains('freelance'))
            mappedType = ContractType.freelance;
          else if (contractStr.toLowerCase().contains('stage'))
            mappedType = ContractType.stage;
          else
            mappedType = ContractType.cdi;

          return JobOffer(
            id: json['_id']?.toString() ?? '',
            title: json['title'] ?? 'Sans titre',
            company: json['company'] ?? 'Non spécifié',
            city: json['location'] ?? 'Remote',
            recruiterId: json['recruiterId']?.toString(),
            contractType: mappedType,
            salaryRange: json['salary'] ?? 'N/A',
            postedAgo: 'Récemment',
            compatibilityPercent: (json['compatibilityPercent'] as num?)?.round() ?? 0,
            matchingSkills: (json['matchingSkills'] as num?)?.round() ?? 0,
            totalSkills: (json['totalSkills'] as num?)?.round() ?? 0,
            description: json['description'] ?? '',
            matchingAnalysis: json['matchingAnalysis'] ?? '',
            recommendation: json['recommendation'] ?? '',
            matchedSkills: List<String>.from(json['matchedSkills'] ?? []),
            missingSkills: List<String>.from(json['missingSkills'] ?? []),
            status: json['status'] ?? 'COMPLETED',
          );
        }).toList();
      }
    } catch (e) {
      // ignore: avoid_print
      print('[JobOffer.fetchAll] Error: $e');
    }

    // Fallback
    return [];
  }
}
