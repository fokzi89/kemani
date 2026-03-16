<script lang="ts">
	import { goto } from '$app/navigation';
	import { Star, Video, MessageSquare, Phone, MapPin, Calendar, Clock, ArrowLeft, CreditCard } from 'lucide-svelte';
	import type { PageData } from './$types';

	export let data: PageData;

	let { provider, slots } = $derived(data);

	// Booking state
	let selectedType = $state('');
	let selectedDate = $state('');
	let selectedSlot = $state<any>(null);
	let bookingStep = $state<'type' | 'datetime' | 'payment'>('type');

	// Group slots by date
	let slotsByDate = $derived.by(() => {
		const grouped: Record<string, any[]> = {};
		slots.forEach(slot => {
			if (!grouped[slot.date]) {
				grouped[slot.date] = [];
			}
			grouped[slot.date].push(slot);
		});
		return grouped;
	});

	// Available dates
	let availableDates = $derived(Object.keys(slotsByDate).sort());

	// Slots for selected date and type
	let availableSlots = $derived.by(() => {
		if (!selectedDate || !selectedType) return [];
		return slotsByDate[selectedDate]?.filter(s => s.consultation_type === selectedType) || [];
	});

	function formatFee(type: string): string {
		const fees = provider.fees;
		if (!fees || typeof fees !== 'object') return '0';
		const amount = fees[type] || 0;
		return amount.toLocaleString();
	}

	function formatDate(dateStr: string): string {
		const date = new Date(dateStr);
		return date.toLocaleDateString('en-NG', {
			weekday: 'short',
			year: 'numeric',
			month: 'short',
			day: 'numeric'
		});
	}

	function formatTime(timeStr: string): string {
		const [hours, minutes] = timeStr.split(':');
		const hour = parseInt(hours);
		const ampm = hour >= 12 ? 'PM' : 'AM';
		const displayHour = hour > 12 ? hour - 12 : hour === 0 ? 12 : hour;
		return `${displayHour}:${minutes} ${ampm}`;
	}

	function selectType(type: string) {
		selectedType = type;
		selectedDate = '';
		selectedSlot = null;
		bookingStep = 'datetime';
	}

	function selectSlot(slot: any) {
		selectedSlot = slot;
	}

	async function proceedToPayment() {
		if (!selectedSlot) return;
		bookingStep = 'payment';
	}

	async function confirmBooking() {
		// TODO: Integrate payment gateway (Paystack/Flutterwave)
		// For now, just navigate to consultations
		alert('Payment integration coming soon! Your booking would be confirmed here.');
		goto('/consultations');
	}
</script>

<svelte:head>
	<title>Book {provider.full_name} | Kemani Health</title>
</svelte:head>

