<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { Save, AlertCircle, CheckCircle, Store, Globe, DollarSign, Bell, Stethoscope, Sparkles } from 'lucide-svelte';

	let loading = $state(true);
	let saving = $state(false);
	let success = $state(false);
	let error = $state('');
	let tenantId = $state('');
	let settings = $state({
		business_name: '', business_type: '', phone: '', email: '',
		address: '', currency: 'NGN', timezone: 'Africa/Lagos',
		receipt_footer: '', low_stock_threshold: '10',
		tax_rate: '0', tax_name: 'VAT',
		logo_url: '', slogan: '', hero_title: '', hero_subtitle: '', about_us: ''
	});
	let allowPartnership = $state(true);

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		const { data: user } = await supabase.from('users').select('tenant_id').eq('id', session.user.id).single();
		if (user?.tenant_id) {
			tenantId = user.tenant_id;
			const { data: tenant } = await supabase.from('tenants').select('*').eq('id', tenantId).single();
			if (tenant) {
				settings = {
					business_name: tenant.business_name || '',
					business_type: tenant.business_type || '',
					phone: tenant.phone || '',
					email: tenant.email || '',
					address: tenant.address || '',
					currency: tenant.currency || 'NGN',
					timezone: tenant.timezone || 'Africa/Lagos',
					receipt_footer: tenant.receipt_footer || 'Thank you for shopping with us!',
					low_stock_threshold: (tenant.low_stock_threshold || 10).toString(),
					tax_rate: (tenant.tax_rate || 0).toString(),
					tax_name: tenant.tax_name || 'VAT',
					logo_url: tenant.logo_url || '',
					slogan: tenant.slogan || '',
					hero_title: tenant.hero_title || '',
					hero_subtitle: tenant.hero_subtitle || '',
					about_us: tenant.about_us || ''
				};
				allowPartnership = tenant.allowDoctorPartnerShip ?? true;
			}
		}
		loading = false;
	});

	async function handleSave(e: Event) {
		e.preventDefault();
		saving = true; error = ''; success = false;
		try {
			const { error: dbErr } = await supabase.from('tenants').update({
				business_name: settings.business_name,
				business_type: settings.business_type || null,
				phone: settings.phone || null,
				email: settings.email || null,
				address: settings.address || null,
				currency: settings.currency,
				timezone: settings.timezone,
				receipt_footer: settings.receipt_footer || null,
				low_stock_threshold: parseInt(settings.low_stock_threshold),
				tax_rate: parseFloat(settings.tax_rate),
				tax_name: settings.tax_name || null,
				logo_url: settings.logo_url || null,
				slogan: settings.slogan || null,
				hero_title: settings.hero_title || null,
				hero_subtitle: settings.hero_subtitle || null,
				about_us: settings.about_us || null,
				allowDoctorPartnerShip: allowPartnership
			}).eq('id', tenantId);
			if (dbErr) throw dbErr;
			success = true;
			setTimeout(() => success = false, 3000);
		} catch (err: any) {
			error = err.message || 'Failed to save settings';
		} finally { saving = false; }
	}

	const currencies = ['NGN', 'USD', 'GBP', 'EUR', 'GHS', 'KES', 'ZAR'];
	const timezones = ['Africa/Lagos', 'Africa/Nairobi', 'Africa/Accra', 'Africa/Johannesburg', 'Europe/London', 'America/New_York'];
</script>

<svelte:head><title>Settings – Kemani POS</title></svelte:head>

