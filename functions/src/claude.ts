import * as functions from "firebase-functions";
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({
  apiKey: functions.config().anthropic?.api_key || process.env.ANTHROPIC_API_KEY || "",
});

export const chatWithCoach = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be signed in");
  }

  const { messages, systemPrompt } = data;

  const response = await client.messages.create({
    model: "claude-sonnet-4-6-20250514",
    max_tokens: 1024,
    system: systemPrompt || "You are Cosmos, a warm and confident high-performance life coach. You believe deeply in the person you're talking to. Be concise, encouraging, and real — not corporate or overly peppy. Like a mentor who sees their potential.",
    messages,
  });

  const textBlock = response.content.find((block: any) => block.type === "text");
  return { content: textBlock ? (textBlock as any).text : "" };
});
