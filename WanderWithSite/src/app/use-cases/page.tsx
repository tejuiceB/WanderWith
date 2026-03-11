import { Metadata } from "next";
import Link from "next/link";
import Footer from "@/components/Footer";

export const metadata: Metadata = {
    title: "WanderWith Use Cases — Group Trips, Solo Travel, College Trips, Agencies & More",
    description:
        "See how WanderWith helps friend groups, families, solo travelers, college students, corporate teams, couples, and travel agencies plan and manage trips effortlessly.",
    keywords: [
        "WanderWith use cases",
        "group trip planning app",
        "college trip planner",
        "family vacation app",
        "solo travel organizer",
        "travel agency software",
        "corporate team outing planner",
        "couple trip app",
    ],
    alternates: { canonical: "https://www.wanderwith.online/use-cases" },
    openGraph: {
        title: "WanderWith Use Cases — Who Is It For?",
        description:
            "Friend groups, families, solo travelers, college students, corporate teams, couples, and travel agencies — WanderWith works for everyone.",
        url: "https://www.wanderwith.online/use-cases",
        siteName: "WanderWith",
        type: "website",
    },
};

const useCases = [
    {
        title: "Friend Group Trips",
        shortName: "Friends",
        icon: "👥",
        subtitle: "3–15 friends planning a weekend getaway or long vacation",
        description:
            "The classic use case WanderWith was built for. When your friend group decides to go on a trip, the planning quickly devolves into endless WhatsApp messages, people dropping out of Google Sheets, and someone forgetting to book their share. WanderWith puts the entire plan in one place where everyone collaborates together.",
        features: [
            "Create a trip and invite everyone with one link",
            "Use polls to vote on destinations, hotels, and restaurants",
            "Built-in chat keeps trip talk separate from personal chats",
            "Budget tracker splits expenses fairly — no more Splitwise confusion",
            "Shared gallery for all trip photos in one place",
        ],
        scenario:
            "Your college friends want a Goa trip. You create a trip on WanderWith, share the invite link in the group. AI generates a 4-day itinerary. Everyone votes on beach vs nightlife mix. Budget tracker logs each expense. Photos go into the shared gallery. No chaos.",
        bg: "bg-violet-50",
    },
    {
        title: "Family Vacations",
        shortName: "Families",
        icon: "👨‍👩‍👧‍👦",
        subtitle: "Parents, kids, grandparents — multi-generational travel",
        description:
            "Family trips come with extra complexity: different age groups, varying interests, budget awareness, and the need for everyone to feel included in decisions. WanderWith handles all of this with simple collaboration tools that even non-tech-savvy family members can use.",
        features: [
            "AI generates itineraries that balance kid-friendly and adult activities",
            "Share the plan with family members who only need to view, not edit",
            "Budget tracker helps parents track vacation spending",
            "Save hotel and flight booking links for easy group access",
            "Offline access means you can check the plan without Wi-Fi at remote destinations",
        ],
        scenario:
            "A family of 8 is planning a Rajasthan trip. Parents create the trip, AI suggests heritage sites and kid-friendly spots. Grandparents view the itinerary on their phones. Uncle adds restaurant bookings. Budget stays transparent. Everyone knows the plan.",
        bg: "bg-amber-50",
    },
    {
        title: "Solo Travelers",
        shortName: "Solo",
        icon: "🎒",
        subtitle: "One person, one backpack, one well-organized plan",
        description:
            "Even solo travelers need organization. WanderWith's AI generates complete day-by-day itineraries for any destination, and you get a single place to store all bookings, notes, and plans. It's like having a personal travel assistant — minus the cost.",
        features: [
            "AI builds full itineraries from just a destination and dates",
            "Store all booking confirmations in one organized place",
            "Offline access lets you navigate even in areas with no signal",
            "Budget tracker helps you stay within your travel budget",
            "Share your itinerary with family at home so they know your plan",
        ],
        scenario:
            "You're backpacking through Vietnam for 2 weeks. You give WanderWith your dates and budget. AI generates a route covering Hanoi, Ha Long Bay, Hoi An, and Ho Chi Minh City with hostels, street food spots, and must-see sites. All booking links saved in one place. Mom can view the plan at home.",
        bg: "bg-emerald-50",
    },
    {
        title: "College Trips & Student Groups",
        shortName: "Students",
        icon: "🎓",
        subtitle: "Big groups, tight budgets, maximum fun",
        description:
            "College trips are legendary — but planning them with 15+ people is a nightmare. WanderWith is free (important for students), handles large groups, and the polling system means decisions actually get made instead of being debated for weeks.",
        features: [
            "Free for everyone — no premium tier needed for groups",
            "Polls end the endless \"where should we go?\" debates",
            "Budget splitting is transparent and fair",
            "AI plans around student budgets — hostels over hotels, street food over fine dining",
            "Group chat keeps all trip discussions in context",
        ],
        scenario:
            "20 classmates want a farewell trip to Manali. Trip organizer creates it on WanderWith, adds everyone. Poll: Manali vs Rishikesh — Manali wins. AI generates a 5-day plan on a ₹5000/person budget. Expenses tracked, photos shared, memories made.",
        bg: "bg-blue-50",
    },
    {
        title: "Corporate Team Outings",
        shortName: "Corporate",
        icon: "🏗️",
        subtitle: "Team building trips and company retreats",
        description:
            "HR managers and team leads need a way to organize offsites without drowning in email threads. WanderWith provides a structured, shareable plan that the whole team can access, with clear budgeting and visibility.",
        features: [
            "Professional itinerary creation with AI assistance",
            "Budget tracking for corporate expense reports",
            "Share the trip plan with the entire team via a link",
            "Polls for team-building activity preferences",
            "Smart booking links for hotel and venue confirmations",
        ],
        scenario:
            "A startup with 30 people plans a 3-day offsite in Coorg. HR creates the trip, AI suggests team activities and venues. Team votes on adventure vs relaxation activities. All bookings centralized. Budget report ready for finance.",
        bg: "bg-rose-50",
    },
    {
        title: "Couples & Honeymoons",
        shortName: "Couples",
        icon: "💑",
        subtitle: "Romantic trips for two, planned together",
        description:
            "Planning a romantic getaway or honeymoon should be exciting, not stressful. WanderWith lets couples plan together, save inspiration, and keep all the bookings organized — from flights to spa appointments.",
        features: [
            "AI creates romantic itineraries with couple-friendly activities",
            "Save restaurant reservations, spa bookings, and hotel links",
            "Shared planning so both partners contribute to the itinerary",
            "Budget tracking for honeymoon spending",
            "Private by default — your romantic plans stay between you two",
        ],
        scenario:
            "Newlyweds planning a Bali honeymoon. Both add places they want to visit. AI balances beach days with temple visits and culinary experiences. All resort and flight bookings saved in the app. Budget tracked. Private and stress-free.",
        bg: "bg-pink-50",
    },
    {
        title: "Travel Agencies",
        shortName: "Agencies",
        icon: "🏢",
        subtitle: "Professional trip management and client packages",
        description:
            "Travel agencies use WanderWith's agency dashboard to create professional trip packages, manage multiple client trips, publish public itineraries, and share branded plans. It's the modern alternative to PDF itineraries.",
        features: [
            "Agency dashboard for managing multiple trips and clients",
            "Create and publish public trip packages for travelers to discover",
            "Professional itinerary creation with AI assistance",
            "Share branded, interactive itineraries instead of static PDFs",
            "Client communication within the trip context",
        ],
        scenario:
            "A travel agency in Mumbai creates a \"Golden Triangle 7-Day\" package on WanderWith. It's published publicly. Travelers discover it, join, and communicate directly with the agency through the app. No more email back-and-forth.",
        bg: "bg-orange-50",
    },
];

