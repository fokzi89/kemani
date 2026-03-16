<script lang="ts">
	import { Calendar, User, FileText, Bell, Video, MessageSquare, Activity } from 'lucide-svelte';
</script>

<svelte:head>
	<title>Dashboard | Kemani Health</title>
</svelte:head>

<div class="py-6 px-4 sm:px-6 lg:px-8">
	<div class="max-w-7xl mx-auto">
		<!-- Welcome Section -->
		<div class="mb-8">
			<h1 class="text-3xl font-bold text-gray-900">Welcome Back!</h1>
			<p class="mt-2 text-gray-600">Manage your health consultations and medical records</p>
		</div>

		<!-- Quick Actions Grid -->
		<div class="grid gap-6 sm:grid-cols-2 lg:grid-cols-4 mb-8">
			<!-- Book Consultation -->
			<a
				href="/providers"
				class="block rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 p-6 shadow-md hover:shadow-lg transition text-white"
			>
				<div class="flex items-center gap-4">
					<div class="rounded-full bg-white/20 p-3">
						<Calendar class="h-6 w-6" />
					</div>
					<div>
						<h3 class="text-lg font-semibold">Book Consultation</h3>
						<p class="text-sm text-blue-100">Find a provider</p>
					</div>
				</div>
			</a>

			<!-- My Consultations -->
			<a
				href="/consultations"
				class="block rounded-lg bg-white p-6 shadow hover:shadow-lg transition"
			>
				<div class="flex items-center gap-4">
					<div class="rounded-full bg-green-100 p-3">
						<Video class="h-6 w-6 text-green-600" />
					</div>
					<div>
						<h3 class="text-lg font-semibold text-gray-900">Consultations</h3>
						<p class="text-sm text-gray-500">View history</p>
					</div>
				</div>
			</a>

			<!-- Prescriptions -->
			<a
				href="/prescriptions"
				class="block rounded-lg bg-white p-6 shadow hover:shadow-lg transition"
			>
				<div class="flex items-center gap-4">
					<div class="rounded-full bg-purple-100 p-3">
						<FileText class="h-6 w-6 text-purple-600" />
					</div>
					<div>
						<h3 class="text-lg font-semibold text-gray-900">Prescriptions</h3>
						<p class="text-sm text-gray-500">Active & past</p>
					</div>
				</div>
			</a>

			<!-- Profile -->
			<a
				href="/profile"
				class="block rounded-lg bg-white p-6 shadow hover:shadow-lg transition"
			>
				<div class="flex items-center gap-4">
					<div class="rounded-full bg-gray-100 p-3">
						<User class="h-6 w-6 text-gray-600" />
					</div>
					<div>
						<h3 class="text-lg font-semibold text-gray-900">My Profile</h3>
						<p class="text-sm text-gray-500">Update info</p>
					</div>
				</div>
			</div>
		</div>

		<div class="grid lg:grid-cols-3 gap-8">
			<!-- Upcoming Consultations -->
			<div class="lg:col-span-2">
				<div class="bg-white rounded-lg shadow p-6">
					<h2 class="text-xl font-semibold text-gray-900 mb-4">Upcoming Consultations</h2>
					<div class="text-center py-12 text-gray-500">
						<Calendar class="w-12 h-12 mx-auto mb-4 text-gray-400" />
						<p>No upcoming consultations</p>
						<a href="/providers" class="inline-block mt-4 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition">
							Book Your First Consultation
						</a>
					</div>
				</div>
			</div>

			<!-- Health Summary -->
			<div class="lg:col-span-1">
				<div class="bg-white rounded-lg shadow p-6 mb-6">
					<h2 class="text-xl font-semibold text-gray-900 mb-4">Quick Stats</h2>
					<div class="space-y-4">
						<div class="flex items-center justify-between">
							<div class="flex items-center gap-2">
								<Video class="w-5 h-5 text-blue-600" />
								<span class="text-gray-600">Total Consultations</span>
							</div>
							<span class="font-semibold text-gray-900">0</span>
						</div>
						<div class="flex items-center justify-between">
							<div class="flex items-center gap-2">
								<FileText class="w-5 h-5 text-purple-600" />
								<span class="text-gray-600">Active Prescriptions</span>
							</div>
							<span class="font-semibold text-gray-900">0</span>
						</div>
						<div class="flex items-center justify-between">
							<div class="flex items-center gap-2">
								<Activity class="w-5 h-5 text-green-600" />
								<span class="text-gray-600">Health Records</span>
							</div>
							<span class="font-semibold text-gray-900">0</span>
						</div>
					</div>
				</div>

				<!-- Notifications -->
				<div class="bg-white rounded-lg shadow p-6">
					<div class="flex items-center justify-between mb-4">
						<h2 class="text-xl font-semibold text-gray-900">Notifications</h2>
						<a href="/notifications" class="text-sm text-blue-600 hover:underline">View All</a>
					</div>
					<div class="text-center py-8 text-gray-500">
						<Bell class="w-10 h-10 mx-auto mb-3 text-gray-400" />
						<p class="text-sm">No new notifications</p>
					</div>
				</div>
			</div>
		</div>
	</div>
</div>
