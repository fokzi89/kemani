<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase';
  import { 
    Clock, 
    CheckCircle2, 
    XCircle, 
    Loader2, 
    User, 
    Calendar, 
    MessageSquare, 
    Video, 
    Phone,
    ArrowRight
  } from 'lucide-svelte';
  import { fade, scale } from 'svelte/transition';

  const consultationId = $page.params.id;
  export let data;
  $: provider = data.provider;
  $: brandColor = provider?.brand_color || '#003f87';

  let consultation: any = null;
  let isLoading = true;
  let status = 'pending'; // pending, accepted, rejected, completed
  let subscription: any = null;

  async function fetchConsultation() {
    isLoading = true;
    const { data: consultData, error } = await supabase
      .from('consultations')
      .select('*')
      .eq('id', consultationId)
      .single();

    if (error) {
      console.error('Error fetching consultation:', error);
    } else {
      consultation = consultData;
      status = consultData.status;

      // Initial check if already accepted
      if (status === 'accepted' || status === 'in_progress') {
        handleRedirect(consultData);
      }
    }
    isLoading = false;
  }

  onMount(() => {
    fetchConsultation();

    // Subscribe to realtime updates
    subscription = supabase
      .channel(`consultation-${consultationId}`)
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'consultations',
          filter: `id=eq.${consultationId}`
        },
        (payload) => {
          console.log('Consultation updated:', payload.new);
          consultation = payload.new;
          status = payload.new.status;
          
          // Automatic redirection on acceptance
          if (status === 'accepted' || status === 'in_progress') {
             handleRedirect(payload.new);
          }
        }
      )
      .subscribe();
  });

  function handleRedirect(c: any) {
    if (c.type === 'chat') {
      goto(`/consultation/${c.id}/chat`);
    } else {
      goto(`/consultation/${c.id}/call`);
    }
  }

  onDestroy(() => {
    if (subscription) {
      supabase.removeChannel(subscription);
    }
  });

  function getStatusConfig(s: string) {
    switch (s) {
      case 'accepted':
      case 'in_progress':
        return {
          icon: CheckCircle2,
          color: '#10b981',
          title: 'Booking Accepted!',
          desc: 'Your doctor is ready to see you. Please wait as we redirect you to the consultation room.',
          isFinal: true
        };
      case 'rejected':
      case 'cancelled':
        return {
          icon: XCircle,
          color: '#ef4444',
          title: 'Booking Cancelled',
          desc: 'This consultation has been cancelled or rejected by the provider.',
          isFinal: true
        };
      case 'completed':
        return {
          icon: CheckCircle2,
          color: '#6366f1',
          title: 'Consultation Completed',
          desc: 'This session has ended. Thank you for using our services.',
          isFinal: true
        };
      default:
        return {
          icon: Clock,
          color: brandColor,
          title: 'Waiting for Doctor',
          desc: 'Your booking has been received. Please stay on this page; the doctor will review and accept your request shortly.',
          isFinal: false
        };
    }
  }

  $: config = getStatusConfig(status);

  function getConsultIcon(type: string) {
    switch (type) {
      case 'video': return Video;
      case 'audio': return Phone;
      case 'chat': return MessageSquare;
      default: return Calendar;
    }
  }
</script>

<svelte:head>
  <title>Waiting Area — {provider?.name}</title>
</svelte:head>

