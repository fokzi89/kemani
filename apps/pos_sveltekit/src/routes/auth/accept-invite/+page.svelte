<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { supabase } from '$lib/supabase';
	import { CheckCircle2, AlertTriangle, ArrowRight, Mail } from 'lucide-svelte';

	let token = $derived($page.url.searchParams.get('token') || '');

	type Stage = 'loading' | 'invalid' | 'expired' | 'already_accepted' | 'confirm' | 'processing' | 'mismatch' | 'success';
	let stage = $state<Stage>('loading');

	let invitation = $state<any>(null);
	let errorMessage = $state('');

	// After Google OAuth redirect, this will hold the Google user's email
	let googleEmail = $state('');

	onMount(async () => {
		if (!token) { stage = 'invalid'; return; }

		// Check if there's already an active session (returning from Google OAuth)
		const { data: { session } } = await supabase.auth.getSession();

		// Fetch the invitation row
		const { data: inv, error } = await supabase
			.from('staff_invitations')
			.select('*')
			.eq('invitation_token', token)
			.maybeSingle();

		if (error || !inv) { stage = 'invalid'; return; }
		if (inv.status === 'accepted') { stage = 'already_accepted'; return; }
		if (inv.status === 'revoked') { stage = 'invalid'; return; }
		if (new Date(inv.expires_at) < new Date()) { stage = 'expired'; return; }

		invitation = inv;

		// If we already have a session (just came back from Google OAuth)
		if (session?.user?.email) {
			googleEmail = session.user.email.trim().toLowerCase();
			await processAcceptance(session);
			return;
		}

		// No session yet — show invitation card with Google sign-in button
		stage = 'confirm';
	});

	async function signInWithGoogle() {
		stage = 'processing';
		const { error } = await supabase.auth.signInWithOAuth({
			provider: 'google',
			options: {
				redirectTo: `${window.location.origin}/auth/accept-invite?token=${token}`,
				queryParams: { prompt: 'select_account' }
			}
		});
		if (error) {
			errorMessage = error.message;
			stage = 'confirm';
		}
	}

	async function processAcceptance(session: any) {
		stage = 'processing';
		try {
			const invEmail = invitation.email.trim().toLowerCase();
			const authEmail = session.user.email.trim().toLowerCase();

			// Email must match
			if (authEmail !== invEmail) {
				googleEmail = authEmail;
				stage = 'mismatch';
				return;
			}

			const userId = session.user.id;

			// Check if user row already exists in users table
			const { data: existingUser } = await supabase
				.from('users')
				.select('id')
				.eq('email', invEmail)
				.maybeSingle();

			if (existingUser) {
				// Update existing user: attach to this tenant and branch
				const { error: updateErr } = await supabase
					.from('users')
					.update({
						tenant_id: invitation.tenant_id,
						branch_id: invitation.branch_id,
						role: invitation.role,
						onboarding_done: true,
						canManagePOS: invitation.canManagePOS,
						canManageProducts: invitation.canManageProducts,
						canManageCustomers: invitation.canManageCustomers,
						canManageOrders: invitation.canManageOrders,
						canViewMessages: invitation.canViewMessages,
						canViewAnalytics: invitation.canViewAnalytics,
						canManageStaff: invitation.canManageStaff,
						canManageInventory: invitation.canManageInventory,
						canManageTransfer: invitation.canManageTransfer,
						canManageBranches: invitation.canManageBranches,
						canManageRoles: invitation.canManageRoles,
						canTransferProduct: invitation.canTransferProduct,
						canReturnProducts: invitation.canReturnProducts,
						canCreatePrescription: invitation.canCreatePrescription,
						canApplyDiscount: invitation.canApplyDiscount,
						canReferDoctor: invitation.canReferDoctor,
						updated_at: new Date().toISOString()
					})
					.eq('email', invEmail);

				if (updateErr) throw updateErr;
			} else {
				// Insert new user row
				const { error: insertErr } = await supabase
					.from('users')
					.insert({
						id: userId,
						email: invEmail,
						full_name: invitation.full_name,
						role: invitation.role,
						tenant_id: invitation.tenant_id,
						branch_id: invitation.branch_id,
						onboarding_done: true,
						canManagePOS: invitation.canManagePOS,
						canManageProducts: invitation.canManageProducts,
						canManageCustomers: invitation.canManageCustomers,
						canManageOrders: invitation.canManageOrders,
						canViewMessages: invitation.canViewMessages,
						canViewAnalytics: invitation.canViewAnalytics,
						canManageStaff: invitation.canManageStaff,
						canManageInventory: invitation.canManageInventory,
						canManageTransfer: invitation.canManageTransfer,
						canManageBranches: invitation.canManageBranches,
						canManageRoles: invitation.canManageRoles,
						canTransferProduct: invitation.canTransferProduct,
						canReturnProducts: invitation.canReturnProducts,
						canCreatePrescription: invitation.canCreatePrescription,
						canApplyDiscount: invitation.canApplyDiscount,
						canReferDoctor: invitation.canReferDoctor
					});

				if (insertErr) throw insertErr;
			}

			// Mark invitation as accepted
			await supabase
				.from('staff_invitations')
				.update({ status: 'accepted', accepted_at: new Date().toISOString() })
				.eq('invitation_token', token);

			stage = 'success';
			setTimeout(() => goto('/'), 3000);
		} catch (err: any) {
			errorMessage = err.message || 'Something went wrong.';
			stage = 'confirm';
		}
	}

	async function signOutAndRetry() {
		await supabase.auth.signOut();
		stage = 'confirm';
	}
