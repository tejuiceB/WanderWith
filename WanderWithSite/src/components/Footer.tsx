import Link from "next/link";
import Image from "next/image";

const footerLinks = {
    product: [
        { name: "Features", href: "/#features" },
        { name: "How It Works", href: "/#how-it-works" },
        { name: "Blog", href: "/blog" },
        { name: "Download", href: "https://play.google.com/store/apps/details?id=com.tejuice.wanderwith" },
    ],
    company: [
        { name: "About", href: "/#about" },
        { name: "Contact", href: "mailto:wanderwithplan@gmail.com" },
    ],
    legal: [
        { name: "Privacy Policy", href: "/privacy" },
        { name: "Terms & Conditions", href: "/terms" },
    ],
    compare: [
        { name: "Trip Planning App", href: "/trip-planning-app" },
        { name: "Wanderlog Alternative", href: "/alternatives/wanderlog" },
        { name: "TripIt Alternative", href: "/alternatives/tripit" },
    ],
};

export default function Footer() {
    return (
        <footer className="bg-brand-dark text-brand-dark-text">
            <div className="mx-auto max-w-7xl px-5 sm:px-8 pt-16 pb-8">
                {/* Links grid */}
                <div className="grid grid-cols-2 md:grid-cols-5 gap-8 pb-12">
                    {/* Brand column */}
                    <div className="col-span-2 md:col-span-1 mb-4 md:mb-0">
                        <div className="flex items-center gap-2 mb-4">
                            <Image src="/logo.png" alt="WanderWith" width={28} height={28} />
                            <span className="text-lg font-semibold text-white">WanderWith</span>
                        </div>
                        <p className="text-sm text-brand-text-tertiary leading-relaxed max-w-xs">
                            The all-in-one trip planner for solo travelers, friend groups, and travel agencies.
                        </p>
                    </div>

                    {/* Product */}
                    <div>
                        <h4 className="text-xs font-semibold uppercase tracking-widest text-brand-text-tertiary mb-4">Product</h4>
                        <ul className="space-y-3">
                            {footerLinks.product.map((link) => (
                                <li key={link.name}>
                                    <Link href={link.href} className="text-sm text-brand-text-secondary hover:text-white transition-colors">
                                        {link.name}
                                    </Link>
                                </li>
                            ))}
                        </ul>
                    </div>

                    {/* Compare */}
                    <div>
                        <h4 className="text-xs font-semibold uppercase tracking-widest text-brand-text-tertiary mb-4">Compare</h4>
                        <ul className="space-y-3">
                            {footerLinks.compare.map((link) => (
                                <li key={link.name}>
                                    <Link href={link.href} className="text-sm text-brand-text-secondary hover:text-white transition-colors">
                                        {link.name}
                                    </Link>
                                </li>
                            ))}
                        </ul>
                    </div>

                    {/* Company */}
                    <div>
                        <h4 className="text-xs font-semibold uppercase tracking-widest text-brand-text-tertiary mb-4">Company</h4>
                        <ul className="space-y-3">
                            {footerLinks.company.map((link) => (
                                <li key={link.name}>
                                    <Link href={link.href} className="text-sm text-brand-text-secondary hover:text-white transition-colors">
                                        {link.name}
                                    </Link>
                                </li>
                            ))}
                        </ul>
                    </div>

                    {/* Legal */}
                    <div>
                        <h4 className="text-xs font-semibold uppercase tracking-widest text-brand-text-tertiary mb-4">Legal</h4>
                        <ul className="space-y-3">
                            {footerLinks.legal.map((link) => (
                                <li key={link.name}>
                                    <Link href={link.href} className="text-sm text-brand-text-secondary hover:text-white transition-colors">
                                        {link.name}
                                    </Link>
                                </li>
                            ))}
                        </ul>
                    </div>
                </div>

                {/* Divider */}
                <div className="border-t border-brand-dark-border" />

                {/* Bottom bar */}
                <div className="flex flex-col sm:flex-row items-center justify-between pt-8 gap-4">
                    <p className="text-xs text-brand-text-tertiary">
                        &copy; {new Date().getFullYear()} WanderWith. All rights reserved.
                    </p>
                    <div className="flex items-center gap-4 text-xs text-brand-text-tertiary">
                        <span>Made with ❤️ in India 🇮🇳</span>
                        <a href="mailto:wanderwithplan@gmail.com" className="hover:text-white transition-colors">
                            wanderwithplan@gmail.com
                        </a>
                    </div>
                </div>
            </div>
        </footer>
    );
}
