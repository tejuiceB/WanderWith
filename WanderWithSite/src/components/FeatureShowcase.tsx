"use client";

import { motion, useScroll, useTransform } from "framer-motion";
import { useRef } from "react";
import Image from "next/image";
import PhoneMockup from "./PhoneMockup";

const showcases = [
    {
        badge: "AI Planning",
        title: "Your AI travel assistant",
        desc: "Describe your dream trip and get a complete itinerary in seconds. Places to visit, restaurants, timings, all mapped out. Powered by AI, personalized for you.",
        image: "/app_images/AI-Plan_1.jpeg",
        alt: "WanderWith AI trip planner generating itinerary",
        accent: "bg-indigo-500/10 text-indigo-600 border-indigo-500/20",
    },
    {
        badge: "Group Trips",
        title: "Travel together, plan together",
        desc: "Create trips with friends, chat in real-time, vote on destinations with polls, split budgets fairly, and share booking links. All without leaving the app.",
        image: "/app_images/chats.jpeg",
        alt: "WanderWith group chat and collaboration features",
        accent: "bg-violet-500/10 text-violet-600 border-violet-500/20",
    },
    {
        badge: "For Agencies",
        title: "Professional tools for travel agencies",
        desc: "Build beautiful trip packages, manage client itineraries, and share public trip links. Give your clients a modern, branded travel experience.",
        image: "/app_images/Agency andPublicTrips.jpeg",
        alt: "WanderWith travel agency dashboard and trip packages",
        accent: "bg-emerald-500/10 text-emerald-600 border-emerald-500/20",
    },
];

function ShowcaseItem({ item, index }: { item: typeof showcases[0]; index: number }) {
    const ref = useRef<HTMLDivElement>(null);
    const { scrollYProgress } = useScroll({
        target: ref,
        offset: ["start end", "end start"],
    });
    const y = useTransform(scrollYProgress, [0, 1], [60, -60]);
    const isReversed = index % 2 === 1;

    return (
        <div
            ref={ref}
            className={`flex flex-col ${isReversed ? "lg:flex-row-reverse" : "lg:flex-row"} items-center gap-12 lg:gap-20`}
        >
            {/* Phone with parallax */}
            <motion.div
                style={{ y }}
                initial={{ opacity: 0, scale: 0.9 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true, margin: "-80px" }}
                transition={{ type: "spring", stiffness: 70, damping: 20 }}
                className="flex-shrink-0"
            >
                <PhoneMockup className="w-[240px] sm:w-[260px] md:w-[280px]">
                    <Image
                        src={item.image}
                        alt={item.alt}
                        fill
                        className="object-cover"
                        sizes="280px"
                    />
                </PhoneMockup>
            </motion.div>

            {/* Text */}
            <motion.div
                initial={{ opacity: 0, x: isReversed ? -30 : 30 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true, margin: "-80px" }}
                transition={{ type: "spring", stiffness: 80, damping: 20, delay: 0.1 }}
                className="flex-1 text-center lg:text-left max-w-lg"
            >
                <span className={`inline-block px-3 py-1 rounded-full text-xs font-semibold tracking-wide uppercase mb-4 border ${item.accent}`}>
                    {item.badge}
                </span>
                <h3 className="font-serif font-bold text-2xl sm:text-3xl md:text-4xl text-brand-primary tracking-tight mb-4 leading-tight">
                    {item.title}
                </h3>
                <p className="text-brand-text-secondary text-base md:text-lg leading-relaxed">
                    {item.desc}
                </p>
            </motion.div>
        </div>
    );
}

export default function FeatureShowcase() {
    return (
        <section className="bg-brand-bg-alt py-24 md:py-32">
            <div className="max-w-7xl mx-auto px-5 md:px-8 space-y-28 md:space-y-36">
                {showcases.map((item, i) => (
                    <ShowcaseItem key={item.badge} item={item} index={i} />
                ))}
            </div>
        </section>
    );
}
