import * as admin from "firebase-admin";

const quotes = [
  { personName: "Tom Brady", quote: "I didn't come this far to only come this far.", category: "mindset", personBio: "7x Super Bowl Champion" },
  { personName: "Kobe Bryant", quote: "Everything negative – pressure, challenges – is all an opportunity for me to rise.", category: "resilience", personBio: "5x NBA Champion, Olympic Gold Medalist" },
  { personName: "Serena Williams", quote: "I really think a champion is defined not by their wins but by how they can recover when they fall.", category: "resilience", personBio: "23x Grand Slam Champion" },
  { personName: "Elon Musk", quote: "When something is important enough, you do it even if the odds are not in your favor.", category: "discipline", personBio: "CEO of Tesla & SpaceX" },
  { personName: "Michael Jordan", quote: "I've failed over and over and over again in my life. And that is why I succeed.", category: "mindset", personBio: "6x NBA Champion, 5x MVP" },
  { personName: "Simone Biles", quote: "I'm not the next Usain Bolt or Michael Phelps. I'm the first Simone Biles.", category: "leadership", personBio: "Most Decorated Gymnast in History" },
  { personName: "Steve Jobs", quote: "Your work is going to fill a large part of your life, and the only way to be truly satisfied is to do what you believe is great work.", category: "craft", personBio: "Co-founder of Apple" },
  { personName: "Muhammad Ali", quote: "I hated every minute of training, but I said, 'Don't quit. Suffer now and live the rest of your life as a champion.'", category: "discipline", personBio: "3x World Heavyweight Champion" },
  { personName: "Oprah Winfrey", quote: "The biggest adventure you can take is to live the life of your dreams.", category: "mindset", personBio: "Media Mogul, Philanthropist" },
  { personName: "David Goggins", quote: "You are in danger of living a life so comfortable and soft that you will die without ever realizing your potential.", category: "discipline", personBio: "Ultramarathon Runner, Navy SEAL" },
  { personName: "Marie Curie", quote: "Nothing in life is to be feared, it is only to be understood.", category: "craft", personBio: "2x Nobel Prize Winner" },
  { personName: "Usain Bolt", quote: "I don't think limits.", category: "mindset", personBio: "8x Olympic Gold Medalist" },
  { personName: "Nelson Mandela", quote: "It always seems impossible until it's done.", category: "resilience", personBio: "Former President of South Africa, Nobel Laureate" },
  { personName: "Satya Nadella", quote: "Don't be a know-it-all; be a learn-it-all.", category: "leadership", personBio: "CEO of Microsoft" },
  { personName: "Maya Angelou", quote: "We delight in the beauty of the butterfly, but rarely admit the changes it has gone through to achieve that beauty.", category: "resilience", personBio: "Poet, Civil Rights Activist" },
  { personName: "Phil Knight", quote: "The cowards never started and the weak died along the way. That leaves us.", category: "discipline", personBio: "Co-founder of Nike" },
  { personName: "Brené Brown", quote: "Vulnerability is not winning or losing; it's having the courage to show up and be seen when we have no control over the outcome.", category: "mindset", personBio: "Research Professor, Author" },
  { personName: "Jensen Huang", quote: "I was different. But the different in me made me who I am.", category: "leadership", personBio: "CEO of NVIDIA" },
  { personName: "Billie Jean King", quote: "Pressure is a privilege — it only comes to those who earn it.", category: "mindset", personBio: "39x Grand Slam Champion, Equality Pioneer" },
  { personName: "Marcus Aurelius", quote: "The impediment to action advances action. What stands in the way becomes the way.", category: "resilience", personBio: "Roman Emperor, Stoic Philosopher" },
];

export async function seedQuotes() {
  const db = admin.firestore();
  const batch = db.batch();

  for (const quote of quotes) {
    const ref = db.collection("quotes").doc();
    batch.set(ref, quote);
  }

  await batch.commit();
  console.log(`Seeded ${quotes.length} quotes`);
}
