import Footer from "@/components/Footer";

export default function TermsAndConditions() {
    return (
        <main className="min-h-screen bg-brand-bg text-brand-text">
            <div className="container mx-auto px-6 py-24 max-w-4xl">
                <h1 className="text-4xl font-bold mb-8 text-brand-primary">Terms & Conditions</h1>
                <div className="prose prose-lg text-slate-600">
                    <p className="mb-4">Last Updated: [Date]</p>
                    <p className="mb-4">
                        Welcome to WanderWith. By using our website and services, you agree to these terms.
                    </p>
                    <h3 className="text-2xl font-bold text-brand-primary mt-8 mb-4">1. Acceptance of Terms</h3>
                    <p className="mb-4">
                        By accessing or using our services, you agree to be bound by these Terms.
                    </p>
                    <h3 className="text-2xl font-bold text-brand-primary mt-8 mb-4">2. User Accounts</h3>
                    <p className="mb-4">
                        You are responsible for maintaining the confidentiality of your account credentials.
                    </p>
                    <h3 className="text-2xl font-bold text-brand-primary mt-8 mb-4">3. Acceptable Use</h3>
                    <p className="mb-4">
                        You agree not to use our services for any illegal or unauthorized purpose.
                    </p>
                    <h3 className="text-2xl font-bold text-brand-primary mt-8 mb-4">4. Limitation of Liability</h3>
                    <p className="mb-4">
                        WanderWith shall not be liable for any indirect, incidental, or consequential damages.
                    </p>
                </div>
            </div>
            <Footer />
        </main>
    );
}
