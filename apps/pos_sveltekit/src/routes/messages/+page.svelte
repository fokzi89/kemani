<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { page } from '$app/stores';
	import { supabase } from '$lib/supabase';
	import {
		ArrowLeft, Building2, ChevronDown, ChevronRight, Image, FileAudio, FileText,
		MessageSquare, Mic, Package, Paperclip, RefreshCw, Search, Send,
		ShoppingCart, Smile, Stethoscope, UserRound, Video, X
	} from 'lucide-svelte';

	// ── Real Data State ───────────────────────────────────────────────────────
	let branches: any[] = $state([]);
	let conversations: any[] = $state([]);
	let liveMessages: any[] = $state([]);
	let products: any[] = $state([]);
	let doctors: any[] = $state([]);
	
	let staffId: string = $state('');
	let tenantId: string = $state('');
	let currentBranchId: string = $state('');
	
	let loading: boolean = $state(true);
	let messageSubscription: any = null;

	// ── UI state ───────────────────────────────────────────────────────────────
	let selectedBranchId: string = $state('all');
	let statusFilter: 'all'|'active'|'closed' = $state('all');
	let searchQuery: string = $state('');
	let activeConvId: string | null = $state(null);
	let messageText: string = $state('');
	let sending: boolean = $state(false);

	// Mobile: 'list' | 'chat'
	let mobileView: 'list'|'chat' = $state('list');

	let messagesEndEl: HTMLElement;

	// ── Rich composer state ────────────────────────────────────────────────────
	let showAttachTray: boolean = $state(false);
	let showEmojiPicker: boolean = $state(false);
	let emojiCategory: number = $state(0);
	let isRecording: boolean = $state(false);
	let recordSeconds: number = $state(0);
	let recordInterval: ReturnType<typeof setInterval> | null = null;
	let pendingFiles: Array<{ type: 'image'|'audio'|'pdf'|'video', name: string, url: string }> = $state([]);
	let msgInputEl: HTMLTextAreaElement;

	const EMOJI_CATEGORIES = [
		{ label: '😊', name: 'Smileys', emojis: ['😀','😃','😄','😁','😆','😅','🤣','😂','🙂','🙃','😉','😊','😇','🥰','😍','🤩','😘','😗','😚','😙','🥲','😋','😛','😜','🤪','😝','🤑','🤗','🤭','🤫','🤔','🤐','🤨','😐','😑','😶','😶‍🌫️','😏','😒','🙄','😬','😮‍💨','🤥','😌','😔','😪','🤤','😴','😷','🤒','🤕','🤢','🤮','🤧','🥵','🥶','🥴','😵','😵‍💫','🤯','🤠','🥳','🥸','😎','🤓','🧐','😕','😟','🙁','☹️','😮','😯','😲','😳','🥺','😦','😧','😨','😰','😥','😢','😭','😱','😖','😣','😞','😓','😩','😫','🥱'] },
		{ label: '👋', name: 'Hands',   emojis: ['👋','🤚','🖐️','✋','🖖','👌','🤌','🤏','✌️','🤞','🤟','🤘','🤙','👈','👉','👆','🖕','👇','☝️','👍','👎','✊','👊','🤛','🤜','👏','🙌','👐','🤲','🤝','🙏','✍️','💅','🤳','💪','🦾','🦿','🦵','🦶','👂','🦻','👃','🫀','🫁','🧠','🦷','🦴','👀','👁️','👅','👄','🫦'] },
		{ label: '❤️', name: 'Hearts',   emojis: ['❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💔','❤️‍🔥','❤️‍🩹','❣️','💕','💞','💓','💗','💖','💘','💝','💟','☮️','✝️','☪️','🕉️','✡️','🔯','🕎','☯️','🛐','⛎','♈','♉','♊','♋','♌','♍','♎','♏','♐','♑','♒','♓'] },
		{ label: '🍕', name: 'Food',     emojis: ['🍎','🍊','🍋','🍇','🍓','🫐','🍈','🍒','🍑','🥭','🍍','🥥','🥝','🍅','🥑','🍆','🥦','🥬','🥒','🌶️','🫑','🧄','🧅','🥔','🌽','🍠','🥐','🥖','🍞','🥨','🥯','🧀','🥚','🍳','🧈','🥞','🧇','🥓','🥩','🍗','🍖','🦴','🌭','🍔','🍟','🍕','🫓','🥪','🥙','🧆','🌮','🌯','🫔','🥗','🥘','🫕','🍝','🍜','🍲','🍛','🍣','🍱','🥟','🦪','🍤','🍙','🍚','🍘','🍥','🥮','🍢','🧁','🍰','🎂','🍮','🍭','🍬','🍫','🍿','🍩','🍪','☕','🫖','🍵','🧃','🥤','🧋','🍺','🍻','🥂','🍷','🥃','🍸','🍹','🧉','🍾'] },
		{ label: '⚽', name: 'Activity', emojis: ['⚽','🏀','🏈','⚾','🥎','🎾','🏐','🏉','🥏','🎱','🏓','🏸','🏒','🏑','🥍','🏏','🪃','🥅','⛳','🪁','🛝','🏹','🎣','🤿','🥊','🥋','🎽','🛹','🛼','🛷','⛸️','🥌','🎿','⛷️','🏂','🪂','🏋️','🤼','🤸','⛹️','🤺','🏇','🧘','🏄','🏊','🤽','🚣','🧗','🚴','🏆','🥇','🥈','🥉','🏅','🎖️','🏵️','🎗️','🎟️','🎫','🎪','🤹','🎨','🖼️','🎭','🎬','🎤','🎧','🎼','🎹','🪘','🥁','🎷','🎺','🎸','🪕','🎻','🪗','🎲','♟️','🎯','🎳','🎮','🎰','🧩'] },
		{ label: '🚀', name: 'Travel',   emojis: ['🚗','🚕','🚙','🚌','🚎','🏎️','🚓','🚑','🚒','🚐','🛻','🚚','🚛','🚜','🏍️','🛵','🛺','🚲','🛴','🛹','🛼','🚏','🛣️','🛤️','⛽','🛞','🚨','🛑','🚦','🚥','🛟','⚓','🪝','⛵','🚤','🛥️','🛳️','🚢','✈️','🛩️','🛫','🛬','💺','🪂','🚁','🚟','🚠','🚡','🛰️','🚀','🛸','🚃','🚄','🚅','🚆','🚇','🚈','🚉','🚊','🚝','🚞','🚋','🚌','🚍','🚎','🏔️','⛰️','🌋','🗻','🏕️','🏖️','🏜️','🏝️','🏟️','🏛️','🏗️','🧱','🛖','🏘️','🏚️','🏠','🏡','🏢','🏣','🏤','🏥','🏦','🏨','🏩','🏪','🏫','🏬','🏭','🗼','🗽','⛪','🕌','🛕','🕍','⛩️','🕋','⛲','⛺','🌁','🌃','🏙️','🌄','🌅','🌆','🌇','🌉','🌌','🌠','🎇','🎆'] },
		{ label: '💡', name: 'Objects',  emojis: ['💊','💉','🩺','🩻','🩹','🩼','🩽','🧬','🔬','🔭','📡','🛒','🚪','🛏️','🛋️','🪑','🚽','🪠','🚿','🛁','🪤','🪣','🧴','🧷','🧹','🧺','🧻','🧼','🫧','🪥','🧽','🪣','🪒','💈','🪮','🛍️','👜','👝','🎒','🧳','👓','🕶️','🥽','🌂','☂️','🧵','🧶','🪡','💎','📿','💍','👑','🎩','🎓','🧢','⛑️','📱','💻','⌨️','🖥️','🖨️','🖱️','💾','💿','📀','📸','📷','📹','🎥','📺','☎️','📞','📟','📠','📷','🔋','🔌','💡','🔦','🕯️','🧯','🗑️','💰','💵','💴','💶','💷','💸','💳','🏷️','🔑','🗝️','🔐','🔏','🔓','🔒','🗡️','⚔️','🛡️','🪚','🔧','🪛','🔩','⚙️','🗜️','📏','📐','✂️','🗃️','🗂️','📋','📁','📂','🗒️','🗓️','📅','📆','📇','📈','📉','📊','📌','📍','📎','🖇️','📏'] },
		{ label: '💬', name: 'Symbols',  emojis: ['✅','❌','❎','🔰','⚠️','🚫','💯','🔔','🔕','🔇','🔈','🔉','🔊','📢','📣','🔔','🔕','💤','🔅','🔆','📶','📳','📴','📵','📱','☎️','🔁','🔂','▶️','⏩','⏭️','⏯️','⏪','⏮️','🔀','🔃','🎵','🎶','➕','➖','➗','✖️','💲','💱','❓','❔','❕','❗','〰️','💠','🔷','🔶','🔹','🔸','🔺','🔻','🔲','🔳','⬛','⬜','◼️','◻️','◾','◽','▪️','▫️','🟥','🟧','🟨','🟩','🟦','🟪','⭕','🔴','🟠','🟡','🟢','🔵','🟣','⚫','⚪','🏁','🚩','🎌','🏴','🏳️'] },
	];

	function insertEmoji(emoji: string) {
		if (!msgInputEl) { messageText += emoji; return; }
		const start = msgInputEl.selectionStart ?? messageText.length;
		const end   = msgInputEl.selectionEnd   ?? messageText.length;
		messageText = messageText.slice(0, start) + emoji + messageText.slice(end);
		// Restore cursor after emoji
		setTimeout(() => {
			msgInputEl.focus();
			msgInputEl.setSelectionRange(start + emoji.length, start + emoji.length);
		}, 0);
	}

	// Lifecycle
	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		
		staffId = session.user.id;
		
		// Load user context (tenant/branch)
		const { data: userData } = await supabase.from('users')
			.select('tenant_id, branch_id, canCreatePrescription, canApplyDiscount, canReferToDoctor')
			.eq('id', staffId)
			.single();
			
		if (userData) {
			tenantId = userData.tenant_id;
			currentBranchId = userData.branch_id;
			canPrescribe = userData.canCreatePrescription;
			canApplyDiscount = userData.canApplyDiscount;
			canReferToDoctor = userData.canReferToDoctor;
		}

		if (tenantId) {
			await Promise.all([
				loadBranches(),
				loadConversations(),
				loadProducts(),
				loadDoctors()
			]);
		}
		
		loading = false;
	});

	onDestroy(() => {
		if (messageSubscription) messageSubscription.unsubscribe();
	});

	async function loadBranches() {
		if (!tenantId) return;
		const { data } = await supabase.from('branches').select('id, name').eq('tenant_id', tenantId);
		branches = data || [];
	}

	async function loadConversations() {
		if (!tenantId) return;
		const { data } = await supabase.from('chat_conversations')
			.select('*, branches(name)')
			.eq('tenant_id', tenantId)
			.order('started_at', { ascending: false });
		
		conversations = (data || []).map(c => ({
			...c,
			customer_name: c.customer_name || 'Anonymous',
			branch_name: c.branches?.name || 'Unknown'
		}));
	}

	async function loadProducts() {
		if (!tenantId) return;
		// Use branch_inventory which has everything pre-joined for POS
		const { data } = await supabase.from('branch_inventory')
			.select('id, product_id, product_name, category_name, selling_price, stock_quantity, sku')
			.eq('tenant_id', tenantId)
			.gt('stock_quantity', 0);
		
		products = (data || []).map(row => ({
			id: row.product_id,
			name: row.product_name,
			category: row.category_name || 'General',
			unit_price: row.selling_price || 0,
			stock_quantity: row.stock_quantity || 0,
			sku: row.sku,
			isPOM: false // Simplified, could join with products if needed
		}));
	}

	async function loadDoctors() {
		if (!tenantId) return;
		const { data } = await supabase.from('healthcare_providers')
			.select('id, full_name, specialization, profile_photo_url')
			.order('full_name');
		
		doctors = (data || []).map(d => ({
			id: d.id,
			name: d.full_name || 'Dr. Unknown',
			specialization: d.specialization || 'General',
			avatar: d.profile_photo_url
		}));
	}

	// ── Rich composer state ────────────────────────────────────────────────────
	let canPrescribe: boolean = $state(false);
	let canApplyDiscount: boolean = $state(true);
	let canReferToDoctor: boolean = $state(true);

	// Product picker
	let showProductPicker: boolean = $state(false);
	let productSearch: string = $state('');
	let pendingDiscounts: Record<string, number> = $state({});

	// Doctor Referral
	let showDoctorPicker: boolean = $state(false);
	let doctorSearchQuery: string = $state('');

	let filteredDoctors = $derived(
		doctorSearchQuery
			? doctors.filter(d => 
				d.name.toLowerCase().includes(doctorSearchQuery.toLowerCase()) || 
				d.specialization.toLowerCase().includes(doctorSearchQuery.toLowerCase()))
			: doctors
	);

	// Filter by POM access AND search query
	let visibleProducts = $derived(
		canPrescribe
			? products       // show all including POM
			: products.filter(p => !p.isPOM)  // hide POM products
	);
	let filteredProducts = $derived(
		productSearch
			? visibleProducts.filter(p =>
					p.name.toLowerCase().includes(productSearch.toLowerCase()) ||
					p.category.toLowerCase().includes(productSearch.toLowerCase()))
			: visibleProducts
	);

	function discountedPrice(price: number, discountPct: number): number {
		return Math.round(price * (1 - discountPct / 100));
	}

	// ── Derived ────────────────────────────────────────────────────────────────
	let filteredConvs = $derived(conversations.filter(c => {
		const matchBranch  = selectedBranchId === 'all' || c.branch_id === selectedBranchId;
		const matchStatus  = statusFilter === 'all' || c.status === statusFilter;
		const q            = searchQuery.toLowerCase();
		const matchSearch  = !q
			|| (c.customer_name || '').toLowerCase().includes(q)
			|| (c.consultation_code || '').toLowerCase().includes(q);
		return matchBranch && matchStatus && matchSearch;
	}));

	let activeConv = $derived(conversations.find(c => c.id === activeConvId) ?? null);

	// ── Actions ────────────────────────────────────────────────────────────────
	async function selectConv(id: string) {
		activeConvId  = id;
		mobileView    = 'chat';
		
		// Fetch message history
		const { data } = await supabase.from('chat_messages')
			.select('*')
			.eq('conversation_id', id)
			.order('created_at', { ascending: true });
			
		liveMessages = data || [];
		
		// Subscribe to real-time updates
		if (messageSubscription) messageSubscription.unsubscribe();
		
		messageSubscription = supabase.channel(`conv-${id}`)
			.on('postgres_changes', { 
				event: 'INSERT', 
				schema: 'public', 
				table: 'chat_messages', 
				filter: `conversation_id=eq.${id}` 
			}, payload => {
				// Avoid duplicate if we just sent it
				if (!liveMessages.find(m => m.id === payload.new.id)) {
					liveMessages = [...liveMessages, payload.new];
					scrollToBottom();
				}
			})
			.subscribe();
			
		scrollToBottom();
	}

	function goBackToList() {
		mobileView   = 'list';
		activeConvId = null;
	}

	async function sendMessage(meta: any = null) {
		const text = messageText.trim();
		const hasFiles = pendingFiles.length > 0;
		if (!text && !hasFiles && !meta || sending || !activeConvId) return;
		sending = true;

		try {
			const payload: any = {
				conversation_id: activeConvId,
				sender_type: 'staff',
				sender_id: staffId,
				message_text: text || (meta?.doctor ? 'Doctor Referral' : meta?.product ? 'Product Recommendation' : '')
			};

			if (meta) {
				payload.metadata = meta;
			}
			
			const { data, error } = await supabase.from('chat_messages')
				.insert(payload)
				.select().single();
			
			if (error) throw error;
			
			// Optimistic update if not already there
			if (!liveMessages.find(m => m.id === data.id)) {
				liveMessages = [...liveMessages, data];
			}
			
			if (!meta) messageText = ''; // only clear text if it wasn't a meta-only message
			scrollToBottom();
		} catch (err) {
			console.error('Failed to send message:', err);
		} finally {
			sending = false;
		}
	}

	function handleKeydown(e: KeyboardEvent) {
		if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); }
	}

	function referDoctor(doc: any) {
		sendMessage({ doctor: { ...doc } });
		showDoctorPicker = false;
		doctorSearchQuery = '';
	}

	// ── Voice recording ────────────────────────────────────────────────────────
	function toggleRecording() {
		if (isRecording) {
			// Stop — send voice note bubble
			if (recordInterval) { clearInterval(recordInterval); recordInterval = null; }
			const dur = recordSeconds;
			recordSeconds = 0;
			isRecording = false;
			liveMessages = [...liveMessages, {
				id: `tmp-voice-${Date.now()}`,
				sender_type: 'staff',
				content: null,
				attachment_type: 'voice',
				attachment_name: `Voice note (${formatDuration(dur)})`,
				attachment_url: null,
				voice_duration: dur,
				created_at: new Date().toISOString()
			}];
			scrollToBottom();
		} else {
			// Start
			isRecording = true;
			recordSeconds = 0;
			showAttachTray = false;
			recordInterval = setInterval(() => { recordSeconds++; }, 1000);
		}
	}

	function cancelRecording() {
		if (recordInterval) { clearInterval(recordInterval); recordInterval = null; }
		isRecording = false;
		recordSeconds = 0;
	}

	function formatDuration(s: number): string {
		const m = Math.floor(s / 60);
		return `${m}:${String(s % 60).padStart(2, '0')}`;
	}

	// ── File attachment ────────────────────────────────────────────────────────
	const MAX_VIDEO_BYTES = 50 * 1024 * 1024; // 50 MB

	function handleFileUpload(type: 'image'|'audio'|'pdf'|'video') {
		const input = document.createElement('input');
		input.type = 'file';
		if      (type === 'image') input.accept = 'image/*';
		else if (type === 'audio') input.accept = 'audio/*';
		else if (type === 'video') input.accept = 'video/*';
		else                       input.accept = 'application/pdf';
		input.onchange = () => {
			const file = input.files?.[0];
			if (!file) return;
			if (type === 'video' && file.size > MAX_VIDEO_BYTES) {
				alert(`Video is too large (${(file.size / 1024 / 1024).toFixed(1)} MB). Maximum allowed size is 50 MB.`);
				return;
			}
			const url = URL.createObjectURL(file);
			pendingFiles = [...pendingFiles, { type, name: file.name, url }];
			showAttachTray = false;
		};
		input.click();
	}

	function removePendingFile(idx: number) {
		pendingFiles = pendingFiles.filter((_, i) => i !== idx);
	}

	// ── Product picker ─────────────────────────────────────────────────────────
	function shareProduct(product: any) {
		const discPct = pendingDiscounts[product.id] ?? 0;
		const finalPrice = discPct > 0 ? discountedPrice(product.unit_price, discPct) : product.unit_price;
		liveMessages = [...liveMessages, {
			id: `tmp-prod-${Date.now()}`,
			sender_type: 'staff',
			content: null,
			attachment_type: 'product',
			product: { ...product, sharedPrice: finalPrice, discountPct: discPct },
			created_at: new Date().toISOString()
		}];
		showProductPicker = false;
		productSearch = '';
		pendingDiscounts = {};  // clear discounts after sharing
		scrollToBottom();
	}

	// ── Helpers ────────────────────────────────────────────────────────────────
	function relativeTime(ts: string): string {
		const diff = Date.now() - new Date(ts).getTime();
		const m = Math.floor(diff / 60000);
		if (m < 1)  return 'Just now';
		if (m < 60) return `${m}m ago`;
		const h = Math.floor(m / 60);
		if (h < 24) return `${h}h ago`;
		return new Date(ts).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' });
	}

	function statusBadge(s: string) {
		return s === 'active' ? 'bg-emerald-100 text-emerald-700' : 'bg-gray-100 text-gray-500';
	}

	function initials(name: string | null): string {
		if (!name) return '?';
		return name.split(' ').map(n => n[0]).join('').slice(0, 2).toUpperCase();
	}

	const avatarPalette = [
		'bg-indigo-200 text-indigo-800', 'bg-violet-200 text-violet-800',
		'bg-pink-200 text-pink-800',     'bg-amber-200 text-amber-800',
		'bg-teal-200 text-teal-800',     'bg-sky-200 text-sky-800',
	];
	function avatarBg(name: string | null): string {
		return avatarPalette[(name || '').charCodeAt(0) % avatarPalette.length];
	}
