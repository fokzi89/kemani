<script lang="ts">
  import '../../app.css';
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { authStore, isAuthenticated, currentUser } from '$lib/stores/auth';
  import { supabase } from '$lib/supabase';
  import { 
    Menu, X, Bell, User as UserIcon, Search, 
    Mail, Phone, Globe, Share2, HeartPulse, ShoppingCart 
  } from 'lucide-svelte';
  import { cartStore, cartTotalItems } from '$lib/stores/cart';

  export let data;
  $: provider = data.provider;
  $: brandColor = provider?.brand_color || '#003f87';

  let isMobileMenuOpen = false;
  let isProfileMenuOpen = false;

  function toggleMobileMenu() { isMobileMenuOpen = !isMobileMenuOpen; isProfileMenuOpen = false; }
  function toggleProfileMenu() { isProfileMenuOpen = !isProfileMenuOpen; isMobileMenuOpen = false; }

  function handleProfileClick() {
    if (window.innerWidth < 768) {
      toggleMobileMenu();
    } else {
      toggleProfileMenu();
    }
  }

  async function signInWithGoogle() {
    // Determine the base origin for the auth callback. 
    // This URL must be whitelisted in the Supabase/Google console.
    const baseOrigin = $page.url.host.includes('localhost') 
      ? `${$page.url.protocol}//localhost:5144` 
      : `${$page.url.protocol}//kemani.com`;

    // The current URL (including subdomain) to return to after auth
    const returnTo = encodeURIComponent($page.url.href);
    
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${baseOrigin}/auth/callback?next=${returnTo}`
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
            {#if provider?.logo_url}
              <img src={provider.logo_url} alt={provider?.name || 'Logo'} class="w-6 h-6 object-cover rounded" />
            {:else}
              <svg fill="none" viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg" class="w-6 h-6">
                <path clip-rule="evenodd" d="M47.2426 24L24 47.2426L0.757355 24L24 0.757355L47.2426 24ZM12.2426 21H35.7574L24 9.24264L12.2426 21Z" fill="currentColor" fill-rule="evenodd"></path>
              </svg>
            {/if}
          </div>
          <span class="logo-text">{provider?.name || 'Kemani Patient Portal'}</span>
        </a>

        <nav class="desktop-nav">
          <a href="/doctors" class="nav-link" class:active={$page.url.pathname === '/doctors'}>
            {provider ? 'Our Doctors' : 'Doctors list'}
          </a>
          <a href="/pharmacies" class="nav-link" class:active={$page.url.pathname === '/pharmacies'}>
            Pharmacy Shops
          </a>
          <a href="/diagnostics" class="nav-link" class:active={$page.url.pathname === '/diagnostics'}>Diagnostic centre</a>
        </nav>
      </div>

      <div class="nav-right">
        <div class="search-bar">
          <Search class="w-4 h-4 text-outline" />
          <input 
            type="text" 
            placeholder="Find a doctor..." 
            on:keydown={(e) => {
              if (e.key === 'Enter') {
                const q = encodeURIComponent(e.currentTarget.value);
                const path = $page.url.pathname.includes('/pharmacies') ? '/pharmacies' : '/doctors';
                goto(`${path}?q=${q}`);
              }
            }}
          />
        </div>

        <div class="nav-actions">
          <button class="icon-btn"><Bell class="w-5 h-5" /></button>
          
          {#if $isAuthenticated}
            <div class="profile-container">
              <button class="profile-btn" on:click={handleProfileClick}>
                {#if $currentUser?.user_metadata?.avatar_url}
                  <img src={$currentUser.user_metadata.avatar_url} alt="Profile" class="avatar" />
                {:else}
                  <div class="avatar-placeholder"><UserIcon class="w-5 h-5" /></div>
                {/if}
              </button>

              {#if isProfileMenuOpen && !isMobileMenuOpen}
                <div class="profile-menu">
                  <div class="menu-header">
                    <p class="user-name">{$currentUser?.user_metadata?.full_name || 'Patient'}</p>
                    <p class="user-email">{$currentUser?.email}</p>
                  </div>
                  <hr />
                  <a href="/appointments" class="menu-item" on:click={() => isProfileMenuOpen = false}>My Appointments</a>
                  <a href="/prescriptions" class="menu-item" on:click={() => isProfileMenuOpen = false}>Prescriptions</a>
                  <a href="/lab-tests" class="menu-item" on:click={() => isProfileMenuOpen = false}>Lab Tests</a>
                  <a href="/orders" class="menu-item" on:click={() => isProfileMenuOpen = false}>Order History</a>
                  <a href="/profile" class="menu-item" on:click={() => isProfileMenuOpen = false}>My Profile</a>
                  <hr />
                  <button class="menu-item text-error" on:click={handleSignOut}>Sign Out</button>
                </div>
              {/if}
            </div>
          {:else}
            <button class="icon-btn" on:click={handleProfileClick}>
              <UserIcon class="w-5 h-5" />
            </button>
          {/if}
        </div>
      </div>
    </div>

    <!-- Mobile Menu Overlay -->
    {#if isMobileMenuOpen}
      <div class="mobile-menu">
        <div class="mobile-menu-header">
           <button class="mobile-close" on:click={toggleMobileMenu}><X class="w-7 h-7" /></button>
           {#if $isAuthenticated}
             <div class="mobile-user-info">
                <p class="m-user-name">{$currentUser?.user_metadata?.full_name || 'Patient'}</p>
                <p class="m-user-email">{$currentUser?.email}</p>
             </div>
           {/if}
        </div>
        <nav class="mobile-nav">
          <a href="/doctors" on:click={toggleMobileMenu}>Doctors list</a>
          <a href="/pharmacies" on:click={toggleMobileMenu}>Pharmacy Shops</a>
          <a href="/diagnostics" on:click={toggleMobileMenu}>Diagnostic centre</a>
          <hr />
          {#if !$isAuthenticated}
            <button class="m-auth-btn" on:click={signInWithGoogle}>Sign In</button>
          {:else}
            <a href="/appointments" on:click={toggleMobileMenu}>Appointments</a>
            <a href="/prescriptions" on:click={toggleMobileMenu}>Prescriptions</a>
            <a href="/lab-tests" on:click={toggleMobileMenu}>Lab Tests</a>
            <a href="/orders" on:click={toggleMobileMenu}>Order History</a>
            <a href="/profile" on:click={toggleMobileMenu}>Profile</a>
            <button class="m-auth-btn text-error" on:click={handleSignOut}>Sign Out</button>
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
  <!-- Floating Cart Icon -->
  {#if $cartTotalItems > 0}
    <a 
      href="/checkout" 
      class="floating-cart" 
      in:fade={{ duration: 200 }} 
      out:fade={{ duration: 200 }}
      style="background: {brandColor};"
    >
      <ShoppingCart class="w-6 h-6" />
      <span class="cart-badge">{$cartTotalItems}</span>
    </a>
  {/if}
</div>

<style>
  .floating-cart {
    position: fixed;
    bottom: 2rem;
    right: 2rem;
    width: 64px;
    height: 64px;
    border-radius: 50%;
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 10px 25px -5px rgba(0,0,0,0.2);
    z-index: 999;
    transition: transform 0.2s;
    text-decoration: none;
  }
  .floating-cart:hover { transform: scale(1.1); }
  .cart-badge {
    position: absolute;
    top: -5px;
    right: -5px;
    background: #ff3e00;
    color: white;
    font-size: 0.75rem;
    font-weight: 800;
    width: 24px;
    height: 24px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    border: 2px solid white;
  }

  .app-layout { min-height: 100vh; display: flex; flex-direction: column; background: var(--surface); }
  
  .navbar { background: #ffffff; border-bottom: 1px solid var(--outline-variant); position: sticky; top: 0; z-index: 1000; height: 64px; display: flex; align-items: center; }
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
  
  .mobile-menu { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: white; z-index: 2000; padding: 1rem; display: flex; flex-direction: column; gap: 1.5rem; }
  .mobile-menu-header { display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid var(--outline-variant); padding-bottom: 1rem; }
  .mobile-close { width: 40px; height: 40px; display: flex; align-items: center; justify-content: center; background: var(--surface-container-low); border-radius: 50%; color: var(--on-surface); }
  .mobile-user-info { text-align: right; }
  .m-user-name { font-weight: 800; font-size: 1rem; color: var(--on-surface); line-height: 1.2; }
  .m-user-email { font-size: 0.75rem; color: var(--on-surface-variant); }

  .mobile-nav { display: flex; flex-direction: column; gap: 0.875rem; }
  .mobile-nav a { font-size: 1.125rem; font-weight: 800; text-align: left; font-family: var(--font-headline); color: var(--on-surface); text-decoration: none; padding: 0.35rem 0; }
  .m-auth-btn { background: var(--brand); color: white; padding: 0.875rem; border-radius: 0.875rem; font-size: 1rem; font-weight: 800; width: 100%; margin-top: 0.5rem; }
  .m-auth-btn.text-error { background: #fef2f2; color: #ba1a1a; }
  
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
