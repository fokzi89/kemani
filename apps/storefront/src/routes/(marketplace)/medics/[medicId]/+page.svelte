<script lang="ts">
	import { 
		Stethoscope, ShieldCheck, Star, Clock, MapPin, 
		Award, Calendar, Video, ArrowLeft, Send, User, ArrowRight 
	} from 'lucide-svelte';
	import { goto } from '$app/navigation';

	export let data;
	$: medic = data.medic;
	$: tenant = data.tenant;

	// Booking state
	let consultationType = 'general_checkup';
	let preferredDate = '';
	let preferredTime = '';
	let isBooking = false;

	const consultationTypes = [
		{ value: 'general_checkup', label: 'General Checkup', duration: '30 min', price: '₦10,000' },
		{ value: 'follow_up', label: 'Follow-up Consultation', duration: '15 min', price: '₦5,000' },
		{ value: 'prescription_renewal', label: 'Prescription Renewal', duration: '10 min', price: '₦2,500' },
		{ value: 'specialist_review', label: 'Specialist Review', duration: '45 min', price: '₦25,000' }
	];

	$: selectedConsultation = consultationTypes.find(t => t.value === consultationType);

	async function bookConsultation() {
		isBooking = true;
		setTimeout(() => {
			alert(`Consultation booked successfully with ${medic.full_name || 'Dr.'}.`);
			isBooking = false;
			goto('/medics');
		}, 1500);
	}
</script>

<svelte:head>
	<title>{medic?.full_name || 'Expert'} | {tenant?.name || 'Healthcare'}</title>
</svelte:head>

