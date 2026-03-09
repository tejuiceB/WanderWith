"use client";

import { motion } from "framer-motion";
import { ArrowRight } from "lucide-react";
import { GooglePlayBadge, AppStoreBadge } from "./StoreBadges";

export default function FinalCTA() {
    return (
        <section className="relative bg-brand-dark py-24 md:py-32 overflow-hidden">
            {/* Background glow */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] rounded-full bg-brand-accent/5 blur-[120px] pointer-events-none" />

            <div className="relative max-w-4xl mx-auto px-5 md:px-8 text-center">
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ type: "spring", stiffness: 80, damping: 20 }}
                >
                    <h2 className="font-sans font-bold text-3xl sm:text-4xl md:text-[3.5rem] text-white tracking-tight leading-tight mb-6">
                        Ready to plan your next trip?
                    </h2>
                    <p className="text-brand-text-tertiary text-lg md:text-xl max-w-2xl mx-auto mb-10 leading-relaxed">
                        Download WanderWith for free and start planning your next adventure with friends, family, or solo.
                    </p>

                    <div className="flex flex-col sm:flex-row gap-4 justify-center items-center mb-6">
                        <GooglePlayBadge />
                        <AppStoreBadge />
                    </div>

                    <div className="flex flex-col sm:flex-row gap-3 justify-center items-center">
                        <a
                            href="mailto:wanderwithplan@gmail.com"
                            className="inline-flex items-center justify-center gap-2 px-6 py-3 rounded-full font-medium text-sm text-white/70 border border-brand-dark-border hover:border-white/30 hover:text-white transition-all duration-300"
                        >
                            Contact Us
                            <ArrowRight className="w-3.5 h-3.5" />
                        </a>
                    </div>

                    <p className="mt-8 text-sm text-brand-text-tertiary">
                        Free on Android &middot; iOS coming soon
                    </p>
                </motion.div>
            </div>
        </section>
    );
}
