"use client";

import React from 'react';
import { Download } from 'lucide-react';

interface InstallAppBannerProps {
    title?: string;
    subtitle?: string;
}

export default function InstallAppBanner({
    title = "Unlock the Full Experience",
    subtitle = "Download the WanderWith app to join trips, like posts, and connect with fellow explorers."
}: InstallAppBannerProps) {
    return (
        <div className="bg-brand-button/10 border border-brand-button/20 rounded-2xl p-6 flex flex-col md:flex-row items-center justify-between gap-6 my-8">
            <div className="text-center md:text-left">
                <h3 className="text-xl font-bold text-brand-text mb-2 tracking-tight">{title}</h3>
                <p className="text-brand-text/70">{subtitle}</p>
            </div>
            <button
                onClick={() => window.open('https://play.google.com/store/apps/details?id=com.tejuice.wanderwith', '_blank')}
                className="bg-brand-button text-white px-8 py-3 rounded-full font-bold flex items-center gap-2 hover:opacity-90 transition-all cursor-pointer whitespace-nowrap"
            >
                <Download size={20} />
                Get the App
            </button>
        </div>
    );
}
