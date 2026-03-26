import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/formateur_service.dart';
import '../models/formateur_model.dart';
import 'profile_view_screen.dart';

class FormateurProfileScreen extends StatefulWidget {
  const FormateurProfileScreen({super.key});

  @override
  _FormateurProfileScreenState createState() => _FormateurProfileScreenState();
}

class _FormateurProfileScreenState extends State<FormateurProfileScreen> {
  final FormateurService _formateurService = FormateurService();
  final String _userId =
      '507f1f77bcf86cd799439011'; // Valid 24-character hex string ObjectId
  bool _isLoading = true;
  int _completeness = 0;

  String _profilePictureBase64 = '';
  List<Certification> certificationsList = [];

  final List<String> _availableDomains = [
    'Développement Web Frontend',
    'Développement Web Backend',
    'Développement Full Stack',
    'Développement Mobile (Android / iOS)',
    'Développement Desktop',
    'Programmation Python',
    'Programmation Java',
    'Programmation C / C++ / C#',
    'Développement API (REST, GraphQL)',
    'Machine Learning',
    'Deep Learning',
    'Data Science',
    'Analyse de données',
    'Big Data',
    'Traitement du langage naturel (NLP)',
    'Computer Vision',
    'Data Engineering',
    'Administration Systèmes (Linux / Windows)',
    'Réseaux informatiques',
    'Cloud Computing (AWS, Azure, GCP)',
    'Virtualisation',
    'DevOps',
    'Docker & Kubernetes',
    'Cybersécurité',
    'Sécurité des réseaux',
    'Ethical Hacking',
    'Pentesting',
    'Cryptographie',
    'Sécurité des applications',
    'Génie logiciel',
    'Architecture logicielle',
    'Tests logiciels (QA)',
    'Méthodes Agile / Scrum',
    'Gestion de projet IT',
    'UML & conception',
    'UI Design',
    'UX Design',
    'Web Design',
    'Prototypage (Figma, Adobe XD)',
    'Design d’interfaces',
    'SQL (MySQL, PostgreSQL)',
    'NoSQL (MongoDB)',
    'Data Modeling',
    'Administration de bases de données',
    'Big Data Storage'
  ];

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();

  final _linkedInController = TextEditingController();
  final _portfolioController = TextEditingController();

