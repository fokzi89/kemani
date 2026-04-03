<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { ShieldCheck, Eye, EyeOff, AlertCircle, CheckCircle, Loader, ArrowRight } from 'lucide-svelte';
	import { supabase } from '$lib/supabase';

	export let data: { storefront: any };
	$: storefront = data.storefront;
	$: brandColor = storefront?.brand_color || '#131921';

	let fullName = '';
	let email = '';
	let phone = '';
	let password = '';
	let confirmPassword = '';
	let showPassword = false;
	let showConfirm = false;
	let isLoading = false;
	let errorMsg = '';
	let successMsg = '';

	onMount(async () => {
		const { data: session } = await supabase.auth.getSession();
		if (session.session) goto('/');
	});

	// Password strength
	$: strength = (() => {
		if (!password) return 0;
		let s = 0;
		if (password.length >= 8) s++;
		if (/[A-Z]/.test(password)) s++;
		if (/[0-9]/.test(password)) s++;
		if (/[^A-Za-z0-9]/.test(password)) s++;
		return s;
	})();
	$: strengthLabel = ['', 'Weak', 'Fair', 'Good', 'Strong'][strength];
	$: strengthColor = ['', 'bg-red-400', 'bg-orange-300', 'bg-yellow-300', 'bg-emerald-400'][strength];

	async function handleRegister(e: Event) {
		e.preventDefault();
		errorMsg = '';
		successMsg = '';

		if (password !== confirmPassword) {
			errorMsg = 'Passwords do not match.';
			return;
		}
		if (password.length < 8) {
			errorMsg = 'Password must be at least 8 characters.';
			return;
		}

		isLoading = true;
		try {
			const { data: signUpData, error } = await supabase.auth.signUp({
				email,
				password,
				options: {
					data: {
						full_name: fullName,
						phone,
						tenant_id: storefront?.id
					}
				}
			});

			if (error) {
				errorMsg = error.message;
			} else if (signUpData.user && !signUpData.session) {
				successMsg = `A confirmation link has been sent to ${email}.`;
			} else {
				goto('/');
			}
		} catch {
			errorMsg = 'An unexpected error occurred. Please try again.';
		} finally {
			isLoading = false;
		}
	}
</script>

<svelte:head>
	<title>Create Account — {storefront?.name || 'Store'}</title>
</svelte:head>

