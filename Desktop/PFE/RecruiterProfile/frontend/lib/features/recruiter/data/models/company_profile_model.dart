class CompanyProfile {
  final String id;
  final String email;
  final String entreprise;
  final String poste;
  final String taille;
  final int anneeCreation;
  final String siteWeb;
  final String localisation;
  final String logoUrl;
  final String secteur;

  CompanyProfile({
    this.id = '',
    this.email = '',
    this.entreprise = '',
    this.poste = '',
    this.taille = '',
    this.anneeCreation = 0,
    this.siteWeb = '',
    this.localisation = '',
    this.logoUrl = '',
    this.secteur = '',
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      entreprise: json['entreprise'] ?? '',
      poste: json['poste'] ?? '',
      taille: json['taille'] ?? '',
      anneeCreation: json['anneeCreation'] != null ? int.tryParse(json['anneeCreation'].toString()) ?? 0 : 0,
      siteWeb: json['siteWeb'] ?? '',
      localisation: json['localisation'] ?? '',
      logoUrl: json['logo'] ?? '',
      secteur: json['secteur'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entreprise': entreprise,
      'poste': poste,
      'taille': taille,
      'anneeCreation': anneeCreation,
      'siteWeb': siteWeb,
      'localisation': localisation,
      'logo': logoUrl,
      'secteur': secteur,
    };
  }
}
