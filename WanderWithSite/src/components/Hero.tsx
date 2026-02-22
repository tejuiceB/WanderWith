"use client";

import { motion } from "framer-motion";
import { ArrowRight } from "lucide-react";
import Image from "next/image";

export default function Hero() {
    return (
        <section className="relative h-screen min-h-[600px] flex items-center justify-center overflow-hidden">
            {/* Background Image with Overlay */}
            <div className="absolute inset-0 z-0">
                <Image
                    src="/assets/hero-friends.jpg"
                    alt="Friends traveling in India"
                    fill
                    className="object-cover object-center"
                    priority
                />
                <div className="absolute inset-0 bg-black/50 backdrop-blur-[1px]" />
                <div className="absolute inset-0 bg-gradient-to-b from-black/60 via-transparent to-[#F7F3EC]" />
            </div>

            <div className="container mx-auto px-6 relative z-10 text-center text-white">
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.8, ease: "easeOut" }}
                >
                    <h1 className="font-serif text-6xl md:text-8xl lg:text-9xl font-medium tracking-tight mb-8 drop-shadow-lg">
                        Your trip. <br />
                        <span className="italic">Not the internet’s.</span>
                    </h1>

                    <div className="max-w-lg mx-auto mb-12">
                        <p className="text-base md:text-lg text-white/95 font-light leading-relaxed drop-shadow-md mb-6">
                            Plan privately. Travel intentionally.
                        </p>
                        <p className="text-sm text-white/80 font-medium tracking-wide border-t border-white/20 pt-6">
                            Most travel apps are built for sharing. <br />
                            <span className="text-brand-accent">WanderWith is built for keeping it personal.</span>
                        </p>
                    </div>

                    <div className="flex flex-col sm:flex-row gap-4 justify-center items-center mt-10">
                        <button className="px-8 py-4 bg-brand-accent text-white rounded-full font-medium hover:bg-[#B45309] transition-colors shadow-lg shadow-brand-accent/20 flex items-center gap-2">
                            Start Planning Privately
                            <ArrowRight size={18} />
                        </button>
                        <button
                            onClick={() => document.getElementById('agencies')?.scrollIntoView({ behavior: 'smooth' })}
                            className="px-8 py-4 bg-white/10 backdrop-blur-md border border-white/30 text-white rounded-full font-medium hover:bg-white/20 transition-colors flex items-center gap-2"
                        >
                            Explore Public Trips
                            <ArrowRight size={18} />
                        </button>
                    </div>

                    <p className="mt-8 text-sm text-white/70 font-light tracking-wide flex items-center justify-center gap-2">
                        <span className="w-1.5 h-1.5 bg-green-400 rounded-full animate-pulse" />
                        Early travel communities in India are already planning privately.
                    </p>


                </motion.div>
            </div>
        </section>
    );
}
