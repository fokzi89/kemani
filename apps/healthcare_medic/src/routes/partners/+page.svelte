<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { 
		Building, 
		User, 
		Calendar, 
		MapPin, 
		ArrowRight, 
		ArrowLeft,
		Handshake,
		Loader2,
		MessageSquare,
		ExternalLink
	} from 'lucide-svelte';
	import { goto } from '$app/navigation';

	let partners = $state<any[]>([]);
	let loading = $state(true);
	let providerId = $state<string | null>(null);

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) {
			goto('/auth/login');
			return;
		}

		// Get current provider profile
		const { data: providerData } = await supabase
			.from('healthcare_providers')
			.select('id')
			.eq('user_id', session.user.id)
			.single();
		
		if (providerData) {
			providerId = providerData.id;
			await loadPartners();
		}
		loading = false;
	});

	async function loadPartners() {
		if (!providerId) return;
		
		// Fetch doctor_aliases where accepted=true
		const { data, error } = await supabase
			.from('doctor_aliases')
			.select(`
				id,
				alias,
				created_at,
				clinic_name,
				primary_doctor_id,
				primary_provider:healthcare_providers!primary_doctor_id (
					full_name,
					specialization,
					profile_photo_url,
					clinic_address,
					region,
					country
				)
			`)
			.eq('doctor_id', providerId)
			.eq('accepted', true)
			.eq('is_active', true);

		if (error) {
			console.error('Error loading partners:', error);
		} else {
			partners = data || [];
		}
	}
</script>

<div class="min-h-screen bg-gray-50/50 p-6 lg:p-8">
	<div class="max-w-6xl mx-auto space-y-8">
		<!-- Header Section -->
		<div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
			<div>
				<div class="flex items-center gap-2 text-gray-500 font-bold mb-1 text-xs uppercase tracking-widest">
					<Handshake class="h-4 w-4" />
					<span>Partnerships</span>
				</div>
				<h1 class="text-2xl font-black text-gray-900 tracking-tight">Active Partners</h1>
				<p class="text-gray-500 mt-1 text-sm font-medium">Clinics and Lead Doctors you are collaborating with.</p>
			</div>
			
			<div class="flex items-center gap-3">
				<div class="bg-black text-white px-5 py-3 rounded-2xl shadow-xl shadow-black/10">
					<p class="text-[9px] font-black uppercase tracking-widest text-gray-400">Total</p>
					<p class="text-2xl font-black">{partners.length}</p>
				</div>
			</div>
		</div>

		{#if loading}
			<div class="bg-white rounded-3xl border border-gray-100 p-12 text-center shadow-sm">
				<Loader2 class="h-10 w-10 animate-spin text-black mx-auto" />
				<p class="mt-4 text-gray-400 text-[10px] font-black uppercase tracking-widest">Loading Partners...</p>
			</div>
		{:else if partners.length === 0}
			<div class="bg-white rounded-3xl border border-gray-100 p-12 text-center shadow-sm">
				<div class="h-16 w-16 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-4">
					<Handshake class="h-8 w-8 text-gray-300" />
				</div>
				<h2 class="text-xl font-black text-gray-900">No Active Partnerships</h2>
				<p class="text-gray-500 text-sm mt-1 max-w-sm mx-auto font-medium">
					You aren't collaborating with any clinics yet. Enable "Allow Invitations" in settings to let clinics find and invite you.
				</p>
				<div class="mt-6">
					<button 
						onclick={() => goto('/settings')}
						class="px-6 py-3 bg-black text-white text-sm font-black rounded-2xl hover:bg-gray-800 transition-all active:scale-95 shadow-xl shadow-black/20"
					>
						Go to Settings
					</button>
				</div>
			</div>
		{:else}
			<!-- Partners Grid -->
			<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
				{#each partners as partner}
					<div class="group relative bg-white rounded-3xl overflow-hidden border border-gray-100 hover:border-black/10 hover:shadow-2xl hover:shadow-black/5 transition-all duration-300">
						<!-- Top Accent -->
						<div class="h-16 bg-gray-50 group-hover:bg-black transition-colors duration-300"></div>

						<div class="p-6 -mt-10">
							<!-- Partner Brand -->
							<div class="relative mb-4">
								<div class="h-16 w-16 bg-white rounded-2xl border-4 border-white shadow-xl flex items-center justify-center overflow-hidden">
									{#if partner.primary_provider?.profile_photo_url}
										<img src={partner.primary_provider.profile_photo_url} alt={partner.clinic_name} class="h-full w-full object-cover" />
									{:else}
										<Building class="h-8 w-8 text-gray-200" />
									{/if}
								</div>
								<div class="absolute -right-1 bottom-0 h-6 w-6 bg-black rounded-lg border-2 border-white flex items-center justify-center text-white shadow-lg">
									<Handshake class="h-3 w-3" />
								</div>
							</div>

							<!-- Details -->
							<div class="space-y-3">
								<div>
									<h3 class="text-xl font-black text-gray-900 leading-tight truncate">{partner.clinic_name}</h3>
									<p class="text-[10px] font-bold text-gray-400 uppercase tracking-tighter mt-0.5">Lead: Dr. {partner.primary_provider?.full_name}</p>
								</div>

								<div class="space-y-2 pt-1 border-t border-gray-50">
									<div class="flex items-center gap-2.5 text-xs font-bold text-gray-600">
										<div class="p-1.5 bg-gray-50 rounded-lg group-hover:bg-gray-100 transition-colors">
											<MapPin class="h-3.5 w-3.5" />
										</div>
										<span class="truncate">{partner.primary_provider?.region}, {partner.primary_provider?.country}</span>
									</div>
									<div class="flex items-center gap-2.5 text-xs font-bold text-gray-600">
										<div class="p-1.5 bg-gray-50 rounded-lg group-hover:bg-gray-100 transition-colors">
											<Calendar class="h-3.5 w-3.5" />
										</div>
										<span>Partnered {new Date(partner.created_at).toLocaleDateString()}</span>
									</div>
								</div>

								<!-- Alias Badge -->
								<div class="bg-gray-50 p-3 rounded-2xl border border-gray-100 group-hover:bg-gray-100 group-hover:border-gray-200 transition-all">
									<p class="text-[8px] font-black uppercase tracking-widest text-gray-400 mb-0.5">Your Alias</p>
									<p class="text-xs font-black text-black">{partner.alias}</p>
								</div>

								<div class="flex gap-2 pt-2">
									<button 
										class="flex-1 py-3 px-3 bg-gray-50 text-gray-900 text-xs font-black rounded-xl hover:bg-black hover:text-white transition-all active:scale-95 flex items-center justify-center gap-1.5"
									>
										<MessageSquare class="h-3.5 w-3.5" />
										Message
									</button>
									<button 
										class="py-3 px-3 bg-gray-50 text-gray-900 font-black rounded-xl hover:bg-black hover:text-white transition-all active:scale-95 shadow-sm"
										title="View Details"
									>
										<ArrowRight class="h-4 w-4" />
									</button>
								</div>
							</div>
						</div>
					</div>
				{/each}
			</div>
		{/if}
	</div>
</div>
