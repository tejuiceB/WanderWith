import { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import Footer from "@/components/Footer";
import { CheckCircle2, Clock, Globe, Laptop, Smartphone } from "lucide-react";

export const metadata: Metadata = {
    title: "Best TripIt Alternative (2026) | Upgrade to WanderWith",
    description: "Looking for a modern TripIt alternative? WanderWith offers beautiful visual itineraries, group chats, budget tracking, and real collaboration—not just a list of flights.",
    keywords: ["tripit alternative", "apps like tripit", "better than tripit", "trip itinerary app", "modern travel planner"],
    alternates: {
        canonical: "https://www.wanderwith.online/alternatives/tripit",
    },
};

// Schema.org structured data for SEO
const jsonLd = {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    name: "WanderWith - TripIt Alternative",
    applicationCategory: "TravelApplication",
    operatingSystem: "Android",
    offers: {
        "@type": "Offer",
        price: "0",
        priceCurrency: "USD",
    },
    description: "The modern, highly visual alternative to TripIt for managing travel itineraries and group trips.",
    url: "https://www.wanderwith.online/alternatives/tripit",
};

export default function TripItAlternativePage() {
    return (
        <>
            <main className="min-h-screen bg-white">
                <script
                    type="application/ld+json"
                    dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
                />

                {/* Hero Section */}
                <section className="pt-32 pb-20 bg-gradient-to-tr from-gray-50 via-white to-gray-50 relative overflow-hidden text-center">
                    <div className="container mx-auto px-6 relative z-10 max-w-4xl">
                        <span className="inline-block px-4 py-2 bg-brand-primary/5 rounded-full text-brand-primary font-semibold text-sm mb-6 tracking-wide border border-brand-primary/10">
                            Upgrade from TripIt
                        </span>
                        <h1 className="text-4xl md:text-6xl font-bold text-gray-900 mb-8 font-serif leading-[1.1] tracking-tight">
                            More Than Just a Forwarded Email List
                        </h1>
                        <p className="text-xl md:text-2xl text-gray-600 mb-10 leading-relaxed font-light">
                            TripIt is great for aggregating airline emails. But when it comes to visual planning, discovering places, setting budgets, and chatting with friends, you need WanderWith.
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

                {/* Problem vs Solution */}
                <section className="py-20 md:py-32">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <div className="grid md:grid-cols-2 gap-12 items-center">
                            <div>
                                <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif mb-6 leading-tight">
                                    Your itinerary should look like a vacation, not a spreadsheet.
                                </h2>
                                <p className="text-lg text-gray-600 mb-8 leading-relaxed">
                                    Many travelers find older itinerary apps clunky. They feel like text-heavy business tools rather than visual, inspiring canvases for your next huge adventure. WanderWith was built from the ground up for aesthetics and joy.
                                </p>

                                <ul className="space-y-6">
                                    <li className="flex gap-4">
                                        <div className="w-10 h-10 rounded-full bg-brand-primary/10 flex items-center justify-center shrink-0">
                                            <Laptop className="w-5 h-5 text-brand-primary" />
                                        </div>
                                        <div>
                                            <h4 className="text-xl font-bold text-gray-900 mb-1">Visual & Inspiring</h4>
                                            <p className="text-gray-600">Rich images, maps, and beautiful cards replace entirely text-based lists.</p>
                                        </div>
                                    </li>
                                    <li className="flex gap-4">
                                        <div className="w-10 h-10 rounded-full bg-brand-primary/10 flex items-center justify-center shrink-0">
                                            <Globe className="w-5 h-5 text-brand-primary" />
                                        </div>
                                        <div>
                                            <h4 className="text-xl font-bold text-gray-900 mb-1">Explore & Discover</h4>
                                            <p className="text-gray-600">Don't just aggregate bookings. Actively discover nearby attractions, cafes, and landmarks.</p>
                                        </div>
                                    </li>
                                </ul>
                            </div>

                            <div className="bg-gradient-to-br from-brand-primary to-gray-900 p-8 rounded-3xl shadow-2xl text-white relative">
                                <h3 className="text-2xl font-bold mb-6 font-serif">The WanderWith Advantage</h3>
                                <div className="space-y-4">
                                    <div className="flex items-center gap-3 p-4 bg-white/5 rounded-xl border border-white/10">
                                        <CheckCircle2 className="w-6 h-6 text-brand-emerald" />
                                        <span className="font-medium text-lg">Integrated Group Chats</span>
                                    </div>
                                    <div className="flex items-center gap-3 p-4 bg-white/5 rounded-xl border border-white/10">
                                        <CheckCircle2 className="w-6 h-6 text-brand-emerald" />
                                        <span className="font-medium text-lg">Expense Splitting & Budgets</span>
                                    </div>
                                    <div className="flex items-center gap-3 p-4 bg-white/5 rounded-xl border border-white/10">
                                        <CheckCircle2 className="w-6 h-6 text-brand-emerald" />
                                        <span className="font-medium text-lg">Real-Time Syncing</span>
                                    </div>
                                    <div className="flex items-center gap-3 p-4 bg-white/5 rounded-xl border border-white/10">
                                        <CheckCircle2 className="w-6 h-6 text-brand-emerald" />
                                        <span className="font-medium text-lg">Modern UI/UX Design</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </section>

                {/* Final CTA */}
                <section className="py-24 bg-brand-accent text-white">
                    <div className="container mx-auto px-6 text-center max-w-3xl">
                        <h2 className="text-3xl md:text-5xl font-bold text-white font-serif mb-6">
                            Upgrade your trip planning.
                        </h2>
                        <a
                            href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center gap-3 bg-white text-brand-accent px-10 py-5 rounded-full font-bold hover:bg-gray-100 transition-all shadow-xl hover:-translate-y-1 text-lg mt-8"
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
