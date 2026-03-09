"use client";

import { motion } from "framer-motion";
import Image from "next/image";
import { Users, MessageCircle, Calendar, Image as ImageIcon, Vote, DollarSign, Link, MapPin } from "lucide-react";

export default function AppFeatures() {
    const features = [
        {
            icon: Users,
            title: "Collaborative Trip Planning",
            description: "Experience the best online itinerary builder for group travel. Keep your travel plans personal and organized in one beautiful space.",
            screenshot: "/app_images/home.jpeg",
            gradient: "from-blue-500/20 to-purple-500/20",
            iconColor: "text-blue-400"
        },
        {
            icon: Users,
            title: "Public & Agency Trips",
            description: "Discover curated travel packages from top agencies or browse public trips for inspiration. Your next big adventure is just a tap away.",
            screenshot: "/app_images/Agency andPublicTrips.jpeg",
            gradient: "from-amber-500/20 to-orange-500/20",
            iconColor: "text-amber-500"
        },
        {
            icon: Calendar,
            title: "Smart Trip Dashboard",
            description: "Your ultimate vacation planner and itinerary manager. Handle dates, budgets, links, and schedules effortlessly in intuitive tabs.",
            screenshot: "/app_images/trip_dashboard.jpeg",
            gradient: "from-orange-500/20 to-pink-500/20",
            iconColor: "text-orange-400"
        },
        {
            icon: MapPin,
            title: "Smart Place Suggestions",
            description: "Easily add the best locations to your trip with intelligent autosuggestions. Finding your next stop has never been smoother.",
            screenshot: "/app_images/AutosugestionsForAddPlace.jpeg",
            gradient: "from-indigo-500/20 to-violet-500/20",
            iconColor: "text-indigo-400"
        },
        {
            icon: DollarSign,
            title: "Budget Tracking",
            description: "As a premier trip planner app, keeping your finances in check is easy. Track expenses, split costs with friends, and stay within budget.",
            screenshot: "/app_images/budget.jpeg",
            gradient: "from-emerald-500/20 to-green-500/20",
            iconColor: "text-emerald-400"
        },
        {
            icon: Link,
            title: "Shared Links & Resources",
            description: "Save and share important links—bookings, tickets, articles, or recommendations. Keep everything your group needs in one spot.",
            screenshot: "/app_images/links.jpeg",
            gradient: "from-cyan-500/20 to-blue-500/20",
            iconColor: "text-cyan-400"
        },
        {
            icon: Vote,
            title: "Group Polls & Decisions",
            description: "Make travel decisions together. Create polls for activities, destinations, or any group choice—democracy made simple.",
            screenshot: "/app_images/polls.jpeg",
            gradient: "from-green-500/20 to-teal-500/20",
            iconColor: "text-green-400"
        },
        {
            icon: ImageIcon,
            title: "Shared Memories Gallery",
            description: "Capture and share trip moments in a private gallery. Create beautiful trip summaries to relive your adventures.",
            screenshot: "/app_images/gallary.jpeg",
            gradient: "from-pink-500/20 to-rose-500/20",
            iconColor: "text-pink-400"
        },
        {
            icon: MessageCircle,
            title: "Real-time Group Chat",
            description: "Stay connected with your travel crew. Discuss plans, share updates, and coordinate seamlessly—all within your trip.",
            screenshot: "/app_images/chats.jpeg",
            gradient: "from-indigo-500/20 to-blue-500/20",
            iconColor: "text-indigo-400"
        },
        {
            icon: Users,
            title: "Personalized Travel Profile",
            description: "Showcase your travel history, bucket list, and favorite memories. Your personal travel identity, all in one place.",
            screenshot: "/app_images/Profile.jpeg",
            gradient: "from-purple-500/20 to-pink-500/20",
            iconColor: "text-purple-400"
        }
    ];

    return (
        <section id="features" className="relative py-24 bg-gradient-to-b from-[#F7F3EC] via-white to-[#F7F3EC] overflow-hidden">
            {/* Background Decoration */}
            <div className="absolute inset-0 opacity-30">
                <div className="absolute top-20 left-10 w-72 h-72 bg-brand-accent/10 rounded-full blur-3xl" />
                <div className="absolute bottom-20 right-10 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" />
            </div>

            <div className="container mx-auto px-6 relative z-10">
                {/* Section Header */}
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.6 }}
                    className="text-center mb-20"
                >
                    <h2 className="font-serif text-5xl md:text-6xl lg:text-7xl font-medium text-brand-primary mb-6">
                        Everything You Need,
                        <br />
                        <span className="italic text-brand-accent">In One Beautiful App</span>
                    </h2>
                    <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                        Plan, collaborate, and create memories—all while keeping your travel moments private and intentional.
                    </p>
                </motion.div>

                {/* Features Grid */}
                <div className="space-y-32">
                    {features.map((feature, index) => {
                        const Icon = feature.icon;
                        const isEven = index % 2 === 0;

                        return (
                            <motion.div
                                key={index}
                                initial={{ opacity: 0, y: 40 }}
                                whileInView={{ opacity: 1, y: 0 }}
                                viewport={{ once: true, margin: "-100px" }}
                                transition={{ duration: 0.7, delay: 0.2 }}
                                className={`flex flex-col ${isEven ? 'lg:flex-row' : 'lg:flex-row-reverse'} items-center gap-12 lg:gap-20`}
                            >
                                {/* Phone Mockup */}
                                <motion.div
                                    whileHover={{ y: -10 }}
                                    transition={{ duration: 0.3 }}
                                    className="relative w-full lg:w-1/2 flex justify-center"
                                >
                                    {/* Glow Effect */}
                                    <div className={`absolute inset-0 bg-gradient-to-br ${feature.gradient} blur-3xl opacity-50 rounded-3xl`} />

                                    {/* Phone Frame */}
                                    <div className="relative">
                                        <div className="relative w-[280px] md:w-[320px] bg-black rounded-[3rem] p-3 shadow-2xl">
                                            {/* Screen */}
                                            <div className="relative bg-white rounded-[2.5rem] overflow-hidden">
                                                <Image
                                                    src={feature.screenshot}
                                                    alt={feature.title}
                                                    width={320}
                                                    height={640}
                                                    className="w-full h-auto"
                                                />
                                            </div>
                                        </div>

                                        {/* Floating Icon Badge */}
                                        <motion.div
                                            animate={{ y: [0, -10, 0] }}
                                            transition={{ duration: 3, repeat: Infinity, ease: "easeInOut" }}
                                            className={`absolute ${isEven ? '-right-6' : '-left-6'} top-1/2 -translate-y-1/2 bg-white rounded-2xl p-4 shadow-xl border border-gray-100`}
                                        >
                                            <Icon className={`w-8 h-8 ${feature.iconColor}`} />
                                        </motion.div>
                                    </div>
                                </motion.div>

                                {/* Feature Content */}
                                <div className="w-full lg:w-1/2 text-center lg:text-left">
                                    <motion.div
                                        initial={{ opacity: 0, x: isEven ? -20 : 20 }}
                                        whileInView={{ opacity: 1, x: 0 }}
                                        viewport={{ once: true }}
                                        transition={{ duration: 0.6, delay: 0.3 }}
                                    >
                                        <div className={`inline-flex items-center gap-3 mb-6 px-4 py-2 bg-gradient-to-r ${feature.gradient} rounded-full border border-white/20`}>
                                            <Icon className={`w-5 h-5 ${feature.iconColor}`} />
                                            <span className="text-sm font-semibold text-gray-700 uppercase tracking-wider">
                                                Feature {index + 1}
                                            </span>
                                        </div>

                                        <h3 className="font-serif text-4xl md:text-5xl font-medium text-brand-primary mb-6">
                                            {feature.title}
                                        </h3>

                                        <p className="text-lg text-gray-600 leading-relaxed mb-8">
                                            {feature.description}
                                        </p>

                                        {/* Feature Highlights */}
                                        <div className="flex flex-wrap gap-3 justify-center lg:justify-start">
                                            <span className="px-4 py-2 bg-white/80 backdrop-blur-sm rounded-full text-sm text-gray-700 border border-gray-200 shadow-sm">
                                                ✨ Intuitive Design
                                            </span>
                                            <span className="px-4 py-2 bg-white/80 backdrop-blur-sm rounded-full text-sm text-gray-700 border border-gray-200 shadow-sm">
                                                🔒 Privacy First
                                            </span>
                                        </div>
                                    </motion.div>
                                </div>
                            </motion.div>
                        );
                    })}
                </div>

                {/* Bottom CTA */}
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.6 }}
                    className="text-center mt-24"
                >
                    <p className="text-gray-600 mb-6 text-lg">
                        Ready to transform how you plan trips?
                    </p>
                    <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
                        <a
                            href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="flex items-center gap-3 bg-brand-accent hover:bg-[#B45309] text-white px-8 py-4 rounded-full font-medium transition-all shadow-lg shadow-brand-accent/20 group"
                        >
                            <Image
                                src="/assets/icons8-google-play-store-100.png"
                                alt="Google Play"
                                width={24}
                                height={24}
                                className="w-6 h-6 group-hover:scale-110 transition-transform"
                            />
                            Download for Android
                        </a>
                        <div className="flex items-center gap-3 bg-white/50 backdrop-blur-md border-2 border-gray-100 text-gray-400 px-8 py-4 rounded-full font-medium cursor-default group">
                            <Image
                                src="/assets/icons8-app-store-100.png"
                                alt="App Store"
                                width={24}
                                height={24}
                                className="w-6 h-6 grayscale opacity-50"
                            />
                            Coming to iOS Soon
                        </div>
                    </div>
                </motion.div>
            </div>
        </section>
    );
}