<div class="min-h-screen theme-bg">
	<!-- Header -->
	<header class="theme-nav border-b">
		<div class="max-w-7xl mx-auto px-4 py-4">
			<button
				onclick={() => goto('/providers')}
				class="flex items-center gap-2 theme-text-muted hover:theme-text transition"
			>
				<ArrowLeft class="w-5 h-5" />
				Back to Providers
			</button>
		</div>
	</header>

	<main class="max-w-7xl mx-auto px-4 py-8">
		<div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
			<!-- Left: Provider Info (Sticky) -->
			<div class="lg:col-span-1">
				<div class="theme-card rounded-lg p-6 sticky top-24">
					<!-- Provider Photo -->
					<div class="text-center mb-6">
						{#if provider.profile_photo_url}
							<img
								src={provider.profile_photo_url}
								alt={provider.full_name}
								class="w-32 h-32 rounded-full object-cover mx-auto mb-4"
							/>
						{:else}
							<div class="w-32 h-32 rounded-full bg-blue-100 flex items-center justify-center mx-auto mb-4">
								<span class="text-4xl font-bold text-blue-600">
									{provider.full_name.charAt(0)}
								</span>
							</div>
						{/if}

						<h2 class="text-xl font-bold theme-text">{provider.full_name}</h2>
						{#if provider.credentials}
							<p class="theme-text-muted">{provider.credentials}</p>
						{/if}
					</div>

					<!-- Specialization -->
					<div class="mb-4">
						<p class="font-medium theme-text text-center">{provider.specialization}</p>
						<p class="text-sm theme-text-muted text-center capitalize">{provider.type}</p>
					</div>

					<!-- Rating & Stats -->
					<div class="flex items-center justify-center gap-4 mb-6">
						<div class="flex items-center gap-1">
							<Star class="w-5 h-5 text-yellow-500 fill-yellow-500" />
							<span class="theme-text font-medium">{provider.average_rating.toFixed(1)}</span>
							<span class="theme-text-muted text-sm">({provider.total_reviews})</span>
						</div>
						<span class="theme-text-muted text-sm">
							{provider.total_consultations} consultations
						</span>
					</div>

					<!-- Bio -->
					{#if provider.bio}
						<div class="border-t theme-border pt-4">
							<h3 class="font-medium theme-text mb-2">About</h3>
							<p class="text-sm theme-text-muted">{provider.bio}</p>
						</div>
					{/if}

					<!-- Experience -->
					<div class="border-t theme-border pt-4 mt-4">
						<h3 class="font-medium theme-text mb-2">Experience</h3>
						<p class="text-sm theme-text">{provider.years_of_experience} years</p>
					</div>
				</div>
			</div>

			<!-- Right: Booking Form -->
			<div class="lg:col-span-2">
				<div class="theme-card rounded-lg p-6">
					<h1 class="text-2xl font-bold theme-text mb-6">Book a Consultation</h1>

					<!-- Progress Steps -->
					<div class="flex items-center gap-4 mb-8">
						<div class={`flex-1 h-2 rounded ${bookingStep === 'type' ? 'bg-blue-600' : 'bg-gray-200'}`}></div>
						<div class={`flex-1 h-2 rounded ${bookingStep === 'datetime' ? 'bg-blue-600' : 'bg-gray-200'}`}></div>
						<div class={`flex-1 h-2 rounded ${bookingStep === 'payment' ? 'bg-blue-600' : 'bg-gray-200'}`}></div>
					</div>

					<!-- Step 1: Select Consultation Type -->
					{#if bookingStep === 'type'}
						<div>
							<h2 class="text-xl font-semibold theme-text mb-4">Select Consultation Type</h2>
							<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
								{#if provider.consultation_types.includes('chat')}
									<button
										onclick={() => selectType('chat')}
										class="theme-card border-2 theme-border p-6 rounded-lg hover:border-blue-500 transition text-left"
									>
										<div class="flex items-start gap-4">
											<div class="p-3 bg-green-100 rounded-lg">
												<MessageSquare class="w-6 h-6 text-green-600" />
											</div>
											<div class="flex-1">
												<h3 class="font-semibold theme-text mb-1">Chat Consultation</h3>
												<p class="text-sm theme-text-muted mb-3">Instant messaging with the provider</p>
												<p class="text-lg font-bold text-blue-600">₦{formatFee('chat')}</p>
											</div>
										</div>
									</button>
								{/if}

								{#if provider.consultation_types.includes('video')}
									<button
										onclick={() => selectType('video')}
										class="theme-card border-2 theme-border p-6 rounded-lg hover:border-blue-500 transition text-left"
									>
										<div class="flex items-start gap-4">
											<div class="p-3 bg-blue-100 rounded-lg">
												<Video class="w-6 h-6 text-blue-600" />
											</div>
											<div class="flex-1">
												<h3 class="font-semibold theme-text mb-1">Video Consultation</h3>
												<p class="text-sm theme-text-muted mb-3">Face-to-face video call</p>
												<p class="text-lg font-bold text-blue-600">₦{formatFee('video')}</p>
											</div>
										</div>
									</button>
								{/if}

								{#if provider.consultation_types.includes('audio')}
									<button
										onclick={() => selectType('audio')}
										class="theme-card border-2 theme-border p-6 rounded-lg hover:border-blue-500 transition text-left"
									>
										<div class="flex items-start gap-4">
											<div class="p-3 bg-purple-100 rounded-lg">
												<Phone class="w-6 h-6 text-purple-600" />
											</div>
											<div class="flex-1">
												<h3 class="font-semibold theme-text mb-1">Audio Consultation</h3>
												<p class="text-sm theme-text-muted mb-3">Voice call consultation</p>
												<p class="text-lg font-bold text-blue-600">₦{formatFee('audio')}</p>
											</div>
										</div>
									</button>
								{/if}

								{#if provider.consultation_types.includes('office_visit')}
									<button
										onclick={() => selectType('office_visit')}
										class="theme-card border-2 theme-border p-6 rounded-lg hover:border-blue-500 transition text-left"
									>
										<div class="flex items-start gap-4">
											<div class="p-3 bg-orange-100 rounded-lg">
												<MapPin class="w-6 h-6 text-orange-600" />
											</div>
											<div class="flex-1">
												<h3 class="font-semibold theme-text mb-1">Office Visit</h3>
												<p class="text-sm theme-text-muted mb-3">In-person consultation at clinic</p>
												<p class="text-lg font-bold text-blue-600">₦{formatFee('office_visit')}</p>
											</div>
										</div>
									</button>
								{/if}
							</div>
						</div>
					{/if}

					<!-- Step 2: Select Date & Time -->
					{#if bookingStep === 'datetime'}
						<div>
							<div class="flex items-center justify-between mb-4">
								<h2 class="text-xl font-semibold theme-text">Select Date & Time</h2>
								<button
									onclick={() => {
										bookingStep = 'type';
										selectedType = '';
									}}
									class="text-sm text-blue-600 hover:underline"
								>
									Change Type
								</button>
							</div>

							<!-- Note for chat -->
							{#if selectedType === 'chat'}
								<div class="bg-green-50 border border-green-200 rounded-lg p-4 mb-6">
									<p class="text-sm text-green-800">
										<strong>Instant Chat:</strong> Chat consultations start immediately after payment. No appointment needed!
									</p>
								</div>
								<button
									onclick={proceedToPayment}
									class="w-full py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-medium"
								>
									Continue to Payment
								</button>
							{:else}
								<!-- Date Selection -->
								<div class="mb-6">
									<label class="block text-sm font-medium theme-text mb-2">
										<Calendar class="inline w-4 h-4 mr-1" />
										Select Date
									</label>
									<div class="grid grid-cols-2 md:grid-cols-3 gap-3">
										{#each availableDates as date}
											<button
												onclick={() => {
													selectedDate = date;
													selectedSlot = null;
												}}
												class={`p-3 rounded-lg border-2 transition text-left ${
													selectedDate === date
														? 'border-blue-500 bg-blue-50'
														: 'theme-border theme-card hover:border-blue-300'
												}`}
											>
												<p class="text-sm theme-text-muted">{new Date(date).toLocaleDateString('en-NG', { weekday: 'short' })}</p>
												<p class="font-semibold theme-text">{formatDate(date)}</p>
											</button>
										{/each}
									</div>
								</div>

								<!-- Time Slot Selection -->
								{#if selectedDate}
									<div class="mb-6">
										<label class="block text-sm font-medium theme-text mb-2">
											<Clock class="inline w-4 h-4 mr-1" />
											Select Time
										</label>
										{#if availableSlots.length === 0}
											<p class="text-sm theme-text-muted py-4">No available slots for this date and consultation type.</p>
										{:else}
											<div class="grid grid-cols-3 md:grid-cols-4 gap-3">
												{#each availableSlots as slot}
													<button
														onclick={() => selectSlot(slot)}
														class={`p-3 rounded-lg border-2 transition ${
															selectedSlot?.id === slot.id
																? 'border-blue-500 bg-blue-50'
																: 'theme-border theme-card hover:border-blue-300'
														}`}
													>
														<p class="font-medium theme-text text-sm">{formatTime(slot.start_time)}</p>
													</button>
												{/each}
											</div>
										{/if}
									</div>

									{#if selectedSlot}
										<button
											onclick={proceedToPayment}
											class="w-full py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-medium"
										>
											Continue to Payment
										</button>
									{/if}
								{/if}
							{/if}
						</div>
					{/if}

					<!-- Step 3: Payment -->
					{#if bookingStep === 'payment'}
						<div>
							<div class="flex items-center justify-between mb-4">
								<h2 class="text-xl font-semibold theme-text">Payment</h2>
								<button
									onclick={() => bookingStep = 'datetime'}
									class="text-sm text-blue-600 hover:underline"
								>
									Back
								</button>
							</div>

							<!-- Booking Summary -->
							<div class="bg-gray-50 rounded-lg p-6 mb-6">
								<h3 class="font-semibold theme-text mb-4">Booking Summary</h3>
								<div class="space-y-2">
									<div class="flex justify-between">
										<span class="theme-text-muted">Provider</span>
										<span class="theme-text font-medium">{provider.full_name}</span>
									</div>
									<div class="flex justify-between">
										<span class="theme-text-muted">Consultation Type</span>
										<span class="theme-text font-medium capitalize">{selectedType}</span>
									</div>
									{#if selectedType !== 'chat' && selectedSlot}
										<div class="flex justify-between">
											<span class="theme-text-muted">Date & Time</span>
											<span class="theme-text font-medium">
												{formatDate(selectedSlot.date)} at {formatTime(selectedSlot.start_time)}
											</span>
										</div>
									{/if}
									<div class="flex justify-between border-t theme-border pt-2 mt-2">
										<span class="theme-text font-semibold">Total</span>
										<span class="text-xl font-bold text-blue-600">₦{formatFee(selectedType)}</span>
									</div>
								</div>
							</div>

							<!-- Payment Methods -->
							<div class="mb-6">
								<h3 class="font-semibold theme-text mb-3">Payment Method</h3>
								<div class="space-y-3">
									<button class="w-full p-4 border-2 theme-border rounded-lg hover:border-blue-500 transition flex items-center gap-3">
										<CreditCard class="w-6 h-6 text-blue-600" />
										<div class="text-left flex-1">
											<p class="font-medium theme-text">Card Payment</p>
											<p class="text-sm theme-text-muted">Pay with Debit/Credit Card</p>
										</div>
									</button>
								</div>
							</div>

							<!-- Confirm Button -->
							<button
								onclick={confirmBooking}
								class="w-full py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-medium"
							>
								Pay ₦{formatFee(selectedType)} & Confirm Booking
							</button>

							<p class="text-xs theme-text-muted text-center mt-4">
								By confirming, you agree to our Terms of Service and Privacy Policy
							</p>
						</div>
					{/if}
				</div>
			</div>
		</div>
	</main>
</div>
