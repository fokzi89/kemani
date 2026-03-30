<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { ArrowLeft, Save, AlertCircle, Building2, MapPin, Phone } from 'lucide-svelte';

	const branchId = $page.params.id;
	let loading = $state(true);
	let saving = $state(false);
	let error = $state('');
	let detectingLocation = $state(false);

	let form = $state({
		name: '',
		business_type: 'pharmacy_supermarket',
		address: '',
		city: '',
		state: '',
		country: '',
		currency: 'NGN',
		phone: '',
		latitude: '',
		longitude: ''
	});

	let countries = $state<any[]>([]);
	let filteredCountries = $state<any[]>([]);
	let countrySearch = $state('');
	let showCountryDropdown = $state(false);

	const businessTypes = [
		{ id: 'pharmacy_supermarket', label: 'Pharmacy & Supermarket' },
		{ id: 'diagnostic_centre', label: 'Diagnostic Centre' },
		{ id: 'supermarket', label: 'Supermarket' },
		{ id: 'pharmacy', label: 'Pharmacy' },
		{ id: 'clinic', label: 'Clinic/Hospital' },
		{ id: 'other', label: 'Other/Retail' }
	];

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

	function selectCountry(c: any) {
		form.country = c.name;
		form.currency = c.currency;
		countrySearch = '';
		showCountryDropdown = false;
	}

	function detectLocation() {
		if (!navigator.geolocation) { error = 'Geolocation is not supported.'; return; }
		detectingLocation = true;
		navigator.geolocation.getCurrentPosition(
			(position) => {
				form.latitude = position.coords.latitude.toFixed(6);
				form.longitude = position.coords.longitude.toFixed(6);
				detectingLocation = false;
			},
			() => { error = 'Failed to detect location.'; detectingLocation = false; },
			{ enableHighAccuracy: true }
		);
	}

	onMount(async () => {
		// Load branch data
		const { data } = await supabase.from('branches').select('*').eq('id', branchId).single();
		if (data) {
			form = {
				name: data.name || '',
				business_type: data.business_type || 'pharmacy_supermarket',
				address: data.address || '',
				city: data.city || '',
				state: data.state || '',
				country: data.country || '',
				currency: data.currency || 'NGN',
				phone: data.phone || '',
				latitude: data.latitude ? String(data.latitude) : '',
				longitude: data.longitude ? String(data.longitude) : ''
			};
		}
		loading = false;

		// Load countries
		try {
			const res = await fetch('https://restcountries.com/v3.1/all?fields=name,flag,cca2,currencies,idd');
			const raw = await res.json();
			countries = raw.map((c: any) => ({
				name: c.name.common,
				code: c.cca2,
				flag: c.flag,
				dialCode: c.idd?.root ? (c.idd.root + (c.idd.suffixes?.[0] || '')) : '',
				currency: c.currencies ? Object.keys(c.currencies)[0] : 'USD'
			})).sort((a: any, b: any) => a.name.localeCompare(b.name));
			filteredCountries = countries;
		} catch {
			countries = [{ name: 'Nigeria', code: 'NG', currency: 'NGN', flag: '🇳🇬', dialCode: '+234' }];
			filteredCountries = countries;
		}
	});

	async function handleSubmit(e: Event) {
		e.preventDefault();
		if (!form.name) { error = 'Branch name is required'; return; }
		saving = true; error = '';
		try {
			const { error: dbErr } = await supabase.from('branches').update({
				name: form.name,
				business_type: form.business_type,
				address: form.address,
				city: form.city,
				state: form.state,
				country: form.country,
				currency: form.currency,
				latitude: form.latitude ? parseFloat(form.latitude) : null,
				longitude: form.longitude ? parseFloat(form.longitude) : null,
				phone: form.phone,
				updated_at: new Date().toISOString()
			}).eq('id', branchId);
			if (dbErr) throw dbErr;
			goto('/branches');
		} catch (err: any) {
			error = err.message || 'Failed to update branch';
		} finally {
			saving = false;
		}
	}
</script>

<svelte:head><title>Edit Branch – Kemani POS</title></svelte:head>

