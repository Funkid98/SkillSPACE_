const axios = require('axios');
const fs = require('fs');
const User = require('../models/candidat');
const Match = require('../models/match');
const { extractText } = require('./extractor');
const { matchCvWithJob } = require('./ai-service');

const taskQueue = [];
let isProcessing = false;

/**
 * Adds a candidate-centric match task to the queue (Match 1 candidate against ALL offers)
 */
const runBackgroundMatchForCandidate = async (candidateId) => {
    const exists = taskQueue.some(t => t.type === 'CANDIDATE' && t.id.toString() === candidateId.toString());
    if (exists) {
        console.log(`[Queue] Prevented duplicate candidate match task for: ${candidateId}`);
        return;
    }
    console.log(`[Queue] Added candidate match task for: ${candidateId}`);
    taskQueue.push({ type: 'CANDIDATE', id: candidateId });
    processQueue(); // Start processing but don't block
};

/**
 * Adds an offer-centric match task to the queue (Match ALL candidates against 1 offer)
 */
const runBackgroundMatchForOffer = async (offerId, offerData = null) => {
    const exists = taskQueue.some(t => t.type === 'OFFER' && t.id.toString() === offerId.toString());
    if (exists) {
        console.log(`[Queue] Prevented duplicate offer match task for: ${offerId}`);
        return;
    }
    console.log(`[Queue] Added offer match task for: ${offerId}`);
    taskQueue.push({ type: 'OFFER', id: offerId, data: offerData });
    processQueue();
};

const processQueue = async () => {
    if (isProcessing || taskQueue.length === 0) return;
    isProcessing = true;

    try {
        while (taskQueue.length > 0) {
            const task = taskQueue.shift();
            try {
                if (task.type === 'CANDIDATE') {
                    await handleCandidateTask(task.id);
                } else if (task.type === 'OFFER') {
                    await handleOfferTask(task.id, task.data);
                }
            } catch (err) {
                console.error(`[Queue] Global Task error (${task.type}):`, err.message);
            }
        }
    } finally {
        isProcessing = false;
    }
};

const handleCandidateTask = async (candidateId) => {
    console.log(`[Background AI Matcher] Processing candidate (${candidateId})...`);
    const candidate = await User.findById(candidateId).lean();
    if (!candidate) return;

    // Fetch all active offers
    let allOffers = [];
    try {
        const res = await axios.get('http://127.0.0.1:5003/api/offers', { timeout: 10000 });
        allOffers = res.data;
    } catch (offerErr) {
        console.error('[Background AI Matcher] Could not reach offer-service:', offerErr.message);
        return;
    }

    if (!allOffers.length) return;

    const cvText = await getCvText(candidate);

    for (const offer of allOffers) {
        // Pre-filter: Same job title OR at least 3 matching skills
        const candidateSkills = (candidate.skills || []).map(s => (typeof s === 'string' ? s : s.name).toLowerCase());
        const offerRequirements = (offer.requirements || []).map(r => r.toLowerCase());

        let matchCount = 0;
        if (offerRequirements.length > 0) {
            matchCount = offerRequirements.filter(reqSkill =>
                candidateSkills.some(candSkill => candSkill.includes(reqSkill) || reqSkill.includes(candSkill))
            ).length;
        }
        const isTitleMatch = candidate.jobtitle && (offer.title || '').toLowerCase() === candidate.jobtitle.toLowerCase();

        if (!isTitleMatch && matchCount < 3) {
            continue; // Skip AI matching for this non-relevant offer
        }

        // Skip if already matched
        const existingMatch = await Match.findOne({ candidateId: candidate._id, offerId: offer._id }).lean();
        if (existingMatch && existingMatch.status === 'COMPLETED') {
            // Check if match is stale (Job Offer OR Candidate was updated after the Match was completed)
            // Use a 2-second buffer to prevent millisecond rounding issues
            const BUFFER_MS = 2000;
            const offerDate = new Date(offer.updatedAt || offer.date || 0);
            const candidateDate = new Date(candidate.updatedAt || 0);
            const matchDate = new Date(existingMatch.updatedAt || 0);

            const isOfferStale = offerDate.getTime() > matchDate.getTime() + BUFFER_MS;
            const isCandidateStale = candidateDate.getTime() > matchDate.getTime() + BUFFER_MS;
            const isPoorQuality = (existingMatch.analysis || "").includes(',') && (existingMatch.analysis || "").length < 150;

            if (!isOfferStale && !isCandidateStale && !isPoorQuality) {
                // Match is still up to date and high quality
                continue;
            }

            if (isPoorQuality && !isOfferStale && !isCandidateStale) {
                console.log(`[Background AI Matcher] Refreshing low-quality analysis for ${candidate.prenom} -> ${offer.title}`);
            } else if (isOfferStale) {
                console.log(`[Background AI Matcher] Offer ${offer.title} was updated (after buffer). Re-analyzing...`);
            } else if (isCandidateStale) {
                console.log(`[Background AI Matcher] Candidate ${candidate.prenom} profile was updated (after buffer). Re-analyzing...`);
            }
        }
        await processSingleAiMatch(candidate, offer, cvText);
    }
    console.log(`[Background AI Matcher] Finished candidate (${candidateId})`);
};

