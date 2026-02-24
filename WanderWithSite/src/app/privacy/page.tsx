import Footer from "@/components/Footer";
import BrandHeader from "@/components/BrandHeader";

export default function PrivacyPolicy() {
    return (
        <main className="min-h-screen bg-white text-gray-800">
            <BrandHeader />
            <div className="container mx-auto px-6 py-24 max-w-4xl">
                <div className="mb-12 border-b border-gray-100 pb-8">
                    <h1 className="text-4xl md:text-5xl font-serif font-bold mb-4 text-brand-primary">Privacy Policy</h1>
                    <p className="text-gray-500">Last Updated: February 23, 2026</p>
                </div>

                <div className="space-y-12">
                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">1. Introduction</h2>
                        <p className="leading-relaxed text-gray-600">
                            WanderWith ("we", "our", or "us") respects your privacy and is committed to protecting the personal data we process. This Privacy Policy describes how we collect, use, store, and share your personal information when you use our mobile application ("App") and website ("Site"). If you have any questions, contact us at <a href="mailto:wanderwithplan@gmail.com" className="text-brand-accent hover:underline">wanderwithplan@gmail.com</a>.
                        </p>
                    </section>

                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">2. Data We Collect</h2>
                        <div className="space-y-6 text-gray-600">
                            <div>
                                <h3 className="font-bold text-gray-900 mb-2">A. Information You Provide to Us</h3>
                                <ul className="list-disc pl-6 space-y-2">
                                    <li><strong>Account Registration:</strong> Name, email address, profile picture (via Google OAuth or email signup).</li>
                                    <li><strong>Trip Details:</strong> Destinations, dates, itineraries, budgets, notes, and collaborative links.</li>
                                    <li><strong>User Content:</strong> Photos uploaded to galleries, messages in group chats, and public posts.</li>
                                    <li><strong>Communication Data:</strong> Any information you provide when contacting support or providing feedback.</li>
                                </ul>
                            </div>
                            <div>
                                <h3 className="font-bold text-gray-900 mb-2">B. Information Collected Automatically</h3>
                                <ul className="list-disc pl-6 space-y-2">
                                    <li><strong>Device Information:</strong> OS version, device model, and unique device identifiers.</li>
                                    <li><strong>Usage Logs:</strong> Feature interactions, error logs, and performance metrics.</li>
                                    <li><strong>Cookies and Tracking:</strong> We use essential cookies to maintain your session and security (managed by Supabase).</li>
                                </ul>
                            </div>
                        </div>
                    </section>

                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">3. Third-Party Sub-processors</h2>
                        <p className="leading-relaxed text-gray-600 mb-4">
                            To provide our services, we use several trusted third-party providers who process data according to our instructions:
                        </p>
                        <ul className="list-disc pl-6 space-y-2 text-gray-600">
                            <li><strong>Supabase:</strong> Provides our database, authentication, and secure file storage.</li>
                            <li><strong>Google Cloud/Maps:</strong> Provides location search, maps, and geolocation services.</li>
                            <li><strong>Gemini AI (Google):</strong> Processes trip preferences to generate AI itineraries. Your data is used only for the current planning session and is not used to train global AI models.</li>
                        </ul>
                    </section>

                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">4. How We Use Your Data</h2>
                        <p className="leading-relaxed text-gray-600 mb-4">
                            We process your data based on these legal grounds:
                        </p>
                        <ul className="list-disc pl-6 space-y-2 text-gray-600">
                            <li><strong>Contractual Necessity:</strong> To create and manage your trips and account.</li>
                            <li><strong>Legitimate Interests:</strong> To improve app performance, prevent fraud, and provide AI suggestions.</li>
                            <li><strong>Consent:</strong> For specific features like accessing your camera roll for photo uploads.</li>
                        </ul>
                    </section>

                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">5. Data Sharing & Disclosure</h2>
                        <p className="leading-relaxed text-gray-600">
                            We do not sell your personal data. Your trip data is shared only with:
                            <br />- <strong>Collaborators:</strong> Users you explicitly invite to your trips.
                            <br />- <strong>Public:</strong> Only if you choose to "Publish" a memory or trip for community discovery.
                            <br />- <strong>Legal Compliance:</strong> If required by law to protect our rights or comply with judicial proceedings.
                        </p>
                    </section>

                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">6. Data Retention & Deletion</h2>
                        <p className="leading-relaxed text-gray-600">
                            We retain your data as long as your account is active. When you delete your account:
                            <br />- Your personal profile and private trips are permanently deleted.
                            <br />- Group trips remain active for other members, but your contributions (messages/photos) are anonymized or removed as per system policy.
                        </p>
                    </section>

                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">7. Children's Privacy</h2>
                        <p className="leading-relaxed text-gray-600">
                            WanderWith is not intended for children under 13. We do not knowingly collect information from children. If we discover a user under 13, we will terminate the account and delete the associated data immediately.
                        </p>
                    </section>

                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">8. Your Rights</h2>
                        <p className="leading-relaxed text-gray-600">
                            Depending on your location, you have the right to access, correct, or port your data. You can exercise these rights directly through the App settings or by contacting us.
                        </p>
                    </section>

                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">9. Contact Us</h2>
                        <p className="leading-relaxed text-gray-600">
                            For any privacy-related inquiries, please contact our Data Protection Coordinator:
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
