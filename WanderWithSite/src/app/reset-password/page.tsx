import type { Metadata } from 'next';
import BrandHeader from '@/components/BrandHeader';
import Footer from '@/components/Footer';
import ResetPasswordForm from '@/components/ResetPasswordForm';
import { Lock } from 'lucide-react';

export const metadata: Metadata = {
    title: 'Reset Password | WanderWith',
    description: 'Reset your WanderWith account password securely.',
    robots: { index: false, follow: false },
};

export default function ResetPasswordPage() {
    return (
        <main className="min-h-screen bg-gradient-to-b from-white to-gray-50 text-gray-800">
            <BrandHeader />
            <div className="container mx-auto px-6 py-28 max-w-md">
                <div className="bg-white rounded-3xl shadow-xl p-8 border border-gray-100">
                    <div className="text-center mb-8">
                        <div className="w-14 h-14 bg-brand-accent/10 rounded-2xl flex items-center justify-center mx-auto mb-4">
                            <Lock className="text-brand-accent" size={28} />
                        </div>
                        <h1 className="text-2xl font-bold text-brand-primary">Reset Your Password</h1>
                        <p className="text-gray-500 text-sm mt-2">Choose a new secure password for your WanderWith account.</p>
                    </div>

                    <ResetPasswordForm />
                </div>

                <p className="text-center text-xs text-gray-400 mt-8">
                    Didn&apos;t request this? You can safely ignore this page.
                </p>
            </div>
            <Footer />
        </main>
    );
}
