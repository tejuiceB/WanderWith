import Header from "@/components/Header";
import Hero from "@/components/Hero";
import Story from "@/components/Story";
import PrivateSpace from "@/components/PrivateSpace";
import Experience from "@/components/Experience";
import AIPlanningShowcase from "@/components/AIPlanningShowcase";
import AppFeatures from "@/components/AppFeatures";
import PrivacyPromise from "@/components/PrivacyPromise";
import HowItWorks from "@/components/HowItWorks";

import RealTrips from "@/components/RealTrips";
import FinalCTA from "@/components/FinalCTA";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <main className="overflow-hidden">
      <Hero />
      <Story />
      <PrivateSpace />
      <Experience />
      <AIPlanningShowcase />
      <AppFeatures />
      <PrivacyPromise />
      <HowItWorks />

      <RealTrips />
      <FinalCTA />
      <Footer />
    </main>
  );
}
