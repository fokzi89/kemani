<script lang="ts">
	import { MessageSquare, Star, Clock, ShieldCheck, ChevronRight, ArrowLeft, Info, Activity } from 'lucide-svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { supabase } from '$lib/supabase';
	import { currentUser, isAuthenticated } from '$lib/stores/auth';
	import { isAuthModalOpen } from '$lib/stores/ui';
    import { setActiveConversation } from '$lib/stores/chat.store';

	let { data } = $props();
	let { pharmacists, storefront, productId } = $derived(data);

	let initiatingId = $state<string | null>(null);

	async function startConsultation(pharmacist: any) {
		if (!$isAuthenticated) {
			isAuthModalOpen.set(true);
			return;
		}

		initiatingId = pharmacist.user_id;
		try {
			// Check for existing active conversation with this pharmacist
			const { data: existing } = await supabase
				.from('chat_conversations')
				.select('id')
				.eq('customer_id', $currentUser.id)
				.eq('service_provider', pharmacist.user_id)
				.eq('status', 'active')
				.single();

			if (existing) {
				setActiveConversation(existing.id);
				goto(`/chat?id=${existing.id}&type=Consultation${productId ? `&productId=${productId}` : ''}`);
				return;
			}

			// Create new consultation chat
			const { data: created, error } = await supabase
				.from('chat_conversations')
				.insert({
					customer_id: $currentUser.id,
					tenant_id: storefront.id,
					chatType: 'Consultation',
					service_provider: pharmacist.user_id,
					service_provider_name: pharmacist.display_name,
					service_provider_pic: pharmacist.photo_url,
					customer_name: $currentUser?.user_metadata?.full_name || $currentUser?.email,
					customer_pic: $currentUser?.user_metadata?.avatar_url,
					status: pharmacist.isBusy ? 'open' : 'active', // 'open' means in queue
					metadata: { 
						origin: 'pharmacist_selection',
						productId: productId,
                        provider_type: pharmacist.provider_type
					}
				})
				.select().single();

			if (error) throw error;

			if (created) {
				setActiveConversation(created.id);
				goto(`/chat?id=${created.id}&type=Consultation${productId ? `&productId=${productId}` : ''}`);
			}
		} catch (err) {
			console.error('Failed to start consultation:', err);
			alert('Failed to start consultation. Please try again.');
		} finally {
			initiatingId = null;
		}
	}

    function initials(name: string) {
        return name.split(' ').map(n => n[0]).join('').slice(0, 2).toUpperCase();
    }
</script>

<svelte:head>
	<title>Select Pharmacist – {storefront.name}</title>
</svelte:head>

