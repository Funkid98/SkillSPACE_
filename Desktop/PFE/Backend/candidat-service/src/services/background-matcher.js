const axios = require("axios");
const fs = require("fs");
const User = require("../models/candidat");
const Match = require("../models/match");
const { extractText } = require("./extractor");
const { matchCvWithJob } = require("./ai-service");

const taskQueue = [];
const processingTasks = new Set(); // Track tasks currently being processed to prevent loops
let isProcessing = false;

// Helpers to compute strict snapshots of skills for comparison
const computeCandidateSkillsSnapshot = (skills) => {
  if (!skills || !Array.isArray(skills)) return "[]";
  const normalized = skills.map((s) => {
    if (typeof s === "string") return `${s.toLowerCase()}:33`; // default assumed level
    return `${(s.name || "").toLowerCase()}:${s.percent || 33}`;
  });
  return JSON.stringify(normalized.sort());
};

const computeOfferRequirementsSnapshot = (requirements) => {
  if (!requirements || !Array.isArray(requirements)) return "[]";
  const normalized = requirements.map((r) => r.toLowerCase());
  return JSON.stringify(normalized.sort());
};

/**
 * Adds a candidate-centric match task to the queue (Match 1 candidate against ALL offers)
 */
const runBackgroundMatchForCandidate = async (candidateId) => {
  const taskId = `CANDIDATE_${candidateId.toString()}`;
  const inQueue = taskQueue.some(
    (t) => t.type === "CANDIDATE" && t.id.toString() === candidateId.toString(),
  );

  if (inQueue || processingTasks.has(taskId)) {
    return; // Already queued or being processed
  }

  // We no longer bulk-reset all matches here.
  // The API (getMatchingOffers) or the processing loop will handle state transitions.

  console.log(`[Queue] Added candidate match task for: ${candidateId}`);
  taskQueue.push({ type: "CANDIDATE", id: candidateId });
  processQueue(); // Start processing but don't block
};

/**
 * Adds an offer-centric match task to the queue (Match ALL candidates against 1 offer)
 */
const runBackgroundMatchForOffer = async (offerId, offerData = null) => {
  const taskId = `OFFER_${offerId.toString()}`;
  const inQueue = taskQueue.some(
    (t) => t.type === "OFFER" && t.id.toString() === offerId.toString(),
  );

  if (inQueue || processingTasks.has(taskId)) {
    return;
  }

  console.log(`[Queue] Added offer match task for: ${offerId}`);
  taskQueue.push({ type: "OFFER", id: offerId, data: offerData });
  processQueue();
};

const processQueue = async () => {
  if (isProcessing || taskQueue.length === 0) return;
  isProcessing = true;

  try {
    while (taskQueue.length > 0) {
      const task = taskQueue.shift();
      const taskId = `${task.type}_${task.id.toString()}`;
      processingTasks.add(taskId);

      try {
        if (task.type === "CANDIDATE") {
          await handleCandidateTask(task.id);
        } else if (task.type === "OFFER") {
          await handleOfferTask(task.id, task.data);
        }
      } catch (err) {
        console.error(`[Queue] Global Task error (${task.type}):`, err.message);
      } finally {
        processingTasks.delete(taskId);
      }
    }
  } finally {
    isProcessing = false;
  }
};

