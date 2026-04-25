<script lang="ts">
    import { onMount } from 'svelte';
    import { goto } from '$app/navigation';

    onMount(() => {
        goto('/auth/login', { replaceState: true });
    });
</script>

<div class="flex items-center justify-center min-h-screen bg-gray-50">
    <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
</div>
