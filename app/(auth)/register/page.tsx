'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { ArrowRight, Building2, User, MapPin } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';

export default function RegisterPage() {
    const [formData, setFormData] = useState({
        businessName: '',
        fullName: '',
        address: '',
        subscriptionPlan: 'free',
    });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [plans, setPlans] = useState<any[]>([]);

    const router = useRouter();
    const searchParams = useSearchParams();
    const userId = searchParams.get('userId');
    const identifier = searchParams.get('identifier');
    // type is assumed to be 'email' now regarding the previous simplified flow

    const supabase = createClient();

    useEffect(() => {
        // Fetch subscription plans
        async function fetchPlans() {
            const { data } = await supabase
                .from('subscriptions')
                .select('*')
                .order('monthly_fee');

            if (data) {
                setPlans(data);
            }
        }

        fetchPlans();
    }, [supabase]);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        try {
            // Get current user session to ensure security
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
                    address: formData.address,
                    subscriptionPlan: formData.subscriptionPlan,
                    userId: user.id
                }),
            });

            const result = await response.json();

            if (!response.ok) {
                throw new Error(result.error || 'Failed to complete registration');
            }

            // Redirect to dashboard
            router.push('/dashboard');
        } catch (err: any) {
            setError(err.message || 'Failed to complete registration');
            setLoading(false);
        }
    };

    const [isValidSession, setIsValidSession] = useState(false);

    useEffect(() => {
        const checkSession = async () => {
            const { data: { session } } = await supabase.auth.getSession();
            if (!session) {
                router.push('/login');
            } else {
                setIsValidSession(true);
            }
        };
        checkSession();
    }, [supabase, router]);

    if (!isValidSession) {
        return null; // or a loading spinner
    }

    return (
        <div className="min-h-screen bg-gradient-to-b from-emerald-950 via-green-900 to-gray-900 flex items-center justify-center px-4 py-12">
            <div className="w-full max-w-2xl">
                {/* Logo */}
                <div className="text-center mb-8">
                    <Link href="/" className="inline-flex items-center">
                        <span className="text-3xl font-bold text-emerald-400">Kemani</span>
                        <span className="ml-2 text-lg text-emerald-300/70">POS</span>
                    </Link>
                    <p className="mt-2 text-emerald-100/70">Complete your registration</p>
                </div>

                {/* Registration Card */}
                <div className="bg-white/5 backdrop-blur-md rounded-2xl p-8 border border-emerald-500/20">
                    <form onSubmit={handleSubmit}>
                        <div className="grid md:grid-cols-2 gap-6 mb-6">
                            {/* Business Name */}
                            <div>
                                <label htmlFor="businessName" className="block text-sm font-medium text-emerald-100 mb-2">
                                    <Building2 className="inline h-4 w-4 mr-1" />
                                    Business Name
                                </label>
                                <input
                                    id="businessName"
                                    type="text"
                                    value={formData.businessName}
                                    onChange={(e) => setFormData({ ...formData, businessName: e.target.value })}
                                    placeholder="Your Business Ltd"
                                    className="w-full px-4 py-3 bg-white/10 border border-emerald-500/30 rounded-lg text-white placeholder-emerald-300/40 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
                                    required
                                />
                            </div>

                            {/* Full Name */}
                            <div>
                                <label htmlFor="fullName" className="block text-sm font-medium text-emerald-100 mb-2">
                                    <User className="inline h-4 w-4 mr-1" />
                                    Full Name
                                </label>
                                <input
                                    id="fullName"
                                    type="text"
                                    value={formData.fullName}
                                    onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
                                    placeholder="John Doe"
                                    className="w-full px-4 py-3 bg-white/10 border border-emerald-500/30 rounded-lg text-white placeholder-emerald-300/40 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
                                    required
                                />
                            </div>
                        </div>

                        {/* Address */}
                        <div className="mb-6">
                            <label htmlFor="address" className="block text-sm font-medium text-emerald-100 mb-2">
                                <MapPin className="inline h-4 w-4 mr-1" />
                                Business Address
                            </label>
                            <input
                                id="address"
                                type="text"
                                value={formData.address}
                                onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                                placeholder="123 Main Street, Lagos"
                                className="w-full px-4 py-3 bg-white/10 border border-emerald-500/30 rounded-lg text-white placeholder-emerald-300/40 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
                                required
                            />
                        </div>

                        {/* Subscription Plan */}
                        <div className="mb-6">
                            <label className="block text-sm font-medium text-emerald-100 mb-3">
                                Choose Your Plan
                            </label>
                            <div className="grid md:grid-cols-2 gap-4">
                                {plans.map((plan) => (
                                    <label
                                        key={plan.id}
                                        className={`relative flex flex-col p-4 rounded-lg border-2 cursor-pointer transition ${formData.subscriptionPlan === plan.id
                                            ? 'border-emerald-500 bg-emerald-500/10'
                                            : 'border-emerald-500/20 bg-white/5 hover:border-emerald-500/40'
                                            }`}
                                    >
                                        <input
                                            type="radio"
                                            name="plan"
                                            value={plan.id}
                                            checked={formData.subscriptionPlan === plan.id}
                                            onChange={(e) => setFormData({ ...formData, subscriptionPlan: e.target.value })}
                                            className="sr-only"
                                        />
                                        <div className="flex items-center justify-between mb-2">
                                            <span className="text-lg font-semibold text-white">{plan.plan_tier}</span>
                                            {plan.monthly_fee === 0 && (
                                                <span className="px-2 py-1 bg-emerald-500 text-white text-xs rounded-full">
                                                    Free
                                                </span>
                                            )}
                                        </div>
                                        <div className="text-2xl font-bold text-emerald-400 mb-2">
                                            ₦{plan.monthly_fee.toLocaleString()}
                                            <span className="text-sm text-emerald-100/50">/month</span>
                                        </div>
                                        <ul className="text-sm text-emerald-100/70 space-y-1">
                                            <li>• {plan.max_users} users</li>
                                            <li>• {plan.max_products} products</li>
                                            <li>• {plan.max_branches} branch(es)</li>
                                        </ul>
                                    </label>
                                ))}
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
                            {loading ? 'Creating Account...' : 'Complete Registration'}
                            {!loading && <ArrowRight className="h-5 w-5" />}
                        </button>
                    </form>
                </div>
            </div>
        </div>
    );
}