<div class="p-6 max-w-2xl mx-auto">
	<div class="mb-6">
		<h1 class="text-2xl font-bold text-gray-900">Settings</h1>
		<p class="text-sm text-gray-500 mt-0.5">Manage your business configuration</p>
	</div>

	{#if success}
		<div class="bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded-lg mb-5 flex items-center gap-2">
			<CheckCircle class="h-5 w-5" /><p class="text-sm font-medium">Settings saved successfully!</p>
		</div>
	{/if}
	{#if error}
		<div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg mb-5 flex items-start gap-2">
			<AlertCircle class="h-5 w-5 flex-shrink-0 mt-0.5" /><p class="text-sm">{error}</p>
		</div>
	{/if}

	{#if loading}
		<div class="p-12 text-center"><div class="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600 mx-auto"></div></div>
	{:else}
		<form onsubmit={handleSave} class="space-y-5">
			<!-- Business Info -->
			<div class="bg-white rounded-xl border p-5 space-y-4">
				<h2 class="font-semibold text-gray-900 flex items-center gap-2"><Store class="h-4 w-4 text-indigo-500" /> Business Information</h2>
				<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
					<div class="sm:col-span-2">
						<label class="block text-sm font-medium text-gray-700 mb-1">Business Name *</label>
						<input type="text" bind:value={settings.business_name} required class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 text-sm" />
					</div>
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">Business Type</label>
						<input type="text" bind:value={settings.business_type} placeholder="e.g. Retail, Restaurant..." class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 text-sm" />
					</div>
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">Phone</label>
						<input type="tel" bind:value={settings.phone} class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 text-sm" />
					</div>
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
						<input type="email" bind:value={settings.email} class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 text-sm" />
					</div>
					<div class="sm:col-span-2">
						<label class="block text-sm font-medium text-gray-700 mb-1">Address</label>
						<input type="text" bind:value={settings.address} placeholder="Business address" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 text-sm" />
					</div>
				</div>
			</div>

			<!-- Regional -->
			<div class="bg-white rounded-xl border p-5 space-y-4">
				<h2 class="font-semibold text-gray-900 flex items-center gap-2"><Globe class="h-4 w-4 text-indigo-500" /> Regional Settings</h2>
				<div class="grid grid-cols-2 gap-4">
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">Currency</label>
						<select bind:value={settings.currency} class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 text-sm bg-white">
							{#each currencies as c}<option value={c}>{c}</option>{/each}
						</select>
					</div>
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">Timezone</label>
						<select bind:value={settings.timezone} class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 text-sm bg-white">
							{#each timezones as tz}<option value={tz}>{tz}</option>{/each}
						</select>
					</div>
				</div>
			</div>

			<!-- Tax + Inventory -->
			<div class="bg-white rounded-xl border p-5 space-y-4">
				<h2 class="font-semibold text-gray-900 flex items-center gap-2"><DollarSign class="h-4 w-4 text-indigo-500" /> Tax &amp; Inventory</h2>
				<div class="grid grid-cols-3 gap-4">
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">Tax Name</label>
						<input type="text" bind:value={settings.tax_name} placeholder="VAT" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 text-sm" />
					</div>
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">Tax Rate (%)</label>
						<input type="number" bind:value={settings.tax_rate} min="0" max="100" step="0.1" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 text-sm" />
					</div>
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">Low Stock Alert</label>
						<input type="number" bind:value={settings.low_stock_threshold} min="0" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 text-sm" />
					</div>
				</div>
			</div>

			<!-- Receipt -->
			<div class="bg-white rounded-xl border p-5 space-y-4">
				<h2 class="font-semibold text-gray-900 flex items-center gap-2"><Bell class="h-4 w-4 text-indigo-500" /> Receipt Settings</h2>
				<div>
					<label class="block text-sm font-medium text-gray-700 mb-1">Receipt Footer Message</label>
					<textarea bind:value={settings.receipt_footer} rows="2" placeholder="Thank you for shopping with us!" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 text-sm resize-none"></textarea>
				</div>
			</div>

			<!-- Storefront Branding -->
			<div class="bg-white rounded-xl border p-5 space-y-4">
				<h2 class="font-semibold text-gray-900 flex items-center gap-2"><Sparkles class="h-4 w-4 text-indigo-500" /> Storefront Branding</h2>
				<p class="text-xs text-gray-500">Customize how your store looks to customers</p>
				
				<div class="space-y-4">
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">Logo URL</label>
						<input type="text" bind:value={settings.logo_url} placeholder="https://..." class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 text-sm" />
					</div>
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">Company Slogan</label>
						<input type="text" bind:value={settings.slogan} placeholder="e.g. Quality health, delivered." class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 text-sm" />
					</div>
					<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
						<div>
							<label class="block text-sm font-medium text-gray-700 mb-1">Hero Title</label>
							<input type="text" bind:value={settings.hero_title} placeholder="Discover Medics, Delivered to You" class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 text-sm" />
						</div>
						<div>
							<label class="block text-sm font-medium text-gray-700 mb-1">Hero Subtitle</label>
							<input type="text" bind:value={settings.hero_subtitle} placeholder="Curated healthcare products — quality you can trust, prices you can afford." class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 text-sm" />
						</div>
					</div>
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">About Us (Footer)</label>
						<textarea bind:value={settings.about_us} rows="3" placeholder="Connecting patients with the worlds leading medical specialists. Quality healthcare, just a click away." class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 text-sm resize-none"></textarea>
					</div>
				</div>
			</div>

			<!-- Partnerships -->
			<div class="bg-white rounded-xl border p-5">
				<h2 class="font-semibold text-gray-900 flex items-center gap-2 mb-1">
					<Stethoscope class="h-4 w-4 text-indigo-500" /> Medic Partnerships
				</h2>
				<p class="text-sm text-gray-500 mb-4">Allow healthcare providers to partner with your pharmacy. Enabling this shows the <strong>Medic Partners</strong> module in the sidebar.</p>
				<label class="flex items-center justify-between cursor-pointer select-none">
					<div>
						<p class="text-sm font-medium text-gray-800">Allow Doctor Partnerships</p>
						<p class="text-xs text-gray-500 mt-0.5">Doctors you invite can accept requests and appear on your storefront.</p>
					</div>
					<button
						type="button"
						role="switch"
						aria-checked={allowPartnership}
						onclick={() => allowPartnership = !allowPartnership}
						class="relative inline-flex h-6 w-11 flex-shrink-0 rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 {allowPartnership ? 'bg-indigo-600' : 'bg-gray-200'}"
					>
						<span
							class="pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out {allowPartnership ? 'translate-x-5' : 'translate-x-0'}"
						></span>
					</button>
				</label>
			</div>

			<button type="submit" disabled={saving} class="w-full flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-4 py-3 rounded-xl transition-colors disabled:opacity-50">
				<Save class="h-4 w-4" />{saving ? 'Saving...' : 'Save Settings'}
			</button>
		</form>
	{/if}
</div>
