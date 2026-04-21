<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/stores';

  onMount(() => {
    // Supabase Implicit Flow appends tokens to the hash
    const hash = window.location.hash;

    // Prefer the `next` query param, then fall back to the storefront URL saved before login
    const nextUrlParam = $page.url.searchParams.get('next');
    const storedReturn = localStorage.getItem('storefront_return_url');

    // Default profile page only as last resort
    const nextPath = nextUrlParam || storedReturn || '/profile';

    // Clean up stored return URL
    localStorage.removeItem('storefront_return_url');

    if (hash && hash.includes('access_token')) {
        let targetUrl: URL;

        try {
            // If nextPath is already a full URL (e.g. http://lanre-pharmacy-yapqx.localhost:5174/)
            // use it directly — new URL(full, base) ignores base when full is absolute
            targetUrl = new URL(nextPath);
        } catch {
            // nextPath is a relative path — resolve against current origin
            targetUrl = new URL(nextPath, window.location.origin);
        }

        // Append the hash so the target layout can exchange tokens
        targetUrl.hash = hash;
        window.location.replace(targetUrl.toString());
    } else {
        console.warn('No access token found in hash during OAuth callback.');
        // Try to go back to storefront even on error
        const fallback = storedReturn || '/';
        window.location.replace(fallback);
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