<div class="waiting-area" style="--brand: {brandColor};">
  <div class="layout-container">
    <div class="glass-orb orb-1"></div>
    <div class="glass-orb orb-2"></div>
    
    <div class="main-card" in:scale={{ duration: 400, start: 0.95 }}>
      {#if isLoading}
        <div class="loader-overlay">
          <Loader2 class="animate-spin w-8 h-8 text-brand" />
          <p>Connecting...</p>
        </div>
      {:else if !consultation}
        <div class="error-state">
           <XCircle class="w-12 h-12 text-error mb-4" />
           <h2>Link Not Found</h2>
           <p>We couldn't find a record with that ID.</p>
           <button class="back-btn" on:click={() => window.location.href = '/'}>Return Home</button>
        </div>
      {:else}
        <div class="status-header">
           <div class="icon-pulse" style="background: {config.color}15; color: {config.color};">
              <svelte:component this={config.icon} class="w-7 h-7" />
              {#if !config.isFinal}
                <div class="pulse-ring" style="border-color: {config.color};"></div>
              {/if}
           </div>
           <h1 class="status-title">{config.title}</h1>
           <p class="status-desc">{config.desc}</p>
        </div>

        <div class="booking-summary">
           <div class="summary-grid">
              <div class="summary-item">
                 <span class="label">PROVIDER</span>
                 <div class="val-row">
                    <div class="mini-avatar">
                       {#if consultation.provider_photo_url}
                          <img src={consultation.provider_photo_url} alt={consultation.provider_name} />
                       {:else}
                          <div class="avatar-ph">{consultation.provider_name?.charAt(0)}</div>
                       {/if}
                    </div>
                    <span class="val">{consultation.provider_name}</span>
                 </div>
              </div>
              <div class="summary-item">
                 <span class="label">SERVICE</span>
                 <div class="val-row">
                    <svelte:component this={getConsultIcon(consultation.type)} class="w-4 h-4 text-brand" />
                    <span class="val text-capitalize">{consultation.type.replace('_', ' ')}</span>
                 </div>
              </div>
              <div class="summary-item">
                 <span class="label">SCHEDULED</span>
                 <div class="val-row">
                    <Calendar class="w-4 h-4 text-brand" />
                    <span class="val">{new Date(consultation.scheduled_time).toLocaleString(undefined, { dateStyle: 'short', timeStyle: 'short' })}</span>
                 </div>
              </div>
              <div class="summary-item">
                 <span class="label">FEES</span>
                 <div class="val-row">
                    <span class="val font-bold">₦{consultation.consultation_fee?.toLocaleString()}</span>
                 </div>
              </div>
           </div>
        </div>

        {#if status === 'pending'}
          <div class="action-footer">
             <div class="loading-bar">
                <div class="bar-fill" style="background: {brandColor};"></div>
             </div>
             <p class="footer-tip">Tip: Keep this tab open. You will be notified instantly.</p>
          </div>
        {:else if status === 'accepted' || status === 'in_progress'}
          <div class="action-footer" in:fade>
             <button class="enter-btn cta-gradient" style="background: {brandColor};" on:click={() => handleRedirect(consultation)}>
                Enter Consultation Room
                <ArrowRight class="ml-2 w-5 h-5" />
             </button>
          </div>
        {/if}
      {/if}
    </div>
  </div>
</div>

<style>
  .waiting-area {
    min-height: calc(100vh - 64px);
    background: #f8fafc;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 1rem;
    position: relative;
    overflow: hidden;
  }

  .glass-orb {
    position: absolute;
    width: 300px;
    height: 300px;
    border-radius: 50%;
    filter: blur(80px);
    opacity: 0.1;
    z-index: 0;
  }
  .orb-1 { top: -50px; left: -50px; background: var(--brand); }
  .orb-2 { bottom: -50px; right: -50px; background: #6366f1; }

  .main-card {
    position: relative;
    z-index: 1;
    background: white;
    width: 100%;
    max-width: 520px;
    border-radius: 2rem;
    padding: 2rem;
    box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.1);
    border: 1px solid rgba(0, 0, 0, 0.05);
    text-align: center;
  }

  .loader-overlay {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
    padding: 2rem 0;
  }
  .loader-overlay p { font-weight: 600; color: #64748b; font-size: 0.875rem; }

  .icon-pulse {
    width: 64px;
    height: 64px;
    border-radius: 1.25rem;
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 0 auto 1.25rem;
    position: relative;
  }

  .pulse-ring {
    position: absolute;
    top: 0; left: 0; right: 0; bottom: 0;
    border: 2px solid;
    border-radius: 1.25rem;
    animation: ring-pulse 2s infinite;
  }

  @keyframes ring-pulse {
    0% { transform: scale(1); opacity: 0.8; }
    100% { transform: scale(1.3); opacity: 0; }
  }

  .status-title {
    font-size: 1.5rem;
    font-weight: 900;
    color: #0f172a;
    margin-bottom: 0.5rem;
    letter-spacing: -0.03em;
  }

  .status-desc {
    font-size: 0.9375rem;
    color: #64748b;
    line-height: 1.5;
    margin-bottom: 1.5rem;
    max-width: 420px;
    margin-left: auto;
    margin-right: auto;
  }

  .booking-summary {
    background: #f8fafc;
    border-radius: 1.25rem;
    padding: 1.25rem;
    margin-bottom: 1.5rem;
    text-align: left;
    border: 1px solid #f1f5f9;
  }

  .summary-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1.25rem;
  }

  .summary-item { display: flex; flex-direction: column; gap: 0.25rem; }
  .label { font-size: 0.6rem; font-weight: 800; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
  
  .val-row { display: flex; align-items: center; gap: 0.5rem; }
  .val { font-size: 0.875rem; font-weight: 700; color: #1e293b; }
  .text-capitalize { text-transform: capitalize; }

  .mini-avatar { width: 24px; height: 24px; border-radius: 50%; overflow: hidden; background: #e2e8f0; }
  .mini-avatar img { width: 100%; height: 100%; object-fit: cover; }
  .avatar-ph { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; font-size: 0.7rem; font-weight: 800; }

  .action-footer { margin-top: 0.5rem; }

  .loading-bar {
    height: 4px;
    background: #e2e8f0;
    border-radius: 99px;
    overflow: hidden;
    margin-bottom: 1rem;
  }

  .bar-fill {
    height: 100%;
    width: 100%;
    animation: loading-slide 2s infinite ease-in-out;
    transform-origin: left;
  }

  @keyframes loading-slide {
    0% { transform: scaleX(0); }
    50% { transform: scaleX(0.5); transform: translateX(25%); }
    100% { transform: scaleX(1); opacity: 0; }
  }

  .footer-tip { font-size: 0.8125rem; color: #94a3b8; font-style: italic; }

  .enter-btn {
    width: 100%;
    padding: 1rem;
    border-radius: 1rem;
    color: white;
    font-weight: 800;
    font-size: 1rem;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1);
    cursor: pointer;
    transition: all 0.2s;
  }

  .back-btn {
    margin-top: 1rem;
    padding: 0.6rem 1.5rem;
    border-radius: 0.75rem;
    background: #f1f5f9;
    font-weight: 700;
    color: #1e293b;
    font-size: 0.875rem;
  }

  @media (max-width: 640px) {
    .main-card { padding: 1.5rem; }
    .summary-grid { grid-template-columns: 1fr; gap: 1rem; }
  }
</style>
