"use client";

import { motion } from "framer-motion";
import { ArrowRight, Users, Building2 } from "lucide-react";
import Image from "next/image";

export default function Experience() {
    return (
        <section className="py-20 md:py-32 space-y-40">
            {/* Block 1: For Friends */}
            <div id="travelers" className="container mx-auto px-6">
                <div className="flex flex-col lg:flex-row items-center gap-12 md:gap-20">
                    <motion.div
                        initial={{ opacity: 0, x: -20 }}
                        whileInView={{ opacity: 1, x: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.8 }}
                        className="lg:w-1/2 relative"
                    >
                        <div className="relative aspect-[4/5] w-full overflow-hidden rounded-sm shadow-xl">
                            <Image
                                src="https://images.unsplash.com/photo-1529156069898-49953e39b3ac?q=80&w=2532&auto=format&fit=crop"
                                alt="Friends traveling together"
                                fill
                                className="object-cover"
                            />
                        </div>
                        {/* Decorative Offset Border */}
                        <div className="absolute top-6 left-6 w-full h-full border border-brand-primary/20 -z-10 rounded-sm" />
                    </motion.div>

                    <motion.div
                        initial={{ opacity: 0, x: 20 }}
                        whileInView={{ opacity: 1, x: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.8 }}
                        className="lg:w-1/2"
                    >
                        <div className="bg-brand-card p-10 md:p-14 rounded-sm border-l-4 border-brand-teal">
                            <h2 className="font-serif text-4xl md:text-5xl text-brand-primary mb-6">
                                Your circle. Your trip.
                            </h2>
                            <div className="w-16 h-1 bg-brand-accent mb-8 rounded-full opacity-80" />
                            <p className="text-base md:text-lg text-brand-text mb-10 leading-relaxed font-light">
                                No public feeds. No random followers. Just your itinerary, your chat, and your circle. A private space for what matters.
                            </p>

                            <ul className="space-y-5 mb-10">
                                {[
                                    "Invite-only trip space",
                                    "Shared plans & budget clarity",
                                    "You decide who sees what",
                                    "No random followers"
                                ].map((item, i) => (
                                    <li key={i} className="flex items-center gap-3 text-brand-text text-base">
                                        <div className="w-1.5 h-1.5 bg-brand-teal rounded-full" />
                                        {item}
                                    </li>
                                ))}
                            </ul>

                            <button className="text-brand-teal font-medium flex items-center gap-2 hover:gap-3 transition-all text-lg">
                                Explore Traveler Features <ArrowRight size={18} />
                            </button>
                        </div>
                    </motion.div>
                </div>
            </div>

            {/* Block 2: For Agencies */}
            <div id="agencies" className="container mx-auto px-6">
                <div className="flex flex-col-reverse lg:flex-row items-center gap-12 md:gap-20">
                    <motion.div
                        initial={{ opacity: 0, x: -20 }}
                        whileInView={{ opacity: 1, x: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.8 }}
                        className="lg:w-1/2"
                    >
                        <div className="bg-brand-card p-10 md:p-14 rounded-sm border-l-4 border-brand-terracotta">
                            <h2 className="font-serif text-4xl md:text-5xl text-brand-primary mb-8">
                                Turn journeys into communities.
                            </h2>
                            <div className="w-16 h-1 bg-brand-terracotta mb-8 rounded-full opacity-80" />
                            <p className="text-base md:text-lg text-brand-text mb-10 leading-relaxed font-light">
                                For travel agencies and creators who want to build deeper connections. Showcase your curated trips to a high-intent audience.
                            </p>

                            <ul className="space-y-5 mb-10">
                                {[
                                    "Publish curated trip packages",
                                    "Receive qualified join requests",
                                    "Build a trusted travel audience",
                                    "Manage bookings seamlessly"
                                ].map((item, i) => (
                                    <li key={i} className="flex items-center gap-3 text-brand-text text-base">
                                        <div className="w-1.5 h-1.5 bg-brand-terracotta rounded-full" />
                                        {item}
                                    </li>
                                ))}
                            </ul>

                            <button className="text-brand-terracotta font-medium flex items-center gap-2 hover:gap-3 transition-all text-lg">
                                Agency Tools <ArrowRight size={18} />
                            </button>
                        </div>
                    </motion.div>

                    <motion.div
                        initial={{ opacity: 0, x: 20 }}
                        whileInView={{ opacity: 1, x: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.8 }}
                        className="lg:w-1/2 relative"
                    >
                        <div className="relative aspect-[4/5] w-full overflow-hidden rounded-sm shadow-xl">
                            <Image
                                src="https://images.unsplash.com/photo-1598324789736-4861f89564a0?q=80&w=2070&auto=format&fit=crop"
                                alt="Rajasthan Desert Safari Camp"
                                fill
                                className="object-cover"
                            />
                        </div>
                        {/* Decorative Offset Border */}
                        <div className="absolute bottom-6 right-6 w-full h-full border border-brand-primary/20 -z-10 rounded-sm" />
                    </motion.div>
                </div>
            </div>
        </section>
    );
}
