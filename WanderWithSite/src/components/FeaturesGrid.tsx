"use client";

import { useState } from "react";
import { motion } from "framer-motion";
import {
    ChevronDown,
    ChevronUp,
    Sparkles,
    Users,
    MessageSquare,
    Wallet,
    Link2,
    BarChart3,
    Image as ImageIcon,
    Globe,
    Shield,
} from "lucide-react";

const features = [
    {
        icon: Sparkles,
        title: "AI Itineraries",
        desc: "Generate complete day-by-day plans in seconds with smart AI suggestions.",
        gradient: "from-indigo-500 to-violet-500",
        bg: "bg-indigo-50",
    },
    {
        icon: Users,
        title: "Group Trips",
        desc: "Invite friends, vote on plans, and keep everyone in sync effortlessly.",
        gradient: "from-violet-500 to-purple-500",
        bg: "bg-violet-50",
    },
    {
        icon: MessageSquare,
        title: "Built-in Chat",
        desc: "Trip-specific group chats so conversations stay with the plan.",
        gradient: "from-emerald-500 to-teal-500",
        bg: "bg-emerald-50",
    },
    {
        icon: Wallet,
        title: "Budget Tracker",
        desc: "Track expenses, split costs fairly, and stay on budget throughout your trip.",
        gradient: "from-amber-500 to-orange-500",
        bg: "bg-amber-50",
    },
    {
        icon: Link2,
        title: "Smart Links",
        desc: "Save hotel bookings, flights, and maps in one place. No more digging through emails.",
        gradient: "from-teal-500 to-cyan-500",
        bg: "bg-teal-50",
    },
    {
        icon: BarChart3,
        title: "Polls & Voting",
        desc: "Can't decide where to eat? Let the group vote and move on. Democracy wins.",
        gradient: "from-rose-500 to-pink-500",
        bg: "bg-rose-50",
    },
    {
        icon: ImageIcon,
        title: "Trip Gallery",
        desc: "Shared photo albums for every trip. Memories stay together, not scattered across phones.",
        gradient: "from-blue-500 to-indigo-500",
        bg: "bg-blue-50",
    },
    {
        icon: Globe,
        title: "Agency Dashboard",
        desc: "Travel agencies can create packages, share itineraries, and manage clients professionally.",
        gradient: "from-orange-500 to-red-500",
        bg: "bg-orange-50",
    },
    {
        icon: Shield,
        title: "Private & Secure",
        desc: "Your trips are yours. No ads, no tracking, no selling data. Privacy built in.",
        gradient: "from-slate-500 to-zinc-600",
        bg: "bg-slate-50",
    },
];

function FeatureCard({ f, i }: { f: (typeof features)[number]; i: number }) {
    return (
        <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-40px" }}
            transition={{ type: "spring", stiffness: 100, damping: 20, delay: i * 0.04 }}
            className="group relative p-6 sm:p-7 rounded-2xl border border-brand-border bg-brand-card overflow-hidden transition-all duration-300 hover:shadow-xl hover:shadow-black/[0.06] hover:-translate-y-1 hover:border-brand-accent/20 min-w-[260px] sm:min-w-0"
        >
            {/* Gradient strip on hover */}
            <div className={`absolute inset-x-0 top-0 h-0.5 bg-gradient-to-r ${f.gradient} opacity-0 group-hover:opacity-100 transition-opacity duration-300`} />

            <div className={`inline-flex p-3 rounded-xl mb-4 sm:mb-5 ${f.bg}`}>
                <f.icon className="w-5 h-5" />
            </div>
            <h3 className="font-semibold text-brand-primary text-lg mb-2">{f.title}</h3>
            <p className="text-brand-text-secondary text-[14px] sm:text-[15px] leading-relaxed">{f.desc}</p>
        </motion.div>
    );
}

export default function FeaturesGrid() {
    const [expanded, setExpanded] = useState(false);

    return (
        <section id="features" className="bg-brand-bg py-24 md:py-32">
            <div className="max-w-7xl mx-auto px-5 md:px-8">
                {/* Section header */}
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ type: "spring", stiffness: 80, damping: 20 }}
                    className="text-center mb-14"
                >
                    <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3">Features</p>
                    <h2 className="font-serif font-bold text-3xl sm:text-4xl md:text-5xl text-brand-primary tracking-tight mb-4">
                        Everything you need to travel smarter
                    </h2>
                    <p className="text-brand-text-secondary text-lg max-w-2xl mx-auto">
                        From AI-powered planning to group coordination. One app replaces a dozen travel tools.
                    </p>
                </motion.div>

                {/* Mobile: horizontal scroll */}
                <div className="sm:hidden -mx-5 px-5 overflow-x-auto scrollbar-hide">
                    <div className="flex gap-4 w-max pb-4">
                        {features.map((f, i) => (
                            <div key={f.title} className="w-[270px] flex-shrink-0">
                                <FeatureCard f={f} i={i} />
                            </div>
                        ))}
                    </div>
                </div>

                {/* Tablet+: grid with fade collapse */}
                <div className="hidden sm:block">
                    <div className="relative">
                        <div
                            className={`transition-[max-height] duration-700 ease-in-out overflow-hidden ${
                                expanded ? "max-h-[2000px]" : "max-h-[420px] lg:max-h-[340px]"
                            }`}
                        >
                            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-5">
                                {features.map((f, i) => (
                                    <FeatureCard key={f.title} f={f} i={i} />
                                ))}
                            </div>
                        </div>

                        {/* Gradient fade */}
                        {!expanded && (
                            <div className="absolute bottom-0 inset-x-0 h-36 bg-gradient-to-t from-[#FFFFFF] via-white/90 to-transparent pointer-events-none" />
                        )}
                    </div>

                    {/* Show more / Show less */}
                    <div className="flex justify-center mt-[-16px] relative z-10">
                        <button
                            onClick={() => setExpanded(!expanded)}
                            className="inline-flex items-center gap-1.5 px-5 py-2.5 rounded-full bg-white border border-brand-border text-sm font-semibold text-brand-primary shadow-sm hover:shadow-md hover:border-brand-accent/30 transition-all duration-200"
                        >
                            {expanded ? (
                                <>
                                    Show less <ChevronUp className="w-4 h-4" />
                                </>
                            ) : (
                                <>
                                    Show more features <ChevronDown className="w-4 h-4" />
                                </>
                            )}
                        </button>
                    </div>
                </div>
            </div>
        </section>
    );
}
