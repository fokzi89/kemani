<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { ArrowLeft, Moon, User, Mail, Lock, Eye, EyeOff } from 'lucide-svelte';

	let formData = $state({
		fullName: '',
		email: '',
		password: ''
	});

	let loading = $state(false);
	let error = $state('');
	let showPassword = $state(false);

	async function handleSignup(e: Event) {
		e.preventDefault();
		loading = true;
		error = '';

		if (formData.password.length < 6) {
			error = 'Password must be at least 6 characters';
			loading = false;
			return;
		}

		try {
			// Create auth account
			const { data: authData, error: authError } = await supabase.auth.signUp({
				email: formData.email,
				password: formData.password
			});

			if (authError) {
				error = authError.message;
				loading = false;
				return;
			}

			if (authData.user) {
				// Is it a fake user ID? (Supabase email enumeration protection)
				if (authData.user.identities && authData.user.identities.length === 0) {
					error = 'An account with this email address already exists. Please sign in instead.';
					loading = false;
					return;
				}

				// Create minimal provider profile
				const nameForSlug = formData.fullName || formData.email.split('@')[0];
				const slug = nameForSlug.toLowerCase().replace(/[^a-z0-9]+/g, '-') + '-' + Math.random().toString(36).substr(2, 6);

				const { data: providerData, error: profileError } = await supabase
					.from('healthcare_providers')
					.insert({
						user_id: authData.user.id,
						full_name: formData.fullName || formData.email.split('@')[0],
						slug,
						email: formData.email,
						type: 'doctor',
						specialization: 'General Practice',
						country: 'Nigeria',
						fees: {
							chat: 5000,
							video: 10000,
							audio: 8000
						},
						is_verified: false,
						is_active: true
					})
					.select()
					.single();

				if (profileError) {
					// Check if it's a conflict, although unique checks are mostly on slug.
					console.error('Provider profile creation error:', profileError);
					error = 'Failed to create provider profile: ' + profileError.message;
					loading = false;
					return;
				}

				console.log('Provider profile created successfully:', providerData);

				// Small delay to ensure the profile is committed to the database
				await new Promise(resolve => setTimeout(resolve, 1000));

				goto('/onboarding');
			} else {
				// If user is null (Email enumeration protection returned empty)
				error = 'An account with this email address already exists. Please log in.';
				loading = false;
			}
		} catch (err: any) {
			console.error("Signup exception:", err);
			error = err?.message || 'An unexpected error occurred during signup.';
			loading = false;
		}
	}
</script>

