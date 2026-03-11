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
                                src="https://images.unsplash.com/photo-1539635278303-d4002c07eae3?q=80&w=2070&auto=format&fit=crop"
                                alt="Friends planning a trip together with WanderWith"
                                fill
                                className="object-cover grayscale hover:grayscale-0 transition-all duration-700"
                            />
                        </div>
                    </div>

                    <div className="md:w-1/2 text-center md:text-left">
                        <h2 className="font-serif text-4xl text-brand-primary mb-8">
                            Travel should connect us,<br />
                            <span className="italic text-brand-accent">not overwhelm us.</span>
                        </h2>

                        <div className="space-y-6 text-lg text-brand-text font-light leading-relaxed">
                            <p>
                                WanderWith was built because planning trips with friends felt messy, scattered, and way too complicated.
                            </p>
                            <p>
                                We missed the simple joy of traveling without the chaos of endless group chats and forgotten spreadsheets.
                                WanderWith is a quiet space for those who want to explore with intention.
                            </p>
                        </div>

                        <div className="mt-10">
                            <p className="font-serif text-xl text-brand-primary">WanderWith Team</p>
                            <p className="text-sm text-brand-text/60 uppercase tracking-widest mt-1">Made in India</p>
                            <a href="mailto:wanderwithplan@gmail.com" className="text-sm text-brand-accent hover:underline mt-2 block">wanderwithplan@gmail.com</a>
                        </div>
                    </div>
                </motion.div>
            </div>
        </section>
    );
}
