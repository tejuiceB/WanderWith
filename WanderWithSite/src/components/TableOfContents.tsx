"use client";

import { useEffect, useState } from "react";

interface TOCItem {
    id: string;
    text: string;
}

export default function TableOfContents({ content }: { content: string }) {
    const [headings, setHeadings] = useState<TOCItem[]>([]);
    const [activeId, setActiveId] = useState<string>("");

    useEffect(() => {
        const regex = /<h2[^>]*>(.*?)<\/h2>/gi;
        const items: TOCItem[] = [];
        let match;
        while ((match = regex.exec(content)) !== null) {
            const text = match[1].replace(/<[^>]*>/g, "").trim();
            const id = text
                .toLowerCase()
                .replace(/[^a-z0-9]+/g, "-")
                .replace(/^-|-$/g, "");
            items.push({ id, text });
        }
        setHeadings(items);
    }, [content]);

    useEffect(() => {
        if (headings.length === 0) return;

        const observer = new IntersectionObserver(
            (entries) => {
                const visible = entries.find((e) => e.isIntersecting);
                if (visible) setActiveId(visible.target.id);
            },
            { rootMargin: "-80px 0px -60% 0px", threshold: 0.1 }
        );

        headings.forEach(({ id }) => {
            const el = document.getElementById(id);
            if (el) observer.observe(el);
        });

        return () => observer.disconnect();
    }, [headings]);

    if (headings.length < 2) return null;

    return (
        <nav className="hidden xl:block" aria-label="Table of contents">
            <div className="sticky top-28">
                <p className="text-xs font-semibold text-gray-400 uppercase tracking-widest mb-4">
                    On this page
                </p>
                <ul className="space-y-2 border-l border-gray-200">
                    {headings.map(({ id, text }) => (
                        <li key={id}>
                            <a
                                href={`#${id}`}
                                onClick={(e) => {
                                    e.preventDefault();
                                    document.getElementById(id)?.scrollIntoView({ behavior: "smooth" });
                                }}
                                className={`block pl-4 py-1 text-[13px] leading-snug transition-colors border-l-2 -ml-px ${
                                    activeId === id
                                        ? "border-brand-accent text-brand-accent font-medium"
                                        : "border-transparent text-gray-500 hover:text-gray-900"
                                }`}
                            >
                                {text}
                            </a>
                        </li>
                    ))}
                </ul>
            </div>
        </nav>
    );
}
