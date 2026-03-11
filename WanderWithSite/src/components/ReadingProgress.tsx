"use client";

import { useEffect, useState } from "react";

export default function ReadingProgress() {
    const [progress, setProgress] = useState(0);

    useEffect(() => {
        function handleScroll() {
            const el = document.documentElement;
            const scrollTop = el.scrollTop;
            const scrollHeight = el.scrollHeight - el.clientHeight;
            setProgress(scrollHeight > 0 ? (scrollTop / scrollHeight) * 100 : 0);
        }
        window.addEventListener("scroll", handleScroll, { passive: true });
        return () => window.removeEventListener("scroll", handleScroll);
    }, []);

    return (
        <div className="fixed top-0 left-0 right-0 z-50 h-1 bg-gray-100">
            <div
                className="h-full bg-brand-accent transition-[width] duration-150"
                style={{ width: `${progress}%` }}
            />
        </div>
    );
}
