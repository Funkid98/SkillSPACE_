from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import json
import re
from huggingface_hub import InferenceClient
import uvicorn
import os

app = FastAPI()

# Your Hugging Face Token
HF_TOKEN = "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"

# Using a very reliable and fast model (Llama-3.2-1B-Instruct) 
# which is perfect for structured JSON and very responsive on the API
client = InferenceClient(model="meta-llama/Llama-3.2-1B-Instruct", token=HF_TOKEN)

class MatchRequest(BaseModel):
    cv: str
    job_description: str

def extract_json_robust(text: str):
    try:
        start = text.find('{')
        end = text.rfind('}') + 1
        if start != -1 and end > start:
            return json.loads(text[start:end])
    except:
        pass
    
    # Regex fallback for individual fields
    try:
        score_match = re.search(r'"score"\s*:\s*(\d+)', text)
        analysis_match = re.search(r'"matching_analysis"\s*:\s*"(.*?)"', text, re.DOTALL)
        if score_match:
            return {
                "score": int(score_match.group(1)),
                "matching_analysis": analysis_match.group(1) if analysis_match else "Analyse effectuée.",
                "recommendation": "Check courses on SkillSpace.",
                "matched_skills": [],
                "missing_skills": []
            }
    except:
        pass
    return None

@app.post("/match")
async def match_cv(request: MatchRequest):
    try:
        sys_prompt = (
            "Tu es un expert en recrutement. Analyse ce CV par rapport au poste.\n"
            "Réponds UNIQUEMENT en JSON avec ces champs :\n"
            "1. matching_analysis: 2-3 phrases narratives (format: 'Le candidat a une expérience...').\n"
            "2. recommendation: Formations spécifiques.\n"
            "3. score: 0-100.\n"
            "4. matched_skills: [].\n"
            "5. missing_skills: [].\n\n"
            "INTERDIT: Pas de texte en dehors du JSON. Texte en Français."
        )

        user_content = f"CV: {request.cv[:2000]}\nJob: {request.job_description[:800]}"

        # Using InferenceClient is the most reliable way to call HF models
        response = client.chat_completion(
            messages=[
                {"role": "system", "content": sys_prompt},
                {"role": "user", "content": user_content}
            ],
            max_tokens=600,
            temperature=0.1
        )

        generated_text = response.choices[0].message.content
        print(f"--- AI OUTPUT ---\n{generated_text}\n--- END ---")
        
        result = extract_json_robust(generated_text)
        if result:
            result["status"] = "COMPLETED"
            return result
        
        return {"score": 0, "status": "FAILED", "matching_analysis": "Échec de parsing JSON"}

    except Exception as e:
        print("MATCHING ERROR:", str(e))
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8007)
