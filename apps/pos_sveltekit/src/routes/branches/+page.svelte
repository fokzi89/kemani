<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { Plus, MoreVertical, Edit2, Trash2, Eye, Building2, MapPin, X } from 'lucide-svelte';

	let branches = $state<any[]>([]);
	let loading = $state(true);
	let tenantId = $state<string | null>(null);

	// Modal state
	let showModal = $state(false);
	let isEditing = $state(false);
	let editingId = $state<string | null>(null);
	let saving = $state(false);

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

	function getBusinessTypeLabel(id: string) {
		return businessTypes.find(t => t.id === id)?.label || 'Other';
	}

	async function fetchBranches() {
		try {
			const { data: { session } } = await supabase.auth.getSession();
			if (!session) return;

			// Quick fetch of the user to get tenant bounds
			const { data: user } = await supabase
				.from('users')
				.select('tenant_id')
				.eq('id', session.user.id)
				.single();

			if (!user) return;
			tenantId = user.tenant_id;

			// Fetch Branches alongside staff count
			const { data, error } = await supabase
				.from('branches')
				.select(`
					*,
					users!branch_id (count)
				`)
				.eq('tenant_id', tenantId)
				.is('deleted_at', null)
				.order('created_at', { ascending: false });

			if (error) throw error;
			
			// Map count extraction (supabase returns users: [{count: x}])
			branches = (data || []).map(b => ({
				...b,
				staff_count: Array.isArray(b.users) ? b.users[0]?.count || 0 : (b.users?.count || 0)
			}));
		} catch (e) {
			console.error('Error fetching branches', e);
		} finally {
			loading = false;
		}
	}

	onMount(async () => {
		fetchBranches();
		
		// Fetch countries
		try {
			const res = await fetch('https://restcountries.com/v3.1/all?fields=name,flag,cca2,currencies,idd');
			const data = await res.json();
			countries = data.map((c: any) => ({
				name: c.name.common,
				code: c.cca2,
				flag: c.flag,
				dialCode: c.idd?.root ? (c.idd.root + (c.idd.suffixes?.[0] || '')) : '',
				currency: c.currencies ? Object.keys(c.currencies)[0] : 'USD'
			})).sort((a: any, b: any) => a.name.localeCompare(b.name));
			filteredCountries = countries;
		} catch (e) {
			console.error('Failed to fetch countries:', e);
			countries = [{ name: 'Nigeria', code: 'NG', currency: 'NGN', flag: '🇳🇬', dialCode: '+234' }];
			filteredCountries = countries;
		}
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

	function selectCountry(c: any) {
		form.country = c.name;
		form.currency = c.currency;
		if (!form.phone || form.phone.startsWith('+')) {
			form.phone = c.dialCode + ' ';
		}
		countrySearch = '';
		showCountryDropdown = false;
	}

	function openAddModal() {
		form = { name: '', business_type: 'pharmacy_supermarket', address: '', city: '', state: '', country: '', currency: 'NGN', phone: '', latitude: '', longitude: '' };
		isEditing = false;
		editingId = null;
		showModal = true;
	}

	function openEditModal(branch: any) {
		form = { 
			name: branch.name, 
			business_type: branch.business_type, 
			address: branch.address || '', 
			city: branch.city || '',
			state: branch.state || '',
			country: branch.country || '',
			currency: branch.currency || 'NGN',
			phone: branch.phone || '',
			latitude: branch.latitude ? String(branch.latitude) : '',
			longitude: branch.longitude ? String(branch.longitude) : 
			'' 
		};
		isEditing = true;
		editingId = branch.id;
		showModal = true;
	}

	async function saveBranch(e: Event) {
		e.preventDefault();
		if (!tenantId) return;
		saving = true;

		try {
			if (isEditing && editingId) {
				const { error } = await supabase
					.from('branches')
					.update({
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
					})
					.eq('id', editingId);
				if (error) throw error;
			} else {
				const { error } = await supabase
					.from('branches')
					.insert({
						tenant_id: tenantId,
						name: form.name,
						business_type: form.business_type,
						address: form.address,
						city: form.city,
						state: form.state,
						country: form.country,
						currency: form.currency,
						latitude: form.latitude ? parseFloat(form.latitude) : null,
						longitude: form.longitude ? parseFloat(form.longitude) : null,
						phone: form.phone
					});
				if (error) throw error;
			}
			showModal = false;
			await fetchBranches();
		} catch (e) {
			console.error('Error saving branch', e);
			alert('Failed to save branch. Please check inputs.');
		} finally {
			saving = false;
		}
	}

	async function deleteBranch(id: string) {
		if (!confirm('Are you sure you want to completely delete this branch?')) return;
		try {
			const { error } = await supabase
				.from('branches')
				.update({ deleted_at: new Date().toISOString() })
				.eq('id', id);
			
			if (error) throw error;
			// Refresh list efficiently
			branches = branches.filter(b => b.id !== id);
		} catch (e) {
			console.error('Error deleting branch', e);
			alert('Failed to delete branch');
		}
	}

	// Active dropdown menu ID logic
	let activeDropdown = $state<string | null>(null);
	function toggleDropdown(id: string) {
		activeDropdown = activeDropdown === id ? null : id;
	}

	let detectingLocation = $state(false);
	function detectLocation() {
		if (!navigator.geolocation) {
			alert('Geolocation is not supported by your browser.');
			return;
		}
		detectingLocation = true;
		navigator.geolocation.getCurrentPosition(
			(position) => {
				form.latitude = position.coords.latitude.toFixed(6);
				form.longitude = position.coords.longitude.toFixed(6);
				detectingLocation = false;
			},
			(error) => {
				console.error('Error getting location', error);
				alert('Failed to detect location. Please check your browser permissions.');
				detectingLocation = false;
			},
			{ enableHighAccuracy: true }
		);
	}
</script>

<div class="p-6 md:p-8 max-w-7xl mx-auto w-full">
	<div class="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-8 gap-4">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">Branch Management</h1>
			<p class="text-sm text-gray-500 mt-1">Manage all your store locations and retail branches.</p>
		</div>
		<button
			onclick={openAddModal}
			class="inline-flex items-center gap-2 bg-blue-600 text-white px-6 py-2.5 rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors shadow-sm focus:ring-4 focus:ring-blue-600/20"
		>
			<Plus class="h-4 w-4" />
			Add Branch
		</button>
	</div>

	{#if loading}
		<div class="flex justify-center items-center py-20">
			<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
		</div>
	{:else if branches.length === 0}
		<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-12 text-center flex items-center justify-center flex-col">
			<div class="h-14 w-14 bg-blue-50 text-blue-600 rounded-full flex items-center justify-center mb-5">
				<Building2 class="h-7 w-7" />
			</div>
			<h3 class="text-lg font-bold text-gray-900 mb-2">No Branches Found</h3>
			<p class="text-gray-500 text-sm max-w-sm">Get started by creating your first branch. Stores, clinics, and offices can all be managed seamlessly here.</p>
			<button
				onclick={openAddModal}
				class="mt-6 inline-flex items-center gap-2 bg-white text-blue-700 border border-blue-200 px-8 py-2.5 rounded-lg text-sm font-bold hover:bg-blue-50 transition-colors"
			>
				<Plus class="h-4 w-4" />
				Create First Branch
			</button>
		</div>
	{:else}
		<div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-visible">
			<div class="overflow-x-auto overflow-y-visible">
				<table class="w-full text-left border-collapse min-w-[700px]">
					<thead>
						<tr class="bg-gray-50/80 border-b border-gray-100">
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Branch Details</th>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Business Type</th>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Address & Contact</th>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider text-center">Staffs</th>
							<th class="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider text-right">Actions</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-gray-100">
						{#each branches as branch}
							<tr class="hover:bg-blue-50/30 transition-colors group">
								<td class="px-6 py-4 whitespace-nowrap">
									<div class="flex items-center gap-3">
										<div class="h-10 w-10 rounded-lg bg-gray-100 flex items-center justify-center text-gray-500 group-hover:bg-blue-100 group-hover:text-blue-600 transition-colors">
											<Building2 class="h-5 w-5" />
										</div>
										<div>
											<p class="text-sm font-bold text-gray-900">{branch.name}</p>
											{#if branch.created_at}
												<p class="text-xs text-gray-400 mt-0.5">Added {new Date(branch.created_at).toLocaleDateString()}</p>
											{/if}
										</div>
									</div>
								</td>
								<td class="px-6 py-4 whitespace-nowrap">
									<span class="inline-flex px-2.5 py-1 bg-blue-50 text-blue-700/80 border border-blue-100/50 rounded-md text-xs font-semibold">
										{getBusinessTypeLabel(branch.business_type)}
									</span>
								</td>
								<td class="px-6 py-4">
									<div class="flex flex-col gap-1 w-full max-w-[250px]">
										<div class="flex items-start gap-1.5 text-sm text-gray-600">
											<MapPin class="h-4 w-4 mt-0.5 shrink-0 text-gray-400" />
											<span class="truncate" title={branch.address}>{branch.address || 'No address provided'}</span>
										</div>
										{#if branch.phone}
											<p class="text-xs text-gray-400 font-medium ml-5.5 pl-[22px]">{branch.phone}</p>
										{/if}
									</div>
								</td>
								<td class="px-6 py-4 whitespace-nowrap text-center">
									<span class="inline-flex items-center justify-center h-7 min-w-[28px] px-2 bg-gray-100 text-gray-700 rounded-full text-xs font-bold border border-gray-200">
										{branch.staff_count}
									</span>
								</td>
								<td class="px-6 py-4 whitespace-nowrap text-right relative">
									<!-- Custom Dropdown -->
									<div class="relative inline-block text-left">
										<button 
											onclick={() => toggleDropdown(branch.id)}
											class="p-2 text-gray-400 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors focus:ring-2 focus:ring-gray-200"
										>
											<MoreVertical class="h-5 w-5" />
										</button>

										{#if activeDropdown === branch.id}
											<button 
												class="fixed inset-0 h-full w-full cursor-default z-10 bg-transparent"
												onclick={() => activeDropdown = null}
											></button>
											
											<div class="absolute right-0 mt-1 w-48 bg-white rounded-xl shadow-[0_10px_40px_-10px_rgba(0,0,0,0.1)] border border-gray-100 overflow-hidden z-20">
												<div class="py-1">
													<a 
														href="/branches/{branch.id}"
														class="w-full text-left px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50 flex items-center gap-3"
													>
														<Eye class="h-4 w-4 text-gray-400" />
														View Details
													</a>
													<button 
														onclick={() => { activeDropdown = null; openEditModal(branch); }}
														class="w-full text-left px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50 flex items-center gap-3"
													>
														<Edit2 class="h-4 w-4 text-blue-500" />
														Edit Branch
													</button>
													<div class="h-px bg-gray-100 my-1 w-full scale-x-90"></div>
													<button 
														onclick={() => { activeDropdown = null; deleteBranch(branch.id); }}
														class="w-full text-left px-4 py-2.5 text-sm font-medium text-red-600 hover:bg-red-50 flex items-center gap-3"
													>
														<Trash2 class="h-4 w-4 text-red-500" />
														Delete Branch
													</button>
												</div>
											</div>
										{/if}
									</div>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		</div>
	{/if}
</div>

<!-- Modal -->
{#if showModal}
	<div class="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6">
		<!-- Backdrop -->
		<button class="absolute inset-0 bg-slate-900/30 backdrop-blur-sm cursor-default transition-all duration-300" onclick={() => !saving && (showModal = false)}></button>
		
		<!-- Modal Content -->
		<div class="relative bg-white rounded-2xl shadow-2xl w-full overflow-hidden border border-gray-100/50 flex flex-col max-h-[90vh]" style="max-width: 450px;">
			<div class="p-6 border-b border-gray-100 flex justify-between items-start bg-white shrink-0">
				<div>
					<div class="w-14 h-14 bg-blue-50 text-blue-600 rounded-2xl flex items-center justify-center mb-5 shadow-sm shadow-blue-100/50">
						<Building2 class="h-7 w-7" />
					</div>
					<h2 class="text-2xl font-extrabold text-gray-900">{isEditing ? 'Edit Branch' : 'Create New Branch'}</h2>
					<p class="text-sm font-medium text-gray-500 mt-1.5">{isEditing ? 'Update the details for this branch location.' : 'Fill out the details to add a new branch.'}</p>
				</div>
				<button 
					onclick={() => showModal = false}
					disabled={saving}
					class="p-2.5 text-gray-400 hover:text-gray-700 hover:bg-gray-50 rounded-xl transition-colors disabled:opacity-50"
				>
					<X class="h-6 w-6" />
				</button>
			</div>

			<form onsubmit={saveBranch} class="flex flex-col min-h-0">
				<div class="p-6 space-y-5 overflow-y-auto">
					<div>
						<label for="name" class="block text-sm font-bold text-gray-700 mb-2">Branch Name <span class="text-red-500">*</span></label>
						<input
							type="text"
							id="name"
							required
							bind:value={form.name}
							placeholder="e.g. Main POS Desk, Ikeja Branch"
							class="w-full px-4 py-3.5 text-sm bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-blue-600 focus:bg-white outline-none transition-all font-medium placeholder:font-normal placeholder:text-gray-400 hover:border-gray-200 hover:bg-gray-50/50"
						/>
					</div>

					<div>
						<label for="btype" class="block text-sm font-bold text-gray-700 mb-2">Business Type</label>
						<select
							id="btype"
							bind:value={form.business_type}
							class="w-full px-4 py-3.5 text-sm bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-blue-600 focus:bg-white outline-none transition-all font-medium appearance-none hover:border-gray-200 hover:bg-gray-50/50"
						>
							{#each businessTypes as type}
								<option value={type.id}>{type.label}</option>
							{/each}
						</select>
					</div>

					<div>
						<label for="phone" class="block text-sm font-bold text-gray-700 mb-2">Contact Number</label>
						<input
							type="tel"
							id="phone"
							bind:value={form.phone}
							placeholder="e.g. +234 800 000 0000"
							class="w-full px-4 py-3.5 text-sm bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-blue-600 focus:bg-white outline-none transition-all font-medium placeholder:font-normal placeholder:text-gray-400 hover:border-gray-200 hover:bg-gray-50/50"
						/>
					</div>

					<div>
						<label for="address" class="block text-sm font-bold text-gray-700 mb-2">Physical Address Location</label>
						<textarea
							id="address"
							bind:value={form.address}
							placeholder="Full address of the branch"
							rows="2"
							class="w-full px-4 py-3.5 text-sm bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-blue-600 focus:bg-white outline-none transition-all font-medium resize-none placeholder:font-normal placeholder:text-gray-400 hover:border-gray-200 hover:bg-gray-50/50"
						></textarea>
					</div>

					<div class="grid grid-cols-2 gap-4">
						<div>
							<label for="city" class="block text-sm font-bold text-gray-700 mb-2">City</label>
							<input
								type="text"
								id="city"
								bind:value={form.city}
								placeholder="e.g. Lagos"
								class="w-full px-4 py-3.5 text-sm bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-blue-600 focus:bg-white outline-none transition-all font-medium placeholder:font-normal placeholder:text-gray-400 hover:border-gray-200 hover:bg-gray-50/50"
							/>
						</div>
						<div>
							<label for="state" class="block text-sm font-bold text-gray-700 mb-2">State</label>
							<input
								type="text"
								id="state"
								bind:value={form.state}
								placeholder="e.g. Lagos State"
								class="w-full px-4 py-3.5 text-sm bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-blue-600 focus:bg-white outline-none transition-all font-medium placeholder:font-normal placeholder:text-gray-400 hover:border-gray-200 hover:bg-gray-50/50"
							/>
						</div>
					</div>

					<div class="relative">
						<label for="country" class="block text-sm font-bold text-gray-700 mb-2">Country</label>
						<div class="relative">
							<input
								type="text"
								id="country"
								bind:value={form.country}
								onfocus={() => showCountryDropdown = true}
								oninput={(e) => { countrySearch = e.currentTarget.value; showCountryDropdown = true; }}
								placeholder="Search and select country"
								class="w-full px-4 py-3.5 text-sm bg-gray-100 border border-gray-100 rounded-xl focus:ring-2 focus:ring-blue-600 focus:bg-white outline-none transition-all font-medium placeholder:font-normal placeholder:text-gray-400"
							/>
							{#if showCountryDropdown}
								<div class="absolute z-50 left-0 right-0 mt-2 bg-white rounded-2xl shadow-2xl border border-gray-100 overflow-hidden max-h-[300px] overflow-y-auto">
									<div class="p-2 space-y-1">
										{#each filteredCountries as c}
											<button
												type="button"
												onclick={() => selectCountry(c)}
												class="w-full flex items-center gap-3 p-3 rounded-xl hover:bg-gray-50 transition-colors text-left"
											>
												<span class="text-xl">{c.flag}</span>
												<span class="text-sm font-medium text-gray-900">{c.name}</span>
												<span class="ml-auto text-xs text-gray-400 font-bold">{c.dialCode}</span>
											</button>
										{:else}
											<div class="p-4 text-center text-sm text-gray-500">No countries found</div>
										{/each}
									</div>
								</div>
								<!-- Overlay to close dropdown -->
								<button type="button" class="fixed inset-0 z-40 bg-transparent cursor-default" onclick={() => showCountryDropdown = false}></button>
							{/if}
						</div>
					</div>

					<div>
						<label for="currency" class="block text-sm font-bold text-gray-700 mb-2">Currency</label>
						<input
							type="text"
							id="currency"
							bind:value={form.currency}
							readonly
							class="w-full px-4 py-3.5 text-sm bg-gray-50 border border-gray-100 rounded-xl focus:outline-none font-bold text-gray-600"
						/>
					</div>

					<div class="pt-2 border-t border-gray-100 mt-2">
						<div class="flex items-center justify-between mb-2">
							<span class="block text-sm font-bold text-gray-700">GPS Coordinates</span>
							<button 
								type="button" 
								onclick={detectLocation}
								disabled={detectingLocation}
								class="text-xs font-bold text-blue-600 hover:text-blue-700 flex items-center gap-1.5 transition-colors disabled:opacity-50"
							>
								{#if detectingLocation}
									<div class="w-3 h-3 rounded-full border-2 border-blue-600/30 border-t-blue-600 animate-spin"></div>
									Detecting...
								{:else}
									<MapPin class="h-3.5 w-3.5" />
									Auto-Detect
								{/if}
							</button>
						</div>
						
						<div class="grid grid-cols-2 gap-4">
							<div>
								<label for="latitude" class="block text-xs font-semibold text-gray-500 mb-1.5 hidden">Latitude</label>
								<input
									type="text"
									id="latitude"
									bind:value={form.latitude}
									placeholder="Latitude (e.g. 6.5244)"
									class="w-full px-4 py-3 text-sm bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-blue-600 focus:bg-white outline-none transition-all font-medium placeholder:font-normal placeholder:text-gray-400 hover:border-gray-200 hover:bg-gray-50/50"
								/>
							</div>
							<div>
								<label for="longitude" class="block text-xs font-semibold text-gray-500 mb-1.5 hidden">Longitude</label>
								<input
									type="text"
									id="longitude"
									bind:value={form.longitude}
									placeholder="Longitude (e.g. 3.3792)"
									class="w-full px-4 py-3 text-sm bg-gray-50 border border-gray-100 rounded-xl focus:ring-2 focus:ring-blue-600 focus:bg-white outline-none transition-all font-medium placeholder:font-normal placeholder:text-gray-400 hover:border-gray-200 hover:bg-gray-50/50"
								/>
							</div>
						</div>
					</div>
				</div>

				<div class="px-6 py-5 bg-gray-50/80 border-t border-gray-100 flex gap-3 justify-end items-center shrink-0">
					<button
						type="button"
						onclick={() => showModal = false}
						disabled={saving}
						class="px-6 py-3.5 text-sm font-bold text-gray-600 bg-white border border-gray-200 hover:bg-gray-50 hover:text-gray-900 rounded-xl transition-colors disabled:opacity-50"
					>
						Cancel
					</button>
					<button
						type="submit"
						disabled={saving || !form.name.trim()}
						class="px-8 py-3.5 text-sm font-bold text-white bg-blue-600 rounded-xl shadow-lg shadow-blue-100 hover:bg-blue-700 hover:scale-[1.02] active:scale-[0.98] transition-all disabled:opacity-50 flex items-center gap-2"
					>
						{#if saving}
							<div class="w-4 h-4 rounded-full border-2 border-white/30 border-t-white animate-spin"></div>
							Saving...
						{:else}
							{isEditing ? 'Apply Changes' : 'Create Branch'}
						{/if}
					</button>
				</div>
			</form>
		</div>
	</div>
{/if}
