'use client';

import React, { useState, useEffect } from 'react';
import { createClient } from '@supabase/supabase-js';
import { Eye, EyeOff, Check, AlertCircle, Smartphone, Globe } from 'lucide-react';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';

export default function ResetPasswordForm() {
    const [password, setPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [status, setStatus] = useState<'loading' | 'app-redirect' | 'ready' | 'submitting' | 'success' | 'error' | 'no-session'>('app-redirect');
    const [errorMsg, setErrorMsg] = useState('');
    const [appOpenAttempted, setAppOpenAttempted] = useState(false);

    async function initializeSession(code: string | null, hash: string) {
        if (!supabaseUrl || !supabaseAnonKey) {
            setStatus('ready');
            return;
        }

        const supabase = createClient(supabaseUrl, supabaseAnonKey);

        try {
            // Try PKCE code exchange first
            if (code) {
                const { error } = await supabase.auth.exchangeCodeForSession(code);
                if (!error) {
                    setStatus('ready');
                    return;
                }
                console.error('Code exchange failed:', error.message);
            }

            // Try hash-based recovery (older Supabase flow)
            if (hash && hash.includes('type=recovery')) {
                // Supabase auto-detects the hash in the URL
                const { data: { session } } = await supabase.auth.getSession();
                if (session) {
                    setStatus('ready');
                    return;
                }
            }

            // Check if there's already a session
            const { data: { session } } = await supabase.auth.getSession();
            if (session) {
                setStatus('ready');
                return;
            }

            setStatus('no-session');
        } catch (e) {
            console.error('Session init error:', e);
            setStatus('no-session');
        }
    }

    useEffect(() => {
        // Step 1: Try to open the reset link in the app first
        const params = new URLSearchParams(window.location.search);
        const hash = window.location.hash;
        const code = params.get('code');
        const token = params.get('token');

        // Build the deep link URL
        let appUrl = 'wanderwith://reset-password';
        const queryParts: string[] = [];
        if (code) queryParts.push(`code=${code}`);
        if (token) queryParts.push(`token=${token}`);
        if (hash) queryParts.push(hash.replace('#', ''));
        if (queryParts.length > 0) appUrl += '?' + queryParts.join('&');

        // Try opening the app without setting state synchronously
        window.location.href = appUrl;

        // If still on this page after 2.5 seconds, app didn't open — show web form
        const timer = setTimeout(async () => {
            setAppOpenAttempted(true);
            await initializeSession(code, hash);
        }, 2500);

        window.addEventListener('blur', () => {
            // App opened successfully, clear the timer
            clearTimeout(timer);
        }, { once: true });

        return () => clearTimeout(timer);
    }, []);

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        setErrorMsg('');

        if (password.length < 8) {
            setErrorMsg('Password must be at least 8 characters.');
            return;
        }
        if (password !== confirmPassword) {
            setErrorMsg('Passwords do not match.');
            return;
        }

        setStatus('submitting');

        try {
            const supabase = createClient(supabaseUrl, supabaseAnonKey);
            const { error } = await supabase.auth.updateUser({ password });

            if (error) {
                setErrorMsg(error.message);
                setStatus('ready');
                return;
            }

            setStatus('success');
        } catch (err) {
            setErrorMsg('Something went wrong. Please try again.');
            setStatus('ready');
        }
    }

    const passwordValid = password.length >= 8;
    const passwordsMatch = password === confirmPassword && confirmPassword.length > 0;

    // Loading / redirecting to app
    if (status === 'loading' || (status === 'app-redirect' && !appOpenAttempted)) {
        return (
            <div className="text-center py-12">
                <div className="w-16 h-16 bg-blue-50 rounded-2xl flex items-center justify-center mx-auto mb-6">
                    <Smartphone className="text-brand-accent" size={32} />
                </div>
                <h2 className="text-2xl font-bold text-brand-primary mb-3">Opening WanderWith...</h2>
                <p className="text-gray-500 mb-6">Trying to open the password reset in the app.</p>
                <div className="w-8 h-8 border-3 border-brand-accent border-t-transparent rounded-full animate-spin mx-auto" />
            </div>
        );
    }

    // No valid session — link expired or invalid
    if (status === 'no-session') {
        return (
            <div className="text-center py-12">
                <div className="w-16 h-16 bg-red-50 rounded-2xl flex items-center justify-center mx-auto mb-6">
                    <AlertCircle className="text-red-500" size={32} />
                </div>
                <h2 className="text-2xl font-bold text-brand-primary mb-3">Link Expired</h2>
                <p className="text-gray-500 mb-6">
                    This password reset link has expired or is invalid.<br />
                    Please request a new one from the app.
                </p>
                <a
                    href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
                    className="inline-flex items-center gap-2 bg-brand-accent text-white px-6 py-3 rounded-2xl font-bold hover:opacity-90 transition-all"
                >
                    Open WanderWith
                </a>
            </div>
        );
    }

    // Success
    if (status === 'success') {
        return (
            <div className="text-center py-12">
                <div className="w-16 h-16 bg-green-50 rounded-2xl flex items-center justify-center mx-auto mb-6">
                    <Check className="text-green-600" size={32} />
                </div>
                <h2 className="text-2xl font-bold text-brand-primary mb-3">Password Updated!</h2>
                <p className="text-gray-500 mb-6">
                    Your password has been changed successfully.<br />
                    You can now sign in with your new password.
                </p>
                <a
                    href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
                    className="inline-flex items-center gap-2 bg-brand-accent text-white px-6 py-3 rounded-2xl font-bold hover:opacity-90 transition-all"
                >
                    Open WanderWith
                </a>
            </div>
        );
    }

    // Password reset form
    return (
        <div>
            {appOpenAttempted && (
                <div className="flex items-center gap-2 bg-blue-50 text-blue-700 px-4 py-3 rounded-xl mb-8 text-sm">
                    <Globe size={16} />
                    <span>App not installed? No worries — reset your password right here.</span>
                </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-6">
                <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-2">New Password</label>
                    <div className="relative">
                        <input
                            type={showPassword ? 'text' : 'password'}
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            placeholder="At least 8 characters"
                            className="w-full px-4 py-3.5 rounded-xl border-2 border-gray-200 focus:border-brand-accent focus:ring-0 outline-none transition-colors text-gray-800 bg-white"
                            required
                            minLength={8}
                        />
                        <button
                            type="button"
                            onClick={() => setShowPassword(!showPassword)}
                            className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                        >
                            {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                        </button>
                    </div>
                    {password.length > 0 && (
                        <div className={`flex items-center gap-1.5 mt-2 text-xs ${passwordValid ? 'text-green-600' : 'text-gray-400'}`}>
                            <Check size={14} />
                            <span>At least 8 characters</span>
                        </div>
                    )}
                </div>

                <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-2">Confirm Password</label>
                    <input
                        type={showPassword ? 'text' : 'password'}
                        value={confirmPassword}
                        onChange={(e) => setConfirmPassword(e.target.value)}
                        placeholder="Re-enter your password"
                        className="w-full px-4 py-3.5 rounded-xl border-2 border-gray-200 focus:border-brand-accent focus:ring-0 outline-none transition-colors text-gray-800 bg-white"
                        required
                    />
                    {confirmPassword.length > 0 && (
                        <div className={`flex items-center gap-1.5 mt-2 text-xs ${passwordsMatch ? 'text-green-600' : 'text-red-500'}`}>
                            {passwordsMatch ? <Check size={14} /> : <AlertCircle size={14} />}
                            <span>{passwordsMatch ? 'Passwords match' : 'Passwords do not match'}</span>
                        </div>
                    )}
                </div>

                {errorMsg && (
                    <div className="flex items-center gap-2 bg-red-50 text-red-600 px-4 py-3 rounded-xl text-sm">
                        <AlertCircle size={16} />
                        <span>{errorMsg}</span>
                    </div>
                )}

                <button
                    type="submit"
                    disabled={status === 'submitting' || !passwordValid || !passwordsMatch}
                    className="w-full bg-brand-accent text-white py-4 rounded-2xl font-bold text-lg shadow-lg hover:scale-[1.01] active:scale-[0.99] transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                >
                    {status === 'submitting' ? (
                        <span className="flex items-center justify-center gap-2">
                            <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                            Updating...
                        </span>
                    ) : (
                        'Update Password'
                    )}
                </button>
            </form>
        </div>
    );
}
