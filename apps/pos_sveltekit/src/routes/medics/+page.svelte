<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import {
		Stethoscope, Plus, Search, ArrowLeft, CheckCircle,
		UserCheck, Clock, AlertCircle, Star, ShieldCheck, Users
	} from 'lucide-svelte';

	// ── State ─────────────────────────────────────────────────────────────────
	let tenantId       = $state('');
	let loading        = $state(true);
	let view           = $state<'list' | 'picker'>('list'); // slide panel state

	// Alias list
	let aliases        = $state<any[]>([]);
	let aliasError     = $state('');

	// Provider picker
	let providers      = $state<any[]>([]);
	let providerSearch = $state('');
	let selected       = $state<Set<string>>(new Set());
	let providerLoading= $state(false);
	let inviting       = $state(false);
	let inviteSuccess  = $state('');
	let inviteError    = $state('');

	let filteredProviders = $derived(
		providerSearch
			? providers.filter(p =>
				p.full_name?.toLowerCase().includes(providerSearch.toLowerCase()) ||
				p.specialization?.toLowerCase().includes(providerSearch.toLowerCase()))
			: providers
	);

	// ── Load ──────────────────────────────────────────────────────────────────
	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) { loading = false; return; }
		const { data: user } = await supabase.from('users').select('tenant_id').eq('id', session.user.id).single();
		if (user?.tenant_id) {
			tenantId = user.tenant_id;
			await loadAliases();
		}
		loading = false;
	});

	async function loadAliases() {
		const { data, error } = await supabase
			.from('doctor_aliases_with_details')
			.select('*')
			.eq('tenant_partner', tenantId)
			.order('alias_id', { ascending: false });
		if (error) { aliasError = error.message; return; }
		aliases = data ?? [];
	}

	async function openPicker() {
		providerLoading = true;
		view = 'picker';
		selected = new Set();
		providerSearch = '';
		inviteError = '';
		inviteSuccess = '';

		// Fetch providers not already aliased for this tenant
		const existingIds = aliases.map(a => a.doctor_id);
		const { data, error } = await supabase
			.from('healthcare_providers')
			.select('id, full_name, specialization, sub_specialty, profile_photo_url, average_rating, is_verified')
			.order('full_name');
		if (!error) {
			providers = (data ?? []).filter(p => !existingIds.includes(p.id));
		}
		providerLoading = false;
	}

	function toggleSelect(id: string) {
		const next = new Set(selected);
		next.has(id) ? next.delete(id) : next.add(id);
		selected = next;
	}

	async function sendInvites() {
		if (selected.size === 0) return;
		inviting = true; inviteError = ''; inviteSuccess = '';
		try {
			const rows = [...selected].map(doctorId => {
				const provider = providers.find(p => p.id === doctorId);
				return {
					doctor_id: doctorId,
					alias: provider?.full_name ?? 'Doctor',
					tenant_partner: tenantId,
					accepted: false,
					is_active: true
				};
			});
			const { error } = await supabase.from('doctor_aliases').insert(rows);
			if (error) throw error;
			inviteSuccess = `${rows.length} invitation${rows.length > 1 ? 's' : ''} sent!`;
			await loadAliases();
			setTimeout(() => {
				view = 'list';
				inviteSuccess = '';
			}, 1500);
		} catch (err: any) {
			inviteError = err.message || 'Failed to send invitations';
		} finally { inviting = false; }
	}

	function initials(name: string) {
		return (name ?? '?').split(' ').slice(0, 2).map((w: string) => w[0].toUpperCase()).join('');
	}

	function avatarColor(name: string) {
		const colors = ['bg-indigo-100 text-indigo-700','bg-teal-100 text-teal-700','bg-rose-100 text-rose-700','bg-amber-100 text-amber-700','bg-violet-100 text-violet-700','bg-sky-100 text-sky-700'];
		return colors[(name?.charCodeAt(0) ?? 0) % colors.length];
	}
</script>

