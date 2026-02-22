"use client";

import { motion } from "framer-motion";
import Image from "next/image";
import { Sparkles, MapPin, Calendar, Info } from "lucide-react";

export default function AIPlanningShowcase() {
    const planningSteps = [
        {
            step: 1,
            title: "Generate Your Plan",
            description: "Click 'Plan with AI' and watch as our intelligent system starts crafting a personalized itinerary based on your destination.",
            screenshot: "/app_images/AI-Plan_1.jpeg",
            icon: Sparkles,
            badge: "AI Powered"
        },
        {
            step: 2,
            title: "Smart Itinerary Created",
            description: "Get a complete day-by-day plan with activities, timings, and recommendations tailored to your trip dates and preferences.",
            screenshot: "/app_images/AI-Plan_2.jpeg",
            icon: Calendar,
            badge: "Personalized"
        },
        {
            step: 3,
            title: "Explore Place Details",
            description: "Tap any location to discover rich information, photos, and insider tips about each destination in your itinerary.",
            screenshot: "/app_images/AI-Plan_3.jpeg",
            icon: Info,
            badge: "Detailed"
        }
    ];

    return (
        <section className="relative py-32 bg-gradient-to-br from-purple-50 via-blue-50 to-indigo-50 overflow-hidden">
            {/* Animated Background Elements */}
            <div className="absolute inset-0 opacity-40">
                <div className="absolute top-0 left-1/4 w-96 h-96 bg-purple-400/20 rounded-full blur-3xl animate-pulse" />
                <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-blue-400/20 rounded-full blur-3xl animate-pulse" style={{ animationDelay: '1s' }} />
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-indigo-400/10 rounded-full blur-3xl" />
            </div>

            {/* Sparkle Decorations */}
            <div className="absolute inset-0 overflow-hidden pointer-events-none">
                <Sparkles className="absolute top-20 left-10 w-6 h-6 text-purple-400 animate-pulse" />
                <Sparkles className="absolute top-40 right-20 w-8 h-8 text-blue-400 animate-pulse" style={{ animationDelay: '0.5s' }} />
                <Sparkles className="absolute bottom-32 left-1/3 w-5 h-5 text-indigo-400 animate-pulse" style={{ animationDelay: '1s' }} />
                <Sparkles className="absolute bottom-20 right-1/4 w-7 h-7 text-purple-400 animate-pulse" style={{ animationDelay: '1.5s' }} />
            </div>

            <div className="container mx-auto px-6 relative z-10">
                {/* Section Header */}
                <motion.div
                    initial={{ opacity: 0, y: 30 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.8 }}
                    className="text-center mb-20"
                >
                    <div className="inline-flex items-center gap-2 bg-gradient-to-r from-purple-500 to-blue-500 text-white px-6 py-3 rounded-full mb-8 shadow-lg">
                        <Sparkles className="w-5 h-5" />
                        <span className="font-semibold uppercase tracking-wider text-sm">AI-Powered Innovation</span>
                    </div>

                    <h2 className="font-serif text-5xl md:text-6xl lg:text-7xl font-medium text-gray-900 mb-6">
                        Your Personal
                        <br />
                        <span className="bg-gradient-to-r from-purple-600 via-blue-600 to-indigo-600 bg-clip-text text-transparent italic">
                            AI Travel Planner
                        </span>
                    </h2>

                    <p className="text-xl text-gray-600 max-w-3xl mx-auto leading-relaxed">
                        Let artificial intelligence do the heavy lifting. Get intelligent, personalized itineraries in seconds—no more hours of research.
                    </p>
                </motion.div>

                {/* Planning Steps Flow */}
                <div className="max-w-7xl mx-auto">
                    {planningSteps.map((step, index) => {
                        const Icon = step.icon;
                        const isEven = index % 2 === 0;

                        return (
                            <motion.div
                                key={index}
                                initial={{ opacity: 0, y: 50 }}
                                whileInView={{ opacity: 1, y: 0 }}
                                viewport={{ once: true, margin: "-100px" }}
                                transition={{ duration: 0.7, delay: index * 0.2 }}
                                className="relative mb-24 last:mb-0"
                            >
                                {/* Connection Line */}
                                {index < planningSteps.length - 1 && (
                                    <div className="absolute left-1/2 -translate-x-1/2 top-full h-24 w-1 bg-gradient-to-b from-purple-300 to-blue-300 hidden lg:block" />
                                )}

                                <div className={`flex flex-col ${isEven ? 'lg:flex-row' : 'lg:flex-row-reverse'} items-center gap-12 lg:gap-16`}>
                                    {/* Phone Mockup */}
                                    <motion.div
                                        whileHover={{ scale: 1.05, rotate: isEven ? 2 : -2 }}
                                        transition={{ duration: 0.3 }}
                                        className="relative w-full lg:w-1/2 flex justify-center"
                                    >
                                        {/* Glow Effect */}
                                        <div className="absolute inset-0 bg-gradient-to-br from-purple-500/30 to-blue-500/30 blur-3xl rounded-3xl" />

                                        {/* Phone Frame */}
                                        <div className="relative">
                                            <div className="relative w-[300px] md:w-[340px] bg-gradient-to-br from-gray-900 to-gray-800 rounded-[3rem] p-3 shadow-2xl">
                                                {/* Screen */}
                                                <div className="relative bg-white rounded-[2.5rem] overflow-hidden">
                                                    <Image
                                                        src={step.screenshot}
                                                        alt={step.title}
                                                        width={340}
                                                        height={680}
                                                        className="w-full h-auto"
                                                    />
                                                </div>
                                            </div>

                                            {/* Step Number Badge */}
                                            <motion.div
                                                animate={{ scale: [1, 1.1, 1] }}
                                                transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
                                                className={`absolute ${isEven ? '-left-6' : '-right-6'} top-8 bg-gradient-to-br from-purple-500 to-blue-500 text-white rounded-2xl w-16 h-16 flex items-center justify-center shadow-xl font-bold text-2xl`}
                                            >
                                                {step.step}
                                            </motion.div>
                                        </div>
                                    </motion.div>

                                    {/* Content */}
                                    <div className="w-full lg:w-1/2 text-center lg:text-left">
                                        <motion.div
                                            initial={{ opacity: 0, x: isEven ? -30 : 30 }}
                                            whileInView={{ opacity: 1, x: 0 }}
                                            viewport={{ once: true }}
                                            transition={{ duration: 0.6, delay: 0.3 }}
                                        >
                                            {/* Badge */}
                                            <div className="inline-flex items-center gap-2 bg-white/80 backdrop-blur-sm px-5 py-2 rounded-full border-2 border-purple-200 mb-6 shadow-sm">
                                                <Icon className="w-5 h-5 text-purple-600" />
                                                <span className="text-sm font-bold text-purple-600 uppercase tracking-wider">
                                                    {step.badge}
                                                </span>
                                            </div>

                                            <h3 className="font-serif text-4xl md:text-5xl font-medium text-gray-900 mb-6">
                                                {step.title}
                                            </h3>

                                            <p className="text-lg md:text-xl text-gray-600 leading-relaxed mb-8">
                                                {step.description}
                                            </p>

                                            {/* Feature Pills */}
                                            <div className="flex flex-wrap gap-3 justify-center lg:justify-start">
                                                {step.step === 1 && (
                                                    <>
                                                        <span className="px-4 py-2 bg-gradient-to-r from-purple-100 to-blue-100 rounded-full text-sm font-medium text-purple-700 border border-purple-200">
                                                            ⚡ Instant Generation
                                                        </span>
                                                        <span className="px-4 py-2 bg-gradient-to-r from-purple-100 to-blue-100 rounded-full text-sm font-medium text-purple-700 border border-purple-200">
                                                            🎯 Location-Based
                                                        </span>
                                                    </>
                                                )}
                                                {step.step === 2 && (
                                                    <>
                                                        <span className="px-4 py-2 bg-gradient-to-r from-purple-100 to-blue-100 rounded-full text-sm font-medium text-purple-700 border border-purple-200">
                                                            📅 Day-by-Day Plans
                                                        </span>
                                                        <span className="px-4 py-2 bg-gradient-to-r from-purple-100 to-blue-100 rounded-full text-sm font-medium text-purple-700 border border-purple-200">
                                                            ✨ Smart Recommendations
                                                        </span>
                                                    </>
                                                )}
                                                {step.step === 3 && (
                                                    <>
                                                        <span className="px-4 py-2 bg-gradient-to-r from-purple-100 to-blue-100 rounded-full text-sm font-medium text-purple-700 border border-purple-200">
                                                            📍 Rich Place Info
                                                        </span>
                                                        <span className="px-4 py-2 bg-gradient-to-r from-purple-100 to-blue-100 rounded-full text-sm font-medium text-purple-700 border border-purple-200">
                                                            💡 Insider Tips
                                                        </span>
                                                    </>
                                                )}
                                            </div>
                                        </motion.div>
                                    </div>
                                </div>
                            </motion.div>
                        );
                    })}
                </div>

                {/* AI Travel Guide Bonus Section */}
                <motion.div
                    initial={{ opacity: 0, y: 30 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.8 }}
                    className="mt-32 text-center"
                >
                    <div className="bg-white/60 backdrop-blur-xl rounded-3xl p-8 md:p-12 border border-purple-200 shadow-2xl max-w-5xl mx-auto">
                        <div className="flex flex-col md:flex-row items-center gap-8">
                            {/* AI Guide Screenshot */}
                            <div className="w-full md:w-1/3">
                                <div className="relative w-[240px] mx-auto bg-gradient-to-br from-gray-900 to-gray-800 rounded-[2.5rem] p-2.5 shadow-xl">
                                    <div className="relative bg-white rounded-[2rem] overflow-hidden">
                                        <Image
                                            src="/app_images/Ai_Travel_Guide.jpeg"
                                            alt="AI Travel Guide"
                                            width={240}
                                            height={480}
                                            className="w-full h-auto"
                                        />
                                    </div>
                                </div>
                            </div>

                            {/* Content */}
                            <div className="w-full md:w-2/3 text-center md:text-left">
                                <div className="inline-flex items-center gap-2 bg-gradient-to-r from-purple-500 to-blue-500 text-white px-4 py-2 rounded-full mb-4">
                                    <MapPin className="w-4 h-4" />
                                    <span className="text-xs font-bold uppercase tracking-wider">Bonus Feature</span>
                                </div>

                                <h3 className="font-serif text-3xl md:text-4xl font-medium text-gray-900 mb-4">
                                    AI Travel Guide
                                </h3>

                                <p className="text-lg text-gray-600 leading-relaxed mb-6">
                                    Get instant answers to all your travel questions. Our AI guide provides real-time recommendations, local insights, and expert advice tailored to your destination.
                                </p>

                                <div className="flex flex-wrap gap-2 justify-center md:justify-start">
                                    <span className="px-3 py-1.5 bg-purple-100 rounded-full text-xs font-medium text-purple-700">
                                        🤖 24/7 Available
                                    </span>
                                    <span className="px-3 py-1.5 bg-purple-100 rounded-full text-xs font-medium text-purple-700">
                                        🌍 Local Expertise
                                    </span>
                                    <span className="px-3 py-1.5 bg-purple-100 rounded-full text-xs font-medium text-purple-700">
                                        💬 Conversational
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                </motion.div>

                {/* Bottom CTA */}
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.6 }}
                    className="text-center mt-20"
                >
                    <p className="text-gray-700 mb-6 text-lg font-medium">
                        Experience the future of trip planning
                    </p>
                    <a
                        href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center gap-3 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white px-10 py-5 rounded-full font-semibold text-lg transition-all shadow-xl shadow-purple-500/30 group"
                    >
                        <Sparkles className="w-6 h-6 group-hover:rotate-12 transition-transform" />
                        Try AI Planning Now
                    </a>
                </motion.div>
            </div>
        </section>
    );
}
