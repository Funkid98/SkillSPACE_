import 'package:flutter/material.dart';
import 'package:pfe/core/network/api_client.dart';
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;
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
  final String? applicationStatus;
  final bool isSaved;
  final String? internalFormationId;
  final DateTime? createdAt;

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
    this.applicationStatus,
    this.isSaved = false,
    this.internalFormationId,
    this.createdAt,
  });

  JobOffer copyWith({bool? isSaved, String? applicationStatus}) {
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
      applicationStatus: applicationStatus ?? this.applicationStatus,
      isSaved: isSaved ?? this.isSaved,
      internalFormationId: internalFormationId,
      createdAt: createdAt,
    );
  }

  static Future<List<JobOffer>> fetchAll() async {
    try {
      final client = ApiClient();
      final response = await client.get('/candidat/matching-offers');

      if (response.statusCode == 200) {
        timeago.setLocaleMessages('fr', timeago.FrMessages());
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

          final DateTime? createdAt = json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null;
          final String postedAgo = createdAt != null 
              ? timeago.format(createdAt, locale: 'fr') 
              : 'Récemment';

          return JobOffer(
            id: json['_id']?.toString() ?? '',
            title: json['title'] ?? 'Sans titre',
            company: json['company'] ?? 'Non spécifié',
            city: json['location'] ?? 'Remote',
            recruiterId: json['recruiterId']?.toString(),
            contractType: mappedType,
            salaryRange: json['salary'] ?? 'N/A',
            postedAgo: postedAgo,
            compatibilityPercent: (json['compatibilityPercent'] as num?)?.round() ?? 0,
            matchingSkills: (json['matchingSkills'] as num?)?.round() ?? 0,
            totalSkills: (json['totalSkills'] as num?)?.round() ?? 0,
            description: json['description'] ?? '',
            matchingAnalysis: json['matchingAnalysis'] ?? '',
            recommendation: json['recommendation'] ?? '',
            matchedSkills: List<String>.from(json['matchedSkills'] ?? []),
            missingSkills: List<String>.from(json['missingSkills'] ?? []),
            status: json['status'] ?? 'COMPLETED',
            applicationStatus: json['applicationStatus'],
            internalFormationId: json['internalFormationId']?.toString(),
            createdAt: createdAt,
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