const handleCandidateTask = async (candidateId) => {
  console.log(
    `[Background AI Matcher] Processing candidate (${candidateId})...`,
  );
  const candidate = await User.findById(candidateId).lean();
  if (!candidate) return;

  // Fetch all active offers
  let allOffers = [];
  try {
    const res = await axios.get((process.env.INTERNAL_GATEWAY_URL || "http://127.0.0.1:8088") + "/api/offers", {
      timeout: 10000,
    });
    allOffers = res.data;
  } catch (offerErr) {
    console.error(
      "[Background AI Matcher] Could not reach offer-service:",
      offerErr.message,
    );
    return;
  }

  if (!allOffers.length) return;

  const cvText = await getCvText(candidate);

  for (const offer of allOffers) {
    // Pre-filter: Same job title OR at least 3 matching skills
    const candidateSkills = (candidate.skills || []).map((s) =>
      (typeof s === "string" ? s : s.name).toLowerCase(),
    );
    const offerRequirements = (offer.requirements || []).map((r) =>
      r.toLowerCase(),
    );

    let matchCount = 0;
    if (offerRequirements.length > 0) {
      matchCount = offerRequirements.filter((reqSkill) =>
        candidateSkills.some(
          (candSkill) =>
            candSkill.includes(reqSkill) || reqSkill.includes(candSkill),
        ),
      ).length;
    }
    const isTitleMatch =
      candidate.jobtitle &&
      (offer.title || "")
        .toLowerCase()
        .includes(candidate.jobtitle.toLowerCase());

    // Skip if absolutely no chance of matching (threshold aligned with API: 2)
    if (!isTitleMatch && matchCount < 2) {
      // If match was stuck in ANALYSING, finalize it as FAILED or COMPLETED(0) to stop the loop
      await Match.findOneAndUpdate(
        { candidateId: candidate._id, offerId: offer._id, status: "ANALYSING" },
        {
          $set: {
            status: "COMPLETED",
            score: 0,
            analysis:
              "Le profil ne correspond pas assez aux pré-requis de l'offre.",
          },
        },
      );
      continue;
    }

    const existingMatch = await Match.findOne({
      candidateId: candidate._id,
      offerId: offer._id,
    }).lean();

    const currentCandidateSnapshot = computeCandidateSkillsSnapshot(
      candidate.skills,
    );
    const currentOfferSnapshot = computeOfferRequirementsSnapshot(
      offer.requirements,
    );

    if (existingMatch && existingMatch.status === "COMPLETED") {
      const isCandidateSkillsChanged =
        existingMatch.candidateSkillsSnapshot !== currentCandidateSnapshot;
      const isOfferRequirementsChanged =
        existingMatch.offerRequirementsSnapshot !== currentOfferSnapshot;
      const isPoorQuality =
        (existingMatch.analysis || "").includes(",") &&
        (existingMatch.analysis || "").length < 150;

      if (
        !isCandidateSkillsChanged &&
        !isOfferRequirementsChanged &&
        !isPoorQuality
      ) {
        // Skills haven't changed and quality is fine -> Skip analysis
        continue;
      }

      if (
        isPoorQuality &&
        !isCandidateSkillsChanged &&
        !isOfferRequirementsChanged
      ) {
        console.log(
          `[Background AI Matcher] Refreshing low-quality analysis for ${candidate.prenom} -> ${offer.title}`,
        );
      } else if (isOfferRequirementsChanged) {
        console.log(
          `[Background AI Matcher] Offer ${offer.title} skills were modified. Re-analyzing...`,
        );
      } else if (isCandidateSkillsChanged) {
        console.log(
          `[Background AI Matcher] Candidate ${candidate.prenom} updated their skill levels. Re-analyzing...`,
        );
      }
    }
    await processSingleAiMatch(
      candidate,
      offer,
      cvText,
      currentCandidateSnapshot,
      currentOfferSnapshot,
    );
  }
  console.log(`[Background AI Matcher] Finished candidate (${candidateId})`);
};

const handleOfferTask = async (offerId, offerData) => {
  console.log(`[Background AI Matcher] Processing offer (${offerId})...`);

  let offer = offerData;
  if (!offer) {
    try {
      const res = await axios.get(
        `${process.env.INTERNAL_GATEWAY_URL || "http://127.0.0.1:8088"}/api/offers/${offerId}`,
        { timeout: 10000 },
      );
      offer = res.data;
    } catch (err) {
      console.error(
        "[Background AI Matcher] Could not fetch offer details:",
        err.message,
      );
      return;
    }
  }

  const candidates = await User.find({ role: "candidat" }).lean();
  for (const candidate of candidates) {
    // Pre-filter: Same job title OR at least 3 matching skills
    const candidateSkillNames = (candidate.skills || []).map((s) =>
      (typeof s === "string" ? s : s.name).toLowerCase(),
    );
    const offerRequirements = (offer.requirements || []).map((r) =>
      r.toLowerCase(),
    );

    let matchCount = 0;
    if (offerRequirements.length > 0) {
      matchCount = offerRequirements.filter((reqSkill) =>
        candidateSkillNames.some(
          (candSkill) =>
            candSkill.includes(reqSkill) || reqSkill.includes(candSkill),
        ),
      ).length;
    }
    const isTitleMatch =
      candidate.jobtitle &&
      (offer.title || "")
        .toLowerCase()
        .includes(candidate.jobtitle.toLowerCase());

    if (!isTitleMatch && matchCount < 2) {
      await Match.findOneAndUpdate(
        { candidateId: candidate._id, offerId: offer._id, status: "ANALYSING" },
        {
          $set: {
            status: "COMPLETED",
            score: 0,
            analysis:
              "Le profil ne correspond pas assez aux pré-requis de l'offre.",
          },
        },
      );
      continue;
    }

    const existingMatch = await Match.findOne({
      candidateId: candidate._id,
      offerId: offer._id,
    }).lean();

    const currentCandidateSnapshot = computeCandidateSkillsSnapshot(
      candidate.skills,
    );
    const currentOfferSnapshot = computeOfferRequirementsSnapshot(
      offer.requirements,
    );

    if (existingMatch && existingMatch.status === "COMPLETED") {
      const isCandidateSkillsChanged =
        existingMatch.candidateSkillsSnapshot !== currentCandidateSnapshot;
      const isOfferRequirementsChanged =
        existingMatch.offerRequirementsSnapshot !== currentOfferSnapshot;

      if (!isCandidateSkillsChanged && !isOfferRequirementsChanged) {
        continue; // Skip: No skills were added/removed/upgraded
      }
      console.log(
        `[Background AI Matcher] Re-analyzing match due to skill changes: ${candidate.prenom} -> ${offer.title}`,
      );
    }
    const cvText = await getCvText(candidate);
    await processSingleAiMatch(
      candidate,
      offer,
      cvText,
      currentCandidateSnapshot,
      currentOfferSnapshot,
    );
  }
  console.log(`[Background AI Matcher] Finished offer (${offerId})`);
};

