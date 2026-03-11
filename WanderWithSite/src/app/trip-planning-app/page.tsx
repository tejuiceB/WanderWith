import { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import Footer from "@/components/Footer";
import { CheckCircle2, XCircle, Map, Users, MessageSquare } from "lucide-react";

export const metadata: Metadata = {
    title: "Best Trip Planning App (2025) | Goodbye Google Docs",
    description: "Looking for the best trip planning app? Organize your family vacations and group trips without messy Google Docs. Chat, budget, and map itineraries in one place.",
    keywords: ["trip planning app", "best trip planning app", "travel planner tool", "group trip organization app", "alternative to google docs for travel", "vacation planner"],
    alternates: {
        canonical: "https://www.wanderwith.online/trip-planning-app",
    },
};

// Schema.org structured data for SEO
const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
        {
            "@type": "SoftwareApplication",
            name: "WanderWith - Trip Planning App",
            applicationCategory: "TravelApplication",
            operatingSystem: "Android",
            offers: {
                "@type": "Offer",
                price: "0",
                priceCurrency: "USD",
            },
            description: "The ultimate trip planning app for groups and solo travelers. Say goodbye to massive Google Docs and messy chats.",
            url: "https://www.wanderwith.online/trip-planning-app",
        },
        {
            "@type": "BreadcrumbList",
            itemListElement: [
                { "@type": "ListItem", position: 1, name: "Home", item: "https://www.wanderwith.online" },
                { "@type": "ListItem", position: 2, name: "Trip Planning App", item: "https://www.wanderwith.online/trip-planning-app" },
            ],
        },
    ],
};

