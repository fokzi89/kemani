'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { ArrowRight, Building2, User, Mail } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';

export default function RegisterPage() {
    const [formData, setFormData] = useState({
        businessName: '',
        fullName: '',
        email: '',
        passcode: '',
        confirmPasscode: '',
    });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [isValidSession, setIsValidSession] = useState(false);

    const router = useRouter();
    const searchParams = useSearchParams();
    const identifier = searchParams.get('identifier');

    const supabase = createClient();

    useEffect(() => {
        // Pre-fill email if provided from login flow
        if (identifier) {
            setFormData(prev => ({ ...prev, email: identifier }));
        }

        // Check if user has valid session
        const checkSession = async () => {
            const { data: { session } } = await supabase.auth.getSession();
            if (!session) {
                router.push('/login');
            } else {
                setIsValidSession(true);
            }
        };
        checkSession();
    }, [identifier, supabase, router]);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        try {
            // Validate passcode
            if (formData.passcode.length !== 6 || !/^\d{6}$/.test(formData.passcode)) {
                throw new Error('Passcode must be exactly 6 digits');
            }

            if (formData.passcode !== formData.confirmPasscode) {
                throw new Error('Passcodes do not match');
            }

            // Get current user session
            const { data: { user } } = await supabase.auth.getUser();

            if (!user) {
                throw new Error('User not authenticated. Please login again.');
            }

            const response = await fetch('/api/auth/register', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    businessName: formData.businessName,
                    fullName: formData.fullName,
                    email: formData.email || user.email,
                    passcode: formData.passcode,
                }),
            });

            const result = await response.json();

            if (!response.ok) {
                throw new Error(result.error || 'Failed to complete registration');
            }

            // Redirect to POS dashboard
            router.push('/pos/pos');
        } catch (err: any) {
            setError(err.message || 'Failed to complete registration');
            setLoading(false);
        }
    };

    if (!isValidSession) {
        return (
            <div className="min-h-screen bg-gradient-to-b from-emerald-950 via-green-900 to-gray-900 flex items-center justify-center">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-400"></div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-gradient-to-b from-emerald-950 via-green-900 to-gray-900 flex items-center justify-center px-4 py-12">
            <div className="w-full max-w-md">
                {/* Logo */}
                <div className="text-center mb-8">
                    <Link href="/" className="inline-flex items-center">
                        <span className="text-3xl font-bold text-emerald-400">Kemani</span>
                        <span className="ml-2 text-lg text-emerald-300/70">POS</span>
                    </Link>
                    <p className="mt-2 text-emerald-100/70">Complete your registration</p>
                    <p className="mt-1 text-sm text-emerald-300/50">Just a few details to get started</p>
                </div>

                {/* Registration Card */}
                <div className="bg-white/5 backdrop-blur-md rounded-2xl p-8 border border-emerald-500/20">
                    <form onSubmit={handleSubmit}>
                        {/* Business Name */}
                        <div className="mb-4">
                            <label htmlFor="businessName" className="block text-sm font-medium text-emerald-100 mb-2">
                                <Building2 className="inline h-4 w-4 mr-1" />
                                Business Name
                            </label>
                            <input
                                id="businessName"
                                type="text"
                                value={formData.businessName}
                                onChange={(e) => setFormData({ ...formData, businessName: e.target.value })}
                                placeholder="e.g., My Coffee Shop"
                                className="w-full px-4 py-3 bg-white/10 border border-emerald-500/30 rounded-lg text-white placeholder-emerald-300/40 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
                                required
                            />
                        </div>

                        {/* Full Name */}
                        <div className="mb-4">
                            <label htmlFor="fullName" className="block text-sm font-medium text-emerald-100 mb-2">
                                <User className="inline h-4 w-4 mr-1" />
                                Your Full Name
                            </label>
                            <input
                                id="fullName"
                                type="text"
                                value={formData.fullName}
                                onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
                                placeholder="e.g., John Doe"
                                className="w-full px-4 py-3 bg-white/10 border border-emerald-500/30 rounded-lg text-white placeholder-emerald-300/40 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
                                required
                            />
                        </div>

                        {/* Email (Read-only if pre-filled) */}
                        <div className="mb-4">
                            <label htmlFor="email" className="block text-sm font-medium text-emerald-100 mb-2">
                                <Mail className="inline h-4 w-4 mr-1" />
                                Email Address
                            </label>
                            <input
                                id="email"
                                type="email"
                                value={formData.email}
                                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                                placeholder="you@example.com"
                                className="w-full px-4 py-3 bg-white/10 border border-emerald-500/30 rounded-lg text-white placeholder-emerald-300/40 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
                                required
                                readOnly={!!identifier}
                            />
                        </div>

                        {/* Security Section */}
                        <div className="mb-6 p-4 bg-emerald-500/10 border border-emerald-500/30 rounded-lg">
                            <h3 className="text-sm font-semibold text-emerald-100 mb-3">
                                🔒 Security Setup (Required for POS access)
                            </h3>
                            <p className="text-xs text-emerald-100/60 mb-4">
                                Set a 6-digit passcode. After 10 minutes of inactivity, you'll need to enter this passcode or use fingerprint to unlock.
                            </p>

                            {/* 6-Digit Passcode */}
                            <div className="mb-3">
                                <label htmlFor="passcode" className="block text-sm font-medium text-emerald-100 mb-2">
                                    6-Digit Passcode
                                </label>
                                <input
                                    id="passcode"
                                    type="password"
                                    inputMode="numeric"
                                    pattern="\d{6}"
                                    maxLength={6}
                                    value={formData.passcode}
                                    onChange={(e) => {
                                        const value = e.target.value.replace(/\D/g, '');
                                        setFormData({ ...formData, passcode: value });
                                    }}
                                    placeholder="000000"
                                    className="w-full px-4 py-3 bg-white/10 border border-emerald-500/30 rounded-lg text-white placeholder-emerald-300/40 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent text-center text-2xl tracking-widest"
                                    required
                                />
                            </div>

                            {/* Confirm Passcode */}
                            <div>
                                <label htmlFor="confirmPasscode" className="block text-sm font-medium text-emerald-100 mb-2">
                                    Confirm Passcode
                                </label>
                                <input
                                    id="confirmPasscode"
                                    type="password"
                                    inputMode="numeric"
                                    pattern="\d{6}"
                                    maxLength={6}
                                    value={formData.confirmPasscode}
                                    onChange={(e) => {
                                        const value = e.target.value.replace(/\D/g, '');
                                        setFormData({ ...formData, confirmPasscode: value });
                                    }}
                                    placeholder="000000"
                                    className="w-full px-4 py-3 bg-white/10 border border-emerald-500/30 rounded-lg text-white placeholder-emerald-300/40 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent text-center text-2xl tracking-widest"
                                    required
                                />
                            </div>
                        </div>

                        {/* Error Message */}
                        {error && (
                            <div className="mb-4 p-3 bg-red-500/20 border border-red-500/50 rounded-lg text-red-200 text-sm">
                                {error}
                            </div>
                        )}

                        {/* Submit Button */}
                        <button
                            type="submit"
                            disabled={loading}
                            className="w-full flex items-center justify-center gap-2 px-6 py-3 bg-gradient-to-r from-emerald-600 to-green-600 text-white font-semibold rounded-lg hover:from-emerald-500 hover:to-green-500 transition shadow-lg shadow-emerald-500/20 disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            {loading ? 'Creating Account...' : 'Create Account'}
                            {!loading && <ArrowRight className="h-5 w-5" />}
                        </button>
                    </form>

                    {/* Info */}
                    <div className="mt-6 text-center text-sm text-emerald-100/50">
                        <p>By creating an account, you agree to our terms of service</p>
                    </div>
                </div>

                {/* Back to Login */}
                <div className="mt-6 text-center">
                    <Link href="/login" className="text-emerald-300/70 hover:text-emerald-300 text-sm">
                        ← Back to login
                    </Link>
                </div>
            </div>
        </div>
    );
}
