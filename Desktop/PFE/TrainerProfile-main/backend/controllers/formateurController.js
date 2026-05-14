const Formateur = require('../models/formateurModel');
const Formation = require('../models/formationModel');
const jwt = require('jsonwebtoken');
const { suggestExpertiseDomains, generateBio: generateBioAI, validatePortfolioUrlAI, suggestFormationContent } = require('../services/ai-service');
const { sendVerificationEmail, sendLoginSuccessEmail } = require('../services/emailService');

const generateToken = (id) => {
  return jwt.sign({ id, sub: id }, process.env.JWT_SECRET, {
    expiresIn: '7d',
  });
};

const formatTimeDiff = (date) => {
  const diffInHours = Math.floor((new Date() - date) / (1000 * 60 * 60));
  if (diffInHours < 1) return 'À l\'instant';
  if (diffInHours < 24) return `Il y a ${diffInHours}h`;
  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays === 1) return 'Hier';
  return `Il y a ${diffInDays} jours`;
};


// @desc    Get formateur profile
// @route   GET /api/formateur/profile/:userId
const getProfile = async (req, res) => {
  try {
    const { userId } = req.params;
    const formateur = await Formateur.findById(userId);

    if (!formateur) {
      return res.status(404).json({ message: 'Profil non trouvé' });
    }
    res.status(200).json(formateur);
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

// @desc    Check if email exists
// @route   GET /api/formateur/exists/:email
const checkEmailExists = async (req, res) => {
  try {
    const { email } = req.params;
    const formateur = await Formateur.findOne({ email });
    res.status(200).json({ exists: !!formateur });
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

// @desc    Register a new formateur
// @route   POST /api/formateur/register
const register = async (req, res) => {
  try {
    const { firstName, lastName, email, password } = req.body;

    const existingFormateur = await Formateur.findOne({ email });
    if (existingFormateur) {
      return res.status(400).json({ message: 'Cet email est déjà utilisé' });
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    const formateur = await Formateur.create({
      firstName,
      lastName,
      email,
      password,
      resetOtp: otp,
      resetOtpExpires: otpExpires,
      isVerified: false,
      profileCompleteness: 10
    });

    await sendVerificationEmail(email, otp);

    res.status(201).json({
      requiresVerification: true,
      email: formateur.email,
      message: 'Un code de vérification a été envoyé à votre email.'
    });
  } catch (error) {
    res.status(500).json({ message: 'Erreur lors de l\'inscription', error: error.message });
  }
};

// @desc    Login formateur
// @route   POST /api/formateur/login
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const formateur = await Formateur.findOne({ email });
    if (formateur && (await formateur.matchPassword(password))) {

      if (!formateur.isVerified) {
        // Resend OTP if not verified
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        formateur.resetOtp = otp;
        formateur.resetOtpExpires = new Date(Date.now() + 10 * 60 * 1000);
        await formateur.save();
        await sendVerificationEmail(formateur.email, otp);

        return res.status(403).json({
          requiresVerification: true,
          email: formateur.email,
          message: 'Votre compte n\'est pas encore vérifié. Un nouveau code a été envoyé.'
        });
      }

      await sendLoginSuccessEmail(formateur.email, formateur.firstName);

      res.status(200).json({
        token: generateToken(formateur._id),
        user: {
          id: formateur._id,
          firstName: formateur.firstName,
          lastName: formateur.lastName,
          email: formateur.email,
          role: 'formateur'
        }
      });
    } else {
      res.status(401).json({ message: 'Email ou mot de passe incorrect.' });
    }
  } catch (error) {
    res.status(500).json({ message: 'Erreur lors de la connexion', error: error.message });
  }
};

const verifySignupOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;
    const formateur = await Formateur.findOne({
      email,
      resetOtp: otp,
      resetOtpExpires: { $gt: Date.now() }
    });

    if (!formateur) {
      return res.status(400).json({ message: 'Code invalide ou expiré.' });
    }

    formateur.isVerified = true;
    formateur.resetOtp = null;
    formateur.resetOtpExpires = null;
    await formateur.save();

    res.status(200).json({
      message: 'Compte vérifié avec succès.',
      token: generateToken(formateur._id),
      user: {
        id: formateur._id,
        firstName: formateur.firstName,
        lastName: formateur.lastName,
        email: formateur.email,
        role: 'formateur'
      }
    });
  } catch (error) {
    res.status(500).json({ message: 'Erreur lors de la vérification', error: error.message });
  }
};

// @desc    Quick partial update (only changed fields)
// @route   PATCH /api/formateur/profile/:userId
const patchProfile = async (req, res) => {
  try {
    const { userId } = req.params;
    const updateData = req.body; // Only contains fields the client wants to change

    // Remove protected fields
    delete updateData._id;
    delete updateData.password;
    delete updateData.email; // email changes need separate flow

    const formateur = await Formateur.findByIdAndUpdate(
      userId,
      { $set: updateData },
      { returnDocument: 'after', runValidators: true, upsert: true }
    );

    if (!formateur) {
      return res.status(404).json({ message: 'Profil non trouvé' });
    }

    res.status(200).json(formateur);
  } catch (error) {
    res.status(500).json({ message: 'Erreur lors de la mise à jour partielle', error: error.message });
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

    const formateur = await Formateur.findByIdAndUpdate(
      userId,
      updateData,
      { returnDocument: 'after', runValidators: true, upsert: true }
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
    let formateur = await Formateur.findById(userId);

    if (!formateur) {
      // This should ideally not happen if createTrainerProfile worked during login
      console.warn(`[Dashboard] Profile for ${userId} missing. Sync error? Returning 404.`);
      return res.status(404).json({ message: 'Profil formateur introuvable. Veuillez vous reconnecter.' });
    }

    // Fetch formations for this trainer
    const formations = await Formation.find({ trainerId: formateur._id }).sort({ createdAt: -1 });

    // Calculate basic stats
    const totalFormations = formations.length;
    const totalStudents = formations.reduce((acc, curr) => acc + curr.studentCount, 0);
    const avgRating = totalFormations > 0
      ? (formations.reduce((acc, curr) => acc + curr.rating, 0) / totalFormations).toFixed(1)
      : 0;

    // Dynamically calculate top formations by student count
    const topFormations = [...formations]
      .sort((a, b) => b.studentCount - a.studentCount)
      .slice(0, 5)
      .map(f => ({ name: f.title, count: f.studentCount }));

    // Extract real recent students from formations
    let allStudents = [];
    const threeDaysAgo = new Date(Date.now() - 3 * 24 * 60 * 60 * 1000);

    formations.forEach(f => {
      if (f.students && f.students.length > 0) {
        f.students.forEach(s => {
          const joinedDate = new Date(s.joinedAt);
          // Only include students who joined in the last 3 days
          if (joinedDate >= threeDaysAgo) {
            allStudents.push({
              id: s._id || Math.random().toString(),
              name: s.name,
              course: f.title,
              joinedAt: joinedDate,
              time: formatTimeDiff(joinedDate)
            });
          }
        });
      }
    });

    // Sort by joinedAt descending (newest first)
    allStudents.sort((a, b) => b.joinedAt - a.joinedAt);

    let recentStudents = allStudents.slice(0, 5);

    // Fallback to mock data ONLY if absolutely empty to keep UI populated during demo
    if (recentStudents.length === 0) {
      recentStudents = [
        { id: 1, name: 'Youssef Borcheni', course: 'Flutter Development Masterclass', time: 'À l\'instant' },
        { id: 2, name: 'Alice Dupont', course: 'SQL for Data Analytics', time: 'Il y a 5h' },
        { id: 3, name: 'Thomas Bernard', course: 'Introduction to Data Visualization', time: 'Hier' }
      ];
    }

    // Dynamically calculate recent activity
    const recentActivity = formations.map((f, i) => ({
      id: i + 1,
      text: `Nouveau participant inscrit à "${f.title}"`,
      date: 'Récemment'
    })).slice(0, 5);

    const stats = {
      totalFormations,
      totalStudents,
      avgRating,
      monthlyInscriptions: Math.round(totalStudents / 2) || 0,
      growthData: (() => {
        const months = ['Janv', 'Févr', 'Mars', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sept', 'Oct', 'Nov', 'Déc'];
        const now = new Date();
        const data = [];
        for (let i = 5; i >= 0; i--) {
          const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
          data.push({
            month: months[d.getMonth()],
            count: Math.floor(Math.random() * (totalStudents / 4 + 5)) + 2 // Poids réaliste
          });
        }
        return data;
      })(),

      recentActivity,
      recentStudents: recentStudents.slice(0, 5),
      topSkills: topFormations
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
    let formateur = await Formateur.findById(userId);

    if (!formateur) {
      return res.status(404).json({ message: 'Trainer not found. Cannot seed data.' });
    }

    const dummyFormations = [
      {
        trainerId: formateur._id,
        title: 'Mastering Machine Learning with Python',
        tags: ['AI', 'Python', 'Scikit-Learn'],
        studentCount: 342,
        rating: 4.9,
        reviewCount: 45,
        category: 'AI',
        duration: '45h',
        level: 'Avancé',
        description: 'Complete guide from basics to advanced ML architectures.',
        meetLink: 'https://meet.google.com/abc-defg-hij',
        date: new Date(),
        time: '14:00'
      },
      {
        trainerId: formateur._id,
        title: 'Fullstack Web Development with React & Node',
        tags: ['React', 'Node.js', 'MongoDB'],
        studentCount: 215,
        rating: 4.7,
        reviewCount: 28,
        category: 'Development',
        duration: '60h',
        level: 'Intermédiaire',
        description: 'Build real-world apps with the MERN stack.',
        meetLink: 'https://meet.google.com/abc-defg-hij',
        date: new Date(),
        time: '10:00'
      },
      {
        trainerId: formateur._id,
        title: 'Introduction to Data Visualization',
        tags: ['Tableau', 'PowerBI', 'Data Viz'],
        studentCount: 128,
        rating: 4.5,
        reviewCount: 15,
        category: 'Data Science',
        duration: '15h',
        level: 'Débutant',
        description: 'Learn to present data effectively.',
        meetLink: 'https://meet.google.com/abc-defg-hij',
        date: new Date(),
        time: '16:00'
      },
      {
        trainerId: formateur._id,
        title: 'Cybersecurity Fundamentals',
        tags: ['Security', 'Network', 'ethical hacking'],
        studentCount: 89,
        rating: 4.8,
        reviewCount: 12,
        category: 'IT Security',
        duration: '25h',
        level: 'Débutant',
        description: 'Protect your systems from cyber threats.',
        meetLink: 'https://meet.google.com/abc-defg-hij',
        date: new Date(),
        time: '18:30'
      },
      {
        trainerId: formateur._id,
        title: 'DevOps CI/CD Masterclass',
        tags: ['Docker', 'Kubernetes', 'Jenkins'],
        studentCount: 56,
        rating: 4.6,
        reviewCount: 8,
        category: 'DevOps',
        duration: '35h',
        level: 'Avancé',
        description: 'Automate your deployment pipeline.',
        meetLink: 'https://meet.google.com/abc-defg-hij',
        date: new Date(),
        time: '09:00'
      },
      {
        trainerId: formateur._id,
        title: 'UX/UI Design for Mobile Apps',
        tags: ['Figma', 'UX Research', 'Design Systems'],
        studentCount: 174,
        rating: 4.9,
        reviewCount: 32,
        category: 'Design',
        duration: '20h',
        level: 'Intermédiaire',
        description: 'Create stunning and intuitive mobile interfaces.',
        meetLink: 'https://meet.google.com/abc-defg-hij',
        date: new Date(),
        time: '11:00'
      },
      {
        trainerId: formateur._id,
        title: 'Deep Learning with TensorFlow',
        tags: ['Deep Learning', 'TensorFlow', 'CNN'],
        studentCount: 42,
        rating: 4.9,
        reviewCount: 5,
        category: 'AI',
        duration: '40h',
        level: 'Avancé',
        description: 'Building modern neural networks.',
        meetLink: 'https://meet.google.com/abc-defg-hij',
        date: new Date(),
        time: '15:00'
      },
      {
        trainerId: formateur._id,
        title: 'SQL for Data Analytics',
        tags: ['SQL', 'PostgreSQL', 'Query Optimization'],
        studentCount: 198,
        rating: 4.4,
        reviewCount: 22,
        category: 'Data',
        duration: '12h',
        level: 'Débutant',
        description: 'Extract and analyze data like a pro.',
        meetLink: 'https://meet.google.com/abc-defg-hij',
        date: new Date(),
        time: '08:00'
      },
      {
        trainerId: formateur._id,
        title: 'Flutter Development Masterclass',
        tags: ['Flutter', 'Dart', 'Mobile', 'App Development'],
        studentCount: 342,
        rating: 4.9,
        reviewCount: 45,
        category: 'Development',
        duration: '40h',
        level: 'Intermédiaire',
        description: 'Maîtrisez Flutter et Dart pour créer des applications iOS et Android magnifiques.',
        meetLink: 'https://meet.google.com/flutter-class',
        date: new Date(),
        time: '14:00'
      },
      {
        trainerId: formateur._id,
        title: 'Bases de Flutter pour Débutants',
        tags: ['Flutter', 'Dart', 'Mobile', 'UI'],
        studentCount: 120,
        rating: 4.8,
        reviewCount: 18,
        category: 'Development',
        duration: '10h',
        level: 'Débutant',
        description: 'Apprenez les fondamentaux de Flutter et créez votre première application mobile.',
        meetLink: 'https://meet.google.com/flutter-beginners',
        date: new Date(),
        time: '09:00'
      }
    ];

    await Formation.deleteMany({ trainerId: formateur._id });
    const created = await Formation.insertMany(dummyFormations);

    // Also update formateur profile to look "established"
    formateur.jobTitle = 'Senior AI & Fullstack Instructor';
    formateur.profileCompleteness = 95;
    formateur.expertise = ['Artificial Intelligence', 'Fullstack Development', 'DevOps', 'Data Visualization'];
    await formateur.save();

    res.status(201).json({ message: 'Dummy data seeded', count: created.length });
  } catch (error) {
    console.error('Seed Data Error:', error);
    res.status(500).json({ error: error.message });
  }
};


// @desc    Get only formations list
// @route   GET /api/formateur/formations/:userId
const getFormations = async (req, res) => {
  try {
    const { userId } = req.params;
    const formateur = await Formateur.findById(userId);

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

// @desc    Create a new formation
// @route   POST /api/formateur/formations/:userId
const createFormation = async (req, res) => {
  try {
    const { userId } = req.params;
    console.log(`[CreateFormation] Request for User: ${userId}`);
    console.log(`[CreateFormation] Body:`, JSON.stringify(req.body, null, 2));

    const formateur = await Formateur.findById(userId);

    if (!formateur) {
      console.error(`[CreateFormation] Trainer ${userId} not found`);
      return res.status(404).json({ message: 'Profil formateur non trouvé' });
    }

    const formationData = {
      ...req.body,
      trainerId: formateur._id
    };

    // Strict Field Validation
    const requiredFields = ['title', 'description', 'category', 'duration', 'meetLink', 'date', 'time', 'level'];
    const missingFields = requiredFields.filter(field => !formationData[field] || formationData[field].toString().trim() === '');
    
    if (missingFields.length > 0) {
      return res.status(400).json({ 
        message: 'Veuillez remplir tous les champs obligatoires.',
        missingFields: missingFields 
      });
    }

    // Prevent duplicate meet links
    if (formationData.meetLink) {
      const existingLink = await Formation.findOne({ 
        meetLink: formationData.meetLink 
      });
      if (existingLink) {
        return res.status(400).json({ 
          message: 'Ce lien de réunion est déjà utilisé pour une autre formation.' 
        });
      }
    }

    // Explicitly handle date if it's a string
    if (formationData.date && typeof formationData.date === 'string') {
      if (formationData.date.includes('/')) {
        const parts = formationData.date.split('/');
        if (parts.length === 3) {
          const day = parseInt(parts[0], 10);
          const month = parseInt(parts[1], 10) - 1; // Month is 0-indexed
          const year = parseInt(parts[2], 10);
          formationData.date = new Date(year, month, day);
        }
      } else {
        formationData.date = new Date(formationData.date);
      }
    }

    const newFormation = new Formation(formationData);

    const saved = await newFormation.save();
    console.log(`[CreateFormation] Success: ${saved._id}`);
    res.status(201).json(saved);
  } catch (error) {
    console.error(`[CreateFormation] Error:`, error);
    res.status(500).json({
      message: 'Erreur lors de la création de la formation',
      error: error.message,
      details: error.errors // Include validation details if any
    });
  }
};

// @desc    Update a formation
// @route   PUT /api/formateur/formations/item/:id
const updateFormation = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = { ...req.body };

    // Remove protected fields
    delete updateData.trainerId;
    delete updateData._id;

    if (updateData.meetLink) {
      const existingLink = await Formation.findOne({ 
        meetLink: updateData.meetLink,
        _id: { $ne: id }
      });
      if (existingLink) {
        return res.status(400).json({ 
          message: 'Ce lien de réunion est déjà utilisé pour une autre formation.' 
        });
      }
    }

    const updated = await Formation.findByIdAndUpdate(
      id,
      updateData,
      { returnDocument: 'after', runValidators: true }
    );

    if (!updated) {
      return res.status(404).json({ message: 'Formation non trouvée' });
    }

    res.status(200).json(updated);
  } catch (error) {
    res.status(500).json({ message: 'Erreur lors de la mise à jour', error: error.message });
  }
};

// @desc    Delete a formation
// @route   DELETE /api/formateur/formations/item/:id
const deleteFormation = async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await Formation.findByIdAndDelete(id);

    if (!deleted) {
      return res.status(404).json({ message: 'Formation non trouvée' });
    }

    res.status(200).json({ message: 'Formation supprimée avec succès' });
  } catch (error) {
    res.status(500).json({ message: 'Erreur lors de la suppression', error: error.message });
  }
};

// @desc    AI-powered formation content enhancement
// @route   POST /api/formateur/enhance-formation
const enhanceFormation = async (req, res) => {
  try {
    const { title } = req.body;
    if (!title) {
      return res.status(400).json({ message: 'Title is required' });
    }

    const suggestion = await suggestFormationContent(title);
    res.status(200).json(suggestion);
  } catch (error) {
    console.error('Enhance formation error:', error.message);
    res.status(500).json({ message: 'Erreur lors de la mise à jour', error: error.message });
  }
};

// @desc    Get all formations across all trainers (for searching/recommendation)
// @route   GET /api/formateur/all-formations
const getAllFormations = async (req, res) => {
  try {
    const { query, level } = req.query;
    let filter = {};

    if (query) {
      const regexQuery = new RegExp(query, 'i');
      filter.$or = [
        { tags: { $in: [regexQuery] } },
        { title: regexQuery },
        { description: regexQuery }
      ];
    }

    if (level) {
      filter.level = level;
    }

    const formations = await Formation.find(filter)
      .populate('trainerId', 'firstName lastName email jobTitle')
      .sort({ rating: -1, studentCount: -1 })
      .limit(10);

    res.status(200).json(formations);
  } catch (error) {
    console.error('Error fetching all formations:', error);
    res.status(500).json({ message: 'Erreur lors de la récupération des formations', error: error.message });
  }
};
const getFormationById = async (req, res) => {
  try {
    const { id } = req.params;
    const formation = await Formation.findById(id).populate('trainerId', 'firstName lastName email jobTitle');
    if (!formation) {
      return res.status(404).json({ message: 'Formation non trouvée' });
    }
    res.status(200).json(formation);
  } catch (error) {
    res.status(500).json({ message: 'Erreur lors de la récupération', error: error.message });
  }
};
const enrollFormation = async (req, res) => {
  try {
    const { id } = req.params;
    const { userName } = req.body;
    const studentName = userName || 'Étudiant Anonyme';

    const updated = await Formation.findByIdAndUpdate(
      id,
      {
        $inc: { studentCount: 1 },
        $push: { students: { name: studentName } }
      },
      { returnDocument: 'after' }
    );

    if (!updated) {
      return res.status(404).json({ message: 'Formation non trouvée' });
    }

    res.status(200).json({ message: 'Inscrit avec succès', studentCount: updated.studentCount });
  } catch (error) {
    res.status(500).json({ message: 'Erreur lors de l\'inscription', error: error.message });
  }
};
const leaveFormation = async (req, res) => {
  try {
    const { id } = req.params;
    const { userName } = req.body;

    const updated = await Formation.findByIdAndUpdate(
      id,
      {
        $inc: { studentCount: -1 },
        $pull: { students: { name: userName } }
      },
      { returnDocument: 'after' }
    );

    if (!updated) {
      return res.status(404).json({ message: 'Formation non trouvée' });
    }

    res.status(200).json({ message: 'Désinscrit avec succès', studentCount: updated.studentCount });
  } catch (error) {
    res.status(500).json({ message: 'Erreur lors de la désinscription', error: error.message });
  }
};
const updateFormationRating = async (req, res) => {
  try {
    const { id } = req.params;
    const { rating } = req.body;

    const formation = await Formation.findById(id);
    if (!formation) {
      return res.status(404).json({ message: 'Formation non trouvée' });
    }

    // Recalculate average rating for formation
    const currentTotal = formation.rating * formation.reviewCount;
    const newCount = formation.reviewCount + 1;
    const newAvg = (currentTotal + rating) / newCount;

    formation.rating = parseFloat(newAvg.toFixed(1));
    formation.reviewCount = newCount;
    await formation.save();

    // Update the trainer's global average rating
    const trainer = await Formateur.findById(formation.trainerId);
    if (trainer) {
      const currentGlobalTotal = (trainer.averageRating || 0) * (trainer.totalReviews || 0);
      const newGlobalCount = (trainer.totalReviews || 0) + 1;
      const newGlobalAvg = (currentGlobalTotal + rating) / newGlobalCount;
      
      trainer.averageRating = parseFloat(newGlobalAvg.toFixed(1));
      trainer.totalReviews = newGlobalCount;
      await trainer.save();
    }

    res.status(200).json({ message: 'Note mise à jour', rating: formation.rating, count: formation.reviewCount });
  } catch (error) {
    res.status(500).json({ message: 'Erreur lors de la mise à jour de la note', error: error.message });
  }
};

module.exports = {
  getProfile,
  updateProfile,
  getDashboardData,
  getFormations,
  getAllFormations,
  seedDummyData,
  suggestExpertise,
  generateBio,
  validateUrl,
  createFormation,
  updateFormation,
  deleteFormation,
  enhanceFormation,
  register,
  login,
  verifySignupOtp,
  checkEmailExists,
  patchProfile,
  enrollFormation,
  leaveFormation,
  getFormationById,
  updateFormationRating
};
