<script lang="ts">
	import { page } from '$app/stores';
	import { supabase } from '$lib/supabase';
	import { onMount } from 'svelte';
	import { ArrowLeft, Clock, Calendar, Video, MessageSquare, Phone, FileText, CheckCircle, XCircle, CreditCard, Stethoscope, User } from 'lucide-svelte';

	let consultation = $state<any>(null);
	let loading = $state(true);
	let prescriptions = $state<any[]>([]);

	const id = $derived($page.params.id);

	onMount(async () => {
		try {
			// 1. Get consultation details
			const { data: consultData, error } = await supabase
				.from('consultations')
				.select(`
					*,
					profiles:patient_id(full_name, avatar_url, phone, email)
				`)
				.eq('id', id)
				.single();

			if (!error && consultData) {
				consultation = consultData;
				
				// 2. Get related prescriptions
				const { data: rxData } = await supabase
					.from('prescriptions')
					.select('*')
					.eq('consultation_id', id)
					.order('created_at', { ascending: false });
				
				prescriptions = rxData || [];
			}
		} catch (err) {
			console.error('Error fetching consultation details:', err);
		} finally {
			loading = false;
		}
	});

	function formatDate(dateStr: string) {
		if (!dateStr) return 'Not scheduled';
		return new Date(dateStr).toLocaleString('en-US', {
			weekday: 'long',
			month: 'long',
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
</script>

<div class="min-h-screen bg-gray-50 p-6 lg:p-8">
	<div class="max-w-5xl mx-auto space-y-6">
		<!-- Header -->
		<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
			<div class="flex items-center gap-4">
				<a
					href="/consultations"
					class="p-2 hover:bg-gray-100 rounded-xl transition-all text-gray-500 hover:text-gray-900"
				>
					<ArrowLeft class="h-6 w-6" />
				</a>
				<div>
					<h2 class="text-2xl font-bold text-gray-900 flex items-center gap-3">
						Consultation Details
						{#if consultation}
							<span class="px-3 py-1 text-xs font-semibold rounded-full {getStatusColor(consultation.status)} capitalize">
								{consultation.status}
							</span>
						{/if}
					</h2>
					<p class="text-gray-500 mt-1 text-sm font-medium">Review patient interaction and clinical notes</p>
				</div>
			</div>
		</div>

		{#if loading}
			<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-12 flex flex-col items-center justify-center">
				<div class="animate-spin rounded-full h-12 w-12 border-4 border-gray-100 border-t-gray-900 mb-4"></div>
				<p class="text-gray-500 font-medium">Loading details...</p>
			</div>
		{:else if !consultation}
			<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-12 text-center">
				<Calendar class="h-16 w-16 text-gray-300 mx-auto mb-4" />
				<h3 class="text-lg font-bold text-gray-900">Consultation Not Found</h3>
				<p class="text-gray-500 mt-2">This consultation record does not exist or you don't have access.</p>
				<a href="/consultations" class="inline-block mt-6 px-6 py-2 bg-gray-900 text-white rounded-xl font-bold hover:bg-black transition-all">
					Go Back
				</a>
			</div>
		{:else}
			<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
				<!-- Quick Actions / Context (Left Sidebar) -->
				<div class="space-y-6">
					<!-- Patient Card -->
					<div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
						<div class="p-6 text-center border-b border-gray-100 bg-gradient-to-b from-gray-50 to-white">
							<div class="h-24 w-24 mx-auto rounded-full bg-white shadow-md border-4 border-white overflow-hidden mb-4 flex items-center justify-center">
								{#if consultation.profiles?.avatar_url}
									<img src={consultation.profiles.avatar_url} alt="" class="h-full w-full object-cover" />
								{:else}
									<User class="h-10 w-10 text-gray-400" />
								{/if}
							</div>
							<h3 class="text-lg font-bold text-gray-900">
								{consultation.profiles?.full_name || 'Anonymous Patient'}
							</h3>
							<p class="text-sm text-gray-500 mt-1 font-medium text-wrap break-all">
								{consultation.profiles?.email || 'No email provided'}
							</p>
						</div>
						<div class="p-6 space-y-4">
							<a 
								href="/chats/{consultation.id}" 
								class="w-full flex items-center justify-center gap-2 py-3 bg-gray-900 text-white rounded-xl font-bold hover:bg-black transition-all shadow-md shadow-gray-200"
							>
								<MessageSquare class="h-4 w-4" />
								Open Interaction Hub
							</a>
							{#if consultation.status === 'in_progress'}
								<a 
									href="/prescriptions/add?consultation={consultation.id}" 
									class="w-full flex items-center justify-center gap-2 py-3 bg-white border-2 border-gray-200 text-gray-900 rounded-xl font-bold hover:border-gray-900 hover:bg-gray-50 transition-all"
								>
									<FileText class="h-4 w-4" />
									Write Prescription
								</a>
							{/if}
						</div>
					</div>

					<!-- Payment Info -->
					<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
						<h3 class="flex items-center gap-2 text-sm font-bold text-gray-900 uppercase tracking-wider mb-4">
							<CreditCard class="h-4 w-4 text-gray-400" />
							Financial
						</h3>
						<div class="space-y-3 font-medium">
							<div class="flex justify-between items-center text-sm">
								<span class="text-gray-500">Consultation Fee</span>
								<span class="text-gray-900 text-lg font-bold">₦{consultation.consultation_fee?.toLocaleString()}</span>
							</div>
							<div class="flex justify-between items-center text-sm">
								<span class="text-gray-500">Payment Status</span>
								<span class="px-2 py-0.5 text-xs font-bold rounded-md capitalize {consultation.payment_status === 'paid' ? 'bg-emerald-100 text-emerald-800' : 'bg-gray-100 text-gray-800'}">
									{consultation.payment_status || 'Pending'}
								</span>
							</div>
						</div>
					</div>
				</div>

				<!-- Detailed Info (Main Content) -->
				<div class="lg:col-span-2 space-y-6">
					
					<!-- Overview Specs -->
					<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
						<h3 class="flex items-center gap-2 text-sm font-bold text-gray-900 uppercase tracking-wider mb-6">
							<Stethoscope class="h-4 w-4 text-gray-400" />
							Session Overview
						</h3>
						
						<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
							<div class="space-y-1">
								<p class="text-xs font-bold text-gray-400 uppercase tracking-widest">Type</p>
								<div class="flex items-center gap-2 font-bold text-gray-900 capitalize">
									{#if true}
										{@const Icon = getTypeIcon(consultation.type)}
										<Icon class="h-4 w-4 text-primary-500" />
									{/if}
									{consultation.type} Consultation
								</div>
							</div>
							<div class="space-y-1">
								<p class="text-xs font-bold text-gray-400 uppercase tracking-widest">Scheduled For</p>
								<div class="flex items-center gap-2 font-medium text-gray-900">
									<Clock class="h-4 w-4 text-gray-400" />
									{formatDate(consultation.scheduled_time)}
								</div>
							</div>
							<div class="space-y-1">
								<p class="text-xs font-bold text-gray-400 uppercase tracking-widest">System Reference</p>
								<div class="font-mono text-xs text-gray-500 bg-gray-50 p-2 rounded-lg border border-gray-100">
									{consultation.id}
								</div>
							</div>
							<div class="space-y-1">
								<p class="text-xs font-bold text-gray-400 uppercase tracking-widest">Referral Origin</p>
								<div class="font-medium text-gray-900 capitalize">
									{consultation.referral_source || 'Direct Clinic Patient'}
								</div>
							</div>
						</div>
					</div>

					<!-- Prescriptions List -->
					<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
						<div class="flex items-center justify-between mb-6">
							<h3 class="flex items-center gap-2 text-sm font-bold text-gray-900 uppercase tracking-wider">
								<FileText class="h-4 w-4 text-gray-400" />
								Session Prescriptions
							</h3>
						</div>

						{#if prescriptions.length === 0}
							<div class="text-center py-8 bg-gray-50 rounded-xl border border-dashed border-gray-200">
								<FileText class="h-8 w-8 text-gray-300 mx-auto mb-2" />
								<p class="text-sm text-gray-500 font-medium">No prescriptions recorded yet.</p>
							</div>
						{:else}
							<div class="space-y-3">
								{#each prescriptions as rx}
									<a 
										href="/prescriptions/edit/{rx.id}"
										class="block p-4 rounded-xl border border-gray-100 hover:border-gray-300 hover:shadow-md transition-all group"
									>
										<div class="flex justify-between items-start mb-2">
											<h4 class="font-bold text-gray-900 group-hover:text-primary-600 transition-colors">
												{rx.diagnosis || 'General Prescription'}
											</h4>
											<span class="px-2 py-1 text-[10px] font-black uppercase tracking-widest rounded-full {rx.status === 'active' ? 'bg-blue-100 text-blue-800' : 'bg-gray-100 text-gray-600'}">
												{rx.status}
											</span>
										</div>
										<p class="text-xs text-gray-500 font-medium">
											{rx.medications?.length || 0} medications prescribed • Issued {new Date(rx.issue_date).toLocaleDateString()}
										</p>
									</a>
								{/each}
							</div>
						{/if}
					</div>

				</div>
			</div>
		{/if}
	</div>
</div>
