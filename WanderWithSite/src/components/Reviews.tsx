"use client";

import { useState } from "react";
import { motion } from "framer-motion";
import { Star, ChevronDown, ChevronUp } from "lucide-react";
import Image from "next/image";

const reviews = [
    {
        name: "Priya K.",
        subtitle: "Travel Blogger",
        rating: 5,
        text: "Planned our entire Goa trip in 10 minutes with the AI. Budget tracking saved us from the usual post-trip arguments. Absolute game-changer for group travel.",
        photo: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80&h=80&fit=crop&crop=face",
        gradient: "from-rose-400 to-orange-400",
    },
    {
        name: "Rahul S.",
        subtitle: "",
        rating: 5,
        text: "We used to have a WhatsApp group, a Google Sheet, and 3 different note apps for one trip. WanderWith replaced all of them.",
        photo: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80&h=80&fit=crop&crop=face",
        gradient: "from-indigo-400 to-cyan-400",
    },
    {
        name: "Ankit M.",
        subtitle: "",
        rating: 4,
        text: "The polls feature is genius. No more 50-message debates about where to eat. Just vote and go. Our group trips have never been this smooth.",
        photo: "",
        gradient: "from-emerald-400 to-teal-400",
    },
    {
        name: "Sneha R.",
        subtitle: "Solo Traveller",
        rating: 5,
        text: "As a solo traveller, the AI itinerary builder is incredible. It suggested places I'd never heard of and mapped out my whole Himachal trip perfectly. The suggestions were spot on and saved me hours of research.",
        photo: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=80&h=80&fit=crop&crop=face",
        gradient: "from-violet-400 to-purple-400",
    },
    {
        name: "Vikram T.",
        subtitle: "Travel Agency Owner",
        rating: 5,
        text: "I run a small travel agency and WanderWith makes me look so professional. Creating trip packages and sharing links with clients is now effortless.",
        photo: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=80&h=80&fit=crop&crop=face",
        gradient: "from-amber-400 to-orange-400",
    },
    {
        name: "Meera D.",
        subtitle: "",
        rating: 4,
        text: "The shared gallery feature is my favourite. After every trip, all the photos are already in one album. No more 'send me that photo' messages!",
        photo: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=80&h=80&fit=crop&crop=face",
        gradient: "from-pink-400 to-rose-400",
    },
    {
        name: "Arjun P.",
        subtitle: "",
        rating: 5,
        text: "Amazing app! Easy to use, love the AI functionality. Makes trip planning actually fun instead of stressful.",
        photo: "",
        gradient: "from-blue-400 to-indigo-400",
    },
    {
        name: "Kavya S.",
        subtitle: "Founder @ExploreMore",
        rating: 5,
        text: "So much easier to visualize and plan a road trip to my favourite destinations and explore the area around. The map integration is brilliant. I have used several trip planning apps and this one is by far the best. The interaction between maps makes the planning so much easier. Adding an adventure not in the app is also easy. Everything is connected including booking a stay. Easy to use on phone, tablets and computer! Well thought through development.",
        photo: "https://images.unsplash.com/photo-1580489944761-15a19d654956?w=80&h=80&fit=crop&crop=face",
        gradient: "from-teal-400 to-emerald-400",
    },
    {
        name: "Rohan N.",
        subtitle: "",
        rating: 5,
        text: "It left me speechless that I can add places to my trip and they get automatically populated with a featured pic and description from the web. Kudos to the developers!",
        photo: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=80&h=80&fit=crop&crop=face",
        gradient: "from-cyan-400 to-blue-400",
    },
    {
        name: "Nisha R.",
        subtitle: "",
        rating: 5,
        text: "I absolutely love this app! I would recommend to anyone who is seriously planning a trip.",
        photo: "",
        gradient: "from-orange-400 to-amber-400",
    },
    {
        name: "Divya K.",
        subtitle: "",
        rating: 5,
        text: "Absolutely love this app! It is so helpful when planning my trips. I especially love the optimize route option. When I have all my information in place like my starting point and my ending point it is fabulous! I especially love how it will suggest things to do if you don't have any plans.",
        photo: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=80&h=80&fit=crop&crop=face",
        gradient: "from-purple-400 to-violet-400",
    },
    {
        name: "Siddharth M.",
        subtitle: "",
        rating: 4,
        text: "Very intuitive and simple while still being powerful. The budget tracker alone is worth using the app for.",
        photo: "",
        gradient: "from-slate-400 to-zinc-400",
    },
];

/* Split into columns for masonry layout */
function splitIntoColumns(items: typeof reviews, cols: number) {
    const columns: (typeof reviews)[] = Array.from({ length: cols }, () => []);
    items.forEach((item, i) => columns[i % cols].push(item));
    return columns;
}

function Stars({ count }: { count: number }) {
    return (
        <div className="flex gap-0.5">
            {Array.from({ length: 5 }).map((_, i) => (
                <Star
                    key={i}
                    className={`w-3.5 h-3.5 ${i < count ? "fill-amber-400 text-amber-400" : "text-slate-200"}`}
                />
            ))}
        </div>
    );
}

