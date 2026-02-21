<script lang="ts">
    import { auth } from "$lib/stores/auth";
    import { page } from "$app/stores";
    import { goto } from "$app/navigation";
    import { createEventDispatcher } from "svelte";

    const dispatch = createEventDispatcher();

    export let redirectTo: string = "/";
    export let mode: "page" | "modal" = "page";

    let email = "";
    let emailSent = false;
    let loading = false;
    let errorMsg = "";

    $: supabase = $page.data.supabase;

    async function handleGoogle() {
        loading = true;
        errorMsg = "";
        try {
            await auth.signInWithGoogle(supabase);
        } catch (e: any) {
            errorMsg = e.message || "Failed to sign in with Google";
            loading = false;
        }
    }

    async function handleApple() {
        loading = true;
        errorMsg = "";
        try {
            await auth.signInWithApple(supabase);
        } catch (e: any) {
            errorMsg = e.message || "Failed to sign in with Apple";
            loading = false;
        }
    }

    async function handleEmail() {
        if (!email.trim()) return;
        loading = true;
        errorMsg = "";
        try {
            await auth.signInWithEmail(supabase, email);
            emailSent = true;
        } catch (e: any) {
            errorMsg = e.message || "Failed to send magic link";
        } finally {
            loading = false;
        }
    }
</script>

<div class="mx-auto w-full max-w-sm space-y-6">
    {#if mode === "page"}
        <div class="text-center">
            <h1 class="text-2xl font-bold tracking-tight text-foreground">
                Welcome back
            </h1>
            <p class="mt-1 text-sm text-muted-foreground">
                Sign in to manage your orders and save delivery info
            </p>
        </div>
    {/if}

    {#if errorMsg}
        <div
            class="rounded-md border border-destructive/50 bg-destructive/10 p-3 text-sm text-destructive"
        >
            {errorMsg}
        </div>
    {/if}

    {#if emailSent}
        <div
            class="rounded-md border border-green-200 bg-green-50 p-4 text-center dark:border-green-800 dark:bg-green-900/20"
        >
            <svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="mx-auto mb-2 text-green-600 dark:text-green-400"
                ><rect width="20" height="16" x="2" y="4" rx="2" /><path
                    d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"
                /></svg
            >
            <p class="text-sm font-medium text-green-800 dark:text-green-400">
                Check your email
            </p>
            <p class="mt-1 text-xs text-green-600 dark:text-green-500">
                We sent a sign-in link to <strong>{email}</strong>
            </p>
        </div>
    {:else}
        <!-- OAuth Providers -->
        <div class="space-y-3">
            <button
                type="button"
                on:click={handleGoogle}
                disabled={loading}
                class="inline-flex w-full h-11 items-center justify-center gap-3 rounded-md border border-input bg-background px-4 text-sm font-medium shadow-sm transition-colors hover:bg-accent hover:text-accent-foreground disabled:opacity-50"
            >
                <svg viewBox="0 0 24 24" width="18" height="18"
                    ><path
                        fill="#4285F4"
                        d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z"
                    /><path
                        fill="#34A853"
                        d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                    /><path
                        fill="#FBBC05"
                        d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                    /><path
                        fill="#EA4335"
                        d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                    /></svg
                >
                Continue with Google
            </button>

            <button
                type="button"
                on:click={handleApple}
                disabled={loading}
                class="inline-flex w-full h-11 items-center justify-center gap-3 rounded-md border border-input bg-background px-4 text-sm font-medium shadow-sm transition-colors hover:bg-accent hover:text-accent-foreground disabled:opacity-50"
            >
                <svg
                    viewBox="0 0 24 24"
                    width="18"
                    height="18"
                    fill="currentColor"
                    ><path
                        d="M17.05 20.28c-.98.95-2.05.88-3.08.4-1.09-.5-2.08-.48-3.24 0-1.44.62-2.2.44-3.06-.4C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"
                    /></svg
                >
                Continue with Apple
            </button>
        </div>

        <!-- Divider -->
        <div class="relative">
            <div class="absolute inset-0 flex items-center">
                <span class="w-full border-t"></span>
            </div>
            <div class="relative flex justify-center text-xs uppercase">
                <span class="bg-background px-2 text-muted-foreground"
                    >Or continue with</span
                >
            </div>
        </div>

        <!-- Email Magic Link -->
        <form on:submit|preventDefault={handleEmail} class="space-y-3">
            <input
                type="email"
                bind:value={email}
                placeholder="your@email.com"
                required
                disabled={loading}
                class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50"
            />
            <button
                type="submit"
                disabled={loading || !email.trim()}
                class="inline-flex w-full h-10 items-center justify-center rounded-md bg-primary px-4 text-sm font-medium text-primary-foreground shadow transition-colors hover:bg-primary/90 disabled:opacity-50"
            >
                {loading ? "Sending..." : "Send Magic Link"}
            </button>
        </form>

        <p class="text-center text-xs text-muted-foreground">
            By signing in, you agree to our Terms of Service and Privacy Policy.
        </p>
    {/if}
</div>
