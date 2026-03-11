import { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import Footer from "@/components/Footer";
import { CheckCircle2, ShieldCheck, Map, Users, MessageSquare } from "lucide-react";

export const metadata: Metadata = {
    title: "Best Wanderlog Alternative (2025) | Switch to WanderWith",
    description: "Looking for a Wanderlog alternative? WanderWith offers better real-time group chat, agency builder tools, and a truly private trip planning experience.",
    keywords: ["wanderlog alternative", "apps like wanderlog", "better than wanderlog", "trip planner app", "group travel planner"],
    alternates: {
        canonical: "https://www.wanderwith.online/alternatives/wanderlog",
    },
};

// Schema.org structured data for SEO
const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
        {
            "@type": "SoftwareApplication",
            name: "WanderWith - Wanderlog Alternative",
            applicationCategory: "TravelApplication",
            operatingSystem: "Android",
            offers: {
                "@type": "Offer",
                price: "0",
                priceCurrency: "USD",
            },
            description: "The premier alternative to Wanderlog for groups, solo travelers, and agencies.",
            url: "https://www.wanderwith.online/alternatives/wanderlog",
        },
        {
            "@type": "BreadcrumbList",
            itemListElement: [
                { "@type": "ListItem", position: 1, name: "Home", item: "https://www.wanderwith.online" },
                { "@type": "ListItem", position: 2, name: "Alternatives", item: "https://www.wanderwith.online/alternatives" },
                { "@type": "ListItem", position: 3, name: "Wanderlog Alternative", item: "https://www.wanderwith.online/alternatives/wanderlog" },
            ],
        },
    ],
};

export default function WanderlogAlternativePage() {
    return (
        <>
            <main className="min-h-screen bg-white">
                <script
                    type="application/ld+json"
                    dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
                />

                {/* Hero Section */}
                <section className="pt-32 pb-20 bg-gradient-to-br from-brand-primary/5 via-white to-brand-accent/5 relative overflow-hidden text-center">
                    <div className="container mx-auto px-6 relative z-10 max-w-4xl">
                        <span className="inline-block px-4 py-2 bg-brand-accent/10 rounded-full text-brand-accent font-semibold text-sm mb-6 tracking-wide border border-brand-accent/20">
                            Wanderlog Alternative
                        </span>
                        <h1 className="text-4xl md:text-6xl font-bold text-gray-900 mb-8 font-serif leading-[1.1] tracking-tight">
                            The Modern Wanderlog Alternative for Seamless Travel
                        </h1>
                        <p className="text-xl md:text-2xl text-gray-600 mb-10 leading-relaxed font-light">
                            Love mapping your trips but want better group collaboration, dedicated trip chats, and a lighter, faster mobile experience?
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
                                Switch to WanderWith
                            </a>
                        </div>
                    </div>
                </section>

                {/* Comparison Section */}
                <section className="py-20 md:py-24">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <div className="text-center mb-16">
                            <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif mb-6">
                                Why Travelers Choose WanderWith Over Wanderlog
                            </h2>
                        </div>

                        <div className="grid md:grid-cols-2 gap-8 lg:gap-12">
                            {/* Feature 1 */}
                            <div className="bg-gray-50 p-8 rounded-3xl border border-gray-100">
                                <div className="w-12 h-12 rounded-xl bg-brand-violet/10 flex items-center justify-center mb-6">
                                    <MessageSquare className="w-6 h-6 text-brand-violet" />
                                </div>
                                <h3 className="text-2xl font-bold text-gray-900 mb-4">Dedicated Trip Chats</h3>
                                <p className="text-gray-600 leading-relaxed">
                                    While Wanderlog is great for mapping, group communication still happens in messy WhatsApp groups. WanderWith integrates a real-time, threaded chat directly into your itinerary, explicitly tied to your trip.
                                </p>
                            </div>

                            {/* Feature 2 */}
                            <div className="bg-gray-50 p-8 rounded-3xl border border-gray-100">
                                <div className="w-12 h-12 rounded-xl bg-brand-emerald/10 flex items-center justify-center mb-6">
                                    <ShieldCheck className="w-6 h-6 text-brand-emerald" />
                                </div>
                                <h3 className="text-2xl font-bold text-gray-900 mb-4">Privacy-First Architecture</h3>
                                <p className="text-gray-600 leading-relaxed">
                                    We believe your vacation data is yours. WanderWith is designed with a privacy-first ethos, giving you a private, walled-garden experience rather than forcing public social network mechanics on your personal trips.
                                </p>
                            </div>

                            {/* Feature 3 */}
                            <div className="bg-gray-50 p-8 rounded-3xl border border-gray-100">
                                <div className="w-12 h-12 rounded-xl bg-brand-accent/10 flex items-center justify-center mb-6">
                                    <Users className="w-6 h-6 text-brand-accent" />
                                </div>
                                <h3 className="text-2xl font-bold text-gray-900 mb-4">True Collaborative Voting</h3>
                                <p className="text-gray-600 leading-relaxed">
                                    Stop arguing over where to eat. WanderWith allows groups to suggest places and run democratic polls directly inside the app, automatically slotting the winner into the daily schedule.
                                </p>
                            </div>

                            {/* Feature 4 */}
                            <div className="bg-gray-50 p-8 rounded-3xl border border-gray-100">
                                <div className="w-12 h-12 rounded-xl bg-brand-primary/5 flex items-center justify-center mb-6">
                                    <Map className="w-6 h-6 text-brand-primary" />
                                </div>
                                <h3 className="text-2xl font-bold text-gray-900 mb-4">Lighter, Faster Mobile App</h3>
                                <p className="text-gray-600 leading-relaxed">
                                    When you are on roaming data in a foreign country, you need speed. WanderWith is optimized for mobile performance, ensuring your itinerary loads blazing fast right from your pocket.
                                </p>
                            </div>
                        </div>
                    </div>
                </section>

                {/* Final CTA */}
                <section className="py-24 bg-gray-900 text-white">
                    <div className="container mx-auto px-6 text-center max-w-3xl">
                        <h2 className="text-3xl md:text-5xl font-bold text-white font-serif mb-6">
                            Make the Switch Today
                        </h2>
                        <p className="text-xl text-gray-300 mb-10">
                            Download WanderWith and experience a trip planner built for the modern traveler.
                        </p>
                        <a
                            href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center gap-3 bg-white text-gray-900 px-10 py-5 rounded-full font-bold hover:bg-gray-100 transition-all shadow-xl hover:-translate-y-1 text-lg"
                        >
                            Get WanderWith Free
                        </a>
                    </div>
                </section>
            </main>
            <Footer />
        </>
    );
}
