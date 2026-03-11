import { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import Footer from "@/components/Footer";

export const metadata: Metadata = {
    title: "About WanderWith — Our Story, Mission & Why We Built This Travel App",
    description:
        "WanderWith was built in India to fix the chaos of group trip planning. Learn about our mission, values, and why the app is free forever with no ads or data selling.",
    keywords: [
        "about WanderWith",
        "WanderWith story",
        "WanderWith mission",
        "travel planning startup India",
        "group travel app story",
        "free trip planner story",
        "AI travel app India",
        "social travel planning",
    ],
    alternates: { canonical: "https://www.wanderwith.online/about" },
    openGraph: {
        title: "About WanderWith — Our Story & Mission",
        description:
            "Built in India to fix the chaos of group trip planning. Free forever, no ads, no data selling.",
        url: "https://www.wanderwith.online/about",
        siteName: "WanderWith",
        type: "website",
    },
};

const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
        {
            "@type": "Organization",
            name: "WanderWith",
            url: "https://www.wanderwith.online",
            email: "wanderwithplan@gmail.com",
            foundingDate: "2025",
            description:
                "WanderWith is a free social travel planning app built in India for group travelers. AI itineraries, real-time collaboration, budgets, chat, polls, and galleries — no ads, no data selling.",
            sameAs: [
                "https://play.google.com/store/apps/details?id=com.tejuice.wanderwith",
                "https://www.instagram.com/wanderwith.online",
            ],
        },
        {
            "@type": "BreadcrumbList",
            itemListElement: [
                { "@type": "ListItem", position: 1, name: "Home", item: "https://www.wanderwith.online" },
                { "@type": "ListItem", position: 2, name: "About" },
            ],
        },
    ],
};

