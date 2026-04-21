const Formateur = require('../models/formateurModel');
const Formation = require('../models/formationModel');
const { suggestExpertiseDomains, generateBio: generateBioAI, validatePortfolioUrlAI } = require('../services/ai-service');

// @desc    Get formateur profile
// @route   GET /api/formateur/profile/:userId
const getProfile = async (req, res) => {
  try {
    const formateur = await Formateur.findOne({ userId: req.params.userId });
    if (!formateur) {
      return res.status(404).json({ message: 'Profil non trouvé' });
    }
    res.status(200).json(formateur);
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

// @desc    Create or Update formateur profile
// @route   PUT /api/formateur/profile/:userId
const updateProfile = async (req, res) => {
  try {
    const { userId } = req.params;
    const updateData = req.body;

    // Calculate profile completeness roughly
    let completeness = 0;
    if (updateData.firstName && updateData.lastName) completeness += 20;
    if (updateData.email) completeness += 10;
    if (updateData.bio) completeness += 20;
    if (updateData.profilePicture) completeness += 20;
    if (updateData.expertise && updateData.expertise.length > 0) completeness += 15;
    if (updateData.certifications && updateData.certifications.length > 0) completeness += 15;

    updateData.profileCompleteness = Math.min(completeness, 100);

    const formateur = await Formateur.findOneAndUpdate(
      { userId },
      updateData,
      { new: true, upsert: true, runValidators: true }
    );

    res.status(200).json(formateur);
  } catch (error) {
    res.status(500).json({ message: 'Erreur lors de la mise à jour', error: error.message });
  }
};

// @desc    Get dashboard data (stats, formations, activity)
// @route   GET /api/formateur/dashboard/:userId
const getDashboardData = async (req, res) => {
  try {
    const { userId } = req.params;
    const formateur = await Formateur.findOne({ userId });

    if (!formateur) {
      return res.status(404).json({ message: 'Profil non trouvé' });
    }

    // Fetch formations for this trainer
    const formations = await Formation.find({ trainerId: formateur._id }).sort({ createdAt: -1 });

    // Calculate basic stats
    const totalFormations = formations.length;
    const totalStudents = formations.reduce((acc, curr) => acc + curr.studentCount, 0);
    const avgRating = totalFormations > 0
      ? (formations.reduce((acc, curr) => acc + curr.rating, 0) / totalFormations).toFixed(1)
      : 0;

    // Dynamically calculate top skills from tags
    const skillCount = {};
    formations.forEach(f => {
      if (f.tags) {
        f.tags.forEach(tag => {
          skillCount[tag] = (skillCount[tag] || 0) + f.studentCount;
        });
      }
    });

    const topSkills = Object.keys(skillCount)
      .map(name => ({ name, count: skillCount[name] }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 5);

    // Dynamically calculate recent students
    const recentStudents = [];
    let studentId = 1;
    formations.forEach(f => {
      if (f.studentCount > 0) {
        recentStudents.push({
          id: studentId++,
          name: `Étudiant (Généré)`,
          course: f.title,
          time: 'Récemment'
        });
      }
    });

    // Dynamically calculate recent activity
    const recentActivity = formations.map((f, i) => ({
      id: i + 1,
      text: `Formation "${f.title}" compte maintenant ${f.studentCount} étudiants`,
      date: 'Récemment' // In a real app we'd use f.updatedAt or a dedicated logs table
    })).slice(0, 5);

    const stats = {
      totalFormations,
      totalStudents,
      avgRating,
      monthlyInscriptions: Math.round(totalStudents / 2) || 0, // Mocked based on real var
      growthData: [
        { month: 'J-6', count: Math.round(totalStudents * 0.1) },
        { month: 'J-5', count: Math.round(totalStudents * 0.2) },
        { month: 'J-4', count: Math.round(totalStudents * 0.3) },
        { month: 'J-3', count: Math.round(totalStudents * 0.1) },
        { month: 'J-2', count: Math.round(totalStudents * 0.4) },
        { month: 'J-1', count: Math.round(totalStudents * 0.5) },
      ],
      recentActivity,
      recentStudents: recentStudents.slice(0, 5),
      topSkills
    };

    res.status(200).json({
      formateur,
      formations,
      stats
    });
  } catch (error) {
    res.status(500).json({ message: 'Erreur lors du chargement du dashboard', error: error.message });
  }
};

// @desc    AI-powered bio generation using Groq Llama 4 Scout
// @route   POST /api/formateur/generate-bio
const generateBio = async (req, res) => {
  try {
    const { name, jobTitle, expertise = [] } = req.body;
    if (!name || !jobTitle) {
      return res.status(400).json({ message: 'Name and Job Title are required' });
    }

    const bio = await generateBioAI(name, jobTitle, expertise);
    res.status(200).json({ bio });
  } catch (error) {
    console.error('Bio generation error:', error.message);
    res.status(500).json({ message: 'Error generating bio', error: error.message });
  }
};

// @desc    AI-powered expertise domain suggestions using Groq Llama 4 Scout
// @route   POST /api/formateur/suggest-expertise
const suggestExpertise = async (req, res) => {
  try {
    const { query, existing = [] } = req.body;
    if (!query || query.trim().length < 1) {
      return res.status(400).json({ message: 'Query is required' });
    }

    const suggestions = await suggestExpertiseDomains(query, existing);
    res.status(200).json({ suggestions });
  } catch (error) {
    console.error('Expertise suggestion error:', error.message);
    // Fallback to static list if AI call fails
    const fallback = [
      'Intelligence Artificielle', 'Développement Web', 'Data Science',
      'Cybersécurité', 'Cloud Computing', 'UX/UI Design',
      'Marketing Digital', 'Gestion de Projet', 'DevOps', 'Mobile Development'
    ];
    res.status(200).json({ suggestions: fallback });
  }
};

// @desc    Seed dummy formations for testing
const seedDummyData = async (req, res) => {
  try {
    const { userId } = req.params;
    let formateur = await Formateur.findOne({ userId });

    if (!formateur) {
      // Auto-create basic profile so we can attach formations to it
      formateur = await Formateur.create({
        userId,
        firstName: 'Nouveau',
        lastName: 'Formateur',
        email: 'formateur@skillspace.com',
        profileCompleteness: 10
      });
    }

    const dummyFormations = [
      {
        trainerId: formateur._id,
        title: 'Python pour la Data Science',
        tags: ['Python', 'Pandas', 'NumPy'],
        studentCount: 64,
        rating: 4.8,
        category: 'Data Science'
      },
      {
        trainerId: formateur._id,
        title: 'Introduction au Machine Learning',
        tags: ['ML', 'Scikit-learn', 'Statistiques'],
        studentCount: 52,
        rating: 4.7,
        category: 'AI'
      },
      {
        trainerId: formateur._id,
        title: 'SQL Avancé & Bases de données',
        tags: ['SQL', 'PostgreSQL', 'Modélisation'],
        studentCount: 41,
        rating: 4.5,
        category: 'Data'
      },
      {
        trainerId: formateur._id,
        title: 'Deep Learning avec TensorFlow',
        tags: ['Deep Learning', 'TensorFlow', 'CNN'],
        studentCount: 33,
        rating: 4.9,
        category: 'AI'
      },
      {
        trainerId: formateur._id,
        title: 'Data Visualization avec Power BI',
        tags: ['Power BI', 'Dashboards', 'KPIs'],
        studentCount: 24,
        rating: 4.4,
        category: 'Data Science'
      }
    ];

    await Formation.deleteMany({ trainerId: formateur._id });
    const created = await Formation.insertMany(dummyFormations);

    res.status(201).json({ message: 'Dummy data seeded', count: created.length });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};


// @desc    Get only formations list
// @route   GET /api/formateur/formations/:userId
const getFormations = async (req, res) => {
  try {
    const { userId } = req.params;
    const formateur = await Formateur.findOne({ userId });

    if (!formateur) {
      return res.status(404).json({ message: 'Profil non trouvé' });
    }

    const formations = await Formation.find({ trainerId: formateur._id }).sort({ createdAt: -1 });

    res.status(200).json(formations);
  } catch (error) {
    res.status(500).json({ message: 'Erreur lors du chargement des formations', error: error.message });
  }
};

// @desc    Validate a portfolio URL using AI
// @route   POST /api/formateur/validate-url
const validateUrl = async (req, res) => {
  try {
    const { url } = req.body;
    if (!url) {
      return res.status(400).json({ message: 'URL is required' });
    }

    const result = await validatePortfolioUrlAI(url);
    res.status(200).json(result);
  } catch (error) {
    console.error('URL validation error:', error.message);
    res.status(200).json({ isValid: true, reason: '' }); // Fallback to avoid blocking user
  }
};

module.exports = {
  getProfile,
  updateProfile,
  getDashboardData,
  getFormations,
  seedDummyData,
  suggestExpertise,
  generateBio,
  validateUrl,
};
