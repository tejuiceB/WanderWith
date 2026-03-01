'use client';

import React, { useState } from 'react';
import { ExternalLink } from 'lucide-react';

interface OpenInAppButtonProps {
    path: string; // e.g., "p/post-id" or "u/username"
    label?: string;
}

export default function OpenInAppButton({ path, label = 'Open in App' }: OpenInAppButtonProps) {
    const [isAttempting, setIsAttempting] = useState(false);

    const handleOpen = (e: React.MouseEvent) => {
        e.preventDefault();
        setIsAttempting(true);

        const appUrl = `wanderwith://wanderwith.online/${path}`;
        // Direct link to Play Store for WanderWith
        const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.tejuice.wanderwith';

        // 1. Try to open the app
        window.location.href = appUrl;

        // 2. Fallback to Play Store if app doesn't open
        const timer = setTimeout(() => {
            window.location.href = playStoreUrl;
        }, 2500);

        // Clean up if the browser handles the protocol and pauses
        window.addEventListener('blur', () => clearTimeout(timer), { once: true });
    };

    return (
        <button
            onClick={handleOpen}
            disabled={isAttempting}
            className={`bg-brand-teal text-white px-6 py-2.5 rounded-2xl font-bold flex items-center gap-2 hover:scale-[1.02] active:scale-95 transition-all cursor-pointer shadow-md ${isAttempting ? 'opacity-70 animate-pulse' : ''}`}
        >
            <ExternalLink size={18} />
            {isAttempting ? 'Opening...' : label}
        </button>
    );
}
