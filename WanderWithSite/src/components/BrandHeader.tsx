"use client";

import React from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { Download } from 'lucide-react';

export default function BrandHeader() {
    return (
        <header className="fixed top-0 left-0 w-full z-[100] bg-brand-primary/95 backdrop-blur-md py-3 shadow-lg">
            <div className="container mx-auto px-6 flex items-center justify-between">
                <Link href="/" className="flex items-center gap-2 group">
                    <div className="relative w-10 h-10 group-hover:scale-105 transition-transform">
                        <Image src="/logo.png" alt="WanderWith Logo" fill className="object-contain" />
                    </div>
                    <span className="text-xl font-bold text-white tracking-wide">
                        WanderWith
                    </span>
                </Link>

                <button
                    onClick={() => window.open('https://play.google.com/store/apps/details?id=com.tejuice.wanderwith', '_blank')}
                    className="bg-brand-accent text-white px-5 py-2 rounded-full text-sm font-bold flex items-center gap-2 hover:opacity-90 transition-all cursor-pointer"
                >
                    <Download size={16} />
                    Get the App
                </button>
            </div>
        </header>
    );
}
