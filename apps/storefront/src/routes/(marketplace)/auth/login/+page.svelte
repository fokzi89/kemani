<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { ShieldCheck, Mail, Lock, Eye, EyeOff, AlertCircle, Loader, ArrowRight } from 'lucide-svelte';
	import { supabase } from '$lib/supabase';

	export let data: { storefront: any };
	$: storefront = data.storefront;
	$: brandColor = storefront?.brand_color || '#131921';

	let email = '';
	let password = '';
	let showPassword = false;
	let isLoading = false;
	let errorMsg = '';

	// Redirect if already logged in
	onMount(async () => {
		const { data: session } = await supabase.auth.getSession();
		if (session.session) goto('/');
	});

	async function handleLogin(e: Event) {
		e.preventDefault();
		errorMsg = '';
		isLoading = true;
		try {
			const { error } = await supabase.auth.signInWithPassword({ email, password });
			if (error) {
				errorMsg = error.message === 'Invalid login credentials'
					? 'The credentials you entered are incorrect.'
					: error.message;
			} else {
				const redirectTo = $page.url.searchParams.get('redirect') || '/';
				goto(redirectTo);
			}
		} catch {
			errorMsg = 'An unexpected error occurred. Please try again.';
		} finally {
			isLoading = false;
		}
	}
</script>

<svelte:head>
	<title>Sign In — {storefront?.name || 'Store'}</title>
</svelte:head>

