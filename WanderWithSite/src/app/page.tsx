import Header from "@/components/Header";
import Hero from "@/components/Hero";
import FeaturesGrid from "@/components/FeaturesGrid";
import FeatureShowcase from "@/components/FeatureShowcase";
import Places from "@/components/Places";
import HowItWorks from "@/components/HowItWorks";
import Reviews from "@/components/Reviews";
import About from "@/components/About";
import FinalCTA from "@/components/FinalCTA";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <main className="overflow-hidden">
      <Hero />
      <FeaturesGrid />
      <FeatureShowcase />
      <Places />
      <HowItWorks />
      <Reviews />
      <About />
      <FinalCTA />
      <Footer />
    </main>
  );
}
