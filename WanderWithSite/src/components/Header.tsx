"use client";

import { useState, useEffect } from "react";
import Image from "next/image";
import Link from "next/link";
import { motion, AnimatePresence } from "framer-motion";
import { Menu, X } from "lucide-react";

export default function Header() {
    const [scrolled, setScrolled] = useState(false);
    const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

    useEffect(() => {
        const handleScroll = () => {
            setScrolled(window.scrollY > 50);
        };
        window.addEventListener("scroll", handleScroll);
        return () => window.removeEventListener("scroll", handleScroll);
    }, []);

    const navLinks = [
        { name: "Features", href: "#features" },
        { name: "For Travelers", href: "#travelers" },
        { name: "For Agencies", href: "#agencies" },
        { name: "About", href: "#about" },
    ];

    const scrollToSection = (e: React.MouseEvent<HTMLAnchorElement>, href: string) => {
        e.preventDefault();
        const element = document.querySelector(href);
        if (element) {
            element.scrollIntoView({ behavior: "smooth" });
            setMobileMenuOpen(false);
        }
    };

    return (
        <header
            className={`fixed top-0 left-0 w-full z-[100] transition-all duration-300 ${scrolled
                ? "bg-brand-primary/95 backdrop-blur-md py-3 shadow-lg"
                : "bg-gradient-to-b from-black/50 to-transparent py-6"
                }`}
        >
            <div className="container mx-auto px-6 flex items-center justify-between">
                {/* Logo */}
                <Link href="/" onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })} className="flex items-center gap-2">
                    <div className="relative w-10 h-10">
                        <Image src="/logo.png" alt="WanderWith Logo" fill className="object-contain" />
                    </div>
                    <span className="text-xl font-bold text-white tracking-wide drop-shadow-md">
                        WanderWith
                    </span>
                </Link>

                {/* Desktop Nav */}
                <nav className="hidden lg:flex items-center gap-8">
                    {navLinks.map((link) => (
                        <a
                            key={link.name}
                            href={link.href}
                            onClick={(e) => scrollToSection(e, link.href)}
                            className="text-white/80 hover:text-brand-accent transition-colors text-sm font-medium cursor-pointer"
                        >
                            {link.name}
                        </a>
                    ))}
                    <div className="flex items-center gap-3">
                        <div className="flex items-center gap-2 bg-white/5 border border-white/10 px-3 py-1.5 rounded-lg opacity-60 cursor-default">
                            <Image
                                src="/assets/icons8-app-store-100.png"
                                alt="App Store"
                                width={20}
                                height={20}
                                className="w-5 h-5 grayscale"
                            />
                            <div className="text-left hidden xl:block">
                                <p className="text-[8px] uppercase tracking-wider text-white/50 leading-none mb-0.5">iOS App</p>
                                <p className="text-[10px] font-bold text-white/70 leading-none">Coming Soon</p>
                            </div>
                        </div>
                        <a href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith" target="_blank" rel="noopener noreferrer" className="flex items-center gap-2 bg-white/10 hover:bg-white/20 border border-white/20 px-3 py-1.5 rounded-lg transition-all group">
                            <Image
                                src="/assets/icons8-google-play-store-100.png"
                                alt="Google Play"
                                width={20}
                                height={20}
                                className="w-5 h-5 group-hover:scale-110 transition-transform"
                            />
                            <div className="text-left hidden xl:block">
                                <p className="text-[8px] uppercase tracking-wider text-white/70 leading-none mb-0.5">Get it on</p>
                                <p className="text-[10px] font-bold text-white leading-none">Google Play</p>
                            </div>
                        </a>
                    </div>
                </nav>

                {/* Mobile Menu Button */}
                <button
                    className="lg:hidden text-white"
                    onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                >
                    {mobileMenuOpen ? <X size={28} /> : <Menu size={28} />}
                </button>
            </div>

            {/* Mobile Menu Overlay */}
            <AnimatePresence>
                {mobileMenuOpen && (
                    <motion.div
                        initial={{ opacity: 0, y: -20 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: -20 }}
                        className="absolute top-full left-0 w-full bg-brand-primary border-t border-white/10 p-6 lg:hidden shadow-xl"
                    >
                        <nav className="flex flex-col gap-4">
                            {navLinks.map((link) => (
                                <a
                                    key={link.name}
                                    href={link.href}
                                    className="text-white/80 hover:text-brand-accent text-lg font-medium cursor-pointer"
                                    onClick={(e) => scrollToSection(e, link.href)}
                                >
                                    {link.name}
                                </a>
                            ))}
                            <div className="pt-4 border-t border-white/10 flex justify-center">
                                <div className="flex flex-col gap-3 w-full">
                                    <div className="flex items-center justify-center gap-3 bg-white/5 border border-white/10 px-4 py-3 rounded-xl opacity-60 w-full">
                                        <Image
                                            src="/assets/icons8-app-store-100.png"
                                            alt="App Store"
                                            width={24}
                                            height={24}
                                            className="w-6 h-6 grayscale"
                                        />
                                        <div className="text-left">
                                            <p className="text-[10px] uppercase tracking-wider text-white/50 leading-none mb-1">iOS App</p>
                                            <p className="text-sm font-bold text-white/70 leading-none">Coming Soon</p>
                                        </div>
                                    </div>
                                    <a href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith" target="_blank" rel="noopener noreferrer" className="flex items-center justify-center gap-3 bg-white/10 border border-white/20 px-4 py-3 rounded-xl hover:bg-white/20 transition-all w-full">
                                        <Image
                                            src="/assets/icons8-google-play-store-100.png"
                                            alt="Google Play"
                                            width={24}
                                            height={24}
                                            className="w-6 h-6"
                                        />
                                        <div className="text-left">
                                            <p className="text-[10px] uppercase tracking-wider text-white/70 leading-none mb-1">Get it on</p>
                                            <p className="text-sm font-bold text-white leading-none">Google Play</p>
                                        </div>
                                    </a>
                                </div>
                            </div>
                        </nav>
                    </motion.div>
                )}
            </AnimatePresence>
        </header>
    );
}
