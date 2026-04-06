<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { 
		ArrowLeft, 
		Building, 
		CheckCircle, 
		XCircle, 
		Loader2,
		Inbox,
		Calendar,
		MapPin,
		User
	} from 'lucide-svelte';
	import { goto } from '$app/navigation';

	let invites = $state<any[]>([]);
	let loading = $state(true);
	let processingId = $state<string | null>(null);
	let providerId = $state<string | null>(null);

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) {
			goto('/auth/login');
			return;
		}

		// Get current provider ID
		const { data: providerData } = await supabase
			.from('healthcare_providers')
			.select('id')
			.eq('user_id', session.user.id)
			.single();
		
		if (providerData) {
			providerId = providerData.id;
			await loadInvites();
		}
		loading = false;
	});

	async function loadInvites() {
		if (!providerId) return;
		
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
					clinic_address
				)
			`)
			.eq('doctor_id', providerId)
			.eq('accepted', false)
			.eq('is_active', true);

		if (error) {
			console.error('Error loading invites:', error);
		} else {
			invites = data || [];
		}
	}

	async function acceptInvite(inviteId: string) {
		processingId = inviteId;
		try {
			const { error } = await supabase
				.from('doctor_aliases')
				.update({ accepted: true } as any)
				.eq('id', inviteId);

			if (error) throw error;
			
			// Remove from local list
			invites = invites.filter(i => i.id !== inviteId);
			alert('Invitation accepted! You are now a partner with this clinic.');
		} catch (err: any) {
			alert('Error accepting invitation: ' + err.message);
		} finally {
			processingId = null;
		}
	}

	async function declineInvite(inviteId: string) {
		if (!confirm('Are you sure you want to decline this invitation?')) return;
		
		processingId = inviteId;
		try {
			const { error } = await supabase
				.from('doctor_aliases')
				.delete()
				.eq('id', inviteId);

			if (error) throw error;
			
			invites = invites.filter(i => i.id !== inviteId);
		} catch (err: any) {
			alert('Error declining invitation: ' + err.message);
		} finally {
			processingId = null;
		}
	}
</script>

<div class="min-h-screen bg-gray-50/50 p-6 lg:p-8">
	<div class="max-w-4xl mx-auto space-y-6">
		<!-- Header -->
		<div class="flex items-center justify-between">
			<button 
				onclick={() => goto('/settings')}
				class="flex items-center gap-2 text-gray-500 hover:text-black font-bold transition-all group text-sm"
			>
				<ArrowLeft class="h-4 w-4 group-hover:-translate-x-1 transition-transform" />
				Back to Settings
			</button>
			<h1 class="text-xl font-black text-gray-900">Clinic Invitations</h1>
		</div>

		{#if loading}
			<div class="bg-white rounded-2xl border border-gray-100 p-12 text-center shadow-sm">
				<Loader2 class="h-10 w-10 animate-spin text-black mx-auto" />
				<p class="mt-4 text-gray-600 text-sm font-medium">Checking for invitations...</p>
			</div>
		{:else if invites.length === 0}
			<div class="bg-white rounded-2xl border border-gray-100 p-12 text-center shadow-sm">
				<div class="h-16 w-16 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-4">
					<Inbox class="h-8 w-8 text-gray-300" />
				</div>
				<h2 class="text-lg font-black text-gray-900">No Pending Invites</h2>
				<p class="text-gray-500 text-sm mt-1 max-w-sm mx-auto font-medium">
					When clinics invite you to partner with them, their requests will appear here.
				</p>
			</div>
		{:else}
			<div class="grid gap-4">
				{#each invites as invite}
					<div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden hover:border-black/10 transition-all">
						<div class="p-5 sm:p-6">
							<div class="flex flex-col sm:flex-row gap-5 items-start sm:items-center">
								<!-- Clinic Info -->
								<div class="h-12 w-12 bg-black rounded-xl flex items-center justify-center flex-shrink-0 shadow-lg text-white font-black text-xl">
									{invite.clinic_name?.[0]?.toUpperCase() || 'C'}
								</div>
								
								<div class="flex-1 space-y-0.5">
									<h3 class="text-lg font-black text-gray-900">{invite.clinic_name || 'Unnamed Clinic'}</h3>
									<div class="flex flex-wrap gap-3 text-xs text-gray-500 font-medium">
										<div class="flex items-center gap-1.5">
											<User class="h-3 w-3" />
											Invited by Dr. {invite.primary_provider?.full_name}
										</div>
										<div class="flex items-center gap-1.5">
											<Calendar class="h-3 w-3" />
											{new Date(invite.created_at).toLocaleDateString()}
										</div>
									</div>
									<p class="text-[10px] font-bold text-black bg-gray-100 inline-block px-2 py-0.5 rounded-md mt-2">
										AS: {invite.alias}
									</p>
								</div>

								<!-- Actions -->
								<div class="flex items-center gap-2 w-full sm:w-auto pt-3 sm:pt-0">
									<button 
										onclick={() => declineInvite(invite.id)}
										disabled={processingId === invite.id}
										class="flex-1 sm:flex-none px-4 py-2 border border-gray-200 text-gray-600 text-sm font-bold rounded-xl hover:bg-red-50 hover:text-red-600 hover:border-red-100 transition-all active:scale-95 disabled:opacity-50"
									>
										Decline
									</button>
									<button 
										onclick={() => acceptInvite(invite.id)}
										disabled={processingId === invite.id}
										class="flex-1 sm:flex-none px-6 py-2 bg-black text-white text-sm font-black rounded-xl hover:bg-gray-800 shadow-xl shadow-black/10 transition-all active:scale-95 disabled:opacity-50 flex items-center justify-center gap-2"
									>
										{#if processingId === invite.id}
											<Loader2 class="h-4 w-4 animate-spin" />
											Accepting...
										{:else}
											<CheckCircle class="h-3.5 w-3.5" />
											Accept Invite
										{/if}
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
