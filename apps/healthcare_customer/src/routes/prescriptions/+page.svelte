<script lang="ts">
	import { goto } from '$app/navigation';
	import { FileText, Calendar, User, Download, ShoppingBag, Clock } from 'lucide-svelte';

	// Sample data - in production, fetch from Supabase
	const prescriptions = [
		{
			id: '1',
			doctor: 'Dr. Sarah Johnson',
			consultation_date: '2026-03-10',
			issue_date: '2026-03-10',
			status: 'active',
			medications: [
				{ name: 'Amoxicillin 500mg', dosage: '3 times daily', duration: '7 days', quantity: '21 capsules' },
				{ name: 'Paracetamol 500mg', dosage: '2 times daily', duration: '5 days', quantity: '10 tablets' }
			],
			fulfillment: {
				status: 'pending',
				pharmacy: null
			}
		},
		{
			id: '2',
			doctor: 'Dr. Michael Chen',
			consultation_date: '2026-03-01',
			issue_date: '2026-03-01',
			status: 'fulfilled',
			medications: [
				{ name: 'Lisinopril 10mg', dosage: '1 time daily', duration: '30 days', quantity: '30 tablets' }
			],
			fulfillment: {
				status: 'fulfilled',
				pharmacy: 'Fokz Pharmacy',
				fulfilled_date: '2026-03-02'
			}
		}
	];

	function getStatusColor(status: string): string {
		const colors: Record<string, string> = {
			active: 'bg-blue-100 text-blue-800',
			fulfilled: 'bg-green-100 text-green-800',
			expired: 'bg-gray-100 text-gray-800',
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
</script>

<svelte:head>
	<title>My Prescriptions | Kemani Health</title>
</svelte:head>

<div class="py-6 px-4 sm:px-6 lg:px-8">
	<div class="max-w-7xl mx-auto">
		<!-- Header -->
		<div class="mb-8">
			<h1 class="text-3xl font-bold text-gray-900">My Prescriptions</h1>
			<p class="mt-2 text-gray-600">View and manage your medical prescriptions</p>
		</div>

		<!-- Prescriptions List -->
		{#if prescriptions.length === 0}
			<div class="bg-white rounded-lg shadow p-12 text-center">
				<FileText class="w-16 h-16 mx-auto mb-4 text-gray-400" />
				<h3 class="text-xl font-semibold text-gray-900 mb-2">No Prescriptions Yet</h3>
				<p class="text-gray-600 mb-6">Prescriptions from your consultations will appear here</p>
				<button
					onclick={() => goto('/providers')}
					class="inline-block px-8 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-medium"
				>
					Book a Consultation
				</button>
			</div>
		{:else}
			<div class="space-y-6">
				{#each prescriptions as prescription}
					<div class="bg-white rounded-lg shadow p-6">
						<!-- Prescription Header -->
						<div class="flex items-start justify-between mb-6">
							<div>
								<h3 class="text-lg font-semibold text-gray-900">Prescription #{prescription.id}</h3>
								<div class="mt-2 flex items-center gap-4 text-sm text-gray-600">
									<div class="flex items-center gap-1">
										<User class="w-4 h-4" />
										<span>{prescription.doctor}</span>
									</div>
									<div class="flex items-center gap-1">
										<Calendar class="w-4 h-4" />
										<span>Issued: {formatDate(prescription.issue_date)}</span>
									</div>
								</div>
							</div>

							<!-- Status Badge -->
							<span class="px-3 py-1 rounded-full text-xs font-medium {getStatusColor(prescription.status)} capitalize">
								{prescription.status}
							</span>
						</div>

						<!-- Medications -->
						<div class="border-t border-gray-200 pt-4 mb-4">
							<h4 class="font-medium text-gray-900 mb-3">Medications</h4>
							<div class="space-y-3">
								{#each prescription.medications as med}
									<div class="flex items-start gap-3 p-3 bg-gray-50 rounded-lg">
										<div class="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center flex-shrink-0">
											<FileText class="w-5 h-5 text-blue-600" />
										</div>
										<div class="flex-1">
											<p class="font-medium text-gray-900">{med.name}</p>
											<div class="mt-1 grid grid-cols-1 md:grid-cols-3 gap-2 text-sm text-gray-600">
												<div>
													<span class="font-medium">Dosage:</span> {med.dosage}
												</div>
												<div>
													<span class="font-medium">Duration:</span> {med.duration}
												</div>
												<div>
													<span class="font-medium">Quantity:</span> {med.quantity}
												</div>
											</div>
										</div>
									</div>
								{/each}
							</div>
						</div>

						<!-- Fulfillment Status -->
						<div class="border-t border-gray-200 pt-4">
							{#if prescription.fulfillment.status === 'fulfilled'}
								<div class="flex items-center justify-between">
									<div class="flex items-center gap-2 text-sm text-green-600">
										<ShoppingBag class="w-4 h-4" />
										<span>Fulfilled by <strong>{prescription.fulfillment.pharmacy}</strong> on {formatDate(prescription.fulfillment.fulfilled_date)}</span>
									</div>
									<button class="text-sm text-blue-600 hover:underline flex items-center gap-1">
										<Download class="w-4 h-4" />
										Download Receipt
									</button>
								</div>
							{:else}
								<div class="flex items-center justify-between">
									<div class="flex items-center gap-2 text-sm text-gray-600">
										<Clock class="w-4 h-4" />
										<span>Pending fulfillment</span>
									</div>
									<button
										onclick={() => goto('/providers?type=pharmacist')}
										class="px-4 py-2 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700 transition"
									>
										Order Medications
									</button>
								</div>
							{/if}
						</div>
					</div>
				{/each}
			</div>
		{/if}
	</div>
</div>
