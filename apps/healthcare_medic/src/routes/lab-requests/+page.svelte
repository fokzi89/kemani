<script lang="ts">
	import { FlaskConical } from 'lucide-svelte';
</script>

<div class="min-h-screen p-6 lg:p-8">
	<div class="max-w-7xl mx-auto">
		<!-- Page Header -->
		<div class="mb-6">
			<h1 class="text-3xl font-bold text-gray-900">Lab Requests</h1>
			<p class="text-gray-600 mt-2">Manage and track laboratory test requests</p>
		</div>

		<!-- Placeholder Content -->
		<div class="bg-white rounded-lg shadow p-12">
			<div class="text-center">
				<div class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-purple-100 mb-4">
					<FlaskConical class="h-8 w-8 text-purple-600" />
				</div>
				<h2 class="text-2xl font-semibold text-gray-900 mb-2">Laboratory Test Management</h2>
				<p class="text-gray-600 max-w-md mx-auto">
					This page will allow you to order lab tests for patients, track results, and manage diagnostic requests.
				</p>
			</div>
		</div>
	</div>
</div>
