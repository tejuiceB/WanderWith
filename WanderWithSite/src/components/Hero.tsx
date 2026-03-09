"use client";

import { motion } from "framer-motion";
import PhoneMockup from "./PhoneMockup";
import { GooglePlayBadge, AppStoreBadge } from "./StoreBadges";

export default function Hero() {
    return (
        <section className="relative bg-gradient-to-b from-brand-bg via-brand-bg to-brand-bg-alt pt-28 pb-20 md:pt-36 md:pb-28 overflow-hidden">
            {/* Decorative gradient orbs */}
            <div className="absolute top-20 left-1/4 w-[500px] h-[500px] bg-brand-accent/[0.06] rounded-full blur-[120px] pointer-events-none" />
            <div className="absolute bottom-0 right-1/4 w-[400px] h-[400px] bg-brand-purple/[0.05] rounded-full blur-[100px] pointer-events-none" />

            <div className="relative max-w-7xl mx-auto px-5 md:px-8">
                <div className="flex flex-col lg:flex-row items-center gap-12 lg:gap-20">
                    {/* Left copy */}
                    <div className="flex-1 text-center lg:text-left max-w-2xl">
                        <motion.div
                            initial={{ opacity: 0, y: 12 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ type: "spring", stiffness: 100, damping: 20 }}
                            className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-brand-accent/8 border border-brand-accent/15 text-brand-accent text-sm font-medium tracking-wide mb-6"
                        >
                            <span className="w-1.5 h-1.5 rounded-full bg-brand-accent animate-pulse" />
                            Your travel, beautifully organized
                        </motion.div>

                        <motion.h1
                            initial={{ opacity: 0, y: 24 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ type: "spring", stiffness: 80, damping: 20, delay: 0.1 }}
                            className="font-sans font-bold text-[2.5rem] sm:text-5xl md:text-6xl lg:text-[4.25rem] text-brand-primary leading-[1.08] tracking-tight mb-6"
                        >
                            Plan your perfect trip,{" "}
                            <span className="bg-gradient-to-r from-brand-accent to-brand-purple bg-clip-text text-transparent">together.</span>
                        </motion.h1>

                        <motion.p
                            initial={{ opacity: 0, y: 24 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ type: "spring", stiffness: 80, damping: 20, delay: 0.2 }}
                            className="text-lg md:text-xl text-brand-text-secondary leading-relaxed mb-10 max-w-xl mx-auto lg:mx-0"
                        >
                            The modern trip planner for solo travellers, groups and travel agencies. AI itineraries, group chats, budgets, polls, all in one app.
                        </motion.p>

                        <motion.div
                            initial={{ opacity: 0, y: 24 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ type: "spring", stiffness: 80, damping: 20, delay: 0.3 }}
                            className="flex flex-wrap gap-4 justify-center lg:justify-start items-center"
                        >
                            <GooglePlayBadge />
                            <AppStoreBadge comingSoon />
                        </motion.div>

                        <motion.p
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            transition={{ duration: 0.6, delay: 0.6 }}
                            className="mt-6 text-sm text-brand-text-tertiary"
                        >
                            Free on Android. No ads, no hidden fees.
                        </motion.p>
                    </div>

                    {/* Right phone mockup */}
                    <motion.div
                        initial={{ opacity: 0, scale: 0.92, y: 40 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        transition={{ type: "spring", stiffness: 60, damping: 18, delay: 0.25 }}
                        className="flex-shrink-0"
                    >
                        <PhoneMockup className="w-[260px] sm:w-[280px] md:w-[300px]">
                            <video
                                autoPlay
                                muted
                                loop
                                playsInline
                                className="absolute inset-0 w-full h-full object-cover"
                                poster="/app_images/trip planner poster.jpg"
                            >
                                <source src="/app_images/trip planner.mp4" type="video/mp4" />
                            </video>
                        </PhoneMockup>
                    </motion.div>
                </div>
            </div>
        </section>
    );
}
