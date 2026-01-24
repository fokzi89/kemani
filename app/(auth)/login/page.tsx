'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { ArrowRight, Mail } from 'lucide-react';

export default function LoginPage() {
    const [identifier, setIdentifier] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const router = useRouter();

    const handleSendOTP = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        try {
            const response = await fetch('/api/auth/send-otp', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    identifier,
                    type: 'email',
                }),
            });

            const data = await response.json();

            if (!response.ok) {
                setError(data.error || 'Failed to send OTP');
                setLoading(false);
                return;
            }

            // Navigate to OTP verification page
            router.push(`/verify-otp?identifier=${encodeURIComponent(data.identifier)}&type=email`);
        } catch (err) {
            setError('Something went wrong. Please try again.');
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-gradient-to-b from-emerald-950 via-green-900 to-gray-900 flex items-center justify-center px-4">
            <div className="w-full max-w-md">
                {/* Logo */}
                <div className="text-center mb-8">
                    <Link href="/" className="inline-flex items-center">
                        <span className="text-3xl font-bold text-emerald-400">Kemani</span>
                        <span className="ml-2 text-lg text-emerald-300/70">POS</span>
                    </Link>
                    <p className="mt-2 text-emerald-100/70">Sign in with email</p>
                </div>

                {/* Login Card */}
                <div className="bg-white/5 backdrop-blur-md rounded-2xl p-8 border border-emerald-500/20">
                    <form onSubmit={handleSendOTP}>
                        {/* Input Field */}
                        <div className="mb-6">
                            <label htmlFor="identifier" className="block text-sm font-medium text-emerald-100 mb-2">
                                Email Address
                            </label>
                            <div className="relative">
                                <Mail className="absolute left-3 top-3.5 h-5 w-5 text-emerald-300/50" />
                                <input
                                    id="identifier"
                                    type="email"
                                    value={identifier}
                                    onChange={(e) => setIdentifier(e.target.value)}
                                    placeholder="you@example.com"
                                    className="w-full pl-10 pr-4 py-3 bg-white/10 border border-emerald-500/30 rounded-lg text-white placeholder-emerald-300/40 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
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
                            {loading ? 'Sending...' : 'Send Verification Code'}
                            {!loading && <ArrowRight className="h-5 w-5" />}
                        </button>
                    </form>

                    {/* Divider */}
                    <div className="my-6 flex items-center">
                        <div className="flex-1 border-t border-emerald-500/20"></div>
                        <span className="px-4 text-sm text-emerald-100/50">or</span>
                        <div className="flex-1 border-t border-emerald-500/20"></div>
                    </div>

                    {/* Register Link */}
                    <div className="text-center">
                        <p className="text-emerald-100/70 text-sm">
                            New to Kemani?{' '}
                            <span className="text-emerald-300">Just enter your email above to setup an account.</span>
                        </p>
                    </div>
                </div>

                {/* Back to Home */}
                <div className="mt-6 text-center">
                    <Link href="/" className="text-emerald-300/70 hover:text-emerald-300 text-sm">
                        ← Back to home
                    </Link>
                </div>
            </div>
        </div>
    );
}
