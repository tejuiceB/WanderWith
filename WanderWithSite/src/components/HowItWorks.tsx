"use client";

import { motion } from "framer-motion";
import { Download, Sparkles, Plane } from "lucide-react";

const steps = [
    {
        num: "01",
        icon: Download,
        title: "Download the app",
        desc: "Get WanderWith free on Android. Sign up in seconds with Google. No forms, no fuss.",
        gradient: "from-indigo-500 to-violet-500",
    },
    {
        num: "02",
        icon: Sparkles,
        title: "Plan with AI",
        desc: "Tell the AI where you want to go. It builds a full itinerary with stays, places, and budget instantly.",
        gradient: "from-violet-500 to-purple-500",
    },
    {
        num: "03",
        icon: Plane,
        title: "Travel together",
        desc: "Invite friends, chat in the trip, vote on plans, split costs, and make memories. All in one place.",
        gradient: "from-purple-500 to-pink-500",
    },
];

export default function HowItWorks() {
    return (
        <section id="how-it-works" className="bg-brand-dark py-24 md:py-32 relative overflow-hidden">
            {/* Background decorations */}
            <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[800px] h-[800px] bg-brand-accent/[0.03] rounded-full blur-[120px] pointer-events-none" />

            <div className="relative max-w-7xl mx-auto px-5 md:px-8">
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ type: "spring", stiffness: 80, damping: 20 }}
                    className="text-center mb-16"
                >
                    <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3">How It Works</p>
                    <h2 className="font-serif font-bold text-3xl sm:text-4xl md:text-5xl text-white tracking-tight mb-4">
                        Three steps to your next adventure
                    </h2>
                    <p className="text-brand-text-tertiary text-lg max-w-2xl mx-auto">
                        No learning curve. No setup headaches. Just download, plan, and go.
                    </p>
                </motion.div>

                <div className="grid md:grid-cols-3 gap-8 relative">
                    {/* Connecting line (desktop) */}
                    <div className="hidden md:block absolute top-[100px] left-[16.6%] right-[16.6%] h-px bg-gradient-to-r from-brand-accent/30 via-brand-purple/30 to-brand-rose/30" />

                    {steps.map((step, i) => (
                        <motion.div
                            key={step.num}
                            initial={{ opacity: 0, y: 30 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            viewport={{ once: true }}
                            transition={{ type: "spring", stiffness: 80, damping: 20, delay: i * 0.15 }}
                            className="relative p-8 rounded-2xl border border-brand-dark-border bg-brand-dark-secondary/40 text-center backdrop-blur-sm"
                        >
                            {/* Step number with gradient */}
                            <div className={`mx-auto w-14 h-14 rounded-2xl bg-gradient-to-br ${step.gradient} flex items-center justify-center mb-6 shadow-lg`}>
                                <step.icon className="w-6 h-6 text-white" />
                            </div>
                            <span className="block text-xs font-bold text-brand-text-tertiary tracking-widest uppercase mb-3">
                                Step {step.num}
                            </span>
                            <h3 className="font-semibold text-xl text-white mb-3">{step.title}</h3>
                            <p className="text-brand-text-tertiary text-[15px] leading-relaxed">{step.desc}</p>
                        </motion.div>
                    ))}
                </div>
            </div>
        </section>
    );
}
