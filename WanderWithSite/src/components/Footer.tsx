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
                        <h4 className="text-white font-semibold mb-4">Download</h4>
                        <div className="flex items-center gap-3 mb-4">
                            <a
                                href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="inline-block"
                            >
                                <img
                                    src="/assets/icons8-google-play-store-100.png"
                                    alt="Get it on Google Play"
                                    className="h-10 hover:scale-105 transition-transform"
                                />
                            </a>
                            <div className="opacity-40 grayscale flex items-center bg-white/5 rounded-lg px-2 h-10 border border-white/10">
                                <img
                                    src="/assets/icons8-app-store-100.png"
                                    alt="App Store Coming Soon"
                                    className="h-6"
                                />
                                <span className="text-[10px] font-bold ml-1 text-white/70">COMING SOON</span>
                            </div>
                        </div>
                        <p className="text-sm mt-4">wanderwithplan@gmail.com</p>
                    </div>
                </div>

                <div className="flex flex-col md:flex-row justify-between items-center text-sm pt-8 border-t border-white/10">
                    <p>&copy; {new Date().getFullYear()} WanderWith. All rights reserved.</p>
                    <div className="flex flex-col md:flex-row items-center gap-4 mt-4 md:mt-0">
                        <span>Made with ❤️ in India 🇮🇳</span>
                        <span>wanderwithplan@gmail.com</span>
                    </div>
                </div>
            </div>
        </footer>
    );
}