<div class="auth-page">
	<div class="auth-container">
		
		<!-- Visual Column -->
		<div class="auth-visual">
			<div class="visual-content">
				<h2 class="visual-title">The Collection</h2>
				<p class="visual-sub">Join a community dedicated to medics and refined living.</p>
			</div>
			<div class="visual-overlay"></div>
			<img src="https://images.unsplash.com/photo-1540555700478-4be289fbecee?q=80&w=2000&auto=format&fit=crop" alt="Register" class="visual-img" />
		</div>

		<!-- Form Column -->
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
					<h1 class="form-title">Join Us</h1>
					<p class="form-subtitle">Register to begin your personalized journey.</p>
				</header>

				{#if errorMsg}
					<div class="alert alert-error">
						<AlertCircle class="w-4 h-4" />
						<span>{errorMsg}</span>
					</div>
				{/if}

				{#if successMsg}
					<div class="alert alert-success">
						<CheckCircle class="w-4 h-4" />
						<span>{successMsg}</span>
					</div>
					<div class="mt-8 text-center">
						<a href="/auth/login" class="btn-primary">Back to Sign In</a>
					</div>
				{:else}
					<form on:submit={handleRegister} class="auth-form">
						<div class="input-group">
							<label for="fullName" class="input-label">Full Name</label>
							<input
								id="fullName"
								type="text"
								bind:value={fullName}
								placeholder="First and last name"
								required
								class="input-field"
							/>
						</div>

						<div class="input-group">
							<label for="email" class="input-label">Email Address</label>
							<input
								id="email"
								type="email"
								bind:value={email}
								required
								placeholder="name@example.com"
								class="input-field"
							/>
						</div>

						<div class="input-group">
							<label for="phone" class="input-label">Phone Number (Optional)</label>
							<input
								id="phone"
								type="tel"
								bind:value={phone}
								placeholder="+234..."
								class="input-field"
							/>
						</div>

						<div class="input-group">
							<label for="password" class="input-label">Create Password</label>
							<div class="input-relative">
								<input
									id="password"
									type={showPassword ? 'text' : 'password'}
									bind:value={password}
									required
									placeholder="At least 8 characters"
									class="input-field"
								/>
								<button type="button" class="toggle-eye" on:click={() => showPassword = !showPassword}>
									{#if showPassword}<EyeOff class="w-4 h-4" />{:else}<Eye class="w-4 h-4" />{/if}
								</button>
							</div>
							{#if password}
								<div class="strength-meter">
									<div class="meter-bars">
										{#each Array(4) as _, i}
											<div class="meter-bar {i < strength ? strengthColor : ''}"></div>
										{/each}
									</div>
									<span class="strength-label">{strengthLabel}</span>
								</div>
							{/if}
						</div>

						<div class="input-group">
							<label for="confirm" class="input-label">Confirm Password</label>
							<div class="input-relative">
								<input
									id="confirm"
									type={showConfirm ? 'text' : 'password'}
									bind:value={confirmPassword}
									required
									class="input-field"
								/>
								<button type="button" class="toggle-eye" on:click={() => showConfirm = !showConfirm}>
									{#if showConfirm}<EyeOff class="w-4 h-4" />{:else}<Eye class="w-4 h-4" />{/if}
								</button>
							</div>
						</div>

						<button type="submit" disabled={isLoading} class="btn-primary">
							{#if isLoading}
								<div class="loader-dot"></div> Creating...
							{:else}
								Create Account <ArrowRight class="btn-icon" />
							{/if}
						</button>
					</form>
				{/if}

				<footer class="form-footer">
					<span>Already registered?</span>
					<a href="/auth/login" class="text-link-bold">Sign In</a>
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

	.visual-overlay { position: absolute; inset: 0; background: linear-gradient(to top, rgba(0,0,0,0.6) 0%, transparent 63%); z-index: 1; }
	.visual-img { width: 100%; height: 100%; object-fit: cover; }
	.visual-content { position: absolute; bottom: 4rem; left: 4rem; z-index: 2; color: #fff; max-width: 400px; }
	.visual-title { font-family: var(--font-display); font-size: 3rem; margin-bottom: 1rem; }
	.visual-sub { font-size: 1.1rem; opacity: 0.8; font-weight: 300; }

	/* ─── FORM COLUMN ─── */
	.auth-form-wrap { flex: 1; display: flex; align-items: center; justify-content: center; padding: 2rem 1rem; background: #fff; overflow-y: auto; }
	.form-inner { width: 100%; max-width: 360px; padding: 2rem 0; }

	.form-header { text-align: center; margin-bottom: 2.5rem; }
	.logo-img { height: 32px; width: 32px; object-fit: contain; }
	.logo-placeholder { width: 44px; height: 44px; background: var(--on-surface); color: #fff; display: flex; align-items: center; justify-content: center; font-family: var(--font-display); font-size: 1.25rem; border-radius: 4px; margin: 0 auto 1.5rem; }
	.form-title { font-family: var(--font-display); font-size: 2rem; font-weight: 500; margin-bottom: 0.5rem; }
	.form-subtitle { font-size: 13px; color: var(--on-surface-muted); }

	.alert { margin-bottom: 1.5rem; padding: 1rem; border-radius: 8px; font-size: 12px; display: flex; align-items: center; gap: 8px; }
	.alert-error { background: #fef2f2; border: 1px solid #fee2e2; color: #b91c1c; }
	.alert-success { background: #f0fdf4; border: 1px solid #dcfce7; color: #15803d; }

	.auth-form { display: flex; flex-direction: column; gap: 1.25rem; }
	.input-group { display: flex; flex-direction: column; gap: 0.4rem; }
	.input-label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; color: var(--on-surface-muted); }
	
	.input-field {
		width: 100%; padding: 10px 0;
		border: none; border-bottom: 1px solid var(--border);
		background: transparent; font-size: 14px; color: var(--on-surface);
		outline: none; transition: border-color 0.2s;
	}
	.input-field:focus { border-color: var(--on-surface); }
	.input-field::placeholder { color: #d1d5db; opacity: 0.6; }

	.input-relative { position: relative; }
	.toggle-eye { position: absolute; right: 0; top: 50%; transform: translateY(-50%); color: var(--on-surface-muted); cursor: pointer; border: none; background: none; }

	.strength-meter { display: flex; align-items: center; justify-content: space-between; margin-top: 0.5rem; }
	.meter-bars { flex: 1; display: flex; gap: 4px; }
	.meter-bar { height: 2px; flex: 1; background: var(--border); border-radius: 2px; transition: all 0.3s; }
	.bg-red-400 { background: #f87171; }
	.bg-orange-300 { background: #fdba74; }
	.bg-yellow-300 { background: #fde047; }
	.bg-emerald-400 { background: #34d399; }
	.strength-label { font-size: 10px; font-weight: 700; color: var(--on-surface-muted); margin-left: 10px; text-transform: uppercase; }

	.btn-primary {
		width: 100%; padding: 16px; border: none; border-radius: var(--radius);
		background: var(--on-surface); color: #fff;
		font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.15em;
		display: flex; align-items: center; justify-content: center; gap: 8px;
		cursor: pointer; transition: background 0.2s; margin-top: 1rem;
	}
	.btn-primary:hover { background: #000; }
	.btn-primary:disabled { opacity: 0.5; }

	.form-footer { margin-top: 2.5rem; text-align: center; font-size: 13px; color: var(--on-surface-muted); }
	.text-link-bold { font-weight: 700; color: var(--on-surface); margin-left: 4px; border-bottom: 1px solid var(--on-surface); padding-bottom: 2px; }

	.loader-dot { width: 8px; height: 8px; border: 2px solid rgba(255,255,255,0.3); border-top-color: #fff; border-radius: 50%; animation: spin 0.8s linear infinite; }
	@keyframes spin { to { transform: rotate(360deg); } }
</style>