const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
        {
            "@type": "BreadcrumbList",
            itemListElement: [
                { "@type": "ListItem", position: 1, name: "Home", item: "https://www.wanderwith.online" },
                { "@type": "ListItem", position: 2, name: "Use Cases" },
            ],
        },
        {
            "@type": "WebPage",
            name: "WanderWith Use Cases",
            description:
                "How friend groups, families, solo travelers, students, corporate teams, couples, and travel agencies use WanderWith to plan trips.",
            url: "https://www.wanderwith.online/use-cases",
        },
    ],
};

export default function UseCasesPage() {
    return (
        <>
            <main className="min-h-screen bg-white">
                <script
                    type="application/ld+json"
                    dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
                />

                {/* Hero */}
                <section className="pt-32 pb-16 bg-gradient-to-br from-[#F7F3EC] via-white to-[#F7F3EC] relative overflow-hidden">
                    <div className="absolute inset-0 opacity-30">
                        <div className="absolute top-10 left-20 w-80 h-80 bg-violet-500/15 rounded-full blur-3xl" />
                        <div className="absolute bottom-10 right-10 w-80 h-80 bg-brand-accent/15 rounded-full blur-3xl" />
                    </div>
                    <div className="container mx-auto px-6 max-w-5xl relative z-10">
                        <nav aria-label="Breadcrumb" className="mb-8 text-sm text-gray-500">
                            <Link href="/" className="hover:text-brand-accent transition-colors">Home</Link>
                            <span className="mx-2">/</span>
                            <span className="text-gray-900">Use Cases</span>
                        </nav>

                        <h1 className="text-4xl md:text-6xl lg:text-[4.5rem] font-bold text-brand-primary font-serif leading-[1.08] tracking-tight mb-6">
                            Who Uses WanderWith?
                        </h1>
                        <p className="text-xl md:text-2xl text-gray-600 max-w-3xl leading-relaxed font-light">
                            One app for every kind of traveler. See how different groups use WanderWith to plan better trips.
                        </p>
                    </div>
                </section>

                {/* Quick overview cards */}
                <section className="py-16">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-7 gap-4">
                            {useCases.map((uc) => (
                                <a
                                    key={uc.title}
                                    href={`#${uc.title.toLowerCase().replace(/[^a-z0-9]+/g, "-")}`}
                                    className="group text-center p-4 rounded-2xl border border-gray-200 bg-white hover:shadow-lg hover:border-brand-accent/20 transition-all"
                                >
                                    <span className="text-3xl block mb-2">{uc.icon}</span>
                                    <p className="text-sm font-semibold text-gray-700 group-hover:text-brand-accent transition-colors leading-tight">{uc.shortName}</p>
                                </a>
                            ))}
                        </div>
                    </div>
                </section>

                {/* Use case sections — alternating 2-column layout */}
                <section className="py-10">
                    <div className="container mx-auto px-6 max-w-5xl space-y-24">
                        {useCases.map((uc, i) => (
                            <article
                                key={uc.title}
                                id={uc.title.toLowerCase().replace(/[^a-z0-9]+/g, "-")}
                                className="scroll-mt-24"
                            >
                                <div className={`grid md:grid-cols-2 gap-10 md:gap-16 items-start`}>
                                    {/* Text side */}
                                    <div className={i % 2 === 1 ? "md:order-2" : ""}>
                                        <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-2">{uc.subtitle}</p>
                                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-4">
                                            {uc.title}
                                        </h2>
                                        <p className="text-lg text-gray-600 leading-relaxed mb-6">
                                            {uc.description}
                                        </p>
                                        <ul className="space-y-3 mb-6">
                                            {uc.features.map((f) => (
                                                <li key={f} className="flex items-start gap-3 text-gray-700">
                                                    <span className="mt-1.5 w-1.5 h-1.5 rounded-full bg-brand-accent shrink-0" />
                                                    {f}
                                                </li>
                                            ))}
                                        </ul>
                                    </div>

                                    {/* Visual side — scenario card */}
                                    <div className={`${uc.bg} rounded-2xl p-8 flex flex-col justify-between ${i % 2 === 1 ? "md:order-1" : ""}`}>
                                        <div>
                                            <span className="text-5xl block mb-4">{uc.icon}</span>
                                            <h3 className="font-semibold text-gray-900 mb-3 text-lg">Real-World Scenario</h3>
                                            <p className="text-gray-600 leading-relaxed italic">
                                                &ldquo;{uc.scenario}&rdquo;
                                            </p>
                                        </div>
                                    </div>
                                </div>
                            </article>
                        ))}
                    </div>
                </section>

                {/* Why WanderWith Works for Every Traveler */}
                <section className="py-20 bg-gray-50">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3 text-center">Universal</p>
                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-4 text-center">
                            Why WanderWith Works for Every Traveler
                        </h2>
                        <p className="text-lg text-gray-600 text-center max-w-2xl mx-auto mb-14">
                            No matter your trip style, these core capabilities make group planning effortless.
                        </p>
                        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
                            {[
                                { icon: "🤖", title: "AI Plans in Seconds", desc: "Generate a full itinerary from just a destination and dates" },
                                { icon: "🔗", title: "One-Link Invites", desc: "Share a link and your whole group joins instantly" },
                                { icon: "📊", title: "Polls End Debates", desc: "Vote on hotels, restaurants, and activities democratically" },
                                { icon: "💰", title: "Budget Transparency", desc: "Track spending in real-time and split fairly" },
                                { icon: "💬", title: "Chat in Context", desc: "Trip discussions that live alongside the plan" },
                                { icon: "📶", title: "Works Offline", desc: "Access your itinerary even without internet" },
                            ].map((f) => (
                                <div key={f.title} className="p-6 rounded-2xl border border-gray-200 bg-white hover:shadow-lg transition-shadow">
                                    <span className="text-3xl mb-3 block">{f.icon}</span>
                                    <h3 className="font-bold text-brand-primary text-lg mb-2">{f.title}</h3>
                                    <p className="text-gray-600 text-sm leading-relaxed">{f.desc}</p>
                                </div>
                            ))}
                        </div>
                    </div>
                </section>

                {/* Social proof numbers */}
                <section className="py-20">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-8 text-center">
                            {[
                                { value: "4.8★", label: "Play Store Rating" },
                                { value: "7", label: "Traveler Types Served" },
                                { value: "100%", label: "Free, No Catches" },
                                { value: "10+", label: "Core Features" },
                            ].map((s) => (
                                <div key={s.label} className="p-6 rounded-2xl border border-gray-200 bg-white">
                                    <p className="text-3xl md:text-4xl font-bold text-brand-primary mb-1">{s.value}</p>
                                    <p className="text-sm text-gray-500">{s.label}</p>
                                </div>
                            ))}
                        </div>
                    </div>
                </section>

                {/* CTA */}
                <section className="py-20 bg-gray-50">
                    <div className="container mx-auto px-6 max-w-3xl text-center">
                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-4">
                            Which Traveler Are You?
                        </h2>
                        <p className="text-lg text-gray-600 mb-8">
                            No matter how you travel, WanderWith has the tools to make planning effortless. Try it free today.
                        </p>
                        <div className="flex flex-col sm:flex-row gap-4 justify-center">
                            <a
                                href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="inline-flex items-center justify-center gap-2 bg-brand-primary text-white px-8 py-4 rounded-full font-bold text-lg hover:bg-brand-accent transition-all shadow-xl hover:-translate-y-0.5"
                            >
                                Download Free
                            </a>
                            <Link
                                href="/features"
                                className="inline-flex items-center justify-center gap-2 bg-white text-brand-primary border border-gray-200 px-8 py-4 rounded-full font-bold text-lg hover:border-brand-accent/30 transition-all"
                            >
                                Explore All Features
                            </Link>
                        </div>
                    </div>
                </section>
            </main>
            <Footer />
        </>
    );
}
