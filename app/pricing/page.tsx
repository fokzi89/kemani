import Link from "next/link";
import { Check, ArrowRight, Zap, TrendingUp, Crown, Sparkles, Phone } from "lucide-react";

export default function PricingPage() {
  const pricingPlans = [
    {
      name: "Free",
      icon: Zap,
      description: "Get started with basic POS features",
      price: "₦0",
      period: "/month",
      annual: "Forever free",
      features: [
        "1 branch location",
        "1 staff user",
        "Up to 100 products",
        "500 transactions/month",
        "Cloud-only POS (requires internet)",
        "Basic inventory management",
        "Sales receipts with branding",
        "CSV product import",
        "Email support",
        "0% commission (no marketplace)"
      ],
      limitations: [
        "No offline mode",
        "No online marketplace",
        "No AI features",
        "No WhatsApp integration",
        "No delivery management",
        "No e-commerce sync"
      ],
      cta: "Start Free Forever",
      href: "/auth/signup?plan=free",
      popular: false,
      color: "gray"
    },
    {
      name: "Basic",
      icon: TrendingUp,
      description: "Perfect for small shops expanding operations",
      price: "₦5,000",
      period: "/month",
      annual: "₦55,000/year (Save ₦5,000)",
      features: [
        "Up to 3 branch locations",
        "Up to 10 staff users",
        "Unlimited products",
        "Unlimited transactions",
        "Offline-first POS (works without internet)",
        "AI chat agent for customer inquiries",
        "WhatsApp Business API integration",
        "Inter-branch inventory transfers",
        "Local & inter-city delivery management",
        "Priority email support",
        "0% commission (no e-commerce)"
      ],
      limitations: [
        "No online marketplace",
        "No e-commerce platform sync",
        "No advanced analytics",
        "No API access"
      ],
      cta: "Start 30-Day Free Trial",
      href: "/auth/signup?plan=basic",
      popular: false,
      color: "emerald"
    },
    {
      name: "Pro",
      icon: Crown,
      description: "For growing businesses selling online",
      price: "₦15,000",
      period: "/month",
      annual: "₦165,000/year (Save ₦15,000)",
      features: [
        "Up to 10 branch locations",
        "Up to 50 staff users",
        "Unlimited products",
        "Unlimited transactions",
        "Everything in Basic, plus:",
        "Online marketplace storefront",
        "AI-powered e-commerce chat",
        "WooCommerce & Shopify sync",
        "Advanced analytics & insights",
        "Bulk import/export",
        "API access for integrations",
        "Priority support (phone & email)",
        "1.5% commission on marketplace sales (capped at ₦500/order)"
      ],
      limitations: [],
      cta: "Start 30-Day Free Trial",
      href: "/auth/signup?plan=pro",
      popular: true,
      color: "cyan"
    },
    {
      name: "Enterprise",
      icon: Sparkles,
      description: "Complete platform for established businesses",
      price: "₦50,000",
      period: "/month",
      annual: "₦550,000/year (Save ₦50,000)",
      features: [
        "Unlimited branch locations",
        "Unlimited staff users",
        "Unlimited products",
        "Unlimited transactions",
        "Everything in Pro, plus:",
        "Multi-currency support",
        "Dedicated account manager",
        "24/7 phone support",
        "Custom reporting & analytics",
        "SLA guarantees (99.9% uptime)",
        "Priority feature requests",
        "Data export capabilities",
        "1% commission on marketplace sales (capped at ₦500/order)"
      ],
      limitations: [],
      cta: "Start 30-Day Free Trial",
      href: "/auth/signup?plan=enterprise",
      popular: false,
      color: "teal"
    },
    {
      name: "Enterprise Custom",
      icon: Phone,
      description: "Tailored solutions for unique business needs",
      price: "Custom",
      period: "pricing",
      annual: "Contact sales for quote",
      features: [
        "Everything in Enterprise, plus:",
        "Custom domain & white-label branding",
        "Custom integrations via dedicated API",
        "On-premise deployment option",
        "Custom feature development",
        "24/7 dedicated support team",
        "Custom SLA agreements",
        "Direct engineering support",
        "Advanced security & compliance",
        "Custom data retention policies",
        "Negotiable commission (0.5% default, capped at ₦500/order)"
      ],
      limitations: [],
      cta: "Contact Sales",
      href: "/contact?plan=enterprise_custom",
      popular: false,
      color: "indigo"
    }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-b from-cyan-50 to-white">
      {/* Navigation */}
      <nav className="border-b border-cyan-100 bg-white/80 backdrop-blur-sm fixed top-0 w-full z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <Link href="/" className="flex items-center">
              <span className="text-2xl font-bold text-cyan-600">Kemani</span>
              <span className="ml-2 text-sm text-gray-500">POS</span>
            </Link>
            <div className="flex items-center space-x-8">
              <Link href="/#features" className="text-gray-600 hover:text-cyan-600 transition">
                Features
              </Link>
              <Link href="/pricing" className="text-cyan-600 font-medium">
                Pricing
              </Link>
              <Link
                href="/auth/signin"
                className="px-4 py-2 text-cyan-600 border border-cyan-600 rounded-lg hover:bg-cyan-50 transition"
              >
                Sign In
              </Link>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero */}
      <section className="pt-32 pb-12 px-4 sm:px-6 lg:px-8">
        <div className="max-w-4xl mx-auto text-center">
          <h1 className="text-5xl md:text-6xl font-bold text-gray-900 mb-6">
            Simple, Transparent Pricing
          </h1>
          <p className="text-xl text-gray-600 mb-8">
            Start free, upgrade when you need more. No hidden fees, no surprises.
            All paid plans include a 30-day free trial.
          </p>
          <div className="inline-flex items-center px-4 py-2 bg-emerald-100 text-emerald-800 rounded-full text-sm font-medium">
            <Check className="h-4 w-4 mr-2" />
            Get 1 month free with annual billing
          </div>
        </div>
      </section>

      {/* Pricing Cards */}
      <section className="pb-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          {/* First Row: Free, Basic, Pro */}
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8 mb-8">
            {pricingPlans.slice(0, 3).map((plan, idx) => {
              const Icon = plan.icon;

              return (
                <div
                  key={idx}
                  className={`relative bg-white rounded-2xl shadow-lg border-2 ${
                    plan.popular
                      ? "border-cyan-600 ring-4 ring-cyan-100 scale-105"
                      : "border-gray-200"
                  } overflow-hidden transition hover:shadow-xl`}
                >
                  {plan.popular && (
                    <div className="absolute top-0 right-0 bg-cyan-600 text-white px-4 py-1 text-sm font-semibold rounded-bl-lg">
                      Most Popular
                    </div>
                  )}

                  <div className="p-8">
                    {/* Header */}
                    <div className="flex items-center mb-4">
                      <div className={`w-12 h-12 bg-${plan.color}-100 rounded-lg flex items-center justify-center mr-3`}>
                        <Icon className={`h-6 w-6 text-${plan.color}-600`} />
                      </div>
                      <div>
                        <h3 className="text-2xl font-bold text-gray-900">{plan.name}</h3>
                      </div>
                    </div>
                    <p className="text-gray-600 mb-6">{plan.description}</p>

                    {/* Pricing */}
                    <div className="mb-6">
                      <div className="flex items-baseline">
                        <span className="text-4xl font-bold text-gray-900">{plan.price}</span>
                        <span className="text-gray-600 ml-2">{plan.period}</span>
                      </div>
                      <p className={`text-sm mt-2 font-medium ${plan.name === "Free" ? "text-emerald-600" : "text-cyan-600"}`}>
                        {plan.annual}
                      </p>
                    </div>

                    {/* CTA */}
                    <Link
                      href={plan.href}
                      className={`block w-full py-3 px-6 text-center font-semibold rounded-lg transition ${
                        plan.popular
                          ? "bg-cyan-600 text-white hover:bg-cyan-700 shadow-md"
                          : plan.name === "Free"
                          ? "bg-emerald-600 text-white hover:bg-emerald-700 shadow-md"
                          : "bg-cyan-50 text-cyan-600 hover:bg-cyan-100"
                      }`}
                    >
                      {plan.cta}
                    </Link>

                    {/* Features */}
                    <div className="mt-8 space-y-4">
                      <div className="font-semibold text-gray-900 mb-3">What's included:</div>
                      <ul className="space-y-3">
                        {plan.features.map((feature, featureIdx) => (
                          <li key={featureIdx} className="flex items-start">
                            <Check className="h-5 w-5 text-emerald-500 mr-3 flex-shrink-0 mt-0.5" />
                            <span className="text-gray-700 text-sm">{feature}</span>
                          </li>
                        ))}
                      </ul>

                      {plan.limitations.length > 0 && (
                        <div className="mt-6 pt-6 border-t border-gray-200">
                          <div className="text-sm text-gray-500 space-y-2">
                            <div className="font-medium text-gray-700 mb-2">Not included:</div>
                            {plan.limitations.map((limitation, limIdx) => (
                              <div key={limIdx}>• {limitation}</div>
                            ))}
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Second Row: Enterprise and Enterprise Custom */}
          <div className="grid md:grid-cols-2 gap-8 max-w-5xl mx-auto">
            {pricingPlans.slice(3, 5).map((plan, idx) => {
              const Icon = plan.icon;
              const isCustom = plan.name === "Enterprise Custom";

              return (
                <div
                  key={idx}
                  className={`relative bg-white rounded-2xl shadow-lg border-2 ${
                    isCustom
                      ? "border-indigo-300"
                      : "border-gray-200"
                  } overflow-hidden transition hover:shadow-xl`}
                >
                  <div className="p-8">
                    {/* Header */}
                    <div className="flex items-center mb-4">
                      <div className={`w-12 h-12 bg-${plan.color}-100 rounded-lg flex items-center justify-center mr-3`}>
                        <Icon className={`h-6 w-6 text-${plan.color}-600`} />
                      </div>
                      <div>
                        <h3 className="text-2xl font-bold text-gray-900">{plan.name}</h3>
                      </div>
                    </div>
                    <p className="text-gray-600 mb-6">{plan.description}</p>

                    {/* Pricing */}
                    <div className="mb-6">
                      <div className="flex items-baseline">
                        <span className="text-4xl font-bold text-gray-900">{plan.price}</span>
                        <span className="text-gray-600 ml-2">{plan.period}</span>
                      </div>
                      <p className={`text-sm mt-2 font-medium ${plan.name === "Free" ? "text-emerald-600" : "text-cyan-600"}`}>
                        {plan.annual}
                      </p>
                    </div>

                    {/* CTA */}
                    <Link
                      href={plan.href}
                      className={`block w-full py-3 px-6 text-center font-semibold rounded-lg transition ${
                        isCustom
                          ? "bg-indigo-600 text-white hover:bg-indigo-700 shadow-md"
                          : "bg-teal-600 text-white hover:bg-teal-700 shadow-md"
                      }`}
                    >
                      {plan.cta}
                    </Link>

                    {/* Features */}
                    <div className="mt-8 space-y-4">
                      <div className="font-semibold text-gray-900 mb-3">What's included:</div>
                      <ul className="space-y-3">
                        {plan.features.map((feature, featureIdx) => (
                          <li key={featureIdx} className="flex items-start">
                            <Check className="h-5 w-5 text-emerald-500 mr-3 flex-shrink-0 mt-0.5" />
                            <span className="text-gray-700 text-sm">{feature}</span>
                          </li>
                        ))}
                      </ul>

                      {plan.limitations.length > 0 && (
                        <div className="mt-6 pt-6 border-t border-gray-200">
                          <div className="text-sm text-gray-500 space-y-2">
                            <div className="font-medium text-gray-700 mb-2">Not included:</div>
                            {plan.limitations.map((limitation, limIdx) => (
                              <div key={limIdx}>• {limitation}</div>
                            ))}
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* Feature Comparison Table */}
      <section className="py-20 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
              Compare All Features
            </h2>
            <p className="text-lg text-gray-600">
              See exactly what's included in each plan
            </p>
          </div>

          <div className="bg-white rounded-2xl shadow-lg overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-cyan-50">
                  <tr>
                    <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">
                      Feature
                    </th>
                    <th className="px-6 py-4 text-center text-sm font-semibold text-gray-900">
                      Free
                    </th>
                    <th className="px-6 py-4 text-center text-sm font-semibold text-gray-900">
                      Basic
                    </th>
                    <th className="px-6 py-4 text-center text-sm font-semibold text-gray-900">
                      Pro
                    </th>
                    <th className="px-6 py-4 text-center text-sm font-semibold text-gray-900">
                      Enterprise
                    </th>
                    <th className="px-6 py-4 text-center text-sm font-semibold text-gray-900">
                      Custom
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {[
                    { feature: "Branch Locations", free: "1", basic: "3", pro: "10", enterprise: "Unlimited", custom: "Unlimited" },
                    { feature: "Staff Users", free: "1", basic: "10", pro: "50", enterprise: "Unlimited", custom: "Unlimited" },
                    { feature: "Products", free: "100", basic: "Unlimited", pro: "Unlimited", enterprise: "Unlimited", custom: "Unlimited" },
                    { feature: "Monthly Transactions", free: "500", basic: "Unlimited", pro: "Unlimited", enterprise: "Unlimited", custom: "Unlimited" },
                    { feature: "Offline-First POS", free: false, basic: true, pro: true, enterprise: true, custom: true },
                    { feature: "Inventory Management", free: true, basic: true, pro: true, enterprise: true, custom: true },
                    { feature: "CSV Import", free: true, basic: true, pro: true, enterprise: true, custom: true },
                    { feature: "AI Chat Agent", free: false, basic: true, pro: true, enterprise: true, custom: true },
                    { feature: "WhatsApp Integration", free: false, basic: true, pro: true, enterprise: true, custom: true },
                    { feature: "Delivery Management", free: false, basic: true, pro: true, enterprise: true, custom: true },
                    { feature: "Inter-Branch Transfers", free: false, basic: true, pro: true, enterprise: true, custom: true },
                    { feature: "Online Marketplace", free: false, basic: false, pro: true, enterprise: true, custom: true },
                    { feature: "E-Commerce Chat", free: false, basic: false, pro: true, enterprise: true, custom: true },
                    { feature: "WooCommerce Sync", free: false, basic: false, pro: true, enterprise: true, custom: true },
                    { feature: "Shopify Sync", free: false, basic: false, pro: true, enterprise: true, custom: true },
                    { feature: "Advanced Analytics", free: false, basic: false, pro: true, enterprise: true, custom: true },
                    { feature: "API Access", free: false, basic: false, pro: true, enterprise: true, custom: true },
                    { feature: "Multi-Currency", free: false, basic: false, pro: false, enterprise: true, custom: true },
                    { feature: "Custom Domain", free: false, basic: false, pro: false, enterprise: false, custom: true },
                    { feature: "White Label", free: false, basic: false, pro: false, enterprise: false, custom: true },
                    { feature: "Marketplace Commission", free: "0%", basic: "0%", pro: "1.5%", enterprise: "1%", custom: "0.5%" },
                    { feature: "Commission Cap", free: "N/A", basic: "N/A", pro: "₦500/order", enterprise: "₦500/order", custom: "₦500/order" },
                    { feature: "Support", free: "Email", basic: "Priority Email", pro: "Phone & Email", enterprise: "24/7 Phone", custom: "24/7 Dedicated" },
                  ].map((row, idx) => (
                    <tr key={idx} className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-sm text-gray-900 font-medium">
                        {row.feature}
                      </td>
                      {['free', 'basic', 'pro', 'enterprise', 'custom'].map((tier) => (
                        <td key={tier} className="px-6 py-4 text-center text-sm">
                          {typeof row[tier as keyof typeof row] === "boolean" ? (
                            row[tier as keyof typeof row] ? (
                              <Check className="h-5 w-5 text-emerald-500 mx-auto" />
                            ) : (
                              <span className="text-gray-400">—</span>
                            )
                          ) : (
                            <span className="text-gray-700">{row[tier as keyof typeof row]}</span>
                          )}
                        </td>
                      ))}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="py-20">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
              Frequently Asked Questions
            </h2>
          </div>

          <div className="space-y-6">
            {[
              {
                question: "What's the difference between cloud-only (Free) and offline-first (paid plans)?",
                answer: "The Free plan requires internet connection to process sales and access your data. Paid plans (Basic and above) work completely offline, storing data locally on your device and syncing automatically when internet becomes available. This means you never lose a sale due to internet issues."
              },
              {
                question: "Can I change plans later?",
                answer: "Absolutely! You can upgrade or downgrade your plan at any time. Changes take effect immediately, and we'll prorate your billing accordingly. Your data stays intact when switching plans."
              },
              {
                question: "What payment methods do you accept?",
                answer: "We accept all major payment methods through Paystack and Flutterwave including card payments, bank transfers, and mobile money. All payments are in Nigerian Naira (₦)."
              },
              {
                question: "What happens when I exceed my plan limits?",
                answer: "We'll notify you when you're approaching your limits. You can upgrade to a higher plan at any time. We'll never interrupt your business operations — you'll always have access to your existing data."
              },
              {
                question: "Is the 30-day free trial really free?",
                answer: "Yes! All paid plans include a genuine 30-day free trial with full access to all features in your chosen plan. No credit card required to start. The Free plan is always free with no trial needed."
              },
              {
                question: "How does marketplace commission work?",
                answer: "Commission only applies when customers order through your online storefront (Pro, Enterprise, and Custom plans only). In-store POS sales have zero commission. All commissions are capped at ₦500 per order, regardless of order value."
              },
              {
                question: "What's included in the commission cap?",
                answer: "The ₦500 commission cap means you'll never pay more than ₦500 per marketplace order, even on large orders. For example, a ₦100,000 order at 1.5% would normally be ₦1,500 commission, but you only pay ₦500."
              },
              {
                question: "What does 'unlimited products and transactions' mean?",
                answer: "From the Basic plan upwards, there are no limits on the number of products you can add to your inventory or the number of transactions you can process monthly. This means your business can scale without worrying about hitting usage caps."
              },
              {
                question: "Can I use Kemani without internet on the Free plan?",
                answer: "No, the Free plan requires internet connection for all operations. If you need offline functionality, upgrade to Basic or higher plans which include full offline-first POS capabilities with automatic sync."
              },
              {
                question: "Do you offer custom enterprise solutions?",
                answer: "Yes! Our Enterprise Custom plan offers white-label branding, custom domains, dedicated infrastructure, custom development, and negotiable pricing. Contact our sales team to discuss your specific requirements."
              }
            ].map((faq, idx) => (
              <div key={idx} className="bg-white rounded-lg shadow-sm p-6 border border-gray-200">
                <h3 className="text-lg font-semibold text-gray-900 mb-3">
                  {faq.question}
                </h3>
                <p className="text-gray-600">
                  {faq.answer}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-20 bg-gradient-to-r from-cyan-600 to-teal-600 text-white">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Ready to Transform Your Business?
          </h2>
          <p className="text-xl text-cyan-100 mb-8">
            Start free today, no credit card required. Upgrade when you're ready for more features.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="/auth/signup?plan=free"
              className="inline-flex items-center px-8 py-4 bg-white text-cyan-600 text-lg font-semibold rounded-lg hover:bg-gray-100 transition shadow-lg hover:shadow-xl"
            >
              Start Free Forever
              <ArrowRight className="ml-2 h-5 w-5" />
            </Link>
            <Link
              href="/contact"
              className="inline-flex items-center px-8 py-4 bg-transparent text-white text-lg font-semibold rounded-lg border-2 border-white hover:bg-white/10 transition"
            >
              Talk to Sales
            </Link>
          </div>
          <p className="mt-6 text-sm text-cyan-200">
            Questions? <Link href="/contact" className="underline hover:text-white">Contact our team</Link>
          </p>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-gray-300 py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid md:grid-cols-4 gap-8">
            <div>
              <Link href="/" className="flex items-center mb-4">
                <span className="text-2xl font-bold text-white">Kemani</span>
                <span className="ml-2 text-sm text-gray-400">POS</span>
              </Link>
              <p className="text-sm text-gray-400">
                Offline-first POS platform built for Nigerian businesses.
              </p>
            </div>

            <div>
              <h3 className="text-white font-semibold mb-4">Product</h3>
              <ul className="space-y-2 text-sm">
                <li><Link href="/#features" className="hover:text-white transition">Features</Link></li>
                <li><Link href="/pricing" className="hover:text-white transition">Pricing</Link></li>
                <li><Link href="/#demo" className="hover:text-white transition">Demo</Link></li>
              </ul>
            </div>

            <div>
              <h3 className="text-white font-semibold mb-4">Support</h3>
              <ul className="space-y-2 text-sm">
                <li><Link href="/docs" className="hover:text-white transition">Documentation</Link></li>
                <li><Link href="/support" className="hover:text-white transition">Help Center</Link></li>
                <li><Link href="/contact" className="hover:text-white transition">Contact Us</Link></li>
              </ul>
            </div>

            <div>
              <h3 className="text-white font-semibold mb-4">Legal</h3>
              <ul className="space-y-2 text-sm">
                <li><Link href="/privacy" className="hover:text-white transition">Privacy Policy</Link></li>
                <li><Link href="/terms" className="hover:text-white transition">Terms of Service</Link></li>
              </ul>
            </div>
          </div>

          <div className="border-t border-gray-800 mt-8 pt-8 text-center text-sm text-gray-400">
            <p>&copy; {new Date().getFullYear()} Kemani POS. All rights reserved. Built with ❤️ for Nigerian businesses.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