const handleOfferTask = async (offerId, offerData) => {
    console.log(`[Background AI Matcher] Processing offer (${offerId})...`);

    let offer = offerData;
    if (!offer) {
        try {
            const res = await axios.get(`http://127.0.0.1:5003/api/offers/${offerId}`, { timeout: 10000 });
            offer = res.data;
        } catch (err) {
            console.error('[Background AI Matcher] Could not fetch offer details:', err.message);
            return;
        }
    }

    const candidates = await User.find({ role: 'candidat' }).lean();
    for (const candidate of candidates) {
        // Pre-filter: Same job title OR at least 3 matching skills
        const candidateSkills = (candidate.skills || []).map(s => (typeof s === 'string' ? s : s.name).toLowerCase());
        const offerRequirements = (offer.requirements || []).map(r => r.toLowerCase());

        let matchCount = 0;
        if (offerRequirements.length > 0) {
            matchCount = offerRequirements.filter(reqSkill =>
                candidateSkills.some(candSkill => candSkill.includes(reqSkill) || reqSkill.includes(candSkill))
            ).length;
        }
        const isTitleMatch = candidate.jobtitle && (offer.title || '').toLowerCase() === candidate.jobtitle.toLowerCase();

        if (!isTitleMatch && matchCount < 3) {
            continue; // Skip AI matching for this non-relevant candidate
        }

        // Skip if already matched
        const existingMatch = await Match.findOne({ candidateId: candidate._id, offerId: offer._id }).lean();

        if (existingMatch && existingMatch.status === 'COMPLETED') {
            // Check if match is stale (Job Offer OR Candidate was updated after the Match was completed)
            const BUFFER_MS = 2000;
            const offerDate = new Date(offer.updatedAt || offer.date || 0);
            const candidateDate = new Date(candidate.updatedAt || 0);
            const matchDate = new Date(existingMatch.updatedAt || 0);

            const isOfferStale = offerDate.getTime() > matchDate.getTime() + BUFFER_MS;
            const isCandidateStale = candidateDate.getTime() > matchDate.getTime() + BUFFER_MS;

            if (!isOfferStale && !isCandidateStale) {
                continue; // Skip: Match is still up to date within buffer
            }
            console.log(`[Background AI Matcher] Re-analyzing stale match (Buffered): ${candidate.prenom} -> ${offer.title}`);
        }
        const cvText = await getCvText(candidate);
        await processSingleAiMatch(candidate, offer, cvText);
    }
    console.log(`[Background AI Matcher] Finished offer (${offerId})`);
};

