import type { Metadata } from "next";
import { Inter, Playfair_Display } from "next/font/google";
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
  metadataBase: new URL('https://tejuice.fun'),
  title: "WanderWith | Travel better. Together.",
  description: "A calm space to plan trips with friends and discover curated journeys — without oversharing.",
  keywords: ["Travel", "Social Network", "Privacy", "Group Travel", "Agency", "Trip Planning"],
  authors: [{ name: "Tejas Bhurbhure" }],
  openGraph: {
    title: "WanderWith | Travel Social. But Private.",
    description: "Join the privacy-first travel revolution. Plan trips, connect safely, and explore the world.",
    url: "https://wanderwith.com",
    siteName: "WanderWith",
    images: [
      {
        url: "/og-image.jpg", // Needs to be added to public
        width: 1200,
        height: 630,
        alt: "WanderWith - Privacy First Travel",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "WanderWith | Travel Social. But Private.",
    description: "Privacy-first travel social network. Your trip. Your circle. Your rules.",
    images: ["/og-image.jpg"],
  },
  icons: {
    icon: "/logo.png",
    shortcut: "/logo.png",
    apple: "/logo.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${inter.variable} ${playfair.variable} antialiased bg-brand-bg text-brand-text`}
      >
        <Header />
        {children}
      </body>
    </html>
  );
}
