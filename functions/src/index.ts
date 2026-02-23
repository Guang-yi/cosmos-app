import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const helloWorld = functions.https.onCall(async (data, context) => {
  return { message: "Cosmos backend is alive" };
});

export { chatWithCoach } from "./claude";

import { seedQuotes } from "./seedQuotes";

export const seedInitialQuotes = functions.https.onCall(async (data, context) => {
  await seedQuotes();
  return { success: true, count: 20 };
});