function ReviewCard({ r, i }: { r: (typeof reviews)[number]; i: number }) {
    return (
        <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-40px" }}
            transition={{ type: "spring", stiffness: 100, damping: 22, delay: i * 0.04 }}
            className="break-inside-avoid mb-4 p-5 rounded-2xl bg-brand-card border border-brand-border hover:shadow-lg hover:shadow-black/[0.04] transition-all duration-300"
        >
            {/* Reviewer info */}
            <div className="flex items-center gap-3 mb-3">
                {r.photo ? (
                    <Image
                        src={r.photo}
                        alt={r.name}
                        width={40}
                        height={40}
                        className="w-10 h-10 rounded-full object-cover ring-2 ring-white shadow-sm"
                    />
                ) : (
                    <div className={`w-10 h-10 rounded-full bg-gradient-to-br ${r.gradient} flex items-center justify-center text-white text-sm font-bold ring-2 ring-white shadow-sm`}>
                        {r.name[0]}
                    </div>
                )}
                <div className="min-w-0">
                    <p className="text-sm font-semibold text-brand-primary truncate">{r.name}</p>
                    {r.subtitle && (
                        <p className="text-xs text-brand-text-tertiary truncate">{r.subtitle}</p>
                    )}
                </div>
            </div>

            <Stars count={r.rating} />

            <p className="mt-3 text-brand-text-secondary text-[14px] leading-relaxed">
                {r.text}
            </p>
        </motion.div>
    );
}

export default function Reviews() {
    const [expanded, setExpanded] = useState(false);
    const cols2 = splitIntoColumns(reviews, 2);
    const cols3 = splitIntoColumns(reviews, 3);
    const cols4 = splitIntoColumns(reviews, 4);

    return (
        <section id="reviews" className="bg-brand-bg-alt py-24 md:py-32">
            <div className="max-w-7xl mx-auto px-5 md:px-8">
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ type: "spring", stiffness: 80, damping: 20 }}
                    className="text-center mb-14"
                >
                    <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3">Reviews</p>
                    <h2 className="font-serif font-bold text-3xl sm:text-4xl md:text-5xl text-brand-primary tracking-tight mb-4">
                        Loved by travellers across India
                    </h2>
                    <p className="text-brand-text-secondary text-lg max-w-2xl mx-auto">
                        Real stories from people who plan their trips with WanderWith.
                    </p>
                </motion.div>

                <div className="relative">
                    {/* Content container with collapse */}
                    <div
                        className={`transition-[max-height] duration-700 ease-in-out overflow-hidden ${
                            expanded ? "max-h-[5000px]" : "max-h-[520px] sm:max-h-[600px] md:max-h-[650px]"
                        }`}
                    >
                        {/* Mobile: 1 col */}
                        <div className="sm:hidden columns-1 gap-4">
                            {reviews.map((r, i) => (
                                <ReviewCard key={r.name} r={r} i={i} />
                            ))}
                        </div>

                        {/* Tablet: 2 cols */}
                        <div className="hidden sm:block md:hidden">
                            <div className="flex gap-4">
                                {cols2.map((col, ci) => (
                                    <div key={ci} className="flex-1 space-y-4">
                                        {col.map((r, i) => (
                                            <ReviewCard key={r.name} r={r} i={i} />
                                        ))}
                                    </div>
                                ))}
                            </div>
                        </div>

                        {/* Small desktop: 3 cols */}
                        <div className="hidden md:block lg:hidden">
                            <div className="flex gap-4">
                                {cols3.map((col, ci) => (
                                    <div key={ci} className="flex-1 space-y-4">
                                        {col.map((r, i) => (
                                            <ReviewCard key={r.name} r={r} i={i} />
                                        ))}
                                    </div>
                                ))}
                            </div>
                        </div>

                        {/* Large desktop: 4 cols */}
                        <div className="hidden lg:block">
                            <div className="flex gap-4">
                                {cols4.map((col, ci) => (
                                    <div key={ci} className="flex-1 space-y-4">
                                        {col.map((r, i) => (
                                            <ReviewCard key={r.name} r={r} i={i} />
                                        ))}
                                    </div>
                                ))}
                            </div>
                        </div>
                    </div>

                    {/* Gradient fade overlay */}
                    {!expanded && (
                        <div className="absolute bottom-0 inset-x-0 h-44 bg-gradient-to-t from-[#F8FAFC] via-[#F8FAFC]/90 to-transparent pointer-events-none" />
                    )}
                </div>

                {/* Show more / Show less toggle */}
                <div className="flex justify-center mt-[-20px] relative z-10">
                    <button
                        onClick={() => setExpanded(!expanded)}
                        className="inline-flex items-center gap-1.5 px-5 py-2.5 rounded-full bg-white border border-brand-border text-sm font-semibold text-brand-primary shadow-sm hover:shadow-md hover:border-brand-accent/30 transition-all duration-200"
                    >
                        {expanded ? (
                            <>
                                Show less <ChevronUp className="w-4 h-4" />
                            </>
                        ) : (
                            <>
                                Show more reviews <ChevronDown className="w-4 h-4" />
                            </>
                        )}
                    </button>
                </div>
            </div>
        </section>
    );
}