  List<String> expertiseList = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await _formateurService.getProfile(_userId);
    if (profile != null) {
      setState(() {
        _firstNameController.text = profile.firstName;
        _lastNameController.text = profile.lastName;
        _emailController.text = profile.email;
        _phoneController.text = profile.phone;
        _jobTitleController.text = profile.jobTitle;
        _locationController.text = profile.location;
        _bioController.text = profile.bio;
        _linkedInController.text = profile.linkedIn;
        _portfolioController.text = profile.portfolio;
        expertiseList = profile.expertise.toList();
        _completeness = profile.profileCompleteness;
        _profilePictureBase64 = profile.profilePicture;
        certificationsList = profile.certifications;
        _isLoading = false;
      });
    } else {
      setState(() {
        _firstNameController.text = 'Sophie';
        _lastNameController.text = 'Bernard';
        _emailController.text = 'sophie.bernard@email.com';
        _phoneController.text = '+33 6 98 76 54 32';
        _jobTitleController.text = 'Formatrice senior en développement web';
        _locationController.text = 'Lyon, France';
        _bioController.text =
            "Formatrice passionnée avec 8 ans d'expérience dans le développement web et la data science.";
        _linkedInController.text = 'https://linkedin.com/in/sophie-bernard';
        _portfolioController.text = 'https://sophiebernard.dev';
        expertiseList = [
          "React",
          "JavaScript",
          "Python",
          "Data Science",
          "UX Design"
        ];
        _completeness = 70;
        _profilePictureBase64 = '';
        certificationsList = [
          Certification(
              name: 'Certified Scrum Master (CSM)',
              issuer: 'Scrum Alliance',
              year: '2023'),
          Certification(
              name: 'Google Professional Data Engineer',
              issuer: 'Google Cloud',
              year: '2022')
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.length < 4 || lastName.length < 4) {
      Fluttertoast.showToast(
          msg: "Le prénom et le nom doivent contenir au moins 4 caractères.",
          backgroundColor: Colors.red,
          textColor: Colors.white);
      setState(() => _isLoading = false);
      return;
    }

    final newProfile = FormateurModel(
      id: '',
      userId: _userId,
      firstName: firstName,
      lastName: lastName,
      email: _emailController.text,
      phone: _phoneController.text,
      jobTitle: _jobTitleController.text,
      location: _locationController.text,
      bio: _bioController.text,
      profilePicture: _profilePictureBase64,
      profileCompleteness: 0,
      expertise: expertiseList,
      certifications: certificationsList,
      linkedIn: _linkedInController.text,
      portfolio: _portfolioController.text,
    );

    final updatedProfile =
        await _formateurService.updateProfile(_userId, newProfile);

    setState(() {
      _isLoading = false;
      if (updatedProfile != null) {
        _completeness = updatedProfile.profileCompleteness;
      }
    });

    if (updatedProfile != null) {
      Fluttertoast.showToast(
          msg: "Votre profil a bien été créé/mis à jour !",
          backgroundColor: Colors.green,
          textColor: Colors.white);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProfileViewScreen(profile: updatedProfile)),
        );
      }
    } else {
      Fluttertoast.showToast(
          msg: "Erreur lors de l'enregistrement",
          backgroundColor: Colors.red,
          textColor: Colors.white);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _profilePictureBase64 = base64Encode(bytes);
      });
    }
  }

  void _showExpertiseDialog() {
    final TextEditingController customExpertiseController =
        TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter un domaine d\'expertise'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: customExpertiseController,
                        decoration: const InputDecoration(
                          hintText: 'Ou saisissez un autre domaine...',
                          isDense: true,
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            if (!expertiseList.contains(value.trim())) {
                              setState(() => expertiseList.add(value.trim()));
                            }
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.blue),
                      onPressed: () {
                        if (customExpertiseController.text.trim().isNotEmpty) {
                          if (!expertiseList.contains(
                              customExpertiseController.text.trim())) {
                            setState(() => expertiseList
                                .add(customExpertiseController.text.trim()));
                          }
                          Navigator.of(context).pop();
                        }
                      },
                    )
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _availableDomains.length,
                    itemBuilder: (context, index) {
                      final domain = _availableDomains[index];
                      return ListTile(
                        title: Text(domain),
                        onTap: () {
                          if (!expertiseList.contains(domain)) {
                            setState(() {
                              expertiseList.add(domain);
                            });
                          }
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCertificationDialog() {
    final nameCtrl = TextEditingController();
    final issuerCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter une certification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nom de la certification')),
              TextField(
                  controller: issuerCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Délivrée par (ex: Google)')),
              TextField(
                  controller: yearCtrl,
                  decoration: const InputDecoration(labelText: 'Année'),
                  keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && issuerCtrl.text.isNotEmpty) {
                  setState(() {
                    certificationsList.add(Certification(
                      name: nameCtrl.text,
                      issuer: issuerCtrl.text,
                      year: yearCtrl.text,
                    ));
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Ajouter'),
            )
          ],
        );
      },
    );
  }

  void _removeExpertise(String item) {
    setState(() {
      expertiseList.remove(item);
    });
  }

  void _removeCertification(Certification c) {
    setState(() {
      certificationsList.remove(c);
    });
  }

  ImageProvider? _getProfileImage() {
    if (_profilePictureBase64.isEmpty) return null;
    try {
      final bytes = base64Decode(_profilePictureBase64);
      return MemoryImage(bytes);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil formateur'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Gérez vos informations et domaines d\'expertise',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Profil complété à',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text('$_completeness%',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _completeness / 100,
                              backgroundColor: Colors.grey[200],
                              color: Colors.blue,
                              minHeight: 8,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Ajoutez une photo et des certifications pour renforcer votre crédibilité',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Informations personnelles',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _buildTextField('Prénom', _firstNameController,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-ZÀ-ÿ\s-]')),
                                ]),
                            _buildTextField('Nom', _lastNameController,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-ZÀ-ÿ\s-]')),
                                ]),
                            _buildTextField('Email', _emailController,
                                type: TextInputType.emailAddress),
                            _buildTextField('Téléphone', _phoneController,
                                type: TextInputType.phone),
                            _buildTextField(
                                'Titre professionnel', _jobTitleController),
                            _buildTextField(
                                'Localisation', _locationController),
                            _buildTextField('Bio', _bioController,
                                type: TextInputType.multiline, maxLines: 3),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Photo de profil',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: _pickImage,
                              child: Container(
                                width: double.infinity,
                                height: 160,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.grey,
                                      style: BorderStyle.solid,
                                      width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                  image: _getProfileImage() != null
                                      ? DecorationImage(
                                          image: _getProfileImage()!,
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _getProfileImage() == null
                                    ? const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.cloud_upload,
                                              size: 40, color: Colors.grey),
                                          SizedBox(height: 8),
                                          Text('Cliquez pour parcourir',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text('PNG ou JPG, 2 Mo max',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
                                        ],
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.military_tech),
                                SizedBox(width: 8),
                                Text('Domaines d\'expertise',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: expertiseList
                                  .map((e) => Chip(
                                        label: Text(e),
                                        onDeleted: () => _removeExpertise(e),
                                        deleteIcon:
                                            const Icon(Icons.close, size: 16),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showExpertiseDialog,
                              icon: const Icon(Icons.add),
                              label:
                                  const Text('Ajouter un domaine d\'expertise'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.menu_book),
                                SizedBox(width: 8),
                                Text('Certifications & Diplômes',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...certificationsList
                                .map((c) => _buildCertificationItem(c)),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _showAddCertificationDialog,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Ajouter une certification'),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.link),
                                SizedBox(width: 8),
                                Text('Liens professionnels',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTextField('LinkedIn', _linkedInController,
                                type: TextInputType.url),
                            _buildTextField('Portfolio / Site web',
                                _portfolioController, type: TextInputType.url),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Enregistrer'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType type = TextInputType.text,
      int maxLines = 1,
      List<TextInputFormatter>? inputFormatters}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: type,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationItem(Certification c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 2,
            height: 40,
            color: Colors.blue.withOpacity(0.5),
            margin: const EdgeInsets.only(right: 12, top: 4),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${c.issuer} · ${c.year}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () => _removeCertification(c),
          ),
        ],
      ),
    );
  }
}
