"use client";

import { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { BlogPost, BlogCategory } from "@/lib/blogData";
import CategoryFilter from "@/components/CategoryFilter";

export default function BlogListingClient({ posts }: { posts: BlogPost[] }) {
    const [activeCategory, setActiveCategory] = useState<BlogCategory | "All">("All");

    const filteredPosts = activeCategory === "All"
        ? posts
        : posts.filter((p) => p.category === activeCategory);

    const featuredPost = filteredPosts[0];
    const regularPosts = filteredPosts.slice(1);

    return (
        <>
            {/* Hero */}
            <section className="pt-32 pb-12 border-b border-gray-100">
                <div className="container mx-auto px-6 max-w-5xl">
                    <h1 className="text-5xl md:text-[5rem] font-bold text-gray-900 mb-6 font-serif tracking-tight">
                        WanderWith Blog
                    </h1>
                    <p className="text-xl md:text-2xl text-gray-500 max-w-2xl font-light">
                        Expert guides, product updates, and stories on modern travel planning.
                    </p>
                </div>
            </section>

            {/* Category Filter */}
            <section className="py-6 border-b border-gray-100">
                <div className="container mx-auto px-6 max-w-5xl">
                    <CategoryFilter activeCategory={activeCategory} onCategoryChange={setActiveCategory} />
                </div>
            </section>

            {/* Featured Post */}
            {featuredPost && (
                <section className="py-12 border-b border-gray-100">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <Link href={`/blog/${featuredPost.slug}`} className="group block">
                            <div className="grid md:grid-cols-2 gap-8 md:gap-12 items-center">
                                <div className="relative h-[250px] md:h-[400px] rounded-lg overflow-hidden bg-gray-100">
                                    <Image
                                        src={featuredPost.heroImage}
                                        alt={featuredPost.heroAlt}
                                        fill
                                        className="object-cover group-hover:scale-105 transition-transform duration-700"
                                        priority
                                        sizes="(max-width: 768px) 100vw, 50vw"
                                    />
                                </div>
                                <div>
                                    <div className="flex items-center gap-3 mb-4">
                                        <span className="bg-brand-accent/10 text-brand-accent text-xs font-semibold px-3 py-1 rounded-full">
                                            {featuredPost.category}
                                        </span>
                                        <span className="text-xs text-gray-500">
                                            {new Date(featuredPost.publishedDate).toLocaleDateString("en-US", { month: "long", day: "numeric" })}
                                        </span>
                                        <span className="text-xs text-gray-500">&middot;</span>
                                        <span className="text-xs text-gray-500">{featuredPost.readTime}</span>
                                    </div>
                                    <h2 className="text-3xl md:text-5xl font-bold font-serif text-gray-900 group-hover:text-brand-accent transition-colors leading-tight mb-4">
                                        {featuredPost.title}
                                    </h2>
                                    <p className="text-lg text-gray-600 leading-relaxed mb-6">
                                        {featuredPost.description}
                                    </p>
                                    <div className="flex items-center gap-3">
                                        <div className="w-10 h-10 rounded-full bg-brand-primary flex items-center justify-center text-white font-serif font-bold text-sm">
                                            W
                                        </div>
                                        <span className="text-sm font-medium text-gray-900">{featuredPost.author}</span>
                                    </div>
                                </div>
                            </div>
                        </Link>
                    </div>
                </section>
            )}

            {/* Blog Grid */}
            {regularPosts.length > 0 && (
                <section className="py-16">
                    <div className="container mx-auto px-6 max-w-5xl">
                        <h3 className="text-xl font-bold text-gray-900 font-serif mb-10 pb-4 border-b border-gray-100">
                            {activeCategory === "All" ? "Latest Stories" : activeCategory}
                        </h3>
                        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-x-8 gap-y-12">
                            {regularPosts.map((post) => (
                                <Link
                                    key={post.slug}
                                    href={`/blog/${post.slug}`}
                                    className="group block"
                                >
                                    <div className="relative h-48 md:h-56 rounded-lg overflow-hidden bg-gray-100 mb-5">
                                        <Image
                                            src={post.heroImage}
                                            alt={post.heroAlt}
                                            fill
                                            className="object-cover group-hover:scale-105 transition-transform duration-700"
                                            sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
                                        />
                                        <div className="absolute top-3 left-3">
                                            <span className="bg-white/90 backdrop-blur-sm text-gray-700 text-[11px] font-semibold px-2.5 py-1 rounded-full">
                                                {post.category}
                                            </span>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-2 text-xs text-gray-500 mb-3">
                                        <span>{new Date(post.publishedDate).toLocaleDateString("en-US", { month: "short", day: "numeric" })}</span>
                                        <span>&middot;</span>
                                        <span>{post.readTime}</span>
                                    </div>
                                    <h2 className="text-xl lg:text-2xl font-bold text-gray-900 font-serif leading-snug group-hover:text-brand-accent transition-colors mb-3">
                                        {post.title}
                                    </h2>
                                    <p className="text-gray-600 line-clamp-2 leading-relaxed text-sm">
                                        {post.description}
                                    </p>
                                </Link>
                            ))}
                        </div>
                    </div>
                </section>
            )}
        </>
    );
}