<svelte:head><title>Medic Partners – Kemani POS</title></svelte:head>

<div class="mp-root">

	<!-- ── Panel A: Alias List ──────────────────────────────────────────────── -->
	<div class="mp-panel {view === 'picker' ? 'mp-panel--hidden' : ''}">

		<!-- Header -->
		<div class="mp-header">
			<div>
				<h1 class="mp-title"><Stethoscope class="h-5 w-5 text-indigo-500" /> Medic Partners</h1>
				<p class="mp-sub">Healthcare providers partnered with your pharmacy</p>
			</div>
			<button onclick={openPicker} class="mp-add-btn">
				<Plus class="h-4 w-4" /> Add Doctor
			</button>
		</div>

		{#if loading}
			<div class="mp-loader"><div class="mp-spinner"></div></div>
		{:else if aliasError}
			<div class="mp-alert-err"><AlertCircle class="h-4 w-4" /> {aliasError}</div>
		{:else if aliases.length === 0}
			<!-- Empty state -->
			<div class="mp-empty">
				<div class="mp-empty-icon"><Users class="h-10 w-10 text-indigo-300" /></div>
				<h3 class="mp-empty-title">No partners yet</h3>
				<p class="mp-empty-sub">Invite healthcare providers to partner with your pharmacy. They'll appear on your storefront once they accept.</p>
				<button onclick={openPicker} class="mp-add-btn mt-4">
					<Plus class="h-4 w-4" /> Invite your first partner
				</button>
			</div>
		{:else}
			<!-- Alias list -->
			<div class="mp-list">
				{#each aliases as alias}
					<div class="mp-card">
						<!-- Avatar -->
						{#if alias.profile_photo_url}
							<img src={alias.profile_photo_url} alt={alias.actual_name} class="mp-avatar-img" />
						{:else}
							<div class="mp-avatar {avatarColor(alias.actual_name ?? '')}">
								{initials(alias.actual_name ?? alias.display_name ?? '?')}
							</div>
						{/if}
						<!-- Info -->
						<div class="mp-card-body">
							<div class="mp-card-name-row">
								<span class="mp-card-name">{alias.display_name}</span>
								{#if alias.is_verified}
									<ShieldCheck class="h-3.5 w-3.5 text-indigo-500" />
								{/if}
							</div>
							<p class="mp-card-spec">{alias.specialization ?? 'General'}{alias.sub_specialty ? ` · ${alias.sub_specialty}` : ''}</p>
							{#if alias.average_rating}
								<div class="mp-rating">
									<Star class="h-3 w-3 text-amber-400 fill-amber-400" />
									<span>{alias.average_rating.toFixed(1)}</span>
								</div>
							{/if}
						</div>
						<!-- Status badge -->
						<div class="flex-shrink-0">
							{#if alias.accepted}
								<span class="mp-badge mp-badge--accepted"><CheckCircle class="h-3 w-3" /> Accepted</span>
							{:else}
								<span class="mp-badge mp-badge--pending"><Clock class="h-3 w-3" /> Pending</span>
							{/if}
						</div>
					</div>
				{/each}
			</div>
		{/if}
	</div>

	<!-- ── Panel B: Provider Picker ────────────────────────────────────────── -->
	<div class="mp-panel mp-panel--picker {view === 'picker' ? 'mp-panel--visible' : ''}">

		<!-- Header -->
		<div class="mp-header">
			<div class="flex items-center gap-3">
				<button onclick={() => view = 'list'} class="mp-back-btn"><ArrowLeft class="h-4 w-4" /></button>
				<div>
					<h1 class="mp-title" style="font-size:1.1rem">Select Doctors to Invite</h1>
					<p class="mp-sub">{selected.size} doctor{selected.size !== 1 ? 's' : ''} selected</p>
				</div>
			</div>
			{#if selected.size > 0}
				<button onclick={sendInvites} disabled={inviting} class="mp-add-btn">
					{#if inviting}
						<div class="mp-btn-spinner"></div> Sending…
					{:else}
						<UserCheck class="h-4 w-4" /> Invite ({selected.size})
					{/if}
				</button>
			{/if}
		</div>

		<!-- Feedback -->
		{#if inviteSuccess}
			<div class="mp-alert-ok"><CheckCircle class="h-4 w-4" /> {inviteSuccess}</div>
		{/if}
		{#if inviteError}
			<div class="mp-alert-err"><AlertCircle class="h-4 w-4" /> {inviteError}</div>
		{/if}

		<!-- Search -->
		<div class="mp-search-wrap">
			<Search class="mp-search-icon" />
			<input
				bind:value={providerSearch}
				placeholder="Search by name or specialization…"
				class="mp-search-input"
			/>
		</div>

		<!-- Provider list -->
		{#if providerLoading}
			<div class="mp-loader"><div class="mp-spinner"></div></div>
		{:else if filteredProviders.length === 0}
			<div class="mp-empty">
				<p class="mp-empty-sub">
					{providers.length === 0 ? 'All available providers have already been invited.' : 'No providers match your search.'}
				</p>
			</div>
		{:else}
			<div class="mp-list">
				{#each filteredProviders as provider}
					{@const isChecked = selected.has(provider.id)}
					<button
						onclick={() => toggleSelect(provider.id)}
						class="mp-card mp-card--selectable {isChecked ? 'mp-card--selected' : ''}"
					>
						<!-- Checkbox -->
						<div class="mp-checkbox {isChecked ? 'mp-checkbox--checked' : ''}">
							{#if isChecked}<CheckCircle class="h-4 w-4 text-white" />{/if}
						</div>
						<!-- Avatar -->
						{#if provider.profile_photo_url}
							<img src={provider.profile_photo_url} alt={provider.full_name} class="mp-avatar-img" />
						{:else}
							<div class="mp-avatar {avatarColor(provider.full_name ?? '')}">
								{initials(provider.full_name ?? '?')}
							</div>
						{/if}
						<!-- Info -->
						<div class="mp-card-body">
							<div class="mp-card-name-row">
								<span class="mp-card-name">{provider.full_name}</span>
								{#if provider.is_verified}
									<ShieldCheck class="h-3.5 w-3.5 text-indigo-500" />
								{/if}
							</div>
							<p class="mp-card-spec">{provider.specialization ?? 'General'}</p>
							{#if provider.average_rating}
								<div class="mp-rating">
									<Star class="h-3 w-3 text-amber-400 fill-amber-400" />
									<span>{provider.average_rating.toFixed(1)}</span>
								</div>
							{/if}
						</div>
					</button>
				{/each}
			</div>
		{/if}

		<!-- Sticky invite footer -->
		{#if selected.size > 0}
			<div class="mp-footer">
				<button onclick={sendInvites} disabled={inviting} class="mp-footer-btn">
					{#if inviting}
						<div class="mp-btn-spinner"></div> Sending invitations…
					{:else}
						<UserCheck class="h-4 w-4" /> Send {selected.size} Invitation{selected.size !== 1 ? 's' : ''}
					{/if}
				</button>
			</div>
		{/if}
	</div>
</div>

<style>
/* Root — clip overflow for slide transition */
.mp-root {
	position: relative; overflow: hidden;
	min-height: calc(100vh - 0px);
	background: #f9fafb;
	display: flex; flex-direction: row;
}

/* Panels */
.mp-panel {
	flex: 1; display: flex; flex-direction: column;
	min-height: 100%;
	transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.3s ease;
	position: absolute; inset: 0; overflow-y: auto;
}
.mp-panel--picker {
	transform: translateX(100%);
	background: #f9fafb;
}
.mp-panel--visible  { transform: translateX(0); }
.mp-panel--hidden   { transform: translateX(-30%); opacity: 0; pointer-events: none; }

/* Header */
.mp-header {
	display: flex; align-items: center; justify-content: space-between;
	padding: 1.5rem 1.5rem 1rem; gap: 1rem; flex-wrap: wrap;
	border-bottom: 1px solid #e5e7eb; background: #fff;
	position: sticky; top: 0; z-index: 10;
}
.mp-title {
	font-size: 1.25rem; font-weight: 800; color: #111827;
	display: flex; align-items: center; gap: 0.5rem;
}
.mp-sub { font-size: 0.8125rem; color: #6b7280; margin-top: 0.1rem; }

/* Buttons */
.mp-add-btn {
	display: flex; align-items: center; gap: 0.4rem;
	background: #4f46e5; color: #fff; border: none; cursor: pointer;
	padding: 0.55rem 1.1rem; border-radius: 0.75rem;
	font-size: 0.875rem; font-weight: 700;
	transition: background 0.15s, transform 0.1s;
	box-shadow: 0 2px 6px rgba(79,70,229,0.3);
}
.mp-add-btn:hover:not(:disabled) { background: #4338ca; transform: translateY(-1px); }
.mp-add-btn:disabled { opacity: 0.6; cursor: not-allowed; }
.mp-back-btn {
	width: 34px; height: 34px; border-radius: 50%;
	border: 1px solid #e5e7eb; background: #f9fafb; color: #374151;
	display: flex; align-items: center; justify-content: center;
	cursor: pointer; transition: background 0.15s;
}
.mp-back-btn:hover { background: #eef2ff; border-color: #c7d2fe; color: #4f46e5; }

/* Search */
.mp-search-wrap {
	position: relative; padding: 0.75rem 1.25rem;
	border-bottom: 1px solid #f3f4f6; background: #fff;
}
.mp-search-icon {
	position: absolute; left: 2rem; top: 50%;
	transform: translateY(-50%); width: 14px; height: 14px; color: #9ca3af;
}
.mp-search-input {
	width: 100%; padding: 0.55rem 0.75rem 0.55rem 2.25rem;
	border: 1px solid #e5e7eb; border-radius: 0.75rem;
	font-size: 0.875rem; background: #f9fafb; outline: none; color: #111827;
	transition: border-color 0.15s;
}
.mp-search-input:focus { border-color: #6366f1; background: #fff; }

/* List */
.mp-list {
	padding: 1rem 1.25rem;
	display: flex; flex-direction: column; gap: 0.65rem;
}

/* Card */
.mp-card {
	display: flex; align-items: center; gap: 0.85rem;
	background: #fff; border: 1px solid #e5e7eb;
	border-radius: 1rem; padding: 0.85rem 1rem;
	transition: box-shadow 0.15s, border-color 0.15s;
}
.mp-card--selectable {
	cursor: pointer; width: 100%; text-align: left; border: none;
	background: #fff; border: 1px solid #e5e7eb;
	border-radius: 1rem; padding: 0.85rem 1rem;
	display: flex; align-items: center; gap: 0.85rem;
	transition: box-shadow 0.15s, border-color 0.15s, background 0.12s;
}
.mp-card--selectable:hover { box-shadow: 0 2px 10px rgba(0,0,0,0.07); border-color: #c7d2fe; }
.mp-card--selected { border-color: #6366f1; background: #f5f5ff; box-shadow: 0 0 0 2px #e0e7ff; }

/* Checkbox */
.mp-checkbox {
	width: 22px; height: 22px; border-radius: 6px; border: 2px solid #d1d5db;
	flex-shrink: 0; display: flex; align-items: center; justify-content: center;
	transition: background 0.12s, border-color 0.12s;
}
.mp-checkbox--checked { background: #4f46e5; border-color: #4f46e5; }

/* Avatar */
.mp-avatar-img { width: 44px; height: 44px; border-radius: 50%; object-fit: cover; flex-shrink: 0; border: 2px solid #e5e7eb; }
.mp-avatar {
	width: 44px; height: 44px; border-radius: 50%; flex-shrink: 0;
	display: flex; align-items: center; justify-content: center;
	font-size: 0.875rem; font-weight: 800;
}

/* Card body */
.mp-card-body { flex: 1; min-width: 0; }
.mp-card-name-row { display: flex; align-items: center; gap: 0.3rem; }
.mp-card-name { font-size: 0.9375rem; font-weight: 700; color: #111827; }
.mp-card-spec  { font-size: 0.75rem; color: #6b7280; margin-top: 0.1rem; }
.mp-rating { display: flex; align-items: center; gap: 0.2rem; font-size: 0.7rem; color: #92400e; margin-top: 0.2rem; }

/* Status badges */
.mp-badge {
	display: inline-flex; align-items: center; gap: 0.25rem;
	padding: 0.25rem 0.6rem; border-radius: 999px;
	font-size: 0.7rem; font-weight: 700;
}
.mp-badge--accepted { background: #dcfce7; color: #15803d; }
.mp-badge--pending  { background: #fef9c3; color: #a16207; }

/* Alerts */
.mp-alert-ok  { display: flex; align-items: center; gap: 0.4rem; margin: 0.5rem 1.25rem; padding: 0.6rem 0.9rem; background: #dcfce7; color: #15803d; border-radius: 0.6rem; font-size: 0.8125rem; font-weight: 600; }
.mp-alert-err { display: flex; align-items: center; gap: 0.4rem; margin: 0.5rem 1.25rem; padding: 0.6rem 0.9rem; background: #fee2e2; color: #dc2626; border-radius: 0.6rem; font-size: 0.8125rem; }

/* Empty state */
.mp-empty {
	flex: 1; display: flex; flex-direction: column;
	align-items: center; justify-content: center;
	text-align: center; padding: 3rem 2rem;
}
.mp-empty-icon { width: 72px; height: 72px; border-radius: 50%; background: #eef2ff; display: flex; align-items: center; justify-content: center; margin: 0 auto 1rem; }
.mp-empty-title { font-size: 1.125rem; font-weight: 800; color: #111827; }
.mp-empty-sub   { font-size: 0.875rem; color: #6b7280; margin-top: 0.4rem; max-width: 340px; }

/* Loader */
.mp-loader { display: flex; justify-content: center; padding: 3rem; }
.mp-spinner { width: 36px; height: 36px; border: 3px solid #e5e7eb; border-top-color: #6366f1; border-radius: 50%; animation: mp-spin 0.7s linear infinite; }
.mp-btn-spinner { width: 14px; height: 14px; border: 2px solid rgba(255,255,255,0.4); border-top-color: #fff; border-radius: 50%; animation: mp-spin 0.6s linear infinite; }
@keyframes mp-spin { to { transform: rotate(360deg); } }

/* Sticky footer */
.mp-footer {
	position: sticky; bottom: 0; padding: 1rem 1.25rem;
	background: rgba(255,255,255,0.95); backdrop-filter: blur(6px);
	border-top: 1px solid #e5e7eb;
}
.mp-footer-btn {
	width: 100%; display: flex; align-items: center; justify-content: center; gap: 0.5rem;
	background: #4f46e5; color: #fff; border: none; cursor: pointer;
	padding: 0.85rem; border-radius: 0.875rem;
	font-size: 0.9375rem; font-weight: 700;
	box-shadow: 0 3px 10px rgba(79,70,229,0.35);
	transition: background 0.15s;
}
.mp-footer-btn:hover:not(:disabled) { background: #4338ca; }
.mp-footer-btn:disabled { opacity: 0.6; cursor: not-allowed; }

@media (min-width: 768px) {
	.mp-list { padding: 1.25rem 2rem; }
	.mp-header { padding: 1.5rem 2rem 1rem; }
	.mp-search-wrap { padding: 0.75rem 2rem; }
	.mp-search-icon { left: 2.75rem; }
	.mp-list { max-width: 680px; margin: 0 auto; width: 100%; }
	.mp-empty { padding: 4rem 2rem; }
}
</style>
