"use client";

import { motion } from "framer-motion";
import { Lock, Key, UserCheck } from "lucide-react";

export default function PrivacyPromise() {
    const points = [
        {
            icon: <Lock strokeWidth={1.5} size={32} />,
            title: "Private by Default",
            text: "Your profile and trips are yours. Zero tracking. Zero broadcasting.",
        },
        {
            icon: <Key strokeWidth={1.5} size={32} />,
            title: "Invite Only",
            text: "Private trips are accessible only via unique links or codes.",
        },
        {
            icon: <UserCheck strokeWidth={1.5} size={32} />,
            title: "Approval Required",
            text: "You decide who follows you and who joins your journey.",
        },
    ];

    return (
        <section className="py-24 md:py-40 bg-brand-bg relative overflow-hidden text-center">
            <div className="container mx-auto px-6 relative z-10">
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    className="max-w-3xl mx-auto mb-24"
                >
                    <h2 className="font-serif text-5xl md:text-6xl text-brand-primary mb-6">
                        Built for small circles.
                    </h2>
                    <div className="w-20 h-1 bg-brand-accent mx-auto mb-8 rounded-full opacity-80" />
                    <p className="text-lg md:text-xl text-brand-text/80 font-light">
                        Every follow, every join request — your approval first.
                    </p>
                </motion.div>

                <div className="grid md:grid-cols-3 gap-16 max-w-6xl mx-auto">
                    {points.map((item, index) => (
                        <motion.div
                            key={index}
                            initial={{ opacity: 0, y: 20 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            viewport={{ once: true }}
                            transition={{ delay: index * 0.1, duration: 0.6 }}
                            className="flex flex-col items-center group"
                        >
                            <div className="w-24 h-24 rounded-full border border-brand-primary/10 flex items-center justify-center text-brand-primary mb-8 group-hover:border-brand-accent/50 group-hover:text-brand-accent transition-colors duration-500 bg-white">
                                {item.icon}
                            </div>
                            <h3 className="font-serif text-3xl text-brand-primary mb-5">
                                {item.title}
                            </h3>
                            <p className="text-base text-brand-text/70 leading-relaxed font-light px-4">
                                {item.text}
                            </p>
                        </motion.div>
                    ))}
                </div>
            </div>
        </section>
    );
}
