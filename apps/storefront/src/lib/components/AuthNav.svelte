<script lang="ts">
	import { goto } from '$app/navigation';
	import { isAuthenticated, currentUser } from '$lib/stores/auth';
	import { AuthService } from '$lib/services/auth';
	import { authStore } from '$lib/stores/auth';

	let showDropdown = false;

	async function handleLogout() {
		const { error } = await AuthService.signOut();
		if (!error) {
			authStore.clearAuth();
			goto('/');
		}
	}

	function toggleDropdown() {
		showDropdown = !showDropdown;
	}

	// Close dropdown when clicking outside
	function handleClickOutside(event: MouseEvent) {
		const target = event.target as HTMLElement;
		if (!target.closest('.user-dropdown')) {
			showDropdown = false;
		}
	}
</script>

<svelte:window on:click={handleClickOutside} />

<div class="flex items-center gap-4">
	{#if $isAuthenticated}
		<!-- User dropdown -->
		<div class="relative user-dropdown">
			<button
				on:click|stopPropagation={toggleDropdown}
				class="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition"
			>
				<div class="w-8 h-8 rounded-full bg-blue-600 dark:bg-blue-500 flex items-center justify-center text-white font-semibold">
					{$currentUser?.email?.charAt(0).toUpperCase() || 'U'}
				</div>
				<span class="hidden sm:inline text-gray-900 dark:text-white">
					{$currentUser?.email?.split('@')[0] || 'User'}
				</span>
				<svg
					class="w-4 h-4 text-gray-600 dark:text-gray-400 transition-transform {showDropdown ? 'rotate-180' : ''}"
					fill="none"
					stroke="currentColor"
					viewBox="0 0 24 24"
				>
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
				</svg>
			</button>

			{#if showDropdown}
				<div class="absolute right-0 mt-2 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 py-1 z-50">
					<a
						href="/profile"
						class="block px-4 py-2 text-gray-900 dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700 transition"
					>
						My Profile
					</a>
					<a
						href="/orders"
						class="block px-4 py-2 text-gray-900 dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700 transition"
					>
						My Orders
					</a>
					<hr class="my-1 border-gray-200 dark:border-gray-700" />
					<button
						on:click={handleLogout}
						class="w-full text-left px-4 py-2 text-red-600 dark:text-red-400 hover:bg-gray-100 dark:hover:bg-gray-700 transition"
					>
						Sign Out
					</button>
				</div>
			{/if}
		</div>
	{:else}
		<!-- Login button -->
		<a
			href="/auth/portal"
			class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-medium"
		>
			Sign In
		</a>
	{/if}
</div>
