"use client";

import { motion } from "framer-motion";

export default function PrivateSpace() {
    return (
        <section className="bg-brand-primary py-32 px-6 text-center">
            <div className="container mx-auto max-w-5xl">
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.8 }}
                >
                    <h2 className="font-serif text-5xl md:text-7xl lg:text-8xl text-white mb-8 leading-tight">
                        Not everything needs to be public.
                    </h2>
                    <div className="w-24 h-1 bg-brand-accent mx-auto mb-10 rounded-full opacity-80" />
                    <p className="text-lg md:text-xl text-white/80 font-light max-w-3xl mx-auto leading-relaxed">
                        WanderWith gives you a private space to plan, chat, and travel — without broadcasting it to the world.
                    </p>
                </motion.div>
            </div>
        </section>
    );
}
