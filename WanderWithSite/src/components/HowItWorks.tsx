"use client";

import { motion } from "framer-motion";
import { Search, UserPlus, MapPin } from "lucide-react";

export default function HowItWorks() {
    const steps = [
        {
            icon: <Search strokeWidth={1.5} />,
            title: "Create or Discover",
            desc: "Start a private group trip or find a curated journey.",
        },
        {
            icon: <UserPlus strokeWidth={1.5} />,
            title: "Request to Join",
            desc: "Send a request to joining a trip. Trust is our priority.",
        },
        {
            icon: <MapPin strokeWidth={1.5} />,
            title: "Travel Together",
            desc: "Plan details, chat with the group, and explore safely.",
        },
    ];

    return (
        <section id="how-it-works" className="py-24 md:py-40 bg-white">
            <div className="container mx-auto px-6">
                <div className="grid md:grid-cols-3 gap-16 max-w-7xl mx-auto">
                    {steps.map((step, index) => (
                        <motion.div
                            key={index}
                            initial={{ opacity: 0, y: 20 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            viewport={{ once: true }}
                            transition={{ delay: index * 0.2, duration: 0.6 }}
                            className="flex flex-col items-center text-center group"
                        >
                            <div className="w-20 h-20 rounded-full border border-brand-text/10 flex items-center justify-center text-brand-text mb-8 group-hover:border-brand-accent group-hover:text-brand-accent transition-colors duration-300">
                                <div className="w-10 h-10 flex items-center justify-center">
                                    {step.icon}
                                </div>
                            </div>

                            <span className="block text-brand-terracotta font-serif text-xl mb-3">0{index + 1}</span>
                            <h3 className="text-2xl font-bold text-brand-primary mb-4">
                                {step.title}
                            </h3>
                            <p className="text-base text-brand-text/70 leading-relaxed font-light">
                                {step.desc}
                            </p>
                        </motion.div>
                    ))}
                </div>
            </div>
        </section>
    );
}
