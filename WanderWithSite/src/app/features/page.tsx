import { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import Footer from "@/components/Footer";

export const metadata: Metadata = {
    title: "WanderWith Features — AI Itineraries, Group Planning, Chat, Budget Tracker & More",
    description:
        "Explore every WanderWith feature: AI-powered itinerary generation, real-time group collaboration, built-in chat, budget tracking & expense splitting, polls, shared photo gallery, travel agency dashboard, and offline access. Free on Android & iOS.",
    keywords: [
        "WanderWith features",
        "AI trip planner features",
        "group travel app features",
        "travel budget tracker",
        "trip chat app",
        "collaborative itinerary",
        "travel polls",
        "shared trip photos",
        "travel agency dashboard",
        "offline travel app",
    ],
    alternates: { canonical: "https://www.wanderwith.online/features" },
    openGraph: {
        title: "WanderWith Features — Everything You Need for Group Travel",
        description:
            "AI itineraries, group planning, chat, budget splitting, polls, shared gallery, agency tools & more — all free.",
        url: "https://www.wanderwith.online/features",
        siteName: "WanderWith",
        type: "website",
    },
};

const features = [
    {
        title: "AI-Powered Itinerary Generation",
        tagline: "Your itinerary, built in seconds.",
        desc: "Enter your destination, dates, budget, and vibe. WanderWith's AI generates a complete day-by-day plan with restaurants, attractions, hidden gems, and time allocations. Not a generic list — a real, usable itinerary you'd actually follow.",
        details: [
            "Generates full day-by-day itineraries from just a destination and dates",
            "Understands budget limits, group size, and travel style preferences",
            "Recommends local restaurants, off-the-beaten-path spots, and must-see attractions",
            "Every part of the AI plan is fully editable — swap, add, remove anything",
            "Works for any destination worldwide, from Tokyo to Tulum",
        ],
        bg: "bg-indigo-50",
    },
    {
        title: "Group Trip Planning",
        tagline: "Everyone plans. No one gets left out.",
        desc: "Invite your entire group with a single link. Everyone sees the same itinerary, makes suggestions, and stays in sync. No more \"did you see the updated sheet?\" messages.",
        details: [
            "Invite unlimited friends via shareable link — no app install required to view",
            "Real-time sync so changes appear instantly for every member",
            "Assign organizer and member roles with different permissions",
            "Everyone can add places, notes, and suggestions to the itinerary",
            "Built for friend groups, families, college trips, bachelorette parties, and corporate offsites",
        ],
        bg: "bg-violet-50",
    },
    {
        title: "Built-in Trip Chat",
        tagline: "Trip talk, in the trip. Not in 5 WhatsApp groups.",
        desc: "Every trip gets its own chat thread attached directly to the plan. Discuss restaurants while looking at the itinerary. Share links that stay findable. Stop scrolling through months of unrelated messages.",
        details: [
            "One dedicated chat per trip — no noise from other conversations",
            "@mention specific people to get their attention on decisions",
            "React to messages with emojis for quick consensus",
            "Share photos, booking links, and media directly in context",
            "Trip discussions are always searchable and never lost",
        ],
        bg: "bg-emerald-50",
    },
    {
        title: "Budget Tracking & Expense Splitting",
        tagline: "No more \"I'll Paytm you later\" that never happens.",
        desc: "Add expenses as they happen. WanderWith automatically calculates who owes whom and shows the simplest way to settle up. Set a trip budget and watch your spending in real-time.",
        details: [
            "Log expenses with category, amount, and who paid",
            "Automatic fair splitting between group members",
            "Clear settlement view showing who owes whom",
            "Real-time planned vs actual budget tracking",
            "Multi-currency support for international trips",
        ],
        bg: "bg-amber-50",
    },
    {
        title: "Smart Booking Links",
        tagline: "Every confirmation, one tap away.",
        desc: "Hotel booking? Flight confirmation? That restaurant reservation your friend found? Save every link attached to the right day in your itinerary. The whole group can access them instantly.",
        details: [
            "Save any booking URL directly to your trip timeline",
            "Organize links by day or category for easy access",
            "One-tap access to hotel, flight, and activity confirmations",
            "Shared with the entire group automatically",
            "No more forwarding email confirmations to 8 people",
        ],
        bg: "bg-teal-50",
    },
    {
        title: "Polls & Group Voting",
        tagline: "Stop debating. Start voting.",
        desc: "Beach resort or mountain cabin? Sushi or street food? Create a poll, set a deadline, and let the group decide democratically. Results update live. Decisions happen in minutes, not days.",
        details: [
            "Create polls for any group decision — hotels, restaurants, activities, dates",
            "Anonymous or visible voting based on what works",
            "Set deadlines so decisions actually get made",
            "Live-updating results visible to everyone",
            "End the endless \"I'm fine with anything\" conversations",
        ],
        bg: "bg-rose-50",
    },
    {
        title: "Shared Photo Gallery",
        tagline: "All your trip photos. One place. Zero hassle.",
        desc: "Every trip gets a shared album. Everyone uploads from their phone. No more \"send me that photo\" requests three months later. All memories, organized by trip, accessible forever.",
        details: [
            "Shared albums where every trip member can upload photos",
            "React to photos with emojis — relive the highlights together",
            "Organized timeline view of all trip moments",
            "Download individual photos or entire albums",
            "Way better than a Google Drive folder nobody remembers",
        ],
        bg: "bg-blue-50",
    },
    {
        title: "Travel Agency Dashboard",
        tagline: "Professional tools for travel professionals.",
        desc: "Travel agencies get a dedicated dashboard to create trip packages, manage client itineraries, and publish trips for travelers to discover. Built for agencies that want to modernize.",
        details: [
            "Create professional trip packages with full itinerary details",
            "Publish trips publicly for travelers to browse and join",
            "Manage multiple client trips from one dashboard",
            "Share branded itineraries with your agency identity",
            "Track bookings, trip status, and client communications",
        ],
        bg: "bg-orange-50",
    },
    {
        title: "Privacy-First Design",
        tagline: "Your trips. Your data. Period.",
        desc: "WanderWith has zero ads, zero user tracking sold to third parties, and zero paywalls. Trips are private by default. Only people you invite can see anything. Your travel data is never sold or shared.",
        details: [
            "No advertisements anywhere in the app — ever",
            "No behavioural data sold to advertisers or third parties",
            "All trips are private by default — invite-only access",
            "Full account deletion with complete data removal",
            "You are the user, not the product",
        ],
        bg: "bg-slate-50",
    },
    {
        title: "Offline Access",
        tagline: "No signal? No problem.",
        desc: "Your full itinerary, budget, and trip details are cached locally. View everything offline — on planes, in remote mountains, or in that basement restaurant with no WiFi. Changes sync when you're back online.",
        details: [
            "All trip data cached locally on your device automatically",
            "Access itineraries, budgets, and notes without internet",
            "Changes queue and sync automatically when reconnected",
            "Designed for hill stations, flights, and international roaming",
        ],
        bg: "bg-cyan-50",
    },
];

const howItWorks = [
    {
        step: "01",
        title: "Create a Trip",
        desc: "Enter your destination, dates, and budget. Let AI generate an itinerary or start from scratch.",
    },
    {
        step: "02",
        title: "Invite Your Group",
        desc: "Share a link via WhatsApp, text, or email. Friends join in one tap.",
    },
    {
        step: "03",
        title: "Plan Together",
        desc: "Add places, vote in polls, track expenses, and chat — all in one app.",
    },
    {
        step: "04",
        title: "Travel & Remember",
        desc: "Follow your shared itinerary, split costs on the go, and save photos to the group gallery.",
    },
];

const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
        {
            "@type": "MobileApplication",
            name: "WanderWith",
            applicationCategory: "TravelApplication",
            operatingSystem: "Android, iOS",
            offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
            url: "https://www.wanderwith.online/features",
            description:
                "WanderWith is a free social travel planning app with AI-powered itineraries, group collaboration, built-in chat, budget tracking, polls, shared galleries, and a travel agency dashboard.",
            featureList: features.map((f) => f.title),
        },
        {
            "@type": "BreadcrumbList",
            itemListElement: [
                { "@type": "ListItem", position: 1, name: "Home", item: "https://www.wanderwith.online" },
                { "@type": "ListItem", position: 2, name: "Features" },
            ],
        },
    ],
};

