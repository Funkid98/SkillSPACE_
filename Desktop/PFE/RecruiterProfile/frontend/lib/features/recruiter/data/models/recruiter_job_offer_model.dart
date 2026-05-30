class RecruiterJobOffer {
  final String id;
  final String title;
  final String location;
  final String type; // CDI, CDD, etc.
  final String status; // Active, Brouillon
  final String description;
  final List<String> requirements;
  final String recruiter;
  final int candidateCount;
  final int viewCount;

  RecruiterJobOffer({
    required this.id,
    required this.recruiter,
    required this.title,
    required this.location,
    required this.type,
    required this.status,
    required this.description,
    required this.requirements,
    required this.candidateCount,
    required this.viewCount,
  });

  factory RecruiterJobOffer.fromJson(Map<String, dynamic> json) {
    return RecruiterJobOffer(
      id: json['_id'] ?? '',
      recruiter: json['recruiter'] ?? '',
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      type: (json['type'] == 'Full-time'
          ? 'CDI'
          : (json['type'] == 'Part-time' || json['type'] == 'Contract'
              ? 'CDD'
              : (json['type'] ?? 'CDI'))),
      status: 'Active',
      description: json['description'] ?? '',
      requirements: List<String>.from(json['requirements'] ?? []),
      candidateCount: json['candidateCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'type': type,
      'requirements': requirements,
    };
  }

  RecruiterJobOffer copyWith({
    String? id,
    String? title,
    String? location,
    String? type,
    String? status,
    String? description,
    List<String>? requirements,
    String? recruiter,
    int? candidateCount,
    int? viewCount,
  }) {
    return RecruiterJobOffer(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      recruiter: recruiter ?? this.recruiter,
      candidateCount: candidateCount ?? this.candidateCount,
      viewCount: viewCount ?? this.viewCount,
    );
  }
}

class CandidateMatch {
  final String id;
  final String name;
  final String role;
  final String location;
  final String experience;
  final List<String> skills;
  final int matchScore;
  final String matchingAnalysis;
  final String recommendation;
  final String status; // Nouveau, En revue, etc.
  final bool isSaved;
  final String initials;

  CandidateMatch({
    required this.id,
    required this.name,
    required this.role,
    required this.location,
    required this.experience,
    required this.skills,
    required this.matchScore,
    required this.matchingAnalysis,
    required this.recommendation,
    required this.status,
    required this.isSaved,
    required this.initials,
  });

  CandidateMatch copyWith({
    String? id,
    String? name,
    String? role,
    String? location,
    String? experience,
    List<String>? skills,
    int? matchScore,
    String? matchingAnalysis,
    String? recommendation,
    String? status,
    bool? isSaved,
    String? initials,
  }) {
    return CandidateMatch(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      location: location ?? this.location,
      experience: experience ?? this.experience,
      skills: skills ?? this.skills,
      matchScore: matchScore ?? this.matchScore,
      matchingAnalysis: matchingAnalysis ?? this.matchingAnalysis,
      recommendation: recommendation ?? this.recommendation,
      status: status ?? this.status,
      isSaved: isSaved ?? this.isSaved,
      initials: initials ?? this.initials,
    );
  }

  factory CandidateMatch.fromJson(Map<String, dynamic> json) {
    final name = json['name'] ?? 'Candidat';
    final initials = json['initials'] ??
        name
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase();

    return CandidateMatch(
      id: json['_id'] ?? json['id'] ?? '',
      name: name,
      role: json['role'] ?? json['poste'] ?? 'Développeur',
      location: json['localisation'] ?? json['location'] ?? 'Non spécifiée',
      experience: json['experience'] ?? 'Jeune diplômé',
      skills: List<String>.from(json['competences'] ?? json['skills'] ?? []),
      matchScore: (json['matchScore'] as num?)?.round() ?? 90,
      matchingAnalysis: json['matchingAnalysis'] ?? '',
      recommendation: json['recommendation'] ?? '',
      status: json['status'] ?? 'Nouveau',
      isSaved: false,
      initials: initials.isEmpty ? 'CA' : initials,
    );
  }
}

class RecruiterOfferWithCandidates {
  final RecruiterJobOffer offer;
  final List<CandidateMatch> candidates;

  RecruiterOfferWithCandidates({
    required this.offer,
    required this.candidates,
  });

  factory RecruiterOfferWithCandidates.fromJson(Map<String, dynamic> json) {
    return RecruiterOfferWithCandidates(
      offer: RecruiterJobOffer.fromJson(json['offer']),
      candidates: (json['candidates'] as List)
          .map((c) => CandidateMatch.fromJson(c))
          .toList(),
    );
  }
}
