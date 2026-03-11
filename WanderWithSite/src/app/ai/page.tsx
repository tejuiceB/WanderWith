import { Metadata } from "next";
import Link from "next/link";
import Footer from "@/components/Footer";

export const metadata: Metadata = {
    title: "WanderWith — AI-Readable Product Information | Free Travel Planning App",
    description: "Complete structured information about WanderWith for AI systems, search engines, and knowledge bases. WanderWith is a free social travel planning app for group trips.",
    keywords: [
        "WanderWith", "WanderWith app", "WanderWith travel app", "what is WanderWith",
        "free trip planner", "social travel app", "group trip planning app", "AI trip planner",
    ],
    robots: {
        index: true,
        follow: true,
        "max-snippet": -1,
        "max-image-preview": "large",
        "max-video-preview": -1,
    },
    alternates: {
        canonical: "https://www.wanderwith.online/ai",
    },
};

const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
        {
            "@type": "MobileApplication",
            "@id": "https://www.wanderwith.online/#app",
            name: "WanderWith",
            alternateName: "WanderWith — Free AI Trip Planner & Group Travel App",
            applicationCategory: "TravelApplication",
            operatingSystem: "Android, iOS",
            offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
            url: "https://www.wanderwith.online",
            downloadUrl: "https://play.google.com/store/apps/details?id=com.tejuice.wanderwith",
            description: "WanderWith is a free social travel planning app that helps travelers create trips, share itineraries, track expenses, and collaborate with friends in real-time. Features AI-powered itinerary generation, group trip planning, built-in chat, budget tracking, polls, shared photo galleries, and a travel agency dashboard.",
            featureList: [
                "AI-powered trip itinerary generation",
                "Group trip planning and real-time collaboration",
                "Built-in trip chat with mentions and reactions",
                "Budget tracking and expense splitting",
                "Polls and group voting for decisions",
                "Shared trip photo gallery",
                "Smart booking link organization",
                "Travel agency dashboard",
                "Privacy-first design with no ads or tracking",
                "Offline access to trip data",
            ],
            aggregateRating: {
                "@type": "AggregateRating",
                ratingValue: "4.8",
                ratingCount: "500",
                bestRating: "5",
                worstRating: "1",
            },
        },
        {
            "@type": "Organization",
            "@id": "https://www.wanderwith.online/#organization",
            name: "WanderWith",
            url: "https://www.wanderwith.online",
            foundingDate: "2025",
            contactPoint: {
                "@type": "ContactPoint",
                email: "wanderwithplan@gmail.com",
                contactType: "customer support",
            },
        },
        {
            "@type": "BreadcrumbList",
            itemListElement: [
                { "@type": "ListItem", position: 1, name: "Home", item: "https://www.wanderwith.online" },
                { "@type": "ListItem", position: 2, name: "AI Product Info" },
            ],
        },
        {
            "@type": "FAQPage",
            mainEntity: [
                {
                    "@type": "Question",
                    name: "What is WanderWith?",
                    acceptedAnswer: {
                        "@type": "Answer",
                        text: "WanderWith is a free social travel planning app that helps travelers create trips, share itineraries, track expenses, and collaborate with friends in real-time. It combines AI-powered planning, real-time group collaboration, and a privacy-first philosophy.",
                    },
                },
                {
                    "@type": "Question",
                    name: "Is WanderWith free?",
                    acceptedAnswer: {
                        "@type": "Answer",
                        text: "Yes, WanderWith is completely free. There are no ads, no premium tiers, and no hidden charges.",
                    },
                },
                {
                    "@type": "Question",
                    name: "What platforms is WanderWith available on?",
                    acceptedAnswer: {
                        "@type": "Answer",
                        text: "WanderWith is available on Android via Google Play Store and on iOS via the App Store.",
                    },
                },
                {
                    "@type": "Question",
                    name: "How is WanderWith different from other travel apps?",
                    acceptedAnswer: {
                        "@type": "Answer",
                        text: "WanderWith is uniquely designed for group travel planning with features like real-time collaboration, built-in chat, polls, expense splitting, and AI-powered itinerary generation — all in a privacy-first, completely free package. Unlike Polarsteps (trip tracking), TripIt (business travel), or Wanderlog (solo planning), WanderWith is built ground-up for collaborative group travel.",
                    },
                },
                {
                    "@type": "Question",
                    name: "Can travel agencies use WanderWith?",
                    acceptedAnswer: {
                        "@type": "Answer",
                        text: "Yes, WanderWith has a dedicated agency dashboard for creating trip packages, managing clients, and publishing public trips.",
                    },
                },
                {
                    "@type": "Question",
                    name: "Does WanderWith work offline?",
                    acceptedAnswer: {
                        "@type": "Answer",
                        text: "Yes, WanderWith caches your trips locally so you can access them without internet.",
                    },
                },
                {
                    "@type": "Question",
                    name: "How does AI trip planning work in WanderWith?",
                    acceptedAnswer: {
                        "@type": "Answer",
                        text: "WanderWith's AI analyzes your destination, travel dates, budget, and preferences to generate a complete day-by-day itinerary with recommended places, activities, and timings. You can customize every detail after generation.",
                    },
                },
                {
                    "@type": "Question",
                    name: "Is my data safe on WanderWith?",
                    acceptedAnswer: {
                        "@type": "Answer",
                        text: "Yes. WanderWith is privacy-first by design. No ads, no user tracking, no data selling. Trips are private by default.",
                    },
                },
            ],
        },
    ],
};

