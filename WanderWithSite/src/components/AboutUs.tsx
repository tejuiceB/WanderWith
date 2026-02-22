"use client";

import { motion } from "framer-motion";
import Image from "next/image";

export default function AboutUs() {
    return (
        <section className="py-32 bg-brand-bg">
            <div className="container mx-auto px-6">
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    className="max-w-5xl mx-auto flex flex-col md:flex-row items-center gap-16"
                >
                    <div className="md:w-1/2 relative">
                        <div className="relative aspect-[3/4] w-full max-w-sm mx-auto overflow-hidden rounded-sm shadow-xl">
                            <Image
                                src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=1887&auto=format&fit=crop"
                                alt="Tejas Bhurbhure, Founder of WanderWith"
                                fill
                                className="object-cover grayscale hover:grayscale-0 transition-all duration-700"
                            />
                        </div>
                    </div>

                    <div className="md:w-1/2 text-center md:text-left">
                        <h2 className="font-serif text-4xl text-brand-primary mb-8">
                            Travel should connect us,<br />
                            <span className="italic text-brand-accent">not perform for us.</span>
                        </h2>

                        <div className="space-y-6 text-lg text-brand-text font-light leading-relaxed">
                            <p>
                                Hi, I&apos;m Tejas. I built WanderWith because planning trips with friends felt messy and too public.
                            </p>
                            <p>
                                I missed the simple joy of traveling without broadcasting it to the world.
                                We&apos;re building a quiet space for those who want to explore India (and beyond) with intention.
                            </p>
                        </div>

                        <div className="mt-10">
                            <p className="font-serif text-xl text-brand-primary">Tejas Bhurbhure</p>
                            <p className="text-sm text-brand-text/60 uppercase tracking-widest mt-1">Founder</p>
                        </div>
                    </div>
                </motion.div>
            </div>
        </section>
    );
}
