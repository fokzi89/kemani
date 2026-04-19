<script lang="ts">
  import { onMount, tick } from 'svelte';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase';
  import { Star, MapPin, CheckCircle2, School, Award, Calendar, MessageSquare, ChevronRight, TrendingUp, Users } from 'lucide-svelte';
  
  export let data;
  $: provider = data.provider;
  $: medics = data.medics || [];
  $: brandColor = provider?.brand_color || '#003f87';
  $: reviews = data.reviews || [];
  $: schedule = data.schedule || [];
  $: followUpDuration = data.followUpDuration || 24;
  $: slotDuration = data.slotDuration || 30;

  // Dynamic stats
  $: stats = [
    { label: 'Experience', value: `${provider?.years_experience || 0}+ Years`, icon: TrendingUp },
    { label: 'Reviews', value: provider?.total_reviews?.toLocaleString() || '0', icon: Users },
    { label: 'Rating', value: provider?.average_rating?.toFixed(1) || '0.0', icon: Star }
  ];

  let activeTab = 'about';
  const tabs = [
    { id: 'about', label: 'About' },
    { id: 'services', label: 'Services' },
    { id: 'reviews', label: 'Reviews' },
    { id: 'locations', label: 'Locations' }
  ];

  // Auth State
  let session: any = null;
  onMount(async () => {
    const { data: { session: curSession } } = await supabase.auth.getSession();
    session = curSession;
    
    supabase.auth.onAuthStateChange((_event, curSession) => {
      session = curSession;
    });
  });

  // Booking State
  $: servicesOffered = provider?.services_offered || ['chat'];
  let selectedService = data.provider?.services_offered?.[0] || 'chat';
  
  // Try to use marked up fees, otherwise calculate minimum fee
  $: selectedFee = provider?.fees?.[selectedService] || Math.min(...Object.values(provider?.fees || {chat: 15000}).map(v => Number(v))) || 15000;

  let selectedDate: string | null = null;
  let selectedTimes: string[] = [];
  let availableSlots: string[] = [];
  let isBooking = false;

  // Sign-in modal state
  let showSignInModal = false;

  async function signInWithGoogle() {
    // The OAuth redirectTo must use the base (non-subdomain) origin that is
    // whitelisted in Supabase & Google Cloud Console.
    // We pass the full current URL (with subdomain) as `next` so the
    // callback can bounce the user back to the right page after auth.
    const baseOrigin = `http://localhost:5143`; // whitelisted redirect base
    const returnTo = encodeURIComponent(window.location.href); // full subdomain URL
    const callbackUrl = `${baseOrigin}/auth/callback?next=${returnTo}`;
    await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: callbackUrl,
        queryParams: { access_type: 'offline', prompt: 'consent' }
      }
    });
  }

  $: bookedList = data.bookedSlots || [];

  function isSlotBooked(slot: string, date: string | null) {
    if (!bookedList || !date) return false;
    const [hh, mm] = slot.split(':').map(Number);
    const m1 = hh * 60 + mm;
    for (let b of bookedList) {
      if (b.date === date) {
         const [sh, sm] = b.start_time.split(':').map(Number);
         const [eh, em] = b.end_time.split(':').map(Number);
         const bsMins = sh * 60 + sm;
         const beMins = eh * 60 + em;
         if (m1 >= bsMins && m1 < beMins) return true;
      }
    }
    return false;
  }

  function generateSlots(startTime: string, endTime: string, slotMins: number) {
    if (!startTime || !endTime) return [];
    const parseTime = (t: string) => {
      const parts = t.split(':');
      return parseInt(parts[0]) * 60 + parseInt(parts[1]);
    };
    const startMins = parseTime(startTime);
    const endMins = parseTime(endTime);
    let slots = [];
    for (let m = startMins; m < endMins; m += slotMins) {
      const hh = Math.floor(m / 60).toString().padStart(2, '0');
      const mm = (m % 60).toString().padStart(2, '0');
      slots.push(`${hh}:${mm}`);
    }
    return slots;
  }

  function handleDateSelect(dayItem: any) {
    if (!dayItem.isAvailable) return;
    selectedDate = dayItem.dateString;
    if (dayItem.scheduleRecord) {
      let slots = generateSlots(dayItem.scheduleRecord.start_time, dayItem.scheduleRecord.end_time, dayItem.scheduleRecord.slot_duration || slotDuration);
      
      const todayString = new Date().toISOString().split('T')[0];
      if (selectedDate === todayString) {
        const today = new Date();
        const currentMins = today.getHours() * 60 + today.getMinutes();
        slots = slots.filter(slot => {
           const [hh, mm] = slot.split(':').map(Number);
           const slotMins = hh * 60 + mm;
           return slotMins > currentMins;
        });
      }
      availableSlots = slots;
    } else {
      availableSlots = [];
    }
    selectedTimes = [];
  }

  function handleTimeSelect(slot: string) {
    if (isSlotBooked(slot, selectedDate)) return;

    const idx = selectedTimes.indexOf(slot);
    if (idx !== -1) {
      if (idx === 0 || idx === selectedTimes.length - 1) {
        selectedTimes = selectedTimes.filter(t => t !== slot);
      } else {
        selectedTimes = [slot];
      }
      return;
    }

    if (selectedTimes.length === 0) {
      selectedTimes = [slot];
      return;
    }

    const slotIdx = availableSlots.indexOf(slot);
    const sortedIndices = selectedTimes.map(t => availableSlots.indexOf(t)).sort((a,b)=>a-b);
    
    if (slotIdx === sortedIndices[0] - 1 || slotIdx === sortedIndices[sortedIndices.length - 1] + 1) {
      let newSelected = [...selectedTimes, slot];
      selectedTimes = newSelected.sort((a,b) => availableSlots.indexOf(a) - availableSlots.indexOf(b));
    } else {
      selectedTimes = [slot];
    }
  }

  $: selectedFeeTotal = Number(selectedFee) * (selectedTimes.length || 1);

  const daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  function getNextDates() {
    let dates = [];
    let today = new Date();
    for (let i = 0; i < 7; i++) {
       let d = new Date(today);
       d.setDate(today.getDate() + i);
       let dayName = daysOfWeek[d.getDay()];
       let isoDate = d.toISOString().split('T')[0];
       let avail = schedule.find((a: any) => a.day_name === dayName);
       dates.push({
         dateString: isoDate,
         dayName,
         dayShort: dayName.substring(0,3),
         num: d.getDate(),
         isAvailable: !!avail,
         scheduleRecord: avail
       });
    }
    return dates;
  }
  
  $: nextDates = getNextDates();

  const handleBooking = async () => {
    if (!selectedService || !selectedDate || selectedTimes.length === 0) {
      alert("Please select a consultation type, date and time slots.");
      return;
    }
    
    if (!session) {
      showSignInModal = true;
      return;
    }

    if (selectedTimes.length > 1) {
      const confirmed = confirm(`Are you sure you want to book ${selectedTimes.length} consecutive slots?\nTotal Fee: ₦${selectedFeeTotal.toLocaleString()}`);
      if (!confirmed) return;
    }
    
    isBooking = true;
    try {
      const firstSlot = selectedTimes[0];
      const lastSlot = selectedTimes[selectedTimes.length - 1];

      const [hh, mm] = firstSlot.split(':').map(Number);
      const start_time = `${hh.toString().padStart(2, '0')}:${mm.toString().padStart(2, '0')}:00`;
      
      let dayObj = nextDates.find(d => d.dateString === selectedDate);
      let ds = dayObj?.scheduleRecord?.slot_duration || slotDuration;

      const [l_hh, l_mm] = lastSlot.split(':').map(Number);
      let eMins = l_hh * 60 + l_mm + ds;
      let e_hh = Math.floor(eMins / 60);
      let e_mm = eMins % 60;
      let end_time = `${e_hh.toString().padStart(2, '0')}:${e_mm.toString().padStart(2, '0')}:00`;

      let totalDuration = ds * selectedTimes.length;

      // 1. Insert time slot
      const { error: slotError } = await supabase.from('provider_time_slots').insert({
        provider_id: provider.hcp_id,
        date: selectedDate,
        start_time,
        end_time,
        slot_duration: totalDuration,
        consultation_type: selectedService,
        status: 'booked'
      });

      if (slotError && slotError.code !== '23505') {
        alert("Failed to confirm time slot: " + slotError.message);
        return;
      }

      // 2. Insert consultation
      const { data: consultData, error: consultError } = await supabase.from('consultations').insert({
        provider_id: provider.hcp_id,
        patient_id: session.user.id,
        tenant_id: provider.id,
        type: selectedService,
        status: 'pending',
        scheduled_time: new Date(`${selectedDate}T${start_time}`).toISOString(),
        slot_duration: totalDuration,
        referral_source: 'direct',
        provider_name: provider.name,
        provider_photo_url: provider.logo_url,
        consultation_fee: selectedFeeTotal,
        payment_status: 'pending'
      }).select('id').single();

      if (consultError) {
        alert("Failed to create appointment: " + consultError.message);
        return;
      }

      bookedList = [...bookedList, {
          date: selectedDate,
          start_time,
          end_time,
          status: 'booked'
      }];

      // Calculate time difference
      const scheduledDateObj = new Date(`${selectedDate}T${start_time}`);
      const now = new Date();
      const diffMins = (scheduledDateObj.getTime() - now.getTime()) / (1000 * 60);

      // Redirect based on time
      if (diffMins > 10) {
        goto(`/booking-details/${consultData.id}`);
      } else {
        goto(`/waiting-area/${consultData.id}`);
      }
      selectedTimes = []; // reset selection
    } catch (e: any) {
      console.error(e);
      alert("An unexpected error occurred during booking. " + (e?.message || ''));
    } finally {
      isBooking = false;
    }
  };

