<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/stores';

  onMount(() => {
    // Supabase Implicit Flow appends tokens to the hash
    const hash = window.location.hash;
    const nextUrlParams = $page.url.searchParams.get('next');
    
    // Default to the profile page on the root domain if no next exists
    const nextPath = nextUrlParams || '/profile';
    
    if (hash && hash.includes('access_token')) {
        // We have implicit flow tokens!
        // We redirect to the target domain, appending the hash so the target layout can handle it
        const targetUrl = new URL(nextPath, window.location.origin);
        targetUrl.hash = hash;
        window.location.replace(targetUrl.toString());
    } else {
        // If there is a code, we can let another mechanism handle it or fallback
        // Since we removed +server.ts, we need to handle it or error out
        // Wait, if no hash, redirect to error page
        console.warn('No access token found in hash during OAuth callback.');
        window.location.replace('/auth/error');
    }
  });
</script>

<div class="flex items-center justify-center min-h-screen bg-gray-50">
    <div class="text-center">
        <div class="w-16 h-16 border-4 border-blue-600 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
        <h2 class="text-xl font-semibold text-gray-900 mb-2">Authenticating...</h2>
        <p class="text-sm text-gray-500">Please wait while we log you in securely.</p>
    </div>
</div>
