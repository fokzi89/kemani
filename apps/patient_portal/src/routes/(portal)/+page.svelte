<script lang="ts">
  import { Star, MapPin, CheckCircle2, School, Award, Calendar, MessageSquare, ChevronRight, TrendingUp, Users } from 'lucide-svelte';
  
  export let data;
  $: provider = data.provider;
  $: medics = data.medics || [];
  $: brandColor = provider?.brand_color || '#003f87';
  $: reviews = data.reviews || [];

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

  // Calculate dynamic pricing
  $: feeValues = Object.values(provider?.fees || {});
  $: minFee = feeValues.length > 0 ? Math.min(...feeValues.map(v => Number(v))) : 15000;
</script>

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
              <p class="location-text">
                <MapPin class="w-4 h-4" />
                {provider?.address || 'Main Plaza, Abuja'}
              </p>

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
                  {provider?.description || 
                  `${provider?.name} is a leading healthcare provider dedicated to clinical excellence and patient-first care. Combining cutting-edge diagnostic technology with a compassionate, holistic approach to health.`}
                </p>
                <p class="bio-text mt-4">
                  Our team brings years of specialized experience to ensure you receive the highest standard of medical attention. We are committed to fostering a safe and supportive environment for all our patients.
                </p>
              </div>
            </section>

            <section class="content-section">
              <h2>Education & Credentials</h2>
              <div class="credentials-grid">
                <div class="credential-card">
                  <div class="cred-icon"><School class="w-5 h-5" /></div>
                  <div class="cred-info">
                    <p class="cred-title">Clinical Excellence Certification</p>
                    <p class="cred-sub">Global Healthcare Standards Institute</p>
                  </div>
                </div>
                <div class="credential-card">
                  <div class="cred-icon"><Award class="w-5 h-5" /></div>
                  <div class="cred-info">
                    <p class="cred-title">Fellow of Medical Council</p>
                    <p class="cred-sub">National Association of Specialists</p>
                  </div>
                </div>
              </div>
            </section>
          {/if}

          {#if activeTab === 'services'}
            <section class="content-section">
              <h2>Services Offered</h2>
              <div class="services-list">
                {#if provider?.services_offered?.length}
                  {#each provider.services_offered as service}
                    <div class="service-chip">{service}</div>
                  {/each}
                {:else}
                  <p class="text-on-surface-variant">General consultation and healthcare services.</p>
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
                {:else}
                   <div class="location-card">
                    <div class="location-header">
                      <MapPin class="w-5 h-5 text-brand" />
                      <span class="location-city">Abuja</span>
                    </div>
                    <p class="location-details">Main Plaza Clinic</p>
                    <p class="location-address">234 Main St, Abuja, Nigeria</p>
                    <button class="dir-link" style="color: {brandColor};">Get Directions</button>
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
          <div class="fee-card">
            <p class="fee-label">Consultation Fee</p>
            <p class="fee-value">₦{minFee?.toLocaleString() || '15,000'}.00</p>
          </div>

          <div class="date-picker">
            <p class="picker-label">CHOOSE DATE</p>
            <div class="dates-row">
              <button class="date-btn active" style="background: {brandColor}; color: white;">
                <span class="day">Mon</span>
                <span class="num">12</span>
              </button>
              <button class="date-btn">
                <span class="day">Tue</span>
                <span class="num">13</span>
              </button>
              <button class="date-btn">
                <span class="day">Wed</span>
                <span class="num">14</span>
              </button>
              <button class="date-btn">
                <span class="day">Thu</span>
                <span class="num">15</span>
              </button>
            </div>
          </div>

          <button class="book-btn-main cta-gradient" style="background: {brandColor};">
            Book Now
            <Calendar class="w-5 h-5 ml-2" />
          </button>
          
          <button class="chat-btn-sec">
            Chat with Provider
            <MessageSquare class="w-5 h-5 ml-2" />
          </button>

          <p class="booking-note">No booking fees. Free cancellation up to 24h prior.</p>
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
  .profile-page { padding: 3rem 0 6rem; background-color: var(--surface); min-height: 100vh; }
  .grid-layout { display: grid; grid-template-columns: 1fr; gap: 3rem; }
  @media (min-width: 1024px) { .grid-layout { grid-template-columns: 8fr 4fr; } }

  /* Hero Card */
  .hero-card { background: var(--surface-container-lowest); border-radius: 1.25rem; padding: 1.5rem; border: 1px solid var(--outline-variant); }
  .hero-inner { display: flex; flex-direction: column; gap: 2rem; }
  @media (min-width: 640px) { .hero-inner { flex-direction: row; align-items: flex-start; } }
  
  .profile-image-container { position: relative; width: 140px; height: 140px; flex-shrink: 0; }
  .profile-img { width: 100%; height: 100%; border-radius: 1.25rem; object-fit: cover; }
  .profile-img-placeholder { width: 100%; height: 100%; border-radius: 1.25rem; display: flex; align-items: center; justify-content: center; font-size: 3rem; font-weight: 800; font-family: var(--font-headline); }
  .status-badge { position: absolute; bottom: -0.5rem; right: -0.5rem; background: var(--secondary-container); color: var(--on-secondary-container); padding: 0.35rem 0.75rem; border-radius: 99px; font-size: 0.7rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; border: 3px solid var(--surface-container-lowest); }

  .hero-info { flex: 1; display: flex; flex-direction: column; }
  .name-row { display: flex; align-items: center; gap: 0.6rem; margin-bottom: 0.4rem; }
  .name-row h1 { font-size: 1.75rem; font-weight: 800; letter-spacing: -0.02em; color: var(--on-surface); }
  
  .specialty-text { font-size: 1rem; font-weight: 600; margin-bottom: 0.4rem; }
  .location-text { display: flex; align-items: center; gap: 0.4rem; color: var(--on-surface-variant); font-size: 0.875rem; margin-bottom: 1.5rem; }
  
  .stats-row { display: flex; gap: 1.5rem; border-top: 1px solid var(--outline-variant); padding-top: 1.5rem; margin-top: auto; }
  .stat-item { flex: 1; }
  .stat-label { font-size: 0.7rem; font-weight: 700; color: var(--on-surface-variant); text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 0.2rem; display: block; }
  .stat-value-row { display: flex; align-items: center; gap: 0.3rem; }
  .stat-value { font-size: 1.125rem; font-weight: 800; color: var(--on-surface); }

  /* Tabs Nav */
  .tabs-nav { display: flex; gap: 3rem; border-bottom: 1px solid var(--outline-variant); margin: 3rem 0; overflow-x: auto; scrollbar-width: none; }
  .tabs-nav::-webkit-scrollbar { display: none; }
  .tab-btn { padding-bottom: 1rem; font-weight: 700; font-size: 0.875rem; color: var(--on-surface-variant); text-transform: uppercase; letter-spacing: 0.075em; position: relative; white-space: nowrap; border-bottom: 3px solid transparent; }
  .tab-btn.active { color: var(--on-surface); border-bottom-color: var(--brand); }

  /* Main Columns */
  .content-section { margin-bottom: 3rem; }
  .content-section h2 { font-size: 1.5rem; font-weight: 800; margin-bottom: 1.25rem; color: var(--on-surface); }
  .bio-text { color: var(--on-surface-variant); line-height: 1.7; font-size: 1rem; }
  
  .credentials-grid { display: grid; grid-template-columns: 1fr; gap: 1.25rem; }
  @media (min-width: 640px) { .credentials-grid { grid-template-columns: 1fr 1fr; } }
  .credential-card { background: var(--surface-container-low); padding: 1.5rem; border-radius: 1rem; display: flex; gap: 1.25rem; align-items: center; border: 1px solid rgba(0,0,0,0.03); }
  .cred-icon { width: 44px; height: 44px; background: white; border-radius: 0.75rem; display: flex; align-items: center; justify-content: center; color: var(--brand); box-shadow: 0 2px 4px rgba(0,0,0,0.05); }
  .cred-title { font-weight: 700; font-size: 1rem; color: var(--on-surface); }
  .cred-sub { font-size: 0.875rem; color: var(--on-surface-variant); margin-top: 0.125rem; }

  .services-list { display: flex; flex-wrap: wrap; gap: 0.75rem; }
  .service-chip { background: var(--surface-container-low); padding: 0.6rem 1.25rem; border-radius: 99px; font-size: 0.9375rem; font-weight: 600; color: var(--on-surface); border: 1px solid var(--outline-variant); }

  .reviews-stack { display: flex; flex-direction: column; gap: 1.25rem; }
  .review-card { background: var(--surface-container-lowest); border: 1px solid var(--outline-variant); padding: 2rem; border-radius: 1.25rem; }
  .review-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.25rem; }
  .reviewer-info { display: flex; align-items: center; gap: 1rem; }
  .reviewer-avatar { width: 44px; height: 44px; border-radius: 50%; background: var(--secondary-container); color: var(--on-secondary-container); display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 0.875rem; }
  .reviewer-avatar.sr { background: #d7e2ff; color: #001a40; }
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
  .booking-widget { background: var(--surface-container-lowest); border: 1px solid var(--outline-variant); padding: 1.5rem; border-radius: 1.25rem; position: sticky; top: 100px; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.05); }
  .booking-widget h3 { margin-bottom: 1.25rem; font-size: 1.125rem; font-weight: 800; color: var(--on-surface); }
  
  .fee-card { background: var(--surface-container-low); padding: 1rem; border-radius: 0.875rem; margin-bottom: 1.5rem; border: 1px solid rgba(0,0,0,0.03); }
  .fee-label { font-size: 0.8125rem; color: var(--on-surface-variant); margin-bottom: 0.2rem; font-weight: 500; }
  .fee-value { font-size: 1.5rem; font-weight: 800; color: var(--on-surface); letter-spacing: -0.01em; }
  
  .picker-label { font-size: 0.75rem; font-weight: 700; color: var(--on-surface-variant); text-transform: uppercase; letter-spacing: 0.125em; margin-bottom: 1rem; }
  .dates-row { display: flex; gap: 0.75rem; overflow-x: auto; padding-bottom: 0.75rem; margin-bottom: 1.75rem; }
  .dates-row::-webkit-scrollbar { height: 4px; }
  .dates-row::-webkit-scrollbar-thumb { background: var(--outline-variant); border-radius: 4px; }
  
  .date-btn { min-width: 60px; height: 72px; display: flex; flex-direction: column; align-items: center; justify-content: center; background: var(--surface-container-high); border-radius: 1rem; border: 1px solid transparent; transition: all 0.2s; }
  .date-btn:hover { background: var(--outline-variant); }
  .date-btn.active { border-color: transparent; }
  .date-btn .day { font-size: 0.75rem; font-weight: 600; opacity: 0.8; }
  .date-btn .num { font-size: 1.125rem; font-weight: 800; }

  .book-btn-main { width: 100%; display: flex; align-items: center; justify-content: center; padding: 1.125rem; border-radius: 1rem; color: white; font-weight: 700; font-size: 1.125rem; margin-bottom: 1rem; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.2); transition: all 0.2s; }
  .book-btn-main:hover { transform: translateY(-2px); box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.2); }
  .chat-btn-sec { width: 100%; display: flex; align-items: center; justify-content: center; padding: 1.125rem; border-radius: 1rem; background: var(--surface-container-high); color: var(--on-surface); font-weight: 700; border: 1px solid var(--outline-variant); font-size: 1rem; }
  .chat-btn-sec:hover { background: var(--outline-variant); }
  .booking-note { text-align: center; font-size: 0.8125rem; color: var(--on-surface-variant); font-style: italic; margin-top: 1.5rem; }

  .team-section { margin-top: 2rem; }
  .side-title { font-size: 1.125rem; font-weight: 800; margin-bottom: 1rem; color: var(--on-surface); }
  .experts-stack { display: flex; flex-direction: column; gap: 1rem; }
  .expert-item { display: flex; align-items: center; gap: 1rem; background: var(--surface-container-lowest); padding: 1rem; border-radius: 1.25rem; cursor: pointer; transition: all 0.2s; border: 1px solid var(--outline-variant); box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05); }
  .expert-item:hover { background: var(--surface-bright); border-color: var(--brand); transform: translateX(4px); }
  .expert-avatar { width: 60px; height: 60px; border-radius: 1rem; overflow: hidden; background: var(--surface-container-high); flex-shrink: 0; }
  .expert-avatar img { width: 100%; height: 100%; object-fit: cover; }
  .avatar-ph { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; font-size: 1.5rem; font-weight: 800; color: var(--on-surface-variant); background: var(--secondary-container); }
  .expert-info { flex: 1; }
  .expert-name { font-weight: 700; font-size: 0.9375rem; color: var(--on-surface); }
  .expert-role { font-size: 0.75rem; color: var(--on-surface-variant); margin-top: 0.125rem; }

  .flex-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; }
  .link-btn { font-size: 0.875rem; font-weight: 700; }
  .link-btn:hover { text-decoration: underline; }
</style>
