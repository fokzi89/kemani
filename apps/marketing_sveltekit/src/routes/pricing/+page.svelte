<script lang="ts">
  import Check from "lucide-svelte/icons/check";
  import X from "lucide-svelte/icons/x";
  import ArrowRight from "lucide-svelte/icons/arrow-right";
  import Zap from "lucide-svelte/icons/zap";
  import TrendingUp from "lucide-svelte/icons/trending-up";
  import Crown from "lucide-svelte/icons/crown";
  import Sparkles from "lucide-svelte/icons/sparkles";
  import Phone from "lucide-svelte/icons/phone";
  import ThemeToggle from "$lib/components/ThemeToggle.svelte";
  import { PUBLIC_POS_WEB_URL } from "$env/static/public";

  const pricingPlans = [
    {
      name: "Starter",
      icon: Zap,
      description: "Side hustles & micro-vendors",
      price: "₦0",
      period: "/month",
      annual: "Forever free",
      features: [
        "1 user (Owner only)",
        "Up to 100 products",
        "Simple Storefront (kemani.store/myshop)",
        "Standard Checkout",
        "Owner-only chat support",
        "Basic sales reports",
        "Receipt printing",
        "₦50 Ecommerce transaction fee",
        "In-chat Purchase",
      ],
      limitations: [
        "No staff accounts",
        "No custom domain",
        "No WhatsApp notifications",
        "AI Chat (Available as Add-on)",
      ],
      cta: "Start Free",
      href: `${PUBLIC_POS_WEB_URL}/register?plan=free`,
      popular: false,
      color: "gray",
    },
    {
      name: "Growth",
      icon: TrendingUp,
      description: "Small businesses with staff",
      price: "₦7,500",
      period: "/month",
      annual: "₦75,000/year (save ₦15K)",
      features: [
        "3 Staff Accounts (Manager, Cashier, Rider)",
        "Unlimited products",
        "Product Variants (Sizes, Colors)",
        "Free Subdomain (storename.kemani.com)",
        "5 Image Gallery per product",
        "Priority Support (Email/Chat)",
        "Rich Analytics (1 Year History)",
        "WhatsApp Order Notifications",
        "₦50 Ecommerce transaction fee",
        "In-chat Purchase",
      ],
      limitations: [
        "AI Chat (Available as Add-on)",
        "Single Branch",
        "No API access",
      ],
      cta: "Start Growth Trial",
      href: `${PUBLIC_POS_WEB_URL}/register?plan=growth`,
      popular: true,
      color: "emerald",
    },
    {
      name: "Business",
      icon: Crown,
      description: "Established multi-branch businesses",
      price: "₦30,000",
      period: "/month",
      annual: "₦300,000/year (save ₦60K)",
      features: [
        "Unlimited Staff",
        "Unlimited Products",
        "Multiple Branches",
        "AI Chat Agent (24/7 Support)",
        "API Access (WooCommerce/Shopify)",
        "White-Label Receipts",
        "Dedicated Account Manager",
        "Delivery Management",
        "₦50 Ecommerce transaction fee",
        "In-chat Purchase",
      ],
      limitations: [],
      cta: "Start Business Trial",
      href: `${PUBLIC_POS_WEB_URL}/register?plan=business`,
      popular: false,
      color: "purple",
    },
    {
      name: "Enterprise",
      icon: Sparkles,
      description: "Custom solutions for large chains",
      price: "Custom",
      period: "",
      annual: "Contact us for quote",
      features: [
        "Everything in Business",
        "Custom White-label Solution",
        "On-premise Deployment",
        "Custom Integrations",
        "SLA Guarantees",
        "Dedicated Infrastructure",
        "Custom Feature Development",
        "In-chat Purchase",
      ],
      limitations: [],
      cta: "Contact Sales",
      href: "/contact?plan=enterprise",
      popular: false,
      color: "amber",
    },
  ];

  const faqs = [
    {
      question: "Is the Starter plan really free?",
      answer:
        "Yes! The Starter plan is completely free with no monthly subscription. We only charge a small transaction fee on successful sales processed through our platform.",
    },
    {
      question: "What are the transaction fees?",
      answer:
        "All plans include a ₦50 fee per ecommerce transaction. This fee covers payment processing and platform maintenance.",
    },
    {
      question: "What is In-chat Purchase?",
      answer:
        "In-chat Purchase allows customers to verify product availability, ask questions, and complete their purchase directly within the chat interface without leaving the conversation.",
    },
    {
      question: "Can I upgrade later?",
      answer:
        "Absolutely. As your business grows and you need more staff or products, you can upgrade to the Growth or Business plan instantly.",
    },
    {
      question: "How does the AI Agent work?",
      answer:
        "The AI Agent is available on the Business plan. It acts as a 24/7 support assistant, answering customer queries about products and orders automatically, even whilst you sleep.",
    },
    {
      question: "What is On-premises Deployment?",
      answer:
        "For Enterprise clients with strict data security requirements, we can deploy the complete Kemani POS system on your own private servers or infrastructure, giving you full control over your data.",
    },
    {
      question: "What is an SLA Guarantee?",
      answer:
        "Service Level Agreement (SLA) is our commitment to a guaranteed level of uptime (e.g., 99.9%). If our service reliability falls below this standard, Enterprise clients are eligible for service credits or refunds.",
    },
    {
      question: "Can I cancel my subscription?",
      answer:
        "Yes, you can cancel your paid subscription at any time. Your data will be preserved, and your account will revert to the Free plan limits at the end of your billing cycle.",
    },
    {
      question: "Do you offer refunds?",
      answer:
        "Yes, we offer a 30-day money-back guarantee on all annual paid plans.",
    },
  ];

  const comparisonFeatures = [
    {
      category: "Branch Management",
      features: [
        "Number of branches",
        "Staff accounts",
        "Multi-branch inventory sync",
      ],
    },
    {
      category: "Core POS",
      features: [
        "Product management",
        "Sales processing",
        "Receipt printing",
        "Barcode scanning",
      ],
    },
    {
      category: "Inventory",
      features: [
        "Stock tracking",
        "Low stock alerts",
        "Product categories",
        "Expiry date tracking",
      ],
    },
    {
      category: "Online Presence",
      features: [
        "Online marketplace",
        "WhatsApp notifications",
        "WhatsApp AI chat",
        "Custom branding",
      ],
    },
    {
      category: "Operations",
      features: [
        "Offline mode",
        "Delivery management",
        "Staff commissions",
        "Customer loyalty",
      ],
    },
    {
      category: "Reporting",
      features: [
        "Sales reports",
        "Inventory reports",
        "Analytics dashboard",
        "Custom reports",
      ],
    },
    {
      category: "Support",
      features: [
        "Email support",
        "Phone support",
        "Priority support",
        "Dedicated manager",
      ],
    },
  ];