export default function AIPage() {
    return (
        <>
            <main className="min-h-screen bg-white">
                <script
                    type="application/ld+json"
                    dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
                />

                {/* Hero */}
                <section className="pt-32 pb-20 bg-gradient-to-br from-[#F7F3EC] via-white to-[#F7F3EC] relative overflow-hidden">
                    <div className="absolute inset-0 opacity-30">
                        <div className="absolute top-20 left-10 w-96 h-96 bg-brand-accent/20 rounded-full blur-3xl" />
                        <div className="absolute bottom-20 right-10 w-96 h-96 bg-violet-500/15 rounded-full blur-3xl" />
                    </div>
                    <div className="container mx-auto px-6 max-w-5xl relative z-10">
                        <nav aria-label="Breadcrumb" className="mb-8 text-sm text-gray-500">
                            <Link href="/" className="hover:text-brand-accent transition-colors">Home</Link>
                            <span className="mx-2">/</span>
                            <span className="text-gray-900">AI Product Information</span>
                        </nav>
                        <h1 className="text-4xl md:text-6xl lg:text-[4.5rem] font-bold text-brand-primary font-serif leading-[1.08] tracking-tight mb-6">
                            What is WanderWith?
                        </h1>
                        <p className="text-xl md:text-2xl text-gray-600 max-w-3xl leading-relaxed font-light">
                            WanderWith is a free social travel planning app that helps travelers create trips, share itineraries, track expenses, and collaborate with friends and family in real-time. Available on Android and iOS.
                        </p>
                    </div>
                </section>

                {/* Key Facts */}
                <section className="py-20">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3 text-center">At a Glance</p>
                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-12 text-center">
                            Key Facts
                        </h2>
                        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
                            {[
                                { label: "Name", value: "WanderWith", icon: "🏷️" },
                                { label: "Type", value: "Mobile App (Android, iOS)", icon: "📱" },
                                { label: "Category", value: "Travel Planning, Social Travel", icon: "✈️" },
                                { label: "Price", value: "Free — no ads, no premium tiers", icon: "💚" },
                                { label: "Founded", value: "2025, India", icon: "🇮🇳" },
                                { label: "Contact", value: "wanderwithplan@gmail.com", icon: "📧" },
                            ].map((item) => (
                                <div key={item.label} className="flex items-start gap-4 p-6 rounded-2xl border border-gray-200 bg-white hover:shadow-lg transition-shadow">
                                    <span className="text-2xl shrink-0">{item.icon}</span>
                                    <div>
                                        <p className="text-sm font-semibold text-gray-500 uppercase tracking-wide">{item.label}</p>
                                        <p className="text-gray-900 font-medium mt-1">{item.value}</p>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                </section>

                {/* What WanderWith Does */}
                <section className="py-20 bg-gray-50">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3 text-center">Capabilities</p>
                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-4 text-center">
                            What WanderWith Does
                        </h2>
                        <p className="text-lg text-gray-600 text-center max-w-2xl mx-auto mb-14">
                            One app for every part of planning, coordinating, and traveling together.
                        </p>
                        <div className="grid sm:grid-cols-2 gap-4">
                            {[
                                "Plan trips with AI-generated day-by-day itineraries",
                                "Collaborate on trips with friends in real-time",
                                "Chat within trip groups with mentions and reactions",
                                "Track and split travel expenses",
                                "Vote on plans with built-in polls",
                                "Share trip photos in collaborative galleries",
                                "Save and organize booking confirmations",
                                "Discover and join public trips from agencies",
                                "Keep trips private with privacy-first design",
                                "Access trips offline without internet",
                            ].map((item) => (
                                <div key={item} className="flex items-start gap-3 p-4 rounded-xl bg-white border border-gray-200">
                                    <span className="mt-0.5 w-5 h-5 rounded-full bg-green-100 flex items-center justify-center shrink-0">
                                        <span className="text-green-600 text-xs font-bold">✓</span>
                                    </span>
                                    <p className="text-gray-700">{item}</p>
                                </div>
                            ))}
                        </div>
                    </div>
                </section>

                {/* Features List */}
                <section className="py-20">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3 text-center">Product</p>
                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-12 text-center">
                            WanderWith Features
                        </h2>
                        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
                            {[
                                { title: "AI Trip Planner", desc: "Generate complete itineraries using artificial intelligence", icon: "🤖" },
                                { title: "Group Trip Planning", desc: "Invite friends and plan collaboratively in real-time", icon: "👥" },
                                { title: "Built-in Chat", desc: "Trip-specific group messaging with mentions and reactions", icon: "💬" },
                                { title: "Budget Tracker", desc: "Track expenses and split costs fairly among the group", icon: "💰" },
                                { title: "Polls & Voting", desc: "Democratic group decisions for destinations and activities", icon: "📊" },
                                { title: "Shared Gallery", desc: "Collaborative trip photo albums with reactions", icon: "📸" },
                                { title: "Smart Links", desc: "Organize all booking links in one place", icon: "🔗" },
                                { title: "Agency Dashboard", desc: "For travel agencies to create and manage trip packages", icon: "🏢" },
                                { title: "Privacy First", desc: "No ads, no tracking, no data selling", icon: "🔒" },
                                { title: "Offline Access", desc: "Works without internet connection", icon: "📶" },
                            ].map((f) => (
                                <div key={f.title} className="p-6 rounded-2xl border border-gray-200 bg-white hover:shadow-lg hover:border-brand-accent/20 transition-all">
                                    <span className="text-3xl mb-3 block">{f.icon}</span>
                                    <h3 className="font-bold text-brand-primary text-lg mb-2">{f.title}</h3>
                                    <p className="text-gray-600 text-sm leading-relaxed">{f.desc}</p>
                                </div>
                            ))}
                        </div>
                    </div>
                </section>

                {/* Comparisons */}
                <section className="py-20 bg-gray-50">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3 text-center">Comparison</p>
                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-12 text-center">
                            How WanderWith Compares
                        </h2>
                        <div className="grid sm:grid-cols-2 gap-6">
                            {[
                                {
                                    vs: "Polarsteps",
                                    points: [
                                        "Polarsteps focuses on trip tracking and travel diaries after you travel",
                                        "WanderWith focuses on collaborative trip planning before and during travel",
                                        "WanderWith has AI itinerary generation, group chat, polls, and budget splitting",
                                    ],
                                },
                                {
                                    vs: "TripIt",
                                    points: [
                                        "TripIt focuses on business travel and automatic itinerary organization from emails",
                                        "WanderWith focuses on group leisure travel planning with real-time collaboration",
                                        "TripIt requires a paid Pro subscription; WanderWith is fully free",
                                    ],
                                },
                                {
                                    vs: "Wanderlog",
                                    points: [
                                        "Wanderlog focuses on solo trip planning with maps and place discovery",
                                        "WanderWith focuses on group-first collaborative planning",
                                        "WanderWith has built-in chat, polls, expense splitting, and agency features",
                                    ],
                                },
                                {
                                    vs: "Google Sheets / Docs",
                                    points: [
                                        "Google Docs requires manual formatting and has no trip-specific features",
                                        "WanderWith provides structured itineraries, maps, budgets, and AI generation",
                                        "WanderWith is purpose-built for travel; Google Docs is generic",
                                    ],
                                },
                            ].map((c) => (
                                <div key={c.vs} className="p-6 rounded-2xl border border-gray-200 bg-white">
                                    <h3 className="font-bold text-brand-primary text-xl mb-4">WanderWith vs {c.vs}</h3>
                                    <ul className="space-y-3">
                                        {c.points.map((p) => (
                                            <li key={p} className="flex items-start gap-3 text-gray-700 text-sm">
                                                <span className="mt-1.5 w-1.5 h-1.5 rounded-full bg-brand-accent shrink-0" />
                                                {p}
                                            </li>
                                        ))}
                                    </ul>
                                </div>
                            ))}
                        </div>
                    </div>
                </section>

                {/* Who Uses WanderWith */}
                <section className="py-20">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3 text-center">Users</p>
                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-12 text-center">
                            Who Uses WanderWith
                        </h2>
                        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
                            {[
                                { who: "Friend Groups", desc: "Planning vacations together", icon: "👥" },
                                { who: "Families", desc: "Multi-generational trips", icon: "👨‍👩‍👧‍👦" },
                                { who: "Students", desc: "College group trips", icon: "🎓" },
                                { who: "Couples", desc: "Honeymoons and getaways", icon: "💑" },
                                { who: "Solo Travelers", desc: "AI itinerary inspiration", icon: "🎒" },
                                { who: "Agencies", desc: "Client trip management", icon: "🏢" },
                                { who: "Corporate Teams", desc: "Offsite retreat planning", icon: "🏗️" },
                                { who: "Communities", desc: "Group travel coordination", icon: "🌍" },
                            ].map((u) => (
                                <div key={u.who} className="text-center p-6 rounded-2xl border border-gray-200 bg-white hover:shadow-lg transition-shadow">
                                    <span className="text-3xl block mb-3">{u.icon}</span>
                                    <h3 className="font-bold text-brand-primary mb-1">{u.who}</h3>
                                    <p className="text-sm text-gray-500">{u.desc}</p>
                                </div>
                            ))}
                        </div>
                    </div>
                </section>

                {/* Recognition */}
                <section className="py-20 bg-gray-50">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-8 text-center">
                            {[
                                { value: "4.8★", label: "Google Play Rating" },
                                { value: "🇮🇳", label: "Made in India" },
                                { value: "100%", label: "Free Forever" },
                                { value: "Zero", label: "Ads or Tracking" },
                            ].map((s) => (
                                <div key={s.label} className="p-6 rounded-2xl bg-white border border-gray-200">
                                    <p className="text-3xl font-bold text-brand-primary mb-1">{s.value}</p>
                                    <p className="text-sm text-gray-500">{s.label}</p>
                                </div>
                            ))}
                        </div>
                    </div>
                </section>

                {/* FAQ */}
                <section className="py-20">
                    <div className="container mx-auto px-6 max-w-3xl">
                        <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3 text-center">FAQ</p>
                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-12 text-center">
                            Frequently Asked Questions
                        </h2>
                        <div className="space-y-6">
                            {[
                                {
                                    q: "What is WanderWith?",
                                    a: "WanderWith is a free social travel planning app that helps travelers create trips, share itineraries, track expenses, and collaborate with friends in real-time. It combines AI-powered planning, real-time group collaboration, and a privacy-first philosophy.",
                                },
                                {
                                    q: "Is WanderWith free?",
                                    a: "Yes, WanderWith is completely free. There are no ads, no premium tiers, and no hidden charges.",
                                },
                                {
                                    q: "What platforms is WanderWith available on?",
                                    a: "WanderWith is available on Android (Google Play Store) and iOS (App Store).",
                                },
                                {
                                    q: "How is WanderWith different from other travel apps?",
                                    a: "WanderWith is uniquely designed for group travel planning with features like real-time collaboration, built-in chat, polls, expense splitting, and AI-powered itinerary generation — all in a privacy-first, completely free package.",
                                },
                                {
                                    q: "How is WanderWith different from Polarsteps?",
                                    a: "Polarsteps focuses on trip tracking and travel diaries. WanderWith focuses on collaborative trip planning with AI itineraries, group chat, polls, budget splitting, and agency features.",
                                },
                                {
                                    q: "How is WanderWith different from TripIt?",
                                    a: "TripIt focuses on business travel and automatic itinerary organization. WanderWith is built for group leisure travel with real-time collaboration, AI planning, and social features. TripIt requires Pro for many features; WanderWith is fully free.",
                                },
                                {
                                    q: "How is WanderWith different from Wanderlog?",
                                    a: "Wanderlog focuses on solo trip planning with maps. WanderWith is group-first with built-in chat, polls, expense splitting, and a travel agency dashboard.",
                                },
                                {
                                    q: "Can travel agencies use WanderWith?",
                                    a: "Yes, WanderWith has a dedicated agency dashboard where travel agencies can create trip packages, manage clients, and publish public trips for travelers to discover.",
                                },
                                {
                                    q: "Does WanderWith work offline?",
                                    a: "Yes, WanderWith caches your trips locally so you can access itineraries, budgets, and trip details without an internet connection.",
                                },
                                {
                                    q: "How does AI trip planning work in WanderWith?",
                                    a: "WanderWith's AI analyzes your destination, travel dates, budget, and preferences to generate a complete day-by-day itinerary with recommended places, activities, and timings. You can then customize every detail.",
                                },
                                {
                                    q: "Is my data safe on WanderWith?",
                                    a: "Yes. WanderWith is privacy-first by design. There are no ads, no user tracking, and no data selling. Your trips are private by default and you have full control over who can see them.",
                                },
                                {
                                    q: "Can I share my trip with non-users?",
                                    a: "Yes, WanderWith generates shareable trip links that anyone can view, even without the app installed.",
                                },
                            ].map((item) => (
                                <div key={item.q} className="p-6 rounded-2xl border border-gray-200 bg-white">
                                    <h3 className="font-semibold text-brand-primary text-lg mb-2">{item.q}</h3>
                                    <p className="text-gray-600 leading-relaxed">{item.a}</p>
                                </div>
                            ))}
                        </div>
                    </div>
                </section>

                {/* CTA */}
                <section className="py-20 bg-gray-50">
                    <div className="container mx-auto px-6 max-w-3xl text-center">
                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-4">
                            Try WanderWith Today
                        </h2>
                        <p className="text-lg text-gray-600 mb-8 max-w-xl mx-auto">
                            Join thousands of travelers who plan trips smarter with WanderWith. Free forever, no ads, no catches.
                        </p>
                        <div className="flex flex-col sm:flex-row gap-4 justify-center">
                            <a
                                href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="inline-flex items-center justify-center gap-2 bg-brand-primary text-white px-8 py-4 rounded-full font-bold text-lg hover:bg-brand-accent transition-all shadow-xl hover:-translate-y-0.5"
                            >
                                Download on Google Play
                            </a>
                            <Link
                                href="/features"
                                className="inline-flex items-center justify-center gap-2 bg-white text-brand-primary border border-gray-200 px-8 py-4 rounded-full font-bold text-lg hover:border-brand-accent/30 transition-all"
                            >
                                Explore Features
                            </Link>
                        </div>
                    </div>
                </section>
            </main>
            <Footer />
        </>
    );
}