<div class="min-h-screen bg-[#faf9f6] pt-24 pb-12">
	<div class="max-w-4xl mx-auto px-4 sm:px-6">
		
		<!-- Back & Breadcrumb -->
		<button onclick={() => history.back()} class="flex items-center gap-2 text-gray-500 hover:text-gray-900 transition-colors mb-8 group">
			<ArrowLeft class="w-4 h-4 group-hover:-translate-x-1 transition-transform" />
			<span class="text-[10px] font-bold uppercase tracking-widest">Back to Store</span>
		</button>

		<!-- Header Section -->
		<div class="mb-12">
			<h1 class="font-display text-4xl text-gray-900 mb-4">Professional Consultation</h1>
			<p class="text-gray-500 max-w-xl leading-relaxed text-sm">
				Our certified pharmacists are available to provide professional guidance, prescription services, and health advice. Select a specialist below to begin your consultation.
			</p>
		</div>

		<!-- Info Note -->
		<div class="bg-indigo-50/50 border border-indigo-100 rounded-2xl p-4 flex items-start gap-4 mb-10">
			<div class="w-10 h-10 bg-white rounded-full flex items-center justify-center flex-shrink-0 shadow-sm">
				<Info class="w-5 h-5 text-indigo-600" />
			</div>
			<div>
				<p class="text-[11px] font-bold text-indigo-900 uppercase tracking-wider mb-1">Professional Excellence</p>
				<p class="text-xs text-indigo-700/80 leading-relaxed">
					All consultations are private, secure, and handled by verified clinical professionals. Ongoing consultations may require a brief wait in the queue.
				</p>
			</div>
		</div>

		<!-- Pharmacist List -->
		<div class="grid grid-cols-1 gap-4">
			{#if pharmacists.length === 0}
				<div class="bg-white border border-gray-100 rounded-3xl p-12 text-center">
					<div class="w-16 h-16 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-4">
						<Activity class="w-8 h-8 text-gray-300" />
					</div>
					<h3 class="text-lg font-bold text-gray-900 mb-2">No pharmacists available</h3>
					<p class="text-sm text-gray-500">Please try again during business hours.</p>
				</div>
			{:else}
				{#each pharmacists as pharmacist}
					<div 
						class="bg-white border border-gray-100 rounded-3xl p-6 transition-all hover:shadow-xl hover:shadow-gray-200/50 hover:border-indigo-100 group relative overflow-hidden"
					>
						<!-- Busy Overlay / Glow -->
						{#if pharmacist.isBusy}
							<div class="absolute top-0 right-0 p-4">
								<div class="bg-amber-50 text-amber-600 text-[9px] font-bold uppercase tracking-widest px-2 py-1 rounded-md border border-amber-100 flex items-center gap-1.5">
									<Clock class="w-3 h-3" /> In Consultation
								</div>
							</div>
						{/if}

						<div class="flex items-center gap-6 relative z-10">
							<!-- Avatar -->
							<div class="relative flex-shrink-0">
								{#if pharmacist.photo_url}
									<img src={pharmacist.photo_url} alt={pharmacist.display_name} class="w-20 h-20 rounded-2xl object-cover shadow-sm border-2 border-white" />
								{:else}
									<div class="w-20 h-20 rounded-2xl bg-gray-100 flex items-center justify-center text-gray-400 font-bold text-xl shadow-sm border-2 border-white">
										{initials(pharmacist.display_name)}
									</div>
								{/if}
								<!-- Online Badge -->
								<div class="absolute -bottom-1 -right-1 w-5 h-5 bg-white rounded-full flex items-center justify-center shadow-md">
									<div class="w-2.5 h-2.5 rounded-full {pharmacist.isBusy ? 'bg-amber-400' : 'bg-emerald-500'}"></div>
								</div>
							</div>

							<!-- Content -->
							<div class="flex-grow">
								<div class="flex items-center gap-2 mb-1">
									<h2 class="text-xl font-bold text-gray-900">{pharmacist.display_name}</h2>
									<ShieldCheck class="w-4 h-4 text-indigo-500" />
								</div>
								<p class="text-xs font-semibold text-gray-400 uppercase tracking-widest mb-3">
									{pharmacist.specialization}
								</p>
								
								<div class="flex items-center gap-4">
									<div class="flex items-center gap-1.5">
										<Star class="w-3.5 h-3.5 text-amber-400 fill-amber-400" />
										<span class="text-sm font-bold text-gray-700">{pharmacist.average_rating.toFixed(1)}</span>
									</div>
									<div class="w-1 h-1 bg-gray-200 rounded-full"></div>
									<div class="flex items-center gap-1.5 text-gray-500">
										<MessageSquare class="w-3.5 h-3.5" />
										<span class="text-[11px] font-medium uppercase tracking-tight">Direct Chat Available</span>
									</div>
								</div>
							</div>

							<!-- Action -->
							<button 
								onclick={() => startConsultation(pharmacist)}
								disabled={initiatingId === pharmacist.user_id}
								class="flex items-center gap-3 px-6 py-4 rounded-2xl font-bold text-sm transition-all {pharmacist.isBusy ? 'bg-gray-100 text-gray-600 hover:bg-gray-200' : 'bg-gray-900 text-white hover:bg-black hover:translate-x-1 shadow-lg shadow-gray-200'}"
							>
								{#if initiatingId === pharmacist.user_id}
									<div class="w-4 h-4 border-2 border-white/20 border-t-white rounded-full animate-spin"></div>
								{:else if pharmacist.isBusy}
									Join Queue
								{:else}
									Consult Now
								{/if}
								<ChevronRight class="w-4 h-4" />
							</button>
						</div>

						<!-- Background Decoration -->
						<div class="absolute -right-4 -bottom-4 opacity-[0.03] group-hover:opacity-[0.06] transition-opacity">
							<Activity class="w-32 h-32 text-gray-900" />
						</div>
					</div>
				{/each}
			{/if}
		</div>

		<!-- Footer Help -->
		<div class="mt-16 text-center">
			<p class="text-xs text-gray-400 uppercase tracking-widest mb-4">Need urgent assistance?</p>
			<div class="flex items-center justify-center gap-6">
				<a href="mailto:{storefront.email}" class="text-[10px] font-bold text-gray-900 hover:text-indigo-600 transition-colors uppercase tracking-[0.2em]">{storefront.email}</a>
				<div class="w-1 h-1 bg-gray-200 rounded-full"></div>
				<a href="tel:{storefront.phone}" class="text-[10px] font-bold text-gray-900 hover:text-indigo-600 transition-colors uppercase tracking-[0.2em]">{storefront.phone}</a>
			</div>
		</div>

	</div>
</div>

<style>
	:global(body) {
		background-color: #faf9f6;
	}
	.font-display {
		font-family: 'Playfair Display', serif;
	}
</style>
