import Footer from "@/components/Footer";
import BrandHeader from "@/components/BrandHeader";
import Link from "next/link";
import type { Metadata } from "next";

export const metadata: Metadata = {
    title: "Terms & Conditions | WanderWith — Service Agreement",
    description: "Read the Terms and Conditions governing your use of the WanderWith travel planning platform. Covers account usage, content rights, AI features, liability, and more.",
    keywords: [
        "WanderWith terms",
        "WanderWith terms and conditions",
        "travel app terms of service",
        "WanderWith service agreement",
    ],
    alternates: { canonical: "https://www.wanderwith.online/terms" },
};

const toc = [
    { id: "acceptance", label: "Acceptance of Terms" },
    { id: "eligibility", label: "Eligibility & Accounts" },
    { id: "service", label: "The Service" },
    { id: "ugc", label: "User-Generated Content" },
    { id: "ip", label: "Intellectual Property" },
    { id: "ai", label: "AI Travel Suggestions" },
    { id: "third-party", label: "Third-Party Links" },
    { id: "acceptable-use", label: "Acceptable Use" },
    { id: "termination", label: "Account Termination" },
    { id: "warranties", label: "Disclaimer of Warranties" },
    { id: "liability", label: "Limitation of Liability" },
    { id: "indemnification", label: "Indemnification" },
    { id: "disputes", label: "Dispute Resolution" },
    { id: "governing-law", label: "Governing Law" },
    { id: "force-majeure", label: "Force Majeure" },
    { id: "modifications", label: "Modifications to Service" },
    { id: "severability", label: "Severability" },
    { id: "entire-agreement", label: "Entire Agreement" },
    { id: "contact", label: "Contact Us" },
];

