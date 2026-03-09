"use client";

import { ReactNode } from "react";

interface PhoneMockupProps {
    children: ReactNode;
    className?: string;
}

export default function PhoneMockup({ children, className = "" }: PhoneMockupProps) {
    return (
        <div className={`relative mx-auto ${className}`} style={{ maxWidth: 300 }}>
            {/* Phone frame */}
            <div className="relative bg-brand-dark rounded-[3rem] p-3 shadow-2xl shadow-black/30 ring-1 ring-white/10">
                {/* Notch */}
                <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[120px] h-[28px] bg-brand-dark rounded-b-2xl z-10" />
                {/* Screen */}
                <div className="relative rounded-[2.4rem] overflow-hidden bg-black aspect-[9/19.5]">
                    {children}
                </div>
            </div>
        </div>
    );
}
