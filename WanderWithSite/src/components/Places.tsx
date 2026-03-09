"use client";

import { motion } from "framer-motion";
import Image from "next/image";

const places = [
    { name: "Paris", country: "France", img: "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=400&h=500&fit=crop" },
    { name: "Bali", country: "Indonesia", img: "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=400&h=500&fit=crop" },
    { name: "Kyoto", country: "Japan", img: "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400&h=500&fit=crop" },
    { name: "Santorini", country: "Greece", img: "https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=400&h=500&fit=crop" },
    { name: "Jaipur", country: "India", img: "https://images.unsplash.com/photo-1599661046289-e31897846e41?w=400&h=500&fit=crop" },
    { name: "New York", country: "USA", img: "https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=400&h=500&fit=crop" },
    { name: "Machu Picchu", country: "Peru", img: "https://images.unsplash.com/photo-1587595431973-160d0d94add1?w=400&h=500&fit=crop" },
    { name: "Dubai", country: "UAE", img: "https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=400&h=500&fit=crop" },
    { name: "Manali", country: "India", img: "https://images.unsplash.com/photo-1626621341517-bbf3d9990a23?w=400&h=500&fit=crop" },
    { name: "Rome", country: "Italy", img: "https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=400&h=500&fit=crop" },
    { name: "Cape Town", country: "South Africa", img: "https://images.unsplash.com/photo-1580060839134-75a5edca2e99?w=400&h=500&fit=crop" },
    { name: "London", country: "England", img: "https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=400&h=500&fit=crop" },
    { name: "Goa", country: "India", img: "https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=400&h=500&fit=crop" },
    { name: "Bangkok", country: "Thailand", img: "https://images.unsplash.com/photo-1508009603885-50cf7c579365?w=400&h=500&fit=crop" },
    { name: "Maldives", country: "Maldives", img: "https://images.unsplash.com/photo-1514282401047-d79a71a590e8?w=400&h=500&fit=crop" },
    { name: "Istanbul", country: "Turkey", img: "https://images.unsplash.com/photo-1541432901042-2d8bd64b4a9b?w=400&h=500&fit=crop" },
];

/* Duplicate for seamless loop */
const row1 = places.slice(0, 8);
const row2 = places.slice(8, 16);

function PlaceCard({ place }: { place: (typeof places)[number] }) {
    return (
        <div className="relative flex-shrink-0 w-[200px] sm:w-[220px] md:w-[240px] aspect-[4/5] rounded-2xl overflow-hidden group">
            <Image
                src={place.img}
                alt={place.name}
                fill
                sizes="240px"
                className="object-cover transition-transform duration-500 group-hover:scale-110"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/10 to-transparent" />
            <div className="absolute bottom-0 left-0 right-0 p-4">
                <p className="text-white font-semibold text-base">{place.name}</p>
                <p className="text-white/70 text-sm">{place.country}</p>
            </div>
        </div>
    );
}

export default function Places() {
    return (
        <section className="bg-brand-bg py-24 md:py-32 overflow-hidden">
            <div className="max-w-7xl mx-auto px-5 md:px-8 mb-12">
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ type: "spring", stiffness: 80, damping: 20 }}
                    className="text-center"
                >
                    <p className="text-brand-accent font-semibold text-sm tracking-wide uppercase mb-3">Explore</p>
                    <h2 className="font-sans font-bold text-3xl sm:text-4xl md:text-5xl text-brand-primary tracking-tight mb-4">
                        Hundreds of places to visit
                    </h2>
                    <p className="text-brand-text-secondary text-lg max-w-2xl mx-auto">
                        For every corner of the world. Plan your dream trip with AI-powered suggestions.
                    </p>
                </motion.div>
            </div>

            {/* Row 1 - scrolls left */}
            <div className="relative mb-5">
                <div className="flex gap-4 animate-scroll-left">
                    {[...row1, ...row1].map((place, i) => (
                        <PlaceCard key={`r1-${i}`} place={place} />
                    ))}
                </div>
            </div>

            {/* Row 2 - scrolls right */}
            <div className="relative">
                <div className="flex gap-4 animate-scroll-right">
                    {[...row2, ...row2].map((place, i) => (
                        <PlaceCard key={`r2-${i}`} place={place} />
                    ))}
                </div>
            </div>
        </section>
    );
}
