import { Metadata } from "next";
import { blogPosts } from "@/lib/blogData";
import Footer from "@/components/Footer";
import BlogListingClient from "./BlogListingClient";

export const metadata: Metadata = {
    title: "Blog | WanderWith — Travel Tips, Guides & AI Trip Planning",
    description: "Explore travel guides, trip planning tips, AI-powered travel tools, and destination insights. Plan smarter, travel better with WanderWith blog.",
    keywords: ["travel blog", "trip planning tips", "AI travel planner", "travel guide India", "WanderWith blog", "travel itinerary tips", "trip planner website", "best travel apps"],
    openGraph: {
        title: "WanderWith Blog — Travel Tips, Guides & AI Trip Planning",
        description: "Explore travel guides, trip planning tips, AI-powered travel tools, and destination insights.",
        url: "https://www.wanderwith.online/blog",
        siteName: "WanderWith",
        type: "website",
    },
    twitter: {
        card: "summary_large_image",
        title: "WanderWith Blog — Travel Tips & Guides",
        description: "Explore travel guides, trip planning tips, and AI-powered travel tools.",
    },
    alternates: {
        canonical: "https://www.wanderwith.online/blog",
    },
};

export default function BlogPage() {
    const jsonLd = {
        "@context": "https://schema.org",
        "@graph": [
            {
                "@type": "CollectionPage",
                name: "WanderWith Blog",
                description: "Travel guides, trip planning tips, AI-powered travel tools, and destination insights.",
                url: "https://www.wanderwith.online/blog",
                mainEntity: {
                    "@type": "ItemList",
                    itemListElement: blogPosts.map((post, i) => ({
                        "@type": "ListItem",
                        position: i + 1,
                        url: `https://www.wanderwith.online/blog/${post.slug}`,
                        name: post.title,
                    })),
                },
            },
            {
                "@type": "BreadcrumbList",
                itemListElement: [
                    { "@type": "ListItem", position: 1, name: "Home", item: "https://www.wanderwith.online" },
                    { "@type": "ListItem", position: 2, name: "Blog", item: "https://www.wanderwith.online/blog" },
                ],
            },
        ],
    };

    return (
        <>
            <main className="min-h-screen bg-white">
                <script
                    type="application/ld+json"
                    dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
                />
                <BlogListingClient posts={blogPosts} />
            </main>
            <Footer />
        </>
    );
}