<div class="p-6 max-w-2xl mx-auto">
	<div class="flex items-center gap-3 mb-6">
		<a href="/branches" class="p-2 hover:bg-gray-100 rounded-lg transition-colors">
			<ArrowLeft class="h-5 w-5 text-gray-600" />
		</a>
		<div>
			<h1 class="text-xl font-bold text-gray-900">Edit Branch</h1>
			<p class="text-sm text-gray-500">Update the details for this branch location</p>
		</div>
	</div>

	{#if error}
		<div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg mb-5 flex items-start gap-2">
			<AlertCircle class="h-5 w-5 flex-shrink-0 mt-0.5" /><p class="text-sm">{error}</p>
		</div>
	{/if}

	{#if loading}
		<div class="p-12 text-center">
			<div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600 mx-auto"></div>
		</div>
	{:else}
		<form onsubmit={handleSubmit} class="space-y-5">
			<!-- Basic Info -->
			<div class="bg-white rounded-xl border p-5 space-y-4">
				<h2 class="font-semibold text-sm uppercase tracking-wider text-gray-500 flex items-center gap-2">
					<Building2 class="h-3.5 w-3.5" /> Basic Info
				</h2>
				<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
					<div class="sm:col-span-2">
						<label for="br_name" class="block text-sm font-medium text-gray-700 mb-1">Branch Name <span class="text-red-500">*</span></label>
						<input id="br_name" type="text" required bind:value={form.name}
							placeholder="e.g. Main POS Desk, Ikeja Branch"
							class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div>
						<label for="br_type" class="block text-sm font-medium text-gray-700 mb-1">Business Type</label>
						<select id="br_type" bind:value={form.business_type}
							class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm bg-white">
							{#each businessTypes as type}
								<option value={type.id}>{type.label}</option>
							{/each}
						</select>
					</div>
					<div>
						<label for="br_phone" class="block text-sm font-medium text-gray-700 mb-1">Contact Number</label>
						<div class="relative">
							<Phone class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400 pointer-events-none" />
							<input id="br_phone" type="tel" bind:value={form.phone}
								placeholder="e.g. +234 800 000 0000"
								class="w-full pl-9 pr-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
						</div>
					</div>
				</div>
			</div>

			<!-- Location -->
			<div class="bg-white rounded-xl border p-5 space-y-4">
				<h2 class="font-semibold text-sm uppercase tracking-wider text-gray-500 flex items-center gap-2">
					<MapPin class="h-3.5 w-3.5" /> Location
				</h2>
				<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
					<div class="sm:col-span-2">
						<label for="br_address" class="block text-sm font-medium text-gray-700 mb-1">Physical Address</label>
						<textarea id="br_address" bind:value={form.address} rows="2"
							placeholder="Full address of the branch"
							class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm resize-none"></textarea>
					</div>
					<div>
						<label for="br_city" class="block text-sm font-medium text-gray-700 mb-1">City</label>
						<input id="br_city" type="text" bind:value={form.city} placeholder="e.g. Lagos"
							class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div>
						<label for="br_state" class="block text-sm font-medium text-gray-700 mb-1">State</label>
						<input id="br_state" type="text" bind:value={form.state} placeholder="e.g. Lagos State"
							class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
					<div class="sm:col-span-2 relative">
						<label for="br_country" class="block text-sm font-medium text-gray-700 mb-1">Country</label>
						<input id="br_country" type="text" bind:value={form.country}
							onfocus={() => showCountryDropdown = true}
							oninput={(e) => { countrySearch = e.currentTarget.value; showCountryDropdown = true; }}
							placeholder="Search and select country"
							class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
						{#if showCountryDropdown}
							<div class="absolute z-50 left-0 right-0 mt-1 bg-white rounded-lg shadow-xl border border-gray-200 overflow-hidden max-h-60 overflow-y-auto">
								<div class="p-1.5 space-y-0.5">
									{#each filteredCountries as c}
										<button type="button" onclick={() => selectCountry(c)}
											class="w-full flex items-center gap-3 px-3 py-2 rounded-md hover:bg-gray-50 transition-colors text-left text-sm">
											<span class="text-lg">{c.flag}</span>
											<span class="font-medium text-gray-900">{c.name}</span>
											<span class="ml-auto text-xs text-gray-400">{c.dialCode}</span>
										</button>
									{:else}
										<div class="p-3 text-center text-sm text-gray-400">No countries found</div>
									{/each}
								</div>
							</div>
							<button type="button" class="fixed inset-0 z-40 bg-transparent cursor-default" onclick={() => showCountryDropdown = false} aria-label="Close dropdown"></button>
						{/if}
					</div>
					<div>
						<label for="br_currency" class="block text-sm font-medium text-gray-700 mb-1">Currency</label>
						<input id="br_currency" type="text" bind:value={form.currency} readonly
							class="w-full px-3 py-2.5 border border-gray-200 rounded-lg bg-gray-50 text-sm font-semibold text-gray-600 cursor-not-allowed" />
					</div>
				</div>

				<!-- GPS -->
				<div class="border-t pt-4 space-y-3">
					<div class="flex items-center justify-between">
						<span class="text-sm font-medium text-gray-700">GPS Coordinates</span>
						<button type="button" onclick={detectLocation} disabled={detectingLocation}
							class="text-xs font-semibold text-indigo-600 hover:text-indigo-700 flex items-center gap-1.5 transition-colors disabled:opacity-50">
							{#if detectingLocation}
								<div class="w-3 h-3 rounded-full border-2 border-indigo-600/30 border-t-indigo-600 animate-spin"></div>
								Detecting...
							{:else}
								<MapPin class="h-3.5 w-3.5" /> Auto-Detect
							{/if}
						</button>
					</div>
					<div class="grid grid-cols-2 gap-4">
						<input type="text" bind:value={form.latitude} placeholder="Latitude (e.g. 6.5244)"
							class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
						<input type="text" bind:value={form.longitude} placeholder="Longitude (e.g. 3.3792)"
							class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm" />
					</div>
				</div>
			</div>

			<div class="flex gap-3">
				<a href="/branches" class="flex-1 flex items-center justify-center px-4 py-2.5 border border-gray-300 text-gray-700 font-medium rounded-xl hover:bg-gray-50 transition-colors text-sm">
					Cancel
				</a>
				<button type="submit" disabled={saving}
					class="flex-1 flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-2.5 rounded-xl transition-colors disabled:opacity-50 text-sm">
					<Save class="h-4 w-4" />{saving ? 'Saving...' : 'Save Changes'}
				</button>
			</div>
		</form>
	{/if}
</div>
