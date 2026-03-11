"use client";

import { useState, useEffect, useRef } from "react";
import { Search, ChevronRight, Menu, X } from "lucide-react";
import { docSections, type DocItem } from "@/lib/docsData";

export default function DocsClient() {
    const [activeItem, setActiveItem] = useState<string>(docSections[0].items[0].id);
    const [searchQuery, setSearchQuery] = useState("");
    const [searchResults, setSearchResults] = useState<DocItem[]>([]);
    const [showSearch, setShowSearch] = useState(false);
    const [sidebarOpen, setSidebarOpen] = useState(false);
    const [tocHeadings, setTocHeadings] = useState<{ id: string; text: string }[]>([]);
    const contentRef = useRef<HTMLDivElement>(null);
    const searchRef = useRef<HTMLInputElement>(null);

    const currentItem = docSections
        .flatMap((s) => s.items)
        .find((item) => item.id === activeItem);

    // Extract h3 headings for right TOC
    useEffect(() => {
        if (!currentItem) return;
        const matches = [...currentItem.content.matchAll(/<h3>(.*?)<\/h3>/gi)];
        setTocHeadings(
            matches.map((m) => ({
                id: m[1]
                    .replace(/<[^>]*>/g, "")
                    .trim()
                    .toLowerCase()
                    .replace(/[^a-z0-9]+/g, "-")
                    .replace(/^-|-$/g, ""),
                text: m[1].replace(/<[^>]*>/g, "").trim(),
            }))
        );
    }, [currentItem]);

    // Inject IDs into h3 elements after render
    useEffect(() => {
        if (!contentRef.current) return;
        const h3s = contentRef.current.querySelectorAll("h3");
        h3s.forEach((h3) => {
            const id = h3.textContent
                ?.trim()
                .toLowerCase()
                .replace(/[^a-z0-9]+/g, "-")
                .replace(/^-|-$/g, "") || "";
            h3.id = id;
        });
    }, [activeItem]);

    // Search
    useEffect(() => {
        if (!searchQuery.trim()) {
            setSearchResults([]);
            return;
        }
        const q = searchQuery.toLowerCase();
        const results = docSections
            .flatMap((s) => s.items)
            .filter(
                (item) =>
                    item.title.toLowerCase().includes(q) ||
                    item.content.replace(/<[^>]*>/g, "").toLowerCase().includes(q)
            );
        setSearchResults(results);
    }, [searchQuery]);

    // Keyboard shortcut for search
    useEffect(() => {
        const handler = (e: KeyboardEvent) => {
            if ((e.metaKey || e.ctrlKey) && e.key === "k") {
                e.preventDefault();
                setShowSearch(true);
                setTimeout(() => searchRef.current?.focus(), 100);
            }
            if (e.key === "Escape") {
                setShowSearch(false);
                setSearchQuery("");
            }
        };
        window.addEventListener("keydown", handler);
        return () => window.removeEventListener("keydown", handler);
    }, []);

    const navigateTo = (itemId: string) => {
        setActiveItem(itemId);
        setSidebarOpen(false);
        setShowSearch(false);
        setSearchQuery("");
        window.scrollTo({ top: 0, behavior: "smooth" });
    };

    // Find next/prev items for navigation
    const allItems = docSections.flatMap((s) => s.items);
    const currentIndex = allItems.findIndex((item) => item.id === activeItem);
    const prevItem = currentIndex > 0 ? allItems[currentIndex - 1] : null;
    const nextItem = currentIndex < allItems.length - 1 ? allItems[currentIndex + 1] : null;

    return (
        <div className="min-h-screen bg-white">
            {/* Search overlay */}
            {showSearch && (
                <div className="fixed inset-0 z-50 bg-black/50 flex items-start justify-center pt-[15vh]" onClick={() => { setShowSearch(false); setSearchQuery(""); }}>
                    <div className="bg-white rounded-2xl shadow-2xl w-full max-w-xl mx-4 overflow-hidden" onClick={(e) => e.stopPropagation()}>
                        <div className="flex items-center gap-3 px-5 py-4 border-b border-gray-100">
                            <Search className="w-5 h-5 text-gray-400 shrink-0" />
                            <input
                                ref={searchRef}
                                type="text"
                                placeholder="Search documentation..."
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                                className="flex-1 text-lg outline-none placeholder:text-gray-400"
                                autoFocus
                            />
                            <kbd className="hidden sm:inline-flex text-xs text-gray-400 bg-gray-100 px-2 py-1 rounded">Esc</kbd>
                        </div>
                        {searchResults.length > 0 && (
                            <div className="max-h-80 overflow-y-auto py-2">
                                {searchResults.map((item) => (
                                    <button
                                        key={item.id}
                                        onClick={() => navigateTo(item.id)}
                                        className="w-full text-left px-5 py-3 hover:bg-gray-50 transition-colors"
                                    >
                                        <p className="font-medium text-gray-900">{item.title}</p>
                                        <p className="text-sm text-gray-500 mt-0.5 line-clamp-1">
                                            {item.content.replace(/<[^>]*>/g, "").slice(0, 100)}...
                                        </p>
                                    </button>
                                ))}
                            </div>
                        )}
                        {searchQuery && searchResults.length === 0 && (
                            <div className="px-5 py-8 text-center text-gray-500">
                                No results found for &quot;{searchQuery}&quot;
                            </div>
                        )}
                    </div>
                </div>
            )}

            {/* Mobile sidebar toggle */}
            <button
                className="fixed bottom-6 right-6 z-40 lg:hidden bg-brand-primary text-white p-3 rounded-full shadow-lg"
                onClick={() => setSidebarOpen(!sidebarOpen)}
                aria-label="Toggle navigation"
            >
                {sidebarOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>

            <div className="max-w-[1400px] mx-auto flex">
                {/* Left Sidebar */}
                <aside className={`fixed lg:sticky top-16 left-0 z-30 h-[calc(100vh-4rem)] w-72 shrink-0 overflow-y-auto border-r border-gray-100 bg-white transition-transform lg:translate-x-0 ${sidebarOpen ? "translate-x-0" : "-translate-x-full"}`}>
                    <div className="p-6">
                        {/* Search trigger */}
                        <button
                            onClick={() => { setShowSearch(true); setTimeout(() => searchRef.current?.focus(), 100); }}
                            className="w-full flex items-center gap-2.5 px-3.5 py-2.5 rounded-xl border border-gray-200 text-sm text-gray-500 hover:border-gray-300 hover:text-gray-700 transition-colors mb-6"
                        >
                            <Search className="w-4 h-4" />
                            <span className="flex-1 text-left">Search docs...</span>
                            <kbd className="hidden sm:inline-flex text-xs text-gray-400 bg-gray-100 px-1.5 py-0.5 rounded">⌘K</kbd>
                        </button>

                        {/* Navigation */}
                        <nav className="space-y-6">
                            {docSections.map((section) => (
                                <div key={section.id}>
                                    <h3 className="text-xs font-semibold uppercase tracking-wider text-gray-400 mb-2 px-2">
                                        {section.title}
                                    </h3>
                                    <ul className="space-y-0.5">
                                        {section.items.map((item) => (
                                            <li key={item.id}>
                                                <button
                                                    onClick={() => navigateTo(item.id)}
                                                    className={`w-full text-left px-3 py-2 rounded-lg text-sm transition-colors ${
                                                        activeItem === item.id
                                                            ? "bg-brand-accent/10 text-brand-accent font-medium"
                                                            : "text-gray-600 hover:bg-gray-50 hover:text-gray-900"
                                                    }`}
                                                >
                                                    {item.title}
                                                </button>
                                            </li>
                                        ))}
                                    </ul>
                                </div>
                            ))}
                        </nav>
                    </div>
                </aside>

                {/* Mobile backdrop */}
                {sidebarOpen && (
                    <div className="fixed inset-0 z-20 bg-black/30 lg:hidden" onClick={() => setSidebarOpen(false)} />
                )}

                {/* Main content */}
                <main className="flex-1 min-w-0 px-6 sm:px-10 lg:px-16 py-10">
                    {/* Breadcrumb */}
                    <nav className="flex items-center gap-1.5 text-sm text-gray-500 mb-8">
                        <a href="/" className="hover:text-brand-accent transition-colors">Home</a>
                        <ChevronRight className="w-3.5 h-3.5" />
                        <a href="/docs" className="hover:text-brand-accent transition-colors">Docs</a>
                        <ChevronRight className="w-3.5 h-3.5" />
                        <span className="text-gray-900 font-medium">{currentItem?.title}</span>
                    </nav>

                    {/* Page title */}
                    <h1 className="text-3xl md:text-4xl font-bold text-gray-900 font-serif tracking-tight mb-8">
                        {currentItem?.title}
                    </h1>

                    {/* Content */}
                    <div
                        ref={contentRef}
                        className="prose prose-lg max-w-none prose-headings:font-serif prose-headings:tracking-tight prose-h3:text-xl prose-h3:mt-10 prose-h3:mb-4 prose-p:text-gray-600 prose-p:leading-relaxed prose-li:text-gray-600 prose-a:text-brand-accent prose-a:no-underline hover:prose-a:underline prose-strong:text-gray-900 prose-ol:space-y-2 prose-ul:space-y-2 [&_.doc-tip]:bg-brand-accent/5 [&_.doc-tip]:border-l-4 [&_.doc-tip]:border-brand-accent [&_.doc-tip]:rounded-r-xl [&_.doc-tip]:p-5 [&_.doc-tip]:my-6 [&_.doc-tip_strong]:text-brand-accent [&_.doc-tip_strong]:block [&_.doc-tip_strong]:mb-1 [&_.doc-tip_p]:text-gray-600 [&_.doc-tip_p]:m-0 [&_.doc-note]:bg-amber-50 [&_.doc-note]:border-l-4 [&_.doc-note]:border-amber-400 [&_.doc-note]:rounded-r-xl [&_.doc-note]:p-5 [&_.doc-note]:my-6 [&_.doc-note_strong]:text-amber-700 [&_.doc-note_strong]:block [&_.doc-note_strong]:mb-1 [&_.doc-note_p]:text-gray-600 [&_.doc-note_p]:m-0"
                        dangerouslySetInnerHTML={{ __html: currentItem?.content || "" }}
                    />

                    {/* Prev / Next navigation */}
                    <div className="mt-16 pt-8 border-t border-gray-100 flex items-center justify-between gap-4">
                        {prevItem ? (
                            <button
                                onClick={() => navigateTo(prevItem.id)}
                                className="group text-left"
                            >
                                <span className="text-xs text-gray-400 uppercase tracking-wide">Previous</span>
                                <p className="text-brand-accent font-medium group-hover:underline mt-0.5">&larr; {prevItem.title}</p>
                            </button>
                        ) : <div />}
                        {nextItem ? (
                            <button
                                onClick={() => navigateTo(nextItem.id)}
                                className="group text-right"
                            >
                                <span className="text-xs text-gray-400 uppercase tracking-wide">Next</span>
                                <p className="text-brand-accent font-medium group-hover:underline mt-0.5">{nextItem.title} &rarr;</p>
                            </button>
                        ) : <div />}
                    </div>
                </main>

                {/* Right TOC */}
                <aside className="hidden xl:block w-56 shrink-0 sticky top-16 h-[calc(100vh-4rem)] overflow-y-auto py-10 pr-6">
                    {tocHeadings.length > 0 && (
                        <div>
                            <h4 className="text-xs font-semibold uppercase tracking-wider text-gray-400 mb-3">
                                On this page
                            </h4>
                            <ul className="space-y-2">
                                {tocHeadings.map((h) => (
                                    <li key={h.id}>
                                        <a
                                            href={`#${h.id}`}
                                            className="text-sm text-gray-500 hover:text-brand-accent transition-colors block"
                                            onClick={(e) => {
                                                e.preventDefault();
                                                document.getElementById(h.id)?.scrollIntoView({ behavior: "smooth", block: "start" });
                                            }}
                                        >
                                            {h.text}
                                        </a>
                                    </li>
                                ))}
                            </ul>
                        </div>
                    )}
                </aside>
            </div>
        </div>
    );
}
