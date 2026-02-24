import Footer from "@/components/Footer";
import BrandHeader from "@/components/BrandHeader";

export default function TermsAndConditions() {
    return (
        <main className="min-h-screen bg-white text-gray-800">
            <BrandHeader />
            <div className="container mx-auto px-6 py-24 max-w-4xl">
                <div className="mb-12 border-b border-gray-100 pb-8">
                    <h1 className="text-4xl md:text-5xl font-serif font-bold mb-4 text-brand-primary">Terms & Conditions</h1>
                    <p className="text-gray-500">Last Updated: February 23, 2026</p>
                </div>

                <div className="space-y-12">
                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">1. Acceptance of Terms</h2>
                        <p className="leading-relaxed text-gray-600">
                            By downloading, installing, or using the WanderWith mobile application and website, you signify your agreement to these Terms and Conditions. WanderWith reserves the right to amend these terms at any time. Your continued use of the platform after changes are posted constitutes your acceptance of the new terms. For inquiries, email <a href="mailto:wanderwithplan@gmail.com" className="text-brand-accent hover:underline">wanderwithplan@gmail.com</a>.
                        </p>
                    </section>

                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">2. Eligibility & Accounts</h2>
                        <p className="leading-relaxed text-gray-600 text-gray-600">
                            You must be at least 13 years old to use the service. You represent that all registration information you submit is accurate and truthful. You are solely responsible for all activity that occurs on your account and for maintaining the confidentiality of your credentials.
                        </p>
                    </section>

                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">3. User-Generated Content (UGC)</h2>
                        <div className="space-y-4 text-gray-600">
                            <p>WanderWith allows you to upload photos, create travel plans, and communicate with others. You retain all ownership rights to your data.</p>
                            <p><strong>License:</strong> By sharing content publicly or within group trips, you grant WanderWith a non-exclusive, royalty-free, worldwide license to host, display, and distribute said content solely for the purpose of providing the service.</p>
                            <p><strong>Prohibited Content:</strong> You may not upload content that is illegal, defamatory, pornographic, harassing, or infringes on any intellectual property rights. WanderWith reserves the right to remove any content at its sole discretion.</p>
                        </div>
                    </section>

                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">4. Intellectual Property</h2>
                        <p className="leading-relaxed text-gray-600">
                            Everything on the WanderWith platform, including the logo, UI design, code, and branded text, is the property of WanderWith and is protected by copyright and intellectual property laws. You may not reproduce or distribute any part of the service without explicit written permission.
                        </p>
                    </section>

                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">5. Third-Party Links & Services</h2>
                        <p className="leading-relaxed text-gray-600">
                            Our platform contains links to third-party websites (e.g., booking sites, maps, guides). WanderWith does not own or control these services and is not responsible for their content, privacy policies, or practices. Use of third-party services is at your own risk.
                        </p>
                    </section>

                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">6. AI Travel Suggestions</h2>
                        <p className="leading-relaxed text-gray-600">
                            WanderWith uses artificial intelligence (Gemini AI) to provide travel recommendations and itineraries. These suggestions are generated based on algorithms and are for informational purposes only. We do not guarantee the accuracy, safety, or availability of any suggested activities or locations.
                        </p>
                    </section>

                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">7. Termination</h2>
                        <p className="leading-relaxed text-gray-600">
                            We may terminate or suspend your account immediately, without prior notice or liability, for any reason, including if you breach these Terms. Upon termination, your right to use the service will cease immediately.
                        </p>
                    </section>

                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">8. Disclaimer of Warranties</h2>
                        <p className="leading-relaxed text-gray-600 italic">
                            THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT ANY WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. WANDERWITH DOES NOT WARRANT THAT THE SERVICE WILL BE UNINTERRUPTED, SECURE, OR ERROR-FREE.
                        </p>
                    </section>

                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">9. Limitation of Liability</h2>
                        <p className="leading-relaxed text-gray-600">
                            WanderWith, its employees, or partners shall not be held liable for any travel-related incidents, financial loss, or personal injury resulting from the use of our services or reliance on information provided within the platform.
                        </p>
                    </section>

                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">10. Governing Law</h2>
                        <p className="leading-relaxed text-gray-600">
                            These terms shall be governed by and construed in accordance with the laws of India. Any disputes arising from these terms shall be subject to the exclusive jurisdiction of the courts in India.
                        </p>
                    </section>

                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">11. Contact Us</h2>
                        <p className="leading-relaxed text-gray-600 text-gray-600">
                            If you have questions about these Terms, please contact us at:
                            <br />
                            <a href="mailto:wanderwithplan@gmail.com" className="text-brand-accent font-medium hover:underline">wanderwithplan@gmail.com</a>
                        </p>
                    </section>
                </div>
            </div>
            <Footer />
        </main>
    );
}
