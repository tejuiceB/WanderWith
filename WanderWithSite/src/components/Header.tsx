"use client";

import { useState, useEffect } from "react";
import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { motion, AnimatePresence } from "framer-motion";
import { Menu, X } from "lucide-react";

export default function Header() {
    const [scrolled, setScrolled] = useState(false);
    const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
    const pathname = usePathname();
    const isHomePage = pathname === "/";

    useEffect(() => {
        const handleScroll = () => setScrolled(window.scrollY > 20);
        window.addEventListener("scroll", handleScroll);
        return () => window.removeEventListener("scroll", handleScroll);
    }, []);

    useEffect(() => {
        document.body.style.overflow = mobileMenuOpen ? "hidden" : "";
        return () => { document.body.style.overflow = ""; };
    }, [mobileMenuOpen]);

    const navLinks = [
        { name: "Features", href: "/features" },
        { name: "Use Cases", href: "/use-cases" },
        { name: "About", href: "/about" },
        { name: "Blog", href: "/blog" },
        { name: "Docs", href: "/docs" },
    ];

    const scrollToSection = (e: React.MouseEvent<HTMLAnchorElement>, href: string) => {
        if (href.startsWith("/#") && isHomePage) {
            e.preventDefault();
            const id = href.replace("/#", "");
            const el = document.getElementById(id);
            if (el) {
                el.scrollIntoView({ behavior: "smooth" });
                setMobileMenuOpen(false);
            }
        } else {
            setMobileMenuOpen(false);
        }
    };

    return (
        <header
            className={`fixed top-0 left-0 w-full z-[100] transition-all duration-300 ${
                scrolled
                    ? "bg-white/80 backdrop-blur-xl border-b border-brand-border shadow-sm"
                    : "bg-transparent"
            }`}
        >
            <div className="mx-auto max-w-7xl px-5 sm:px-8 h-16 flex items-center justify-between">
                <Link href="/" className="flex items-center gap-2.5 shrink-0">
                    <div className="relative w-8 h-8">
                        <Image src="/logo.png" alt="WanderWith" fill className="object-contain" />
                    </div>
                    <span className="text-[17px] font-semibold tracking-tight text-brand-primary">
                        WanderWith
                    </span>
                </Link>

                <nav className="hidden lg:flex items-center gap-8">
                    {navLinks.map((link) => (
                        <Link
                            key={link.name}
                            href={link.href}
                            onClick={(e) => scrollToSection(e, link.href)}
                            className="text-[14px] font-medium text-brand-text-secondary hover:text-brand-primary transition-colors"
                        >
                            {link.name}
                        </Link>
                    ))}
                </nav>

                <div className="hidden lg:flex items-center gap-3">
                    <a
                        href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center gap-2 bg-brand-primary text-white px-5 py-2 rounded-full text-[13px] font-semibold hover:bg-brand-primary/90 transition-all hover:shadow-lg hover:shadow-brand-primary/15"
                    >
                        <Image
                            src="/assets/icons8-google-play-store-100.png"
                            alt="Google Play"
                            width={16}
                            height={16}
                        />
                        Download App
                    </a>
                </div>

                <button
                    className="lg:hidden p-2 -mr-2 text-brand-primary"
                    onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                    aria-label="Toggle menu"
                >
                    {mobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
                </button>
            </div>

            <AnimatePresence>
                {mobileMenuOpen && (
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        transition={{ duration: 0.2 }}
                        className="fixed inset-0 top-16 bg-white z-[99] lg:hidden"
                    >
                        <nav className="flex flex-col items-center justify-center h-full gap-8 -mt-16">
                            {navLinks.map((link, i) => (
                                <motion.div
                                    key={link.name}
                                    initial={{ opacity: 0, y: 20 }}
                                    animate={{ opacity: 1, y: 0 }}
                                    transition={{ delay: i * 0.05 }}
                                >
                                    <Link
                                        href={link.href}
                                        onClick={(e) => scrollToSection(e, link.href)}
                                        className="text-2xl font-semibold text-brand-primary hover:text-brand-accent transition-colors"
                                    >
                                        {link.name}
                                    </Link>
                                </motion.div>
                            ))}
                            <motion.div
                                initial={{ opacity: 0, y: 20 }}
                                animate={{ opacity: 1, y: 0 }}
                                transition={{ delay: 0.2 }}
                            >
                                <a
                                    href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="inline-flex items-center gap-2 bg-brand-primary text-white px-8 py-3.5 rounded-full text-base font-semibold hover:bg-brand-primary/90 transition-all"
                                >
                                    <Image
                                        src="/assets/icons8-google-play-store-100.png"
                                        alt="Google Play"
                                        width={20}
                                        height={20}
                                    />
                                    Download App
                                </a>
                            </motion.div>
                        </nav>
                    </motion.div>
                )}
            </AnimatePresence>
        </header>
    );
}
