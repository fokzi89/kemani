<script lang="ts">
    import { Sparkles, Bot, Clock, ArrowRight, Star } from 'lucide-svelte';
    import { fade, fly, scale } from 'svelte/transition';
</script>

<div class="min-h-screen bg-slate-50 flex items-center justify-center p-6 relative overflow-hidden">
    <!-- Decorative background elements -->
    <div class="absolute top-0 right-0 w-[500px] h-[500px] bg-indigo-100 rounded-full blur-[120px] opacity-40 -translate-y-1/2 translate-x-1/2"></div>
    <div class="absolute bottom-0 left-0 w-[500px] h-[500px] bg-blue-100 rounded-full blur-[120px] opacity-40 translate-y-1/2 -translate-x-1/2"></div>

    <div class="max-w-2xl w-full text-center relative z-10" in:fly={{ y: 20, duration: 800 }}>
        <!-- Icon Container -->
        <div class="relative inline-block mb-8">
            <div class="p-5 bg-white rounded-3xl shadow-2xl shadow-indigo-100 relative z-10 border border-slate-50" in:scale={{ duration: 600, delay: 200 }}>
                <div class="p-4 bg-indigo-600 rounded-2xl text-white shadow-lg shadow-indigo-200">
                    <Sparkles class="h-10 w-10 animate-pulse" />
                </div>
            </div>
            <!-- Floating particles -->
            <div class="absolute -top-4 -right-4 animate-bounce">
                <div class="p-2 bg-amber-400 rounded-xl text-white shadow-lg">
                    <Star class="h-4 w-4" />
                </div>
            </div>
            <div class="absolute -bottom-2 -left-6 animate-pulse [animation-delay:0.5s]">
                <div class="p-2 bg-emerald-400 rounded-xl text-white shadow-lg">
                    <Bot class="h-5 w-5" />
                </div>
            </div>
        </div>

        <!-- Text Content -->
        <div class="space-y-4">
            <h1 class="text-4xl md:text-5xl font-black text-slate-900 tracking-tight">
                AI Assistant is <span class="text-transparent bg-clip-text bg-gradient-to-r from-indigo-600 to-blue-600">Coming Soon</span>
            </h1>
            <p class="text-lg text-slate-500 font-medium max-w-lg mx-auto leading-relaxed">
                We're building a powerful AI companion to help you analyze sales, manage inventory, and grow your business with intelligent insights.
            </p>
        </div>

        <!-- Features Preview -->
        <div class="mt-12 grid grid-cols-1 md:grid-cols-3 gap-4 text-left">
            {#each [
                { icon: 'BarChart3', title: 'Sales Insights', desc: 'Real-time analysis' },
                { icon: 'ClipboardList', title: 'Stock Alerts', desc: 'Predictive restocking' },
                { icon: 'TrendingUp', title: 'Growth Tips', desc: 'Data-driven advice' }
            ] as feature, i}
                <div 
                    class="p-5 bg-white rounded-2xl border border-slate-100 shadow-sm hover:shadow-md transition-all hover:-translate-y-1 group"
                    in:fly={{ y: 20, duration: 600, delay: 400 + (i * 100) }}
                >
                    <div class="h-10 w-10 bg-slate-50 rounded-xl flex items-center justify-center mb-3 group-hover:bg-indigo-50 transition-colors">
                        <ArrowRight class="h-5 w-5 text-slate-400 group-hover:text-indigo-600" />
                    </div>
                    <h3 class="font-bold text-slate-800 text-sm">{feature.title}</h3>
                    <p class="text-xs text-slate-400 font-medium">{feature.desc}</p>
                </div>
            {/each}
        </div>

        <!-- Status Indicator -->
        <div class="mt-12 flex flex-col items-center gap-4">
            <div class="px-4 py-2 bg-white rounded-full border border-slate-100 shadow-sm flex items-center gap-2" in:fade={{ delay: 1000 }}>
                <Clock class="h-4 w-4 text-indigo-600" />
                <span class="text-xs font-bold text-slate-600 uppercase tracking-widest">In Development</span>
            </div>
            
            <p class="text-[10px] text-slate-400 font-black uppercase tracking-[0.2em]">
                Kemani POS Intelligence Engine v1.0
            </p>
        </div>
    </div>
</div>

<style>
    :global(body) {
        background-color: #f8fafc;
    }
</style>