export default function FeaturesPage() {
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
                            <span className="text-gray-900">Features</span>
                        </nav>

                        <h1 className="text-4xl md:text-6xl lg:text-[4.5rem] font-bold text-brand-primary font-serif leading-[1.08] tracking-tight mb-6">
                            Everything Your Group Needs to Plan, Travel, and Remember
                        </h1>
                        <p className="text-xl md:text-2xl text-gray-600 max-w-3xl leading-relaxed font-light mb-10">
                            AI itineraries. Shared planning. Built-in chat. Budget splitting. Polls. Photo gallery. One app, zero chaos. Free forever.
                        </p>
                        <div className="flex flex-col sm:flex-row gap-4">
                            <a
                                href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="inline-flex items-center gap-2 bg-brand-primary text-white px-8 py-4 rounded-full font-bold text-lg hover:bg-brand-accent transition-all hover:-translate-y-0.5 shadow-xl"
                            >
                                <Image
                                    src="/assets/icons8-google-play-store-100.png"
                                    alt="Play Store"
                                    width={22}
                                    height={22}
                                    className="brightness-0 invert"
                                />
                                Get WanderWith Free
                            </a>
                            <a
                                href="#how-it-works"
                                className="inline-flex items-center gap-2 bg-white text-brand-primary border border-gray-200 px-8 py-4 rounded-full font-bold text-lg hover:border-brand-accent/30 transition-all"
                            >
                                See How It Works
                            </a>
                        </div>

                        {/* Social proof strip */}
                        <div className="mt-14 grid grid-cols-2 sm:grid-cols-4 gap-6">
                            {[
                                ["4.8★", "Play Store Rating"],
                                ["10+", "Core Features"],
                                ["100%", "Free Forever"],
                                ["0", "Ads or Trackers"],
                            ].map(([value, label]) => (
                                <div key={label} className="text-center">
                                    <p className="text-3xl md:text-4xl font-bold text-brand-primary">{value}</p>
                                    <p className="text-sm text-gray-500 mt-1">{label}</p>
                                </div>
                            ))}
                        </div>
                    </div>
                </section>

                {/* How It Works */}
                <section id="how-it-works" className="py-20 bg-gray-50 scroll-mt-24">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3 text-center">How It Works</p>
                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-4 text-center">
                            From idea to trip in four steps.
                        </h2>
                        <p className="text-lg text-gray-600 text-center max-w-2xl mx-auto mb-14">
                            Getting started takes about 2 minutes. Here&apos;s the process.
                        </p>
                        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-8">
                            {howItWorks.map((s) => (
                                <div key={s.step} className="relative p-6 rounded-2xl bg-white border border-gray-200 hover:shadow-lg transition-shadow">
                                    <span className="text-5xl font-bold text-brand-accent/10 block mb-2">{s.step}</span>
                                    <h3 className="font-bold text-brand-primary text-xl mb-2">{s.title}</h3>
                                    <p className="text-gray-600 leading-relaxed">{s.desc}</p>
                                </div>
                            ))}
                        </div>
                    </div>
                </section>

                {/* Feature Grid Overview */}
                <section className="py-20">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3 text-center">Features</p>
                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-4 text-center">
                            Built for how friends actually travel.
                        </h2>
                        <p className="text-lg text-gray-600 text-center max-w-2xl mx-auto mb-14">
                            Every feature exists because we ran into a real problem on a real trip.
                        </p>
                        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
                            {features.map((f) => (
                                <a key={f.title} href={`#${f.title.toLowerCase().replace(/[^a-z0-9]+/g, "-")}`} className="group p-6 rounded-2xl border border-gray-200 bg-white hover:shadow-lg hover:border-brand-accent/20 transition-all">
                                    <h3 className="font-bold text-brand-primary text-lg mb-1 group-hover:text-brand-accent transition-colors">{f.title}</h3>
                                    <p className="text-sm text-gray-500 italic mb-3">{f.tagline}</p>
                                    <p className="text-gray-600 text-sm leading-relaxed line-clamp-3">{f.desc}</p>
                                </a>
                            ))}
                        </div>
                    </div>
                </section>

                {/* Features Deep Dive */}
                <section className="py-20 bg-gray-50">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <div className="space-y-28">
                            {features.map((feature, i) => (
                                <div
                                    key={feature.title}
                                    id={feature.title.toLowerCase().replace(/[^a-z0-9]+/g, "-")}
                                    className="scroll-mt-24 grid md:grid-cols-2 gap-10 md:gap-16 items-start"
                                >
                                    <div className={i % 2 === 1 ? "md:order-2" : ""}>
                                        <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-2">{feature.tagline}</p>
                                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-4">
                                            {feature.title}
                                        </h2>
                                        <p className="text-lg text-gray-600 leading-relaxed mb-6">
                                            {feature.desc}
                                        </p>
                                        <ul className="space-y-3">
                                            {feature.details.map((detail) => (
                                                <li key={detail} className="flex items-start gap-3 text-gray-700">
                                                    <span className="mt-1.5 w-1.5 h-1.5 rounded-full bg-brand-accent shrink-0" />
                                                    {detail}
                                                </li>
                                            ))}
                                        </ul>
                                    </div>
                                    <div className={`${feature.bg} rounded-2xl aspect-[4/3] flex flex-col items-center justify-center p-8 ${i % 2 === 1 ? "md:order-1" : ""}`}>
                                        <span className="text-7xl mb-4 select-none">
                                            {["🤖", "👥", "💬", "💰", "🔗", "📊", "📸", "🏢", "🔒", "📶"][i] || "✨"}
                                        </span>
                                        <p className="text-lg font-semibold text-gray-700 text-center">{feature.tagline}</p>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                </section>

                {/* Social Proof */}
                <section className="py-20">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3 text-center">Real Travelers</p>
                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-4 text-center">
                            Groups are already planning with WanderWith.
                        </h2>
                        <p className="text-lg text-gray-600 text-center max-w-2xl mx-auto mb-14">
                            Here&apos;s what people say after their first trip with the app.
                        </p>
                        <div className="grid md:grid-cols-3 gap-6">
                            {[
                                {
                                    quote: "We planned a Goa trip with 12 people in under an hour. The AI itinerary was actually good, and splitting expenses at the end was painless.",
                                    who: "College friend group, Goa trip",
                                },
                                {
                                    quote: "The polls feature saved us from 3 days of debate about whether to go to Manali or Rishikesh. 10 seconds, done.",
                                    who: "Weekend getaway group",
                                },
                                {
                                    quote: "As a travel agent, the dashboard lets me create packages and share itineraries with clients professionally. Way better than PDFs.",
                                    who: "Travel agency owner, Mumbai",
                                },
                            ].map((t) => (
                                <div key={t.who} className="p-6 rounded-2xl border border-gray-200 bg-white">
                                    <p className="text-gray-700 leading-relaxed mb-4 italic">&quot;{t.quote}&quot;</p>
                                    <p className="text-sm text-gray-500 font-medium">{t.who}</p>
                                </div>
                            ))}
                        </div>
                    </div>
                </section>

                {/* Comparison Table */}
                <section className="py-20 bg-gray-50">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3 text-center">Comparison</p>
                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-4 text-center">
                            WanderWith vs. the rest.
                        </h2>
                        <p className="text-lg text-gray-600 text-center max-w-2xl mx-auto mb-12">
                            Most travel apps are built for solo travelers booking hotels. WanderWith is built for groups planning together.
                        </p>

                        <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse">
                                <thead>
                                    <tr className="border-b-2 border-gray-200">
                                        <th className="py-4 pr-6 text-sm font-semibold text-gray-500 uppercase tracking-wide">Feature</th>
                                        <th className="py-4 px-4 text-sm font-semibold text-brand-accent uppercase tracking-wide text-center">WanderWith</th>
                                        <th className="py-4 px-4 text-sm font-semibold text-gray-500 uppercase tracking-wide text-center">TripIt</th>
                                        <th className="py-4 px-4 text-sm font-semibold text-gray-500 uppercase tracking-wide text-center">Wanderlog</th>
                                        <th className="py-4 px-4 text-sm font-semibold text-gray-500 uppercase tracking-wide text-center">Polarsteps</th>
                                    </tr>
                                </thead>
                                <tbody className="text-sm">
                                    {([
                                        ["AI Itinerary Generation", true, false, true, false],
                                        ["Group Trip Planning", true, false, true, false],
                                        ["Built-in Group Chat", true, false, false, false],
                                        ["Polls & Voting", true, false, false, false],
                                        ["Budget Tracking & Splitting", true, false, true, false],
                                        ["Shared Photo Gallery", true, false, false, true],
                                        ["Travel Agency Dashboard", true, false, false, false],
                                        ["Privacy-First (No Ads)", true, false, false, false],
                                        ["Completely Free", true, false, false, true],
                                        ["Offline Access", true, true, true, true],
                                    ] as [string, boolean, boolean, boolean, boolean][]).map(([name, ww, tripit, wlog, polar]) => (
                                        <tr key={name} className="border-b border-gray-100">
                                            <td className="py-3 pr-6 font-medium text-gray-900">{name}</td>
                                            <td className="py-3 px-4 text-center">{ww ? <span className="text-green-600 font-bold">✓</span> : <span className="text-gray-300">—</span>}</td>
                                            <td className="py-3 px-4 text-center">{tripit ? <span className="text-green-600 font-bold">✓</span> : <span className="text-gray-300">—</span>}</td>
                                            <td className="py-3 px-4 text-center">{wlog ? <span className="text-green-600 font-bold">✓</span> : <span className="text-gray-300">—</span>}</td>
                                            <td className="py-3 px-4 text-center">{polar ? <span className="text-green-600 font-bold">✓</span> : <span className="text-gray-300">—</span>}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </section>

                {/* CTA */}
                <section className="py-20">
                    <div className="container mx-auto px-6 max-w-3xl text-center">
                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-4">
                            Your group&apos;s next trip deserves better planning.
                        </h2>
                        <p className="text-lg text-gray-600 mb-8 max-w-xl mx-auto">
                            Download WanderWith, create a trip, and share the link with your group. Two minutes is all it takes.
                        </p>
                        <div className="flex flex-col sm:flex-row gap-4 justify-center">
                            <a
                                href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="inline-flex items-center justify-center gap-2 bg-brand-primary text-white px-8 py-4 rounded-full font-bold text-lg hover:bg-brand-accent transition-all shadow-xl hover:-translate-y-0.5"
                            >
                                Download Free on Google Play
                            </a>
                            <Link
                                href="/use-cases"
                                className="inline-flex items-center justify-center gap-2 bg-white text-brand-primary border border-brand-border px-8 py-4 rounded-full font-bold text-lg hover:border-brand-accent/30 transition-all"
                            >
                                See Use Cases
                            </Link>
                        </div>
                    </div>
                </section>
            </main>
            <Footer />
        </>
    );
}
