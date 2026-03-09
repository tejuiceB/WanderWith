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
  title: "WanderWith — Free Trip Planner & Group Travel App | Plan Trips Together",
  description: "WanderWith is a free AI-powered trip planner and group travel app. Create itineraries, plan trips with friends, track budgets, join agency trips, and discover curated experiences — all in one privacy-first platform.",
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
  authors: [{ name: "Tejas Bhurbhure" }],
  openGraph: {
    title: "WanderWith — Free Trip Planner & Group Travel App",
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
    title: "WanderWith — Free Trip Planner & Group Travel App",
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
      description: "WanderWith is a free AI-powered trip planner and group travel app. Plan trips with friends, create itineraries, track budgets, and join agency trips.",
      contactPoint: {
        "@type": "ContactPoint",
        email: "wanderwithplan@gmail.com",
        contactType: "customer support",
      },
    },
    {
      "@type": "WebSite",
      "@id": "https://www.wanderwith.online/#website",
      url: "https://www.wanderwith.online",
      name: "WanderWith",
      publisher: {
        "@id": "https://www.wanderwith.online/#organization",
      },
      description: "Free AI trip planner and group travel app — plan trips with friends, create itineraries, and join curated travel experiences.",
    },
    {
      "@type": "SoftwareApplication",
      name: "WanderWith - Trip Planner App",
      operatingSystem: "Android",
      applicationCategory: "TravelApplication",
      offers: {
        "@type": "Offer",
        price: "0",
        priceCurrency: "INR",
      },
      url: "https://play.google.com/store/apps/details?id=com.tejuice.wanderwith",
      description: "Free AI-powered trip planner app for group travel. Create itineraries, plan trips with friends, track budgets, and discover curated experiences.",
      downloadUrl: "https://play.google.com/store/apps/details?id=com.tejuice.wanderwith",
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
