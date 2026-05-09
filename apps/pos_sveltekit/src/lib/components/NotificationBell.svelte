<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { 
		Bell, X, Package, ShoppingCart, 
		AlertCircle, Clock, ClipboardList,
		MessageSquare, Check
	} from 'lucide-svelte';
	import { fly } from 'svelte/transition';

	let { tenantId, align = 'right' } = $props<{ tenantId: string, align?: 'left'|'right' }>();

	let notifications = $state<any[]>([]);
	let unreadCount = $state(0);
	let isOpen = $state(false);
	let loading = $state(true);
	let realtimeChannel: any = null;

	async function fetchNotifications() {
		if (!tenantId) return;
		loading = true;
		const { data, error } = await supabase
			.from('staff_notifications')
			.select('*')
			.eq('tenant_id', tenantId)
			.order('created_at', { ascending: false })
			.limit(10);
		
		if (!error) {
			notifications = data || [];
			unreadCount = notifications.filter(n => !n.is_read).length;
		}
		loading = false;
	}

	async function markAsRead(id: string) {
		const { error } = await supabase
			.from('staff_notifications')
			.update({ is_read: true })
			.eq('id', id);
		
		if (!error) {
			notifications = notifications.map(n => n.id === id ? { ...n, is_read: true } : n);
			unreadCount = Math.max(0, unreadCount - 1);
		}
	}

	async function markAllAsRead() {
		const { error } = await supabase
			.from('staff_notifications')
			.update({ is_read: true })
			.eq('tenant_id', tenantId)
			.eq('is_read', false);
		
		if (!error) {
			notifications = notifications.map(n => ({ ...n, is_read: true }));
			unreadCount = 0;
		}
	}

	onMount(() => {
		fetchNotifications();

		// Realtime listener
		realtimeChannel = supabase.channel(`staff-notifications-${tenantId}`)
			.on('postgres_changes', {
				event: 'INSERT',
				schema: 'public',
				table: 'staff_notifications',
				filter: `tenant_id=eq.${tenantId}`
			}, (payload) => {
				notifications = [payload.new, ...notifications.slice(0, 9)];
				unreadCount++;
			})
			.subscribe();
	});

	onDestroy(() => {
		if (realtimeChannel) {
			supabase.removeChannel(realtimeChannel);
		}
	});

	function getCategoryStyle(category: string) {
		switch (category) {
			case 'inventory': return { icon: Package, color: 'text-amber-600', bg: 'bg-amber-50' };
			case 'sale': return { icon: ShoppingCart, color: 'text-emerald-600', bg: 'bg-emerald-50' };
			case 'task': return { icon: ClipboardList, color: 'text-blue-600', bg: 'bg-blue-50' };
			case 'chat': return { icon: MessageSquare, color: 'text-indigo-600', bg: 'bg-indigo-50' };
			case 'urgent': return { icon: AlertCircle, color: 'text-rose-600', bg: 'bg-rose-50' };
			default: return { icon: Bell, color: 'text-gray-600', bg: 'bg-gray-50' };
		}
	}
</script>

<div class="relative">
	<button 
		onclick={() => isOpen = !isOpen}
		class="relative p-2 rounded-xl text-gray-600 hover:text-indigo-600 hover:bg-indigo-50 transition-all duration-200" 
		title="Notifications"
	>
		<Bell class="h-5 w-5" />
		{#if unreadCount > 0}
			<span class="absolute top-1.5 right-1.5 flex h-4 w-4 items-center justify-center rounded-full bg-rose-500 text-[9px] font-black text-white shadow-sm ring-2 ring-white animate-bounce">
				{unreadCount > 9 ? '9+' : unreadCount}
			</span>
		{/if}
	</button>

	{#if isOpen}
		<div 
			class="fixed inset-0 z-50 bg-black/5 lg:bg-transparent"
			onclick={() => isOpen = false}
		></div>

		<div 
			transition:fly={{ y: 10, duration: 200 }}
			class="absolute {align === 'right' ? 'right-0' : 'left-0'} mt-2 w-80 sm:w-96 bg-white rounded-2xl shadow-2xl border border-gray-100 z-[60] overflow-hidden"
		>
			<div class="p-4 border-b flex items-center justify-between bg-gray-50/50">
				<h3 class="font-bold text-gray-900 text-sm flex items-center gap-2">
					<Bell class="h-4 w-4 text-indigo-600" />
					Staff Alerts
				</h3>
				<button onclick={() => isOpen = false} class="text-gray-400 hover:text-gray-600">
					<X class="h-4 w-4" />
				</button>
			</div>

			<div class="max-h-[400px] overflow-y-auto">
				{#if loading && notifications.length === 0}
					<div class="p-8 text-center text-gray-400 italic">
						<div class="animate-spin h-5 w-5 border-b-2 border-indigo-600 mx-auto mb-2"></div>
						Syncing notifications...
					</div>
				{:else if notifications.length === 0}
					<div class="p-12 text-center">
						<div class="h-16 w-16 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-4 text-gray-300">
							<Check class="h-8 w-8" />
						</div>
						<p class="text-sm font-bold text-gray-900">All Clear!</p>
						<p class="text-xs text-gray-500 mt-1">No pending alerts for your tenant.</p>
					</div>
				{:else}
					<div class="divide-y divide-gray-50">
						{#each notifications as n}
							{@const style = getCategoryStyle(n.category || n.type)}
							<div class="relative group">
								<button 
									onclick={() => {
										markAsRead(n.id);
										if (n.action_url) window.location.href = n.action_url;
									}}
									class="w-full p-4 text-left hover:bg-gray-50 transition-colors flex gap-4 {n.is_read ? 'opacity-60' : ''}"
								>
									<div class="h-10 w-10 shrink-0 rounded-xl {style.bg} {style.color} flex items-center justify-center border border-current/10">
										<style.icon class="h-5 w-5" />
									</div>
									<div class="flex-1 min-w-0">
										<div class="flex items-center justify-between gap-2">
											<p class="text-sm font-bold text-gray-900 truncate">{n.title}</p>
											<span class="text-[10px] text-gray-400 font-medium whitespace-nowrap bg-gray-100 px-1.5 py-0.5 rounded">
												{new Date(n.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
											</span>
										</div>
										<p class="text-xs text-gray-500 mt-0.5 line-clamp-2 leading-relaxed">{n.body || n.message}</p>
									</div>
									{#if !n.is_read}
										<div class="h-2 w-2 bg-indigo-600 rounded-full mt-1.5 shrink-0 shadow-[0_0_8px_rgba(79,70,229,0.5)]"></div>
									{/if}
								</button>
							</div>
						{/each}
					</div>
				{/if}
			</div>

			{#if notifications.length > 0}
				<div class="p-3 border-t bg-gray-50/50 text-center">
					<button 
						onclick={markAllAsRead}
						class="text-[10px] font-black text-indigo-600 hover:text-indigo-700 uppercase tracking-widest"
					>
						Mark all as read
					</button>
				</div>
			{/if}
		</div>
	{/if}
</div>
