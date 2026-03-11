"use client";

import { useState } from "react";
import { ChevronDown } from "lucide-react";

export interface FAQItem {
    question: string;
    answer: string;
}

export default function FAQ({ items }: { items: FAQItem[] }) {
    const [openIndex, setOpenIndex] = useState<number | null>(null);

    if (!items || items.length === 0) return null;

    return (
        <section className="mt-16 pt-8 border-t border-gray-100">
            <h2 className="text-2xl font-bold text-gray-900 font-serif mb-6">
                Frequently Asked Questions
            </h2>
            <div className="space-y-3">
                {items.map((item, i) => (
                    <div key={i} className="border border-gray-200 rounded-lg overflow-hidden">
                        <button
                            onClick={() => setOpenIndex(openIndex === i ? null : i)}
                            className="w-full flex items-center justify-between p-5 text-left hover:bg-gray-50 transition-colors"
                            aria-expanded={openIndex === i}
                        >
                            <span className="font-semibold text-gray-900 text-[15px] pr-4">
                                {item.question}
                            </span>
                            <ChevronDown
                                className={`w-5 h-5 text-gray-400 flex-shrink-0 transition-transform ${
                                    openIndex === i ? "rotate-180" : ""
                                }`}
                            />
                        </button>
                        {openIndex === i && (
                            <div className="px-5 pb-5 text-gray-600 text-[15px] leading-relaxed">
                                {item.answer}
                            </div>
                        )}
                    </div>
                ))}
            </div>
        </section>
    );
}
