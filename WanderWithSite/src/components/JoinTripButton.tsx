'use client';

import React, { useState, useEffect } from 'react';
import { ChevronRight } from 'lucide-react';

interface JoinTripButtonProps {
    code: string;
}

export default function JoinTripButton({ code }: JoinTripButtonProps) {
    const [isAttempting, setIsAttempting] = useState(false);

    const handleJoin = (e: React.MouseEvent) => {
        e.preventDefault();
        setIsAttempting(true);

        const appUrl = `wanderwith://wanderwith.online/join/${code}`;
        const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.tejuice.wanderwith';

        // 1. Try to open the app
        window.location.href = appUrl;

        // 2. Set a timeout to redirect to download page if app doesn't open
        // If the app opens, the browser usually pauses JS or hides the page
        const timer = setTimeout(() => {
            window.location.href = playStoreUrl;
        }, 2500);

        // Clean up if user comes back or something
        window.addEventListener('blur', () => clearTimeout(timer), { once: true });
    };

    return (
        <button
            onClick={handleJoin}
            disabled={isAttempting}
            className={`w-full bg-brand-accent text-white py-4 rounded-2xl font-black text-lg shadow-lg hover:scale-[1.02] active:scale-95 transition-all cursor-pointer flex items-center justify-center gap-2 text-center ${isAttempting ? 'opacity-70 animate-pulse' : ''}`}
        >
            {isAttempting ? 'Opening WanderWith...' : 'Join this Trip'}
            <ChevronRight size={20} />
        </button>
    );
}
