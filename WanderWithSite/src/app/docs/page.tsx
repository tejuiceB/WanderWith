import { Metadata } from "next";
import Footer from "@/components/Footer";
import DocsClient from "./DocsClient";
import { docSections } from "@/lib/docsData";

export const metadata: Metadata = {
    title: "WanderWith Documentation — Getting Started, Guides & Help",
    description:
        "Complete documentation for WanderWith: getting started, AI itinerary generation, group trip planning, budget tracking, expense splitting, trip chat, photo gallery, agency dashboard, privacy, and troubleshooting.",
    keywords: [
        "WanderWith documentation",
        "WanderWith how to use",
        "WanderWith getting started",
        "WanderWith tutorial",
        "WanderWith help",
        "trip planning app guide",
        "AI itinerary help",
        "group trip planning guide",
    ],
    alternates: { canonical: "https://www.wanderwith.online/docs" },
    openGraph: {
        title: "WanderWith Documentation — Getting Started & Help",
        description:
            "Everything you need to know about using WanderWith. Step-by-step guides for AI itinerary generation, group planning, budget tracking, and more.",
        url: "https://www.wanderwith.online/docs",
        siteName: "WanderWith",
        type: "website",
    },
};

const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
        {
            "@type": "TechArticle",
            name: "WanderWith Documentation",
            description:
                "Complete documentation for WanderWith travel planning app. Guides for AI itineraries, group planning, budget tracking, and more.",
            url: "https://www.wanderwith.online/docs",
            publisher: {
                "@type": "Organization",
                name: "WanderWith",
                url: "https://www.wanderwith.online",
            },
        },
        {
            "@type": "FAQPage",
            mainEntity: docSections.flatMap((s) =>
                s.items.map((item) => ({
                    "@type": "Question",
                    name: `How to use ${item.title} in WanderWith?`,
                    acceptedAnswer: {
                        "@type": "Answer",
                        text: item.content.replace(/<[^>]*>/g, "").trim().slice(0, 300),
                    },
                }))
            ),
        },
        {
            "@type": "BreadcrumbList",
            itemListElement: [
                { "@type": "ListItem", position: 1, name: "Home", item: "https://www.wanderwith.online" },
                { "@type": "ListItem", position: 2, name: "Documentation" },
            ],
        },
    ],
};

export default function DocsPage() {
    return (
        <>
            <script
                type="application/ld+json"
                dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
            />
            <DocsClient />
            <Footer />
        </>
    );
}
