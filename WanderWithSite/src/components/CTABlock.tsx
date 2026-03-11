import Link from "next/link";
import { Download, ArrowRight } from "lucide-react";

export default function CTABlock() {
    return (
        <div className="mt-16 p-8 md:p-10 bg-gradient-to-br from-brand-primary to-[#1e293b] rounded-2xl text-white">
            <h3 className="text-2xl md:text-3xl font-bold font-serif mb-3">
                Plan your next trip smarter
            </h3>
            <p className="text-gray-300 text-[15px] leading-relaxed mb-6 max-w-lg">
                WanderWith is an AI-powered travel planning app designed for collaborative trip planning.
                Generate itineraries, track budgets, and coordinate with friends — all in one place.
            </p>
            <div className="flex flex-col sm:flex-row gap-3">
                <a
                    href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center justify-center gap-2 bg-white text-brand-primary px-6 py-3 rounded-full font-semibold text-sm hover:bg-gray-100 transition-colors"
                >
                    <Download className="w-4 h-4" />
                    Download Free
                </a>
                <Link
                    href="/features"
                    className="inline-flex items-center justify-center gap-2 border border-white/30 text-white px-6 py-3 rounded-full font-semibold text-sm hover:bg-white/10 transition-colors"
                >
                    Learn More
                    <ArrowRight className="w-4 h-4" />
                </Link>
            </div>
        </div>
    );
}
