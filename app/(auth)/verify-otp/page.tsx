'use client';

import { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { ArrowRight, RefreshCw } from 'lucide-react';

export default function VerifyOTPPage() {
    const [otp, setOtp] = useState(['', '', '', '', '', '']);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [resending, setResending] = useState(false);

    const router = useRouter();
    const searchParams = useSearchParams();
    const identifier = searchParams.get('identifier');
    const type = searchParams.get('type') as 'phone' | 'email';

    const inputRefs = useRef<(HTMLInputElement | null)[]>([]);

    useEffect(() => {
        // Focus first input on mount
        inputRefs.current[0]?.focus();
    }, []);

    const handleChange = (index: number, value: string) => {
        if (value.length > 1) {
            value = value[0];
        }

        const newOtp = [...otp];
        newOtp[index] = value;
        setOtp(newOtp);

        // Auto-focus next input
        if (value && index < 5) {
            inputRefs.current[index + 1]?.focus();
        }

        // Auto-submit when all filled
        if (newOtp.every(digit => digit) && index === 5) {
            handleVerifyOTP(newOtp.join(''));
        }
    };

    const handleKeyDown = (index: number, e: React.KeyboardEvent) => {
        if (e.key === 'Backspace' && !otp[index] && index > 0) {
            inputRefs.current[index - 1]?.focus();
        }
    };

    const handleVerifyOTP = async (otpCode: string) => {
        setError('');
        setLoading(true);

        try {
            const response = await fetch('/api/auth/verify-otp', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    identifier,
                    otp: otpCode,
                    type,
                }),
            });

            const data = await response.json();

            if (!response.ok) {
                setError(data.error || 'Invalid OTP');
                setLoading(false);
                setOtp(['', '', '', '', '', '']);
                inputRefs.current[0]?.focus();
                return;
            }

            if (data.needsRegistration) {
                // New user, redirect to registration
                // We rely on session now, so we don't need to pass userId strictly, 
                // but passing identifier helps pre-fill or confirm context if needed (though API uses session)
                router.push(`/register?identifier=${encodeURIComponent(identifier!)}`);
            } else {
                // Existing user, redirect to dashboard
                router.push('/dashboard');
            }
        } catch (err) {
            setError('Something went wrong. Please try again.');
            setLoading(false);
            setOtp(['', '', '', '', '', '']);
            inputRefs.current[0]?.focus();
        }
    };

    const handleResendOTP = async () => {
        setResending(true);
        setError('');

        try {
            const response = await fetch('/api/auth/send-otp', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    identifier,
                    type,
                }),
            });

            const data = await response.json();

            if (!response.ok) {
                setError(data.error || 'Failed to resend OTP');
            }
        } catch (err) {
            setError('Failed to resend OTP');
        } finally {
            setResending(false);
        }
    };

    if (!identifier || !type) {
        return (
            <div className="min-h-screen bg-gradient-to-b from-emerald-950 via-green-900 to-gray-900 flex items-center justify-center px-4">
                <div className="text-center">
                    <p className="text-emerald-100 mb-4">Invalid verification link</p>
                    <Link href="/login" className="text-emerald-400 hover:text-emerald-300">
                        Go to login
                    </Link>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-gradient-to-b from-emerald-950 via-green-900 to-gray-900 flex items-center justify-center px-4">
            <div className="w-full max-w-md">
                {/* Logo */}
                <div className="text-center mb-8">
                    <Link href="/" className="inline-flex items-center">
                        <span className="text-3xl font-bold text-emerald-400">Kemani</span>
                        <span className="ml-2 text-lg text-emerald-300/70">POS</span>
                    </Link>
                    <p className="mt-2 text-emerald-100/70">Enter verification code</p>
                    <p className="mt-1 text-sm text-emerald-300/50">
                        Sent to {type === 'phone' ? 'your phone' : identifier}
                    </p>
                </div>

                {/* OTP Card */}
                <div className="bg-white/5 backdrop-blur-md rounded-2xl p-8 border border-emerald-500/20">
                    {/* OTP Input */}
                    <div className="flex gap-2 justify-center mb-6">
                        {otp.map((digit, index) => (
                            <input
                                key={index}
                                ref={(el: HTMLInputElement | null) => { inputRefs.current[index] = el; }}
                                type="text"
                                inputMode="numeric"
                                maxLength={1}
                                value={digit}
                                onChange={(e) => handleChange(index, e.target.value)}
                                onKeyDown={(e) => handleKeyDown(index, e)}
                                className="w-12 h-14 text-center text-2xl font-bold bg-white/10 border border-emerald-500/30 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
                            />
                        ))}
                    </div>

                    {/* Error Message */}
                    {error && (
                        <div className="mb-4 p-3 bg-red-500/20 border border-red-500/50 rounded-lg text-red-200 text-sm text-center">
                            {error}
                        </div>
                    )}

                    {/* Verify Button */}
                    <button
                        onClick={() => handleVerifyOTP(otp.join(''))}
                        disabled={loading || otp.some(digit => !digit)}
                        className="w-full flex items-center justify-center gap-2 px-6 py-3 bg-gradient-to-r from-emerald-600 to-green-600 text-white font-semibold rounded-lg hover:from-emerald-500 hover:to-green-500 transition shadow-lg shadow-emerald-500/20 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                        {loading ? 'Verifying...' : 'Verify Code'}
                        {!loading && <ArrowRight className="h-5 w-5" />}
                    </button>

                    {/* Resend OTP */}
                    <div className="mt-6 text-center">
                        <button
                            onClick={handleResendOTP}
                            disabled={resending}
                            className="text-emerald-400 hover:text-emerald-300 text-sm font-medium inline-flex items-center gap-2 disabled:opacity-50"
                        >
                            <RefreshCw className={`h-4 w-4 ${resending ? 'animate-spin' : ''}`} />
                            {resending ? 'Sending...' : 'Resend Code'}
                        </button>
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
