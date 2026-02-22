"use client";

import { motion } from "framer-motion";
import Image from "next/image";
import { Users, Lock, Sparkles } from "lucide-react";
import { useEffect, useRef, useState } from "react";

const tripsData = [
    {
        title: "Goa New Year 2026",
        meta: "8 friends · Invite only",
        tag: "🔒 Private",
        image: "https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?q=80&w=2574&auto=format&fit=crop",
        icon: <Users size={16} className="text-brand-accent" />
    },
    {
        title: "Spiti Road Trip",
        meta: "5 riders · Private",
        tag: "👥 5 Spots Filled",
        image: "https://images.unsplash.com/photo-1626621341517-bbf3d9990a23?q=80&w=2574&auto=format&fit=crop",
        icon: <Lock size={16} className="text-brand-accent" />
    },
    {
        title: "Kerala Monsoon Retreat",
        meta: "Hosted by Coastal Trails",
        tag: "🌿 Curated",
        image: "https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?q=80&w=2532&auto=format&fit=crop",
        icon: <Sparkles size={16} className="text-brand-accent" />
    },
    {
        title: "Meghalaya Root Bridges",
        meta: "4 hikers · Closed Group",
        tag: "🔒 Private",
        image: "https://images.unsplash.com/photo-1627894483216-2138af692e32?q=80&w=2574&auto=format&fit=crop",
        icon: <Users size={16} className="text-brand-accent" />
    },
    {
        title: "Pondicherry French Quarter",
        meta: "Girls Trip · 6 People",
        tag: "👥 6 People",
        image: "https://images.unsplash.com/photo-1582510003544-4d00b7f74220?q=80&w=2574&auto=format&fit=crop",
        icon: <Lock size={16} className="text-brand-accent" />
    },
    {
        title: "Jaisalmer Desert Nights",
        meta: "Stargazing · 12 Spots",
        tag: "🎟 3 Spots Left",
        // Desert/Camel vibe
        image: "https://images.unsplash.com/photo-1682687220063-4742bd7fd538?q=80&w=2070&auto=format&fit=crop",
        icon: <Sparkles size={16} className="text-brand-accent" />
    }
];

// Double the array for seamless infinite scroll
const trips = [...tripsData, ...tripsData];

export default function RealTrips() {
    const scrollRef = useRef<HTMLDivElement>(null);
    const [isPaused, setIsPaused] = useState(false);

    useEffect(() => {
        const scrollContainer = scrollRef.current;
        if (!scrollContainer) return;

        let animationFrameId: number;
        // Adjust speed here (pixels per frame)
        // 0.5 is very slow and smooth
        const speed = 0.5;

        const scroll = () => {
            if (!isPaused && scrollContainer) {
                if (scrollContainer.scrollLeft >= scrollContainer.scrollWidth / 2) {
                    // Reset seamlessly to 0 when halfway (since list is doubled)
                    scrollContainer.scrollLeft = 0;
                } else {
                    scrollContainer.scrollLeft += speed;
                }
            }
            animationFrameId = requestAnimationFrame(scroll);
        };

        animationFrameId = requestAnimationFrame(scroll);

        return () => cancelAnimationFrame(animationFrameId);
    }, [isPaused]);

    return (
        <section className="py-24 md:py-40 bg-brand-bg relative overflow-hidden">
            <div className="container mx-auto px-6 mb-16 text-center">
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.8 }}
                >
                    <h2 className="font-serif text-5xl md:text-7xl text-brand-primary mb-6">
                        Real trips. Real circles.
                    </h2>
                    <div className="w-20 h-1 bg-brand-accent mx-auto rounded-full opacity-60" />
                </motion.div>
            </div>

            {/* Hybrid Scroll Container */}
            {/* 'cursor-grab' indicates manual scrollability */}
            <div
                ref={scrollRef}
                className="flex overflow-x-auto hide-scrollbar gap-6 px-6 cursor-grab active:cursor-grabbing"
                onMouseEnter={() => setIsPaused(true)}
                onMouseLeave={() => setIsPaused(false)}
                onTouchStart={() => setIsPaused(true)}
                onTouchEnd={() => setTimeout(() => setIsPaused(false), 2000)} // Resume after a delay
            >
                {trips.map((trip, index) => (
                    <div
                        key={index}
                        className="min-w-[85vw] sm:min-w-[400px] md:min-w-[350px] flex-shrink-0 group"
                    >
                        <div className="relative aspect-[4/5] overflow-hidden rounded-xl shadow-lg border border-white/20 select-none">
                            <Image
                                src={trip.image}
                                alt={trip.title}
                                fill
                                className="object-cover transition-transform duration-700 group-hover:scale-105"
                                draggable={false}
                            />
                            <div className="absolute top-4 left-4">
                                <span className="px-3 py-1 bg-white/90 backdrop-blur-md text-brand-primary text-xs font-bold uppercase tracking-wider rounded-md shadow-sm border border-white/20">
                                    {trip.tag}
                                </span>
                            </div>

                            <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent opacity-80" />

                            <div className="absolute bottom-6 left-6 right-6 text-white">
                                <h3 className="font-serif text-2xl font-medium mb-3 drop-shadow-md leading-tight">{trip.title}</h3>
                                <div className="flex items-center gap-2 text-xs font-medium tracking-wide text-white/90 bg-white/10 backdrop-blur-md px-3 py-1.5 rounded-full border border-white/20 w-fit">
                                    {trip.icon}
                                    {trip.meta}
                                </div>
                            </div>
                        </div>
                    </div>
                ))}
            </div>

            <style jsx global>{`
                .hide-scrollbar::-webkit-scrollbar {
                    display: none;
                }
                .hide-scrollbar {
                    -ms-overflow-style: none;
                    scrollbar-width: none;
                }
            `}</style>
        </section>
    );
}
