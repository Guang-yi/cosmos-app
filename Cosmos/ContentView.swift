import SwiftUI

struct Quote {
    let text: String
    let author: String
}

let quotes: [Quote] = [
    Quote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs"),
    Quote(text: "It does not matter how slowly you go as long as you do not stop.", author: "Confucius"),
    Quote(text: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt"),
    Quote(text: "Believe you can and you're halfway there.", author: "Theodore Roosevelt"),
    Quote(text: "The best time to plant a tree was 20 years ago. The second best time is now.", author: "Chinese Proverb"),
    Quote(text: "Your time is limited, don't waste it living someone else's life.", author: "Steve Jobs"),
    Quote(text: "The only impossible journey is the one you never begin.", author: "Tony Robbins"),
    Quote(text: "Success is not final, failure is not fatal: it is the courage to continue that counts.", author: "Winston Churchill"),
    Quote(text: "What you get by achieving your goals is not as important as what you become by achieving your goals.", author: "Zig Ziglar"),
    Quote(text: "The mind is everything. What you think you become.", author: "Buddha"),
    Quote(text: "Strive not to be a success, but rather to be of value.", author: "Albert Einstein"),
    Quote(text: "I have not failed. I've just found 10,000 ways that won't work.", author: "Thomas Edison"),
    Quote(text: "The only limit to our realization of tomorrow is our doubts of today.", author: "Franklin D. Roosevelt"),
    Quote(text: "Do what you can, with what you have, where you are.", author: "Theodore Roosevelt"),
    Quote(text: "Everything you've ever wanted is on the other side of fear.", author: "George Addair"),
    Quote(text: "Hardships often prepare ordinary people for an extraordinary destiny.", author: "C.S. Lewis"),
    Quote(text: "The best revenge is massive success.", author: "Frank Sinatra"),
    Quote(text: "What lies behind us and what lies before us are tiny matters compared to what lies within us.", author: "Ralph Waldo Emerson"),
    Quote(text: "I am not a product of my circumstances. I am a product of my decisions.", author: "Stephen Covey"),
    Quote(text: "Every strike brings me closer to the next home run.", author: "Babe Ruth"),
    Quote(text: "We may encounter many defeats but we must not be defeated.", author: "Maya Angelou"),
    Quote(text: "Whether you think you can or you think you can't, you're right.", author: "Henry Ford"),
    Quote(text: "The greatest glory in living lies not in never falling, but in rising every time we fall.", author: "Nelson Mandela"),
    Quote(text: "In the middle of every difficulty lies opportunity.", author: "Albert Einstein"),
    Quote(text: "If you want to lift yourself up, lift up someone else.", author: "Booker T. Washington"),
    Quote(text: "Whoever is happy will make others happy too.", author: "Anne Frank"),
    Quote(text: "Life is what happens when you're busy making other plans.", author: "John Lennon"),
    Quote(text: "The purpose of our lives is to be happy.", author: "Dalai Lama"),
    Quote(text: "Get busy living or get busy dying.", author: "Stephen King"),
    Quote(text: "You only live once, but if you do it right, once is enough.", author: "Mae West"),
    Quote(text: "If life were predictable it would cease to be life and be without flavor.", author: "Eleanor Roosevelt"),
    Quote(text: "Life is really simple, but we insist on making it complicated.", author: "Confucius"),
    Quote(text: "May you live all the days of your life.", author: "Jonathan Swift"),
    Quote(text: "The unexamined life is not worth living.", author: "Socrates"),
    Quote(text: "Turn your wounds into wisdom.", author: "Oprah Winfrey"),
    Quote(text: "The way to get started is to quit talking and begin doing.", author: "Walt Disney"),
    Quote(text: "Don't let yesterday take up too much of today.", author: "Will Rogers"),
    Quote(text: "You learn more from failure than from success. Don't let it stop you.", author: "Unknown"),
    Quote(text: "It's not whether you get knocked down, it's whether you get up.", author: "Vince Lombardi"),
    Quote(text: "People who are crazy enough to think they can change the world are the ones who do.", author: "Rob Siltanen"),
    Quote(text: "We generate fears while we sit. We overcome them by action.", author: "Dr. Henry Link"),
    Quote(text: "Knowing is not enough; we must apply. Wishing is not enough; we must do.", author: "Johann Wolfgang von Goethe"),
    Quote(text: "The secret of getting ahead is getting started.", author: "Mark Twain"),
    Quote(text: "It is during our darkest moments that we must focus to see the light.", author: "Aristotle"),
    Quote(text: "You are never too old to set another goal or to dream a new dream.", author: "C.S. Lewis"),
    Quote(text: "Only a life lived for others is a life worthwhile.", author: "Albert Einstein"),
    Quote(text: "A person who never made a mistake never tried anything new.", author: "Albert Einstein"),
    Quote(text: "Go confidently in the direction of your dreams. Live the life you've imagined.", author: "Henry David Thoreau"),
    Quote(text: "When you reach the end of your rope, tie a knot in it and hang on.", author: "Franklin D. Roosevelt"),
    Quote(text: "There is nothing impossible to they who will try.", author: "Alexander the Great"),
    Quote(text: "The best way to predict the future is to create it.", author: "Abraham Lincoln"),
    Quote(text: "You miss 100% of the shots you don't take.", author: "Wayne Gretzky"),
    Quote(text: "Act as if what you do makes a difference. It does.", author: "William James"),
    Quote(text: "What we achieve inwardly will change outer reality.", author: "Plutarch"),
    Quote(text: "Happiness is not something ready made. It comes from your own actions.", author: "Dalai Lama"),
    Quote(text: "Limit your 'always' and your 'nevers.'", author: "Amy Poehler"),
    Quote(text: "Nothing is impossible. The word itself says 'I'm possible!'", author: "Audrey Hepburn"),
    Quote(text: "The power of imagination makes us infinite.", author: "John Muir"),
    Quote(text: "Try to be a rainbow in someone's cloud.", author: "Maya Angelou"),
    Quote(text: "There is no substitute for hard work.", author: "Thomas Edison"),
    Quote(text: "Dream big and dare to fail.", author: "Norman Vaughan"),
    Quote(text: "You must be the change you wish to see in the world.", author: "Mahatma Gandhi"),
    Quote(text: "Well done is better than well said.", author: "Benjamin Franklin"),
    Quote(text: "What we think, we become.", author: "Buddha"),
    Quote(text: "All our dreams can come true, if we have the courage to pursue them.", author: "Walt Disney"),
    Quote(text: "If you can dream it, you can do it.", author: "Walt Disney"),
    Quote(text: "The only person you are destined to become is the person you decide to be.", author: "Ralph Waldo Emerson"),
    Quote(text: "Don't be afraid to give up the good to go for the great.", author: "John D. Rockefeller"),
    Quote(text: "I find that the harder I work, the more luck I seem to have.", author: "Thomas Jefferson"),
    Quote(text: "If you are not willing to risk the usual, you will have to settle for the ordinary.", author: "Jim Rohn"),
    Quote(text: "All progress takes place outside the comfort zone.", author: "Michael John Bobak"),
    Quote(text: "Success usually comes to those who are too busy to be looking for it.", author: "Henry David Thoreau"),
    Quote(text: "Don't be distracted by criticism. Remember, the only taste of success some people get is to take a bite out of you.", author: "Zig Ziglar"),
    Quote(text: "Just when the caterpillar thought the world was ending, he turned into a butterfly.", author: "Proverb"),
    Quote(text: "Successful people do what unsuccessful people are not willing to do.", author: "Jim Rohn"),
    Quote(text: "The ones who are crazy enough to think they can change the world are the ones that do.", author: "Steve Jobs"),
    Quote(text: "Do one thing every day that scares you.", author: "Eleanor Roosevelt"),
    Quote(text: "The start is what stops most people.", author: "Don Shula"),
    Quote(text: "A champion is defined not by their wins but by how they can recover when they fall.", author: "Serena Williams"),
    Quote(text: "I didn't get there by wishing for it or hoping for it, but by working for it.", author: "Estée Lauder"),
    Quote(text: "Fall seven times, stand up eight.", author: "Japanese Proverb"),
    Quote(text: "Don't wait. The time will never be just right.", author: "Napoleon Hill"),
    Quote(text: "Everything has beauty, but not everyone sees it.", author: "Confucius"),
    Quote(text: "How wonderful it is that nobody need wait a single moment before starting to improve the world.", author: "Anne Frank"),
    Quote(text: "The only way to achieve the impossible is to believe it is possible.", author: "Charles Kingsleigh"),
    Quote(text: "It always seems impossible until it's done.", author: "Nelson Mandela"),
    Quote(text: "Don't count the days, make the days count.", author: "Muhammad Ali"),
    Quote(text: "If you want something you've never had, you must be willing to do something you've never done.", author: "Thomas Jefferson"),
    Quote(text: "Strength does not come from physical capacity. It comes from an indomitable will.", author: "Mahatma Gandhi"),
    Quote(text: "The difference between ordinary and extraordinary is that little extra.", author: "Jimmy Johnson"),
    Quote(text: "With the new day comes new strength and new thoughts.", author: "Eleanor Roosevelt"),
    Quote(text: "It is never too late to be what you might have been.", author: "George Eliot"),
    Quote(text: "Ever tried. Ever failed. No matter. Try again. Fail again. Fail better.", author: "Samuel Beckett"),
    Quote(text: "Be yourself; everyone else is already taken.", author: "Oscar Wilde"),
    Quote(text: "No one can make you feel inferior without your consent.", author: "Eleanor Roosevelt"),
    Quote(text: "In order to be irreplaceable one must always be different.", author: "Coco Chanel"),
    Quote(text: "Courage is not the absence of fear, but the triumph over it.", author: "Nelson Mandela"),
    Quote(text: "Life shrinks or expands in proportion to one's courage.", author: "Anaïs Nin"),
    Quote(text: "Great things never come from comfort zones.", author: "Ben Francia"),
    Quote(text: "Wake up with determination. Go to bed with satisfaction.", author: "Unknown"),
]

struct ContentView: View {
    @State private var currentIndex = Int.random(in: 0..<100)
    @State private var opacity = 1.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "flame.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse)

                Text("Cosmos")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                VStack(spacing: 16) {
                    Text("\"\(quotes[currentIndex].text)\"")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Text("— \(quotes[currentIndex].author)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                }
                .opacity(opacity)

                Spacer()
                Spacer()

                Text("tap for next")
                    .font(.caption)
                    .foregroundStyle(.gray.opacity(0.5))
                    .padding(.bottom, 32)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.15)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                currentIndex = (currentIndex + 1) % quotes.count
                withAnimation(.easeIn(duration: 0.25)) {
                    opacity = 1
                }
            }
        }
    }
}
