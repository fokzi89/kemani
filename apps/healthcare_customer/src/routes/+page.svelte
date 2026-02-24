<script lang="ts">
	import { Home, Calendar, User, Bell } from 'lucide-svelte';
</script>

<div class="min-h-screen bg-gray-50">
	<!-- Header -->
	<header class="bg-white shadow">
		<div class="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
			<h1 class="text-3xl font-bold tracking-tight text-gray-900">Healthcare Customer Portal</h1>
		</div>
	</header>

	<!-- Main Content -->
	<main class="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
		<div class="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
			<!-- Dashboard Cards -->
			<a href="/consultations" class="block rounded-lg bg-white p-6 shadow hover:shadow-lg transition-shadow">
				<div class="flex items-center gap-4">
					<div class="rounded-full bg-blue-100 p-3">
						<Calendar class="h-6 w-6 text-blue-600" />
					</div>
					<div>
						<h3 class="text-lg font-semibold text-gray-900">Consultations</h3>
						<p class="text-sm text-gray-500">View and manage</p>
					</div>
				</div>
			</a>

			<a href="/book" class="block rounded-lg bg-white p-6 shadow hover:shadow-lg transition-shadow">
				<div class="flex items-center gap-4">
					<div class="rounded-full bg-green-100 p-3">
						<Home class="h-6 w-6 text-green-600" />
					</div>
					<div>
						<h3 class="text-lg font-semibold text-gray-900">Book Consultation</h3>
						<p class="text-sm text-gray-500">Schedule new</p>
					</div>
				</div>
			</a>

			<a href="/profile" class="block rounded-lg bg-white p-6 shadow hover:shadow-lg transition-shadow">
				<div class="flex items-center gap-4">
					<div class="rounded-full bg-purple-100 p-3">
						<User class="h-6 w-6 text-purple-600" />
					</div>
					<div>
						<h3 class="text-lg font-semibold text-gray-900">Profile</h3>
						<p class="text-sm text-gray-500">Manage account</p>
					</div>
				</div>
			</a>

			<a href="/notifications" class="block rounded-lg bg-white p-6 shadow hover:shadow-lg transition-shadow">
				<div class="flex items-center gap-4">
					<div class="rounded-full bg-yellow-100 p-3">
						<Bell class="h-6 w-6 text-yellow-600" />
					</div>
					<div>
						<h3 class="text-lg font-semibold text-gray-900">Notifications</h3>
						<p class="text-sm text-gray-500">View updates</p>
					</div>
				</div>
			</a>
		</div>

		<!-- Recent Consultations -->
		<div class="mt-8 rounded-lg bg-white p-6 shadow">
			<h2 class="text-xl font-semibold text-gray-900 mb-4">Recent Consultations</h2>
			<p class="text-gray-500">No recent consultations. Book your first consultation to get started.</p>
		</div>
	</main>
</div>
