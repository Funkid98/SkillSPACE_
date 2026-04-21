const User = require('../models/candidat')
const Match = require('../models/match')
const axios = require('axios')
const { hashPassword, verifyPassword, createToken, calculateCompletion } = require('../services/candidat-service')


// Register (for testing)
const register = async (req, res) => {
    try {
        const { email, password, prenom, nom } = req.body
        const hashedPassword = await hashPassword(password)
        const user = new User({ email, password: hashedPassword, prenom, nom })
        await user.save()
        const token = createToken(user._id)
        res.status(201).json({
            token,
            user: { _id: user._id, email: user.email, prenom: user.prenom, nom: user.nom, role: user.role, sector: user.sector }
        })
    } catch (err) {
        res.status(500).json({ error: err.message })
    }
}

// Login (for testing)
const login = async (req, res) => {
    try {
        const { email, password } = req.body
        console.log('Login attempt for:', email)
        const user = await User.findOne({ email })
        if (!user || !(await verifyPassword(password, user.password))) {
            return res.status(401).json({ error: 'Invalid credentials' })
        }
        console.log('User found in DB:', user.email, 'Sector:', user.sector)
        const token = createToken(user._id)

        // Trigger AI matching in the background immediately on login
        try {
            const { runBackgroundMatchForCandidate } = require('../services/background-matcher')
            runBackgroundMatchForCandidate(user._id).catch(e => console.error("Background match login trigger error:", e))
        } catch (e) {
            console.error("Failed to start background match at login:", e)
        }

        res.json({
            token,
            user: { _id: user._id, email: user.email, prenom: user.prenom, nom: user.nom, role: user.role, sector: user.sector }
        })
    } catch (err) {
        res.status(500).json({ error: err.message })
    }
}


//Get Profile
const getProfile = async (req, res) => {
    try {
        const user = await User.findById(req.userId).select('-password').lean()
        if (!user) return res.status(404).json({ error: 'User not found' })

        // Auto-migrate old string skills to {name, percent} objects
        if (user.skills && user.skills.some(s => typeof s === 'string')) {
            user.skills = user.skills.map(s =>
                typeof s === 'string' ? { name: s, percent: 50 } : s
            )
            // Save migrated skills back to DB
            await User.findByIdAndUpdate(req.userId, { skills: user.skills })
        }

        res.json(user)
    } catch (err) {
        res.status(500).json({ error: err.message })
    }
}

//Update Profile
const updateProfile = async (req, res) => {
    try {
        const updates = req.body
        console.log('Updating user:', req.userId, 'with:', updates)

        // Normalize skills: convert any plain strings to {name, percent} objects
        if (updates.skills && Array.isArray(updates.skills)) {
            updates.skills = updates.skills.map(s =>
                typeof s === 'string' ? { name: s, percent: 50 } : s
            )
        }

        const user = await User.findByIdAndUpdate(
            req.userId,
            { $set: updates },
            { returnDocument: 'after' }
        ).select('-password').lean()

        const completion = calculateCompletion(user)
        await User.findByIdAndUpdate(req.userId, { completion_percent: completion })

        // Fire and forget background matcher
        try {
            const { runBackgroundMatchForCandidate } = require('../services/background-matcher')
            runBackgroundMatchForCandidate(user._id).catch(e => console.error("Background match trigger error:", e))
        } catch (e) {
            console.error("Failed to start background match module:", e)
        }

        res.json({ message: 'Profile updated', completion_percent: completion })
    } catch (err) {
        res.status(500).json({ error: err.message })
    }
}

