<script lang="ts">
	import { Bell, Calendar, FileText, AlertCircle, CheckCircle, X } from 'lucide-svelte';

	// Sample notifications - in production, fetch from Supabase
	let notifications = $state([
		{
			id: '1',
			type: 'appointment',
			title: 'Upcoming Consultation',
			message: 'You have a video consultation with Dr. Michael Chen tomorrow at 10:00 AM',
			timestamp: '2026-03-17T15:30:00',
			read: false,
			action_url: '/consultations/2'
		},
		{
			id: '2',
			type: 'prescription',
			title: 'Prescription Ready',
			message: 'Your prescription from Dr. Sarah Johnson is ready for pickup at Fokz Pharmacy',
			timestamp: '2026-03-15T14:00:00',
			read: false,
			action_url: '/prescriptions'
		},
		{
			id: '3',
			type: 'reminder',
			title: 'Medication Reminder',
			message: 'Time to take your Lisinopril 10mg medication',
			timestamp: '2026-03-15T08:00:00',
			read: true,
			action_url: null
		},
		{
			id: '4',
			type: 'consultation_complete',
			title: 'Consultation Completed',
			message: 'Your consultation with Dr. Sarah Johnson has been completed. View your prescription.',
			timestamp: '2026-03-10T15:00:00',
			read: true,
			action_url: '/consultations/1'
		}
	]);

	function formatTimestamp(timestamp: string): string {
		const date = new Date(timestamp);
		const now = new Date();
		const diffMs = now.getTime() - date.getTime();
		const diffMins = Math.floor(diffMs / 60000);
		const diffHours = Math.floor(diffMins / 60);
		const diffDays = Math.floor(diffHours / 24);

		if (diffMins < 60) {
			return `${diffMins} minute${diffMins !== 1 ? 's' : ''} ago`;
		} else if (diffHours < 24) {
			return `${diffHours} hour${diffHours !== 1 ? 's' : ''} ago`;
		} else if (diffDays < 7) {
			return `${diffDays} day${diffDays !== 1 ? 's' : ''} ago`;
		} else {
			return date.toLocaleDateString('en-NG', {
				year: 'numeric',
				month: 'short',
				day: 'numeric'
			});
		}
	}

	function getNotificationIcon(type: string) {
		const icons: Record<string, any> = {
			appointment: Calendar,
			prescription: FileText,
			reminder: Bell,
			consultation_complete: CheckCircle,
			alert: AlertCircle
		};
		return icons[type] || Bell;
	}

	function getNotificationColor(type: string): string {
		const colors: Record<string, string> = {
			appointment: 'bg-blue-100 text-blue-600',
			prescription: 'bg-purple-100 text-purple-600',
			reminder: 'bg-yellow-100 text-yellow-600',
			consultation_complete: 'bg-green-100 text-green-600',
			alert: 'bg-red-100 text-red-600'
		};
		return colors[type] || 'bg-gray-100 text-gray-600';
	}

	function markAsRead(id: string) {
		notifications = notifications.map(n =>
			n.id === id ? { ...n, read: true } : n
		);
	}

	function deleteNotification(id: string) {
		notifications = notifications.filter(n => n.id !== id);
	}

	function markAllAsRead() {
		notifications = notifications.map(n => ({ ...n, read: true }));
	}

	let unreadCount = $derived(notifications.filter(n => !n.read).length);
</script>

<svelte:head>
	<title>Notifications | Kemani Health</title>
</svelte:head>

<div class="py-6 px-4 sm:px-6 lg:px-8">
	<div class="max-w-4xl mx-auto">
		<!-- Header -->
		<div class="mb-8 flex items-center justify-between">
			<div>
				<h1 class="text-3xl font-bold text-gray-900">Notifications</h1>
				<p class="mt-2 text-gray-600">
					{#if unreadCount > 0}
						You have {unreadCount} unread notification{unreadCount !== 1 ? 's' : ''}
					{:else}
						All caught up!
					{/if}
				</p>
			</div>
			{#if unreadCount > 0}
				<button
					onclick={markAllAsRead}
					class="text-sm text-blue-600 hover:underline"
				>
					Mark all as read
				</button>
			{/if}
		</div>

		<!-- Notifications List -->
		{#if notifications.length === 0}
			<div class="bg-white rounded-lg shadow p-12 text-center">
				<Bell class="w-16 h-16 mx-auto mb-4 text-gray-400" />
				<h3 class="text-xl font-semibold text-gray-900 mb-2">No Notifications</h3>
				<p class="text-gray-600">You're all caught up! Check back later for updates.</p>
			</div>
		{:else}
			<div class="space-y-4">
				{#each notifications as notification}
					<div
						class="bg-white rounded-lg shadow hover:shadow-md transition {notification.read ? '' : 'border-l-4 border-blue-500'}"
					>
						<div class="p-6">
							<div class="flex items-start gap-4">
								<!-- Icon -->
								<div class="flex-shrink-0">
									<div class="w-12 h-12 rounded-lg {getNotificationColor(notification.type)} flex items-center justify-center">
										<svelte:component this={getNotificationIcon(notification.type)} class="w-6 h-6" />
									</div>
								</div>

								<!-- Content -->
								<div class="flex-1 min-w-0">
									<div class="flex items-start justify-between gap-4">
										<div class="flex-1">
											<h3 class="text-lg font-semibold text-gray-900 {notification.read ? '' : 'font-bold'}">
												{notification.title}
											</h3>
											<p class="mt-1 text-sm text-gray-600">
												{notification.message}
											</p>
											<p class="mt-2 text-xs text-gray-500">
												{formatTimestamp(notification.timestamp)}
											</p>
										</div>

										<!-- Delete Button -->
										<button
											onclick={() => deleteNotification(notification.id)}
											class="flex-shrink-0 p-1 text-gray-400 hover:text-gray-600 transition"
											title="Delete notification"
										>
											<X class="w-5 h-5" />
										</button>
									</div>

									<!-- Action Buttons -->
									<div class="mt-4 flex gap-3">
										{#if notification.action_url}
											<a
												href={notification.action_url}
												onclick={() => !notification.read && markAsRead(notification.id)}
												class="text-sm text-blue-600 hover:underline font-medium"
											>
												View Details
											</a>
										{/if}
										{#if !notification.read}
											<button
												onclick={() => markAsRead(notification.id)}
												class="text-sm text-gray-600 hover:underline"
											>
												Mark as read
											</button>
										{/if}
									</div>
								</div>
							</div>
						</div>
					</div>
				{/each}
			</div>
		{/if}
	</div>
</div>