</script>

<svelte:head><title>Messages – Kemani POS</title></svelte:head>

<!--
	LAYOUT STRATEGY
	───────────────
	Desktop (lg+): flex row — left panel (w-80) + right chat panel, both always visible.
	Mobile (<lg):  show ONLY the active panel (list OR chat), controlled by mobileView.
	
	We do this with CSS visibility classes on each panel:
	  List  panel: always visible on desktop | hidden on mobile when mobileView==='chat'
	  Chat  panel: always visible on desktop | hidden on mobile when mobileView==='list'
-->

<div class="messages-root">
	{#if loading}
		<div class="loading-overlay">
			<RefreshCw class="h-8 w-8 animate-spin text-indigo-600" />
			<p class="mt-4 text-sm font-medium text-gray-500">Loading messages…</p>
		</div>
	{/if}

	<!-- ══════════════════════════════════════════════════════════
		 PANEL A — Conversation List
	══════════════════════════════════════════════════════════ -->
	<aside class="conv-panel {mobileView === 'chat' ? 'mobile-hidden' : ''}">

		<!-- Header -->
		<div class="conv-header">
			<div class="conv-header-top">
				<h1 class="conv-title">
					<MessageSquare class="h-5 w-5 text-indigo-600" />
					Messages
					<span class="conv-badge">{conversations.filter(c => c.status === 'active').length}</span>
				</h1>
				<button class="icon-btn" title="Refresh"><RefreshCw class="h-4 w-4" /></button>
			</div>

			<!-- Search -->
			<div class="search-wrap">
				<Search class="search-icon" />
				<input type="text" bind:value={searchQuery} placeholder="Search customer or code…" class="search-input" />
			</div>

			<!-- Filters -->
			<div class="filter-row">
				<div class="branch-select-wrap">
					<Building2 class="branch-icon" />
					<select bind:value={selectedBranchId} class="branch-select">
						<option value="all">All Branches</option>
						{#each branches as b}
							<option value={b.id}>{b.name}</option>
						{/each}
					</select>
					<ChevronDown class="select-chevron" />
				</div>
				<div class="status-pills">
					{#each [['all','All'],['active','Active'],['closed','Closed']] as [val, label]}
						<button
							onclick={() => statusFilter = val as any}
							class="status-pill {statusFilter === val ? 'status-pill--active' : ''}"
						>{label}</button>
					{/each}
				</div>
			</div>
		</div>

		<!-- List -->
		<div class="conv-list">
			{#if filteredConvs.length === 0}
				<div class="empty-state">
					<MessageSquare class="h-10 w-10 opacity-30" />
					<p class="text-sm font-medium text-gray-500">No conversations found</p>
				</div>
			{:else}
				{#each filteredConvs as conv}
					<button
						onclick={() => selectConv(conv.id)}
						class="conv-item {activeConvId === conv.id ? 'conv-item--active' : ''}"
					>
						<!-- Avatar -->
						<div class="avatar-wrap">
							<div class="avatar {activeConvId === conv.id ? 'bg-indigo-200 text-indigo-800' : avatarBg(conv.customer_name)}">
								{initials(conv.customer_name)}
							</div>
							{#if conv.status === 'active'}
								<span class="online-dot"></span>
							{/if}
						</div>

						<!-- Body -->
						<div class="conv-body">
							<div class="conv-row">
								<span class="conv-name">{conv.customer_name}</span>
								<span class="conv-time">{relativeTime(conv.lastMsg?.created_at || conv.started_at)}</span>
							</div>
							<div class="conv-meta">
								<span>{conv.branch_name}</span>
								{#if conv.consultation_code}<span>· {conv.consultation_code}</span>{/if}
							</div>
							<p class="conv-preview">
								{#if conv.lastMsg?.content}
									{#if conv.lastMsg.sender_type === 'staff'}<strong>You: </strong>{/if}{conv.lastMsg.content}
								{:else}
									<em>No messages yet</em>
								{/if}
							</p>
						</div>

						<!-- Status -->
						<span class="status-dot {statusBadge(conv.status)}">{conv.status}</span>
					</button>
				{/each}
			{/if}

			<!-- Doctor Referral Modal -->
			{#if showDoctorPicker}
				<div class="modal-backdrop" onclick={() => showDoctorPicker = false}>
					<div class="product-modal" onclick={e => e.stopPropagation()}>
						<div class="product-modal-header">
							<div>
								<h3 class="product-modal-title">Refer to a Doctor</h3>
								<p class="product-modal-sub">Select a partner medic to refer the customer</p>
							</div>
							<button onclick={() => { showDoctorPicker = false; doctorSearchQuery = ''; }} class="modal-close"><X class="h-4 w-4" /></button>
						</div>

						<div class="product-search-wrap">
							<Search class="product-search-pill-icon" />
							<input
								bind:value={doctorSearchQuery}
								placeholder="Search by specialty or name…"
								class="product-search-input"
							/>
						</div>

						<div class="product-grid">
							{#each filteredDoctors as doc}
								<button class="product-row-wrap" style="width: 100%; text-align: left;" onclick={() => referDoctor(doc)}>
									<div class="product-row">
										<div class="product-row-img-wrap" style="background: #f5f5ff">
											<UserRound class="h-5 w-5 text-indigo-400" />
										</div>
										<div class="product-row-body">
											<p class="product-row-name">{doc.name}</p>
											<p class="product-row-meta">{doc.specialization}</p>
										</div>
										<ChevronRight class="h-4 w-4 text-gray-300" />
									</div>
								</button>
							{/each}
							{#if filteredDoctors.length === 0}
								<div class="p-12 text-center text-gray-400 text-sm">No doctors found matching "{doctorSearchQuery}"</div>
							{/if}
						</div>
					</div>
				</div>
			{/if}
		</div>

		<!-- Footer -->
		<div class="conv-footer">
			<span><strong>{conversations.filter(c => c.status === 'active').length}</strong> active</span>
			<span>·</span>
			<span><strong>{filteredConvs.length}</strong> shown</span>
		</div>
	</aside>


	<!-- ══════════════════════════════════════════════════════════
		 PANEL B — Chat thread
	══════════════════════════════════════════════════════════ -->
	<main class="chat-panel {mobileView === 'list' ? 'mobile-hidden' : ''}">

		{#if !activeConv}
			<!-- Desktop empty state (mobile never shows this since mobileView guards it) -->
			<div class="chat-empty">
				<div class="chat-empty-icon"><MessageSquare class="h-10 w-10 text-indigo-300" /></div>
				<p class="text-base font-semibold text-gray-600">Select a conversation</p>
				<p class="text-sm text-gray-400">Choose a chat from the left to begin.</p>
			</div>

		{:else}
			<!-- Chat header -->
			<div class="chat-header">
				<!-- Mobile back button -->
				<button onclick={goBackToList} class="back-btn" aria-label="Back to conversations">
					<ArrowLeft class="h-5 w-5" />
				</button>

				<div class="avatar {avatarBg(activeConv.customer_name)} small">
					{initials(activeConv.customer_name)}
				</div>

				<div class="chat-header-info">
					<p class="chat-header-name">{activeConv.customer_name}</p>
					<div class="chat-header-meta">
						<Building2 class="h-3 w-3" /> {activeConv.branch_name}
						{#if activeConv.consultation_code}
							<span class="text-indigo-500 font-mono">· #{activeConv.consultation_code}</span>
						{/if}
						<span class="status-dot ml-1 {statusBadge(activeConv.status)}">{activeConv.status}</span>
					</div>
				</div>

				{#if activeConv.status === 'active'}
					<button class="close-chat-btn">Close Chat</button>
				{/if}
			</div>

			<!-- Messages -->
			<div class="messages-area">
				{#each liveMessages as msg, i}
					{@const isStaff = msg.sender_type === 'staff'}
					{@const showSep = i === 0 || new Date(msg.created_at).toDateString() !== new Date(liveMessages[i-1].created_at).toDateString()}

					{#if showSep}
						<div class="date-sep">
							<span>{new Date(msg.created_at).toLocaleDateString('en-GB', { weekday:'short', day:'numeric', month:'short' })}</span>
						</div>
					{/if}

					<div class="bubble-row {isStaff ? 'bubble-row--right' : 'bubble-row--left'}">
						{#if !isStaff}
							<div class="bubble-avatar {avatarBg(activeConv.customer_name)}">{initials(activeConv.customer_name)}</div>
						{/if}
						<div class="bubble-col {isStaff ? 'items-end' : 'items-start'}">
							<!-- Voice note -->
							{#if msg.attachment_type === 'voice'}
								<div class="bubble bubble-voice {isStaff ? 'bubble--staff' : 'bubble--customer'}">
									<div class="voice-bubble">
										<div class="voice-play-btn">▶</div>
										<div class="voice-waveform">
											{#each Array(18) as _, wi}
												<span class="voice-bar" style="height:{8 + Math.sin(wi * 1.3) * 10 + Math.random() * 6}px"></span>
											{/each}
										</div>
										<span class="voice-dur">{msg.attachment_name?.match(/\((.+)\)/)?.[1] ?? '0:00'}</span>
									</div>
								</div>
							<!-- Video -->
							{:else if msg.attachment_type === 'video'}
								<div class="bubble bubble-media {isStaff ? 'bubble--staff' : 'bubble--customer'}">
									<video src={msg.attachment_url} controls class="media-video" playsinline></video>
									<p class="media-name">{msg.attachment_name}</p>
								</div>
							<!-- Image -->
							{:else if msg.attachment_type === 'image'}
								<div class="bubble bubble-media {isStaff ? 'bubble--staff' : 'bubble--customer'}">
									<img src={msg.attachment_url} alt={msg.attachment_name} class="media-img" />
									<p class="media-name">{msg.attachment_name}</p>
								</div>
							<!-- Audio file -->
							{:else if msg.attachment_type === 'audio'}
								<div class="bubble {isStaff ? 'bubble--staff' : 'bubble--customer'}">
									<div class="file-chip">
										<span class="file-chip-icon">🎵</span>
										<span class="file-chip-name">{msg.attachment_name}</span>
									</div>
									<audio src={msg.attachment_url} controls class="audio-player"></audio>
								</div>
							<!-- PDF -->
							{:else if msg.attachment_type === 'pdf'}
								<a href={msg.attachment_url} target="_blank" class="bubble bubble-file {isStaff ? 'bubble--staff' : 'bubble--customer'}">
									<div class="file-chip">
										<span class="file-chip-icon pdf">PDF</span>
										<span class="file-chip-name">{msg.attachment_name}</span>
									</div>
								</a>
							<!-- Product card -->
							{:else if msg.attachment_type === 'product'}
								<div class="bubble bubble-product {isStaff ? 'bubble--staff-light' : 'bubble--customer'}">
									<div class="product-card">
										<div class="product-card-icon"><Package class="h-5 w-5" /></div>
										<div class="product-card-body">
											<p class="product-card-name">{msg.product.name}</p>
											<p class="product-card-cat">{msg.product.category}</p>
											<div class="product-card-pricing">
												{#if msg.product.discountPct > 0}
													<span class="product-original-price">₦{msg.product.unit_price.toLocaleString()}</span>
													<span class="product-card-price">₦{msg.product.sharedPrice.toLocaleString()}</span>
													<span class="product-disc-badge">{msg.product.discountPct}% OFF</span>
												{:else}
													<p class="product-card-price">₦{msg.product.unit_price.toLocaleString()}</p>
												{/if}
											</div>
										</div>
									</div>
									<button class="product-order-btn"><ShoppingCart class="h-3 w-3" /> Order Now</button>
								</div>
							<!-- Referral card -->
							{:else if msg.attachment_type === 'referral'}
								<div class="referral-bubble">
									<div class="ref-header">
										<div class="ref-icon-wrap"><Stethoscope class="h-4 w-4" /></div>
										<span class="ref-tag">Dr. Referral</span>
									</div>
									<div class="ref-body">
										<div class="ref-doctor">
											<div class="ref-avatar">
												{#if msg.doctor.avatar}
													<img src={msg.doctor.avatar} alt={msg.doctor.name} />
												{:else}
													<UserRound class="h-5 w-5 opacity-40" />
												{/if}
											</div>
											<div class="ref-info">
												<p class="ref-name">{msg.doctor.name}</p>
												<p class="ref-spec">{msg.doctor.specialization}</p>
											</div>
										</div>
										<button class="ref-action-btn">
											<span>Book Consultation</span>
											<ChevronRight class="h-4 w-4" />
										</button>
									</div>
								</div>
							<!-- Plain text -->
							{:else}
								<div class="bubble {isStaff ? 'bubble--staff' : 'bubble--customer'}">{msg.message_text}</div>
							{/if}
							<span class="bubble-time">{new Date(msg.created_at).toLocaleTimeString([], { hour:'2-digit', minute:'2-digit' })}</span>
						</div>
					</div>
				{/each}

				{#if liveMessages.length === 0}
					<div class="empty-state"><MessageSquare class="h-9 w-9 opacity-30" /><p class="text-sm">No messages yet</p></div>
				{/if}

				<div bind:this={messagesEndEl}></div>
			</div>

			<!-- ── Rich Composer ──────────────────────────────────────────── -->
			{#if activeConv.status === 'active'}
				<div class="composer">

					<!-- Pending file previews -->
					{#if pendingFiles.length > 0}
						<div class="pending-files">
							{#each pendingFiles as f, i}
								<div class="pending-chip">
									{#if f.type === 'image'}
										<img src={f.url} alt={f.name} class="pending-thumb" />
									{:else if f.type === 'audio'}
										<span class="pending-icon">🎵</span>
									{:else}
										<span class="pending-icon pdf">PDF</span>
									{/if}
									<span class="pending-name">{f.name}</span>
									<button onclick={() => removePendingFile(i)} class="pending-remove"><X class="h-3 w-3" /></button>
								</div>
							{/each}
						</div>
					{/if}

					<!-- Emoji picker panel -->
					{#if showEmojiPicker}
						<div class="emoji-panel">
							<!-- Category tabs -->
							<div class="emoji-tabs">
								{#each EMOJI_CATEGORIES as cat, ci}
									<button
										onclick={() => emojiCategory = ci}
										title={cat.name}
										class="emoji-tab {emojiCategory === ci ? 'emoji-tab--active' : ''}"
									>{cat.label}</button>
								{/each}
							</div>
							<!-- Emoji grid -->
							<div class="emoji-grid">
								{#each EMOJI_CATEGORIES[emojiCategory].emojis as emoji}
									<button onclick={() => insertEmoji(emoji)} class="emoji-btn">{emoji}</button>
								{/each}
							</div>
						</div>
					{/if}

					<!-- Attachment tray -->
					{#if showAttachTray}
						<div class="attach-tray">
							<button onclick={() => handleFileUpload('image')} class="attach-option">
								<span class="attach-opt-icon img"><Image class="h-5 w-5" /></span>
								<span>Image</span>
							</button>
							<button onclick={() => handleFileUpload('audio')} class="attach-option">
								<span class="attach-opt-icon aud"><FileAudio class="h-5 w-5" /></span>
								<span>Audio</span>
							</button>
							<button onclick={() => handleFileUpload('pdf')} class="attach-option">
								<span class="attach-opt-icon pdf"><FileText class="h-5 w-5" /></span>
								<span>PDF</span>
							</button>
							<button onclick={() => handleFileUpload('video')} class="attach-option">
								<span class="attach-opt-icon vid"><Video class="h-5 w-5" /></span>
								<span>Video</span>
							</button>
							<button onclick={() => { showProductPicker = true; showAttachTray = false; }} class="attach-option">
								<span class="attach-opt-icon prod"><Package class="h-5 w-5" /></span>
								<span>Product</span>
							</button>
							{#if canReferToDoctor}
								<button onclick={() => { showDoctorPicker = true; showAttachTray = false; }} class="attach-option">
									<span class="attach-opt-icon ref"><Stethoscope class="h-5 w-5" /></span>
									<span>Dr. Referral</span>
								</button>
							{/if}
						</div>
					{/if}

					<!-- Voice recording mode -->
					{#if isRecording}
						<div class="recording-bar">
							<button onclick={cancelRecording} class="rec-cancel"><X class="h-4 w-4" /> Cancel</button>
							<div class="rec-indicator">
								<span class="rec-dot"></span>
								<span class="rec-label">Recording…</span>
								<span class="rec-timer">{formatDuration(recordSeconds)}</span>
							</div>
							<button onclick={toggleRecording} class="rec-send"><Send class="h-4 w-4" /> Send</button>
						</div>
					{:else}
						<!-- Normal input row -->
						<div class="input-row">
							<!-- Attach button -->
							<button
								onclick={() => { showAttachTray = !showAttachTray; showEmojiPicker = false; }}
								class="composer-btn {showAttachTray ? 'composer-btn--active' : ''}"
								title="Attach file"
							><Paperclip class="h-4 w-4" /></button>

							<!-- Emoji button -->
							<button
								onclick={() => { showEmojiPicker = !showEmojiPicker; showAttachTray = false; }}
								class="composer-btn {showEmojiPicker ? 'composer-btn--active' : ''}"
								title="Emoji"
							><Smile class="h-4 w-4" /></button>

							<!-- Textarea -->
							<textarea
								bind:value={messageText}
								bind:this={msgInputEl}
								onkeydown={handleKeydown}
								placeholder="Type a reply…"
								rows="1"
								disabled={sending}
								class="msg-input"
							></textarea>

							<!-- Voice / Send -->
							{#if messageText.trim() || pendingFiles.length > 0}
								<button onclick={sendMessage} disabled={sending} class="send-btn">
									{#if sending}<div class="spinner"></div>{:else}<Send class="h-4 w-4" />{/if}
								</button>
							{:else}
								<button onclick={toggleRecording} class="composer-btn mic-btn" title="Voice note">
									<Mic class="h-4 w-4" />
								</button>
							{/if}
						</div>
					{/if}
					<p class="input-hint">Enter to send · Shift+Enter for newline</p>
				</div>
			{:else}
				<div class="closed-bar">This conversation is closed.</div>
			{/if}

			<!-- ── Product Picker Modal ──────────────────────────────────── -->
			{#if showProductPicker}
				<div class="modal-backdrop" onclick={() => { showProductPicker = false; productSearch = ''; pendingDiscounts = {}; }}>
					<div class="product-modal" onclick={(e) => e.stopPropagation()}>
						<div class="product-modal-header">
							<div>
								<h3 class="product-modal-title">Share a Product</h3>
								<p class="product-modal-sub">
									{canPrescribe ? 'All products including POM' : 'Over-the-counter products only'}
								</p>
							</div>
							<button onclick={() => { showProductPicker = false; productSearch = ''; pendingDiscounts = {}; }} class="modal-close"><X class="h-4 w-4" /></button>
						</div>
						<div class="product-search-wrap">
							<Search class="product-search-icon" />
							<input bind:value={productSearch} placeholder="Search products…" class="product-search-input" />
						</div>
						<div class="product-list">
							{#each filteredProducts as product}
								{@const disc = pendingDiscounts[product.id] ?? 0}
								{@const finalP = disc > 0 ? discountedPrice(product.price, disc) : product.price}
								<div class="product-row-wrap">
									<button onclick={() => shareProduct(product)} class="product-row">
										<div class="product-row-icon"><Package class="h-4 w-4 text-indigo-500" /></div>
										<div class="product-row-body">
											<div class="product-row-name-row">
												<p class="product-row-name">{product.name}</p>
												{#if product.isPOM}
													<span class="pom-badge">POM</span>
												{/if}
											</div>
											<p class="product-row-meta">{product.category} · {product.stock} in stock</p>
										</div>
										<div class="product-row-price-col">
											{#if disc > 0}
												<span class="product-row-original">₦{product.price.toLocaleString()}</span>
												<span class="product-row-price discounted">₦{finalP.toLocaleString()}</span>
											{:else}
												<span class="product-row-price">₦{product.price.toLocaleString()}</span>
											{/if}
										</div>
									</button>
									{#if canApplyDiscount}
										<div class="discount-row">
											<span class="disc-label">Discount</span>
											<div class="disc-input-wrap">
												<input
													type="number" min="0" max="100" step="1"
													value={disc}
													onchange={(e) => {
														const v = Math.min(100, Math.max(0, Number((e.target as HTMLInputElement).value)));
														pendingDiscounts = { ...pendingDiscounts, [product.id]: v };
													}}
													placeholder="0"
													class="disc-input"
												/>
												<span class="disc-pct-label">%</span>
											</div>
											{#if disc > 0}
												<span class="disc-preview">→ ₦{finalP.toLocaleString()}</span>
											{/if}
										</div>
									{/if}
								</div>
							{/each}
						</div>
					</div>
				</div>
			{/if}
		{/if}
	</main>
</div>


<style>
/* ── Root ──────────────────────────────────────────────────────────────── */
.messages-root {
	display: flex;
	height: calc(100vh - 0px);
	background: #f9fafb;
	overflow: hidden;
	font-family: 'Inter', sans-serif;
}

/* ══ CONVERSATION PANEL ════════════════════════════════════════════════ */
.conv-panel {
	width: 320px;
	flex-shrink: 0;
	background: #fff;
	border-right: 1px solid #e5e7eb;
	display: flex;
	flex-direction: column;
}

.conv-header { padding: 1.25rem 1rem 0.75rem; border-bottom: 1px solid #f3f4f6; }
.conv-header-top { display: flex; align-items: center; justify-content: space-between; margin-bottom: 0.75rem; }

.conv-title {
	display: flex; align-items: center; gap: 0.5rem;
	font-size: 1.05rem; font-weight: 800; color: #111827;
}
.conv-badge {
	display: inline-flex; align-items: center; justify-content: center;
	background: #4f46e5; color: #fff;
	font-size: 0.6rem; font-weight: 700;
	padding: 0.15rem 0.45rem; border-radius: 999px; min-width: 20px;
}

.icon-btn {
	padding: 0.35rem; border-radius: 0.5rem; border: none; background: none;
	color: #9ca3af; cursor: pointer; transition: background 0.15s, color 0.15s;
}
.icon-btn:hover { background: #f3f4f6; color: #374151; }

/* Search */
.search-wrap { position: relative; margin-bottom: 0.5rem; }
.search-icon  { position: absolute; left: 0.65rem; top: 50%; transform: translateY(-50%); width: 13px; height: 13px; color: #9ca3af; }
.search-input {
	width: 100%; padding: 0.4rem 0.75rem 0.4rem 2rem;
	font-size: 0.8125rem; border: 1px solid #e5e7eb; border-radius: 0.6rem;
	background: #f9fafb; outline: none; color: #374151;
	transition: border-color 0.15s, box-shadow 0.15s;
}
.search-input:focus { border-color: #6366f1; box-shadow: 0 0 0 2px #e0e7ff; }

/* Filter row */
.filter-row { display: flex; gap: 0.4rem; align-items: center; }
.branch-select-wrap { position: relative; flex: 1; }
.branch-icon   { position: absolute; left: 0.5rem; top: 50%; transform: translateY(-50%); width: 12px; height: 12px; color: #9ca3af; pointer-events: none; }
.select-chevron { position: absolute; right: 0.4rem; top: 50%; transform: translateY(-50%); width: 11px; height: 11px; color: #9ca3af; pointer-events: none; }
.branch-select {
	width: 100%; padding: 0.35rem 1.2rem 0.35rem 1.6rem;
	font-size: 0.7rem; border: 1px solid #e5e7eb; border-radius: 0.5rem;
	background: #f9fafb; appearance: none; color: #374151; outline: none;
}
.branch-select:focus { border-color: #6366f1; }

.loading-overlay {
	position: absolute; inset: 0; background: rgba(255,255,255,0.8);
	backdrop-filter: blur(4px); z-index: 50;
	display: flex; flex-direction: column; align-items: center; justify-content: center;
}

.status-pills { display: flex; gap: 0.2rem; }
.status-pill {
	padding: 0.3rem 0.5rem; border-radius: 0.4rem; border: none;
	font-size: 0.625rem; font-weight: 700; cursor: pointer;
	background: #f3f4f6; color: #6b7280; transition: background 0.15s, color 0.15s;
}
.status-pill--active { background: #4f46e5; color: #fff; }

/* List */
.conv-list { flex: 1; overflow-y: auto; }
.conv-item {
	width: 100%; text-align: left;
	padding: 0.75rem 1rem; display: flex; align-items: flex-start; gap: 0.75rem;
	border: none; background: none; cursor: pointer;
	border-bottom: 1px solid #f9fafb; transition: background 0.12s;
}
.conv-item:hover { background: #f9fafb; }
.conv-item--active { background: #eef2ff; border-right: 3px solid #4f46e5; }

/* Avatar */
.avatar-wrap { position: relative; flex-shrink: 0; }
.avatar {
	width: 40px; height: 40px; border-radius: 50%;
	display: flex; align-items: center; justify-content: center;
	font-size: 0.8125rem; font-weight: 700;
}
.avatar.small { width: 34px; height: 34px; font-size: 0.75rem; }
.online-dot {
	position: absolute; bottom: -1px; right: -1px;
	width: 11px; height: 11px; background: #10b981;
	border: 2px solid #fff; border-radius: 50%;
}

/* Conv body */
.conv-body { flex: 1; min-width: 0; }
.conv-row { display: flex; justify-content: space-between; gap: 0.25rem; align-items: center; }
.conv-name  { font-size: 0.875rem; font-weight: 700; color: #111827; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.conv-time  { font-size: 0.625rem; color: #9ca3af; white-space: nowrap; flex-shrink: 0; }
.conv-meta  { display: flex; gap: 0.2rem; font-size: 0.625rem; color: #6366f1; font-weight: 600; margin-top: 0.1rem; }
.conv-preview { font-size: 0.75rem; color: #6b7280; margin-top: 0.25rem; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

/* Status dot pill */
.status-dot {
	align-self: flex-start; flex-shrink: 0;
	padding: 0.1rem 0.4rem; border-radius: 999px;
	font-size: 0.55rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.04em;
}

/* Footer */
.conv-footer {
	padding: 0.4rem 1rem; border-top: 1px solid #f3f4f6;
	background: #f9fafb; display: flex; gap: 0.5rem;
	font-size: 0.7rem; color: #9ca3af;
}

/* ══ CHAT PANEL ════════════════════════════════════════════════════════ */
.chat-panel { flex: 1; display: flex; flex-direction: column; min-width: 0; }

.chat-empty {
	flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center;
	gap: 0.75rem; color: #9ca3af; padding: 2rem;
}
.chat-empty-icon {
	width: 72px; height: 72px; background: #eef2ff;
	border-radius: 1rem; display: flex; align-items: center; justify-content: center;
}

/* Chat header */
.chat-header {
	background: #fff; border-bottom: 1px solid #e5e7eb;
	padding: 0.75rem 1.25rem; display: flex; align-items: center; gap: 0.75rem;
	flex-shrink: 0; box-shadow: 0 1px 3px rgba(0,0,0,0.04);
}
.back-btn {
	display: none; /* hidden on desktop, shown on mobile */
	padding: 0.35rem; border-radius: 0.5rem; border: none; background: none;
	color: #4f46e5; cursor: pointer; flex-shrink: 0;
}
.chat-header-info { flex: 1; min-width: 0; }
.chat-header-name { font-size: 0.9375rem; font-weight: 700; color: #111827; }
.chat-header-meta { display: flex; align-items: center; gap: 0.3rem; font-size: 0.7rem; color: #9ca3af; margin-top: 0.1rem; }
.close-chat-btn {
	padding: 0.35rem 0.75rem; border-radius: 0.5rem; border: none;
	background: #fef2f2; color: #dc2626; font-size: 0.75rem; font-weight: 700;
	cursor: pointer; transition: background 0.15s;
}
.close-chat-btn:hover { background: #fee2e2; }

/* Messages area */
.messages-area {
	flex: 1; overflow-y: auto; padding: 1rem 1.25rem; display: flex;
	flex-direction: column; gap: 0.25rem; background: #f9fafb;
}
.date-sep {
	display: flex; align-items: center; gap: 0.75rem; margin: 0.5rem 0;
}
.date-sep::before, .date-sep::after { content:''; flex:1; height:1px; background:#e5e7eb; }
.date-sep span { font-size: 0.625rem; color: #9ca3af; font-weight: 600; white-space: nowrap; }

.bubble-row { display: flex; align-items: flex-end; gap: 0.5rem; margin-top: 0.25rem; }
.bubble-row--right { justify-content: flex-end; }
.bubble-row--left  { justify-content: flex-start; }
.bubble-avatar {
	width: 28px; height: 28px; border-radius: 50%;
	display: flex; align-items: center; justify-content: center;
	font-size: 0.625rem; font-weight: 700; flex-shrink: 0;
}
.bubble-col { display: flex; flex-direction: column; max-width: 68%; }
.items-end   { align-items: flex-end; }
.items-start { align-items: flex-start; }
.bubble {
	padding: 0.6rem 0.875rem; border-radius: 1.25rem;
	font-size: 0.875rem; line-height: 1.5; box-shadow: 0 1px 2px rgba(0,0,0,0.06);
}
.bubble--staff    { background: #4f46e5; color: #fff; border-bottom-right-radius: 0.25rem; }
.bubble--customer { background: #fff; color: #1f2937; border: 1px solid #e5e7eb; border-bottom-left-radius: 0.25rem; }
.bubble-time { font-size: 0.6rem; color: #9ca3af; margin-top: 0.2rem; padding: 0 0.25rem; }

/* ── Composer ──────────────────────────────────────────────────────────── */
.composer {
	background: #fff; border-top: 1px solid #e5e7eb;
	padding: 0.5rem 0.75rem 0.25rem; flex-shrink: 0; position: relative;
}

/* Pending files */
.pending-files { display: flex; flex-wrap: wrap; gap: 0.4rem; padding: 0.4rem 0 0.5rem; }
.pending-chip {
	display: flex; align-items: center; gap: 0.35rem;
	background: #f0f4ff; border: 1px solid #c7d2fe;
	border-radius: 0.5rem; padding: 0.25rem 0.5rem;
	max-width: 200px;
}
.pending-thumb { width: 32px; height: 32px; object-fit: cover; border-radius: 0.3rem; flex-shrink: 0; }
.pending-icon { font-size: 0.75rem; font-weight: 800; padding: 0.25rem 0.35rem; border-radius: 0.25rem; background: #e0e7ff; color: #4f46e5; }
.pending-icon.pdf { background: #fee2e2; color: #dc2626; }
.pending-name { font-size: 0.65rem; color: #374151; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 100px; }
.pending-remove { background: none; border: none; cursor: pointer; color: #9ca3af; padding: 0; display: flex; }
.pending-remove:hover { color: #dc2626; }

/* Attachment tray */
.attach-tray {
	display: flex; gap: 0.5rem; padding: 0.5rem 0 0.6rem;
	border-bottom: 1px solid #f3f4f6; margin-bottom: 0.4rem;
}
.attach-option {
	display: flex; flex-direction: column; align-items: center; gap: 0.25rem;
	border: none; background: none; cursor: pointer; padding: 0.35rem 0.6rem;
	border-radius: 0.6rem; transition: background 0.15s;
	font-size: 0.65rem; font-weight: 600; color: #374151;
}
.attach-option:hover { background: #f3f4f6; }
.attach-opt-icon {
	width: 38px; height: 38px; border-radius: 0.75rem;
	display: flex; align-items: center; justify-content: center;
}
.attach-opt-icon.img  { background: #ecfdf5; color: #059669; }
.attach-opt-icon.aud  { background: #fdf4ff; color: #9333ea; }
.attach-opt-icon.pdf  { background: #fef2f2; color: #dc2626; }
.attach-opt-icon.vid  { background: #fff7ed; color: #ea580c; }
.attach-opt-icon.prod { background: #eff6ff; color: #2563eb; }

/* Recording bar */
.recording-bar {
	display: flex; align-items: center; justify-content: space-between;
	padding: 0.5rem 0; gap: 0.75rem;
}
.rec-cancel {
	display: flex; align-items: center; gap: 0.3rem;
	background: none; border: none; cursor: pointer;
	color: #6b7280; font-size: 0.75rem; font-weight: 600; padding: 0.35rem 0.6rem;
	border-radius: 0.5rem; transition: background 0.15s;
}
.rec-cancel:hover { background: #f3f4f6; }
.rec-indicator {
	display: flex; align-items: center; gap: 0.5rem; flex: 1; justify-content: center;
}
.rec-dot {
	width: 10px; height: 10px; border-radius: 50%; background: #ef4444;
	animation: pulse-dot 1s ease-in-out infinite;
}
@keyframes pulse-dot { 0%,100% { opacity:1; transform:scale(1); } 50% { opacity:0.5; transform:scale(0.8); } }
.rec-label { font-size: 0.8125rem; color: #374151; font-weight: 600; }
.rec-timer { font-size: 0.875rem; font-weight: 700; color: #ef4444; font-variant-numeric: tabular-nums; min-width: 36px; }
.rec-send {
	display: flex; align-items: center; gap: 0.3rem;
	background: #4f46e5; color: #fff; border: none; cursor: pointer;
	font-size: 0.75rem; font-weight: 700; padding: 0.4rem 0.85rem;
	border-radius: 999px; transition: background 0.15s;
}
.rec-send:hover { background: #4338ca; }

/* Input row */
.input-row { display: flex; align-items: flex-end; gap: 0.5rem; padding: 0.35rem 0 0.25rem; }
.composer-btn {
	width: 36px; height: 36px; border-radius: 50%; border: 1px solid #e5e7eb;
	background: #f9fafb; color: #6b7280; display: flex; align-items: center; justify-content: center;
	cursor: pointer; flex-shrink: 0; transition: all 0.15s;
}
.composer-btn:hover { background: #f0f0ff; border-color: #c7d2fe; color: #4f46e5; }
.composer-btn--active { background: #eef2ff; border-color: #a5b4fc; color: #4f46e5; }
.mic-btn:hover { background: #fef2f2; border-color: #fca5a5; color: #dc2626; }
.msg-input {
	flex: 1; resize: none; min-height: 36px; max-height: 120px;
	padding: 0.5rem 0.875rem; font-size: 0.875rem;
	border: 1px solid #e5e7eb; border-radius: 1.25rem;
	background: #f9fafb; outline: none; color: #111827;
	transition: border-color 0.15s, box-shadow 0.15s; font-family: inherit;
}
.msg-input:focus { border-color: #6366f1; box-shadow: 0 0 0 2px #e0e7ff; }
.send-btn {
	width: 36px; height: 36px; border-radius: 50%; border: none;
	background: #4f46e5; color: #fff; display: flex; align-items: center; justify-content: center;
	cursor: pointer; flex-shrink: 0; transition: background 0.15s, transform 0.1s;
	box-shadow: 0 2px 4px rgba(79,70,229,0.3);
}
.send-btn:hover:not(:disabled) { background: #4338ca; transform: scale(1.05); }
.send-btn:disabled { opacity: 0.4; cursor: not-allowed; box-shadow: none; }
.spinner { width: 14px; height: 14px; border: 2px solid rgba(255,255,255,0.4); border-top-color: #fff; border-radius: 50%; animation: spin 0.6s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.input-hint { padding: 0 0.25rem 0.25rem; font-size: 0.58rem; color: #e5e7eb; }

/* ── Rich bubble types ──────────────────────────────────────────────────── */
/* Voice */
.voice-bubble { display: flex; align-items: center; gap: 0.5rem; }
.voice-play-btn {
	width: 28px; height: 28px; border-radius: 50%; background: rgba(255,255,255,0.25);
	display: flex; align-items: center; justify-content: center; font-size: 0.65rem;
	cursor: pointer; flex-shrink: 0;
}
.bubble--customer .voice-play-btn { background: #e0e7ff; color: #4f46e5; }
.voice-waveform { display: flex; align-items: center; gap: 2px; height: 28px; }
.voice-bar { width: 3px; border-radius: 2px; background: rgba(255,255,255,0.6); flex-shrink: 0; }
.bubble--customer .voice-bar { background: #a5b4fc; }
.voice-dur { font-size: 0.65rem; opacity: 0.8; white-space: nowrap; }

/* Image / Video bubble */
.bubble-media { padding: 0.4rem !important; }
.media-img { max-width: 200px; max-height: 180px; border-radius: 0.75rem; object-fit: cover; display: block; }
.media-video { max-width: 240px; width: 100%; border-radius: 0.75rem; display: block; background: #000; }
.media-name { font-size: 0.65rem; opacity: 0.7; margin-top: 0.25rem; padding: 0 0.25rem; }

/* File chip */
.file-chip { display: flex; align-items: center; gap: 0.4rem; }
.file-chip-icon {
	padding: 0.2rem 0.35rem; border-radius: 0.25rem;
	font-size: 0.6rem; font-weight: 800;
	background: rgba(255,255,255,0.2); flex-shrink: 0;
}
.file-chip-icon.pdf { background: #fee2e2; color: #dc2626; }
.bubble--customer .file-chip-icon { background: #e0e7ff; color: #4f46e5; }
.file-chip-name { font-size: 0.75rem; }
.audio-player { width: 100%; margin-top: 0.4rem; height: 32px; }

/* Product bubble */
.bubble-product { padding: 0.5rem !important; min-width: 200px; }
.bubble--staff-light { background: #eef2ff; color: #1f2937; border: 1px solid #c7d2fe; border-bottom-right-radius: 0.25rem; }
.product-card { display: flex; align-items: flex-start; gap: 0.6rem; margin-bottom: 0.5rem; }
.product-card-icon {
	width: 36px; height: 36px; border-radius: 0.5rem;
	background: #e0e7ff; display: flex; align-items: center; justify-content: center;
	color: #4f46e5; flex-shrink: 0;
}
.product-card-body { flex: 1; min-width: 0; }
.product-card-name { font-size: 0.8125rem; font-weight: 700; color: #111827; line-height: 1.3; }
.product-card-cat  { font-size: 0.65rem; color: #6b7280; margin-top: 0.1rem; }
.product-card-price { font-size: 0.875rem; font-weight: 800; color: #4f46e5; margin-top: 0.2rem; }
.product-order-btn {
	width: 100%; display: flex; align-items: center; justify-content: center; gap: 0.3rem;
	background: #4f46e5; color: #fff; border: none; border-radius: 0.5rem;
	padding: 0.4rem; font-size: 0.7rem; font-weight: 700; cursor: pointer; transition: background 0.15s;
}
.product-order-btn:hover { background: #4338ca; }

/* ── Product Picker Modal ───────────────────────────────────────────────── */
.modal-backdrop {
	position: fixed; inset: 0; background: rgba(0,0,0,0.45);
	z-index: 100; display: flex; align-items: flex-end;
	justify-content: center; padding: 0;
}
.product-modal {
	background: #fff; width: 100%; max-width: 520px;
	border-radius: 1.25rem 1.25rem 0 0;
	max-height: 75vh; display: flex; flex-direction: column;
	box-shadow: 0 -4px 32px rgba(0,0,0,0.12);
	animation: slide-up 0.25s ease;
}
@keyframes slide-up { from { transform: translateY(40px); opacity: 0; } to { transform: none; opacity: 1; } }
.product-modal-header {
	display: flex; justify-content: space-between; align-items: flex-start;
	padding: 1.25rem 1.25rem 0.75rem; border-bottom: 1px solid #f3f4f6;
}
.product-modal-title { font-size: 1rem; font-weight: 800; color: #111827; }
.product-modal-sub   { font-size: 0.75rem; color: #9ca3af; margin-top: 0.1rem; }
.modal-close {
	width: 28px; height: 28px; border-radius: 50%; border: 1px solid #e5e7eb;
	background: #f9fafb; color: #6b7280; cursor: pointer;
	display: flex; align-items: center; justify-content: center; flex-shrink: 0;
}
.product-search-wrap { position: relative; padding: 0.75rem 1.25rem 0.5rem; }
.product-search-icon { position: absolute; left: 1.85rem; top: 50%; transform: translateY(-50%); width: 14px; height: 14px; color: #9ca3af; }
.product-search-input {
	width: 100%; padding: 0.5rem 0.75rem 0.5rem 2.2rem;
	border: 1px solid #e5e7eb; border-radius: 0.75rem;
	background: #f9fafb; font-size: 0.875rem; outline: none;
}
.product-search-input:focus { border-color: #6366f1; box-shadow: 0 0 0 2px #e0e7ff; }
.product-list { overflow-y: auto; flex: 1; padding: 0.25rem 0.75rem 1rem; }
.product-row {
	width: 100%; display: flex; align-items: center; gap: 0.75rem;
	padding: 0.65rem 0.5rem; border: none; background: none;
	cursor: pointer; border-radius: 0.75rem; transition: background 0.12s; text-align: left;
}
.product-row:hover { background: #f5f5ff; }
.product-row-icon {
	width: 36px; height: 36px; border-radius: 0.6rem;
	background: #eef2ff; display: flex; align-items: center; justify-content: center; flex-shrink: 0;
}
.product-row-body { flex: 1; min-width: 0; }
.product-row-name-row { display: flex; align-items: center; gap: 0.35rem; }
.product-row-name { font-size: 0.8125rem; font-weight: 600; color: #111827; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.product-row-meta { font-size: 0.65rem; color: #9ca3af; margin-top: 0.1rem; }
.product-row-price { font-size: 0.8125rem; font-weight: 700; color: #4f46e5; white-space: nowrap; flex-shrink: 0; }
.product-row-price.discounted { color: #16a34a; }
.product-row-price-col { display: flex; flex-direction: column; align-items: flex-end; flex-shrink: 0; gap: 0.05rem; }
.product-row-original { font-size: 0.65rem; color: #9ca3af; text-decoration: line-through; }
.product-row-wrap { border-bottom: 1px solid #f9fafb; }

/* POM badge */
.pom-badge {
	display: inline-block; padding: 0.1rem 0.35rem; border-radius: 0.3rem;
	font-size: 0.55rem; font-weight: 800; letter-spacing: 0.04em;
	background: #fef3c7; color: #d97706; border: 1px solid #fde68a; flex-shrink: 0;
}

/* Discount row */
.discount-row {
	display: flex; align-items: center; gap: 0.5rem;
	padding: 0.3rem 0.5rem 0.5rem 0.5rem;
	background: #fafafa;
}
.disc-label { font-size: 0.65rem; color: #6b7280; font-weight: 600; white-space: nowrap; }
.disc-input-wrap { display: flex; align-items: center; gap: 0.2rem; }
.disc-input {
	width: 52px; padding: 0.2rem 0.35rem; text-align: center;
	font-size: 0.75rem; font-weight: 700; border: 1px solid #e5e7eb;
	border-radius: 0.4rem; background: #fff; outline: none; color: #111827;
	transition: border-color 0.15s;
}
.disc-input:focus { border-color: #6366f1; }
.disc-pct-label { font-size: 0.7rem; color: #6b7280; font-weight: 700; }
.disc-preview { font-size: 0.75rem; font-weight: 800; color: #16a34a; }
.disc-allowed-badge {
	display: inline-block; margin-left: 0.4rem; padding: 0.1rem 0.4rem;
	background: #dcfce7; color: #16a34a; border-radius: 0.3rem;
	font-size: 0.6rem; font-weight: 700; letter-spacing: 0.03em; border: 1px solid #bbf7d0;
}

/* Product card pricing */
.product-card-pricing { display: flex; align-items: center; gap: 0.35rem; margin-top: 0.2rem; flex-wrap: wrap; }
.product-original-price { font-size: 0.7rem; color: #9ca3af; text-decoration: line-through; }
.product-disc-badge {
	padding: 0.1rem 0.35rem; border-radius: 0.3rem;
	font-size: 0.6rem; font-weight: 800; background: #dcfce7; color: #16a34a;
	border: 1px solid #bbf7d0;
}

@media (min-width: 640px) {
	.modal-backdrop { align-items: center; }
	.product-modal { border-radius: 1.25rem; max-height: 80vh; }
}

.closed-bar {
	background: #f9fafb; border-top: 1px solid #e5e7eb;
	padding: 0.75rem; text-align: center; font-size: 0.8125rem; color: #9ca3af; flex-shrink: 0;
}
.empty-state { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 0.5rem; color: #9ca3af; padding: 3rem; }

/* ══ MOBILE ════════════════════════════════════════════════════════════ */
@media (max-width: 1023px) {

	/* Both panels fill the full screen; we toggle which is visible */
	.conv-panel,
	.chat-panel {
		position: absolute;
		inset: 0;
		width: 100%;
	}

	/* The one not active gets pushed off-screen (smooth slide) */
	.conv-panel { transform: translateX(0); transition: transform 0.3s ease; z-index: 1; }
	.chat-panel { transform: translateX(100%); transition: transform 0.3s ease; z-index: 2; }

	/* When mobile-hidden is applied to a panel, slide it off-screen */
	.conv-panel.mobile-hidden { transform: translateX(-100%); }
	.chat-panel.mobile-hidden { transform: translateX(100%); }

	/* Show back button on mobile */
	.back-btn { display: flex; }
}

@media (min-width: 1024px) {
	/* On desktop always show both; ignore mobile-hidden */
	.conv-panel, .chat-panel { position: static; transform: none !important; width: auto; }
	.chat-panel.mobile-hidden { display: flex; }
	.conv-panel.mobile-hidden { display: flex; }
}

/* ── Emoji Picker ───────────────────────────────────────────────────────── */
.emoji-panel {
	border-top: 1px solid #f0f0f0;
	border-bottom: 1px solid #f0f0f0;
	background: #fff;
	animation: slide-up-quick 0.15s ease;
}
@keyframes slide-up-quick { from { opacity: 0; transform: translateY(6px); } to { opacity: 1; transform: none; } }

.emoji-tabs {
	display: flex; gap: 0; overflow-x: auto; scrollbar-width: none;
	border-bottom: 1px solid #f3f4f6; padding: 0 0.25rem;
}
.emoji-tabs::-webkit-scrollbar { display: none; }
.emoji-tab {
	flex-shrink: 0; padding: 0.35rem 0.6rem; border: none;
	background: none; cursor: pointer; font-size: 1rem;
	border-bottom: 2px solid transparent; transition: border-color 0.15s, background 0.12s;
	border-radius: 0.25rem 0.25rem 0 0;
}
.emoji-tab:hover { background: #f9fafb; }
.emoji-tab--active { border-bottom-color: #6366f1; background: #f5f5ff; }

.emoji-grid {
	display: grid;
	grid-template-columns: repeat(auto-fill, minmax(32px, 1fr));
	gap: 2px;
	padding: 0.4rem 0.5rem;
	max-height: 160px;
	overflow-y: auto;
	scrollbar-width: thin;
	scrollbar-color: #e5e7eb transparent;
}
.emoji-grid::-webkit-scrollbar { width: 4px; }
.emoji-grid::-webkit-scrollbar-thumb { background: #e5e7eb; border-radius: 2px; }

.emoji-btn {
	width: 32px; height: 32px; border: none; background: none;
	cursor: pointer; font-size: 1.1rem; border-radius: 0.35rem;
	display: flex; align-items: center; justify-content: center;
	transition: background 0.1s, transform 0.1s;
	line-height: 1;
}
.emoji-btn:hover  { background: #f0f0ff; transform: scale(1.25); }
.emoji-btn:active { transform: scale(0.9); }

/* ── Referral Card ──────────────────────────────────────────────────────── */
.referral-bubble {
	width: 240px; background: #fff; border: 1px solid #eef2ff;
	border-radius: 1.25rem; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.05);
	margin: 0.5rem 0;
}
.ref-header {
	background: #f8faff; padding: 0.6rem 0.85rem;
	display: flex; align-items: center; gap: 0.5rem; border-bottom: 1px solid #f0f4ff;
}
.ref-icon-wrap {
	width: 24px; height: 24px; border-radius: 50%;
	background: #eef2ff; color: #6366f1;
	display: flex; align-items: center; justify-content: center;
}
.ref-tag { font-size: 0.7rem; font-weight: 800; color: #6366f1; text-transform: uppercase; letter-spacing: 0.02em; }
.ref-body { padding: 1rem; }
.ref-doctor { display: flex; gap: 0.75rem; margin-bottom: 1rem; }
.ref-avatar {
	width: 48px; height: 48px; border-radius: 1rem;
	background: #f3f4f6; color: #9ca3af;
	display: flex; align-items: center; justify-content: center; flex-shrink: 0;
	overflow: hidden;
}
.ref-avatar img { width: 100%; height: 100%; object-fit: cover; }
.ref-info { min-width: 0; }
.ref-name { font-size: 0.875rem; font-weight: 700; color: #111827; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.ref-spec { font-size: 0.75rem; color: #6b7280; font-weight: 500; }
.ref-clinic { font-size: 0.65rem; color: #9ca3af; margin-top: 0.1rem; }

.ref-action-btn {
	width: 100%; padding: 0.65rem; border-radius: 0.75rem;
	background: #4f46e5; color: #fff; border: none;
	font-size: 0.8125rem; font-weight: 700; cursor: pointer;
	display: flex; align-items: center; justify-content: center; gap: 0.4rem;
	transition: background 0.15s;
}
.ref-action-btn:hover { background: #4338ca; }

.attach-opt-icon.ref { background: #fdf2f8; color: #db2777; }

</style>