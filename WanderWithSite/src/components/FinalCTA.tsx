"use client";

import { motion } from "framer-motion";

export default function FinalCTA() {
    return (
        <section className="py-24 md:py-40 bg-brand-bg text-center">
            <div className="container mx-auto px-6">
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    className="max-w-3xl mx-auto"
                >
                    <h2 className="font-serif text-6xl md:text-8xl text-brand-primary mb-10">
                        Your next trip doesn’t need an audience.
                    </h2>
                    <div className="w-24 h-1 bg-brand-accent mx-auto mb-10 rounded-full opacity-80" />
                    <p className="text-xl text-brand-text/80 mb-12 font-light italic">
                        &quot;Some memories are better kept between friends.&quot;
                    </p>

                    <button className="px-12 py-5 bg-brand-accent text-white rounded-full font-medium hover:bg-[#B45309] transition-colors shadow-lg shadow-brand-accent/20 text-xl flex items-center gap-3 mx-auto">
                        👉 Plan Your First Private Trip
                    </button>

                    <p className="mt-6 text-sm text-brand-text/60 font-medium tracking-wide">
                        Currently rolling out to early members.
                    </p>
                </motion.div>
            </div>
        </section>
    );
}
