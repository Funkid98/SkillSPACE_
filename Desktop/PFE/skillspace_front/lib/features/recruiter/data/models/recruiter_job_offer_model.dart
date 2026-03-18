class RecruiterJobOffer {
  final String id;
  final String title;
  final String location;
  final String type; // CDI, CDD, etc.
  final String status; // Active, Brouillon
  final String description;
  final List<String> requirements;
  final int candidateCount;
  final int viewCount;

  RecruiterJobOffer({
    required this.id,
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
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      type: json['type'] ?? 'Full-time',
      status: 'Active', 
      description: json['description'] ?? '',
      requirements: List<String>.from(json['requirements'] ?? []),
      candidateCount: 0,
      viewCount: 0,
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
}

class CandidateMatch {
  final String id;
  final String name;
  final String role;
  final String location;
  final String experience;
  final List<String> skills;
  final int matchScore;
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
    required this.status,
    required this.isSaved,
    required this.initials,
  });
}