<div class="auth-page">
	<div class="auth-container">
		
		<!-- Left: Visual/Brand (Optional/Hidden on mobile) -->
		<div class="auth-visual">
			<div class="visual-content">
				<h2 class="visual-title">{storefront?.name}</h2>
				<p class="visual-sub">Curated healthcare solutions for a modern lifestyle.</p>
			</div>
			<div class="visual-overlay"></div>
			<img src="https://images.unsplash.com/photo-1579389083078-4e7018379f7e?q=80&w=2000&auto=format&fit=crop" alt="Brand" class="visual-img" />
		</div>

		<!-- Right: Form -->
		<div class="auth-form-wrap">
			<div class="form-inner">
				<header class="form-header">
					<a href="/" class="form-logo">
						{#if storefront?.logo_url}
							<img src={storefront.logo_url} alt={storefront.name} class="logo-img" />
						{:else}
							<div class="logo-placeholder">{storefront?.name.charAt(0)}</div>
						{/if}
					</a>
					<h1 class="form-title">Welcome Back</h1>
					<p class="form-subtitle">Enter your credentials to access your collection.</p>
				</header>

				{#if errorMsg}
					<div class="alert">
						<AlertCircle class="w-4 h-4" />
						<span>{errorMsg}</span>
					</div>
				{/if}

				<form on:submit={handleLogin} class="auth-form">
					<div class="input-group">
						<label for="email" class="input-label">Email Address</label>
						<input
							id="email"
							type="email"
							bind:value={email}
							required
							placeholder="e.g. name@curator.com"
							class="input-field"
						/>
					</div>

					<div class="input-group">
						<div class="label-row">
							<label for="password" class="input-label">Password</label>
							<a href="/auth/forgot-password" class="text-link">Forgot?</a>
						</div>
						<div class="input-relative">
							<input
								id="password"
								type={showPassword ? 'text' : 'password'}
								bind:value={password}
								required
								placeholder="Enter your password"
								class="input-field pr-10"
							/>
							<button 
								type="button" 
								on:click={() => showPassword = !showPassword}
								class="toggle-eye"
							>
								{#if showPassword}<EyeOff class="w-4 h-4" />{:else}<Eye class="w-4 h-4" />{/if}
							</button>
						</div>
					</div>

					<button type="submit" disabled={isLoading} class="btn-primary">
						{#if isLoading}
							<div class="loader-dot"></div> Authenticating...
						{:else}
							Sign In <ArrowRight class="btn-icon" />
						{/if}
					</button>
				</form>

				<footer class="form-footer">
					<span>New to the collection?</span>
					<a href="/auth/register" class="text-link-bold">Create an account</a>
				</footer>
			</div>
		</div>
	</div>
</div>

<style>
	/* ─── TOKENS ─── */
	:root {
		--font-display: 'Playfair Display', Georgia, serif;
		--font-body: 'Inter', -apple-system, sans-serif;
		--surface: #faf9f6;
		--on-surface: #1a1c1a;
		--on-surface-muted: #6b7280;
		--border: #e5e5e0;
		--radius: 8px;
	}

	.auth-page {
		min-height: 100vh;
		background: var(--surface);
		display: flex; align-items: stretch;
		font-family: var(--font-body);
	}

	.auth-container {
		display: flex; width: 100%;
	}

	/* ─── VISUAL COLUMN ─── */
	.auth-visual {
		display: none; flex: 1.2; position: relative; overflow: hidden;
	}
	@media (min-width: 1024px) { .auth-visual { display: block; } }

	.visual-overlay { position: absolute; inset: 0; background: linear-gradient(to top, rgba(0,0,0,0.6) 0%, transparent 60%); z-index: 1; }
	.visual-img { width: 100%; height: 100%; object-fit: cover; }
	.visual-content { position: absolute; bottom: 4rem; left: 4rem; z-index: 2; color: #fff; max-width: 400px; }
	.visual-title { font-family: var(--font-display); font-size: 3rem; margin-bottom: 1rem; }
	.visual-sub { font-size: 1.1rem; opacity: 0.8; font-weight: 300; }

	/* ─── FORM COLUMN ─── */
	.auth-form-wrap { flex: 1; display: flex; align-items: center; justify-content: center; padding: 2rem; background: #fff; }
	.form-inner { width: 100%; max-width: 360px; }

	.form-header { text-align: center; margin-bottom: 2.5rem; }
	.form-logo { display: inline-block; margin-bottom: 1.5rem; }
	.logo-img { h: 32px; w: 32px; object-fit: contain; }
	.logo-placeholder { width: 44px; height: 44px; background: var(--on-surface); color: #fff; display: flex; align-items: center; justify-content: center; font-family: var(--font-display); font-size: 1.25rem; border-radius: 4px; }
	.form-title { font-family: var(--font-display); font-size: 2rem; font-weight: 500; margin-bottom: 0.5rem; }
	.form-subtitle { font-size: 13px; color: var(--on-surface-muted); }

	.alert { margin-bottom: 1.5rem; padding: 1rem; background: #fef2f2; border: 1px solid #fee2e2; border-radius: 8px; color: #b91c1c; font-size: 12px; display: flex; align-items: center; gap: 8px; }

	.auth-form { display: flex; flex-direction: column; gap: 1.5rem; }
	.input-group { display: flex; flex-direction: column; gap: 0.5rem; }
	.label-row { display: flex; justify-content: space-between; align-items: center; }
	.input-label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; color: var(--on-surface-muted); }
	
	.input-field {
		width: 100%; padding: 12px 0;
		border: none; border-bottom: 1px solid var(--border);
		background: transparent; font-size: 14px; color: var(--on-surface);
		outline: none; transition: border-color 0.2s;
	}
	.input-field:focus { border-color: var(--on-surface); }
	.input-field::placeholder { color: #d1d5db; opacity: 0.6; }

	.input-relative { position: relative; }
	.toggle-eye { position: absolute; right: 0; top: 50%; transform: translateY(-50%); color: var(--on-surface-muted); cursor: pointer; border: none; background: none; }

	.btn-primary {
		width: 100%; padding: 16px; border: none; border-radius: var(--radius);
		background: var(--on-surface); color: #fff;
		font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.15em;
		display: flex; align-items: center; justify-content: center; gap: 8px;
		cursor: pointer; transition: background 0.2s; margin-top: 1rem;
	}
	.btn-primary:hover { background: #000; }
	.btn-primary:disabled { opacity: 0.5; }

	.text-link { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; color: var(--on-surface-muted); border-bottom: 1px solid transparent; }
	.text-link:hover { border-color: var(--on-surface-muted); }

	.form-footer { margin-top: 2.5rem; text-align: center; font-size: 13px; color: var(--on-surface-muted); }
	.text-link-bold { font-weight: 700; color: var(--on-surface); margin-left: 4px; border-bottom: 1px solid var(--on-surface); padding-bottom: 2px; }

	.loader-dot { width: 8px; height: 8px; border: 2px solid rgba(255,255,255,0.3); border-top-color: #fff; border-radius: 50%; animation: spin 0.8s linear infinite; }
	@keyframes spin { to { transform: rotate(360deg); } }
</style>