</script>

<svelte:head>
  <title>Pricing - Kemani POS</title>
  <meta
    name="description"
    content="Simple, transparent pricing. Start free, upgrade when you need more. Forever free plan available."
  />
</svelte:head>

<div class="min-h-screen theme-gradient-page transition-theme">
  <!-- Navigation -->
  <nav
    class="border-b backdrop-blur-md fixed top-0 w-full z-50 transition-all bg-white/80 dark:bg-gray-900/80 border-gray-200 dark:border-gray-800"
  >
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex justify-between items-center h-16">
        <a href="/" class="flex items-center">
          <span
            class="text-2xl font-bold bg-gradient-to-r from-emerald-600 to-green-600 bg-clip-text text-transparent"
            >Kemani</span
          >
          <span class="ml-2 text-sm text-gray-600 dark:text-gray-400">POS</span>
        </a>
        <div class="hidden md:flex items-center gap-6">
          <a
            href="/"
            class="text-gray-700 dark:text-gray-300 hover:text-emerald-600 dark:hover:text-emerald-400 transition text-sm"
            >Home</a
          >
          <a
            href="/#features"
            class="text-gray-700 dark:text-gray-300 hover:text-emerald-600 dark:hover:text-emerald-400 transition text-sm"
            >Features</a
          >
          <a
            href="/#benefits"
            class="text-gray-700 dark:text-gray-300 hover:text-emerald-600 dark:hover:text-emerald-400 transition text-sm"
            >Benefits</a
          >
          <a
            href="/pricing"
            class="text-emerald-600 dark:text-emerald-400 transition text-sm font-semibold"
            >Pricing</a
          >
          <ThemeToggle />
          <a
            href="{PUBLIC_POS_WEB_URL}/login"
            class="px-4 py-2 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition text-sm"
          >
            Sign In
          </a>
          <a
            href="{PUBLIC_POS_WEB_URL}/register"
            class="px-4 py-2 bg-gradient-to-r from-emerald-600 to-green-600 text-white rounded-lg hover:from-emerald-500 hover:to-green-500 transition text-sm font-medium"
          >
            Start Free
          </a>
        </div>
      </div>
    </div>
  </nav>

  <!-- Hero -->
  <section class="pt-24 pb-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-4xl mx-auto text-center">
      <h1 class="text-4xl sm:text-5xl md:text-6xl font-bold theme-heading mb-6">
        Simple, Transparent Pricing
      </h1>
      <p class="text-lg sm:text-xl theme-text-muted mb-6">
        Start free, upgrade when you need more. No hidden fees, no surprises.
      </p>
      <div
        class="inline-flex items-center gap-2 px-4 py-2 bg-emerald-500/10 border border-emerald-500/30 rounded-full text-sm theme-text mb-4"
      >
        <Sparkles class="h-4 w-4 theme-logo" />
        <span
          >30-day free trial on Professional & Business plans • No credit card
          required</span
        >
      </div>
    </div>
  </section>

  <!-- Pricing Cards -->
  <section class="pb-16 px-4 sm:px-6 lg:px-8">
    <div class="max-w-7xl mx-auto">
      <div class="grid sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {#each pricingPlans as plan, idx}
          <div
            class="relative bg-white/5 backdrop-blur-md rounded-xl shadow-lg border transition hover:shadow-xl {plan.popular
              ? 'border-emerald-500/60 ring-2 ring-emerald-500/20 lg:scale-105'
              : 'border-emerald-800/30'}"
          >
            {#if plan.popular}
              <div
                class="absolute -top-4 left-1/2 -translate-x-1/2 bg-gradient-to-r from-emerald-600 to-green-600 text-white px-4 py-1 text-xs font-semibold rounded-full shadow-lg"
              >
                Most Popular
              </div>
            {/if}

            <div class="p-6">
              <!-- Header -->
              <div class="flex items-center mb-3">
                <div
                  class="w-10 h-10 bg-{plan.color}-500/20 rounded-lg flex items-center justify-center mr-3"
                >
                  <svelte:component
                    this={plan.icon}
                    class="h-5 w-5 theme-logo"
                  />
                </div>
                <h3 class="text-xl font-bold theme-heading">{plan.name}</h3>
              </div>
              <p class="text-sm theme-text-muted mb-6 min-h-[40px]">
                {plan.description}
              </p>

              <!-- Pricing -->
              <div class="mb-5">
                <div class="flex items-baseline">
                  <span class="text-3xl sm:text-4xl font-bold theme-heading"
                    >{plan.price}</span
                  >
                  <span class="theme-text-muted ml-2 text-sm"
                    >{plan.period}</span
                  >
                </div>
                <p class="text-xs mt-1 font-medium theme-logo">{plan.annual}</p>
              </div>

              <!-- CTA -->
              <a
                href={plan.href}
                class="block w-full py-2.5 px-6 text-center text-sm font-semibold rounded-lg transition {plan.popular
                  ? 'bg-gradient-to-r from-emerald-600 to-green-600 text-white hover:from-emerald-500 hover:to-green-500 shadow-md'
                  : 'bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 hover:bg-emerald-500/30'}"
              >
                {plan.cta}
              </a>

              <!-- Features -->
              <div class="mt-6 space-y-3">
                <div class="text-sm font-semibold theme-heading mb-2">
                  What's included:
                </div>
                <ul class="space-y-2">
                  {#each plan.features as feature}
                    <li class="flex items-start">
                      <Check
                        class="h-4 w-4 theme-logo mr-2 flex-shrink-0 mt-0.5"
                      />
                      <span class="theme-text-muted text-xs leading-relaxed"
                        >{feature}</span
                      >
                    </li>
                  {/each}
                </ul>

                {#if plan.limitations.length > 0}
                  <div class="mt-4 pt-4 border-t border-emerald-800/30">
                    <div class="text-xs theme-text-muted opacity-70 space-y-1">
                      <div class="font-medium mb-1">Not included:</div>
                      {#each plan.limitations as limitation}
                        <div class="flex items-start">
                          <X
                            class="h-3 w-3 text-red-500 mr-1 flex-shrink-0 mt-0.5"
                          />
                          <span>{limitation}</span>
                        </div>
                      {/each}
                    </div>
                  </div>
                {/if}
              </div>
            </div>
          </div>
        {/each}
      </div>

      <!-- Trust Banner -->
      <div
        class="text-center py-8 bg-gradient-to-r from-emerald-500/10 to-green-500/10 rounded-xl border border-emerald-500/30"
      >
        <p class="text-lg theme-heading font-semibold mb-2">
          All plans include:
        </p>
        <div
          class="flex flex-wrap justify-center gap-4 text-sm theme-text-muted"
        >
          <span class="flex items-center gap-2">
            <Check class="h-4 w-4 theme-logo" />
            Free updates forever
          </span>
          <span class="flex items-center gap-2">
            <Check class="h-4 w-4 theme-logo" />
            Data encryption & security
          </span>
          <span class="flex items-center gap-2">
            <Check class="h-4 w-4 theme-logo" />
            Daily automatic backups
          </span>
          <span class="flex items-center gap-2">
            <Check class="h-4 w-4 theme-logo" />
            Mobile app (Android & iOS)
          </span>
        </div>
      </div>
    </div>
  </section>

  <!-- AI Add-on Highlight -->
  <section
    class="py-12 bg-emerald-500/5 backdrop-blur-sm border-y border-emerald-800/30"
  >
    <div class="max-w-4xl mx-auto px-4 text-center">
      <div
        class="inline-flex items-center justify-center p-3 bg-emerald-500/10 rounded-full mb-4"
      >
        <Sparkles class="h-6 w-6 text-emerald-600 dark:text-emerald-400 mr-2" />
        <span class="text-emerald-600 dark:text-emerald-400 font-semibold"
          >New Feature</span
        >
      </div>
      <h2 class="text-3xl font-bold theme-heading mb-4">Supercharge with AI</h2>
      <p class="text-lg theme-text-muted mb-6">
        Turn your data into insights. Add the AI Chat Agent to your Starter or
        Growth plan for just
        <span class="text-emerald-600 dark:text-emerald-400 font-bold mx-1"
          >₦10,000/month</span
        >
        (Included in Business & Enterprise).
      </p>
      <div
        class="grid grid-cols-1 md:grid-cols-3 gap-6 text-left max-w-2xl mx-auto"
      >
        <div class="flex items-start">
          <Check
            class="h-5 w-5 text-emerald-600 dark:text-emerald-400 mr-2 mt-0.5"
          />
          <span class="text-sm theme-text-muted"
            >Analyze sales trends instantly</span
          >
        </div>
        <div class="flex items-start">
          <Check
            class="h-5 w-5 text-emerald-600 dark:text-emerald-400 mr-2 mt-0.5"
          />
          <span class="text-sm theme-text-muted"
            >Get inventory recommendations</span
          >
        </div>
        <div class="flex items-start">
          <Check
            class="h-5 w-5 text-emerald-600 dark:text-emerald-400 mr-2 mt-0.5"
          />
          <span class="text-sm theme-text-muted">Draft marketing messages</span>
        </div>
      </div>
    </div>
  </section>

  <!-- FAQ Section -->
  <section class="py-20 theme-gradient-section transition-theme">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="text-center mb-12">
        <h2 class="text-3xl md:text-4xl font-bold theme-heading mb-4">
          Frequently Asked Questions
        </h2>
        <p class="text-lg theme-text-muted">
          Got questions? We've got answers.
        </p>
      </div>

      <div class="space-y-4">
        {#each faqs as faq, idx}
          <details
            class="group bg-white/5 backdrop-blur-md rounded-lg border border-emerald-500/20 hover:border-emerald-400/40 transition"
          >
            <summary
              class="flex items-center justify-between p-6 cursor-pointer list-none"
            >
              <h3 class="text-lg font-semibold theme-heading pr-4">
                {faq.question}
              </h3>
              <ArrowRight
                class="h-5 w-5 theme-logo transition-transform group-open:rotate-90"
              />
            </summary>
            <div class="px-6 pb-6 pt-2">
              <p class="theme-text-muted leading-relaxed">{faq.answer}</p>
            </div>
          </details>
        {/each}
      </div>

      <div class="mt-12 text-center">
        <p class="theme-text-muted mb-4">Still have questions?</p>
        <a
          href="/contact"
          class="inline-flex items-center px-6 py-3 bg-gradient-to-r from-emerald-600 to-green-600 text-white font-semibold rounded-lg hover:from-emerald-500 hover:to-green-500 transition shadow-lg"
        >
          <Phone class="h-5 w-5 mr-2" />
          Contact Sales
        </a>
      </div>
    </div>
  </section>

  <!-- CTA Section -->
  <section
    class="py-20 theme-gradient-cta backdrop-blur-sm text-white transition-theme"
  >
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
      <h2 class="text-3xl md:text-4xl font-bold mb-6">
        Ready to Transform Your Business?
      </h2>
      <p class="text-xl text-emerald-50/90 mb-8">
        Join hundreds of Nigerian businesses using Kemani POS. Start free today.
      </p>
      <div class="flex flex-col sm:flex-row gap-4 justify-center">
        <a
          href="{PUBLIC_POS_WEB_URL}/register?plan=free"
          class="inline-flex items-center justify-center px-8 py-4 bg-white text-emerald-600 text-lg font-semibold rounded-lg hover:bg-emerald-50 transition shadow-lg hover:shadow-xl"
        >
          Start Free Forever
          <ArrowRight class="ml-2 h-5 w-5" />
        </a>
        <a
          href="{PUBLIC_POS_WEB_URL}/register?plan=growth"
          class="inline-flex items-center justify-center px-8 py-4 bg-transparent text-white text-lg font-semibold rounded-lg border-2 border-white hover:bg-white/10 backdrop-blur-sm transition"
        >
          Try Growth Free
        </a>
      </div>
      <p class="mt-6 text-sm text-emerald-100/70">
        No credit card required • 30-day money-back guarantee • Cancel anytime
      </p>
    </div>
  </section>

  <!-- Footer -->
  <footer
    class="bg-gray-900 text-gray-300 py-12 border-t border-emerald-800/30"
  >
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="grid md:grid-cols-4 gap-8">
        <div>
          <div class="flex items-center mb-4">
            <span class="text-2xl font-bold text-emerald-400">Kemani</span>
            <span class="ml-2 text-sm text-emerald-300/70">POS</span>
          </div>
          <p class="text-sm text-gray-400">
            Offline-first POS platform built for Nigerian businesses.
          </p>
        </div>

        <div>
          <h3 class="text-white font-semibold mb-4">Product</h3>
          <ul class="space-y-2 text-sm">
            <li>
              <a href="/#features" class="hover:text-emerald-400 transition"
                >Features</a
              >
            </li>
            <li>
              <a href="/pricing" class="hover:text-emerald-400 transition"
                >Pricing</a
              >
            </li>
            <li>
              <a href="#demo" class="hover:text-emerald-400 transition">Demo</a>
            </li>
          </ul>
        </div>

        <div>
          <h3 class="text-white font-semibold mb-4">Support</h3>
          <ul class="space-y-2 text-sm">
            <li>
              <a href="/docs" class="hover:text-emerald-400 transition"
                >Documentation</a
              >
            </li>
            <li>
              <a href="/support" class="hover:text-emerald-400 transition"
                >Help Center</a
              >
            </li>
            <li>
              <a href="/contact" class="hover:text-emerald-400 transition"
                >Contact Us</a
              >
            </li>
          </ul>
        </div>

        <div>
          <h3 class="text-white font-semibold mb-4">Legal</h3>
          <ul class="space-y-2 text-sm">
            <li>
              <a href="/privacy" class="hover:text-emerald-400 transition"
                >Privacy Policy</a
              >
            </li>
            <li>
              <a href="/terms" class="hover:text-emerald-400 transition"
                >Terms of Service</a
              >
            </li>
          </ul>
        </div>
      </div>

      <div
        class="border-t border-gray-800 mt-8 pt-8 text-center text-sm text-gray-400"
      >
        <p>
          &copy; {new Date().getFullYear()} Kemani POS. All rights reserved. Built
          with ❤️ for Nigerian businesses.
        </p>
      </div>
    </div>
  </footer>
</div>
