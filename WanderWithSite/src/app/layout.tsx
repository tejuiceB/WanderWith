import type { Metadata } from "next";
import { Inter, Playfair_Display } from "next/font/google";
import Script from "next/script";
import "./globals.css";
import Header from "@/components/Header";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

const playfair = Playfair_Display({
  variable: "--font-playfair",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  metadataBase: new URL('https://www.wanderwith.online'),
  title: "WanderWith | Free Trip Planner & Group Travel App | Plan Trips Together",
  description: "WanderWith is a free AI-powered trip planner and group travel app. Create itineraries, plan trips with friends, track budgets, join agency trips, and discover curated experiences. All in one privacy-first platform.",
  keywords: [
    "free trip planner",
    "group trip planner",
    "travel planner app",
    "free itinerary planner",
    "plan trip with friends",
    "travel social network",
    "AI trip planner",
    "travel agency platform",
    "group travel app India",
    "trip planner website",
    "free travel planner",
    "itinerary maker free",
    "social media for travellers",
    "friends trip planner",
    "plan trip online free",
    "WanderWith",
  ],
  authors: [{ name: "WanderWith Team" }],
  openGraph: {
    title: "WanderWith | Free Trip Planner & Group Travel App",
    description: "Plan trips with friends using AI. Free itinerary planner, group travel collaboration, budget tracking & agency trip packages.",
    url: "https://www.wanderwith.online",
    siteName: "WanderWith",
    images: [
      {
        url: "/og-image.jpg",
        width: 1200,
        height: 630,
        alt: "WanderWith — Free AI Trip Planner & Group Travel App",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "WanderWith | Free Trip Planner & Group Travel App",
    description: "Free AI trip planner for group travel. Plan itineraries, split expenses, and join curated trips.",
    images: ["/og-image.jpg"],
  },
  icons: {
    icon: "/logo.png",
    shortcut: "/logo.png",
    apple: "/logo.png",
  },
  alternates: {
    canonical: "https://www.wanderwith.online",
  },
  verification: {
    other: {
      "ahrefs-site-verification": "2b5248886c923eab76fb2e40cd70ca6ec7aef778b3a1acb95f712337b1a91863",
    },
  },
};

// Schema.org structured data for SEO
const jsonLd = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": "https://www.wanderwith.online/#organization",
      name: "WanderWith",
      url: "https://www.wanderwith.online",
      logo: {
        "@type": "ImageObject",
        url: "https://www.wanderwith.online/logo.png",
      },
      description: "WanderWith is a free AI-powered trip planner and social travel app. Plan trips with friends, create itineraries, track budgets, and join agency trips — all in one privacy-first platform.",
      foundingDate: "2025",
      contactPoint: {
        "@type": "ContactPoint",
        email: "wanderwithplan@gmail.com",
        contactType: "customer support",
      },
      sameAs: [
        "https://play.google.com/store/apps/details?id=com.tejuice.wanderwith",
        "https://www.wanderwith.online/blog",
      ],
    },
    {
      "@type": "WebSite",
      "@id": "https://www.wanderwith.online/#website",
      url: "https://www.wanderwith.online",
      name: "WanderWith",
      publisher: {
        "@id": "https://www.wanderwith.online/#organization",
      },
      description: "Free AI trip planner and group travel app. Plan trips with friends, create itineraries, and join curated travel experiences.",
    },
    {
      "@type": "MobileApplication",
      "@id": "https://www.wanderwith.online/#app",
      name: "WanderWith - Trip Planner App",
      alternateName: "WanderWith — Free AI Trip Planner & Group Travel App",
      operatingSystem: "Android, iOS",
      applicationCategory: "TravelApplication",
      offers: {
        "@type": "Offer",
        price: "0",
        priceCurrency: "USD",
      },
      url: "https://www.wanderwith.online",
      downloadUrl: "https://play.google.com/store/apps/details?id=com.tejuice.wanderwith",
      description: "WanderWith is a free social travel planning app that helps travelers create trips, share itineraries, track expenses, and collaborate with friends in real-time. Features AI-powered itinerary generation, group trip planning, built-in chat, budget tracking, polls, shared photo galleries, and a travel agency dashboard.",
      screenshot: "https://www.wanderwith.online/og-image.jpg",
      featureList: [
        "AI-powered trip itinerary generation",
        "Group trip planning and collaboration",
        "Built-in trip chat with mentions and reactions",
        "Budget tracking and expense splitting",
        "Polls and group voting",
        "Shared trip photo gallery",
        "Smart booking link organization",
        "Travel agency dashboard",
        "Privacy-first design with no ads",
        "Offline access to trip data",
      ],
      aggregateRating: {
        "@type": "AggregateRating",
        ratingValue: "4.8",
        ratingCount: "500",
        bestRating: "5",
        worstRating: "1",
      },
    },
    {
      "@type": "FAQPage",
      mainEntity: [
        {
          "@type": "Question",
          name: "What is WanderWith?",
          acceptedAnswer: {
            "@type": "Answer",
            text: "WanderWith is a free social travel planning app that helps travelers create trips, share itineraries, track expenses, and collaborate with friends in real-time. It combines AI-powered planning, real-time group collaboration, and a privacy-first philosophy.",
          },
        },
        {
          "@type": "Question",
          name: "Is WanderWith free to use?",
          acceptedAnswer: {
            "@type": "Answer",
            text: "Yes, WanderWith is completely free to download and use. There are no ads, no premium tiers, and no hidden charges for trip planning, group collaboration, or AI itinerary generation.",
          },
        },
        {
          "@type": "Question",
          name: "Can I plan group trips with friends on WanderWith?",
          acceptedAnswer: {
            "@type": "Answer",
            text: "Absolutely. WanderWith lets you create group trips, invite friends, chat in real-time, vote on plans with polls, split budgets, and share booking links — all in one app.",
          },
        },
        {
          "@type": "Question",
          name: "Does WanderWith have an AI trip planner?",
          acceptedAnswer: {
            "@type": "Answer",
            text: "Yes, WanderWith features an AI-powered itinerary builder that creates complete day-by-day travel plans based on your destination, budget, and preferences.",
          },
        },
        {
          "@type": "Question",
          name: "How is WanderWith different from Polarsteps or TripIt?",
          acceptedAnswer: {
            "@type": "Answer",
            text: "Unlike Polarsteps (focused on trip tracking) or TripIt (focused on business travel), WanderWith is built ground-up for collaborative group travel planning with real-time chat, polls, expense splitting, AI itineraries, and a privacy-first design. It's completely free with no ads.",
          },
        },
        {
          "@type": "Question",
          name: "Can travel agencies use WanderWith?",
          acceptedAnswer: {
            "@type": "Answer",
            text: "Yes, WanderWith includes a dedicated agency dashboard where travel agencies can create trip packages, manage clients, and publish public trips for travelers to discover and join.",
          },
        },
        {
          "@type": "Question",
          name: "Does WanderWith work offline?",
          acceptedAnswer: {
            "@type": "Answer",
            text: "Yes, WanderWith caches your trips locally so you can access itineraries, budgets, and trip details without an internet connection.",
          },
        },
        {
          "@type": "Question",
          name: "What platforms is WanderWith available on?",
          acceptedAnswer: {
            "@type": "Answer",
            text: "WanderWith is available on Android via Google Play Store and on iOS via the App Store. A web version is also accessible at wanderwith.online.",
          },
        },
        {
          "@type": "Question",
          name: "Is my data safe on WanderWith?",
          acceptedAnswer: {
            "@type": "Answer",
            text: "Yes. WanderWith is privacy-first by design. There are no ads, no user tracking, and no data selling. Your trips are private by default and you have full control over who can see them.",
          },
        },
        {
          "@type": "Question",
          name: "How does AI trip planning work in WanderWith?",
          acceptedAnswer: {
            "@type": "Answer",
            text: "WanderWith's AI analyzes your destination, travel dates, budget, and preferences to generate a complete day-by-day itinerary with recommended places, activities, and timings. You can then customize every detail.",
          },
        },
      ],
    },
  ],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        <Script
          src="https://analytics.ahrefs.com/analytics.js"
          data-key="5dnH8bax5j11nlu7Zsk4Mw"
          strategy="afterInteractive"
        />
      </head>
      <body
        className={`${inter.variable} ${playfair.variable} antialiased bg-brand-bg text-brand-text`}
      >
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
        <Header />
        {children}
      </body>
    </html>
  );
}