export default function TermsAndConditions() {
    return (
        <main className="min-h-screen bg-white text-gray-800">
            <BrandHeader />
            <div className="container mx-auto px-6 py-24 max-w-4xl">
                {/* Header */}
                <div className="mb-8 border-b border-gray-100 pb-8">
                    <nav aria-label="Breadcrumb" className="mb-6 text-sm text-gray-500">
                        <Link href="/" className="hover:text-brand-accent transition-colors">Home</Link>
                        <span className="mx-2">/</span>
                        <span className="text-gray-900">Terms &amp; Conditions</span>
                    </nav>
                    <h1 className="text-4xl md:text-5xl font-serif font-bold mb-4 text-brand-primary tracking-tight">Terms &amp; Conditions</h1>
                    <p className="text-gray-500">Effective Date: March 2, 2025 &middot; Last Updated: March 2, 2025</p>
                </div>

                {/* Table of Contents */}
                <nav className="mb-12 p-6 bg-gray-50 rounded-2xl border border-gray-200">
                    <h2 className="text-sm font-bold text-gray-900 uppercase tracking-wide mb-4">Table of Contents</h2>
                    <ol className="grid sm:grid-cols-2 gap-x-8 gap-y-2 text-sm">
                        {toc.map((item, i) => (
                            <li key={item.id}>
                                <a href={`#${item.id}`} className="text-gray-600 hover:text-brand-accent transition-colors">
                                    {i + 1}. {item.label}
                                </a>
                            </li>
                        ))}
                    </ol>
                </nav>

                <div className="space-y-12">
                    {/* 1 — Acceptance */}
                    <section id="acceptance">
                        <h2 className="text-2xl font-bold text-brand-primary mb-4 font-serif">1. Acceptance of Terms</h2>
                        <p className="leading-relaxed text-gray-600">
                            By downloading, installing, accessing, or using the WanderWith mobile application (&quot;App&quot;) and website at{" "}
                            <a href="https://www.wanderwith.online" className="text-brand-accent hover:underline">www.wanderwith.online</a> (&quot;Site&quot;), you agree to be bound by these Terms &amp; Conditions (&quot;Terms&quot;). If you do not agree, do not use the platform. WanderWith reserves the right to modify these Terms at any time. Material changes will be communicated via the App or email. Continued use after changes constitutes acceptance. For questions, email{" "}
                            <a href="mailto:wanderwithplan@gmail.com" className="text-brand-accent hover:underline">wanderwithplan@gmail.com</a>.
                        </p>
                    </section>

                    <section id="eligibility">
                        <h2 className="text-2xl font-bold text-brand-primary mb-4 font-serif">2. Eligibility &amp; Accounts</h2>
                        <p className="leading-relaxed text-gray-600">
                            You must be at least 13 years of age (or the minimum age of digital consent in your jurisdiction) to use WanderWith. By creating an account, you represent that all registration information is accurate and truthful. You are solely responsible for maintaining the confidentiality of your credentials and for all activity under your account. Notify us immediately at{" "}
                            <a href="mailto:wanderwithplan@gmail.com" className="text-brand-accent hover:underline">wanderwithplan@gmail.com</a>{" "}
                            if you suspect unauthorised access.
                        </p>
                    </section>

                    <section id="service">
                        <h2 className="text-2xl font-bold text-brand-primary mb-4 font-serif">3. Description of the Service</h2>
                        <p className="leading-relaxed text-gray-600">
                            WanderWith is a collaborative travel-planning platform that allows users to create trips, build itineraries, invite collaborators, track expenses, share photos, chat within groups, and discover community-published travel memories. We also provide AI-powered itinerary suggestions via Google Gemini AI. The service is currently offered free of charge; we reserve the right to introduce paid features or subscriptions in the future with prior notice.
                        </p>
                    </section>

                    <section id="ugc">
                        <h2 className="text-2xl font-bold text-brand-primary mb-4 font-serif">4. User-Generated Content</h2>
                        <div className="space-y-4 text-gray-600">
                            <p>WanderWith allows you to upload photos, create travel plans, share memories, and communicate with other users. <strong>You retain all ownership rights to your content.</strong></p>
                            <p><strong>License Grant:</strong> By sharing content publicly or within group trips, you grant WanderWith a non-exclusive, royalty-free, worldwide, sublicensable license to host, display, cache, and distribute said content solely for the purpose of providing, improving, and promoting the service. This license terminates when you delete the content or your account, except where content has been shared with or copied by other users.</p>
                            <p><strong>Prohibited Content:</strong> You may not upload content that is:</p>
                            <ul className="list-disc pl-6 space-y-1">
                                <li>Illegal, defamatory, obscene, pornographic, or sexually explicit</li>
                                <li>Harassing, threatening, or promoting violence or discrimination</li>
                                <li>Infringing on any third-party intellectual property, privacy, or publicity rights</li>
                                <li>Spam, malware, or deceptive in nature</li>
                                <li>Impersonating another person or entity</li>
                            </ul>
                            <p>WanderWith reserves the right to remove any content and suspend or terminate accounts that violate these guidelines, at our sole discretion and without prior notice.</p>
                        </div>
                    </section>

                    <section id="ip">
                        <h2 className="text-2xl font-bold text-brand-primary mb-4 font-serif">5. Intellectual Property</h2>
                        <p className="leading-relaxed text-gray-600">
                            All elements of the WanderWith platform—including the logo, UI/UX design, source code, graphics, and branded text—are the property of WanderWith and are protected by copyright, trademark, and other intellectual property laws. You may not reproduce, distribute, modify, create derivative works of, or reverse engineer any part of the service without our explicit written consent.
                        </p>
                    </section>

                    <section id="ai">
                        <h2 className="text-2xl font-bold text-brand-primary mb-4 font-serif">6. AI Travel Suggestions</h2>
                        <p className="leading-relaxed text-gray-600">
                            WanderWith uses Google Gemini AI to generate travel recommendations and itineraries. These suggestions are <strong>for informational purposes only</strong> and should not be relied upon as professional travel advice. We do not guarantee the accuracy, safety, legality, availability, or suitability of any suggested activities, locations, or routes. Always verify critical details (visa requirements, safety advisories, operating hours, pricing) independently before travelling. WanderWith shall not be liable for any loss, injury, or inconvenience arising from reliance on AI-generated suggestions.
                        </p>
                    </section>

                    <section id="third-party">
                        <h2 className="text-2xl font-bold text-brand-primary mb-4 font-serif">7. Third-Party Links &amp; Services</h2>
                        <p className="leading-relaxed text-gray-600">
                            The platform may contain links to third-party websites, booking services, maps, or guides. WanderWith does not own, control, endorse, or assume responsibility for the content, privacy practices, or terms of any third-party services. Your interaction with third-party services is governed by their own terms and is entirely at your own risk.
                        </p>
                    </section>

                    <section id="acceptable-use">
                        <h2 className="text-2xl font-bold text-brand-primary mb-4 font-serif">8. Acceptable Use</h2>
                        <p className="leading-relaxed text-gray-600 mb-3">You agree not to:</p>
                        <ul className="list-disc pl-6 space-y-2 text-gray-600">
                            <li>Use the service for any unlawful or fraudulent purpose.</li>
                            <li>Attempt to gain unauthorised access to any part of the platform, other users&apos; accounts, or our servers.</li>
                            <li>Interfere with or disrupt the service, servers, or networks connected to the service.</li>
                            <li>Use automated scripts, bots, or scrapers to access or collect data from the platform.</li>
                            <li>Upload viruses, malware, or any other harmful code.</li>
                            <li>Circumvent, disable, or otherwise interfere with security-related features.</li>
                            <li>Use WanderWith to send unsolicited messages or spam to other users.</li>
                        </ul>
                    </section>

                    <section id="termination">
                        <h2 className="text-2xl font-bold text-brand-primary mb-4 font-serif">9. Account Termination</h2>
                        <div className="space-y-3 text-gray-600">
                            <p><strong>By You:</strong> You may delete your account at any time through the App settings. Upon deletion, your personal data is permanently removed in accordance with our <a href="/privacy" className="text-brand-accent hover:underline">Privacy Policy</a>.</p>
                            <p><strong>By Us:</strong> We may suspend or terminate your account immediately, without prior notice, if you breach these Terms, engage in fraudulent or abusive conduct, or if continued operation of your account poses a risk to other users or the platform. We may also terminate inactive accounts after an extended period of inactivity with prior notice.</p>
                            <p>Upon termination, your right to use the service ceases immediately. Provisions that by their nature should survive (IP, limitation of liability, indemnification, governing law) shall continue in effect.</p>
                        </div>
                    </section>

                    <section id="warranties">
                        <h2 className="text-2xl font-bold text-brand-primary mb-4 font-serif">10. Disclaimer of Warranties</h2>
                        <div className="bg-gray-50 border border-gray-200 rounded-xl p-5">
                            <p className="leading-relaxed text-gray-600 italic">
                                THE SERVICE IS PROVIDED &quot;AS IS&quot; AND &quot;AS AVAILABLE&quot; WITHOUT ANY WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. WANDERWITH DOES NOT WARRANT THAT THE SERVICE WILL BE UNINTERRUPTED, TIMELY, SECURE, OR ERROR-FREE, OR THAT ANY DEFECTS WILL BE CORRECTED.
                            </p>
                        </div>
                    </section>

                    <section id="liability">
                        <h2 className="text-2xl font-bold text-brand-primary mb-4 font-serif">11. Limitation of Liability</h2>
                        <p className="leading-relaxed text-gray-600">
                            To the maximum extent permitted by applicable law, WanderWith, its operators, employees, affiliates, and partners shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including but not limited to loss of profits, data, goodwill, or other intangible losses, arising out of or related to your use of or inability to use the service—regardless of whether we were advised of the possibility of such damages. Our total aggregate liability for any claims shall not exceed the amount you have paid us (if any) in the 12 months preceding the claim.
                        </p>
                    </section>

                    <section id="indemnification">
                        <h2 className="text-2xl font-bold text-brand-primary mb-4 font-serif">12. Indemnification</h2>
                        <p className="leading-relaxed text-gray-600">
                            You agree to indemnify, defend, and hold harmless WanderWith and its operators, employees, and affiliates from and against any and all claims, liabilities, damages, losses, costs, and expenses (including reasonable legal fees) arising out of or related to: (a) your use of the service; (b) your violation of these Terms; (c) your violation of any third-party rights; or (d) any content you upload or share through the platform.
                        </p>
                    </section>

                    <section id="disputes">
                        <h2 className="text-2xl font-bold text-brand-primary mb-4 font-serif">13. Dispute Resolution</h2>
                        <p className="leading-relaxed text-gray-600">
                            If a dispute arises from these Terms or your use of WanderWith, we encourage you to first contact us at{" "}
                            <a href="mailto:wanderwithplan@gmail.com" className="text-brand-accent hover:underline">wanderwithplan@gmail.com</a>{" "}
                            to attempt informal resolution. If the dispute cannot be resolved within 30 days, either party may pursue formal proceedings under the jurisdiction specified in Section 14.
                        </p>
                    </section>

                    <section id="governing-law">
                        <h2 className="text-2xl font-bold text-brand-primary mb-4 font-serif">14. Governing Law &amp; Jurisdiction</h2>
                        <p className="leading-relaxed text-gray-600">
                            These Terms shall be governed by and construed in accordance with the laws of India, without regard to conflict of law principles. Any disputes arising from or relating to these Terms or the service shall be subject to the exclusive jurisdiction of the courts located in India.
                        </p>
                    </section>

                    <section id="force-majeure">
                        <h2 className="text-2xl font-bold text-brand-primary mb-4 font-serif">15. Force Majeure</h2>
                        <p className="leading-relaxed text-gray-600">
                            WanderWith shall not be liable for any failure or delay in performing obligations under these Terms due to circumstances beyond our reasonable control, including but not limited to natural disasters, pandemics, government actions, internet outages, infrastructure failures, or acts of third parties.
                        </p>
                    </section>

                    <section id="modifications">
                        <h2 className="text-2xl font-bold text-brand-primary mb-4 font-serif">16. Modifications to the Service</h2>
                        <p className="leading-relaxed text-gray-600">
                            We reserve the right to modify, suspend, or discontinue any part of the service at any time, with or without notice. We shall not be liable to you or any third party for any modification, suspension, or discontinuation of the service.
                        </p>
                    </section>

                    <section id="severability">
                        <h2 className="text-2xl font-bold text-brand-primary mb-4 font-serif">17. Severability</h2>
                        <p className="leading-relaxed text-gray-600">
                            If any provision of these Terms is found to be invalid or unenforceable by a court of competent jurisdiction, the remaining provisions shall continue in full force and effect. The invalid provision shall be modified to the minimum extent necessary to make it valid and enforceable.
                        </p>
                    </section>

                    <section id="entire-agreement">
                        <h2 className="text-2xl font-bold text-brand-primary mb-4 font-serif">18. Entire Agreement</h2>
                        <p className="leading-relaxed text-gray-600">
                            These Terms, together with our <a href="/privacy" className="text-brand-accent hover:underline">Privacy Policy</a>, constitute the entire agreement between you and WanderWith regarding your use of the service, and supersede all prior or contemporaneous agreements, understandings, or representations.
                        </p>
                    </section>

                    <section id="contact">
                        <h2 className="text-2xl font-bold text-brand-primary mb-4 font-serif">19. Contact Us</h2>
                        <p className="leading-relaxed text-gray-600">
                            If you have questions or concerns about these Terms, please contact us:
                        </p>
                        <div className="mt-3 p-4 bg-gray-50 rounded-xl text-gray-600">
                            <p><strong>WanderWith</strong></p>
                            <p>Email:{" "}
                                <a href="mailto:wanderwithplan@gmail.com" className="text-brand-accent font-medium hover:underline">wanderwithplan@gmail.com</a>
                            </p>
                            <p>Website:{" "}
                                <a href="https://www.wanderwith.online" className="text-brand-accent hover:underline">www.wanderwith.online</a>
                            </p>
                        </div>
                    </section>
                </div>
            </div>
            <Footer />
        </main>
    );
}
