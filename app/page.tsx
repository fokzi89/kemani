import Link from "next/link";
import { ArrowRight, Zap, Smartphone, ShoppingBag, TrendingUp, MessageSquare, Shield } from "lucide-react";

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-cyan-50 to-white">
      {/* Navigation */}
      <nav className="border-b border-cyan-100 bg-white/80 backdrop-blur-sm fixed top-0 w-full z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center">
              <span className="text-2xl font-bold text-cyan-600">Kemani</span>
              <span className="ml-2 text-sm text-gray-500">POS</span>
            </div>
            <div className="hidden md:flex items-center space-x-8">
              <Link href="#features" className="text-gray-600 hover:text-cyan-600 transition">
                Features
              </Link>
              <Link href="#benefits" className="text-gray-600 hover:text-cyan-600 transition">
                Benefits
              </Link>
              <Link href="/pricing" className="text-gray-600 hover:text-cyan-600 transition">
                Pricing
              </Link>
              <Link
                href="/auth/signin"
                className="px-4 py-2 text-cyan-600 border border-cyan-600 rounded-lg hover:bg-cyan-50 transition"
              >
                Sign In
              </Link>
              <Link
                href="/auth/signup"
                className="px-4 py-2 bg-cyan-600 text-white rounded-lg hover:bg-cyan-700 transition"
              >
                Start Free
              </Link>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="pt-32 pb-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="text-center max-w-3xl mx-auto">
            <h1 className="text-5xl md:text-6xl font-bold text-gray-900 mb-6 leading-tight">
              Your Business Never Stops.
              <span className="text-cyan-600"> Neither Should Your POS.</span>
            </h1>
            <p className="text-xl text-gray-600 mb-8 leading-relaxed">
              Kemani is Nigeria's first offline-first POS platform built for independent businesses.
              Process sales, manage inventory, and serve customers — even when the internet doesn't cooperate.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link
                href="/auth/signup?plan=free"
                className="inline-flex items-center px-8 py-4 bg-cyan-600 text-white text-lg font-semibold rounded-lg hover:bg-cyan-700 transition shadow-lg hover:shadow-xl"
              >
                Start Free Forever
                <ArrowRight className="ml-2 h-5 w-5" />
              </Link>
              <Link
                href="#demo"
                className="inline-flex items-center px-8 py-4 bg-white text-cyan-600 text-lg font-semibold rounded-lg border-2 border-cyan-600 hover:bg-cyan-50 transition"
              >
                Watch Demo
              </Link>
            </div>
            <p className="mt-4 text-sm text-gray-500">
              Forever free plan • Upgrade anytime • No credit card required
            </p>
          </div>

          {/* Trust Badges */}
          <div className="mt-16 grid grid-cols-2 md:grid-cols-4 gap-8 max-w-4xl mx-auto">
            {[
              { label: "Start Free", value: "₦0" },
              { label: "Works Offline", value: "Always On" },
              { label: "Nigeria-First", value: "Built for You" },
              { label: "From ₦5K/month", value: "Affordable" },
            ].map((badge, idx) => (
              <div key={idx} className="text-center">
                <div className="text-3xl font-bold text-cyan-600">{badge.value}</div>
                <div className="text-sm text-gray-600 mt-1">{badge.label}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Problem Statement */}
      <section className="py-20 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="max-w-3xl mx-auto text-center">
            <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-6">
              Tired of Losing Sales When Internet Cuts?
            </h2>
            <p className="text-lg text-gray-600 mb-8">
              Traditional POS systems fail when you need them most. Every minute of downtime costs you money.
              Your customers won't wait, and your competitors won't sleep.
            </p>
            <div className="grid md:grid-cols-3 gap-6 mt-12">
              {[
                { problem: "Internet outages", impact: "Lost sales & frustrated customers" },
                { problem: "Expensive systems", impact: "High setup costs & monthly fees" },
                { problem: "Complex software", impact: "Hours of training & wasted time" },
              ].map((item, idx) => (
                <div key={idx} className="p-6 bg-white rounded-lg shadow-sm">
                  <div className="text-red-500 font-semibold mb-2">{item.problem}</div>
                  <div className="text-gray-600 text-sm">{item.impact}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
              Everything You Need to Run Your Business
            </h2>
            <p className="text-lg text-gray-600 max-w-2xl mx-auto">
              From in-store sales to online orders, delivery management to analytics — all in one powerful platform.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            {[
              {
                icon: Zap,
                title: "Offline-First POS",
                description: "Process sales, update inventory, and print receipts even when internet is down. Automatic sync when you're back online.",
                color: "indigo"
              },
              {
                icon: ShoppingBag,
                title: "Online Marketplace",
                description: "Reach nearby customers with your digital storefront. They browse, order, and pay while you fulfill — seamlessly.",
                color: "purple"
              },
              {
                icon: Smartphone,
                title: "WhatsApp & AI Chat",
                description: "Take orders via WhatsApp and AI chat agent. Your customers shop the way they prefer — on their phones.",
                color: "blue"
              },
              {
                icon: TrendingUp,
                title: "Smart Analytics",
                description: "See what's selling, when it's selling, and who's buying. Make data-driven decisions to grow your revenue.",
                color: "green"
              },
              {
                icon: MessageSquare,
                title: "Delivery Management",
                description: "Local bike delivery or inter-city shipping — we handle the logistics while you focus on serving customers.",
                color: "orange"
              },
              {
                icon: Shield,
                title: "Multi-Branch Management",
                description: "Manage multiple locations from one dashboard. Track inventory, sales, and staff across all your branches in real-time.",
                color: "red"
              },
            ].map((feature, idx) => {
              const Icon = feature.icon;
              return (
                <div key={idx} className="p-6 bg-white rounded-xl shadow-sm hover:shadow-md transition border border-gray-100">
                  <div className={`w-12 h-12 bg-${feature.color}-100 rounded-lg flex items-center justify-center mb-4`}>
                    <Icon className={`h-6 w-6 text-${feature.color}-600`} />
                  </div>
                  <h3 className="text-xl font-semibold text-gray-900 mb-2">{feature.title}</h3>
                  <p className="text-gray-600">{feature.description}</p>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* Benefits Section */}
      <section id="benefits" className="py-20 bg-gradient-to-br from-cyan-600 to-teal-600 text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold mb-4">
              Built for Nigerian Businesses, By Nigerians
            </h2>
            <p className="text-lg text-cyan-100 max-w-2xl mx-auto">
              We understand your challenges because we've lived them. That's why Kemani works the way Nigerian businesses actually operate.
            </p>
          </div>

          <div className="grid md:grid-cols-2 gap-12 items-center">
            <div className="space-y-6">
              {[
                {
                  title: "Works on Low-End Devices",
                  description: "Runs smoothly on affordable Android phones with 2GB RAM. No expensive hardware required."
                },
                {
                  title: "Phone Number Authentication",
                  description: "Sign in with your phone number and OTP. No complicated passwords to remember."
                },
                {
                  title: "Naira-Native Pricing",
                  description: "Pay in Naira through Paystack or Flutterwave. No hidden forex charges or surprise fees."
                },
                {
                  title: "3G-Optimized Performance",
                  description: "Designed to work fast even on slow internet connections. Because we know Nigerian network reality."
                },
              ].map((benefit, idx) => (
                <div key={idx} className="flex items-start">
                  <div className="flex-shrink-0 w-6 h-6 bg-teal-500 rounded-full flex items-center justify-center mr-4 mt-1">
                    <svg className="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                    </svg>
                  </div>
                  <div>
                    <h3 className="text-xl font-semibold mb-2">{benefit.title}</h3>
                    <p className="text-cyan-100">{benefit.description}</p>
                  </div>
                </div>
              ))}
            </div>

            <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-8 border border-white/20">
              <h3 className="text-2xl font-bold mb-6">Real Results from Real Businesses</h3>
              <div className="space-y-6">
                <blockquote className="border-l-4 border-teal-400 pl-4">
                  <p className="text-cyan-100 mb-2">
                    "We haven't lost a single sale since switching to Kemani. Even during NEPA outages, our POS just works."
                  </p>
                  <footer className="text-sm text-cyan-200">— Pharmacy Owner, Ikeja</footer>
                </blockquote>
                <blockquote className="border-l-4 border-teal-400 pl-4">
                  <p className="text-cyan-100 mb-2">
                    "Our online orders tripled in 2 months. The WhatsApp integration is a game-changer."
                  </p>
                  <footer className="text-sm text-cyan-200">— Supermarket Manager, Lekki</footer>
                </blockquote>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Use Cases */}
      <section className="py-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
              Perfect for Every Type of Business
            </h2>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
            {[
              { type: "Pharmacies", icon: "💊", use: "Manage prescriptions, track expiry dates, serve walk-in customers" },
              { type: "Supermarkets", icon: "🛒", use: "Handle high transaction volumes, bulk imports, multiple cashiers" },
              { type: "Restaurants", icon: "🍽️", use: "Table management, order tracking, delivery coordination" },
              { type: "Mini-Marts", icon: "🏪", use: "Quick sales, inventory alerts, customer loyalty programs" },
            ].map((useCase, idx) => (
              <div key={idx} className="p-6 bg-gradient-to-br from-cyan-50 to-teal-50 rounded-xl text-center border border-cyan-100">
                <div className="text-5xl mb-4">{useCase.icon}</div>
                <h3 className="text-xl font-semibold text-gray-900 mb-2">{useCase.type}</h3>
                <p className="text-gray-600 text-sm">{useCase.use}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 bg-gradient-to-r from-cyan-600 to-teal-600 text-white">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Stop Losing Money to Internet Outages
          </h2>
          <p className="text-xl text-cyan-100 mb-8">
            Join hundreds of Nigerian businesses that never miss a sale. Start free forever — no credit card required.
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
              href="/pricing"
              className="inline-flex items-center px-8 py-4 bg-transparent text-white text-lg font-semibold rounded-lg border-2 border-white hover:bg-white/10 transition"
            >
              View Pricing
            </Link>
          </div>
          <p className="mt-6 text-sm text-cyan-200">
            Setup takes less than 10 minutes • Import your products via CSV • Start selling immediately
          </p>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-gray-300 py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid md:grid-cols-4 gap-8">
            <div>
              <div className="flex items-center mb-4">
                <span className="text-2xl font-bold text-white">Kemani</span>
                <span className="ml-2 text-sm text-gray-400">POS</span>
              </div>
              <p className="text-sm text-gray-400">
                Offline-first POS platform built for Nigerian businesses.
              </p>
            </div>

            <div>
              <h3 className="text-white font-semibold mb-4">Product</h3>
              <ul className="space-y-2 text-sm">
                <li><Link href="#features" className="hover:text-white transition">Features</Link></li>
                <li><Link href="/pricing" className="hover:text-white transition">Pricing</Link></li>
                <li><Link href="#demo" className="hover:text-white transition">Demo</Link></li>
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
