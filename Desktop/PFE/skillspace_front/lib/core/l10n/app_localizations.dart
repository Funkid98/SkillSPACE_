import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = {
    'fr': {
      'dashboard': 'Tableau de bord',
      'profile': 'Mon profil',
      'jobs': 'Offres d\'emploi',
      'simulation': 'Simulation entretien',
      'training': 'Formations',
      'logout': 'Déconnexion',
      'welcome': 'Bienvenue',
      'summary': 'Voici un résumé de votre activité',
      'matched_offers': 'Offres matchées',
      'sent_applications': 'Candidatures envoyées',
      'avg_match_score': 'Score moyen de match',
      'simulated_interviews': 'Entretiens simulés',
      'recent_offers': 'Offres récentes',
      'skills': 'Compétences',
      'upcoming_interviews': 'Entretiens à venir',
      'profile_visibility': 'Visibilité du profil',
      'see_all': 'Tout voir',
      'agenda': 'Agenda',
      'edit': 'Modifier',
      'no_interviews': 'Aucun entretien programmé',
      'views_this_month': 'vues ce mois',
      'vs_last_month': 'par rapport au mois dernier',
      'language': 'Langue',
      'manage_profile': 'Gérez vos informations et compétences',
      'profile_completed': 'Profil complété à',
      'complete_profile_hint':
          'Ajoutez un CV et une photo pour compléter votre profil',
      'personal_info': 'Informations personnelles',
      'first_name': 'Prénom',
      'last_name': 'Nom',
      'email': 'Email',
      'phone': 'Téléphone',
      'location': 'Localisation',
      'bio': 'Bio',
      'my_cv': 'Mon CV',
      'replace': 'Remplacer',
      'upload_hint': 'Cliquez ou glissez pour téléverser',
      'add': 'Ajouter',
      'save_changes': 'Enregistrer les modifications',
      'find_jobs': 'Trouvez les offres qui correspondent à vos compétences',
      'ai_match_hint':
          'offres avec une compatibilité supérieure à 80% — basé sur l\'analyse de votre CV et compétences.',
      'search_hint': 'Rechercher par titre ou entreprise...',
      'all': 'Tous',
      'no_jobs_found': 'Aucune offre trouvée',
      'compatibility': 'compatibilité',
      'matching_skills': 'compétences correspondantes',
      'hide': 'Masquer',
      'details': 'Détails',
      'apply': 'Postuler',
      'about_job': 'À propos du poste',
      'features': 'Fonctionnalités',
      'how_it_works': 'Comment ça marche',
      'for_whom': 'Pour qui',
      'login': 'Se connecter',
      'register': 'S\'inscrire',
      'hero_label': 'PLATEFORME DE RECRUTEMENT INTELLIGENTE',
      'hero_title_1': 'Vos ',
      'hero_title_2': 'compétences',
      'hero_title_3': ' sont votre meilleur atout',
      'hero_subtitle':
          'SkillSpace connecte les jeunes diplômés aux entreprises grâce à l\'IA. Fini le stress des entretiens — préparez-vous, matchez, décrochez.',
      'btn_start_free': 'Commencer gratuitement',
      'btn_discover': 'Découvrir la plateforme',
      'stat_active_candidates': 'candidats actifs',
      'stat_companies': 'entreprises',
      'stat_satisfaction': 'Taux de satisfaction',
      'section_features_label': 'FONCTIONNALITÉS',
      'section_features_title':
          'Tout ce qu\'il faut pour décrocher votre premier emploi',
      'section_features_subtitle':
          'SkillSpace combine l\'intelligence artificielle et le coaching pour maximiser vos chances d\'insertion professionnelle.',
      'feat_1_title': 'Analyse de CV par IA',
      'feat_1_desc':
          'Importez votre CV et laissez l\'IA extraire vos compétences automatiquement.',
      'feat_2_title': 'Matching intelligent',
      'feat_2_desc':
          'Score de compatibilité calculé entre votre profil et les offres disponibles.',
      'feat_3_title': 'Formations recommandées',
      'feat_3_desc':
          'Comblez vos lacunes avec des formations ciblées selon le marché.',
      'feat_4_title': 'Simulation d\'entretien',
      'feat_4_desc':
          'Entraînez-vous avec un chatbot IA qui s\'adapte au poste visé.',
      'feat_5_title': 'IA qui apprend',
      'feat_5_desc':
          'Le système s\'améliore continuellement grâce aux données collectées.',
      'feat_6_title': 'Tendances du marché',
      'feat_6_desc':
          'Restez informé des compétences les plus demandées dans votre secteur.',
      'section_steps_title': '5 étapes vers votre premier emploi',
      'step_1_title': 'Créez votre profil',
      'step_1_desc':
          'Inscrivez-vous et importez votre CV. L\'IA analyse vos compétences en quelques secondes.',
      'step_2_title': 'Recevez des matchs',
      'step_2_desc':
          'Notre algorithme vous propose les offres les plus adaptées avec un score de compatibilité.',
      'step_3_title': 'Formez-vous',
      'step_3_desc':
          'Suivez des formations recommandées par l\'IA pour combler vos lacunes et booster votre profil.',
      'step_4_title': 'Postulez en un clic',
      'step_4_desc':
          'Candidatez aux offres qui vous correspondent en toute simplicité.',
      'step_5_title': 'Préparez vos entretiens',
      'step_5_desc':
          'Simulez des entretiens avec l\'IA pour arriver confiant le jour J.',
      'section_audience_label': 'POUR QUI ?',
      'section_audience_title':
          'Une plateforme pour chaque Jeunes diplômés , Recruteur , Formatteur',
      'role_recruiter': 'Recruteur',
      'role_recruiter_sub': 'Entreprise',
      'role_candidate': 'Candidat',
      'role_candidate_sub': 'Jeune diplômé',
      'role_trainer': 'Formateur',
      'role_trainer_sub': 'Organisme de formation',
      'btn_start': 'Commencer',
      'btn_learn_more': 'En savoir plus',
      'cta_title': 'Prêt à lancer votre carrière ?',
      'cta_subtitle':
          'Rejoignez des milliers de jeunes diplômés qui ont trouvé leur premier emploi grâce à SkillSpace.',
      'btn_create_profile': 'Créer mon profil gratuitement',
      'footer_rights': '© 2026 SkillSpace. Tous droits réservés.',
      'footer_privacy': 'Confidentialité',
      'footer_tos': 'CGU',
      'footer_contact': 'Contact',
      'coming_soon': 'Bientôt disponible',
      'recruiter_feat_1': 'Publication d\'offres ciblées',
      'recruiter_feat_2': 'Tri automatique des candidats',
      'recruiter_feat_3': 'Score de compatibilité',
      'recruiter_feat_4': 'Gain de temps considérable',
      'candidate_feat_1': 'Profil basé sur les compétences',
      'candidate_feat_2': 'Matching intelligent avec les offres',
      'candidate_feat_3': 'Simulation d\'entretien IA',
      'candidate_feat_4': 'Formations recommandées',
      'trainer_feat_1': 'Visibilité auprès des candidats',
      'trainer_feat_2': 'Recommandations IA ciblées',
      'trainer_feat_3': 'Suivi des inscriptions',
      'trainer_feat_4': 'Alignement marché du travail',
      // Recruiter Strings
      'recruiter_dashboard': 'Tableau de bord entreprise',
      'publish_offer': 'Publier une offre',
      'active_offers': 'Offres actives',
      'received_applications': 'Candidatures reçues',
      'offer_views': 'Vues des offres',
      'conversion_rate': 'Taux de conversion',
      'recent_candidates': 'Candidats récents',
      'new_status': 'Nouveau',
      'in_review_status': 'En revue',
      'interview_planned_status': 'Entretien planifié',
      'company_profile_title': 'Profil entreprise',
      'company_profile_subtitle': 'Gérez les informations de votre entreprise',
      'profile_completion': 'Profil complété à',
      'company_info': 'Informations de l\'entreprise',
      'company_name': 'Nom de l\'entreprise',
      'business_sector': 'Secteur d\'activité',
      'company_size': 'Nombre d\'employés',
      'creation_year': 'Année de création',
      'website': 'Site web',
      'company_description': 'Description de l\'entreprise',
      'company_logo': 'Logo de l\'entreprise',
      'upload_logo_hint': 'Glissez votre logo ici ou cliquez pour parcourir',
      'hr_contact': 'Contact RH',
      'hr_manager_name': 'Nom du responsable RH',
      'recruitment_sectors': 'Secteurs de recrutement',
      'add_sector_hint': 'Ajouter un secteur...',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'my_offers_title': 'Mes offres',
      'my_offers_subtitle': 'Gérez et publiez vos offres d\'emploi',
      'new_offer': 'Nouvelle offre',
      'candidates_page_title': 'Candidats',
      'candidates_page_subtitle':
          'Consultez et gérez les profils des candidats',
      'search_candidate_hint': 'Rechercher un candidat...',
      'saved': 'Sauvegardés',
      'contact_candidate': 'Contacter',
      'match': 'match',
      'post': 'Poste',
      'contract_cdi': 'CDI',
      'contract_cdd': 'CDD',
      'contract_freelance': 'Freelance',
      'contract_stage': 'Stage',
      'upload_format_hint': 'PDF, DOC — max 5 Mo',
      'cv_example_name': 'CV_Jean_Dupont.pdf',
      'level_advanced': 'Avancé',
      'level_intermediate': 'Intermédiaire',
      'level_expert': 'Expert',
      'About Position': 'À propos du poste',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Helper getters
  String get dashboard => translate('dashboard');
  String get profile => translate('profile');
  String get jobs => translate('jobs');
  String get simulation => translate('simulation');
  String get training => translate('training');
  String get logout => translate('logout');
  String get welcome => translate('welcome');
  String get summary => translate('summary');
  String get matchedOffers => translate('matched_offers');
  String get sentApplications => translate('sent_applications');
  String get avgMatchScore => translate('avg_match_score');
  String get simulatedInterviews => translate('simulated_interviews');
  String get recentOffers => translate('recent_offers');
  String get skills => translate('skills');
  String get upcomingInterviews => translate('upcoming_interviews');
  String get profileVisibility => translate('profile_visibility');
  String get seeAll => translate('see_all');
  String get agenda => translate('agenda');
  String get edit => translate('edit');
  String get noInterviews => translate('no_interviews');
  String get viewsThisMonth => translate('views_this_month');
  String get vsLastMonth => translate('vs_last_month');
  String get language => translate('language');
  String get manageProfile => translate('manage_profile');
  String get profileCompleted => translate('profile_completed');
  String get completeProfileHint => translate('complete_profile_hint');
  String get personalInfo => translate('personal_info');
  String get firstName => translate('first_name');
  String get lastName => translate('last_name');
  String get email => translate('email');
  String get phone => translate('phone');
  String get location => translate('location');
  String get bio => translate('bio');
  String get myCv => translate('my_cv');
  String get replace => translate('replace');
  String get uploadHint => translate('upload_hint');
  String get add => translate('add');
  String get saveChanges => translate('save_changes');
  String get findJobs => translate('find_jobs');
  String get aiMatchHint => translate('ai_match_hint');
  String get searchHint => translate('search_hint');
  String get all => translate('all');
  String get noJobsFound => translate('no_jobs_found');
  String get compatibility => translate('compatibility');
  String get matchingSkills => translate('matching_skills');
  String get hide => translate('hide');
  String get details => translate('details');
  String get apply => translate('apply');
  String get aboutJob => translate('about_job');
  String get features => translate('features');
  String get howItWorks => translate('how_it_works');
  String get forWhom => translate('for_whom');
  String get login => translate('login');
  String get register => translate('register');
  String get heroLabel => translate('hero_label');
  String get heroTitle1 => translate('hero_title_1');
  String get heroTitle2 => translate('hero_title_2');
  String get heroTitle3 => translate('hero_title_3');
  String get heroSubtitle => translate('hero_subtitle');
  String get btnStartFree => translate('btn_start_free');
  String get btnDiscover => translate('btn_discover');
  String get statActiveCandidates => translate('stat_active_candidates');
  String get statCompanies => translate('stat_companies');
  String get statSatisfaction => translate('stat_satisfaction');
  String get sectionFeaturesLabel => translate('section_features_label');
  String get sectionFeaturesTitle => translate('section_features_title');
  String get sectionFeaturesSubtitle => translate('section_features_subtitle');
  String get feat1Title => translate('feat_1_title');
  String get feat1Desc => translate('feat_1_desc');
  String get feat2Title => translate('feat_2_title');
  String get feat2Desc => translate('feat_2_desc');
  String get feat3Title => translate('feat_3_title');
  String get feat3Desc => translate('feat_3_desc');
  String get feat4Title => translate('feat_4_title');
  String get feat4Desc => translate('feat_4_desc');
  String get feat5Title => translate('feat_5_title');
  String get feat5Desc => translate('feat_5_desc');
  String get feat6Title => translate('feat_6_title');
  String get feat6Desc => translate('feat_6_desc');
  String get sectionStepsTitle => translate('section_steps_title');
  String get step1Title => translate('step_1_title');
  String get step1Desc => translate('step_1_desc');
  String get step2Title => translate('step_2_title');
  String get step2Desc => translate('step_2_desc');
  String get step3Title => translate('step_3_title');
  String get step3Desc => translate('step_3_desc');
  String get step4Title => translate('step_4_title');
  String get step4Desc => translate('step_4_desc');
  String get step5Title => translate('step_5_title');
  String get step5Desc => translate('step_5_desc');
  String get sectionAudienceLabel => translate('section_audience_label');
  String get sectionAudienceTitle => translate('section_audience_title');
  String get roleRecruiter => translate('role_recruiter');
  String get roleRecruiterSub => translate('role_recruiter_sub');
  String get roleCandidate => translate('role_candidate');
  String get roleCandidateSub => translate('role_candidate_sub');
  String get roleTrainer => translate('role_trainer');
  String get roleTrainerSub => translate('role_trainer_sub');
  String get btnStart => translate('btn_start');
  String get btnLearnMore => translate('btn_learn_more');
  String get ctaTitle => translate('cta_title');
  String get ctaSubtitle => translate('cta_subtitle');
  String get btnCreateProfile => translate('btn_create_profile');
  String get footerRights => translate('footer_rights');
  String get footerPrivacy => translate('footer_privacy');
  String get footerTos => translate('footer_tos');
  String get footerContact => translate('footer_contact');

  String get contractCdi => translate('contract_cdi');
  String get contractCdd => translate('contract_cdd');
  String get contractFreelance => translate('contract_freelance');
  String get contractStage => translate('contract_stage');
  String get uploadFormatHint => translate('upload_format_hint');
  String get cvExampleName => translate('cv_example_name');
  String get levelAdvanced => translate('level_advanced');
  String get levelIntermediate => translate('level_intermediate');
  String get levelExpert => translate('level_expert');
  String get aboutJobDesc => translate('About Position');

  String get comingSoon => translate('coming_soon');
  String get recruiterFeat1 => translate('recruiter_feat_1');
  String get recruiterFeat2 => translate('recruiter_feat_2');
  String get recruiterFeat3 => translate('recruiter_feat_3');
  String get recruiterFeat4 => translate('recruiter_feat_4');
  String get candidateFeat1 => translate('candidate_feat_1');
  String get candidateFeat2 => translate('candidate_feat_2');
  String get candidateFeat3 => translate('candidate_feat_3');
  String get candidateFeat4 => translate('candidate_feat_4');
  String get trainerFeat1 => translate('trainer_feat_1');
  String get trainerFeat2 => translate('trainer_feat_2');
  String get trainerFeat3 => translate('trainer_feat_3');
  String get trainerFeat4 => translate('trainer_feat_4');

  // Recruiter Getters
  String get recruiterDashboard => translate('recruiter_dashboard');
  String get publishOffer => translate('publish_offer');
  String get activeOffers => translate('active_offers');
  String get receivedApplications => translate('received_applications');
  String get offerViews => translate('offer_views');
  String get conversionRate => translate('conversion_rate');
  String get recentCandidates => translate('recent_candidates');
  String get newStatus => translate('new_status');
  String get inReviewStatus => translate('in_review_status');
  String get interviewPlannedStatus => translate('interview_planned_status');
  String get companyProfileTitle => translate('company_profile_title');
  String get companyProfileSubtitle => translate('company_profile_subtitle');
  String get profileCompletion => translate('profile_completion');
  String get companyInfo => translate('company_info');
  String get companyName => translate('company_name');
  String get businessSector => translate('business_sector');
  String get companySize => translate('company_size');
  String get creationYear => translate('creation_year');
  String get website => translate('website');
  String get companyDescription => translate('company_description');
  String get companyLogo => translate('company_logo');
  String get uploadLogoHint => translate('upload_logo_hint');
  String get hrContact => translate('hr_contact');
  String get hrManagerName => translate('hr_manager_name');
  String get recruitmentSectors => translate('recruitment_sectors');
  String get addSectorHint => translate('add_sector_hint');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get myOffersTitle => translate('my_offers_title');
  String get myOffersSubtitle => translate('my_offers_subtitle');
  String get newOffer => translate('new_offer');
  String get candidatesPageTitle => translate('candidates_page_title');
  String get candidatesPageSubtitle => translate('candidates_page_subtitle');
  String get searchCandidateHint => translate('search_candidate_hint');
  String get savedLabel => translate('saved');
  String get contactCandidate => translate('contact_candidate');
  String get matchLabel => translate('match');
  String get post => translate('post');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