<div class="min-h-screen w-full flex font-sans">
	<!-- Left Side: Form Content -->
	<div class="w-full lg:w-[45%] bg-[#f9fafb] flex flex-col items-center justify-center p-8 relative">
		<!-- Top Action Bar -->
		<div class="absolute top-8 left-8 right-8 flex justify-between items-center max-w-xl mx-auto w-[calc(100%-4rem)]">
			<a href="/" class="flex items-center text-[#111827] font-semibold text-sm hover:underline hover:text-[#000000] transition-colors">
				<ArrowLeft size={16} class="mr-2" strokeWidth={2.5} />
				Back to Home
			</a>
			<button class="text-[#111827] p-2 hover:bg-gray-200 rounded-full transition-colors">
				<Moon size={22} fill="currentColor" />
			</button>
		</div>

		<div class="w-full max-w-[400px] mt-12">
			<h1 class="text-4xl font-bold text-[#113022] mb-3 font-sans tracking-tight">Grow Your Practice 🩺</h1>
			<p class="text-[15px] text-[#4a6357] leading-relaxed mb-8 pr-4">
				Join Kemani Health and connect with patients who need your expertise. Boost your practice with teleconsultations, prescriptions, and seamless patient management.
			</p>

			{#if error}
				<div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-xl text-sm mb-6">
					{error}
				</div>
			{/if}

			<form onsubmit={handleSignup} class="space-y-4">
				<!-- Full Name -->
				<div class="relative group">
					<div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400 group-focus-within:text-[#111827] transition-colors">
						<User size={18} />
					</div>
					<input
						type="text"
						bind:value={formData.fullName}
						required
						placeholder="Full name"
						class="w-full pl-10 pr-4 py-3.5 bg-white border border-[#d1d5db] rounded-xl focus:outline-none focus:ring-[1.5px] focus:ring-[#111827] focus:border-[#111827] text-gray-800 placeholder-gray-400 transition-shadow text-[15px]"
					/>
				</div>

				<!-- Email -->
				<div class="relative group">
					<div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400 group-focus-within:text-[#111827] transition-colors">
						<Mail size={18} />
					</div>
					<input
						type="email"
						bind:value={formData.email}
						required
						placeholder="Email"
						class="w-full pl-10 pr-4 py-3.5 bg-white border border-[#d1d5db] rounded-xl focus:outline-none focus:ring-[1.5px] focus:ring-[#111827] focus:border-[#111827] text-gray-800 placeholder-gray-400 transition-shadow text-[15px]"
					/>
				</div>

				<!-- Password -->
				<div class="relative group">
					<div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400 group-focus-within:text-[#111827] transition-colors">
						<Lock size={18} />
					</div>
					<input
						type={showPassword ? "text" : "password"}
						bind:value={formData.password}
						required
						placeholder="Password"
						class="w-full pl-10 pr-12 py-3.5 bg-white border border-[#d1d5db] rounded-xl focus:outline-none focus:ring-[1.5px] focus:ring-[#111827] focus:border-[#111827] text-gray-800 placeholder-gray-400 transition-shadow text-[15px]"
					/>
					<button
						type="button"
						class="absolute inset-y-0 right-0 pr-3.5 flex items-center text-gray-400 hover:text-gray-600 transition-colors"
						onclick={() => showPassword = !showPassword}
					>
						{#if showPassword}
							<EyeOff size={18} />
						{:else}
							<Eye size={18} />
						{/if}
					</button>
				</div>

				<!-- Setup Button -->
				<button
					type="submit"
					disabled={loading}
					class="w-full mt-2 bg-[#111827] hover:bg-[#000000] font-semibold text-white py-3.5 px-4 rounded-xl transition-all focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#111827] shadow-sm disabled:opacity-70 disabled:cursor-not-allowed text-[15px]"
				>
					{loading ? 'Processing...' : 'Sign up'}
				</button>
			</form>

			<p class="mt-8 text-center text-sm text-[14px] text-gray-500">
				Already have an account? 
				<a href="/auth/login" class="font-bold text-[#111827] hover:text-[#000000] transition-colors ml-1">Log in</a>
			</p>
		</div>
	</div>

	<!-- Right Side: Promotional/Brand Content -->
	<div class="hidden lg:flex w-[55%] bg-[#111827] flex-col justify-center px-16 xl:px-24 relative overflow-hidden">
		<!-- Brand Logo/Name -->
		<div class="absolute top-12 left-16 xl:left-24">
			<span class="text-white text-[32px] font-bold tracking-tight">Kemani Health</span>
		</div>

		<!-- Testimonial Content -->
		<div class="text-white z-10 max-w-2xl mt-12">
			<!-- Quote Icon -->
			<svg class="w-10 h-10 mb-8 text-[#6b7280]" fill="currentColor" viewBox="0 0 24 24">
				<path d="M14.017 21v-7.391c0-5.704 3.731-9.57 8.983-10.609l.995 2.151c-2.432.917-3.995 3.638-3.995 5.849h4v10h-9.983zm-14.017 0v-7.391c0-5.704 3.748-9.57 9-10.609l.996 2.151c-2.433.917-3.996 3.638-3.996 5.849h3.983v10h-9.983z"/>
			</svg>

			<p class="text-[20px] font-semibold leading-[1.6] mb-8 text-white">
				Kemani Health has transformed how I manage my practice. The platform makes it incredibly easy to conduct teleconsultations, prescribe medications, and track patient progress. I've been able to reach more patients and grow my practice significantly while maintaining quality care.
			</p>

			<div class="mt-8">
				<h4 class="font-bold text-lg mb-1">Dr. Adebayo Okonkwo</h4>
				<p class="text-white/80 text-[14px]">General Practitioner • Lagos, Nigeria</p>
			</div>
		</div>
	</div>
</div>
