import { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { blogPosts } from "@/lib/blogData";
import Footer from "@/components/Footer";
import { ArrowLeft } from "lucide-react";

interface BlogPostPageProps {
    params: Promise<{ slug: string }>;
}

export async function generateStaticParams() {
    return blogPosts.map((post) => ({
        slug: post.slug,
    }));
}

export async function generateMetadata({ params }: BlogPostPageProps): Promise<Metadata> {
    const { slug } = await params;
    const post = blogPosts.find((p) => p.slug === slug);
    if (!post) return { title: "Blog Post Not Found" };

    return {
        title: `${post.title} | WanderWith Blog`,
        description: post.description,
        keywords: post.keywords,
        authors: [{ name: post.author }],
        openGraph: {
            title: post.title,
            description: post.description,
            url: `https://www.wanderwith.online/blog/${post.slug}`,
            siteName: "WanderWith",
            type: "article",
            publishedTime: post.publishedDate,
            authors: [post.author],
            images: [
                {
                    url: post.heroImage,
                    width: 1200,
                    height: 630,
                    alt: post.heroAlt,
                },
            ],
        },
        twitter: {
            card: "summary_large_image",
            title: post.title,
            description: post.description,
            images: [post.heroImage],
        },
        alternates: {
            canonical: `https://www.wanderwith.online/blog/${post.slug}`,
        },
    };
}

export default async function BlogPostPage({ params }: BlogPostPageProps) {
    const { slug } = await params;
    const post = blogPosts.find((p) => p.slug === slug);

    if (!post) {
        notFound();
    }

    const relatedPosts = blogPosts.filter((p) => p.slug !== post.slug).slice(0, 3);

    // Schema.org Article structured data
    const jsonLd = {
        "@context": "https://schema.org",
        "@type": "Article",
        headline: post.title,
        description: post.description,
        image: `https://www.wanderwith.online${post.heroImage}`,
        datePublished: post.publishedDate,
        dateModified: post.publishedDate,
        author: {
            "@type": "Organization",
            name: post.author,
            url: "https://www.wanderwith.online",
        },
        publisher: {
            "@type": "Organization",
            name: "WanderWith",
            url: "https://www.wanderwith.online",
            logo: {
                "@type": "ImageObject",
                url: "https://www.wanderwith.online/logo.png",
            },
        },
        mainEntityOfPage: {
            "@type": "WebPage",
            "@id": `https://www.wanderwith.online/blog/${post.slug}`,
        },
        keywords: post.keywords.join(", "),
    };

    return (
        <>
            <main className="min-h-screen bg-white">
                {/* JSON-LD Structured Data */}
                <script
                    type="application/ld+json"
                    dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
                />

                <article className="pt-24 pb-16">
                    {/* Header Details */}
                    <div className="container mx-auto px-6 max-w-3xl pt-8 md:pt-16">
                        <Link
                            href="/blog"
                            className="inline-flex items-center gap-2 text-gray-500 hover:text-brand-accent text-sm mb-12 transition-colors font-medium"
                        >
                            <ArrowLeft className="w-4 h-4" />
                            Back to Blog
                        </Link>

                        <h1 className="text-4xl md:text-[3.5rem] font-bold text-gray-900 font-serif leading-[1.15] mb-8 tracking-tight">
                            {post.title}
                        </h1>

                        <div className="flex items-center gap-4 mb-12">
                            <div className="w-12 h-12 rounded-full bg-brand-primary flex flex-shrink-0 items-center justify-center text-white font-serif font-bold text-lg">
                                W
                            </div>
                            <div className="flex flex-col">
                                <span className="font-semibold text-gray-900 text-[15px]">{post.author}</span>
                                <div className="flex items-center gap-2 text-sm text-gray-500 mt-0.5">
                                    <span>{post.readTime}</span>
                                    <span>&middot;</span>
                                    <span>{new Date(post.publishedDate).toLocaleDateString("en-US", {
                                        year: "numeric",
                                        month: "long",
                                        day: "numeric",
                                    })}</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Minimalist Hero Image */}
                    <div className="container mx-auto px-6 max-w-5xl mb-16">
                        <div className="relative w-full h-[300px] md:h-[500px] lg:h-[600px] rounded-xl overflow-hidden bg-gray-50 border border-gray-100 shadow-sm">
                            <Image
                                src={post.heroImage}
                                alt={post.heroAlt}
                                fill
                                className="object-cover"
                                priority
                                sizes="100vw"
                            />
                        </div>
                    </div>

                    {/* Article Content - Typography Plugin */}
                    <div className="container mx-auto px-6 max-w-2xl">
                        <div
                            className="prose prose-lg md:prose-xl prose-slate max-w-none prose-headings:font-serif prose-headings:font-bold prose-headings:tracking-tight prose-a:text-brand-accent prose-a:font-semibold hover:prose-a:text-[#1e584f] prose-p:leading-relaxed prose-img:rounded-xl"
                            dangerouslySetInnerHTML={{ __html: post.content }}
                        />

                        {/* Tags */}
                        <div className="mt-16 pt-8 border-t border-gray-100 flex flex-wrap gap-2">
                            {post.keywords.slice(0, 5).map(keyword => (
                                <span key={keyword} className="bg-gray-100 text-gray-600 px-3 py-1 rounded-full text-sm font-medium">
                                    {keyword}
                                </span>
                            ))}
                        </div>
                    </div>
                </article>

                {/* Related Posts */}
                {relatedPosts.length > 0 && (
                    <section className="py-20 bg-gray-50 border-t border-gray-100">
                        <div className="container mx-auto px-6 max-w-5xl">
                            <h2 className="text-2xl font-bold text-gray-900 mb-10 font-serif">
                                More from WanderWith
                            </h2>
                            <div className="grid md:grid-cols-3 gap-8">
                                {relatedPosts.map((related) => (
                                    <Link
                                        key={related.slug}
                                        href={`/blog/${related.slug}`}
                                        className="group block"
                                    >
                                        <div className="relative h-48 rounded-lg overflow-hidden bg-gray-200 mb-4">
                                            <Image
                                                src={related.heroImage}
                                                alt={related.heroAlt}
                                                fill
                                                className="object-cover group-hover:scale-105 transition-transform duration-500"
                                                sizes="(max-width: 768px) 100vw, 33vw"
                                            />
                                        </div>
                                        <h3 className="font-bold text-gray-900 font-serif group-hover:text-brand-accent transition-colors leading-snug mb-2">
                                            {related.title}
                                        </h3>
                                        <p className="text-sm text-gray-500">
                                            {related.author} &middot; {related.readTime}
                                        </p>
                                    </Link>
                                ))}
                            </div>
                        </div>
                    </section>
                )}
            </main>
            <Footer />
        </>
    );
}
