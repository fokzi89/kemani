<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { supabase } from '$lib/supabase';
	import { Calendar, Video, MessageSquare, Phone, CheckCircle, Clock, XCircle } from 'lucide-svelte';

	let provider = $state<any>(null);
	let consultations = $state<any[]>([]);
	let loading = $state(true);
	let filter = $state('all'); // all, pending, in_progress, completed

	let showNotTimePopup = $state(false);
	let showReschedulePopup = $state(false);
	let selectedConsultation = $state<any>(null);
	let rescheduleDate = $state('');
	let rescheduleTime = $state('');

	onMount(async () => {
		try {
			const { data: { session } } = await supabase.auth.getSession();

			if (session) {
				const { data: providerData } = await supabase
					.from('healthcare_providers')
					.select('*')
					.eq('user_id', session.user.id)
					.single();

				provider = providerData;

				if (provider) {
					await loadConsultations(provider.id);
				}
			}
		} catch (err) {
			console.error('Error in onMount:', err);
		} finally {
			loading = false;
		}
	});

	async function loadConsultations(providerId: string) {
		try {
			// 1. Get all clinics this doctor is a partner with
			const { data: partnerData, error: partnerError } = await supabase
				.from('doctor_aliases')
				.select('primary_doctor_id')
				.eq('doctor_id', providerId)
				.eq('accepted', true)
				.eq('is_active', true);

			if (partnerError) throw partnerError;

			const clinicIds = partnerData?.map(p => p.primary_doctor_id) || [];
			
			// 2. Build the query
			// We want consultations where I am the provider OR it belongs to a clinic I'm part of
			let orFilter = `provider_id.eq.${providerId},tenant_id.eq.${providerId}`;
			if (clinicIds.length > 0) {
				orFilter += `,tenant_id.in.(${clinicIds.join(',')})`;
			}

			let query = supabase
				.from('consultations')
				.select('*')
				.or(orFilter)
				.order('created_at', { ascending: false });

			if (filter !== 'all') {
				query = query.eq('status', filter);
			}

			const { data, error } = await query;
			if (error) throw error;
			
			consultations = data || [];
		} catch (err) {
			console.error('Error fetching consultations:', err);
		}
	}

	async function updateStatus(consultationId: string, newStatus: string) {
		const { error } = await supabase
			.from('consultations')
			.update({ status: newStatus })
			.eq('id', consultationId);

		if (!error && provider) {
			await loadConsultations(provider.id);
		}
	}

	function formatDate(dateString: string) {
		if (!dateString) return 'Not scheduled';
		return new Date(dateString).toLocaleDateString('en-US', {
			month: 'short',
			day: 'numeric',
			year: 'numeric',
			hour: '2-digit',
			minute: '2-digit'
		});
	}

	function getTypeIcon(type: string) {
		switch (type) {
			case 'video': return Video;
			case 'chat': return MessageSquare;
			case 'audio': return Phone;
			default: return Calendar;
		}
	}

	function getStatusColor(status: string) {
		switch (status) {
			case 'completed': return 'bg-green-100 text-green-800';
			case 'in_progress': return 'bg-blue-100 text-blue-800';
			case 'pending': return 'bg-yellow-100 text-yellow-800';
			case 'cancelled': return 'bg-red-100 text-red-800';
			default: return 'bg-gray-100 text-gray-800';
		}
	}

	function getReferralBadge(referralSource: string) {
		switch (referralSource) {
			case 'storefront':
				return { text: 'Referred by Storefront', color: 'bg-blue-100 text-blue-800', icon: '🛒' };
			case 'medic_clinic':
				return { text: 'Referred by Clinic', color: 'bg-purple-100 text-purple-800', icon: '🏥' };
			case 'pharmacy':
				return { text: 'Referred by Pharmacy', color: 'bg-green-100 text-green-800', icon: '💊' };
			case 'lab':
				return { text: 'Referred by Lab', color: 'bg-orange-100 text-orange-800', icon: '🔬' };
			default:
				return { text: 'Direct Patient', color: 'bg-gray-100 text-gray-800', icon: '👤' };
		}
	}

	async function handleFilterChange(newFilter: string) {
		filter = newFilter;
		if (provider) {
			loading = true;
			await loadConsultations(provider.id);
			loading = false;
		}
	}

	async function startConsultation(consultation: any) {
		if (consultation.scheduled_time) {
			const now = new Date();
			const scheduledDate = new Date(consultation.scheduled_time);
			const timeDiffMins = (scheduledDate.getTime() - now.getTime()) / (1000 * 60);

			if (timeDiffMins > 5) {
				showNotTimePopup = true;
				return;
			}
		}

		loading = true;
		
		try {
			// 1. Update status if pending
			if (consultation.status === 'pending') {
				const { error: statusError } = await supabase
					.from('consultations')
					.update({ status: 'in_progress' })
					.eq('id', consultation.id);
				
				if (statusError) throw statusError;
			}

			// 2. Pre-initialize Chat Conversation if it's a chat type
			if (consultation.type === 'chat') {
				const { data: existing } = await supabase
					.from('chat_conversations')
					.select('*')
					.eq('consultation_id', consultation.id)
					.single();

				if (!existing) {
					const { error: chatError } = await supabase
						.from('chat_conversations')
						.insert({
							consultation_id: consultation.id,
							tenant_id: consultation.tenant_id,
							branch_id: provider.id,
							customer_id: consultation.patient_id,
							status: 'active'
						});
					
					if (chatError) throw chatError;
				}
			}

			// 3. Navigate smoothly
			navigateToInteraction(consultation);
		} catch (err) {
			console.error('Error starting consultation:', err);
		} finally {
			loading = false;
		}
	}

	function navigateToInteraction(consultation: any) {
		const id = consultation.id;
		switch (consultation.type) {
			case 'chat':
				goto(`/chats/${id}`);
				break;
			case 'video':
				goto(`/consultations/video/${id}`);
				break;
			case 'audio':
				goto(`/consultations/audio/${id}`);
				break;
			default:
				goto(`/consultations/${id}`);
		}
	}

	function openReschedule(consultation: any) {
		selectedConsultation = consultation;
		showReschedulePopup = true;
	}

	function closeReschedule() {
		showReschedulePopup = false;
		selectedConsultation = null;
		rescheduleDate = '';
		rescheduleTime = '';
	}

	async function submitReschedule() {
		if (!rescheduleDate || !rescheduleTime || !selectedConsultation) return;
		
		const newDateTime = new Date(`${rescheduleDate}T${rescheduleTime}`);
		
		loading = true;
		try {
			const { error } = await supabase
				.from('consultations')
				.update({ scheduled_time: newDateTime.toISOString() })
				.eq('id', selectedConsultation.id);
				
			if (error) throw error;
			
			closeReschedule();
			
			if (provider) {
				await loadConsultations(provider.id);
			}
		} catch (err) {
			console.error('Error rescheduling:', err);
		} finally {
			loading = false;
		}
	}
