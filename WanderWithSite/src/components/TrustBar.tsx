"use client";

import { motion } from "framer-motion";
import { Star, MapPin, Building2, Flag } from "lucide-react";

const stats = [
    { icon: Star, label: "4.8 Rating", color: "text-amber-500" },
    { icon: MapPin, label: "500+ Trips Planned", color: "text-brand-accent" },
    { icon: Building2, label: "100+ Agencies", color: "text-brand-purple" },
    { icon: Flag, label: "Made in India", color: "text-brand-green" },
];

export default function TrustBar() {
    return (
        <section className="bg-brand-bg-alt border-y border-brand-border py-6">
            <div className="max-w-7xl mx-auto px-5 md:px-8">
                <motion.div
                    initial={{ opacity: 0, y: 10 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.5 }}
                    className="flex flex-wrap items-center justify-center gap-6 md:gap-12"
                >
                    {stats.map((stat) => (
                        <div key={stat.label} className="flex items-center gap-2.5">
                            <stat.icon className={`w-5 h-5 ${stat.color}`} />
                            <span className="text-sm font-semibold text-brand-text-secondary tracking-wide">
                                {stat.label}
                            </span>
                        </div>
                    ))}
                </motion.div>
            </div>
        </section>
    );
}