export default function AboutPage() {
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
                        <div className="absolute top-20 right-20 w-96 h-96 bg-brand-accent/15 rounded-full blur-3xl" />
                        <div className="absolute bottom-10 left-10 w-72 h-72 bg-brand-accent/10 rounded-full blur-3xl" />
                    </div>
                    <div className="container mx-auto px-6 max-w-5xl relative z-10">
                        <nav aria-label="Breadcrumb" className="mb-8 text-sm text-gray-500">
                            <Link href="/" className="hover:text-brand-accent transition-colors">Home</Link>
                            <span className="mx-2">/</span>
                            <span className="text-gray-900">About</span>
                        </nav>

                        <h1 className="text-4xl md:text-6xl lg:text-[4.5rem] font-bold text-brand-primary font-serif leading-[1.08] tracking-tight mb-6">
                            We Just Wanted to Go on a Trip Without the Chaos
                        </h1>
                        <p className="text-xl md:text-2xl text-gray-600 max-w-3xl leading-relaxed font-light">
                            Every group trip starts exciting and ends with &quot;who booked what?&quot; and &quot;send me that photo.&quot;
                            We built WanderWith so the only thing you worry about is having fun.
                        </p>
                    </div>
                </section>

                {/* The Problem */}
                <section className="py-20">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <div className="grid md:grid-cols-2 gap-12 md:gap-16 items-center">
                            <div className="relative aspect-[4/3] w-full overflow-hidden rounded-2xl shadow-xl">
                                <Image
                                    src="https://images.unsplash.com/photo-1539635278303-d4002c07eae3?q=80&w=2070&auto=format&fit=crop"
                                    alt="Group of friends planning a trip together, representing collaborative travel planning"
                                    fill
                                    className="object-cover"
                                />
                            </div>
                            <div>
                                <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3">The Problem</p>
                                <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-6">
                                    Planning trips with friends{" "}
                                    <span className="italic text-brand-accent">shouldn&apos;t require a project manager.</span>
                                </h2>
                                <div className="space-y-4 text-lg text-gray-600 leading-relaxed font-light">
                                    <p>
                                        You know how it goes. Someone drops the idea in the group chat. Everyone&apos;s excited for about 5 minutes. Then it turns into 47 unread WhatsApp messages, a Google Sheet nobody updates, and that one friend who sends hotel links at 2 AM.
                                    </p>
                                    <p>
                                        Three weeks later, nothing is booked. The trip almost dies. And when it finally happens, half the group didn&apos;t know the itinerary changed.
                                    </p>
                                    <p>
                                        We&apos;ve been that group. Multiple times. And we got tired of it.
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </section>

                {/* Our Story */}
                <section className="py-20 bg-gray-50">
                    <div className="container mx-auto px-6 max-w-3xl">
                        <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3 text-center">Our Story</p>
                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-10 text-center">
                            So we built what we wished existed.
                        </h2>
                        <div className="space-y-6 text-lg text-gray-600 leading-relaxed font-light">
                            <p>
                                WanderWith started in early 2025 in India. Not in a startup incubator, not with venture funding. It started because we were planning a Goa trip with 8 friends and the process was an absolute mess.
                            </p>
                            <p>
                                We looked at every trip planning app out there. Most were designed for solo travelers booking hotels. The few that supported groups felt like enterprise project management tools dressed up with a beach photo. None of them understood what it&apos;s actually like to plan a trip with your friends.
                            </p>
                            <p>
                                So we started building. The first version just had a shared itinerary and a chat. We used it on our next trip and immediately realized how much better everything felt when the plan, the budget, and the conversation all lived in the same place.
                            </p>
                            <p>
                                Then we added AI itinerary generation because building a day-by-day plan from scratch is tedious. Then budget tracking and expense splitting because &quot;I&apos;ll Paytm you later&quot; never works. Then polls because choosing between Manali and Rishikesh took our group 3 days over text.
                            </p>
                            <p>
                                Every single feature in WanderWith exists because we ran into a real problem on a real trip.
                            </p>
                        </div>
                    </div>
                </section>

                {/* Product Philosophy */}
                <section className="py-20">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3 text-center">How We Think About Product</p>
                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-4 text-center">
                            The travel app we&apos;d want to use ourselves.
                        </h2>
                        <p className="text-lg text-gray-600 text-center max-w-2xl mx-auto mb-14">
                            We make decisions as travelers first, developers second.
                        </p>
                        <div className="grid sm:grid-cols-2 gap-6 md:gap-8">
                            {[
                                {
                                    title: "Groups First, Always",
                                    desc: "Most travel apps treat groups as an afterthought. We built WanderWith for the way people actually travel: together. Shared itineraries, group polls, split bills, trip chat. Everything is collaborative by default.",
                                    icon: "👥",
                                },
                                {
                                    title: "AI as a Starting Point",
                                    desc: "Our AI generates complete itineraries, but it never locks you in. Every suggestion is editable. It's more like a well-traveled friend who gives you a solid first draft than a robot that tells you what to do.",
                                    icon: "✨",
                                },
                                {
                                    title: "No Upsells, No Walls",
                                    desc: "WanderWith is free. Not \"free with a catch\" or \"free for 3 trips.\" Actually free. No premium tier that gates the good features. No ads between your itinerary items. Your data stays yours.",
                                    icon: "💚",
                                },
                                {
                                    title: "Built for Real Conditions",
                                    desc: "We know you'll use this app with spotty hotel WiFi and one bar of signal at a hill station. So we made it fast, lightweight, and reliable. Because the last thing you need on a trip is an app that doesn't work.",
                                    icon: "📱",
                                },
                            ].map((v) => (
                                <div
                                    key={v.title}
                                    className="p-8 rounded-2xl border border-gray-200 bg-white hover:shadow-lg transition-shadow"
                                >
                                    <span className="text-3xl mb-4 block">{v.icon}</span>
                                    <h3 className="font-semibold text-brand-primary text-xl mb-3">{v.title}</h3>
                                    <p className="text-gray-600 leading-relaxed">{v.desc}</p>
                                </div>
                            ))}
                        </div>
                    </div>
                </section>

                {/* What We've Built So Far */}
                <section className="py-20 bg-gray-50">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3 text-center">What We&apos;ve Built So Far</p>
                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-12 text-center">
                            From side project to platform.
                        </h2>
                        <div className="relative">
                            {/* Timeline line */}
                            <div className="hidden md:block absolute left-1/2 top-0 bottom-0 w-px bg-gray-200" />
                            <div className="space-y-12 md:space-y-0">
                                {[
                                    {
                                        phase: "Phase 1",
                                        title: "Core Planning",
                                        desc: "Started with the basics: shared itineraries, trip chat, and friend invites via link. Used it ourselves on 3 trips before showing it to anyone else.",
                                        side: "left",
                                    },
                                    {
                                        phase: "Phase 2",
                                        title: "AI + Intelligence",
                                        desc: "Added AI itinerary generation so you don't have to spend hours researching. Enter your destination, dates, and preferences. Get a complete day-by-day plan in seconds.",
                                        side: "right",
                                    },
                                    {
                                        phase: "Phase 3",
                                        title: "Group Features",
                                        desc: "Polls for group decisions. Budget tracking with expense splitting. Shared photo gallery. The features groups actually need when 8 people are trying to agree on anything.",
                                        side: "left",
                                    },
                                    {
                                        phase: "Phase 4",
                                        title: "Agency Dashboard",
                                        desc: "Travel agencies asked if they could use WanderWith to manage clients. So we built a dedicated agency dashboard with package creation, client management, and public trip publishing.",
                                        side: "right",
                                    },
                                ].map((m, i) => (
                                    <div
                                        key={i}
                                        className={`md:grid md:grid-cols-2 md:gap-12 items-center ${i > 0 ? "md:mt-12" : ""}`}
                                    >
                                        <div className={`${m.side === "right" ? "md:order-2" : ""}`}>
                                            <div className="p-6 rounded-2xl border border-gray-200 bg-white">
                                                <p className="text-brand-accent font-bold text-sm mb-2">{m.phase}</p>
                                                <h3 className="font-bold text-brand-primary text-xl mb-3">{m.title}</h3>
                                                <p className="text-gray-600 leading-relaxed">{m.desc}</p>
                                            </div>
                                        </div>
                                        <div className={`hidden md:block ${m.side === "right" ? "md:order-1" : ""}`} />
                                    </div>
                                ))}
                            </div>
                        </div>
                    </div>
                </section>

                {/* Where We're Going */}
                <section className="py-20">
                    <div className="container mx-auto px-6 max-w-3xl">
                        <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3 text-center">Where We&apos;re Going</p>
                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-10 text-center">
                            This is just the beginning.
                        </h2>
                        <div className="space-y-5 text-lg text-gray-600 leading-relaxed font-light">
                            <p>
                                We&apos;re building WanderWith to be the one app every travel group opens first. Not because we do the most things, but because we do the right things for how friends actually plan trips together.
                            </p>
                            <p>
                                The roadmap includes iOS support, deeper AI personalization that learns your travel style over time, offline mode for remote destinations, and tools for travel communities to discover and plan together.
                            </p>
                            <p>
                                We&apos;re not trying to replace every travel app. We&apos;re building the one that handles the part nobody else gets right: the part where you plan, coordinate, and travel <em>together</em>.
                            </p>
                        </div>
                    </div>
                </section>

                {/* Quick Facts */}
                <section className="py-20 bg-gray-50">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-12 text-center">
                            WanderWith at a Glance
                        </h2>
                        <dl className="grid sm:grid-cols-2 lg:grid-cols-4 gap-8 text-center">
                            {[
                                ["Founded", "2025"],
                                ["Built In", "India"],
                                ["Price", "Free forever"],
                                ["Platforms", "Android (iOS soon)"],
                            ].map(([label, value]) => (
                                <div key={label} className="p-6 rounded-2xl bg-white border border-gray-200">
                                    <dt className="text-sm text-gray-500 uppercase tracking-wide mb-1">{label}</dt>
                                    <dd className="text-2xl font-bold text-brand-primary">{value}</dd>
                                </div>
                            ))}
                        </dl>
                    </div>
                </section>

                {/* CTA */}
                <section className="py-20">
                    <div className="container mx-auto px-6 max-w-3xl text-center">
                        <h2 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-4">
                            Made with love in India.
                        </h2>
                        <p className="text-lg text-gray-600 mb-8">
                            We&apos;d love for you to try WanderWith on your next trip. It&apos;s free, it works, and your group will thank you.
                        </p>
                        <div className="flex flex-col sm:flex-row gap-4 justify-center">
                            <a
                                href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="inline-flex items-center justify-center gap-2 bg-brand-primary text-white px-8 py-4 rounded-full font-bold text-lg hover:bg-brand-accent transition-all shadow-xl hover:-translate-y-0.5"
                            >
                                Download Free on Play Store
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
