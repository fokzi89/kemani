<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { fade, scale } from 'svelte/transition';
	import {
		CheckCircle2, Circle, Clock, AlertTriangle, Zap, Plus, X,
		User, Calendar, RefreshCw, ChevronDown, Search, Filter,
		Loader2, Building2, Trash2, Edit3, CheckCheck
	} from 'lucide-svelte';

	// ── State ─────────────────────────────────────────────────────────────
	let tasks: any[] = $state([]);
	let staffList: any[] = $state([]);
	let loading = $state(true);
	let saving = $state(false);

	let staffId = $state('');
	let tenantId = $state('');
	let userRole = $state('');

	// Filters
	let statusFilter = $state('all');
	let priorityFilter = $state('all');
	let searchQuery = $state('');

	// Modal
	let showModal = $state(false);
	let editingTask: any = $state(null);
	let form = $state({
		title: '', description: '', priority: 'medium',
		assignee_id: '', due_date: ''
	});

	// ── Priority config ────────────────────────────────────────────────────
	const PRIORITY = {
		urgent: { label: 'Urgent', color: 'text-red-700 bg-red-100 border-red-200', dot: 'bg-red-500' },
		high:   { label: 'High',   color: 'text-orange-700 bg-orange-100 border-orange-200', dot: 'bg-orange-500' },
		medium: { label: 'Medium', color: 'text-amber-700 bg-amber-100 border-amber-200', dot: 'bg-amber-400' },
		low:    { label: 'Low',    color: 'text-green-700 bg-green-100 border-green-200', dot: 'bg-green-500' },
	} as Record<string, any>;

	const STATUS = {
		todo:        { label: 'To Do',       color: 'text-gray-600 bg-gray-100', icon: Circle },
		in_progress: { label: 'In Progress', color: 'text-blue-700 bg-blue-100', icon: Clock },
		completed:   { label: 'Done',        color: 'text-emerald-700 bg-emerald-100', icon: CheckCircle2 },
		cancelled:   { label: 'Cancelled',   color: 'text-gray-400 bg-gray-50', icon: X },
	} as Record<string, any>;

	const isAdmin = $derived(['tenant_admin', 'branch_manager'].includes(userRole));

	// ── Lifecycle ─────────────────────────────────────────────────────────
	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();
		if (!session) return;
		staffId = session.user.id;

		const { data: u } = await supabase.from('users')
			.select('tenant_id, role').eq('id', staffId).single();
		if (u) { tenantId = u.tenant_id; userRole = u.role; }

		await Promise.all([loadTasks(), loadStaff()]);
		loading = false;
	});

	async function loadTasks() {
		const { data, error } = await supabase.from('staff_tasks')
			.select(`*, creator:users!staff_tasks_creator_id_fkey(full_name, avatar_url),
				assignee:users!staff_tasks_assignee_id_fkey(full_name, avatar_url)`)
			.eq('tenant_id', tenantId)
			.order('created_at', { ascending: false });
		if (!error) tasks = data || [];
	}

	async function loadStaff() {
		const { data } = await supabase.from('users')
			.select('id, full_name, role, branches(name)')
			.eq('tenant_id', tenantId).order('full_name');
		staffList = data || [];
	}

	// ── Filtered tasks ─────────────────────────────────────────────────────
	let filtered = $derived(tasks.filter(t => {
		const q = searchQuery.toLowerCase();
		const matchSearch = !q || t.title.toLowerCase().includes(q) ||
			(t.description || '').toLowerCase().includes(q) ||
			(t.assignee?.full_name || '').toLowerCase().includes(q);
		const matchStatus = statusFilter === 'all' || t.status === statusFilter;
		const matchPriority = priorityFilter === 'all' || t.priority === priorityFilter;
		return matchSearch && matchStatus && matchPriority;
	}));

	// ── Summary counts ─────────────────────────────────────────────────────
	let counts = $derived({
		todo: tasks.filter(t => t.status === 'todo').length,
		in_progress: tasks.filter(t => t.status === 'in_progress').length,
		completed: tasks.filter(t => t.status === 'completed').length,
		urgent: tasks.filter(t => t.priority === 'urgent' && t.status !== 'completed').length,
	});

	// ── Actions ───────────────────────────────────────────────────────────
	function openCreate() {
		editingTask = null;
		form = { title: '', description: '', priority: 'medium', assignee_id: '', due_date: '' };
		showModal = true;
	}

	function openEdit(task: any) {
		editingTask = task;
		form = {
			title: task.title,
			description: task.description || '',
			priority: task.priority,
			assignee_id: task.assignee_id || '',
			due_date: task.due_date ? task.due_date.slice(0, 10) : ''
		};
		showModal = true;
	}

	async function saveTask() {
		if (!form.title.trim()) return;
		saving = true;
		const payload: any = {
			title: form.title.trim(),
			description: form.description.trim() || null,
			priority: form.priority,
			assignee_id: form.assignee_id || null,
			due_date: form.due_date || null,
		};

		if (editingTask) {
			const { error } = await supabase.from('staff_tasks')
				.update({ ...payload, updated_at: new Date().toISOString() })
				.eq('id', editingTask.id);
			if (!error) await loadTasks();
		} else {
			const { error } = await supabase.from('staff_tasks')
				.insert({ ...payload, tenant_id: tenantId, creator_id: staffId, status: 'todo' });
			if (!error) await loadTasks();
		}
		saving = false;
		showModal = false;
	}

	async function updateStatus(task: any, status: string) {
		await supabase.from('staff_tasks').update({ status, updated_at: new Date().toISOString() }).eq('id', task.id);
		tasks = tasks.map(t => t.id === task.id ? { ...t, status } : t);
	}

	async function deleteTask(task: any) {
		if (!confirm('Delete this task?')) return;
		await supabase.from('staff_tasks').delete().eq('id', task.id);
		tasks = tasks.filter(t => t.id !== task.id);
	}

	function relativeDate(d: string) {
		if (!d) return '';
		const diff = new Date(d).getTime() - Date.now();
		const days = Math.ceil(diff / 86400000);
		if (days < 0) return `${Math.abs(days)}d overdue`;
		if (days === 0) return 'Due today';
		if (days === 1) return 'Due tomorrow';
		return `Due in ${days}d`;
	}

	function isOverdue(task: any) {
		return task.due_date && new Date(task.due_date) < new Date() && task.status !== 'completed';
	}
