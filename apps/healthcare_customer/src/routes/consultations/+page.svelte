<script lang="ts">
	import { goto } from '$app/navigation';
	import { Calendar, Video, MessageSquare, Phone, MapPin, Clock, ChevronRight, Filter } from 'lucide-svelte';

	// Sample data - in production, fetch from Supabase
	const consultations = [
		{
			id: '1',
			provider: {
				name: 'Dr. Sarah Johnson',
				specialization: 'General Physician',
				photo: null
			},
			type: 'video',
			status: 'completed',
			date: '2026-03-10',
			time: '14:30',
			duration: '30 minutes',
			fee: 2500
		},
		{
			id: '2',
			provider: {
				name: 'Dr. Michael Chen',
				specialization: 'Cardiologist',
				photo: null
			},
			type: 'chat',
			status: 'scheduled',
			date: '2026-03-18',
			time: '10:00',
			duration: '20 minutes',
			fee: 3000
		}
	];

	let selectedStatus = $state('all');
	let selectedType = $state('all');

	let filteredConsultations = $derived.by(() => {
		return consultations.filter(c => {
			if (selectedStatus !== 'all' && c.status !== selectedStatus) return false;
			if (selectedType !== 'all' && c.type !== selectedType) return false;
			return true;
		});
	});

	function getStatusColor(status: string): string {
		const colors: Record<string, string> = {
			scheduled: 'bg-blue-100 text-blue-800',
			in_progress: 'bg-yellow-100 text-yellow-800',
			completed: 'bg-green-100 text-green-800',
			cancelled: 'bg-red-100 text-red-800'
		};
		return colors[status] || 'bg-gray-100 text-gray-800';
	}

	function formatDate(dateStr: string): string {
		const date = new Date(dateStr);
		return date.toLocaleDateString('en-NG', {
			year: 'numeric',
			month: 'short',
			day: 'numeric'
		});
	}

	function getTypeIcon(type: string) {
		const icons: Record<string, any> = {
			video: Video,
			chat: MessageSquare,
			audio: Phone,
			office_visit: MapPin
		};
		return icons[type] || Video;
	}
</script>

<svelte:head>
	<title>My Consultations | Kemani Health</title>
</svelte:head>

<div class="py-6 px-4 sm:px-6 lg:px-8">
	<div class="max-w-7xl mx-auto">
		<!-- Header -->
		<div class="mb-8">
			<h1 class="text-3xl font-bold text-gray-900">My Consultations</h1>
			<p class="mt-2 text-gray-600">View and manage your healthcare consultations</p>
		</div>

		<!-- Filters -->
		<div class="bg-white rounded-lg shadow p-6 mb-6">
			<div class="grid grid-cols-1 md:grid-cols-3 gap-4">
				<div>
					<label class="block text-sm font-medium text-gray-700 mb-2">
						<Filter class="inline w-4 h-4 mr-1" />
						Status
					</label>
					<select
						bind:value={selectedStatus}
						class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
					>
						<option value="all">All Status</option>
						<option value="scheduled">Scheduled</option>
						<option value="in_progress">In Progress</option>
						<option value="completed">Completed</option>
						<option value="cancelled">Cancelled</option>
					</select>
				</div>

				<div>
					<label class="block text-sm font-medium text-gray-700 mb-2">
						Consultation Type
					</label>
					<select
						bind:value={selectedType}
						class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
					>
						<option value="all">All Types</option>
						<option value="video">Video</option>
						<option value="chat">Chat</option>
						<option value="audio">Audio</option>
						<option value="office_visit">Office Visit</option>
					</select>
				</div>

				<div class="flex items-end">
					<button
						onclick={() => goto('/providers')}
						class="w-full px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-medium"
					>
						Book New Consultation
					</button>
				</div>
			</div>
		</div>

		<!-- Consultations List -->
		{#if filteredConsultations.length === 0}
			<div class="bg-white rounded-lg shadow p-12 text-center">
				<Calendar class="w-16 h-16 mx-auto mb-4 text-gray-400" />
				<h3 class="text-xl font-semibold text-gray-900 mb-2">No Consultations Found</h3>
				<p class="text-gray-600 mb-6">Get started by booking your first consultation</p>
				<button
					onclick={() => goto('/providers')}
					class="inline-block px-8 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-medium"
				>
					Find a Provider
				</button>
			</div>
		{:else}
			<div class="space-y-4">
				{#each filteredConsultations as consultation}
					<div
						class="bg-white rounded-lg shadow hover:shadow-lg transition p-6 cursor-pointer"
						onclick={() => goto(`/consultations/${consultation.id}`)}
					>
						<div class="flex items-start gap-6">
							<!-- Provider Photo -->
							<div class="flex-shrink-0">
								{#if consultation.provider.photo}
									<img
										src={consultation.provider.photo}
										alt={consultation.provider.name}
										class="w-16 h-16 rounded-full object-cover"
									/>
								{:else}
									<div class="w-16 h-16 rounded-full bg-blue-100 flex items-center justify-center">
										<span class="text-2xl font-bold text-blue-600">
											{consultation.provider.name.charAt(0)}
										</span>
									</div>
								{/if}
							</div>

							<!-- Consultation Details -->
							<div class="flex-1">
								<div class="flex items-start justify-between">
									<div>
										<h3 class="text-lg font-semibold text-gray-900">{consultation.provider.name}</h3>
										<p class="text-sm text-gray-600">{consultation.provider.specialization}</p>
									</div>

									<!-- Status Badge -->
									<span class="px-3 py-1 rounded-full text-xs font-medium {getStatusColor(consultation.status)} capitalize">
										{consultation.status.replace('_', ' ')}
									</span>
								</div>

								<div class="mt-4 grid grid-cols-2 md:grid-cols-4 gap-4">
									<!-- Type -->
									<div class="flex items-center gap-2 text-sm text-gray-600">
										<svelte:component this={getTypeIcon(consultation.type)} class="w-4 h-4" />
										<span class="capitalize">{consultation.type.replace('_', ' ')}</span>
									</div>

									<!-- Date -->
									<div class="flex items-center gap-2 text-sm text-gray-600">
										<Calendar class="w-4 h-4" />
										<span>{formatDate(consultation.date)}</span>
									</div>

									<!-- Time -->
									<div class="flex items-center gap-2 text-sm text-gray-600">
										<Clock class="w-4 h-4" />
										<span>{consultation.time}</span>
									</div>

									<!-- Fee -->
									<div class="text-sm font-medium text-gray-900">
										₦{consultation.fee.toLocaleString()}
									</div>
								</div>
							</div>

							<!-- Arrow -->
							<div class="flex-shrink-0">
								<ChevronRight class="w-6 h-6 text-gray-400" />
							</div>
						</div>
					</div>
				{/each}
			</div>
		{/if}
	</div>
</div>