// Get recent candidates matching recruiter's job titles
const getRecentCandidatesBySector = async (req, res) => {
    try {
        const recruiterId = req.userId

        let recruiterOffers = []
        try {
            const offerRes = await axios.get('http://127.0.0.1:5003/api/offers')
            recruiterOffers = offerRes.data.filter(o => o.recruiter && o.recruiter.toString() === recruiterId.toString())
        } catch (err) {
            console.error('Error fetching recruiter offers:', err.message)
        }

        if (!recruiterOffers || recruiterOffers.length === 0) {
            return res.json([])
        }

        const offerTitles = recruiterOffers.map(o => o.title)
        const jobTitleRegexes = offerTitles.map(title => new RegExp(`^${title.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i')) // Match exactly but ignore case
        const query = { jobtitle: { $in: jobTitleRegexes } }

        const candidates = await User.find(query)
            .select('prenom nom jobtitle sector localisation skills bio cv_path')
            .sort({ createdAt: -1 })
            .limit(10)
            .lean()

        // Map to a format expected by the frontend
        const formattedCandidates = []

        for (const c of candidates) {
            // Find the best matched offer for this candidate's job title
            const matchedOffer = recruiterOffers.find(o =>
                new RegExp('^' + o.title.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '$', 'i').test(c.jobtitle) ||
                new RegExp(o.title, 'i').test(c.jobtitle) ||
                new RegExp(c.jobtitle, 'i').test(o.title)
            ) || recruiterOffers[0]

            // Construct CV from path if exists, else fallback to db profile
            let cvText = '';

            if (c.cv_path) {
                try {
                    const fs = require('fs');
                    const { extractText } = require('../services/extractor');
                    if (fs.existsSync(c.cv_path)) {
                        const fileBuffer = fs.readFileSync(c.cv_path);
                        const extractedCvText = await extractText(fileBuffer, c.cv_path);
                        if (extractedCvText && extractedCvText.trim()) {
                            cvText = extractedCvText;
                        }
                    }
                } catch (extractErr) {
                    console.error('Failed to extract text from cv_path:', extractErr.message);
                }
            }

            // Fallback if cvText is still empty
            if (!cvText) {
                const cvSkills = (c.skills || []).map(s => typeof s === 'string' ? s : s.name).join(', ')
                cvText = `Job Title: ${c.jobtitle || 'N/A'}\nBio: ${c.bio || 'N/A'}\nSkills: ${cvSkills}`
            }

            const jobDescriptionText = `Title: ${matchedOffer.title}\nDescription: ${matchedOffer.description}\nRequirements: ${(matchedOffer.requirements || []).join(', ')}`

            let matchScore = 0
            let matchingAnalysis = ""
            let recommendation = ""

            // Check if we already have a generated match for this offer in our Match collection
            const existingMatch = await Match.findOne({ candidateId: c._id, offerId: matchedOffer._id })

            let matchStatus = 'COMPLETED';

            if (existingMatch) {
                // 1. Use cached result from Match collection
                matchScore = existingMatch.score || 0;
                matchingAnalysis = existingMatch.analysis || "";
                recommendation = existingMatch.recommendation || "";
                matchStatus = existingMatch.status || 'COMPLETED';
            } else {
                // 2. No cache — save ANALYSING placeholder and fire background AI
                matchScore = 0;
                matchingAnalysis = "L'IA analyse le profil pour trouver la meilleure correspondance...";
                recommendation = "Analyse en cours...";
                matchStatus = 'ANALYSING';

                await Match.findOneAndUpdate(
                    { candidateId: c._id, offerId: matchedOffer._id },
                    {
                        $setOnInsert: {
                            score: matchScore,
                            analysis: matchingAnalysis,
                            recommendation: recommendation,
                            matchedSkills: [],
                            missingSkills: [],
                            status: matchStatus
                        }
                    },
                    { upsert: true, returnDocument: 'after' }
                ).catch(e => console.error('Cache save error:', e.message));

                // Trigger AI in background (non-blocking)
                try {
                    const { runBackgroundMatchForCandidate } = require('../services/background-matcher');
                    runBackgroundMatchForCandidate(c._id).catch(e => console.error("BG match error:", e));
                } catch (e) {
                    console.error("Failed to start background match:", e);
                }
            }

            formattedCandidates.push({
                _id: c._id,
                name: `${c.prenom} ${c.nom}`,
                role: c.jobtitle || 'Candidat',
                localisation: c.localisation || 'Non spécifiée',
                competences: (c.skills || []).map(s => typeof s === 'string' ? s : s.name),
                status: 'Nouveau',
                matchScore: matchScore,
                matchingAnalysis: matchingAnalysis,
                recommendation: recommendation,
                matchedSkills: existingMatch ? (existingMatch.matchedSkills || []) : [],
                missingSkills: existingMatch ? (existingMatch.missingSkills || []) : [],
                matchStatus: matchStatus,
                initials: `${c.prenom[0] || '?'}${c.nom[0] || '?'}`.toUpperCase()
            })
        }

        res.json(formattedCandidates)
    } catch (err) {
        res.status(500).json({ error: err.message })
    }
}

// Get all offers and generate/fetch matching score for the logged-in candidate
const getMatchingOffersForCandidate = async (req, res) => {
    try {
        const candidateId = req.userId;
        const candidate = await User.findById(candidateId).lean();
        if (!candidate) return res.status(404).json({ error: 'Candidate not found' });

        let allOffers = [];
        try {
            const offerRes = await axios.get('http://127.0.0.1:5003/api/offers', { timeout: 5000 });
            allOffers = offerRes.data;
        } catch (err) {
            console.error('Error fetching offers from offer-service:', err.message);
            return res.status(502).json({ error: 'Could not reach offer service' });
        }

        if (!allOffers || allOffers.length === 0) {
            return res.json([]);
        }

        const candidateSkills = (candidate.skills || []).map(s => (typeof s === 'string' ? s : s.name).toLowerCase());

        let cvText = '';
        if (candidate.cv_path) {
            try {
                const fs = require('fs');
                const { extractText } = require('../services/extractor');
                if (fs.existsSync(candidate.cv_path)) {
                    const fileBuffer = fs.readFileSync(candidate.cv_path);
                    const extracted = await extractText(fileBuffer, candidate.cv_path);
                    if (extracted && extracted.trim()) cvText = extracted;
                }
            } catch (_) { }
        }
        if (!cvText) {
            cvText = `Job Title: ${candidate.jobtitle || 'N/A'}\nBio: ${candidate.bio || 'N/A'}\nSkills: ${candidateSkills.join(', ')}`;
        }

        let needsBackgroundMatch = false;

        // Process all offers IN PARALLEL for speed
        const formattedOffers = await Promise.all(allOffers.map(async (offer) => {
            const jobDescriptionText = `Title: ${offer.title}\nDescription: ${offer.description}\nRequirements: ${(offer.requirements || []).join(', ')}`;
            const requirements = (offer.requirements || []).map(r => r.toLowerCase());
            let matchCount = 0;
            if (requirements.length > 0) {
                matchCount = requirements.filter(reqSkill =>
                    candidateSkills.some(candSkill => candSkill.includes(reqSkill) || reqSkill.includes(candSkill))
                ).length;
            }
            const totalSkills = requirements.length || 1;

            const isTitleMatch = candidate.jobtitle && (offer.title || '').toLowerCase() === candidate.jobtitle.toLowerCase();
            if (!isTitleMatch && matchCount < 3) {
                return null; // Skip this offer entirely
            }

            let matchScore = 0;
            let matchingAnalysis = '';
            let recommendation = '';
            let matchStatus = 'COMPLETED'; // Default to COMPLETED if already in DB

            // 1. Check Cache
            const existingMatch = await Match.findOne({ candidateId: candidate._id, offerId: offer._id });

            if (existingMatch) {
                matchScore = existingMatch.score;
                matchingAnalysis = existingMatch.analysis;
                recommendation = existingMatch.recommendation;
                matchStatus = existingMatch.status;

                // Check if the match is STALE (Offer OR Candidate was updated after the match was created/last updated)
                // Use a 2-second buffer to handle millisecond rounding between different servers/DBs
                const BUFFER_MS = 2000;
                const offerDate = new Date(offer.updatedAt || offer.date || 0);
                const candidateDate = new Date(candidate.updatedAt || 0);
                const matchDate = new Date(existingMatch.updatedAt || 0);

                const isOfferStale = offerDate.getTime() > matchDate.getTime() + BUFFER_MS;
                const isCandidateStale = candidateDate.getTime() > matchDate.getTime() + BUFFER_MS;

                // SPECIAL: Quality Check - If the analysis is just a short list (lots of commas, few words), mark as stale to get the new paragraph version
                const isPoorQuality = existingMatch.status === 'COMPLETED' &&
                    (existingMatch.analysis || "").includes(',') &&
                    (existingMatch.analysis || "").length < 150;

                if (existingMatch.status === 'COMPLETED' && (isOfferStale || isCandidateStale || isPoorQuality)) {
                    needsBackgroundMatch = true;
                    matchScore = 0; // Trigger Analyzing UI
                    matchStatus = 'ANALYSING';

                    if (isPoorQuality && !isOfferStale && !isCandidateStale) {
                        matchingAnalysis = "Amélioration de la qualité de l'analyse (passage au format paragraphe)...";
                        console.log(`[API] Quality-based refresh triggered for ${candidate.prenom} -> ${offer.title}`);
                    } else {
                        matchingAnalysis = isOfferStale
                            ? "Mise à jour de l'analyse (l'offre a été modifiée)..."
                            : "Mise à jour de l'analyse (votre profil a été modifié)...";
                        console.log(`[API] Stale match detected (Buffered) for ${candidate.prenom} -> ${offer.title}`);
                    }
                } else if (existingMatch.status === 'ANALYSING') {
                    // Re-trigger background match if it was stuck in ANALYSING status (e.g. after server restart)
                    needsBackgroundMatch = true;
                    console.log(`[API] Resuming stalled analysis for ${candidate.prenom} -> ${offer.title}`);
                }

                // Update match count in cache if it was 0
                if (existingMatch.totalSkills === 0) {
                    await Match.updateOne({ _id: existingMatch._id }, { matchingSkills: matchCount, totalSkills: totalSkills });
                } else {
                    matchCount = existingMatch.matchingSkills;
                }
            } else {
                // No match exists yet. Use keyword fallback and mark as ANALYSING.
                // The background matcher (triggered on login/update) will eventually provide AI insights.
                matchScore = Math.round((matchCount / totalSkills) * 100);
                matchingAnalysis = "L'IA analyse votre profil pour trouver la meilleure correspondance...";
                recommendation = "Analyse en cours...";

                // Save initial match state to Cache using upsert to avoid duplicate key errors
                const initialStatus = 'ANALYSING';
                await Match.findOneAndUpdate(
                    { candidateId: candidate._id, offerId: offer._id },
                    {
                        $setOnInsert: {
                            score: matchScore,
                            matchingSkills: matchCount,
                            totalSkills: totalSkills,
                            analysis: matchingAnalysis,
                            recommendation: recommendation,
                            status: initialStatus
                        }
                    },
                    { upsert: true, returnDocument: 'after' }
                ).catch(e => console.error('Cache save error:', e.message));

                needsBackgroundMatch = true;

                return {
                    _id: offer._id,
                    title: offer.title,
                    company: offer.company,
                    location: offer.location,
                    recruiterId: offer.recruiter || null,
                    type: offer.type,
                    salary: offer.salary,
                    description: offer.description,
                    compatibilityPercent: matchScore,
                    matchingSkills: matchCount,
                    totalSkills: totalSkills,
                    matchingAnalysis,
                    recommendation,
                    matchedSkills: [],
                    missingSkills: [],
                    status: initialStatus
                };
            }

            return {
                _id: offer._id,
                title: offer.title,
                company: offer.company,
                location: offer.location,
                recruiterId: offer.recruiter || null,
                type: offer.type,
                salary: offer.salary,
                description: offer.description,
                compatibilityPercent: matchScore,
                matchingSkills: matchCount,
                totalSkills: totalSkills,
                matchingAnalysis,
                recommendation,
                matchedSkills: existingMatch ? (existingMatch.matchedSkills || []) : [],
                missingSkills: existingMatch ? (existingMatch.missingSkills || []) : [],
                status: matchStatus || (existingMatch ? (existingMatch.status || 'COMPLETED') : 'COMPLETED')
            };
        }));

        // Fire the background match ONCE if any new offers need analysis
        if (needsBackgroundMatch) {
            try {
                const { runBackgroundMatchForCandidate } = require('../services/background-matcher');
                runBackgroundMatchForCandidate(candidate._id).catch(e => console.error('BG Match trigger error:', e));
            } catch (e) {
                console.error('Failed to require background-matcher:', e);
            }
        }

        res.json(formattedOffers.filter(Boolean));

    } catch (err) {
        console.error('getMatchingOffersForCandidate error:', err.message);
        res.status(500).json({ error: err.message });
    }
}

// Get candidates grouped by offer for the recruiter
const getMatchingCandidatesGroupedByOffer = async (req, res) => {
    try {
        const recruiterId = req.userId;

        // 1. Fetch all offers for this recruiter from offer-service
        let recruiterOffers = [];
        try {
            const offerRes = await axios.get('http://127.0.0.1:5003/api/offers', { timeout: 5000 });
            recruiterOffers = offerRes.data.filter(o => o.recruiter && o.recruiter.toString() === recruiterId.toString());
        } catch (err) {
            console.error('Error fetching recruiter offers from offer-service:', err.message);
            return res.status(502).json({ error: 'Could not reach offer service' });
        }

        if (!recruiterOffers || recruiterOffers.length === 0) {
            return res.json([]);
        }

        const groupedResult = [];

        // 2. For each offer, find matching candidates
        for (const offer of recruiterOffers) {
            // Find all matches for this offer in the Match collection
            let matches = await Match.find({ offerId: offer._id })
                .sort({ score: -1 })
                .limit(10)
                .lean();

            // Use Keyword Fallback instantly if no match exists, and trigger AI in the background.
            // OR trigger if the existing matches are STALE
            let isStale = false;
            if (matches.length > 0) {
                const offerDate = new Date(offer.updatedAt || offer.date || 0);
                const latestMatchDate = new Date(Math.max(...matches.map(m => new Date(m.updatedAt || 0).getTime())));
                if (offerDate > latestMatchDate) {
                    isStale = true;
                }
            }

            if (matches.length === 0 || isStale) {
                const candidates = await User.find({ role: 'candidat' });
                const { runBackgroundMatchForCandidate } = require('../services/background-matcher');

                let triggerBackgroundArray = [];

                for (const c of candidates) {
                    const candidateSkillNames = (c.skills || []).map(s => (typeof s === 'string' ? s : s.name).toLowerCase());
                    const offerRequirements = (offer.requirements || []).map(r => r.toLowerCase());

                    let matchCount = 0;
                    if (offerRequirements.length > 0) {
                        matchCount = offerRequirements.filter(reqSkill =>
                            candidateSkillNames.some(candSkill => candSkill.includes(reqSkill) || reqSkill.includes(candSkill))
                        ).length;
                    }
                    const isTitleMatch = c.jobtitle && (offer.title || '').toLowerCase() === c.jobtitle.toLowerCase();

                    if (!isTitleMatch && matchCount < 3) {
                        continue; // Skip this candidate entirely
                    }

                    let fallbackScore = 0; // 0 triggers AI Analyzing UI
                    const fallbackAnalysis = "L'IA analyse le profil pour trouver la meilleure correspondance...";
                    const fallbackRec = "Analyse IA en cours...";
                    const fallbackStatus = 'ANALYSING';

                    // Use update logic that handles both new entries AND stale entries
                    const updatePayload = {
                        $set: {
                            score: fallbackScore,
                            analysis: fallbackAnalysis,
                            recommendation: fallbackRec,
                            status: fallbackStatus
                        }
                    };

                    const newMatch = await Match.findOneAndUpdate(
                        { candidateId: c._id, offerId: offer._id },
                        updatePayload,
                        { upsert: true, returnDocument: 'after' }
                    );

                    matches.push({
                        candidateId: c._id,
                        score: fallbackScore,
                        analysis: fallbackAnalysis,
                        recommendation: fallbackRec,
                        status: fallbackStatus
                    });

                    triggerBackgroundArray.push(c._id);
                }

                matches.sort((a, b) => b.score - a.score);

                // If candidates were missing scores, trigger full recalculation for those candidates in background
                if (triggerBackgroundArray.length > 0) {
                    console.log(`[API] Triggering AI background matched for ${triggerBackgroundArray.length} candidates...`);
                    for (const cid of triggerBackgroundArray) {
                        try {
                            const { runBackgroundMatchForCandidate } = require('../services/background-matcher');
                            runBackgroundMatchForCandidate(cid).catch(e => console.error(e));
                        } catch (e) {
                            console.error("Could not run background matcher", e);
                        }
                    }
                }
            }

            const candidateDetails = [];

            const { runBackgroundMatchForCandidate } = require('../services/background-matcher');

            for (const match of matches) {
                const candidate = await User.findById(match.candidateId).select('prenom nom jobtitle sector localisation skills bio updatedAt').lean();
                if (candidate) {
                    let currentStatus = match.status || 'COMPLETED';
                    let currentScore = match.score;
                    let currentAnalysis = match.analysis;
                    let currentRecommendation = match.recommendation;

                    // SMART CACHING: Check if individual match is stale
                    // Use a 2-second buffer to handle millisecond rounding between different servers/DBs
                    const BUFFER_MS = 2000;
                    const offerDate = new Date(offer.updatedAt || offer.date || 0);
                    const candidateDate = new Date(candidate.updatedAt || 0);
                    const matchDate = new Date(match.updatedAt || 0);

                    const isOfferStale = offerDate.getTime() > matchDate.getTime() + BUFFER_MS;
                    const isCandidateStale = candidateDate.getTime() > matchDate.getTime() + BUFFER_MS;

                    // QUALITY CHECK: If the analysis is just a short list, mark as stale to refresh quality
                    const isPoorQuality = currentStatus === 'COMPLETED' &&
                        (currentAnalysis || "").includes(',') &&
                        (currentAnalysis || "").length < 150;

                    if (currentStatus === 'COMPLETED' && (isOfferStale || isCandidateStale || isPoorQuality)) {
                        console.log(`[API] Stale/Poor Quality match detected for ${candidate.prenom}. Resetting...`);
                        currentStatus = 'ANALYSING';
                        currentScore = 0;
                        currentAnalysis = isPoorQuality && !isOfferStale && !isCandidateStale
                            ? "Amélioration de la qualité de l'analyse (passage au format paragraphe)..."
                            : "Mise à jour de l'analyse en cours...";
                        currentRecommendation = "Analyse en cours...";
                    }

                    // IF the score is not yet COMPLETED, trigger a real AI analysis in the background
                    if (currentStatus !== 'COMPLETED') {
                        console.log(`[API] Triggering required AI update for ${candidate.prenom} (Status: ${currentStatus})...`);
                        runBackgroundMatchForCandidate(candidate._id).catch(e => console.error(e));
                    }

                    candidateDetails.push({
                        _id: candidate._id,
                        name: `${candidate.prenom} ${candidate.nom}`,
                        role: candidate.jobtitle || 'Candidat',
                        location: candidate.localisation || 'Non spécifiée',
                        experience: 'Nouveau diplômé',
                        skills: (candidate.skills || []).map(s => typeof s === 'string' ? s : s.name),
                        status: 'Nouveau',
                        matchScore: currentScore,
                        matchingAnalysis: currentAnalysis,
                        recommendation: currentRecommendation,
                        initials: `${candidate.prenom[0] || '?'}${candidate.nom[0] || '?'}`.toUpperCase(),
                        isSaved: false // Placeholder
                    });
                }
            }

            groupedResult.push({
                offer: {
                    _id: offer._id,
                    title: offer.title,
                    company: offer.company,
                    location: offer.location,
                    type: offer.type
                },
                candidates: candidateDetails
            });
        }

        res.json(groupedResult);

    } catch (err) {
        console.error('getMatchingCandidatesGroupedByOffer error:', err.message);
        res.status(500).json({ error: err.message });
    }
}

// Trigger background match for a specific offer (when job is updated)
const reMatchOffer = async (req, res) => {
    try {
        const { id } = req.params;
        const offerData = req.body; // Optional offer data from the update body

        console.log(`[API] Triggering re-match for Offer ID: ${id}`);
        // Clear cached matches so the next dashboard view triggers a recalculation
        await Match.deleteMany({ offerId: id }).catch(e => console.error("Error clearing old matches:", e.message));

        const { runBackgroundMatchForOffer } = require('../services/background-matcher');
        // This is async but we don't await because it goes to the background queue
        runBackgroundMatchForOffer(id, offerData).catch(e => console.error("Error triggering offer re-match:", e));

        res.json({ message: "Re-matching triggered in background" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

// ============== NOTIFICATIONS AND APPLICATIONS =====================

const Application = require('../models/application');
const Notification = require('../models/notification');

// Postuler (Apply to an offer)
const applyToOffer = async (req, res) => {
    try {
        const { offerId, recruiterId, offerTitle } = req.body;
        const candidateId = req.userId;

        if (!offerId || !recruiterId) return res.status(400).json({ error: 'Missing parameters' });

        const candidate = await User.findById(candidateId).lean();

        // Save application locally
        await Application.findOneAndUpdate(
            { candidateId, offerId },
            { $setOnInsert: { candidateId, offerId, recruiterId, status: 'PENDING' } },
            { upsert: true }
        );

        // Notify Recruiter Service
        try {
            await axios.post('http://127.0.0.1:5002/recruiter/internal/notify', {
                recruiterId: recruiterId,
                senderId: candidateId,
                senderName: `${candidate.prenom} ${candidate.nom}`,
                senderEmail: candidate.email,
                message: `Le candidat ${candidate.prenom} ${candidate.nom} a postulé à l'offre: ${offerTitle || "N/A"}`,
                type: 'APPLICATION'
            });
        } catch (e) {
            console.error('Failed to notify recruiter:', e.message);
        }

        res.json({ message: 'Application envoyée avec succès' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// Internal endpoint to receive notification
const receiveNotification = async (req, res) => {
    try {
        const { candidateId, senderId, senderName, senderEmail, message, type } = req.body;
        const notif = new Notification({
            userId: candidateId,
            senderId,
            senderName,
            senderEmail,
            message,
            type
        });
        await notif.save();
        res.json({ message: 'Notification received' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// Get notifications
const getNotifications = async (req, res) => {
    try {
        const notifs = await Notification.find({ userId: req.userId }).sort({ createdAt: -1 }).limit(20);
        res.json(notifs);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// Mark notification as read
const markNotificationRead = async (req, res) => {
    try {
        await Notification.findByIdAndUpdate(req.params.id, { read: true });
        res.json({ message: 'Read' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

module.exports = {
    register, login, getProfile, updateProfile, getRecentCandidatesBySector,
    getMatchingOffersForCandidate, getMatchingCandidatesGroupedByOffer, reMatchOffer,
    applyToOffer, receiveNotification, getNotifications, markNotificationRead
};