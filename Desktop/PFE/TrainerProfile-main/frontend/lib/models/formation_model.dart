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
    };
  }
}
