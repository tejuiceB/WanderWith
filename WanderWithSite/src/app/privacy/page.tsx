import Footer from "@/components/Footer";
import BrandHeader from "@/components/BrandHeader";
import type { Metadata } from "next";

export const metadata: Metadata = {
    title: "Privacy Policy | WanderWith",
    description: "Learn how WanderWith collects, uses, and protects your personal data. Read our comprehensive privacy policy.",
};

export default function PrivacyPolicy() {
    return (
        <main className="min-h-screen bg-white text-gray-800">
            <BrandHeader />
            <div className="container mx-auto px-6 py-24 max-w-4xl">
                <div className="mb-12 border-b border-gray-100 pb-8">
                    <h1 className="text-4xl md:text-5xl font-serif font-bold mb-4 text-brand-primary">Privacy Policy</h1>
                    <p className="text-gray-500">Effective Date: March 2, 2026 &middot; Last Updated: March 2, 2026</p>
                </div>

                <div className="space-y-12">
                    {/* 1 — Introduction */}
                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">1. Introduction</h2>
                        <p className="leading-relaxed text-gray-600">
                            WanderWith (&quot;we&quot;, &quot;our&quot;, or &quot;us&quot;) is a travel-planning platform operated from India. We respect your privacy and are committed to protecting your personal data. This Privacy Policy explains what information we collect, how we use it, and the choices you have when you use our mobile application (&quot;App&quot;) available on Android, and our website at{" "}
                            <a href="https://www.wanderwith.online" className="text-brand-accent hover:underline">www.wanderwith.online</a> (&quot;Site&quot;). By using WanderWith, you agree to the practices described herein. If you have questions, contact us at{" "}
                            <a href="mailto:wanderwithplan@gmail.com" className="text-brand-accent hover:underline">wanderwithplan@gmail.com</a>.
                        </p>
                    </section>

                    {/* 2 — Data We Collect */}
                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">2. Data We Collect</h2>
                        <div className="space-y-6 text-gray-600">
                            <div>
                                <h3 className="font-bold text-gray-900 mb-2">A. Information You Provide Directly</h3>
                                <ul className="list-disc pl-6 space-y-2">
                                    <li><strong>Account Registration:</strong> Name, email address, and profile picture—supplied via Google Sign-In (OAuth 2.0) or email/password signup through Supabase Auth.</li>
                                    <li><strong>Trip &amp; Itinerary Data:</strong> Destinations, travel dates, itineraries, budgets, notes, checklists, and collaborative invite links you create or join.</li>
                                    <li><strong>User-Generated Content:</strong> Photos uploaded to trip galleries, messages sent in group chats, published memories, and public trip posts.</li>
                                    <li><strong>Expense &amp; Budget Data:</strong> Trip expense entries, split details, and budget categories you record within the app.</li>
                                    <li><strong>Support &amp; Feedback:</strong> Any information you provide when contacting us via email or in-app feedback forms.</li>
                                </ul>
                            </div>
                            <div>
                                <h3 className="font-bold text-gray-900 mb-2">B. Information Collected Automatically</h3>
                                <ul className="list-disc pl-6 space-y-2">
                                    <li><strong>Device Information:</strong> Operating system, device model, app version, screen resolution, and language/locale.</li>
                                    <li><strong>Usage &amp; Crash Data:</strong> Feature interactions, navigation paths, error/crash logs, and performance metrics to help us improve reliability.</li>
                                    <li><strong>Network Information:</strong> Connection type (WiFi/mobile) used solely to optimise sync behaviour and offline support.</li>
                                </ul>
                            </div>
                            <div>
                                <h3 className="font-bold text-gray-900 mb-2">C. Permissions-Based Data</h3>
                                <ul className="list-disc pl-6 space-y-2">
                                    <li><strong>Camera &amp; Photo Library:</strong> Accessed only when you choose to upload photos to a trip gallery. We do not access your camera or photos without your explicit action.</li>
                                    <li><strong>Location (Optional):</strong> If you grant location permission, we use it to show nearby places on the map and to auto-fill location fields. Location is never tracked in the background.</li>
                                    <li><strong>Notifications:</strong> Push notification tokens are stored to deliver trip reminders, chat messages, and collaboration invites. You can disable notifications in your device settings at any time.</li>
                                    <li><strong>Internet Access:</strong> Required for syncing trip data, authentication, and real-time collaboration features.</li>
                                </ul>
                            </div>
                        </div>
                    </section>

                    {/* 3 — How We Use Your Data */}
                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">3. How We Use Your Data</h2>
                        <ul className="list-disc pl-6 space-y-2 text-gray-600">
                            <li><strong>Provide &amp; Operate the Service:</strong> Create accounts, manage trips, enable real-time collaboration, sync data across devices, and deliver push notifications.</li>
                            <li><strong>AI-Powered Itinerary Generation:</strong> When you request AI suggestions, your trip preferences (destination, dates, interests) are sent to Gemini AI to generate personalised itineraries. This data is used only for that single request and is <strong>not</strong> stored by Google or used to train AI models.</li>
                            <li><strong>Improve &amp; Debug:</strong> Analyse usage patterns and crash reports to fix bugs, optimise performance, and develop new features.</li>
                            <li><strong>Safety &amp; Security:</strong> Detect abuse, prevent fraud, and enforce our Terms &amp; Conditions.</li>
                            <li><strong>Communications:</strong> Send transactional emails (password resets, invite confirmations) and, with your consent, occasional product updates. You can opt-out of non-essential emails at any time.</li>
                        </ul>
                    </section>

                    {/* 4 — Legal Basis for Processing */}
                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">4. Legal Basis for Processing</h2>
                        <ul className="list-disc pl-6 space-y-2 text-gray-600">
                            <li><strong>Contractual Necessity:</strong> Processing required to provide the service you signed up for (account management, trip planning, collaboration).</li>
                            <li><strong>Legitimate Interests:</strong> Improving app performance, preventing misuse, and generating aggregated analytics.</li>
                            <li><strong>Consent:</strong> For optional features such as camera/photo access, location permission, and push notifications. You may withdraw consent at any time via device settings.</li>
                            <li><strong>Legal Obligation:</strong> Where processing is required to comply with applicable laws or regulations.</li>
                        </ul>
                    </section>

                    {/* 5 — Third-Party Services & Sub-processors */}
                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">5. Third-Party Services &amp; Sub-processors</h2>
                        <p className="leading-relaxed text-gray-600 mb-4">
                            We rely on trusted third-party providers to deliver core functionality. Each processes data under our instructions and their own privacy policies:
                        </p>
                        <div className="overflow-x-auto">
                            <table className="w-full text-sm text-gray-600 border border-gray-200 rounded-lg">
                                <thead className="bg-gray-50">
                                    <tr>
                                        <th className="text-left px-4 py-3 font-bold text-gray-900">Provider</th>
                                        <th className="text-left px-4 py-3 font-bold text-gray-900">Purpose</th>
                                        <th className="text-left px-4 py-3 font-bold text-gray-900">Data Processed</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-gray-100">
                                    <tr><td className="px-4 py-3 font-medium">Supabase</td><td className="px-4 py-3">Database, Auth, File Storage, Edge Functions</td><td className="px-4 py-3">Account info, trip data, photos, auth tokens</td></tr>
                                    <tr><td className="px-4 py-3 font-medium">Google Cloud / Maps</td><td className="px-4 py-3">Maps, Places API, Geocoding</td><td className="px-4 py-3">Location queries, map interactions</td></tr>
                                    <tr><td className="px-4 py-3 font-medium">Gemini AI (Google)</td><td className="px-4 py-3">AI itinerary generation</td><td className="px-4 py-3">Trip preferences (single-session only)</td></tr>
                                    <tr><td className="px-4 py-3 font-medium">Google Sign-In</td><td className="px-4 py-3">OAuth authentication</td><td className="px-4 py-3">Email, name, profile picture</td></tr>
                                    <tr><td className="px-4 py-3 font-medium">Vercel</td><td className="px-4 py-3">Website hosting</td><td className="px-4 py-3">Standard HTTP logs, cookies</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </section>

                    {/* 6 — Data Sharing & Disclosure */}
                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">6. Data Sharing &amp; Disclosure</h2>
                        <p className="leading-relaxed text-gray-600 mb-3">
                            <strong>We do not sell, rent, or trade your personal data.</strong> Information is shared only in these limited scenarios:
                        </p>
                        <ul className="list-disc pl-6 space-y-2 text-gray-600">
                            <li><strong>Trip Collaborators:</strong> Users you explicitly invite to a trip can see the trip&apos;s itinerary, gallery, chat, and expense data.</li>
                            <li><strong>Public Content:</strong> If you choose to &quot;Publish&quot; a trip or memory, it becomes visible to the WanderWith community and may appear in search results.</li>
                            <li><strong>Service Providers:</strong> The sub-processors listed above, solely to operate and improve the service.</li>
                            <li><strong>Legal Requirements:</strong> If required by law, subpoena, court order, or to protect the rights, property, or safety of WanderWith, our users, or the public.</li>
                            <li><strong>Business Transfers:</strong> In the event of a merger, acquisition, or asset sale, user data may be transferred. We will notify you before your data is subject to a different privacy policy.</li>
                        </ul>
                    </section>

                    {/* 7 — Cookies & Tracking */}
                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">7. Cookies &amp; Tracking Technologies</h2>
                        <p className="leading-relaxed text-gray-600 mb-3">
                            Our website uses only <strong>essential/functional cookies</strong> to maintain your session and security (managed by Supabase Auth). We do <strong>not</strong> use third-party advertising cookies or cross-site tracking pixels.
                        </p>
                        <p className="leading-relaxed text-gray-600">
                            The mobile app does not use cookies. Authentication tokens are stored securely in device-native secure storage.
                        </p>
                    </section>

                    {/* 8 — Data Security */}
                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">8. Data Security</h2>
                        <p className="leading-relaxed text-gray-600">
                            We take reasonable technical and organisational measures to protect your data, including:
                        </p>
                        <ul className="list-disc pl-6 space-y-2 text-gray-600 mt-3">
                            <li>All data transmitted between your device and our servers is encrypted via TLS/SSL.</li>
                            <li>Passwords are hashed using industry-standard algorithms (bcrypt via Supabase Auth); we never store plaintext passwords.</li>
                            <li>Database access is governed by Row-Level Security (RLS) policies, ensuring users can only access data they are authorised to view.</li>
                            <li>File uploads (photos) are stored in Supabase Storage with access-controlled bucket policies.</li>
                            <li>Authentication uses PKCE (Proof Key for Code Exchange) flow for enhanced security.</li>
                        </ul>
                        <p className="leading-relaxed text-gray-600 mt-3">
                            While we strive to protect your data, no method of electronic transmission or storage is 100% secure. We cannot guarantee absolute security.
                        </p>
                    </section>

                    {/* 9 — Data Retention & Deletion */}
                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">9. Data Retention &amp; Deletion</h2>
                        <p className="leading-relaxed text-gray-600 mb-3">
                            We retain your personal data only as long as necessary to provide the service and fulfil the purposes described in this policy:
                        </p>
                        <ul className="list-disc pl-6 space-y-2 text-gray-600">
                            <li><strong>Active Accounts:</strong> Data is retained for the lifetime of your account.</li>
                            <li><strong>Account Deletion:</strong> You can delete your account from the App settings. Upon deletion, your profile, private trips, uploaded photos, and personal data are permanently removed within 30 days.</li>
                            <li><strong>Group Trips:</strong> If you delete your account while part of a group trip, the trip remains for other members. Your messages and contributions are anonymised (displayed as &quot;Deleted User&quot;).</li>
                            <li><strong>Backup Retention:</strong> Encrypted database backups may retain residual data for up to 90 days before being purged.</li>
                        </ul>
                    </section>

                    {/* 10 — International Data Transfers */}
                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">10. International Data Transfers</h2>
                        <p className="leading-relaxed text-gray-600">
                            WanderWith is operated from India. Our infrastructure providers (Supabase, Google Cloud, Vercel) may process data in regions outside your country of residence, including the United States and the European Economic Area. These providers maintain appropriate safeguards (such as Standard Contractual Clauses) for cross-border data transfers. By using WanderWith, you consent to the transfer of your data to these jurisdictions.
                        </p>
                    </section>

                    {/* 11 — Children's Privacy */}
                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">11. Children&apos;s Privacy</h2>
                        <p className="leading-relaxed text-gray-600">
                            WanderWith is not directed at children under the age of 13 (or the applicable age of digital consent in your jurisdiction). We do not knowingly collect personal information from children. If we become aware that a user is under 13, we will promptly terminate the account and delete all associated data. If you believe a child has provided us with personal information, please contact us at{" "}
                            <a href="mailto:wanderwithplan@gmail.com" className="text-brand-accent hover:underline">wanderwithplan@gmail.com</a>.
                        </p>
                    </section>

                    {/* 12 — Your Rights */}
                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">12. Your Rights</h2>
                        <p className="leading-relaxed text-gray-600 mb-3">
                            Depending on your jurisdiction, you may have the following rights regarding your personal data:
                        </p>
                        <ul className="list-disc pl-6 space-y-2 text-gray-600">
                            <li><strong>Access:</strong> Request a copy of the personal data we hold about you.</li>
                            <li><strong>Rectification:</strong> Correct inaccurate or incomplete personal data via your profile settings.</li>
                            <li><strong>Deletion:</strong> Request deletion of your account and associated data.</li>
                            <li><strong>Data Portability:</strong> Request your data in a structured, commonly used format.</li>
                            <li><strong>Withdraw Consent:</strong> Revoke permissions (camera, location, notifications) at any time through your device settings.</li>
                            <li><strong>Objection:</strong> Object to processing based on legitimate interests.</li>
                        </ul>
                        <p className="leading-relaxed text-gray-600 mt-3">
                            To exercise any of these rights, use the in-app account settings or email us at{" "}
                            <a href="mailto:wanderwithplan@gmail.com" className="text-brand-accent hover:underline">wanderwithplan@gmail.com</a>. We will respond within 30 days.
                        </p>
                    </section>

                    {/* 13 — Google API Services Disclosure */}
                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">13. Google API Services Disclosure</h2>
                        <p className="leading-relaxed text-gray-600">
                            WanderWith&apos;s use and transfer of information received from Google APIs adheres to the{" "}
                            <a href="https://developers.google.com/terms/api-services-user-data-policy" target="_blank" rel="noopener noreferrer" className="text-brand-accent hover:underline">Google API Services User Data Policy</a>, including the Limited Use requirements. We only request the minimum scopes necessary for authentication (email, profile) and do not use Google user data for serving advertisements or for any purpose other than providing and improving WanderWith.
                        </p>
                    </section>

                    {/* 14 — Changes to This Policy */}
                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">14. Changes to This Policy</h2>
                        <p className="leading-relaxed text-gray-600">
                            We may update this Privacy Policy from time to time to reflect changes in our practices, technology, or legal requirements. When we make material changes, we will update the &quot;Last Updated&quot; date at the top and, where appropriate, notify you via the App or email. Your continued use of WanderWith after any changes constitutes acceptance of the revised policy.
                        </p>
                    </section>

                    {/* 15 — Contact Us */}
                    <section>
                        <h2 className="text-2xl font-bold text-brand-primary mb-4">15. Contact Us</h2>
                        <p className="leading-relaxed text-gray-600">
                            For any privacy-related inquiries, data requests, or concerns, please contact us:
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
