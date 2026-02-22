import Link from "next/link";
import { Twitter, Instagram, Linkedin } from "lucide-react";

export default function Footer() {
    return (
        <footer className="bg-brand-primary text-white/80 py-12 border-t border-white/10">
            <div className="container mx-auto px-6">
                <div className="grid md:grid-cols-4 gap-8 mb-12">
                    <div className="col-span-1 md:col-span-1">
                        <h3 className="text-white text-xl font-bold mb-4">WanderWith</h3>
                        <p className="text-sm leading-relaxed text-slate-400">
                            Built in India. <br />
                            For those who travel with intention.
                        </p>
                    </div>

                    <div>
                        <h4 className="text-white font-semibold mb-4">Company</h4>
                        <ul className="space-y-2 text-sm">
                            <li><Link href="#about" className="hover:text-white transition-colors">About Us</Link></li>
                            <li><Link href="#careers" className="hover:text-white transition-colors">Careers</Link></li>
                            <li><Link href="#blog" className="hover:text-white transition-colors">Blog</Link></li>
                        </ul>
                    </div>

                    <div>
                        <h4 className="text-white font-semibold mb-4">Legal</h4>
                        <ul className="space-y-2 text-sm">
                            <li><Link href="/privacy" className="hover:text-white transition-colors">Privacy Policy</Link></li>
                            <li><Link href="/terms" className="hover:text-white transition-colors">Terms & Conditions</Link></li>
                        </ul>
                    </div>

                    <div>
                        <h4 className="text-white font-semibold mb-4">Connect</h4>
                        <div className="flex gap-4">
                            <a href="#" className="hover:text-brand-accent transition-colors"><Twitter size={20} /></a>
                            <a href="#" className="hover:text-brand-accent transition-colors"><Instagram size={20} /></a>
                            <a href="#" className="hover:text-brand-accent transition-colors"><Linkedin size={20} /></a>
                        </div>
                        <p className="text-sm mt-4">support@wanderwith.com</p>
                    </div>
                </div>

                <div className="flex flex-col md:flex-row justify-between items-center text-sm pt-8 border-t border-white/10">
                    <p>&copy; {new Date().getFullYear()} WanderWith. All rights reserved.</p>
                    <div className="flex flex-col md:flex-row items-center gap-4 mt-4 md:mt-0">
                        <span>Made with ❤️ in India 🇮🇳</span>
                        <span>support@wanderwith.com</span>
                    </div>
                </div>
            </div>
        </footer>
    );
}
