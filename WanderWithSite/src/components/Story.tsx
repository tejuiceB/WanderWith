"use client";

import { motion } from "framer-motion";

export default function Story() {
    return (
        <section id="about" className="py-24 md:py-40 bg-brand-bg text-center px-6">
            <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.8 }}
                className="max-w-4xl mx-auto"
            >
                <h2 className="font-serif text-5xl md:text-7xl lg:text-8xl text-brand-primary leading-tight mb-10">
                    Travel today is loud. <br />
                    <span className="text-brand-text opacity-60">WanderWith brings back intention.</span>
                </h2>
                <div className="w-20 h-1 bg-brand-accent mx-auto mb-12 rounded-full opacity-80" />
                <p className="text-lg md:text-xl text-brand-text font-light leading-relaxed max-w-3xl mx-auto">
                    Group chats get messy. Social feeds turn trips into content. WanderWith keeps your journey between the people who matter.
                </p>
            </motion.div>
        </section>
    );
}
