"use client";

export function GooglePlayBadge({ className = "" }: { className?: string }) {
    return (
        <a
            href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
            target="_blank"
            rel="noopener noreferrer"
            className={`inline-flex items-center gap-3 bg-black text-white pl-4 pr-5 py-2.5 rounded-lg border border-white/10 transition-transform duration-200 hover:scale-[1.03] active:scale-[0.98] ${className}`}
        >
            {/* Google Play triangle SVG */}
            <svg width="24" height="27" viewBox="0 0 24 27" fill="none" className="shrink-0">
                <path d="M0.917 0.648C0.636 0.945 0.47 1.4 0.47 1.994V25.006C0.47 25.6 0.636 26.054 0.917 26.352L0.985 26.418L13.817 13.586V13.414L0.985 0.582L0.917 0.648Z" fill="url(#gp_a)" />
                <path d="M18.09 17.862L13.817 13.586V13.414L18.091 9.14L18.175 9.188L23.203 12.049C24.638 12.865 24.638 14.137 23.203 14.953L18.175 17.814L18.09 17.862Z" fill="url(#gp_b)" />
                <path d="M18.175 17.814L13.817 13.5L0.917 26.352C1.376 26.838 2.134 26.896 2.983 26.412L18.175 17.814Z" fill="url(#gp_c)" />
                <path d="M18.175 9.186L2.983 0.588C2.134 0.106 1.376 0.162 0.917 0.648L13.817 13.5L18.175 9.186Z" fill="url(#gp_d)" />
                <defs>
                    <linearGradient id="gp_a" x1="12.612" y1="1.874" x2="-4.117" y2="18.604" gradientUnits="userSpaceOnUse">
                        <stop stopColor="#00A0FF" /><stop offset="1" stopColor="#00A0FF" stopOpacity="0" />
                    </linearGradient>
                    <linearGradient id="gp_b" x1="25.145" y1="13.5" x2="-0.017" y2="13.5" gradientUnits="userSpaceOnUse">
                        <stop stopColor="#FFE000" /><stop offset="0.41" stopColor="#FFBD00" /><stop offset="0.78" stopColor="#FFA500" />
                    </linearGradient>
                    <linearGradient id="gp_c" x1="15.859" y1="15.824" x2="-6.19" y2="37.872" gradientUnits="userSpaceOnUse">
                        <stop stopColor="#FF3A44" /><stop offset="1" stopColor="#C31162" />
                    </linearGradient>
                    <linearGradient id="gp_d" x1="-1.839" y1="-5.943" x2="7.549" y2="3.445" gradientUnits="userSpaceOnUse">
                        <stop stopColor="#32A071" /><stop offset="0.07" stopColor="#2DA771" /><stop offset="0.48" stopColor="#15CF74" /><stop offset="0.8" stopColor="#06E775" /><stop offset="1" stopColor="#00F076" />
                    </linearGradient>
                </defs>
            </svg>
            <div className="flex flex-col">
                <span className="text-[10px] leading-none text-white/70 uppercase tracking-wider font-medium">Get it on</span>
                <span className="text-[17px] font-semibold leading-tight mt-0.5 tracking-tight">Google Play</span>
            </div>
        </a>
    );
}

export function AppStoreBadge({ className = "", comingSoon = true }: { className?: string; comingSoon?: boolean }) {
    const Wrapper = comingSoon ? "div" : "a";
    const linkProps = comingSoon ? {} : {
        href: "#",
        target: "_blank" as const,
        rel: "noopener noreferrer",
    };

    return (
        <div className={`relative ${className}`}>
            <Wrapper
                {...linkProps}
                className={`inline-flex items-center gap-3 bg-black text-white pl-4 pr-5 py-2.5 rounded-lg border border-white/10 transition-transform duration-200 ${comingSoon ? "opacity-60 cursor-default" : "hover:scale-[1.03] active:scale-[0.98]"}`}
            >
                {/* Apple logo SVG */}
                <svg width="20" height="24" viewBox="0 0 20 24" fill="white" className="shrink-0">
                    <path d="M16.57 12.632c-.027-2.756 2.253-4.088 2.355-4.152-1.287-1.878-3.284-2.135-3.99-2.16-1.685-.174-3.313 1.005-4.172 1.005-.873 0-2.196-.986-3.619-.957-1.838.028-3.55 1.087-4.494 2.736-1.939 3.355-.494 8.296 1.37 11.012.93 1.332 2.024 2.822 3.46 2.77 1.399-.058 1.922-.895 3.612-.895 1.676 0 2.163.895 3.618.863 1.5-.025 2.449-1.342 3.348-2.686 1.077-1.53 1.51-3.04 1.526-3.118-.034-.013-2.907-1.11-2.937-4.418h-.077ZM13.844 4.51c.753-.937 1.269-2.217 1.126-3.51-1.09.047-2.44.747-3.225 1.668-.697.82-1.322 2.157-1.16 3.417 1.22.093 2.471-.619 3.259-1.575Z" />
                </svg>
                <div className="flex flex-col">
                    <span className="text-[10px] leading-none text-white/70 uppercase tracking-wider font-medium">Download on the</span>
                    <span className="text-[17px] font-semibold leading-tight mt-0.5 tracking-tight">App Store</span>
                </div>
            </Wrapper>
            {comingSoon && (
                <span className="absolute -top-2 -right-3 text-[10px] font-bold bg-brand-accent text-white px-2 py-0.5 rounded-full shadow-sm">
                    Soon
                </span>
            )}
        </div>
    );
}
