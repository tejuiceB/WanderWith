"use client";

import { useState } from "react";
import { BlogCategory, blogCategories } from "@/lib/blogData";

interface CategoryFilterProps {
    activeCategory: BlogCategory | "All";
    onCategoryChange: (category: BlogCategory | "All") => void;
}

export default function CategoryFilter({ activeCategory, onCategoryChange }: CategoryFilterProps) {
    return (
        <div className="flex flex-wrap gap-2">
            <button
                onClick={() => onCategoryChange("All")}
                className={`px-4 py-2 rounded-full text-sm font-medium transition-colors ${
                    activeCategory === "All"
                        ? "bg-brand-primary text-white"
                        : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                }`}
            >
                All
            </button>
            {blogCategories.map((cat) => (
                <button
                    key={cat}
                    onClick={() => onCategoryChange(cat)}
                    className={`px-4 py-2 rounded-full text-sm font-medium transition-colors ${
                        activeCategory === cat
                            ? "bg-brand-primary text-white"
                            : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                    }`}
                >
                    {cat}
                </button>
            ))}
        </div>
    );
}
