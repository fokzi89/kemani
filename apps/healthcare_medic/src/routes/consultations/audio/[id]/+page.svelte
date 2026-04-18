<script lang="ts">
	import { page } from '$app/stores';
	import { supabase } from '$lib/supabase';
	import { onMount } from 'svelte';
	import { 
		Mic, MicOff, PhoneOff, User, 
		ShieldCheck, Settings, Volume2 
	} from 'lucide-svelte';

	const consultationId = $derived($page.params.id);
	let consultation = $state<any>(null);
	let loading = $state(true);
	let micOn = $state(true);
	let timeElapsed = $state(0);

	onMount(async () => {
		const { data: consultationData } = await supabase
			.from('consultations')
			.select('*, profiles:patient_id(full_name)')
			.eq('id', consultationId)
			.single();
		
		consultation = consultationData;
		loading = false;

		const timer = setInterval(() => {
			timeElapsed++;
		}, 1000);

		return () => clearInterval(timer);
	});

	function formatTime(seconds: number) {
		const mins = Math.floor(seconds / 60);
		const secs = seconds % 60;
		return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
	}

	async function endCall() {
		if (confirm('Are you sure you want to end this audio consultation?')) {
			const { error } = await supabase
				.from('consultations')
				.update({ status: 'completed' })
				.eq('id', consultationId);
			
			if (!error) {
				window.location.href = '/consultations';
			}
		}
	}
</script>

<svelte:head>
	<title>Audio Consultation - Kemani</title>
</svelte:head>

<div class="fixed inset-0 bg-gray-900 flex flex-col z-50 overflow-hidden">
	<!-- Top Bar -->
	<div class="h-16 flex items-center justify-between px-6 bg-gray-900/50 backdrop-blur-md border-b border-white/5 z-10">
		<div class="flex items-center gap-4">
			<div class="h-8 w-8 rounded-full bg-emerald-500/10 flex items-center justify-center border border-emerald-500/20">
				<ShieldCheck class="h-4 w-4 text-emerald-500" />
			</div>
			<div>
				<p class="text-[10px] font-black text-white/40 uppercase tracking-[0.2em]">Secure Audio Channel</p>
			</div>
		</div>

		<div class="flex items-center gap-3">
			<div class="flex items-center gap-2 px-3 py-1.5 bg-emerald-500/5 rounded-full border border-emerald-500/10">
				<span class="text-[10px] font-bold text-emerald-400 uppercase tracking-widest">Active</span>
			</div>
			<button class="p-2 text-white/60 hover:text-white transition-colors">
				<Settings class="h-5 w-5" />
			</button>
		</div>
	</div>

	<!-- Main Audio Content -->
	<div class="flex-1 flex flex-col items-center justify-center p-6 text-center space-y-12">
		<!-- Patient Profile Card -->
		<div class="space-y-6">
			<div class="relative inline-block">
				<!-- Outer Pulsing Rings -->
				<div class="absolute inset-0 bg-primary-500/20 rounded-full animate-ping"></div>
				<div class="absolute inset-0 bg-primary-500/10 rounded-full animate-pulse blur-xl"></div>
				
				<div class="relative h-40 w-40 bg-gray-800 rounded-full flex items-center justify-center border-4 border-white/5 shadow-2xl overflow-hidden">
					<User class="h-20 w-20 text-gray-500" />
				</div>
			</div>
			
			<div>
				<h2 class="text-3xl font-bold text-white tracking-tight">
					{consultation?.profiles?.full_name || 'Patient'}
				</h2>
				<p class="text-primary-500 font-extrabold text-sm uppercase tracking-widest mt-2">
					Voice Call • {formatTime(timeElapsed)}
				</p>
			</div>
		</div>

		<!-- Waveform Visualization -->
		<div class="flex items-center justify-center gap-1.5 h-16 w-full max-w-sm">
			{#each Array(24) as _, i}
				<div 
					class="w-1.5 bg-primary-500/40 rounded-full animate-waveform" 
					style="height: {20 + Math.random() * 80}%; animation-delay: {i * 0.1}s"
				></div>
			{/each}
		</div>

		<div class="p-4 bg-white/5 rounded-2xl border border-white/5 flex items-center gap-3">
			<Volume2 class="h-4 w-4 text-white/40" />
			<p class="text-xs text-white/40 font-medium tracking-wide">Noise suppression active for high clarity</p>
		</div>
	</div>

	<!-- Bottom Control Bar -->
	<div class="h-32 flex flex-col items-center justify-center">
		<div class="flex items-center gap-6 bg-gray-800/80 backdrop-blur-2xl px-12 py-5 rounded-full border border-white/10 shadow-2xl">
			<button 
				onclick={() => micOn = !micOn}
				class="p-4 rounded-full {micOn ? 'bg-white/5 text-white hover:bg-white/10' : 'bg-red-500/10 text-red-500'} transition-all"
			>
				{#if micOn}<Mic class="h-7 w-7" />{:else}<MicOff class="h-7 w-7" />{/if}
			</button>

			<button 
				onclick={endCall}
				class="p-5 rounded-full bg-red-600 text-white hover:bg-red-700 transition-all shadow-xl shadow-red-500/40"
			>
				<PhoneOff class="h-10 w-10" />
			</button>

			<button class="p-4 rounded-full bg-white/5 text-white hover:bg-white/10 transition-all">
				<Volume2 class="h-7 w-7" />
			</button>
		</div>
	</div>
</div>

<style>
	:global(body) {
		overflow: hidden !important;
	}

	@keyframes -global-waveform {
		0%, 100% { height: 20%; opacity: 0.4; }
		50% { height: 100%; opacity: 1; }
	}

	.animate-waveform {
		animation: -global-waveform 1.2s ease-in-out infinite;
	}
</style>