export default function TripPlanningAppPage() {
    return (
        <>
            <main className="min-h-screen bg-white">
                <script
                    type="application/ld+json"
                    dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
                />

                {/* Hero Section */}
                <section className="pt-32 pb-20 bg-gradient-to-br from-[#F7F3EC] via-white to-[#F7F3EC] relative overflow-hidden">
                    <div className="absolute inset-0 opacity-40">
                        <div className="absolute top-20 left-10 w-96 h-96 bg-brand-accent/20 rounded-full blur-3xl" />
                        <div className="absolute bottom-20 right-10 w-96 h-96 bg-blue-500/20 rounded-full blur-3xl" />
                    </div>

                    <div className="container mx-auto px-6 relative z-10">
                        <div className="max-w-4xl mx-auto text-center">
                            <span className="inline-block px-4 py-2 bg-brand-primary/5 rounded-full text-brand-primary font-semibold text-sm mb-6 tracking-wide border border-brand-primary/10">
                                🏆 Rated Top Trip Planning App
                            </span>
                            <h1 className="text-5xl md:text-6xl lg:text-[5rem] font-bold text-brand-primary mb-8 font-serif leading-[1.05] tracking-tight">
                                Organizing a trip shouldn't require a massive Google Doc.
                            </h1>
                            <p className="text-xl md:text-2xl text-gray-600 mb-10 leading-relaxed font-light">
                                Stop juggling chaotic group chats and clunky spreadsheets. WanderWith is the all-in-one trip planning app you actually want to use.
                            </p>

                            <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
                                <a
                                    href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="px-8 py-4 bg-brand-primary text-white rounded-full font-bold hover:bg-brand-accent transition-all flex items-center gap-3 text-lg shadow-xl hover:-translate-y-1"
                                >
                                    <Image
                                        src="/assets/icons8-google-play-store-100.png"
                                        alt="Play Store"
                                        width={24}
                                        height={24}
                                        className="brightness-0 invert"
                                    />
                                    Get the App Free
                                </a>
                            </div>
                        </div>
                    </div>
                </section>

                {/* The "Google Doc Problem" Section */}
                <section className="py-20 md:py-32">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <div className="text-center mb-16">
                            <h2 className="text-3xl md:text-5xl font-bold text-gray-900 font-serif mb-6">
                                The Old Way vs. The WanderWith Way
                            </h2>
                            <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                                Planning a family vacation or a trip with friends is frustrating when multiple people are involved. Here is how we fix it.
                            </p>
                        </div>

                        <div className="grid md:grid-cols-2 gap-8 md:gap-16">
                            {/* The Google Doc Way */}
                            <div className="bg-red-50 p-8 md:p-10 rounded-3xl border border-red-100">
                                <div className="flex items-center gap-3 mb-6">
                                    <XCircle className="w-8 h-8 text-red-500" />
                                    <h3 className="text-2xl font-bold text-red-900">Spreadsheets & Docs</h3>
                                </div>
                                <ul className="space-y-4">
                                    <li className="flex items-start gap-3">
                                        <XCircle className="w-5 h-5 text-red-400 shrink-0 mt-0.5" />
                                        <span className="text-red-900/80">Endless text fields and messy unformatted rows.</span>
                                    </li>
                                    <li className="flex items-start gap-3">
                                        <XCircle className="w-5 h-5 text-red-400 shrink-0 mt-0.5" />
                                        <span className="text-red-900/80">Can't easily visualize dates or a true day-by-day itinerary.</span>
                                    </li>
                                    <li className="flex items-start gap-3">
                                        <XCircle className="w-5 h-5 text-red-400 shrink-0 mt-0.5" />
                                        <span className="text-red-900/80">Group chats are in WhatsApp, links are in texts, plans are in a doc. Total chaos.</span>
                                    </li>
                                    <li className="flex items-start gap-3">
                                        <XCircle className="w-5 h-5 text-red-400 shrink-0 mt-0.5" />
                                        <span className="text-red-900/80">Clunky on mobile phones while you are actually traveling.</span>
                                    </li>
                                </ul>
                            </div>

                            {/* The WanderWith Way */}
                            <div className="bg-emerald-50 p-8 md:p-10 rounded-3xl border border-emerald-100 relative shadow-lg">
                                <div className="absolute -top-4 -right-4 bg-brand-accent text-white text-xs font-bold px-3 py-1 rounded-full uppercase tracking-wider shadow-md">
                                    The Solution
                                </div>
                                <div className="flex items-center gap-3 mb-6">
                                    <CheckCircle2 className="w-8 h-8 text-emerald-600" />
                                    <h3 className="text-2xl font-bold text-emerald-900">Trip Planning App</h3>
                                </div>
                                <ul className="space-y-5">
                                    <li className="flex items-start gap-3">
                                        <CheckCircle2 className="w-5 h-5 text-emerald-500 shrink-0 mt-0.5" />
                                        <span className="text-emerald-900/90 font-medium">Beautiful, drag-and-drop itinerary builder.</span>
                                    </li>
                                    <li className="flex items-start gap-3">
                                        <CheckCircle2 className="w-5 h-5 text-emerald-500 shrink-0 mt-0.5" />
                                        <span className="text-emerald-900/90 font-medium">A dedicated trip chat room explicitly tied to your itinerary.</span>
                                    </li>
                                    <li className="flex items-start gap-3">
                                        <CheckCircle2 className="w-5 h-5 text-emerald-500 shrink-0 mt-0.5" />
                                        <span className="text-emerald-900/90 font-medium">Built-in poll voting for activities & shared expense tracking.</span>
                                    </li>
                                    <li className="flex items-start gap-3">
                                        <CheckCircle2 className="w-5 h-5 text-emerald-500 shrink-0 mt-0.5" />
                                        <span className="text-emerald-900/90 font-medium">Pocket-friendly, blazing fast mobile app exactly when you need it.</span>
                                    </li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </section>

                {/* Feature Deep Dives */}
                <section className="py-20 bg-brand-primary text-white">
                    <div className="container mx-auto px-6 max-w-6xl">
                        <div className="grid md:grid-cols-3 gap-12">
                            <div className="flex flex-col items-center text-center">
                                <div className="w-16 h-16 rounded-2xl bg-white/10 flex items-center justify-center mb-6">
                                    <Map className="w-8 h-8 text-brand-accent" />
                                </div>
                                <h3 className="text-2xl font-bold mb-4">Smart Itineraries</h3>
                                <p className="text-white/70">
                                    Piece it all together. Effortlessly map out places, drag and drop events, and view your entire vacation schedule beautifully.
                                </p>
                            </div>
                            <div className="flex flex-col items-center text-center">
                                <div className="w-16 h-16 rounded-2xl bg-white/10 flex items-center justify-center mb-6">
                                    <Users className="w-8 h-8 text-brand-emerald" />
                                </div>
                                <h3 className="text-2xl font-bold mb-4">Multi-Person Sync</h3>
                                <p className="text-white/70">
                                    No more text chains. Invite family and friends to collaboratively edit the itinerary, add items, and manage budgets in real-time.
                                </p>
                            </div>
                            <div className="flex flex-col items-center text-center">
                                <div className="w-16 h-16 rounded-2xl bg-white/10 flex items-center justify-center mb-6">
                                    <MessageSquare className="w-8 h-8 text-brand-violet" />
                                </div>
                                <h3 className="text-2xl font-bold mb-4">Contextual Chats</h3>
                                <p className="text-white/70">
                                    Every trip has its own dedicated chat room. Share links, discuss restaurants, and make decisions exactly where the trip lives.
                                </p>
                            </div>
                        </div>
                    </div>
                </section>

                {/* Final CTA */}
                <section className="py-24">
                    <div className="container mx-auto px-6 text-center max-w-3xl">
                        <h2 className="text-3xl md:text-5xl font-bold text-gray-900 font-serif mb-6">
                            Ready for a better trip planner?
                        </h2>
                        <p className="text-xl text-gray-600 mb-10">
                            Join thousands of travelers who have already ditched spreadsheets for a cleaner, smarter, and more unified travel experience.
                        </p>
                        <a
                            href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center gap-3 bg-brand-primary text-white px-10 py-5 rounded-full font-bold hover:bg-brand-accent transition-all shadow-xl hover:-translate-y-1 text-lg"
                        >
                            Download WanderWith Now
                        </a>
                    </div>
                </section>
            </main>
            <Footer />
        </>
    );
}