</script>

<!-- Sign-In Modal -->
{#if showSignInModal}
  <div class="modal-backdrop" on:click={() => showSignInModal = false} role="presentation">
    <div class="signin-modal" on:click|stopPropagation role="dialog" aria-modal="true" aria-labelledby="signin-title">
      <button class="modal-close" on:click={() => showSignInModal = false} aria-label="Close">✕</button>

      <div class="modal-logo" style="color: {brandColor};">
        {#if provider?.logo_url}
          <img src={provider.logo_url} alt={provider?.name} class="modal-provider-logo" />
        {:else}
          <svg fill="none" viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg" class="w-10 h-10">
            <path clip-rule="evenodd" d="M47.2426 24L24 47.2426L0.757355 24L24 0.757355L47.2426 24ZM12.2426 21H35.7574L24 9.24264L12.2426 21Z" fill="currentColor" fill-rule="evenodd"></path>
          </svg>
        {/if}
      </div>

      <h2 id="signin-title" class="modal-title">Sign in to book</h2>
      <p class="modal-subtitle">You need an account to book a consultation with <strong>{provider?.name}</strong>.</p>

      <button class="google-btn" on:click={signInWithGoogle}>
        <svg class="google-icon" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
          <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
          <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z" fill="#FBBC05"/>
          <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
        </svg>
        Continue with Google
      </button>

      <p class="modal-terms">By continuing, you agree to our Terms of Service and Privacy Policy.</p>
    </div>
  </div>
{/if}

<div class="profile-page">
  <div class="layout-container">
    <div class="grid-layout">
      <!-- MAIN CONTENT -->
      <div class="main-column">
        <!-- Hero Section -->
        <section class="hero-card">
          <div class="hero-inner">
            <div class="profile-image-container">
              {#if provider?.logo_url}
                <img src={provider.logo_url} alt={provider.name} class="profile-img" />
              {:else}
                <div class="profile-img-placeholder" style="background: {brandColor}20; color: {brandColor};">
                  {provider?.name?.charAt(0) || 'H'}
                </div>
              {/if}
              <div class="status-badge">Available</div>
            </div>

            <div class="hero-info">
              <div class="name-row">
                <h1>{provider?.name}</h1>
                {#if provider?.is_verified}
                  <CheckCircle2 class="w-6 h-6" style="color: {brandColor};" fill={brandColor} />
                {/if}
              </div>
              <p class="specialty-text" style="color: {brandColor};">{provider?.category || 'Healthcare Provider'}</p>
              {#if provider?.address}
                <p class="location-text">
                  <MapPin class="w-4 h-4" />
                  {provider.address} {provider.city ? `, ${provider.city}` : ''}
                </p>
              {/if}

              <div class="stats-row">
                {#each stats as stat}
                  <div class="stat-item">
                    <span class="stat-label">{stat.label}</span>
                    <div class="stat-value-row">
                      <span class="stat-value">{stat.value}</span>
                      {#if stat.label === 'Rating'}
                        <Star class="w-4 h-4 text-tertiary" fill="currentColor" />
                      {/if}
                    </div>
                  </div>
                {/each}
              </div>
            </div>
          </div>
        </section>

        <!-- Tabs -->
        <nav class="tabs-nav">
          {#each tabs as tab}
            <button 
              class="tab-btn" 
              class:active={activeTab === tab.id}
              on:click={() => activeTab = tab.id}
            >
              {tab.label}
            </button>
          {/each}
        </nav>

        <div class="tab-content">
          {#if activeTab === 'about'}
            <section class="content-section">
              <h2>Biography</h2>
              <div class="bio-container">
                <p class="bio-text">
                  {#if provider?.description}
                    {provider.description}
                  {:else}
                    No information found
                  {/if}
                </p>
              </div>
            </section>
          {/if}

          {#if activeTab === 'services'}
            <section class="content-section">
              <div class="flex-header">
                <h2>Services Offered</h2>
                <div class="header-badge" style="background: {brandColor}15; color: {brandColor};">
                  Professional Consultations
                </div>
              </div>
              <div class="services-vertical-list">
                {#if provider?.services_offered?.length}
                  {#each provider.services_offered as service}
                    <div class="service-row">
                      <div class="service-main-info">
                        <div class="service-icon-box" style="background: {brandColor}10;">
                          <CheckCircle2 class="w-5 h-5" style="color: {brandColor};" />
                        </div>
                        <div class="name-meta">
                          <span class="service-name">{service}</span>
                          <span class="service-tag">Professional Session</span>
                        </div>
                      </div>
                      {#if provider.fees && provider.fees[service]}
                        <div class="service-price">
                          <span class="currency">₦</span>
                          <span class="amount">{Number(provider.fees[service]).toLocaleString()}</span>
                          <span class="price-suffix">/ session</span>
                        </div>
                      {/if}
                    </div>
                  {/each}
                {:else}
                  <div class="empty-state">
                    <p class="text-on-surface-variant">General consultation and healthcare services.</p>
                  </div>
                {/if}
              </div>
            </section>
          {/if}

          {#if activeTab === 'reviews'}
            <section class="content-section">
              <div class="flex-header">
                <h2>Patient Reviews</h2>
                <button class="link-btn" style="color: {brandColor};">View All {provider?.total_reviews || 0} Reviews</button>
              </div>
              <div class="reviews-stack">
                {#if reviews.length > 0}
                  {#each reviews as review}
                    <div class="review-card">
                      <div class="review-header">
                        <div class="reviewer-info">
                          <div class="reviewer-avatar" style="background: {brandColor}15; color: {brandColor};">
                            {review.reviewer_name?.charAt(0) || 'P'}
                          </div>
                          <div>
                            <p class="reviewer-name">{review.reviewer_name}</p>
                            <p class="review-date">{new Date(review.created_at).toLocaleDateString(undefined, { month: 'long', year: 'numeric' })}</p>
                          </div>
                        </div>
                        <div class="rating-stars">
                          {#each Array(5) as _, i}
                            <Star 
                              class="w-4 h-4 {i < review.rating ? 'text-tertiary' : 'text-outline-variant opacity-30'}" 
                              fill={i < review.rating ? 'currentColor' : 'none'} 
                            />
                          {/each}
                        </div>
                      </div>
                      <p class="review-body">"{review.comment}"</p>
                    </div>
                  {/each}
                {:else}
                  <div class="empty-reviews text-center py-12">
                    <MessageSquare class="w-12 h-12 text-outline-variant mx-auto mb-4 opacity-50" />
                    <p class="text-on-surface-variant">No reviews yet. Be the first to share your experience!</p>
                  </div>
                {/if}
              </div>
            </section>
          {/if}

          {#if activeTab === 'locations'}
            <section class="content-section">
              <h2>Our Locations</h2>
              <div class="locations-grid">
                {#if provider?.branches?.length}
                  {#each provider.branches as branch}
                    <div class="location-card">
                      <div class="location-header">
                        <MapPin class="w-5 h-5 text-brand" />
                        <span class="location-city">{branch.city || 'Main'}</span>
                      </div>
                      <p class="location-details">{branch.name}</p>
                      <p class="location-address">{branch.address}</p>
                      <button class="dir-link" style="color: {brandColor};">Get Directions</button>
                    </div>
                  {/each}
                {:else if provider?.address}
                   <div class="location-card">
                    <div class="location-header">
                      <MapPin class="w-5 h-5 text-brand" />
                      <span class="location-city">{provider.city || 'Main'}</span>
                    </div>
                    <p class="location-details">Primary Clinic</p>
                    <p class="location-address">{provider.address}</p>
                    <button class="dir-link" style="color: {brandColor};">Get Directions</button>
                  </div>
                {:else}
                  <div class="empty-state">
                    <p class="text-on-surface-variant">No location information found.</p>
                  </div>
                {/if}
              </div>
            </section>
          {/if}
        </div>
      </div>

      <!-- SIDEBAR -->
      <aside class="sidebar-column">
        <!-- Booking Widget -->
        <div class="booking-widget">
          <h3>Book Appointment</h3>
          
          <div class="booking-section">
            <p class="picker-label">SELECT CONSULTATION TYPE</p>
            <select class="type-dropdown" bind:value={selectedService} style="border: 1px solid black;">
              {#each servicesOffered as type}
                <option value={type}>{type.replace('_', ' ').toUpperCase()}</option>
              {/each}
            </select>
          </div>

          <div class="fee-card">
            <p class="fee-label">{selectedService.replace('_', ' ')} Fee {selectedTimes.length > 1 ? `x${selectedTimes.length}` : ''}</p>
            <p class="fee-value">₦{selectedFeeTotal.toLocaleString()}.00</p>
          </div>

          <div class="date-picker">
            <p class="picker-label">CHOOSE DATE</p>
            <div class="dates-row">
              {#each nextDates as day}
                <button 
                  class="date-btn {selectedDate === day.dateString ? 'active' : ''} {!day.isAvailable ? 'disabled' : ''}" 
                  style="{selectedDate === day.dateString ? `background: ${brandColor}; color: white;` : ''}"
                  on:click={() => handleDateSelect(day)}
                  disabled={!day.isAvailable}
                >
                  <span class="day">{day.dayShort}</span>
                  <span class="num">{day.num}</span>
                </button>
              {/each}
            </div>
          </div>

          {#if selectedDate && availableSlots.length > 0}
            <div class="time-picker">
              <p class="picker-label">CHOOSE TIME</p>
              <div class="times-grid">
                {#each availableSlots as slot}
                  {@const booked = isSlotBooked(slot, selectedDate)}
                  <button 
                    class="time-btn {selectedTimes.includes(slot) ? 'active' : ''} {booked ? 'booked' : ''}"
                    style="{booked ? 'background: #fee2e2; color: #ef4444; border-color: transparent; text-decoration: line-through; opacity: 0.6;' : (selectedTimes.includes(slot) ? `background: ${brandColor}20; color: ${brandColor}; border-color: ${brandColor};` : '')}"
                    on:click={() => handleTimeSelect(slot)}
                    disabled={booked}
                  >
                    {slot}
                  </button>
                {/each}
              </div>
            </div>
          {/if}

          {#if selectedDate && availableSlots.length === 0}
            <p class="text-sm text-on-surface-variant text-center mb-4">No slots available on this date.</p>
          {/if}

          <button class="book-btn-main cta-gradient" style="background: {brandColor};" on:click={handleBooking} disabled={isBooking}>
            {#if !session}
              Sign in to Book
            {:else if isBooking}
              Booking...
            {:else}
              Complete Booking
            {/if}
            {#if !isBooking}
              <Calendar class="w-5 h-5 ml-2" />
            {/if}
          </button>
          


          <p class="booking-note">Includes {followUpDuration}h follow-up duration window.</p>
        </div>

        <!-- Team / Medics -->
        {#if medics.length > 0}
          <div class="team-section">
            <h3 class="side-title">Medical Team</h3>
            <div class="experts-stack">
              {#each medics as medic}
                <div class="expert-item">
                  <div class="expert-avatar">
                   {#if medic.photo_url}
                      <img src={medic.photo_url} alt={medic.full_name} />
                    {:else}
                      <div class="avatar-ph">{medic.full_name.charAt(0)}</div>
                    {/if}
                  </div>
                  <div class="expert-info">
                    <p class="expert-name">{medic.full_name}</p>
                    <p class="expert-role">{medic.specialty || 'Medical Specialist'}</p>
                  </div>
                  <ChevronRight class="w-4 h-4 text-outline" />
                </div>
              {/each}
            </div>
          </div>
        {/if}
      </aside>
    </div>
  </div>
</div>

<style>
  /* Sign-in Modal */
  .modal-backdrop { position: fixed; inset: 0; background: rgba(0,0,0,0.5); backdrop-filter: blur(4px); z-index: 2000; display: flex; align-items: center; justify-content: center; padding: 1rem; animation: fadeIn 0.2s ease; }
  @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }

  .signin-modal { background: white; border-radius: 1.5rem; padding: 2.5rem 2rem; max-width: 400px; width: 100%; position: relative; text-align: center; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25); animation: slideUp 0.25s cubic-bezier(0.34, 1.56, 0.64, 1); }
  @keyframes slideUp { from { opacity: 0; transform: translateY(20px) scale(0.97); } to { opacity: 1; transform: translateY(0) scale(1); } }

  .modal-close { position: absolute; top: 1rem; right: 1rem; width: 32px; height: 32px; border-radius: 50%; background: var(--surface-container-high); color: var(--on-surface-variant); font-size: 0.875rem; display: flex; align-items: center; justify-content: center; transition: background 0.2s; }
  .modal-close:hover { background: var(--outline-variant); }

  .modal-logo { display: flex; justify-content: center; margin-bottom: 1.25rem; }
  .modal-provider-logo { width: 56px; height: 56px; border-radius: 1rem; object-fit: cover; border: 1px solid var(--outline-variant); }

  .modal-title { font-size: 1.375rem; font-weight: 800; color: var(--on-surface); margin-bottom: 0.5rem; letter-spacing: -0.02em; }
  .modal-subtitle { font-size: 0.9rem; color: var(--on-surface-variant); margin-bottom: 2rem; line-height: 1.5; }
  .modal-subtitle strong { color: var(--on-surface); }

  .google-btn { width: 100%; display: flex; align-items: center; justify-content: center; gap: 0.75rem; padding: 0.875rem 1.5rem; border-radius: 0.875rem; border: 1.5px solid var(--outline-variant); background: white; font-weight: 700; font-size: 0.9375rem; color: var(--on-surface); transition: all 0.2s; cursor: pointer; margin-bottom: 1.25rem; }
  .google-btn:hover { background: var(--surface-container-low); box-shadow: 0 4px 12px rgba(0,0,0,0.08); transform: translateY(-1px); }
  .google-icon { width: 20px; height: 20px; flex-shrink: 0; }

  .modal-terms { font-size: 0.75rem; color: var(--on-surface-variant); line-height: 1.5; }

  .profile-page { padding: 3rem 0 6rem; background-color: var(--surface); min-height: 100vh; }
  .grid-layout { display: grid; grid-template-columns: minmax(0, 1fr); gap: 3rem; width: 100%; box-sizing: border-box; }
  @media (min-width: 1024px) { .grid-layout { grid-template-columns: minmax(0, 8fr) minmax(0, 4fr); } }

  /* Hero Card */
  .hero-card { background: var(--surface-container-lowest); border-radius: 1.25rem; padding: 1.5rem; border: 1px solid var(--outline-variant); }
  .hero-inner { display: flex; flex-direction: column; gap: 2rem; }
  @media (min-width: 640px) { .hero-inner { flex-direction: row; align-items: flex-start; } }
  
  .profile-image-container { position: relative; width: 110px; height: 110px; flex-shrink: 0; }
  .profile-img { width: 100%; height: 100%; border-radius: 1rem; object-fit: cover; }
  .profile-img-placeholder { width: 100%; height: 100%; border-radius: 1rem; display: flex; align-items: center; justify-content: center; font-size: 2.5rem; font-weight: 800; font-family: var(--font-headline); }
  .status-badge { position: absolute; bottom: -0.35rem; right: -0.35rem; background: var(--secondary-container); color: var(--on-secondary-container); padding: 0.3rem 0.65rem; border-radius: 99px; font-size: 0.65rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; border: 2px solid var(--surface-container-lowest); }

  .hero-info { flex: 1; display: flex; flex-direction: column; }
  .name-row { display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.25rem; }
  .name-row h1 { font-size: 1.5rem; font-weight: 800; letter-spacing: -0.02em; color: var(--on-surface); }
  
  .specialty-text { font-size: 0.9375rem; font-weight: 600; margin-bottom: 0.25rem; }
  .location-text { display: flex; align-items: center; gap: 0.4rem; color: var(--on-surface-variant); font-size: 0.8125rem; margin-bottom: 1.25rem; }
  
  .stats-row { display: flex; gap: 1.25rem; border-top: 1px solid var(--outline-variant); padding-top: 1.25rem; margin-top: auto; }
  .stat-item { flex: 1; }
  .stat-label { font-size: 0.65rem; font-weight: 700; color: var(--on-surface-variant); text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 0.15rem; display: block; }
  .stat-value-row { display: flex; align-items: center; gap: 0.3rem; }
  .stat-value { font-size: 1rem; font-weight: 800; color: var(--on-surface); }

  /* Tabs Nav */
  .tabs-nav { display: flex; gap: 2.25rem; border-bottom: 1px solid var(--outline-variant); margin: 2.5rem 0; overflow-x: auto; scrollbar-width: none; }
  .tabs-nav::-webkit-scrollbar { display: none; }
  .tab-btn { padding-bottom: 0.85rem; font-weight: 700; font-size: 0.8125rem; color: var(--on-surface-variant); text-transform: uppercase; letter-spacing: 0.075em; position: relative; white-space: nowrap; border-bottom: 3px solid transparent; }
  .tab-btn.active { color: var(--on-surface); border-bottom-color: var(--brand); }

  /* Main Columns */
  .content-section { margin-bottom: 2.5rem; }
  .content-section h2 { font-size: 1.25rem; font-weight: 800; margin-bottom: 1rem; color: var(--on-surface); }
  .bio-text { color: var(--on-surface-variant); line-height: 1.6; font-size: 0.9375rem; }

  .services-vertical-list { display: flex; flex-direction: column; gap: 1.25rem; }
  .service-row { 
    display: flex; 
    justify-content: space-between; 
    align-items: center; 
    background: var(--surface-container-lowest); 
    padding: 1.25rem 1.75rem; 
    border-radius: 1.25rem; 
    border: 1px solid var(--outline-variant); 
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    box-shadow: 0 4px 6px -1px rgba(0,0,0,0.02);
  }
  .service-row:hover { 
    background: var(--surface-container-low);
    border-color: var(--brand); 
    transform: translateX(6px);
    box-shadow: 0 10px 15px -3px rgba(0,0,0,0.05);
  }
  .service-main-info { display: flex; align-items: center; gap: 1.25rem; }
  .service-icon-box { 
    width: 44px; 
    height: 44px; 
    border-radius: 0.875rem; 
    display: flex; 
    align-items: center; 
    justify-content: center;
  }
  .name-meta { display: flex; flex-direction: column; gap: 0.15rem; }
  .service-name { font-weight: 800; font-size: 1.125rem; color: var(--on-surface); text-transform: capitalize; letter-spacing: -0.01em; }
  .service-tag { font-size: 0.75rem; font-weight: 600; color: var(--on-surface-variant); opacity: 0.8; }
  
  .service-price { display: flex; align-items: baseline; gap: 0.2rem; color: var(--on-surface); }
  .service-price .currency { font-size: 1rem; font-weight: 700; color: var(--on-surface-variant); }
  .service-price .amount { font-size: 1.5rem; font-weight: 900; letter-spacing: -0.03em; color: var(--on-surface); }
  .service-price .price-suffix { font-size: 0.8125rem; font-weight: 600; color: var(--on-surface-variant); opacity: 0.7; margin-left: 0.25rem; }

  .header-badge { padding: 0.4rem 0.85rem; border-radius: 99px; font-size: 0.75rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; }

  .reviews-stack { display: flex; flex-direction: column; gap: 1.25rem; }
  .review-card { background: var(--surface-container-lowest); border: 1px solid var(--outline-variant); padding: 2rem; border-radius: 1.25rem; }
  .review-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.25rem; }
  .reviewer-info { display: flex; align-items: center; gap: 1rem; }
  .reviewer-avatar { width: 44px; height: 44px; border-radius: 50%; background: var(--secondary-container); color: var(--on-secondary-container); display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 0.875rem; }
  .reviewer-name { font-weight: 700; font-size: 1.0625rem; color: var(--on-surface); }
  .review-date { font-size: 0.8125rem; color: var(--on-surface-variant); }
  .rating-stars { display: flex; gap: 2px; }
  .review-body { color: var(--on-surface-variant); line-height: 1.7; font-size: 1rem; }

  .locations-grid { display: grid; grid-template-columns: 1fr; gap: 1.25rem; }
  @media (min-width: 640px) { .locations-grid { grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); } }
  .location-card { background: white; border: 1px solid var(--outline-variant); padding: 1.5rem; border-radius: 1.25rem; display: flex; flex-direction: column; gap: 0.5rem; }
  .location-header { display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.5rem; }
  .location-city { font-weight: 700; color: var(--on-surface); font-size: 0.875rem; text-transform: uppercase; letter-spacing: 0.05em; }
  .location-details { font-weight: 700; color: var(--on-surface); font-size: 1rem; }
  .location-address { font-size: 0.9375rem; color: var(--on-surface-variant); margin-bottom: 1rem; }
  .dir-link { font-weight: 700; font-size: 0.875rem; text-align: left; }

  /* Sidebar */
  .booking-widget { 
    background: var(--surface-container-lowest, #ffffff); 
    border: 1px solid var(--outline-variant, #e5e7eb); 
    padding: 1.25rem; 
    border-radius: 1rem; 
    box-shadow: 0 10px 15px -3px rgba(0,0,0,0.05); 
    width: 100%; 
    max-width: 100%; 
    box-sizing: border-box; 
    z-index: 10;
  }
  @media (min-width: 1024px) {
    .booking-widget {
      position: sticky;
      top: 100px;
    }
  }
  @media (max-width: 640px) {
    .booking-widget { padding: 1rem; margin: 0 auto; }
  }
  .booking-widget h3 { margin-bottom: 1rem; font-size: 1rem; font-weight: 800; color: var(--on-surface); }
  
  .fee-card { background: var(--surface-container-low); padding: 0.85rem; border-radius: 0.75rem; margin-bottom: 1.25rem; border: 1px solid rgba(0,0,0,0.03); }
  .fee-label { font-size: 0.75rem; color: var(--on-surface-variant); margin-bottom: 0.15rem; font-weight: 500; }
  .fee-value { font-size: 1.25rem; font-weight: 800; color: var(--on-surface); letter-spacing: -0.01em; }
  
  .picker-label { font-size: 0.75rem; font-weight: 700; color: var(--on-surface-variant); text-transform: uppercase; letter-spacing: 0.125em; margin-bottom: 0.75rem; }
  .booking-section { margin-bottom: 1.25rem; }
  .type-dropdown { width: 100%; padding: 0.75rem 1rem; border-radius: 0.75rem; border: 2px solid var(--outline-variant); background: var(--surface-container-high); color: var(--on-surface); font-weight: 700; font-size: 0.9375rem; outline: none; transition: all 0.2s; cursor: pointer; text-transform: capitalize; appearance: auto; -webkit-appearance: auto; }
  .type-dropdown:focus { border-color: var(--brand); box-shadow: 0 0 0 3px rgba(0,0,0,0.05); }

  .dates-row { display: flex; gap: 0.75rem; overflow-x: auto; padding-bottom: 0.75rem; margin-bottom: 1.25rem; max-width: 100%; -webkit-overflow-scrolling: touch; }
  @media (max-width: 480px) {
    .dates-row { gap: 0.5rem; }
  }
  .dates-row::-webkit-scrollbar { height: 4px; }
  .dates-row::-webkit-scrollbar-thumb { background: var(--outline-variant); border-radius: 4px; }
  
  .date-btn { min-width: 60px; height: 72px; display: flex; flex-direction: column; align-items: center; justify-content: center; background: var(--surface-container-high); border-radius: 1rem; border: 1px solid transparent; transition: all 0.2s; cursor: pointer; }
  .date-btn:hover:not(.disabled) { background: var(--outline-variant); }
  .date-btn.active { border-color: transparent; }
  .date-btn.disabled { opacity: 0.4; cursor: not-allowed; background: var(--surface-container); }
  .date-btn .day { font-size: 0.75rem; font-weight: 600; opacity: 0.8; }
  .date-btn .num { font-size: 1.125rem; font-weight: 800; }

  .time-picker { margin-bottom: 1.5rem; }
  .times-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 0.5rem; max-height: 400px; overflow-y: auto; padding-right: 0.5rem; }
  @media (max-width: 400px) {
    .times-grid { grid-template-columns: repeat(2, 1fr); }
  }
  .times-grid::-webkit-scrollbar { width: 4px; }
  .times-grid::-webkit-scrollbar-thumb { background: var(--outline-variant); border-radius: 4px; }
  .time-btn { padding: 0.6rem; border-radius: 0.6rem; font-weight: 700; font-size: 0.875rem; background: var(--surface-container-high); color: var(--on-surface); border: 1px solid transparent; transition: all 0.2s; }
  .time-btn:hover { background: var(--outline-variant); }
  .time-btn.active { border: 1px solid var(--brand); }

  .book-btn-main { width: 100%; display: flex; align-items: center; justify-content: center; padding: 1rem; border-radius: 0.875rem; color: white; font-weight: 700; font-size: 1rem; margin-bottom: 0.75rem; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.2); transition: all 0.2s; cursor: pointer; }
  .book-btn-main:hover { transform: translateY(-2px); box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.2); }
  .booking-note { text-align: center; font-size: 0.8125rem; color: var(--on-surface-variant); font-style: italic; margin-top: 1.5rem; }

  .team-section { margin-top: 2rem; }
  .side-title { font-size: 1.125rem; font-weight: 800; margin-bottom: 1rem; color: var(--on-surface); }
  .experts-stack { display: flex; flex-direction: column; gap: 1rem; }
  .expert-item { display: flex; align-items: center; gap: 0.85rem; background: var(--surface-container-lowest); padding: 0.85rem; border-radius: 1rem; cursor: pointer; transition: all 0.2s; border: 1px solid var(--outline-variant); box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05); }
  .expert-item:hover { background: var(--surface-bright); border-color: var(--brand); transform: translateX(4px); }
  .expert-avatar { width: 52px; height: 52px; border-radius: 0.875rem; overflow: hidden; background: var(--surface-container-high); flex-shrink: 0; }
  .expert-avatar img { width: 100%; height: 100%; object-fit: cover; }
  .avatar-ph { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; font-size: 1.25rem; font-weight: 800; color: var(--on-surface-variant); background: var(--secondary-container); }
  .expert-info { flex: 1; }
  .expert-name { font-weight: 700; font-size: 0.875rem; color: var(--on-surface); }
  .expert-role { font-size: 0.7rem; color: var(--on-surface-variant); margin-top: 0.1rem; }

  .flex-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; }
  .link-btn { font-size: 0.875rem; font-weight: 700; }
  .link-btn:hover { text-decoration: underline; }
</style>
