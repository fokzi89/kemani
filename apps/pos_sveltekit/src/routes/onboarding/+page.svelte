<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { 
		Building2, MapPin, User, Globe, Store, 
		CheckCircle2, ArrowRight, Loader2, Sparkles
	} from 'lucide-svelte';

	let currentStage = $state(1);
	let loading = $state(false);
	let error = $state('');
	let currentUser = $state<any>(null);

	// Form State
	let form = $state({
		// Stage 1: Country
		country: 'Nigeria',
		currency: 'NGN',
		
		// Stage 2: Business Info
		businessName: '',
		businessType: 'supermarket',
		branchName: 'Main Branch',
		
		// Stage 3: Personal Profile
		fullName: '',
		phone: ''
	});

	let countries = $state<any[]>([]);
	let filteredCountries = $state<any[]>([]);
	let countrySearch = $state('');

	const businessTypes = [
		{ id: 'pharmacy_supermarket', label: 'Pharmacy & Supermarket', description: 'Combined health & retail store' },
		{ id: 'diagnostic_centre', label: 'Diagnostic Centre', description: 'Lab tests & health diagnostics' },
		{ id: 'supermarket', label: 'Supermarket', description: 'Retail goods & groceries' },
		{ id: 'pharmacy', label: 'Pharmacy', description: 'Medicines & health products' },
		{ id: 'grocery', label: 'Grocery Store', description: 'Fresh produce & food items' },
		{ id: 'mini_mart', label: 'Mini Mart', description: 'Convenience store' },
		{ id: 'restaurant', label: 'Restaurant', description: 'Food & dining' }
	];

	onMount(async () => {
		// Fetch countries
		try {
			const res = await fetch('https://restcountries.com/v3.1/all?fields=name,flag,cca2,currencies');
			const data = await res.json();
			countries = data.map((c: any) => ({
				name: c.name.common,
				code: c.cca2,
				flag: c.flag,
				currency: c.currencies ? Object.keys(c.currencies)[0] : 'USD'
			})).sort((a: any, b: any) => a.name.localeCompare(b.name));
			filteredCountries = countries;
		} catch (e) {
			console.error('Failed to fetch countries:', e);
			countries = [{ name: 'Nigeria', code: 'NG', currency: 'NGN', flag: '🇳🇬' }];
			filteredCountries = countries;
		}

		const { data: { session } } = await supabase.auth.getSession();
		if (!session) {
			goto('/auth/login');
			return;
		}
		currentUser = session.user;
		// Pre-fill email/name if available from auth
		if (currentUser.user_metadata?.full_name) form.fullName = currentUser.user_metadata.full_name;
	});

	$effect(() => {
		if (countrySearch) {
			filteredCountries = countries.filter(c => 
				c.name.toLowerCase().includes(countrySearch.toLowerCase()) ||
				c.code.toLowerCase().includes(countrySearch.toLowerCase())
			);
		} else {
			filteredCountries = countries;
		}
	});

	async function nextStage() {
		if (currentStage === 2 && !form.businessName) {
			error = 'Please enter your business name';
			return;
		}
		if (currentStage === 3 && (!form.fullName || !form.phone)) {
			error = 'Please complete your profile details';
			return;
		}
		
		error = '';
		if (currentStage < 3) {
			currentStage++;
		} else {
			await completeOnboarding();
		}
	}

	async function completeOnboarding() {
		if (loading) return; // prevent double-click
		loading = true;
		error = '';
		
		try {
			// 1. Create Tenant (Business)
			const slug = form.businessName.toLowerCase().replace(/[^a-z0-9]+/g, '-') + '-' + Math.random().toString(36).substr(2, 5);
			
			const { data: tenant, error: tenantErr } = await supabase
				.from('tenants')
				.insert({
					name: form.businessName,
					slug: slug,
					email: currentUser.email,
					phone: form.phone
				})
				.select()
				.single();

			if (tenantErr) throw tenantErr;

			// 2. Create Subscription (Free Tier)
			const { data: sub, error: subErr } = await supabase
				.from('subscriptions')
				.insert({
					tenant_id: tenant.id,
					plan_tier: 'free',
					monthly_fee: 0,
					commission_rate: 10, // 10% default commission
					max_branches: 1,
					max_staff_users: 10,
					max_products: 1000,
					monthly_transaction_quota: 500,
					billing_cycle_start: new Date().toISOString(),
					billing_cycle_end: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
					status: 'active'
				})
				.select()
				.single();

			if (subErr) throw subErr;

			// 3. Create Default Branch
			const { data: branch, error: branchErr } = await supabase
				.from('branches')
				.insert({
					tenant_id: tenant.id,
					name: form.branchName,
					business_type: form.businessType,
					currency: form.currency,
					phone: form.phone
				})
				.select()
				.single();

			if (branchErr) throw branchErr;

			// 4. Create or Update User Profile (Upsert)
			const { error: userErr } = await supabase
				.from('users')
				.upsert({
					id: currentUser.id,
					tenant_id: tenant.id,
					branch_id: branch.id,
					full_name: form.fullName,
					email: currentUser.email,
					phone: form.phone,
					role: 'tenant_admin',
					onboarding_done: true,
					// Grant all privileges to the tenant owner
					canManagePOS: true,
					canManageProducts: true,
					canManageCustomers: true,
					canManageOrders: true,
					canManageStaff: true,
					canManageInventory: true,
					canManageTransfer: true,
					canManageBranches: true,
					canManageRoles: true,
					canManageScrap: true
				}, { onConflict: 'id' });

			if (userErr) throw userErr;

			// Success! Redirect to dashboard
			goto('/');
		} catch (err: any) {
			console.error('Onboarding error:', err);
			error = err.message || 'An error occurred during setup. Please try again.';
		} finally {
			loading = false;
		}
	}

	async function handleLogout() {
		await supabase.auth.signOut();
		goto('/auth/signup');
	}
