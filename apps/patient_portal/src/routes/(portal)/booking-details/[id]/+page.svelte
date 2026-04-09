<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { supabase } from '$lib/supabase';
  import { 
    CalendarCheck, 
    Calendar, 
    User, 
    Clock, 
    ChevronRight, 
    CheckCircle2,
    Info
  } from 'lucide-svelte';
  import { fade, slide } from 'svelte/transition';

  const consultationId = $page.params.id;
  export let data;
  $: provider = data.provider;
  $: brandColor = provider?.brand_color || '#003f87';

  let consultation: any = null;
  let isLoading = true;

  onMount(async () => {
    const { data: consultData, error } = await supabase
      .from('consultations')
      .select('*')
      .eq('id', consultationId)
      .single();

    if (error) {
      console.error('Error fetching consultation:', error);
    } else {
      consultation = consultData;
    }
    isLoading = false;
  });

  function getConsultTypeLabel(type: string) {
    return type.replace('_', ' ').toUpperCase();
  }
</script>

<svelte:head>
  <title>Booking Confirmed — {provider?.name}</title>
</svelte:head>

<div class="details-page" style="--brand: {brandColor};">
  <div class="layout-container">
    <div class="glass-bg"></div>
    
    <div class="content-wrapper">
      {#if isLoading}
        <div class="loading-state">
           <div class="dot-spinner"></div>
           <p>Retrieving your booking details...</p>
        </div>
      {:else if consultation}
        <section class="success-hero" in:fade>
          <div class="icon-circle" style="background: {brandColor}15; color: {brandColor};">
            <CheckCircle2 class="w-7 h-7" />
          </div>
          <h1>Booking Confirmed!</h1>
          <p class="hero-sub">We've saved your spot. You'll receive a reminder shortly before your session starts.</p>
        </section>

        <div class="details-card" in:slide={{ duration: 400 }}>
          <div class="card-header">
            <h3>Consultation Summary</h3>
            <span class="status-badge">Scheduled</span>
          </div>

          <div class="info-grid">
            <div class="info-row">
              <div class="info-icon"><User class="w-5 h-5" /></div>
              <div class="info-text">
                <span class="label">Healthcare Provider</span>
                <span class="val">{consultation.provider_name}</span>
              </div>
            </div>

            <div class="info-row">
              <div class="info-icon"><Calendar class="w-5 h-5" /></div>
              <div class="info-text">
                <span class="label">Date & Time</span>
                <span class="val">{new Date(consultation.scheduled_time).toLocaleString(undefined, { dateStyle: 'long', timeStyle: 'short' })}</span>
              </div>
            </div>

            <div class="info-row">
              <div class="info-icon"><Clock class="w-5 h-5" /></div>
              <div class="info-text">
                <span class="label">Service Type</span>
                <span class="val">{getConsultTypeLabel(consultation.type)}</span>
              </div>
            </div>

             <div class="info-row">
              <div class="info-icon"><Info class="w-5 h-5" /></div>
              <div class="info-text">
                <span class="label">Payment Status</span>
                <span class="val text-capitalize">{consultation.payment_status}</span>
              </div>
            </div>
          </div>

          <div class="calendar-alert">
             <CalendarCheck class="w-6 h-6 text-brand" />
             <div class="alert-text">
                <h4>Calendar Integration</h4>
                <p>This appointment will be automatically added to your patient calendar. You can also export it to Google or Outlook from your dashboard.</p>
             </div>
          </div>

          <div class="card-footer">
             <button class="primary-btn" on:click={() => window.location.href = '/'}>
                Back to Portal
             </button>
             <button class="secondary-btn" on:click={() => window.location.href = '/appointments'}>
                View My Appointments
                <ChevronRight class="w-4 h-4" />
             </button>
          </div>
        </div>
      {:else}
        <div class="error-state">
           <h3>Record missing</h3>
           <p>Something went wrong while fetching your booking.</p>
           <a href="/" class="primary-btn">Go Home</a>
        </div>
      {/if}
    </div>
  </div>
</div>

<style>
  .details-page {
    min-height: calc(100vh - 64px);
    background: #fdfdfd;
    padding: 2.5rem 0;
    position: relative;
    display: flex;
    align-items: center;
  }

  .content-wrapper { position: relative; z-index: 1; max-width: 520px; margin: 0 auto; width: 100%; padding: 0 1rem; }

  /* Hero */
  .success-hero { text-align: center; margin-bottom: 1.25rem; }
  .icon-circle { width: 56px; height: 56px; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 1rem; }
  .success-hero h1 { font-size: 1.5rem; font-weight: 800; color: #0f172a; margin-bottom: 0.25rem; letter-spacing: -0.02em; }
  .hero-sub { font-size: 0.875rem; color: #64748b; line-height: 1.4; }

  /* Card */
  .details-card {
    background: white;
    border-radius: 1.25rem;
    padding: 1.5rem;
    box-shadow: 0 15px 30px -10px rgba(0, 0, 0, 0.05);
    border: 1px solid #f1f5f9;
  }

  .card-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem; }
  .card-header h3 { font-size: 1rem; font-weight: 800; color: #0f172a; }
  .status-badge { padding: 0.25rem 0.6rem; background: #f0fdf4; color: #15803d; border-radius: 99px; font-size: 0.7rem; font-weight: 700; text-transform: uppercase; }

  .info-grid { display: grid; grid-template-columns: 1fr; gap: 1rem; margin-bottom: 1.5rem; }
  @media (min-width: 640px) { .info-grid { grid-template-columns: 1fr 1fr; } }

  .info-row { display: flex; align-items: center; gap: 0.75rem; }
  .info-icon { width: 32px; height: 32px; border-radius: 8px; background: #f8fafc; color: var(--brand); display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
  .info-text { display: flex; flex-direction: column; gap: 0.1rem; }
  .label { font-size: 0.6rem; font-weight: 700; color: #94a3b8; text-transform: uppercase; }
  .val { font-size: 0.8125rem; font-weight: 700; color: #1e293b; }

  .calendar-alert {
    background: #f8fbff;
    border: 1px solid #e0f2fe;
    border-radius: 0.75rem;
    padding: 0.75rem 1rem;
    display: flex;
    align-items: center;
    gap: 0.75rem;
    margin-bottom: 1.5rem;
  }
  .alert-text h4 { font-size: 0.875rem; font-weight: 700; color: #0369a1; margin-bottom: 0.2rem; }
  .alert-text p { font-size: 0.75rem; color: #075985; line-height: 1.6; }

  .card-footer { display: flex; flex-direction: column; gap: 0.75rem; }
  @media (min-width: 640px) { .card-footer { flex-direction: row; } }

  .primary-btn { flex: 1; padding: 0.875rem; border-radius: 0.75rem; background: var(--brand); color: white; font-weight: 700; font-size: 0.875rem; text-align: center; }
  .secondary-btn { flex: 1; padding: 0.875rem; border-radius: 0.75rem; background: #f1f5f9; color: #1e293b; font-weight: 700; font-size: 0.875rem; display: flex; align-items: center; justify-content: center; gap: 0.5rem; }
  .secondary-btn:hover { background: #e2e8f0; }

  .loading-state, .error-state { text-align: center; padding: 4rem 0; }
  .dot-spinner { width: 40px; height: 40px; border: 4px solid #f1f5f9; border-top-color: var(--brand); border-radius: 50%; animation: spin 0.8s linear infinite; margin: 0 auto 1.5rem; }
  @keyframes spin { to { transform: rotate(360deg); } }
  .text-capitalize { text-transform: capitalize; }
</style>
