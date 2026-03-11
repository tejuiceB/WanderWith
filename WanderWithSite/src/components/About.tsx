"use client";

import { motion } from "framer-motion";
import { MapPin, Users, Sparkles, Heart } from "lucide-react";

const values = [
    {
        icon: MapPin,
        title: "Born from real trips",
        text: "We got tired of scattered WhatsApp groups, forgotten Google Sheets, and the friend who never shared their photos. So we built what we wished existed.",
    },
    {
        icon: Users,
        title: "Made for real groups",
        text: "Whether it's 2 best friends or 20 college mates, WanderWith keeps everyone on the same page with polls, budgets, chats, and shared itineraries.",
    },
    {
        icon: Sparkles,
        title: "AI that actually helps",
        text: "Our AI doesn't just list tourist traps. It suggests hidden gems, builds day-by-day plans, and adapts to your travel style. Like having a local friend everywhere.",
    },
    {
        icon: Heart,
        title: "Free, forever",
        text: "No ads. No premium walls. No selling your data. WanderWith is free because we believe great trip planning shouldn't cost anything.",
    },
];

export default function About() {
    return (
        <section id="about" className="bg-brand-bg py-24 md:py-32">
            <div className="max-w-6xl mx-auto px-5 md:px-8">
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ type: "spring", stiffness: 80, damping: 20 }}
                    className="text-center mb-16"
                >
                    <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3">Our Story</p>
                    <h2 className="font-serif font-bold text-3xl sm:text-4xl md:text-5xl text-brand-primary tracking-tight mb-5">
                        We just wanted to go on a trip<br className="hidden sm:block" /> without the chaos
                    </h2>
                    <p className="text-brand-text-secondary text-lg max-w-2xl mx-auto leading-relaxed">
                        Every group trip starts exciting and ends with &quot;who booked what?&quot; and &quot;send me that photo.&quot;
                        We built WanderWith so the only thing you worry about is having fun.
                    </p>
                </motion.div>

                <div className="grid sm:grid-cols-2 gap-6 md:gap-8 mb-14">
                    {values.map((v, i) => (
                        <motion.div
                            key={v.title}
                            initial={{ opacity: 0, y: 24 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            viewport={{ once: true }}
                            transition={{ type: "spring", stiffness: 100, damping: 20, delay: i * 0.08 }}
                            className="flex gap-4 p-6 rounded-2xl border border-brand-border bg-brand-card"
                        >
                            <div className="shrink-0 w-10 h-10 rounded-xl bg-brand-accent/10 flex items-center justify-center">
                                <v.icon className="w-5 h-5 text-brand-accent" />
                            </div>
                            <div>
                                <h3 className="font-semibold text-brand-primary text-base mb-1.5">{v.title}</h3>
                                <p className="text-brand-text-secondary text-[14px] leading-relaxed">{v.text}</p>
                            </div>
                        </motion.div>
                    ))}
                </div>

                <motion.div
                    initial={{ opacity: 0, y: 16 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ type: "spring", stiffness: 80, damping: 20 }}
                    className="text-center"
                >
                    <p className="text-brand-text-tertiary text-sm mb-2">Made with love in India</p>
                    <a
                        href="mailto:wanderwithplan@gmail.com"
                        className="text-sm text-brand-accent font-medium hover:underline"
                    >
                        wanderwithplan@gmail.com
                    </a>
                </motion.div>
            </div>
        </section>
    );
}
