class StudentRating {
  final String id;
  final String name;
  final double rating;
  final String review;

  StudentRating({
    required this.id,
    required this.name,
    this.rating = 0.0,
    this.review = '',
  });

  factory StudentRating.fromJson(Map<String, dynamic> json) {
    return StudentRating(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      review: json['review'] ?? '',
    );
  }
}

class FormationModel {
  final String id;
  final String trainerId;
  final String title;
  final String description;
  final List<String> tags;
  final int studentCount;
  final double rating;
  final int reviewCount;
  final double price;
  final String duration;
  final String category;
  final String level;
  final String imageUrl;
  final String? meetLink;
  final DateTime? date;
  final String? time;
  final String status;
  final List<StudentRating> students;

  FormationModel({
    required this.id,
    required this.trainerId,
    required this.title,
    this.description = '',
    this.tags = const [],
    this.studentCount = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.price = 0.0,
    this.duration = '',
    this.category = '',
    this.level = 'Débutant',
    this.imageUrl = '',
    this.meetLink,
    this.date,
    this.time,
    this.status = 'active',
    this.students = const [],
  });

  factory FormationModel.fromJson(Map<String, dynamic> json) {
    return FormationModel(
      id: json['_id'] ?? '',
      trainerId: json['trainerId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      studentCount: json['studentCount'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      duration: json['duration'] ?? '',
      category: json['category'] ?? '',
      level: json['level'] ?? 'Débutant',
      imageUrl: json['imageUrl'] ?? '',
      meetLink: json['meetLink'],
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      time: json['time'],
      status: json['status'] ?? 'active',
      students: json['students'] != null
          ? (json['students'] as List)
              .map((s) => StudentRating.fromJson(s))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trainerId': trainerId,
      'title': title,
      'description': description,
      'tags': tags,
      'studentCount': studentCount,
      'rating': rating,
      'reviewCount': reviewCount,
      'price': price,
      'duration': duration,
      'category': category,
      'level': level,
      'imageUrl': imageUrl,
      'meetLink': meetLink,
      'date': date?.toIso8601String(),
      'time': time,
      'status': status,
    };
  }
}