</script>

<div class="min-h-screen bg-white font-sans text-gray-900 flex flex-col items-center justify-center p-6 sm:p-12 relative overflow-hidden">
	<!-- Background Accents -->
	<div class="absolute top-0 right-0 -translate-y-1/2 translate-x-1/2 w-[600px] h-[600px] bg-blue-50 rounded-full blur-3xl opacity-50 pointer-events-none"></div>
	<div class="absolute bottom-0 left-0 translate-y-1/2 -translate-x-1/2 w-[600px] h-[600px] bg-blue-50 rounded-full blur-3xl opacity-50 pointer-events-none"></div>

	<!-- Logout Button -->
	<div class="absolute top-6 right-6 z-20">
		<button onclick={handleLogout} class="px-4 py-2 bg-white/50 hover:bg-white text-gray-600 hover:text-gray-900 rounded-full text-sm font-bold border border-gray-100 shadow-sm transition-all">
			Log out & Start Over
		</button>
	</div>

	<div class="w-full max-w-xl relative z-10">
		<!-- Header -->
		<div class="text-center mb-12">
			<div class="inline-flex items-center gap-2 px-3 py-1 bg-blue-50 text-blue-700 rounded-full text-sm font-bold mb-4">
				<Sparkles size={14} /> Setup Your Business
			</div>
			<h1 class="text-4xl font-extrabold tracking-tight text-gray-900 mb-2">Welcome to Kemani POS</h1>
			<p class="text-gray-500 text-lg">Let's get your store ready for sales in minutes.</p>
		</div>

		<!-- Progress Bar -->
		<div class="flex items-center gap-2 mb-10 overflow-x-auto pb-2 scrollbar-hide">
			{#each [1, 2, 3] as stage}
				<div class="flex-1 flex items-center gap-2">
					<div class="w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm transition-all duration-300 {currentStage >= stage ? 'bg-blue-600 text-white shadow-lg shadow-blue-100' : 'bg-gray-100 text-gray-400'}">
						{currentStage > stage ? '✓' : stage}
					</div>
					{#if stage < 3}
						<div class="flex-1 h-1 rounded-full bg-gray-100 overflow-hidden">
							<div class="h-full bg-blue-600 transition-all duration-500" style="width: {currentStage > stage ? '100%' : '0%'}"></div>
						</div>
					{/if}
				</div>
			{/each}
		</div>

		<div class="bg-white/80 backdrop-blur-sm border border-gray-100 rounded-3xl p-8 sm:p-10 shadow-2xl shadow-gray-200/50">
			{#if currentStage === 1}
				<!-- Stage 1: Country -->
				<div class="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
					<div class="flex items-center gap-4 mb-2">
						<div class="bg-blue-100 p-3 rounded-2xl">
							<Globe class="text-blue-600" />
						</div>
						<div>
							<h3 class="text-xl font-bold">Select Your Country</h3>
							<p class="text-sm text-gray-500">We'll use this to set your currency and timezone.</p>
						</div>
					</div>

					<!-- Country Search -->
					<div class="relative group mb-4">
						<Globe class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 group-focus-within:text-blue-600 transition-colors" size={18} />
						<input 
							type="text" 
							bind:value={countrySearch}
							placeholder="Search for your country..."
							class="w-full pl-12 pr-4 py-3 bg-gray-50 border border-gray-100 rounded-2xl focus:ring-2 focus:ring-blue-600 transition-all outline-none font-medium"
						/>
					</div>

					<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 max-h-[400px] overflow-y-auto pr-2 scrollbar-thin">
						{#each filteredCountries as c}
							<button 
								onclick={() => { form.country = c.name; form.currency = c.currency; }}
								class="flex items-center gap-3 p-4 rounded-2xl border-2 transition-all {form.country === c.name ? 'border-blue-600 bg-blue-50/50 shadow-sm' : 'border-gray-50 bg-white hover:border-gray-200'}"
							>
								<span class="text-2xl">{c.flag}</span>
								<div class="text-left min-w-0">
									<p class="font-bold text-gray-900 text-sm truncate">{c.name}</p>
									<p class="text-[10px] text-gray-400 font-mono">{c.currency}</p>
								</div>
								{#if form.country === c.name}
									<CheckCircle2 class="ml-auto text-blue-600 flex-shrink-0" size={16} />
								{/if}
							</button>
						{:else}
							<div class="col-span-full py-12 text-center text-gray-400">
								No countries found matching "{countrySearch}"
							</div>
						{/each}
					</div>
				</div>

			{:else if currentStage === 2}
				<!-- Stage 2: Business -->
				<div class="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
					<div class="flex items-center gap-4 mb-2 text-left">
						<div class="bg-blue-100 p-3 rounded-2xl">
							<Store class="text-blue-600" />
						</div>
						<div>
							<h3 class="text-xl font-bold">Business Setup</h3>
							<p class="text-sm text-gray-500">Tell us about your brand.</p>
						</div>
					</div>

					<div class="space-y-4 text-left">
						<div>
							<label for="businessName" class="block text-sm font-bold text-gray-700 mb-2">Business Name</label>
							<div class="relative group">
								<Building2 class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 group-focus-within:text-blue-600 transition-colors" size={18} />
								<input 
									id="businessName"
									type="text" 
									bind:value={form.businessName}
									placeholder="e.g. Acme Supermarket"
									class="w-full pl-12 pr-4 py-4 bg-gray-50 border border-gray-100 rounded-2xl focus:ring-2 focus:ring-blue-600 transition-all outline-none font-medium"
								/>
							</div>
						</div>

						<div>
							<label class="block text-sm font-bold text-gray-700 mb-2">Business Type</label>
							<div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
								{#each businessTypes as type}
									<button 
										onclick={() => form.businessType = type.id}
										class="flex flex-col p-4 rounded-2xl border-2 transition-all text-left {form.businessType === type.id ? 'border-blue-600 bg-blue-50/50 shadow-sm' : 'border-gray-50 bg-white hover:border-gray-200'}"
									>
										<p class="font-bold text-sm text-gray-900">{type.label}</p>
										<p class="text-[10px] text-gray-500 mt-0.5 leading-tight">{type.description}</p>
									</button>
								{/each}
							</div>
						</div>
					</div>
				</div>

			{:else if currentStage === 3}
				<!-- Stage 3: Profile -->
				<div class="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
					<div class="flex items-center gap-4 mb-2 text-left">
						<div class="bg-emerald-100 p-3 rounded-2xl">
							<User class="text-emerald-600" />
						</div>
						<div>
							<h3 class="text-xl font-bold">Profile Details</h3>
							<p class="text-sm text-gray-500">Complete your personal details.</p>
						</div>
					</div>

					<div class="space-y-4 text-left">
						<div>
							<label for="fullName" class="block text-sm font-bold text-gray-700 mb-2">Full Name</label>
							<div class="relative group">
								<User class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 group-focus-within:text-blue-600 transition-colors" size={18} />
								<input 
									id="fullName"
									type="text" 
									bind:value={form.fullName}
									placeholder="e.g. John Doe"
									class="w-full pl-12 pr-4 py-4 bg-gray-50 border border-gray-100 rounded-2xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all outline-none font-medium"
								/>
							</div>
						</div>

						<div>
							<label for="phone" class="block text-sm font-bold text-gray-700 mb-2">Phone Number</label>
							<div class="relative group">
								<MapPin class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 group-focus-within:text-blue-600 transition-colors" size={18} />
								<input 
									id="phone"
									type="tel" 
									bind:value={form.phone}
									placeholder="e.g. +234 812 345 6789"
									class="w-full pl-12 pr-4 py-4 bg-gray-50 border border-gray-100 rounded-2xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all outline-none font-medium"
								/>
							</div>
						</div>
					</div>
				</div>
			{/if}

			{#if error}
				<div class="mt-6 p-4 bg-red-50 border border-red-100 text-red-600 rounded-2xl text-sm font-medium animate-in shake-in">
					{error}
				</div>
			{/if}

			<!-- Action Buttons -->
			<div class="mt-10 flex gap-4">
				{#if currentStage > 1}
					<button 
						onclick={() => currentStage--}
						class="flex-1 py-4 bg-gray-100 hover:bg-gray-200 text-gray-700 font-bold rounded-2xl transition-all"
					>
						Back
					</button>
				{/if}
				<button 
					onclick={nextStage}
					disabled={loading}
					class="flex-[2] py-4 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-2xl transition-all shadow-xl shadow-blue-100 flex items-center justify-center gap-2"
				>
					{#if loading}
						<Loader2 class="animate-spin" size={20} /> Finalizing Setup...
					{:else}
						{currentStage === 3 ? 'Get Started' : 'Next Step'} <ArrowRight size={20} />
					{/if}
				</button>
			</div>
		</div>

		<p class="mt-8 text-center text-sm text-gray-400">
			Kemani POS - Trusted by 10,000+ business owners across Africa.
		</p>
	</div>
</div>

<style>
	:global(.scrollbar-hide::-webkit-scrollbar) {
		display: none;
	}
	:global(.scrollbar-hide) {
		-ms-overflow-style: none;
		scrollbar-width: none;
	}
	@keyframes shake {
		0%, 100% { transform: translateX(0); }
		25% { transform: translateX(-4px); }
		75% { transform: translateX(4px); }
	}
	.animate-in.shake-in {
		animation: shake 0.5s ease-in-out;
	}
</style>
