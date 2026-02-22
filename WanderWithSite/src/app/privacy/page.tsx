import Footer from "@/components/Footer";

export default function PrivacyPolicy() {
    return (
        <main className="min-h-screen bg-brand-bg text-brand-text">
            <div className="container mx-auto px-6 py-24 max-w-4xl">
                <h1 className="text-4xl font-bold mb-8 text-brand-primary">Privacy Policy</h1>
                <div className="prose prose-lg text-slate-600">
                    <p className="mb-4">Last Updated: [Date]</p>
                    <p className="mb-4">
                        At WanderWith, we take your privacy seriously. This policy explains how we handle your data.
                    </p>
                    <h3 className="text-2xl font-bold text-brand-primary mt-8 mb-4">1. Information We Collect</h3>
                    <p className="mb-4">
                        We collect information you provide directly to us, such as when you create an account, create a trip, or contact us for support.
                    </p>
                    <h3 className="text-2xl font-bold text-brand-primary mt-8 mb-4">2. How We Use Your Information</h3>
                    <p className="mb-4">
                        We use your information to provide, maintain, and improve our services, including to facilitate trip planning and community connection.
                    </p>
                    <h3 className="text-2xl font-bold text-brand-primary mt-8 mb-4">3. Data Security</h3>
                    <p className="mb-4">
                        We implement strict security measures to protect your personal information.
                    </p>
                    <h3 className="text-2xl font-bold text-brand-primary mt-8 mb-4">4. Contact Us</h3>
                    <p className="mb-4">
                        If you have any questions, please contact us at support@wanderwith.com.
                    </p>
                </div>
            </div>
            <Footer />
        </main>
    );
}
