<script lang="ts">
	import { User, Mail, Phone, MapPin, Calendar, Edit, Save } from 'lucide-svelte';

	let isEditing = $state(false);

	// Sample user data - in production, fetch from Supabase
	let profile = $state({
		full_name: 'John Doe',
		email: 'john.doe@example.com',
		phone: '+234 801 234 5678',
		date_of_birth: '1990-01-15',
		gender: 'male',
		blood_type: 'O+',
		address: '123 Main Street, Ikeja, Lagos',
		emergency_contact_name: 'Jane Doe',
		emergency_contact_phone: '+234 801 234 5679',
		medical_conditions: 'None',
		allergies: 'Penicillin'
	});

	function handleSave() {
		// TODO: Save to Supabase
		isEditing = false;
		alert('Profile updated successfully!');
	}
</script>

<svelte:head>
	<title>My Profile | Kemani Health</title>
</svelte:head>

<div class="py-6 px-4 sm:px-6 lg:px-8">
	<div class="max-w-4xl mx-auto">
		<!-- Header -->
		<div class="mb-8 flex items-center justify-between">
			<div>
				<h1 class="text-3xl font-bold text-gray-900">My Profile</h1>
				<p class="mt-2 text-gray-600">Manage your personal and medical information</p>
			</div>
			{#if !isEditing}
				<button
					onclick={() => isEditing = true}
					class="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
				>
					<Edit class="w-4 h-4" />
					Edit Profile
				</button>
			{/if}
		</div>

		<div class="space-y-6">
			<!-- Personal Information -->
			<div class="bg-white rounded-lg shadow p-6">
				<h2 class="text-xl font-semibold text-gray-900 mb-6">Personal Information</h2>
				<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">Full Name</label>
						<input
							type="text"
							bind:value={profile.full_name}
							disabled={!isEditing}
							class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50 disabled:text-gray-600"
						/>
					</div>

					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">Email</label>
						<input
							type="email"
							bind:value={profile.email}
							disabled={!isEditing}
							class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50 disabled:text-gray-600"
						/>
					</div>

					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">Phone</label>
						<input
							type="tel"
							bind:value={profile.phone}
							disabled={!isEditing}
							class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50 disabled:text-gray-600"
						/>
					</div>

					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">Date of Birth</label>
						<input
							type="date"
							bind:value={profile.date_of_birth}
							disabled={!isEditing}
							class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50 disabled:text-gray-600"
						/>
					</div>

					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">Gender</label>
						<select
							bind:value={profile.gender}
							disabled={!isEditing}
							class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50 disabled:text-gray-600"
						>
							<option value="male">Male</option>
							<option value="female">Female</option>
							<option value="other">Other</option>
						</select>
					</div>

					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">Blood Type</label>
						<select
							bind:value={profile.blood_type}
							disabled={!isEditing}
							class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50 disabled:text-gray-600"
						>
							<option>A+</option>
							<option>A-</option>
							<option>B+</option>
							<option>B-</option>
							<option>AB+</option>
							<option>AB-</option>
							<option>O+</option>
							<option>O-</option>
						</select>
					</div>

					<div class="md:col-span-2">
						<label class="block text-sm font-medium text-gray-700 mb-2">Address</label>
						<textarea
							bind:value={profile.address}
							disabled={!isEditing}
							rows="2"
							class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50 disabled:text-gray-600"
						></textarea>
					</div>
				</div>
			</div>

			<!-- Emergency Contact -->
			<div class="bg-white rounded-lg shadow p-6">
				<h2 class="text-xl font-semibold text-gray-900 mb-6">Emergency Contact</h2>
				<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">Contact Name</label>
						<input
							type="text"
							bind:value={profile.emergency_contact_name}
							disabled={!isEditing}
							class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50 disabled:text-gray-600"
						/>
					</div>

					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">Contact Phone</label>
						<input
							type="tel"
							bind:value={profile.emergency_contact_phone}
							disabled={!isEditing}
							class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50 disabled:text-gray-600"
						/>
					</div>
				</div>
			</div>

			<!-- Medical Information -->
			<div class="bg-white rounded-lg shadow p-6">
				<h2 class="text-xl font-semibold text-gray-900 mb-6">Medical Information</h2>
				<div class="space-y-6">
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">Medical Conditions</label>
						<textarea
							bind:value={profile.medical_conditions}
							disabled={!isEditing}
							rows="3"
							placeholder="List any chronic conditions or ongoing treatments"
							class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50 disabled:text-gray-600"
						></textarea>
					</div>

					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">Allergies</label>
						<textarea
							bind:value={profile.allergies}
							disabled={!isEditing}
							rows="2"
							placeholder="List any known allergies (medications, food, etc.)"
							class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50 disabled:text-gray-600"
						></textarea>
					</div>
				</div>
			</div>

			<!-- Save/Cancel Buttons -->
			{#if isEditing}
				<div class="flex gap-4 justify-end">
					<button
						onclick={() => isEditing = false}
						class="px-6 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition"
					>
						Cancel
					</button>
					<button
						onclick={handleSave}
						class="flex items-center gap-2 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
					>
						<Save class="w-4 h-4" />
						Save Changes
					</button>
				</div>
			{/if}
		</div>
	</div>
</div>