</script>

<svelte:head>
	<title>Accept Invitation — Kemani POS</title>
</svelte:head>

<div class="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50/30 to-indigo-50/20 flex items-center justify-center p-4">
	<div class="w-full" style="max-width: 420px;">

		<!-- Loading -->
		{#if stage === 'loading' || stage === 'processing'}
			<div class="bg-white rounded-3xl shadow-xl border border-gray-100 p-14 text-center">
				<div class="flex justify-center mb-5">
					<div class="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600"></div>
				</div>
				<p class="text-gray-500 font-semibold text-sm">
					{stage === 'loading' ? 'Validating your invitation...' : 'Setting up your account...'}
				</p>
			</div>

		<!-- Invalid -->
		{:else if stage === 'invalid'}
			<div class="bg-white rounded-3xl shadow-xl border border-gray-100 p-12 text-center">
				<div class="h-16 w-16 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-5">
					<AlertTriangle class="h-8 w-8 text-red-500" />
				</div>
				<h2 class="text-xl font-black text-gray-900 mb-2">Invalid Invitation</h2>
				<p class="text-sm text-gray-500 mb-6">This link is invalid, expired, or has already been used.</p>
				<a href="/auth/login" class="inline-flex items-center gap-2 text-sm font-bold text-blue-600 hover:underline">
					Go to Login <ArrowRight class="h-4 w-4" />
				</a>
			</div>

		<!-- Expired -->
		{:else if stage === 'expired'}
			<div class="bg-white rounded-3xl shadow-xl border border-gray-100 p-12 text-center">
				<div class="h-16 w-16 bg-amber-50 rounded-full flex items-center justify-center mx-auto mb-5">
					<AlertTriangle class="h-8 w-8 text-amber-500" />
				</div>
				<h2 class="text-xl font-black text-gray-900 mb-2">Invitation Expired</h2>
				<p class="text-sm text-gray-500">This invitation link has expired (7-day limit). Ask your admin to send a new one.</p>
			</div>

		<!-- Already accepted -->
		{:else if stage === 'already_accepted'}
			<div class="bg-white rounded-3xl shadow-xl border border-gray-100 p-12 text-center">
				<div class="h-16 w-16 bg-emerald-50 rounded-full flex items-center justify-center mx-auto mb-5">
					<CheckCircle2 class="h-8 w-8 text-emerald-600" />
				</div>
				<h2 class="text-xl font-black text-gray-900 mb-2">Already Joined</h2>
				<p class="text-sm text-gray-500 mb-6">This invitation has already been accepted.</p>
				<a href="/auth/login" class="inline-flex items-center gap-2 text-sm font-bold text-blue-600 hover:underline">
					Sign In <ArrowRight class="h-4 w-4" />
				</a>
			</div>

		<!-- Confirm invitation — show Google sign-in -->
		{:else if stage === 'confirm' && invitation}
			<div class="bg-white rounded-3xl shadow-xl border border-gray-100 overflow-hidden">
				<!-- Gradient header -->
				<div class="bg-gradient-to-br from-blue-600 to-indigo-700 px-8 pt-10 pb-8 text-white">
					<div class="h-14 w-14 bg-white/20 rounded-2xl flex items-center justify-center text-2xl font-black mb-5">
						{invitation.full_name?.charAt(0)?.toUpperCase()}
					</div>
					<h1 class="text-2xl font-black mb-1">You're Invited!</h1>
					<p class="text-blue-100 text-sm">Sign in with Google to activate your Kemani POS account.</p>
				</div>

				<!-- Profile strip -->
				<div class="px-8 py-4 bg-gray-50 border-b border-gray-100">
					<p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-2">Invitation For</p>
					<div class="flex items-center gap-3">
						<div class="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center font-black text-blue-700 shrink-0">
							{invitation.full_name?.charAt(0)?.toUpperCase()}
						</div>
						<div>
							<p class="text-sm font-black text-gray-900">{invitation.full_name}</p>
							<div class="flex items-center gap-1.5 mt-0.5">
								<Mail class="h-3 w-3 text-gray-400" />
								<p class="text-xs text-gray-500">{invitation.email}</p>
							</div>
						</div>
						<span class="ml-auto text-[10px] font-black px-2.5 py-1 bg-blue-50 text-blue-700 rounded-full uppercase border border-blue-100">
							{invitation.role?.replace('_', ' ')}
						</span>
					</div>
				</div>

				<!-- Action -->
				<div class="px-8 py-8">
					{#if errorMessage}
						<div class="bg-red-50 border border-red-100 text-red-700 text-sm font-medium px-4 py-3 rounded-xl flex items-center gap-2 mb-5">
							<AlertTriangle class="h-4 w-4 shrink-0" />
							{errorMessage}
						</div>
					{/if}

					<p class="text-sm text-gray-500 mb-5 leading-relaxed">
						You must sign in with the Google account matching <strong class="text-gray-900">{invitation.email}</strong> to accept this invitation.
					</p>

					<button
						onclick={signInWithGoogle}
						class="w-full flex items-center justify-center gap-3 bg-white border-2 border-gray-200 hover:border-blue-300 hover:shadow-md text-gray-800 font-bold py-3.5 rounded-xl transition-all text-sm"
					>
						<!-- Google G logo -->
						<svg class="h-5 w-5" viewBox="0 0 24 24">
							<path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
							<path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
							<path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
							<path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
						</svg>
						Continue with Google
					</button>

					<p class="text-[11px] text-gray-400 text-center mt-4 leading-relaxed">
						Only the Google account matching the invited email address will be accepted.
					</p>
				</div>
			</div>

		<!-- Email Mismatch -->
		{:else if stage === 'mismatch' && invitation}
			<div class="bg-white rounded-3xl shadow-xl border border-gray-100 p-10 text-center">
				<div class="h-16 w-16 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-5">
					<AlertTriangle class="h-8 w-8 text-red-500" />
				</div>
				<h2 class="text-xl font-black text-gray-900 mb-2">Wrong Google Account</h2>
				<p class="text-sm text-gray-500 mb-2">
					You signed in as <strong class="text-gray-900">{googleEmail}</strong>, but this invitation is for:
				</p>
				<p class="text-sm font-black text-blue-700 bg-blue-50 px-4 py-2 rounded-xl mb-6">{invitation.email}</p>
				<button
					onclick={signOutAndRetry}
					class="w-full py-3 bg-blue-600 text-white font-bold rounded-xl hover:bg-blue-700 transition-colors text-sm"
				>
					Sign in with the correct account
				</button>
			</div>

		<!-- Success -->
		{:else if stage === 'success'}
			<div class="bg-white rounded-3xl shadow-xl border border-gray-100 p-12 text-center">
				<div class="h-16 w-16 bg-emerald-50 rounded-full flex items-center justify-center mx-auto mb-5">
					<CheckCircle2 class="h-8 w-8 text-emerald-600" />
				</div>
				<h2 class="text-xl font-black text-gray-900 mb-2">Account Activated! 🎉</h2>
				<p class="text-sm text-gray-500 mb-6">Welcome aboard! Redirecting you to the dashboard...</p>
				<div class="flex justify-center">
					<div class="animate-spin rounded-full h-5 w-5 border-b-2 border-blue-600"></div>
				</div>
			</div>
		{/if}

		<p class="text-center text-xs text-gray-400 mt-6">Kemani POS &mdash; Secure Staff Onboarding</p>
	</div>
</div>