<div class="medic-detail-page">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 md:py-16">
		
		<!-- Back Link (Minimalist) -->
		<nav class="breadcrumb">
			<a href="/medics" class="back-link"><ArrowLeft class="w-3 h-3" /> All Professionals</a>
			<span class="sep">/</span>
			<span class="current">{medic?.specialization || 'Expert Profile'}</span>
		</nav>

		{#if medic}
			<div class="profile-layout">
				
				<!-- Left Column: Portrait & Biography -->
				<div class="profile-main">
					<div class="expert-header">
						<div class="expert-portrait-wrap">
							{#if medic.profile_photo_url}
								<img src={medic.profile_photo_url} alt={medic.full_name} class="expert-portrait" />
							{:else}
								<div class="expert-placeholder">
									<Stethoscope class="h-20 w-20" />
								</div>
							{/if}
						</div>

						<div class="expert-meta">
							<div class="badges">
								{#if medic.type}
									<span class="badge badge-type">{medic.type}</span>
								{/if}
								{#if medic.is_verified}
									<span class="badge badge-verified"><ShieldCheck class="w-3 h-3" /> Verified Expert</span>
								{/if}
							</div>
							
							<h1 class="expert-name">{medic.full_name}</h1>
							<p class="expert-specialty">{medic.specialization}</p>

							<div class="expert-stats">
								{#if medic.average_rating}
									<div class="stat">
										<Star class="stat-icon star" />
										<div class="stat-text">
											<p class="stat-val">{medic.average_rating}</p>
											<p class="stat-label">Rating</p>
										</div>
									</div>
								{/if}
								{#if medic.years_of_experience}
									<div class="stat">
										<Clock class="stat-icon" />
										<div class="stat-text">
											<p class="stat-val">{medic.years_of_experience}y</p>
											<p class="stat-label">Experience</p>
										</div>
									</div>
								{/if}
							</div>
						</div>
					</div>

					<div class="expert-content">
						<section class="bio-section">
							<h3 class="section-label">The Professional Journey</h3>
							<div class="bio-text">
								{#if medic.bio}
									<p>{medic.bio}</p>
								{:else}
									<p>A distinguished healthcare professional dedicated to delivering excellence in medical care and holistic patient medics.</p>
								{/if}
							</div>
						</section>

						<!-- Logistics Panel -->
						<div class="logistics-grid">
							<div class="logistics-card">
								<MapPin class="logistics-icon" />
								<div>
									<p class="logi-label">Clinical Location</p>
									<p class="logi-val">{medic.location_served || 'Lagos, Nigeria'}</p>
								</div>
							</div>
							<div class="logistics-card">
								<Award class="logistics-icon" />
								<div>
									<p class="logi-label">Accreditation</p>
									<p class="logi-val">Medical Board Certified</p>
								</div>
							</div>
						</div>
					</div>
				</div>

				<!-- Right Column: Booking & Consulting -->
				<aside class="booking-sidebar">
					<div class="booking-box">
						<h2 class="booking-title">Book Consultation</h2>
						<p class="booking-sub">Choose your consultation type and preferred schedule.</p>

						<div class="consultation-selector">
							{#each consultationTypes as type}
								<button 
									on:click={() => consultationType = type.value}
									class="consult-item {consultationType === type.value ? 'active' : ''}"
								>
									<div class="consult-info">
										<p class="consult-name">{type.label}</p>
										<p class="consult-dur">{type.duration}</p>
									</div>
									<p class="consult-price">{type.price}</p>
								</button>
							{/each}
						</div>

						<div class="schedule-form">
							<div class="input-group">
								<label for="date" class="input-label">Preferred Date</label>
								<input type="date" id="date" bind:value={preferredDate} class="input-field" />
							</div>
							<div class="input-group">
								<label for="time" class="input-label">Preferred Time</label>
								<input type="time" id="time" bind:value={preferredTime} class="input-field" />
							</div>
						</div>

						<button 
							on:click={bookConsultation}
							disabled={isBooking}
							class="btn-primary"
						>
							{#if isBooking}
								<div class="loader-dot"></div> Processing...
							{:else}
								Confirm Consultation <ArrowRight class="btn-icon" />
							{/if}
						</button>

						<div class="payment-note">
							<ShieldCheck class="note-icon" />
							<span>Pay online securely via Paystack integrated checkout.</span>
						</div>
					</div>
				</aside>
			</div>
		{/if}
	</div>
</div>

<style>
	/* ─── TOKENS ─── */
	:root {
		--font-display: 'Playfair Display', Georgia, serif;
		--font-body: 'Inter', -apple-system, sans-serif;
		--surface: #faf9f6;
		--on-surface: #1a1c1a;
		--on-surface-muted: #6b7280;
		--border: #f0eeea;
		--accent: #785a1a;
		--radius: 8px;
	}

	.medic-detail-page {
		background: var(--surface);
		color: var(--on-surface);
		font-family: var(--font-body);
		min-height: 100vh;
	}

	/* ─── BREADCRUMB ─── */
	.breadcrumb { display: flex; align-items: center; gap: 8px; font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; color: var(--on-surface-muted); margin-bottom: 3rem; }
	.back-link { display: flex; align-items: center; gap: 6px; color: var(--on-surface); }
	.sep { opacity: 0.4; }

	/* ─── LAYOUT ─── */
	.profile-layout {
		display: grid;
		grid-template-columns: 1fr;
		gap: 4rem;
	}
	@media (min-width: 1024px) {
		.profile-layout { grid-template-columns: 1fr 360px; gap: 6rem; }
	}

	/* ─── MAIN COLUMN ─── */
	.profile-main { display: flex; flex-direction: column; gap: 4rem; }
	.expert-header { display: flex; flex-direction: column; gap: 2.5rem; }
	@media (min-width: 768px) { .expert-header { flex-direction: row; align-items: center; } }

	.expert-portrait-wrap { 
		width: 180px; aspect-ratio: 3/4; border-radius: var(--radius); 
		background: #fff; border: 1px solid var(--border); overflow: hidden;
		flex-shrink: 0;
	}
	.expert-portrait { width: 100%; height: 100%; object-fit: cover; }
	.expert-placeholder { display: flex; align-items: center; justify-content: center; height: 100%; color: #f3f4f6; }

	.expert-meta { display: flex; flex-direction: column; gap: 1rem; }
	.badges { display: flex; gap: 8px; }
	.badge { font-size: 9px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; padding: 4px 12px; border-radius: 4px; }
	.badge-type { background: var(--on-surface); color: #fff; }
	.badge-verified { background: #fff; border: 1px solid var(--border); color: #059669; display: flex; align-items: center; gap: 4px; }

	.expert-name { font-family: var(--font-display); font-size: 3rem; font-weight: 500; line-height: 1; }
	.expert-specialty { font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.25em; color: var(--accent); }

	.expert-stats { display: flex; gap: 2.5rem; margin-top: 1rem; }
	.stat { display: flex; align-items: center; gap: 12px; }
	.stat-icon { width: 20px; height: 20px; color: #d1d5db; }
	.stat-icon.star { color: #f59e0b; fill: currentColor; }
	.stat-val { font-size: 15px; font-weight: 700; line-height: 1; }
	.stat-label { font-size: 9px; font-weight: 700; text-transform: uppercase; color: var(--on-surface-muted); letter-spacing: 0.05em; }

	.section-label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.15em; color: var(--on-surface-muted); margin-bottom: 2rem; border-bottom: 1px solid var(--border); padding-bottom: 12px; }
	.bio-text { font-size: 15px; line-height: 1.8; color: var(--on-surface-muted); max-width: 600px; font-weight: 300; }

	.logistics-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1.5rem; margin-top: 2rem; }
	.logistics-card { padding: 1.5rem; background: #fff; border: 1px solid var(--border); border-radius: var(--radius); display: flex; align-items: center; gap: 1rem; }
	.logistics-icon { width: 24px; height: 24px; color: var(--accent); opacity: 0.6; }
	.logi-label { font-size: 9px; font-weight: 700; text-transform: uppercase; color: var(--on-surface-muted); margin-bottom: 2px; }
	.logi-val { font-size: 13px; font-weight: 600; }

	/* ─── BOOKING SIDEBAR ─── */
	.booking-sidebar { display: flex; flex-direction: column; }
	.booking-box { background: #fff; border: 1px solid var(--border); border-radius: var(--radius); padding: 2.5rem; position: sticky; top: 120px; }
	.booking-title { font-family: var(--font-display); font-size: 1.75rem; font-weight: 500; margin-bottom: 0.5rem; }
	.booking-sub { font-size: 13px; color: var(--on-surface-muted); margin-bottom: 2.5rem; line-height: 1.5; }

	.consultation-selector { display: flex; flex-direction: column; gap: 0.75rem; margin-bottom: 2.5rem; }
	.consult-item { display: flex; justify-content: space-between; align-items: center; padding: 1rem; border: 1px solid var(--border); border-radius: 6px; background: transparent; cursor: pointer; transition: all 0.2s; text-align: left; }
	.consult-item.active { border-color: var(--on-surface); background: rgba(0,0,0,0.01); }
	.consult-name { font-size: 12px; font-weight: 700; color: var(--on-surface); }
	.consult-dur { font-size: 10px; color: var(--on-surface-muted); text-transform: uppercase; }
	.consult-price { font-size: 13px; font-weight: 700; color: var(--on-surface); }

	.schedule-form { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 2.5rem; }
	.input-group { display: flex; flex-direction: column; gap: 0.4rem; }
	.input-label { font-size: 11px; font-weight: 700; text-transform: uppercase; color: var(--on-surface-muted); }
	.input-field { border: none; border-bottom: 1px solid var(--border); padding: 8px 0; font-size: 13px; font-weight: 600; background: transparent; outline: none; }
	.input-field:focus { border-color: var(--on-surface); }

	.btn-primary {
		width: 100%; padding: 18px; border: none; border-radius: 6px;
		background: var(--on-surface); color: #fff;
		font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.15em;
		display: flex; align-items: center; justify-content: center; gap: 8px;
		cursor: pointer; transition: background 0.2s;
	}
	.btn-primary:hover { background: #000; }
	.btn-primary:disabled { opacity: 0.5; }

	.payment-note { margin-top: 1.5rem; display: flex; align-items: start; gap: 8px; font-size: 10px; color: var(--on-surface-muted); line-height: 1.4; font-weight: 500; }
	.note-icon { width: 14px; height: 14px; flex-shrink: 0; color: #059669; }

	.loader-dot { width: 8px; height: 8px; border: 2px solid rgba(255,255,255,0.3); border-top-color: #fff; border-radius: 50%; animation: spin 0.8s linear infinite; }
	@keyframes spin { to { transform: rotate(360deg); } }
</style>
