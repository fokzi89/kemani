<script lang="ts">
  import '../../app.css';
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { authStore, isAuthenticated, currentUser } from '$lib/stores/auth';
  import { supabase } from '$lib/supabase';
  import { 
    Menu, X, Bell, User as UserIcon, Search, 
    Mail, Phone, Globe, Share2, HeartPulse 
  } from 'lucide-svelte';

  export let data;
  $: provider = data.provider;
  $: brandColor = provider?.brand_color || '#003f87';

  let isMobileMenuOpen = false;
  let isProfileMenuOpen = false;

  function toggleMobileMenu() { isMobileMenuOpen = !isMobileMenuOpen; }
  function toggleProfileMenu() { isProfileMenuOpen = !isProfileMenuOpen; }

  async function signInWithGoogle() {
    const next = window.location.href;
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${window.location.origin}/auth/callback?next=${encodeURIComponent(next)}`
      }
    });
    if (error) console.error('Google sign-in error:', error);
  }

  async function handleSignOut() {
    await supabase.auth.signOut();
    authStore.clearAuth();
    isProfileMenuOpen = false;
    goto('/');
  }

  onMount(() => {
    authStore.initialize();
  });
</script>

<div class="app-layout" style="--brand: {brandColor};">
  <!-- Top Navigation -->
  <header class="navbar">
    <div class="layout-container nav-inner">
      <div class="nav-left">
        <a href="/" class="logo">
          <div class="logo-icon" style="color: {brandColor};">
            <svg fill="none" viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg" class="w-6 h-6">
              <path clip-rule="evenodd" d="M47.2426 24L24 47.2426L0.757355 24L24 0.757355L47.2426 24ZM12.2426 21H35.7574L24 9.24264L12.2426 21Z" fill="currentColor" fill-rule="evenodd"></path>
            </svg>
          </div>
          <span class="logo-text">{provider?.name || 'Healthcare Portal'}</span>
        </a>

        <nav class="desktop-nav">
          <a href="/doctors" class="nav-link" class:active={$page.url.pathname === '/doctors'}>Doctors list</a>
          <a href="/pharmacies" class="nav-link" class:active={$page.url.pathname === '/pharmacies'}>Pharmacy shops</a>
          <a href="/diagnostics" class="nav-link" class:active={$page.url.pathname === '/diagnostics'}>Diagnostic centre</a>
        </nav>
      </div>

      <div class="nav-right">
        <div class="search-bar">
          <Search class="w-4 h-4 text-outline" />
          <input type="text" placeholder="Find a doctor..." />
        </div>

        <div class="nav-actions">
          <button class="icon-btn"><Bell class="w-5 h-5" /></button>
          
          {#if $isAuthenticated}
            <div class="profile-container">
              <button class="profile-btn" on:click={toggleProfileMenu}>
                {#if $currentUser?.user_metadata?.avatar_url}
                  <img src={$currentUser.user_metadata.avatar_url} alt="Profile" class="avatar" />
                {:else}
                  <div class="avatar-placeholder"><UserIcon class="w-5 h-5" /></div>
                {/if}
              </button>

              {#if isProfileMenuOpen}
                <div class="profile-menu">
                  <div class="menu-header">
                    <p class="user-name">{$currentUser?.user_metadata?.full_name || 'Patient'}</p>
                    <p class="user-email">{$currentUser?.email}</p>
                  </div>
                  <hr />
                  <a href="/profile" class="menu-item" on:click={() => isProfileMenuOpen = false}>My Profile</a>
                  <hr />
                  <button class="menu-item text-error" on:click={handleSignOut}>Sign Out</button>
                </div>
              {/if}
            </div>
          {:else}
            <button class="icon-btn" on:click={signInWithGoogle}>
              <UserIcon class="w-5 h-5" />
            </button>
          {/if}

          <button class="mobile-toggle" on:click={toggleMobileMenu}>
            {#if isMobileMenuOpen}<X class="w-6 h-6" />{:else}<Menu class="w-6 h-6" />{/if}
          </button>
        </div>
      </div>
    </div>

    <!-- Mobile Menu Overlay -->
    {#if isMobileMenuOpen}
      <div class="mobile-menu">
        <nav class="mobile-nav">
          <a href="/doctors" on:click={toggleMobileMenu}>Doctors list</a>
          <a href="/pharmacies" on:click={toggleMobileMenu}>Pharmacy shops</a>
          <a href="/diagnostics" on:click={toggleMobileMenu}>Diagnostic centre</a>
          <hr />
          {#if !$isAuthenticated}
            <button on:click={signInWithGoogle}>Sign In</button>
          {:else}
            <a href="/profile" on:click={toggleMobileMenu}>Profile</a>
            <button on:click={handleSignOut}>Sign Out</button>
          {/if}
        </nav>
      </div>
    {/if}
  </header>

  <!-- Main Content -->
  <main class="main-content">
    <slot />
  </main>

  <!-- Footer -->
  <footer class="footer">
    <div class="layout-container">
      <div class="footer-top">
        <div class="footer-info">
          <div class="logo footer-logo">
            <svg fill="none" viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg" class="w-6 h-6" style="color: {brandColor};">
              <path clip-rule="evenodd" d="M47.2426 24L24 47.2426L0.757355 24L24 0.757355L47.2426 24ZM12.2426 21H35.7574L24 9.24264L12.2426 21Z" fill="currentColor" fill-rule="evenodd"></path>
            </svg>
            <h2 class="text-xl font-bold">{provider?.name || 'Healthcare Portal'}</h2>
          </div>
          <p class="footer-desc">
            Connecting patients with the world's leading medical specialists. Quality healthcare, just a click away.
          </p>
        </div>

        <div class="footer-links-grid">
          <div class="footer-col">
            <h4>Company</h4>
            <a href="#">About Us</a>
            <a href="#">Careers</a>
            <a href="#">Press</a>
          </div>
          <div class="footer-col">
            <h4>Support</h4>
            <a href="#">Help Center</a>
            <a href="#">Privacy Policy</a>
            <a href="#">Terms of Service</a>
          </div>
          <div class="footer-col">
            <h4>Contact</h4>
            <div class="contact-item"><Mail class="w-4 h-4" /> <span>{provider?.email || 'support@kemani.com'}</span></div>
            <div class="contact-item"><Phone class="w-4 h-4" /> <span>{provider?.phone || '+1 (555) 000-1234'}</span></div>
          </div>
        </div>
      </div>

      <div class="footer-bottom">
        <p>© {new Date().getFullYear()} {provider?.name || 'Healthcare Portal'} Inc. All rights reserved.</p>
        <div class="footer-actions">
          <Globe class="w-4 h-4 cursor-pointer" />
          <Share2 class="w-4 h-4 cursor-pointer" />
        </div>
      </div>
    </div>
  </footer>
</div>

<style>
  .app-layout { min-height: 100vh; display: flex; flex-direction: column; background: var(--surface); }
  
  .navbar { background: var(--surface-container-lowest); border-bottom: 1px solid var(--outline-variant); position: sticky; top: 0; z-index: 1000; height: 64px; display: flex; align-items: center; }
  .nav-inner { display: flex; align-items: center; justify-content: space-between; width: 100%; }
  
  .nav-left { display: flex; align-items: center; gap: 2.25rem; }
  .logo { display: flex; align-items: center; gap: 0.6rem; text-decoration: none; }
  .logo-text { font-family: var(--font-headline); font-size: 1rem; font-weight: 800; color: var(--on-surface); letter-spacing: -0.015em; }
  
  .desktop-nav { display: none; align-items: center; gap: 2rem; }
  @media (min-width: 768px) { .desktop-nav { display: flex; } }
  .nav-link { font-size: 0.8125rem; font-weight: 500; color: var(--on-surface); transition: color 0.2s; }
  .nav-link:hover { color: var(--brand); }
  .nav-link.active { color: var(--brand); font-weight: 600; }
  
  .nav-right { display: flex; align-items: center; gap: 1.5rem; }
  .search-bar { display: none; align-items: center; background: var(--surface-container-low); padding: 0 1rem; border-radius: var(--radius-xl); height: 40px; width: 240px; }
  @media (min-width: 1024px) { .search-bar { display: flex; } }
  .search-bar input { border: none; background: transparent; padding-left: 0.75rem; font-size: 0.875rem; outline: none; width: 100%; }
  
  .nav-actions { display: flex; align-items: center; gap: 0.75rem; }
  .icon-btn { display: flex; align-items: center; justify-content: center; width: 40px; height: 40px; background: var(--surface-container-high); border-radius: 0.75rem; color: var(--on-surface); transition: all 0.2s; }
  .icon-btn:hover { background: var(--outline-variant); }
  
  .profile-container { position: relative; }
  .profile-btn { width: 40px; height: 40px; border-radius: 50%; overflow: hidden; border: 1px solid var(--outline-variant); background: white; }
  .avatar { width: 100%; height: 100%; object-fit: cover; }
  .avatar-placeholder { width: 100%; height: 100%; background: var(--secondary-container); display: flex; align-items: center; justify-content: center; color: var(--on-secondary-container); }
  
  .profile-menu { position: absolute; top: 50px; right: 0; min-width: 200px; background: white; border-radius: 1rem; border: 1px solid var(--outline-variant); box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1); padding: 0.4rem 0; z-index: 1001; }
  .menu-header { padding: 0.6rem 1rem; }
  .user-name { font-weight: 700; font-size: 0.8125rem; color: var(--on-surface); }
  .user-email { font-size: 0.7rem; color: var(--on-surface-variant); }
  .menu-item { display: block; width: 100%; text-align: left; padding: 0.5rem 1rem; font-size: 0.8125rem; color: var(--on-surface); font-weight: 500; }
  .menu-item:hover { background: var(--surface-container-low); color: var(--brand); }
  .text-error { color: #ba1a1a; }
  
  .mobile-toggle { display: flex; align-items: center; justify-content: center; width: 40px; height: 40px; }
  @media (min-width: 768px) { .mobile-toggle { display: none; } }
  
  .mobile-menu { position: fixed; top: 64px; left: 0; right: 0; bottom: 0; background: white; z-index: 999; padding: 2rem; }
  .mobile-nav { display: flex; flex-direction: column; gap: 1.5rem; }
  .mobile-nav a, .mobile-nav button { font-size: 1.25rem; font-weight: 700; text-align: left; font-family: var(--font-headline); color: var(--on-surface); }
  
  .main-content { flex: 1; }
  
  .footer { background: var(--surface-container-lowest); border-top: 1px solid var(--outline-variant); padding: 3rem 0 2rem; margin-top: auto; }
  .footer-top { display: flex; flex-direction: column; gap: 2.5rem; margin-bottom: 2.5rem; }
  @media (min-width: 768px) { .footer-top { flex-direction: row; justify-content: space-between; } }
  .footer-info { max-width: 300px; }
  .footer-logo { display: flex; align-items: center; gap: 0.6rem; margin-bottom: 1rem; }
  .footer-desc { font-size: 0.8125rem; color: var(--on-surface-variant); line-height: 1.6; }
  
  .footer-links-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1.5rem; }
  @media (min-width: 640px) { .footer-links-grid { grid-template-columns: repeat(3, 1fr); } }
  .footer-col h4 { font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 1.25rem; color: var(--on-surface); font-weight: 800; }
  .footer-col a, .contact-item { display: flex; align-items: center; gap: 0.5rem; font-size: 0.8125rem; color: var(--on-surface-variant); margin-bottom: 0.75rem; transition: color 0.2s; font-weight: 500; }
  .footer-col a:hover { color: var(--brand); }
  
  .footer-bottom { border-top: 1px solid var(--outline-variant); padding-top: 2rem; display: flex; justify-content: space-between; align-items: center; font-size: 0.75rem; color: var(--on-surface-variant); }
  .footer-actions { display: flex; gap: 1.25rem; }
</style>