const getCvText = async (candidate) => {
  let extractedText = "";
  if (candidate.cv_path && fs.existsSync(candidate.cv_path)) {
    try {
      const fileBuffer = fs.readFileSync(candidate.cv_path);
      const extracted = await extractText(fileBuffer, candidate.cv_path);
      if (extracted && extracted.trim()) extractedText = extracted;
    } catch (e) {
      console.error("[Background AI Matcher] CV extraction error:", e.message);
    }
  }

  // Include skill levels so the AI can factor in proficiency, not just presence
  const cvSkills = (candidate.skills || [])
    .map((s) => {
      if (typeof s === "string") return s;
      const level =
        s.percent >= 80
          ? "Advanced"
          : s.percent >= 40
            ? "Intermediate"
            : "Beginner";
      return `${s.name} (${level})`;
    })
    .join(", ");

  let finalCvText = `Job Title: ${candidate.jobtitle || "N/A"}\nBio: ${candidate.bio || "N/A"}\nExplicit Profile Skills (with level): ${cvSkills}\n`;

  if (extractedText) {
    finalCvText += `\n--- Extracted CV File Content ---\n${extractedText}`;
  }

  return finalCvText;
};

const processSingleAiMatch = async (
  candidate,
  offer,
  cvText,
  currentCandidateSnapshot = "",
  currentOfferSnapshot = "",
) => {
  // Only fetch minimal required data for matching
  const jobDescriptionText = `Title: ${offer.title}\nSkills_Required: ${(offer.requirements || []).join(", ")}`;

  try {
    console.log(
      `[Background AI Matcher] Analyzing: ${candidate.prenom} -> ${offer.title}`,
    );

    // Signature restored to: cvText, jobDescription, candidateSkills
    const aiResData = await matchCvWithJob(
      cvText,
      jobDescriptionText,
      candidate.skills || [],
    );

    if (aiResData && aiResData.status === "COMPLETED") {
      const matchedSkills = aiResData.matched_skills || [];
      const missingSkills = aiResData.missing_skills || [];

      let finalScore = aiResData.score || 0;
      if (finalScore > 100) finalScore = 100;
      if (finalScore < 0) finalScore = 0;

      console.log(
        `[Background AI Matcher] Result: ${finalScore}% for ${offer.title}`,
      );

      await Match.findOneAndUpdate(
        { candidateId: candidate._id, offerId: offer._id },
        {
          $set: {
            score: finalScore,
            matchingSkills: matchedSkills.length,
            totalSkills: (offer.requirements || []).length || 1,
            analysis: aiResData.matching_analysis || "Analyse complétée",
            recommendation: aiResData.recommendation || "",
            matchedSkills: matchedSkills,
            missingSkills: missingSkills,
            candidateSkillsSnapshot: currentCandidateSnapshot,
            offerRequirementsSnapshot: currentOfferSnapshot,
            status: "COMPLETED",
          },
        },
        { upsert: true, returnDocument: "after" },
      );
    }
  } catch (aiErr) {
    console.error(
      `[Background AI Matcher] AI Error for ${offer.title}:`,
      aiErr.message,
    );
    try {
      await Match.findOneAndUpdate(
        { candidateId: candidate._id, offerId: offer._id },
        {
          $set: {
            score: 0,
            status: "FAILED",
            analysis: "Erreur technique lors de l'analyse.",
            recommendation: "",
          },
        },
      );
    } catch (dbErr) {
      console.error(`[Background AI Matcher] DB Error:`, dbErr.message);
    }
  }
};

module.exports = { runBackgroundMatchForCandidate, runBackgroundMatchForOffer };
