import 'package:flutter/material.dart';

class RecruiterLocalizations {
  final Locale locale;

  RecruiterLocalizations(this.locale);

  static RecruiterLocalizations of(BuildContext context) {
    return Localizations.of<RecruiterLocalizations>(context, RecruiterLocalizations)!;
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
      'section_steps_title': '4 étapes vers votre premier emploi',
      'step_1_title': 'Créez votre profil',
      'step_1_desc':
          'Inscrivez-vous et importez votre CV. L\'IA analyse vos compétences en quelques secondes.',
      'step_2_title': 'Recevez des matchs',
      'step_2_desc':
          'Notre algorithme vous propose les offres les plus adaptées avec un score de compatibilité.',
      'step_3_title': 'Préparez-vous',
      'step_3_desc':
          'Simulez des entretiens avec l\'IA et suivez des formations pour combler vos lacunes.',
      'step_4_title': 'Décrochez le poste',
      'step_4_desc':
          'Postulez en toute confiance avec un profil optimisé et une préparation solide.',
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
    },
    'en': {
      'dashboard': 'Dashboard',
      'profile': 'My Profile',
      'jobs': 'Job Offers',
      'simulation': 'Interview Simulation',
      'training': 'Training',
      'logout': 'Logout',
      'welcome': 'Hello',
      'summary': 'Here is a summary of your activity',
      'matched_offers': 'Matched offers',
      'sent_applications': 'Sent applications',
      'avg_match_score': 'Average match score',
      'simulated_interviews': 'Simulated interviews',
      'recent_offers': 'Recent offers',
      'skills': 'Skills',
      'upcoming_interviews': 'Upcoming interviews',
      'profile_visibility': 'Profile visibility',
      'see_all': 'See all',
      'agenda': 'Agenda',
      'edit': 'Edit',
      'no_interviews': 'No interviews scheduled',
      'views_this_month': 'views this month',
      'vs_last_month': 'vs last month',
      'language': 'Language',
      'manage_profile': 'Manage your information and skills',
      'profile_completed': 'Profile completed at',
      'complete_profile_hint': 'Add a CV and a photo to complete your profile',
      'personal_info': 'Personal Information',
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'email': 'Email',
      'phone': 'Phone',
      'location': 'Location',
      'bio': 'Bio',
      'my_cv': 'My CV',
      'replace': 'Replace',
      'upload_hint': 'Click or drag to upload',
      'add': 'Add',
      'save_changes': 'Save Changes',
      'find_jobs': 'Find offers that match your skills',
      'ai_match_hint':
          'offers with compatibility over 80% — based on your CV and skills analysis.',
      'search_hint': 'Search by title or company...',
      'all': 'All',
      'no_jobs_found': 'No offers found',
      'compatibility': 'compatibility',
      'matching_skills': 'matching skills',
      'hide': 'Hide',
      'details': 'Details',
      'apply': 'Apply',
      'about_job': 'About the position',
      'features': 'Features',
      'how_it_works': 'How it works',
      'for_whom': 'For whom',
      'login': 'Login',
      'register': 'Register',
      'hero_label': 'SMART RECRUITMENT PLATFORM',
      'hero_title_1': 'Your ',
      'hero_title_2': 'skills',
      'hero_title_3': ' are your best asset',
      'hero_subtitle':
          'SkillSpace connects young graduates to companies through AI. No more interview stress — prepare, match, get hired.',
      'btn_start_free': 'Start for free',
      'btn_discover': 'Discover the platform',
      'stat_active_candidates': 'active candidates',
      'stat_companies': 'companies',
      'stat_satisfaction': 'Satisfaction rate',
      'section_features_label': 'FEATURES',
      'section_features_title': 'Everything you need to land your first job',
      'section_features_subtitle':
          'SkillSpace combines artificial intelligence and coaching to maximize your career entry chances.',
      'feat_1_title': 'AI CV Analysis',
      'feat_1_desc':
          'Upload your CV and let AI extract your skills automatically.',
      'feat_2_title': 'Smart Matching',
      'feat_2_desc':
          'Compatibility score calculated between your profile and available offers.',
      'feat_3_title': 'Recommended Training',
      'feat_3_desc':
          'Fill your gaps with targeted training based on the market.',
      'feat_4_title': 'Interview Simulation',
      'feat_4_desc':
          'Practice with an AI chatbot that adapts to the target position.',
      'feat_5_title': 'Learning AI',
      'feat_5_desc': 'The system continuously improves through collected data.',
      'feat_6_title': 'Market Trends',
      'feat_6_desc':
          'Stay informed about the most in-demand skills in your sector.',
      'section_steps_title': '4 steps to your first job',
      'step_1_title': 'Create your profile',
      'step_1_desc':
          'Sign up and upload your CV. AI analyzes your skills in seconds.',
      'step_2_title': 'Receive matches',
      'step_2_desc':
          'Our algorithm proposes the most suitable offers with a compatibility score.',
      'step_3_title': 'Get prepared',
      'step_3_desc':
          'Simulate interviews with AI and take training to fill your gaps.',
      'step_4_title': 'Get the job',
      'step_4_desc':
          'Apply with confidence with an optimized profile and solid preparation.',
      'section_audience_label': 'FOR WHOM?',
      'section_audience_title':
          'A platform for Fresh graduates , Recruiter , Trainer ',
      'role_recruiter': 'Recruiter',
      'role_recruiter_sub': 'Company',
      'role_candidate': 'Candidate',
      'role_candidate_sub': 'Young Graduate',
      'role_trainer': 'Trainer',
      'role_trainer_sub': 'Training Center',
      'btn_start': 'Get Started',
      'btn_learn_more': 'Learn More',
      'cta_title': 'Ready to launch your career?',
      'cta_subtitle':
          'Join thousands of young graduates who found their first job with SkillSpace.',
      'btn_create_profile': 'Create my profile for free',
      'footer_rights': '© 2026 SkillSpace. All rights reserved.',
      'footer_privacy': 'Privacy Policy',
      'footer_tos': 'Terms of Use',
      'footer_contact': 'Contact',
      'coming_soon': 'Coming Soon',
      'recruiter_feat_1': 'Targeted job postings',
      'recruiter_feat_2': 'Automatic candidate sorting',
      'recruiter_feat_3': 'Compatibility scoring',
      'recruiter_feat_4': 'Significant time savings',
      'candidate_feat_1': 'Skills-based profile',
      'candidate_feat_2': 'Smart job matching',
      'candidate_feat_3': 'AI interview simulation',
      'candidate_feat_4': 'Recommended training',
      'trainer_feat_1': 'Visibility to candidates',
      'trainer_feat_2': 'Targeted AI recommendations',
      'trainer_feat_3': 'Enrollment tracking',
      'trainer_feat_4': 'Labor market alignment',
      // Recruiter Strings
      'recruiter_dashboard': 'Recruiter Dashboard',
      'publish_offer': 'Post an offer',
      'active_offers': 'Active offers',
      'received_applications': 'Received applications',
      'offer_views': 'Offer views',
      'conversion_rate': 'Conversion rate',
      'recent_candidates': 'Recent candidates',
      'new_status': 'New',
      'in_review_status': 'In review',
      'interview_planned_status': 'Interview planned',
      'company_profile_title': 'Company profile',
      'company_profile_subtitle': 'Manage your company information',
      'profile_completion': 'Profile completed at',
      'company_info': 'Company information',
      'company_name': 'Company name',
      'business_sector': 'Business sector',
      'company_size': 'Company size',
      'creation_year': 'Creation year',
      'website': 'Website',
      'company_description': 'Company description',
      'company_logo': 'Company logo',
      'upload_logo_hint': 'Drag your logo here or click to browse',
      'hr_contact': 'HR Contact',
      'hr_manager_name': 'HR manager name',
      'recruitment_sectors': 'Recruitment sectors',
      'add_sector_hint': 'Add a sector...',
      'save': 'Save',
      'cancel': 'Cancel',
      'my_offers_title': 'My offers',
      'my_offers_subtitle': 'Manage and publish your job offers',
      'new_offer': 'New offer',
      'candidates_page_title': 'Candidates',
      'candidates_page_subtitle': 'View and manage candidate profiles',
      'search_candidate_hint': 'Search for a candidate...',
      'saved': 'Saved',
      'contact_candidate': 'Contact',
      'match': 'match',
      'post': 'Position',
    },
    'ar': {
      'dashboard': 'لوحة القيادة',
      'profile': 'ملفي الشخصي',
      'jobs': 'عروض العمل',
      'simulation': 'محاكاة المقابلة',
      'training': 'تدريبات',
      'logout': 'تسجيل الخروج',
      'welcome': 'مرحباً',
      'summary': 'إليك ملخص لنشاطك',
      'matched_offers': 'العروض المطابقة',
      'sent_applications': 'الطلبات المرسلة',
      'avg_match_score': 'متوسط درجة المطابقة',
      'simulated_interviews': 'المقابلات المحاكية',
      'recent_offers': 'العروض الأخيرة',
      'skills': 'المهارات',
      'upcoming_interviews': 'المقابلات القادمة',
      'profile_visibility': 'رؤية الملف الشخصي',
      'see_all': 'عرض الكل',
      'agenda': 'الأجندة',
      'edit': 'تعديل',
      'no_interviews': 'لا توجد مقابلات مجدولة',
      'views_this_month': 'مشاهدات هذا الشهر',
      'vs_last_month': 'مقارنة بالشهر الماضي',
      'language': 'اللغة',
      'manage_profile': 'إدارة معلوماتك ومهاراتك',
      'profile_completed': 'تم إكمال الملف الشخصي بنسبة',
      'complete_profile_hint': 'أضف سيرة ذاتية وصورة لإكمال ملفك الشخصي',
      'personal_info': 'المعلومات الشخصية',
      'first_name': 'الاسم الأول',
      'last_name': 'الاسم الأخير',
      'email': 'البريد الإلكتروني',
      'phone': 'رقم الهاتف',
      'location': 'الموقع',
      'bio': 'السيرة الذاتية',
      'my_cv': 'سيرتي الذاتية',
      'replace': 'استبدال',
      'upload_hint': 'انقر أو اسحب للتحميل',
      'add': 'إضافة',
      'save_changes': 'حفظ التغييرات',
      'find_jobs': 'ابحث عن العروض التي تناسب مهاراتك',
      'ai_match_hint':
          'عروض بنسبة مطابقة تتجاوز 80٪ - بناءً على تحليل سيرتك الذاتية ومهاراتك.',
      'search_hint': 'البحث حسب المسمى الوظيفي أو الشركة...',
      'all': 'الكل',
      'no_jobs_found': 'لم يتم العثور على عروض',
      'compatibility': 'مطابقة',
      'matching_skills': 'مهارات متطابقة',
      'hide': 'إخفاء',
      'details': 'تفاصيل',
      'apply': 'تقدم للوظيفة',
      'about_job': 'حول الوظيفة',
      'features': 'الميزات',
      'how_it_works': 'كيف يعمل',
      'for_whom': 'لمن',
      'login': 'تسجيل الدخول',
      'register': 'إنشاء حساب',
      'hero_label': 'منصة توظيف ذكية',
      'hero_title_1': 'مهاراتك هي ',
      'hero_title_2': 'أفضل أصولك',
      'hero_title_3': '',
      'hero_subtitle':
          'SkillSpace تربط الخريجين الجدد بالشركات من خلال الذكاء الاصطناعي. لا مزيد من ضغوط المقابلات - استعد، تطابق، واحصل على الوظيفة.',
      'btn_start_free': 'ابدأ مجاناً',
      'btn_discover': 'اكتشف المنصة',
      'stat_active_candidates': 'مرشحين نشطين',
      'stat_companies': 'شركة',
      'stat_satisfaction': 'معدل الرضا',
      'section_features_label': 'الميزات',
      'section_features_title': 'كل ما تحتاجه للحصول على وظيفتك الأولى',
      'section_features_subtitle':
          'تجمع SkillSpace بين الذكاء الاصطناعي والتدريب لزيادة فرصك في الاندماج المهني.',
      'feat_1_title': 'تحليل السيرة الذاتية بالذكاء الاصطناعي',
      'feat_1_desc':
          'ارفع سيرتك الذاتية واترك الذكاء الاصطناعي يستخرج مهاراتك تلقائياً.',
      'feat_2_title': 'مطابقة ذكية',
      'feat_2_desc': 'درجة مطابقة محسوبة بين ملفك الشخصي والعروض المتاحة.',
      'feat_3_title': 'تدريبات موصى بها',
      'feat_3_desc': 'سد فجواتك بتدريبات مستهدفة بناءً على متطلبات السوق.',
      'feat_4_title': 'محاكاة المقابلة',
      'feat_4_desc': 'تدرب مع روبوت محادثة ذكي يتكيف مع الوظيفة المستهدفة.',
      'feat_5_title': 'ذكاء اصطناعي يتعلم',
      'feat_5_desc': 'يتطور النظام باستمرار بفضل البيانات التي يتم جمعها.',
      'feat_6_title': 'اتجاهات السوق',
      'feat_6_desc': 'ابق على اطلاع بأكثر المهارات طلباً في قطاعك.',
      'section_steps_title': '4 خطوات نحو وظيفتك الأولى',
      'step_1_title': 'أنشئ ملفك الشخصي',
      'step_1_desc':
          'سجل وارفع سيرتك الذاتية. يقوم الذكاء الاصطناعي بتحليل مهاراتك في ثوانٍ.',
      'step_2_title': 'استلم المطابقات',
      'step_2_desc':
          'تقترح خوارزميتنا العروض الأكثر ملاءمة مع كشف نسبة المطابقة.',
      'step_3_title': 'استعد جيداً',
      'step_3_desc':
          'حاكي المقابلات مع الذكاء الاصطناعي وتابع التدريبات لسد الفجوات.',
      'step_4_title': 'احصل على الوظيفة',
      'step_4_desc': 'تقدم بثقة بملف شخصي محسّن واستعداد قوي.',
      'section_audience_label': 'لمن؟',
      'section_audience_title':
          'منصة لكل الخريجين الجدد ، أرباب العمل ، والمدربين',
      'role_recruiter': 'صاحب عمل',
      'role_recruiter_sub': 'شركة',
      'role_candidate': 'مرشح',
      'role_candidate_sub': 'خريج جديد',
      'role_trainer': 'مدرب',
      'role_trainer_sub': 'مركز تدريب',
      'btn_start': 'ابدأ الآن',
      'btn_learn_more': 'اكتشف المزيد',
      'cta_title': 'هل أنت مستعد لبدء مسيرتك المهنية؟',
      'cta_subtitle':
          'انضم إلى آلاف الخريجين الجدد الذين وجدوا وظيفتهم الأولى بفضل SkillSpace.',
      'btn_create_profile': 'أنشئ ملفي الشخصي مجاناً',
      'footer_rights': '© 2026 SkillSpace. جميع الحقوق محفوظة.',
      'footer_privacy': 'سياسة الخصوصية',
      'footer_tos': 'شروط الاستخدام',
      'footer_contact': 'اتصل بنا',
      'coming_soon': 'قريباً',
      'recruiter_feat_1': 'نشر عروض عمل مستهدفة',
      'recruiter_feat_2': 'فرز تلقائي للمرشحين',
      'recruiter_feat_3': 'تقييم المطابقة',
      'recruiter_feat_4': 'توفير وقت كبير',
      'candidate_feat_1': 'ملف شخصي قائم على المهارات',
      'candidate_feat_2': 'مطابقة ذكية مع العروض',
      'candidate_feat_3': 'محاكاة المقابلة بالذكاء الاصطناعي',
      'candidate_feat_4': 'تدريبات موصى بها',
      'trainer_feat_1': 'ظهور للمرشحين',
      'trainer_feat_2': 'توصيات ذكية مستهدفة',
      'trainer_feat_3': 'متابعة التسجيلات',
      'trainer_feat_4': 'التوافق مع متطلبات السوق',
      // Recruiter Strings
      'recruiter_dashboard': 'لوحة تحكم المجند',
      'publish_offer': 'نشر عرض',
      'active_offers': 'العروض النشطة',
      'received_applications': 'الطلبات المستلمة',
      'offer_views': 'مشاهدات العروض',
      'conversion_rate': 'معدل التحويل',
      'recent_candidates': 'المرشحون الأخيرون',
      'new_status': 'جديد',
      'in_review_status': 'قيد المراجعة',
      'interview_planned_status': 'تم تحديد موعد مقابلة',
      'company_profile_title': 'ملف الشركة',
      'company_profile_subtitle': 'إدارة معلومات شركتك',
      'profile_completion': 'تم إكمال الملف الشخصي بنسبة',
      'company_info': 'معلومات الشركة',
      'company_name': 'اسم الشركة',
      'business_sector': 'قطاع الأعمال',
      'company_size': 'حجم الشركة',
      'creation_year': 'سنة التأسيس',
      'website': 'الموقع الإلكتروني',
      'company_description': 'وصف الشركة',
      'company_logo': 'شعار الشركة',
      'upload_logo_hint': 'اسحب شعارك هنا أو انقر للتصفح',
      'hr_contact': 'جهة اتصال الموارد البشرية',
      'hr_manager_name': 'اسم مدير الموارد البشرية',
      'recruitment_sectors': 'قطاعات التوظيف',
      'add_sector_hint': 'أضف قطاعاً...',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'my_offers_title': 'عروضي',
      'my_offers_subtitle': 'إدارة ونشر عروض العمل الخاصة بك',
      'new_offer': 'عرض جديد',
      'candidates_page_title': 'المرشحون',
      'candidates_page_subtitle': 'عرض وإدارة ملفات المرشحين',
      'search_candidate_hint': 'البحث عن مرشح...',
      'saved': 'محفوظ',
      'contact_candidate': 'اتصال',
      'match': 'مطابقة',
      'post': 'المنصب',
    },
    'contract_cdi': {
      'fr': 'CDI',
      'en': 'Permanent',
      'ar': 'عقد دائم',
    },
    'contract_cdd': {
      'fr': 'CDD',
      'en': 'Fixed-term',
      'ar': 'عقد محدد المدة',
    },
    'contract_freelance': {
      'fr': 'Freelance',
      'en': 'Freelance',
      'ar': 'عمل حر',
    },
    'contract_stage': {
      'fr': 'Stage',
      'en': 'Internship',
      'ar': 'تدريب',
    },
    'upload_format_hint': {
      'fr': 'PDF, DOC — max 5 Mo',
      'en': 'PDF, DOC — max 5 MB',
      'ar': 'PDF, DOC — بحد أقصى 5 ميجابايت',
    },
    'cv_example_name': {
      'fr': 'CV_Jean_Dupont.pdf',
      'en': 'CV_John_Doe.pdf',
      'ar': 'السيرة_الذاتية.pdf',
    },
    'level_advanced': {
      'fr': 'Avancé',
      'en': 'Advanced',
      'ar': 'متقدم',
    },
    'level_intermediate': {
      'fr': 'Intermédiaire',
      'en': 'Intermediate',
      'ar': 'متوسط',
    },
    'level_expert': {
      'fr': 'Expert',
      'en': 'Expert',
      'ar': 'خبير',
    },
    'About Position': {
      'fr': 'À propos du poste',
      'en': 'About the position',
      'ar': 'حول الوظيفة',
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

class RecruiterLocalizationsDelegate extends LocalizationsDelegate<RecruiterLocalizations> {
  const RecruiterLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'fr', 'ar'].contains(locale.languageCode);

  @override
  Future<RecruiterLocalizations> load(Locale locale) async {
    return RecruiterLocalizations(locale);
  }

  @override
  bool shouldReload(RecruiterLocalizationsDelegate old) => false;
}
