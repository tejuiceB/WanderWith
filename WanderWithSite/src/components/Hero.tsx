"use client";

import { motion } from "framer-motion";
import { Sparkles, Navigation, Users, Briefcase, MessageSquare, Link, Wallet } from "lucide-react";
import Image from "next/image";

export default function Hero() {
    return (
        <section className="relative min-h-screen bg-[#F9FAFB] pt-24 pb-16 px-4 md:px-6 flex flex-col items-center">

            {/* The main Entraw-style rounded container */}
            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.8 }}
                className="relative w-full max-w-7xl h-[75vh] min-h-[500px] rounded-[2.5rem] overflow-hidden shadow-2xl flex flex-col justify-end"
            >
                {/* Background Image */}
                <Image
                    src="/assets/hero.jpg"
                    alt="WanderWith - Trip Planner for Solo, Groups and Travel Agencies"
                    fill
                    className="object-cover object-center"
                    priority
                    sizes="(max-width: 768px) 100vw, 1280px"
                />

                {/* Gradient overlays for text readability */}
                <div className="absolute inset-0 bg-black/20" />
                <div className="absolute inset-0 bg-gradient-to-t from-black/95 via-black/40 to-transparent" />

                {/* Content Overlay */}
                <div className="relative z-10 p-6 md:p-12 lg:p-16 flex flex-col items-center text-center w-full">

                    {/* Badge Pill */}
                    <motion.div
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: 0.2, duration: 0.6 }}
                        className="mb-6 px-4 py-1.5 bg-black/40 backdrop-blur-md rounded-full border border-white/20 flex items-center gap-2"
                    >
                        <Image src="/logo.png" alt="WanderWith" width={20} height={20} className="w-5 h-5 rounded-full object-cover" />
                        <span className="text-sm font-medium text-white/90 tracking-wide">by WanderWith</span>
                    </motion.div>

                    {/* Main H1 - Uppercase, bold, large */}
                    <motion.div
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: 0.3, duration: 0.8 }}
                        className="w-full flex flex-col items-center"
                    >
                        <h1 className="font-sans font-black text-4xl sm:text-5xl md:text-6xl lg:text-[5rem] text-white uppercase tracking-tight leading-[1.05] max-w-5xl mb-6">
                            A Modern Trip Planner <br className="hidden md:block" />
                            For Solo, Groups & Agencies
                        </h1>

                        <h2 className="text-lg md:text-xl text-white/90 font-medium max-w-3xl mb-12 leading-relaxed">
                            The best online itinerary builder and travel planner app. Organize trips, manage group chats, track budgets, and share links effortlessly.
                        </h2>

                        {/* CTA Buttons */}
                        <div className="flex flex-col sm:flex-row gap-5 items-center">
                            <a
                                href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="group px-8 py-4 bg-white text-brand-primary rounded-full font-bold hover:bg-brand-accent hover:text-white transition-all duration-300 flex items-center gap-3 text-[15px] shadow-2xl hover:shadow-brand-accent/30 hover:-translate-y-1"
                            >
                                <Image
                                    src="/assets/icons8-google-play-store-100.png"
                                    alt="Play Store"
                                    width={22}
                                    height={22}
                                    className="group-hover:grayscale-0 transition-all duration-300"
                                />
                                Get the App Free
                            </a>
                            <div className="px-8 py-4 bg-black/20 backdrop-blur-md text-white rounded-full font-semibold flex items-center gap-3 text-[15px] border border-white/10 hover:bg-black/40 transition-all cursor-default shadow-lg">
                                <Image
                                    src="/assets/icons8-app-store-100.png"
                                    alt="App Store"
                                    width={22}
                                    height={22}
                                    className="invert opacity-80"
                                />
                                iOS Coming Soon
                            </div>
                        </div>
                    </motion.div>
                </div>
            </motion.div>

            {/* Feature Highlights Grid */}
            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.6, duration: 0.6 }}
                className="w-full max-w-7xl mt-8 grid grid-cols-1 md:grid-cols-3 gap-4"
            >
                {/* Feature 1 */}
                <div className="bg-white p-6 rounded-3xl flex flex-col gap-4 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.1)] border border-gray-100 hover:border-gray-200 transition-colors">
                    <div className="flex items-center gap-3">
                        <div className="p-3 bg-brand-accent/10 text-brand-accent rounded-xl">
                            <Navigation className="w-5 h-5" />
                        </div>
                        <h3 className="font-bold text-gray-900 text-lg">Solo Travellers</h3>
                    </div>
                    <p className="text-gray-500 text-sm leading-relaxed">
                        Discover hidden gems, generate AI itineraries instantly, and keep all your bookings and links in one private space.
                    </p>
                </div>

                {/* Feature 2 */}
                <div className="bg-white p-6 rounded-3xl flex flex-col gap-4 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.1)] border border-gray-100 hover:border-gray-200 transition-colors">
                    <div className="flex items-center gap-3">
                        <div className="p-3 bg-brand-violet/10 text-brand-violet rounded-xl">
                            <Users className="w-5 h-5" />
                        </div>
                        <h3 className="font-bold text-gray-900 text-lg">Group Trips</h3>
                    </div>
                    <p className="text-gray-500 text-sm leading-relaxed">
                        Say goodbye to messy chats. Manage group chats, vote on plans, split expenses fairly, and travel without the chaos.
                    </p>
                    <div className="flex gap-2 mt-auto pt-2">
                        <span className="flex items-center gap-1 text-[11px] font-medium text-gray-500 bg-gray-50 px-2 py-1 rounded-md border border-gray-100"><MessageSquare className="w-3 h-3" /> Chats</span>
                        <span className="flex items-center gap-1 text-[11px] font-medium text-gray-500 bg-gray-50 px-2 py-1 rounded-md border border-gray-100"><Wallet className="w-3 h-3" /> Budgets</span>
                    </div>
                </div>

                {/* Feature 3 */}
                <div className="bg-white p-6 rounded-3xl flex flex-col gap-4 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.1)] border border-gray-100 hover:border-gray-200 transition-colors">
                    <div className="flex items-center gap-3">
                        <div className="p-3 bg-brand-amber/10 text-brand-amber rounded-xl">
                            <Briefcase className="w-5 h-5" />
                        </div>
                        <h3 className="font-bold text-gray-900 text-lg">Travel Agencies</h3>
                    </div>
                    <p className="text-gray-500 text-sm leading-relaxed">
                        Create beautiful trip packages, share itinerary links seamlessly, and give your clients a modern travel experience.
                    </p>
                    <div className="flex gap-2 mt-auto pt-2">
                        <span className="flex items-center gap-1 text-[11px] font-medium text-gray-500 bg-gray-50 px-2 py-1 rounded-md border border-gray-100"><Link className="w-3 h-3" /> Share Links</span>
                    </div>
                </div>
            </motion.div>
        </section>
    );
}