const getCvText = async (candidate) => {
    let extractedText = '';
    if (candidate.cv_path && fs.existsSync(candidate.cv_path)) {
        try {
            const fileBuffer = fs.readFileSync(candidate.cv_path);
            const extracted = await extractText(fileBuffer, candidate.cv_path);
            if (extracted && extracted.trim()) extractedText = extracted;
        } catch (e) {
            console.error('[Background AI Matcher] CV extraction error:', e.message);
        }
    }

    const cvSkills = (candidate.skills || []).map(s => typeof s === 'string' ? s : s.name).join(', ');
    
    // Always include the database profile data so the AI knows about manually added skills
    let finalCvText = `Job Title: ${candidate.jobtitle || 'N/A'}\nBio: ${candidate.bio || 'N/A'}\nExplicit Profile Skills: ${cvSkills}\n`;
    
    if (extractedText) {
        finalCvText += `\n--- Extracted CV File Content ---\n${extractedText}`;
    }

    return finalCvText;
};

const processSingleAiMatch = async (candidate, offer, cvText) => {

    // EXCLUDE description text to force AI to evaluate ONLY against the explicitly required skills
    const jobDescriptionText = `Title: ${offer.title}\nSkills_Required: ${(offer.requirements || []).join(', ')}`;

    try {
        console.log(`[Background AI Matcher] Querying AI via Groq API for ${candidate.prenom} -> ${offer.title}`);

        const aiResData = await matchCvWithJob(cvText, jobDescriptionText);

        if (aiResData && aiResData.status === 'COMPLETED') {
            const matchedSkills = aiResData.matched_skills || [];
            const missingSkills = aiResData.missing_skills || [];

            // USE THE AI'S HOLISTIC SCORE
            // Instead of manual math (matched/total), we trust the AI's internal assessment
            // but we still keep matchedCount/totalRequirementsCount for metadata display.
            const matchedCount = matchedSkills.length;
            const totalRequirementsCount = (offer.requirements || []).length || 1;

            let finalScore = aiResData.score || 0;
            if (finalScore > 100) finalScore = 100;
            if (finalScore < 0) finalScore = 0;

            console.log(`[Background AI Matcher] Holistic AI Score: ${finalScore}%`);
            console.log(`[Background AI Matcher] AI Analysis: ${aiResData.matching_analysis}`);
            console.log(`[Background AI Matcher] AI Recommendation: ${aiResData.recommendation}`);

            await Match.findOneAndUpdate(
                { candidateId: candidate._id, offerId: offer._id },
                {
                    $set: {
                        score: finalScore,
                        matchingSkills: matchedCount,
                        totalSkills: totalRequirementsCount,
                        analysis: aiResData.matching_analysis || "Analyse complétée par l'IA",
                        recommendation: aiResData.recommendation || "",
                        matchedSkills: matchedSkills,
                        missingSkills: missingSkills,
                        status: 'COMPLETED'
                    }
                },
                { upsert: true, returnDocument: 'after' }
            );
            console.log(`[Background AI Matcher] Logic Corrected result (${finalScore}%) for ${candidate.prenom} -> ${offer.title}`);
        }
    } catch (aiErr) {
        console.error(`[Background AI Matcher] AI Error for ${candidate.prenom} -> ${offer.title}:`, aiErr.message);
        try {
            await Match.findOneAndUpdate(
                { candidateId: candidate._id, offerId: offer._id },
                {
                    $set: {
                        score: 0,
                        status: 'FAILED',
                        analysis: 'Erreur lors de la communication avec l\'IA.',
                        recommendation: ''
                    }
                }
            )
        } catch (dbErr) {
            console.error(`[Background AI Matcher] DB FAILED status update error`, dbErr.message);
        }
    }
};

module.exports = { runBackgroundMatchForCandidate, runBackgroundMatchForOffer };
