import OpenAI from "openai";
import { getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { onRequest } from "firebase-functions/v2/https";

if (getApps().length === 0) {
  initializeApp();
}

const packSchema = {
  type: "object",
  additionalProperties: false,
  required: ["pack"],
  properties: {
    pack: {
      type: "object",
      additionalProperties: false,
      required: ["dayId", "focusAreas", "generator", "items"],
      properties: {
        dayId: { type: "string" },
        focusAreas: {
          type: "array",
          items: { type: "string" },
        },
        generator: { type: "string" },
        items: {
          type: "array",
          minItems: 8,
          maxItems: 8,
          items: {
            type: "object",
            additionalProperties: false,
            required: ["id", "type", "prompt", "answer", "explanation", "source"],
            properties: {
              id: { type: "string" },
              type: {
                type: "string",
                enum: ["briefing", "concept", "decision", "scenario", "articulation", "review"],
              },
              prompt: { type: "string" },
              answer: { type: ["string", "null"] },
              explanation: { type: ["string", "null"] },
              source: {
                anyOf: [
                  { type: "null" },
                  {
                    type: "object",
                    additionalProperties: false,
                    required: ["title", "publisher", "dateLabel", "url", "snippet"],
                    properties: {
                      title: { type: "string" },
                      publisher: { type: "string" },
                      dateLabel: { type: "string" },
                      url: { type: "string" },
                      snippet: { type: ["string", "null"] },
                    },
                  },
                ],
              },
            },
          },
        },
      },
    },
  },
};

export const generateDailyPack = onRequest(
  {
    cors: true,
    timeoutSeconds: 60,
    secrets: ["OPENAI_API_KEY"],
  },
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).json({ error: "Use POST" });
      return;
    }

    const authHeader = request.get("authorization") || "";
    if (!authHeader.startsWith("Bearer ")) {
      response.status(401).json({ error: "Unauthorized" });
      return;
    }

    let decodedToken;
    try {
      decodedToken = await getAuth().verifyIdToken(authHeader.slice(7));
    } catch {
      response.status(401).json({ error: "Unauthorized" });
      return;
    }

    const model = process.env.OPENAI_MODEL;
    if (!model) {
      response.status(500).json({ error: "OPENAI_MODEL is not configured" });
      return;
    }

    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      response.status(500).json({ error: "OPENAI_API_KEY is not configured" });
      return;
    }

    const client = new OpenAI({ apiKey });

    const body = request.body || {};
    const uid = typeof body.uid === "string" ? body.uid : "";
    const dayId = typeof body.dayId === "string" ? body.dayId : "";
    const focusAreas = Array.isArray(body.focusAreas)
      ? body.focusAreas.filter((item) => typeof item === "string")
      : [];
    const learningProfile = body.learningProfile && typeof body.learningProfile === "object"
      ? body.learningProfile
      : null;

    if (!uid || uid !== decodedToken.uid) {
      response.status(403).json({ error: "Authenticated user does not match uid" });
      return;
    }

    if (!dayId || focusAreas.length === 0) {
      response.status(400).json({ error: "dayId and focusAreas are required" });
      return;
    }

    const aiResponse = await client.responses.create({
      model,
      input: [
        {
          role: "system",
          content:
            "You generate concise AI fluency daily packs for founders and operators. Return only valid structured JSON. Use credible, inspectable source metadata for the two briefing items. Do not invent URLs; use stable publisher/source pages if exact news URLs are unavailable.",
        },
        {
          role: "user",
          content: [
            `Create Sivra's daily pack for ${dayId}.`,
            `Focus areas: ${focusAreas.join(", ")}.`,
            learningProfile ? `Personalization guidance: ${learningProfile.guidance || ""}` : "",
            learningProfile?.weakDrillTypes
              ? `Weak drill types: ${learningProfile.weakDrillTypes.join(", ")}.`
              : "",
            "The pack must have exactly 8 items: 2 sourced briefings, 4 short drills, screen 7 as an articulation exercise, and screen 8 as a review item.",
            "Keep prompts practical and concise. Non-articulation items need answer and explanation. Articulation answer must be null.",
          ].join("\n"),
        },
      ],
      text: {
        format: {
          type: "json_schema",
          name: "sivra_daily_pack",
          schema: packSchema,
          strict: true,
        },
      },
    });

    const outputText = aiResponse.output_text;
    const parsed = JSON.parse(outputText);
    parsed.pack.dayId = dayId;
    parsed.pack.focusAreas = focusAreas;
    parsed.pack.generator = "openai_responses_v1";

    response.json(parsed);
  },
);
