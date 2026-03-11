import { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { blogPosts } from "@/lib/blogData";
import Footer from "@/components/Footer";
import { Twitter, Linkedin, ChevronRight } from "lucide-react";
import ReadingProgress from "@/components/ReadingProgress";
import TableOfContents from "@/components/TableOfContents";
import QuickAnswer from "@/components/QuickAnswer";
import FAQ from "@/components/FAQ";
import CTABlock from "@/components/CTABlock";

interface BlogPostPageProps {
    params: Promise<{ slug: string }>;
}

// Inject IDs into h2 tags so TOC can link to them
function injectHeadingIds(html: string): string {
    return html.replace(/<h2([^>]*)>(.*?)<\/h2>/gi, (match, attrs, inner) => {
        const text = inner.replace(/<[^>]*>/g, "").trim();
        const id = text
            .toLowerCase()
            .replace(/[^a-z0-9]+/g, "-")
            .replace(/^-|-$/g, "");
        return `<h2${attrs} id="${id}">${inner}</h2>`;
    });
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

    const contentWithIds = injectHeadingIds(post.content);

    // Related posts: prefer same category, then fill with others
    const sameCategoryPosts = blogPosts.filter((p) => p.slug !== post.slug && p.category === post.category);
    const otherPosts = blogPosts.filter((p) => p.slug !== post.slug && p.category !== post.category);
    const relatedPosts = [...sameCategoryPosts, ...otherPosts].slice(0, 3);

    // Schema.org structured data
    const jsonLdGraph: Record<string, unknown>[] = [
        {
            "@type": "Article",
            headline: post.title,
            description: post.description,
            image: `https://www.wanderwith.online${post.heroImage}`,
            datePublished: post.publishedDate,
            dateModified: post.modifiedDate,
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
        },
        {
            "@type": "BreadcrumbList",
            itemListElement: [
                { "@type": "ListItem", position: 1, name: "Home", item: "https://www.wanderwith.online" },
                { "@type": "ListItem", position: 2, name: "Blog", item: "https://www.wanderwith.online/blog" },
                { "@type": "ListItem", position: 3, name: post.title, item: `https://www.wanderwith.online/blog/${post.slug}` },
            ],
        },
    ];

    if (post.faq && post.faq.length > 0) {
        jsonLdGraph.push({
            "@type": "FAQPage",
            mainEntity: post.faq.map((item) => ({
                "@type": "Question",
                name: item.question,
                acceptedAnswer: {
                    "@type": "Answer",
                    text: item.answer,
                },
            })),
        });
    }

    const jsonLd = { "@context": "https://schema.org", "@graph": jsonLdGraph };

    return (
        <>
            <ReadingProgress />
            <main className="min-h-screen bg-white">
                <script
                    type="application/ld+json"
                    dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
                />

                <article className="pt-24 pb-16">
                    {/* Breadcrumb + Header */}
                    <div className="container mx-auto px-6 max-w-[720px] xl:max-w-5xl pt-8 md:pt-16">
                        {/* Breadcrumb Navigation */}
                        <nav className="flex items-center gap-1.5 text-sm text-gray-500 mb-10" aria-label="Breadcrumb">
                            <Link href="/" className="hover:text-brand-accent transition-colors">Home</Link>
                            <ChevronRight className="w-3.5 h-3.5" />
                            <Link href="/blog" className="hover:text-brand-accent transition-colors">Blog</Link>
                            <ChevronRight className="w-3.5 h-3.5" />
                            <span className="text-gray-400 truncate max-w-[200px] md:max-w-none">{post.category}</span>
                        </nav>

                        <h1 className="text-4xl md:text-5xl font-bold text-gray-900 font-serif leading-[1.15] mb-8 tracking-tight max-w-[720px]">
                            {post.title}
                        </h1>

                        <div className="flex items-center gap-4 mb-10 max-w-[720px]">
                            <div className="w-11 h-11 rounded-full bg-brand-primary flex flex-shrink-0 items-center justify-center text-white font-serif font-bold text-base">
                                W
                            </div>
                            <div className="flex flex-col">
                                <span className="font-semibold text-gray-900 text-[15px]">{post.author}</span>
                                <div className="flex items-center gap-2 text-sm text-gray-500 mt-0.5">
                                    <span>{new Date(post.publishedDate).toLocaleDateString("en-US", {
                                        year: "numeric",
                                        month: "long",
                                        day: "numeric",
                                    })}</span>
                                    <span>&middot;</span>
                                    <span>{post.readTime}</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Hero Image */}
                    <div className="container mx-auto px-6 max-w-5xl mb-12">
                        <div className="relative w-full h-[300px] md:h-[500px] lg:h-[560px] rounded-xl overflow-hidden bg-gray-50 border border-gray-100">
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

                    {/* Content + TOC Layout */}
                    <div className="container mx-auto px-6 max-w-5xl">
                        <div className="flex gap-16">
                            {/* Main Content Column */}
                            <div className="min-w-0 max-w-[720px]">
                                {/* Quick Answer */}
                                {post.quickAnswer && (
                                    <QuickAnswer answer={post.quickAnswer} />
                                )}

                                {/* Article Body */}
                                <div
                                    className="prose prose-lg prose-slate max-w-none prose-headings:font-serif prose-headings:font-bold prose-headings:tracking-tight prose-h2:text-[1.65rem] prose-h2:mt-12 prose-h2:mb-4 prose-h3:text-xl prose-a:text-brand-accent prose-a:font-semibold hover:prose-a:text-[#1e584f] prose-p:leading-[1.75] prose-p:text-[17px] prose-li:text-[17px] prose-li:leading-[1.75] prose-img:rounded-xl"
                                    dangerouslySetInnerHTML={{ __html: contentWithIds }}
                                />

                                {/* FAQ Section */}
                                {post.faq && post.faq.length > 0 && (
                                    <FAQ items={post.faq} />
                                )}

                                {/* Tags */}
                                <div className="mt-16 pt-8 border-t border-gray-100 flex flex-wrap gap-2">
                                    {post.keywords.slice(0, 6).map(keyword => (
                                        <span key={keyword} className="bg-gray-100 text-gray-600 px-3 py-1 rounded-full text-sm font-medium">
                                            {keyword}
                                        </span>
                                    ))}
                                </div>

                                {/* Share Buttons */}
                                <div className="mt-10 pt-8 border-t border-gray-100">
                                    <p className="text-sm font-semibold text-gray-500 uppercase tracking-widest mb-4">Share this article</p>
                                    <div className="flex gap-3">
                                        <a
                                            href={`https://twitter.com/intent/tweet?text=${encodeURIComponent(post.title)}&url=${encodeURIComponent(`https://www.wanderwith.online/blog/${post.slug}`)}`}
                                            target="_blank"
                                            rel="noopener noreferrer"
                                            className="inline-flex items-center gap-2 px-4 py-2 bg-gray-100 hover:bg-gray-200 rounded-full text-sm font-medium text-gray-700 transition-colors"
                                        >
                                            <Twitter className="w-4 h-4" /> Twitter
                                        </a>
                                        <a
                                            href={`https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(`https://www.wanderwith.online/blog/${post.slug}`)}`}
                                            target="_blank"
                                            rel="noopener noreferrer"
                                            className="inline-flex items-center gap-2 px-4 py-2 bg-gray-100 hover:bg-gray-200 rounded-full text-sm font-medium text-gray-700 transition-colors"
                                        >
                                            <Linkedin className="w-4 h-4" /> LinkedIn
                                        </a>
                                    </div>
                                </div>

                                {/* CTA Block */}
                                <CTABlock />
                            </div>

                            {/* TOC Sidebar */}
                            <TableOfContents content={post.content} />
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
                                        <span className="text-xs font-medium text-brand-accent mb-1.5 block">{related.category}</span>
                                        <h3 className="font-bold text-gray-900 font-serif group-hover:text-brand-accent transition-colors leading-snug mb-2">
                                            {related.title}
                                        </h3>
                                        <p className="text-sm text-gray-500">
                                            {related.readTime}
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