</script>

<svelte:head><title>Task Manager – Kemani POS</title></svelte:head>

<div class="page">
	<!-- Header -->
	<div class="page-header">
		<div>
			<h1 class="page-title">Task Manager</h1>
			<p class="page-sub">Assign and track operational tasks across your organization</p>
		</div>
		{#if isAdmin}
			<button onclick={openCreate} class="btn-primary">
				<Plus class="h-4 w-4" /> New Task
			</button>
		{/if}
	</div>

	<!-- Summary Cards -->
	<div class="summary-grid">
		{#each [
			{ label: 'To Do', value: counts.todo, color: 'from-slate-50 to-slate-100 border-slate-200', text: 'text-slate-700' },
			{ label: 'In Progress', value: counts.in_progress, color: 'from-blue-50 to-blue-100 border-blue-200', text: 'text-blue-700' },
			{ label: 'Completed', value: counts.completed, color: 'from-emerald-50 to-emerald-100 border-emerald-200', text: 'text-emerald-700' },
			{ label: 'Urgent', value: counts.urgent, color: 'from-red-50 to-red-100 border-red-200', text: 'text-red-700' },
		] as card}
			<div class="summary-card bg-gradient-to-br {card.color}">
				<p class="summary-label">{card.label}</p>
				<p class="summary-value {card.text}">{card.value}</p>
			</div>
		{/each}
	</div>

	<!-- Filters -->
	<div class="filters-bar">
		<div class="search-wrap">
			<Search class="search-icon" />
			<input type="text" bind:value={searchQuery} placeholder="Search tasks..." class="search-input" />
		</div>
		<div class="filter-pills">
			{#each [['all','All'],['todo','To Do'],['in_progress','In Progress'],['completed','Done']] as [v,l]}
				<button onclick={() => statusFilter = v}
					class="filter-pill {statusFilter === v ? 'filter-pill--active' : ''}">{l}</button>
			{/each}
		</div>
		<select bind:value={priorityFilter} class="priority-select">
			<option value="all">All Priorities</option>
			{#each Object.entries(PRIORITY) as [v, p]}<option value={v}>{p.label}</option>{/each}
		</select>
	</div>

	<!-- Task List -->
	{#if loading}
		<div class="loading-state">
			<Loader2 class="h-8 w-8 animate-spin text-indigo-500" />
			<p>Loading tasks...</p>
		</div>
	{:else if filtered.length === 0}
		<div class="empty-state">
			<CheckCheck class="h-12 w-12 text-gray-300" />
			<p class="text-gray-500 font-medium">No tasks found</p>
			{#if isAdmin}<button onclick={openCreate} class="btn-outline mt-2">Create your first task</button>{/if}
		</div>
	{:else}
		<div class="task-list">
			{#each filtered as task (task.id)}
				<div class="task-card {task.status === 'completed' ? 'opacity-60' : ''}" transition:fade>
					<!-- Priority dot + status toggle -->
					<div class="task-left">
						<button onclick={() => {
							const next = { todo: 'in_progress', in_progress: 'completed', completed: 'todo', cancelled: 'todo' };
							updateStatus(task, next[task.status as keyof typeof next] || 'todo');
						}} class="status-toggle" title="Click to advance status">
							{#if task.status === 'completed'}
								<CheckCircle2 class="h-5 w-5 text-emerald-500" />
							{:else if task.status === 'in_progress'}
								<Clock class="h-5 w-5 text-blue-500" />
							{:else}
								<Circle class="h-5 w-5 text-gray-300" />
							{/if}
						</button>
						<span class="priority-dot {PRIORITY[task.priority]?.dot || 'bg-gray-400'}"></span>
					</div>

					<!-- Content -->
					<div class="task-content">
						<div class="task-top">
							<p class="task-title {task.status === 'completed' ? 'line-through text-gray-400' : ''}">{task.title}</p>
							<div class="task-badges">
								<span class="badge {PRIORITY[task.priority]?.color}">{PRIORITY[task.priority]?.label}</span>
								<span class="badge {STATUS[task.status]?.color}">{STATUS[task.status]?.label}</span>
							</div>
						</div>
						{#if task.description}
							<p class="task-desc">{task.description}</p>
						{/if}
						<div class="task-meta">
							{#if task.assignee}
								<div class="meta-chip">
									<User class="h-3 w-3" />
									<span>{task.assignee.full_name}</span>
								</div>
							{:else}
								<div class="meta-chip text-gray-400"><User class="h-3 w-3" /><span>Unassigned</span></div>
							{/if}
							{#if task.due_date}
								<div class="meta-chip {isOverdue(task) ? 'text-red-600' : ''}">
									<Calendar class="h-3 w-3" />
									<span>{relativeDate(task.due_date)}</span>
								</div>
							{/if}
							<div class="meta-chip text-gray-400">
								<span>by {task.creator?.full_name || 'Unknown'}</span>
							</div>
						</div>
					</div>

					<!-- Actions -->
					{#if isAdmin || task.assignee_id === staffId}
						<div class="task-actions">
							<button onclick={() => openEdit(task)} class="action-btn" title="Edit">
								<Edit3 class="h-4 w-4" />
							</button>
							{#if isAdmin}
								<button onclick={() => deleteTask(task)} class="action-btn text-red-400 hover:text-red-600" title="Delete">
									<Trash2 class="h-4 w-4" />
								</button>
							{/if}
						</div>
					{/if}
				</div>
			{/each}
		</div>
	{/if}
</div>

<!-- Create/Edit Modal -->
{#if showModal}
	<div class="modal-overlay" transition:fade onclick={() => showModal = false}>
		<div class="modal" transition:scale={{ start: 0.96, duration: 200 }} onclick={e => e.stopPropagation()}>
			<div class="modal-header">
				<h2>{editingTask ? 'Edit Task' : 'New Task'}</h2>
				<button onclick={() => showModal = false} class="icon-btn"><X class="h-5 w-5" /></button>
			</div>
			<div class="modal-body">
				<div class="field">
					<label>Title <span class="text-red-500">*</span></label>
					<input type="text" bind:value={form.title} placeholder="Task title..." class="input" />
				</div>
				<div class="field">
					<label>Description</label>
					<textarea bind:value={form.description} placeholder="Details about this task..." class="input" rows="3"></textarea>
				</div>
				<div class="field-row">
					<div class="field">
						<label>Priority</label>
						<select bind:value={form.priority} class="input">
							{#each Object.entries(PRIORITY) as [v, p]}<option value={v}>{p.label}</option>{/each}
						</select>
					</div>
					<div class="field">
						<label>Due Date</label>
						<input type="date" bind:value={form.due_date} class="input" />
					</div>
				</div>
				<div class="field">
					<label>Assign To</label>
					<select bind:value={form.assignee_id} class="input">
						<option value="">Unassigned</option>
						{#each staffList as s}
							<option value={s.id}>{s.full_name} — {s.role.replace('_',' ')}</option>
						{/each}
					</select>
				</div>
			</div>
			<div class="modal-footer">
				<button onclick={() => showModal = false} class="btn-outline">Cancel</button>
				<button onclick={saveTask} disabled={saving || !form.title.trim()} class="btn-primary">
					{#if saving}<Loader2 class="h-4 w-4 animate-spin" />{/if}
					{editingTask ? 'Save Changes' : 'Create Task'}
				</button>
			</div>
		</div>
	</div>
{/if}

<style>
	@reference "../../app.css";

	.page { @apply p-6 max-w-5xl mx-auto space-y-6; }
	.page-header { @apply flex items-start justify-between; }
	.page-title { @apply text-xl font-bold text-gray-900 tracking-tight; }
	.page-sub { @apply text-sm text-gray-500 mt-1; }

	.summary-grid { @apply grid grid-cols-2 lg:grid-cols-4 gap-4; }
	.summary-card { @apply rounded-2xl border p-4; }
	.summary-label { @apply text-xs font-bold text-gray-500 uppercase tracking-widest; }
	.summary-value { @apply text-2xl font-bold mt-1; }

	.filters-bar { @apply flex flex-wrap gap-3 items-center; }
	.search-wrap { @apply relative flex-1 min-w-48; }
	.search-icon { @apply absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400; }
	.search-input { @apply w-full pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-xl bg-gray-50 outline-none focus:ring-2 focus:ring-indigo-400; }
	.filter-pills { @apply flex gap-1; }
	.filter-pill { @apply px-3 py-1.5 text-xs font-bold rounded-lg bg-gray-100 text-gray-500 hover:bg-gray-200 transition-colors; }
	.filter-pill--active { @apply bg-indigo-600 text-white; }
	.priority-select { @apply text-xs font-bold border border-gray-200 rounded-xl px-3 py-2 bg-gray-50 outline-none; }

	.loading-state { @apply flex flex-col items-center justify-center py-20 gap-3 text-gray-400; }
	.empty-state { @apply flex flex-col items-center justify-center py-20 gap-2; }

	.task-list { @apply space-y-3; }
	.task-card { @apply bg-white rounded-2xl border border-gray-100 p-4 flex gap-4 shadow-sm hover:shadow-md transition-shadow; }
	.task-left { @apply flex flex-col items-center gap-2 shrink-0 pt-0.5; }
	.status-toggle { @apply hover:scale-110 transition-transform; }
	.priority-dot { @apply h-2 w-2 rounded-full; }

	.task-content { @apply flex-1 min-w-0; }
	.task-top { @apply flex items-start justify-between gap-3 flex-wrap; }
	.task-title { @apply text-sm font-bold text-gray-900; }
	.task-badges { @apply flex gap-2 flex-wrap; }
	.badge { @apply text-[10px] font-black uppercase px-2 py-0.5 rounded-lg border tracking-wide; }
	.task-desc { @apply text-xs text-gray-500 mt-1 line-clamp-2; }
	.task-meta { @apply flex flex-wrap gap-3 mt-2; }
	.meta-chip { @apply flex items-center gap-1 text-[11px] font-medium text-gray-500; }

	.task-actions { @apply flex flex-col gap-1 shrink-0; }
	.action-btn { @apply p-1.5 rounded-lg text-gray-400 hover:bg-gray-100 hover:text-gray-700 transition-colors; }

	/* Modal */
	.modal-overlay { @apply fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4; }
	.modal { @apply bg-white rounded-3xl w-full max-w-lg shadow-2xl border border-gray-100 overflow-hidden; }
	.modal-header { @apply flex items-center justify-between p-6 border-b; }
	.modal-header h2 { @apply text-lg font-bold text-gray-900; }
	.modal-body { @apply p-6 space-y-4; }
	.modal-footer { @apply flex items-center justify-end gap-3 p-6 border-t bg-gray-50/50; }

	.field { @apply flex flex-col gap-1.5 flex-1; }
	.field-row { @apply flex gap-4; }
	.field label { @apply text-xs font-bold text-gray-600 uppercase tracking-wide; }
	.input { @apply w-full border border-gray-200 rounded-xl px-3 py-2.5 text-sm bg-gray-50 outline-none focus:ring-2 focus:ring-indigo-400 transition-all; }

	.btn-primary { @apply flex items-center gap-2 px-5 py-2.5 bg-indigo-600 text-white text-sm font-bold rounded-xl hover:bg-indigo-700 transition-colors shadow-lg shadow-indigo-200 disabled:opacity-50; }
	.btn-outline { @apply px-5 py-2.5 text-sm font-bold border border-gray-200 rounded-xl hover:bg-gray-50 transition-colors; }
	.icon-btn { @apply p-2 rounded-xl hover:bg-gray-100 text-gray-500 transition-colors; }
</style>