</script>

<div class="min-h-screen p-6 lg:p-8">
	<div class="max-w-7xl mx-auto space-y-6">
		<!-- Header -->
		<div class="bg-white rounded-lg shadow p-6">
			<h2 class="text-2xl font-bold text-gray-900">Consultations</h2>
			<p class="text-gray-600 mt-1">Manage your patient consultations</p>
		</div>

	<!-- Filters -->
	<div class="bg-white rounded-lg shadow p-4">
		<div class="flex flex-wrap gap-2">
			<button
				onclick={() => handleFilterChange('all')}
				class="px-4 py-2 rounded-md transition-colors {filter === 'all' ? 'bg-primary-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}"
			>
				All
			</button>
			<button
				onclick={() => handleFilterChange('pending')}
				class="px-4 py-2 rounded-md transition-colors {filter === 'pending' ? 'bg-primary-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}"
			>
				Pending
			</button>
			<button
				onclick={() => handleFilterChange('in_progress')}
				class="px-4 py-2 rounded-md transition-colors {filter === 'in_progress' ? 'bg-primary-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}"
			>
				In Progress
			</button>
			<button
				onclick={() => handleFilterChange('completed')}
				class="px-4 py-2 rounded-md transition-colors {filter === 'completed' ? 'bg-primary-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}"
			>
				Completed
			</button>
		</div>
	</div>

	<!-- Consultations List -->
	{#if loading}
		<div class="bg-white rounded-lg shadow p-12 text-center">
			<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600 mx-auto"></div>
			<p class="mt-4 text-gray-600">Loading consultations...</p>
		</div>
	{:else if consultations.length === 0}
		<div class="bg-white rounded-lg shadow p-12 text-center">
			<Calendar class="h-16 w-16 text-gray-300 mx-auto mb-4" />
			<h3 class="text-lg font-medium text-gray-900 mb-2">No consultations found</h3>
			<p class="text-gray-600">
				{#if filter === 'all'}
					You don't have any consultations yet.
				{:else}
					No {filter} consultations at the moment.
				{/if}
			</p>
		</div>
	{:else}
		<div class="space-y-4">
			{#each consultations as consultation}
				{@const badge = getReferralBadge(consultation.referral_source || 'direct')}
				{@const Icon = getTypeIcon(consultation.type)}
				<div class="bg-white rounded-lg shadow hover:shadow-md transition-shadow">
					<div class="p-6">
						<div class="flex items-start justify-between">
							<div class="flex items-start gap-4 flex-1">
								<!-- Icon -->
								<div class="bg-primary-100 p-3 rounded-full flex-shrink-0">
									<Icon class="h-6 w-6 text-primary-600" />
								</div>

								<!-- Details -->
								<div class="flex-1 min-w-0">
									<div class="flex items-center gap-3 mb-2 flex-wrap">
										<h3 class="text-lg font-semibold text-gray-900">
											{consultation.provider_name || 'Patient'}
										</h3>
										{#if consultation.tenant_id !== provider?.id}
											<span class="px-2 py-0.5 text-[10px] font-black uppercase tracking-widest bg-gray-900 text-white rounded-md">
												Clinic Assignment
											</span>
										{/if}
										<span class="px-2 py-1 text-xs font-semibold rounded-full {getStatusColor(consultation.status)}">
											{consultation.status}
										</span>
										<span class="px-2 py-1 text-xs font-semibold rounded-full {badge.color}">
											{badge.icon} {badge.text}
										</span>
									</div>

									<div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-gray-600">
										<div>
											<span class="font-medium">Type:</span> {consultation.type}
										</div>
										<div>
											<span class="font-medium">Fee:</span> ₦{consultation.consultation_fee?.toLocaleString() || '0'}
										</div>
										<div>
											<span class="font-medium">Scheduled:</span> {formatDate(consultation.scheduled_time)}
										</div>
										<div>
											<span class="font-medium">Payment:</span>
											<span class="capitalize">{consultation.payment_status}</span>
										</div>
									</div>

									{#if consultation.agora_channel_name}
										<div class="mt-3 p-3 bg-blue-50 rounded-md text-sm">
											<span class="font-medium text-blue-900">Channel:</span>
											<span class="text-blue-700 font-mono">{consultation.agora_channel_name}</span>
										</div>
									{/if}
								</div>
							</div>

							<div class="flex flex-col gap-2 ml-4">
								{#if consultation.status === 'pending'}
									{@const nowTime = new Date().getTime()}
									{@const schedTime = consultation.scheduled_time ? new Date(consultation.scheduled_time).getTime() : nowTime}
									
									<button
										onclick={() => startConsultation(consultation)}
										class="px-4 py-2 bg-gray-900 text-white text-sm font-bold rounded-xl hover:bg-black transition-all flex items-center justify-center gap-2 shadow-md shadow-gray-200"
									>
										<Clock class="h-4 w-4" />
										Start
									</button>

									{#if nowTime > schedTime}
										<button
											onclick={() => openReschedule(consultation)}
											class="px-4 py-2 border-2 border-gray-900 text-gray-900 text-sm font-bold rounded-xl hover:bg-gray-50 transition-all flex items-center justify-center gap-2"
										>
											<Calendar class="h-4 w-4" />
											Reschedule
										</button>
									{/if}
								{/if}

								{#if consultation.status === 'in_progress'}
									<button
										onclick={() => navigateToInteraction(consultation)}
										class="px-4 py-2 bg-gray-900 text-white text-sm font-bold rounded-xl hover:bg-black transition-all flex items-center justify-center gap-2 shadow-md shadow-gray-200"
									>
										{#if consultation.type === 'video'}<Video class="h-4 w-4" />{:else if consultation.type === 'chat'}<MessageSquare class="h-4 w-4" />{:else}<Phone class="h-4 w-4" />{/if}
										Continue
									</button>
									<button
										onclick={() => updateStatus(consultation.id, 'completed')}
										class="px-4 py-2 border-2 border-gray-900 text-gray-900 text-sm font-bold rounded-xl hover:bg-gray-50 transition-all flex items-center justify-center gap-2"
									>
										<CheckCircle class="h-4 w-4" />
										Complete
									</button>
								{/if}

								{#if consultation.status !== 'cancelled' && consultation.status !== 'completed'}
									<button
										onclick={() => updateStatus(consultation.id, 'cancelled')}
										class="px-4 py-2 border-2 border-red-100 text-red-600 text-sm font-bold rounded-xl hover:bg-red-50 hover:border-red-200 transition-all flex items-center justify-center gap-2"
									>
										<XCircle class="h-4 w-4" />
										Cancel
									</button>
								{/if}

								<a
									href="/consultations/{consultation.id}"
									class="px-4 py-2 text-gray-500 hover:text-gray-700 text-xs font-bold text-center transition-colors"
								>
									View Full Details
								</a>
							</div>
						</div>
					</div>
				</div>
			{/each}
		</div>
	{/if}
	</div>
</div>

<!-- Not Time Popup -->
{#if showNotTimePopup}
	<div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-gray-900/50 backdrop-blur-sm">
		<div class="bg-white rounded-2xl shadow-xl max-w-sm w-full overflow-hidden">
			<div class="p-6 text-center text-gray-900">
				<div class="mx-auto w-12 h-12 bg-yellow-100 text-yellow-600 rounded-full flex items-center justify-center mb-4">
					<Clock class="w-6 h-6" />
				</div>
				<h3 class="text-xl font-bold mb-2">Not Yet Time</h3>
				<p class="text-gray-600 mb-6">
					You can only start the consultation within 5 minutes of the scheduled time. Return closer to the appointment time.
				</p>
				<button
					onclick={() => showNotTimePopup = false}
					class="w-full bg-gray-900 text-white py-3 rounded-xl font-bold hover:bg-black transition-colors"
				>
					Okay
				</button>
			</div>
		</div>
	</div>
{/if}

<!-- Reschedule Popup -->
{#if showReschedulePopup}
	<div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-gray-900/50 backdrop-blur-sm">
		<div class="bg-white rounded-2xl shadow-xl max-w-md w-full overflow-hidden">
			<div class="p-6">
				<div class="flex justify-between items-center mb-6">
					<h3 class="text-xl font-bold text-gray-900">Reschedule Consultation</h3>
					<button onclick={closeReschedule} class="text-gray-400 hover:text-gray-600 transition-colors">
						<XCircle class="w-6 h-6" />
					</button>
				</div>
				
				<div class="space-y-4 mb-6 text-gray-900">
					<div>
						<label class="block text-sm font-semibold mb-1" for="reschedule_date">New Date</label>
						<input
							type="date"
							id="reschedule_date"
							bind:value={rescheduleDate}
							class="w-full px-4 py-3 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all"
						/>
					</div>
					<div>
						<label class="block text-sm font-semibold mb-1" for="reschedule_time">New Time</label>
						<input
							type="time"
							id="reschedule_time"
							bind:value={rescheduleTime}
							class="w-full px-4 py-3 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all"
						/>
					</div>
				</div>

				<div class="flex gap-3">
					<button
						onclick={closeReschedule}
						class="flex-1 py-3 bg-gray-100 text-gray-700 rounded-xl font-bold hover:bg-gray-200 transition-colors"
					>
						Cancel
					</button>
					<button
						onclick={submitReschedule}
						disabled={!rescheduleDate || !rescheduleTime}
						class="flex-1 py-3 bg-primary-600 text-white rounded-xl font-bold hover:bg-primary-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
					>
						Reschedule
					</button>
				</div>
			</div>
		</div>
	</div>
{/if}
