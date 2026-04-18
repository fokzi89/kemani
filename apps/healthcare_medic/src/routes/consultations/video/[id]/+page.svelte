<script lang="ts">
	import { page } from '$app/stores';
	import { supabase } from '$lib/supabase';
	import { onMount } from 'svelte';
	import { 
		Video, VideoOff, Mic, MicOff, PhoneOff, 
		User, ShieldCheck, Maximize, Settings 
	} from 'lucide-svelte';

	const consultationId = $derived($page.params.id);
	let consultation = $state<any>(null);
	let loading = $state(true);
	let cameraBg = $state(true);
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
		if (confirm('Are you sure you want to end this consultation session?')) {
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
	<title>Video Consultation - Kemani</title>
</svelte:head>

<div class="fixed inset-0 bg-gray-900 flex flex-col z-50 overflow-hidden">
	<!-- Top Bar -->
	<div class="h-16 flex items-center justify-between px-6 bg-gray-900/50 backdrop-blur-md border-b border-white/5 z-10">
		<div class="flex items-center gap-4">
			<div class="h-10 w-10 rounded-full bg-primary-600 flex items-center justify-center border-2 border-white/20">
				<User class="h-5 w-5 text-white" />
			</div>
			<div>
				<h3 class="text-sm font-bold text-white tracking-wide">
					{consultation?.profiles?.full_name || 'Patient'}
				</h3>
				<div class="flex items-center gap-2">
					<div class="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse"></div>
					<p class="text-[10px] font-bold text-emerald-500 uppercase tracking-widest">Live Call • {formatTime(timeElapsed)}</p>
				</div>
			</div>
		</div>

		<div class="flex items-center gap-3">
			<div class="hidden md:flex items-center gap-2 px-3 py-1.5 bg-white/5 rounded-full border border-white/10">
				<ShieldCheck class="h-3.5 w-3.5 text-emerald-400" />
				<span class="text-[10px] font-bold text-gray-300 uppercase tracking-widest">End-to-End Encrypted</span>
			</div>
			<button class="p-2 text-white/60 hover:text-white transition-colors">
				<Settings class="h-5 w-5" />
			</button>
		</div>
	</div>

	<!-- Main Video Area -->
	<div class="flex-1 relative flex items-center justify-center p-4 lg:p-8">
		<!-- Patient (Remote) Video Placeholder -->
		<div class="w-full h-full max-w-5xl rounded-3xl bg-gray-800/50 border border-white/5 overflow-hidden relative shadow-2xl flex flex-col items-center justify-center group">
			<div class="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
			
			<div class="text-center space-y-4 relative z-10">
				<div class="h-32 w-32 bg-gray-700 rounded-full flex items-center justify-center mx-auto border-4 border-white/10 shadow-2xl">
					<User class="h-16 w-16 text-gray-400" />
				</div>
				<div>
					<h2 class="text-2xl font-bold text-white tracking-tight">Patient View</h2>
					<p class="text-gray-400 text-sm font-medium">Connecting to encrypted peer stream...</p>
				</div>
				<div class="flex justify-center gap-1">
					{#each Array(3) as _, i}
						<div class="h-1 w-1 rounded-full bg-primary-500 animate-bounce" style="animation-delay: {i * 0.2}s"></div>
					{/each}
				</div>
			</div>

			<!-- Provider (Local) Preview Overlay -->
			<div class="absolute bottom-6 left-6 w-32 md:w-48 aspect-video bg-gray-900 rounded-2xl border-2 border-white/20 shadow-2xl overflow-hidden group/local">
				{#if cameraBg}
					<div class="w-full h-full flex items-center justify-center bg-gray-800">
						<User class="h-8 w-8 text-gray-600" />
					</div>
				{:else}
					<div class="w-full h-full flex items-center justify-center bg-black">
						<VideoOff class="h-6 w-6 text-white/20" />
					</div>
				{/if}
				<div class="absolute top-2 left-2 px-1.5 py-0.5 bg-black/40 backdrop-blur-sm rounded text-[8px] font-bold text-white uppercase tracking-widest">You</div>
			</div>
		</div>
	</div>

	<!-- Bottom Control Bar -->
	<div class="h-28 flex flex-col items-center justify-center bg-transparent z-10">
		<div class="flex items-center gap-4 bg-gray-800/80 backdrop-blur-2xl px-8 py-4 rounded-3xl border border-white/10 shadow-2xl">
			<button 
				onclick={() => micOn = !micOn}
				class="p-4 rounded-2xl {micOn ? 'bg-white/5 text-white hover:bg-white/10' : 'bg-red-500/10 text-red-500'} transition-all"
			>
				{#if micOn}<Mic class="h-6 w-6" />{:else}<MicOff class="h-6 w-6" />{/if}
			</button>
			
			<button 
				onclick={() => cameraBg = !cameraBg}
				class="p-4 rounded-2xl {cameraBg ? 'bg-white/5 text-white hover:bg-white/10' : 'bg-red-500/10 text-red-500'} transition-all"
			>
				{#if cameraBg}<Video class="h-6 w-6" />{:else}<VideoOff class="h-6 w-6" />{/if}
			</button>

			<button 
				onclick={endCall}
				class="p-4 rounded-2xl bg-red-600 text-white hover:bg-red-700 transition-all shadow-lg shadow-red-500/20"
			>
				<PhoneOff class="h-8 w-8" />
			</button>

			<div class="w-px h-8 bg-white/10 mx-2"></div>

			<button class="p-4 rounded-2xl bg-white/5 text-white hover:bg-white/10 transition-all">
				<Maximize class="h-6 w-6" />
			</button>
		</div>

		<div class="mt-2 text-[10px] font-black uppercase tracking-[0.2em] text-white/30">
			Kemani Secure Media Stream
		</div>
	</div>
</div>

<style>
	:global(body) {
		overflow: hidden !important;
	}
</style>
