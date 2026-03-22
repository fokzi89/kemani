<script lang="ts">
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { ArrowLeft } from 'lucide-svelte';

	let provider = $state(null);
	let loading = $state(false);
	let error = $state('');

	let formData = $state({
		email: '',
		password: '',
		full_name: '',
		phone: '',
		date_of_birth: '',
		gender: 'male',
		address: '',
		city: '',
		state: '',
		blood_group: '',
		allergies: '',
		medical_history: ''
	});

	async function handleSubmit(e: Event) {
		e.preventDefault();
		loading = true;
		error = '';

		try {
			// Create auth user for patient
			const { data: authData, error: authError } = await supabase.auth.signUp({
				email: formData.email,
				password: formData.password,
				options: {
					data: {
						full_name: formData.full_name,
						role: 'patient'
					}
				}
			});

			if (authError) throw authError;

			if (authData.user) {
				// Note: In production, you'd have a patients table to store additional info
				// For now, we'll just create the user and they can book consultations

				goto('/patients');
			}
		} catch (err: any) {
			error = err.message || 'Failed to add patient';
			loading = false;
		}
	}
</script>

<div class="max-w-3xl mx-auto space-y-6">
	<!-- Header -->
	<div class="bg-white rounded-lg shadow p-6">
		<div class="flex items-center gap-4">
			<a
				href="/patients"
				class="p-2 hover:bg-gray-100 rounded-md transition-colors"
			>
				<ArrowLeft class="h-5 w-5 text-gray-600" />
			</a>
			<div>
				<h2 class="text-2xl font-bold text-gray-900">Add New Patient</h2>
				<p class="text-gray-600 mt-1">Create a patient account and medical record</p>
			</div>
		</div>
	</div>

	<!-- Form -->
	<form onsubmit={handleSubmit} class="bg-white rounded-lg shadow p-6 space-y-6">
		{#if error}
			<div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-md text-sm">
				{error}
			</div>
		{/if}

		<!-- Basic Information -->
		<div>
			<h3 class="text-lg font-semibold text-gray-900 mb-4">Basic Information</h3>
			<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
				<div class="md:col-span-2">
					<label for="full_name" class="block text-sm font-medium text-gray-700 mb-2">
						Full Name *
					</label>
					<input
						id="full_name"
						type="text"
						bind:value={formData.full_name}
						required
						class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
						placeholder="John Doe"
					/>
				</div>

				<div>
					<label for="email" class="block text-sm font-medium text-gray-700 mb-2">
						Email Address *
					</label>
					<input
						id="email"
						type="email"
						bind:value={formData.email}
						required
						class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
						placeholder="patient@example.com"
					/>
				</div>

				<div>
					<label for="password" class="block text-sm font-medium text-gray-700 mb-2">
						Password *
					</label>
					<input
						id="password"
						type="password"
						bind:value={formData.password}
						required
						minlength="6"
						class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
						placeholder="••••••••"
					/>
				</div>

				<div>
					<label for="phone" class="block text-sm font-medium text-gray-700 mb-2">
						Phone Number
					</label>
					<input
						id="phone"
						type="tel"
						bind:value={formData.phone}
						class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
						placeholder="+234 800 000 0000"
					/>
				</div>

				<div>
					<label for="date_of_birth" class="block text-sm font-medium text-gray-700 mb-2">
						Date of Birth (Optional)
					</label>
					<input
						id="date_of_birth"
						type="date"
						bind:value={formData.date_of_birth}
						class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
					/>
				</div>

				<div>
					<label for="gender" class="block text-sm font-medium text-gray-700 mb-2">
						Gender
					</label>
					<select
						id="gender"
						bind:value={formData.gender}
						class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
					>
						<option value="male">Male</option>
						<option value="female">Female</option>
					</select>
				</div>

				<div>
					<label for="blood_group" class="block text-sm font-medium text-gray-700 mb-2">
						Blood Group
					</label>
					<select
						id="blood_group"
						bind:value={formData.blood_group}
						class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
					>
						<option value="">Select...</option>
						<option value="A+">A+</option>
						<option value="A-">A-</option>
						<option value="B+">B+</option>
						<option value="B-">B-</option>
						<option value="AB+">AB+</option>
						<option value="AB-">AB-</option>
						<option value="O+">O+</option>
						<option value="O-">O-</option>
					</select>
				</div>
			</div>
		</div>

		<!-- Address -->
		<div>
			<h3 class="text-lg font-semibold text-gray-900 mb-4">Address</h3>
			<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
				<div class="md:col-span-2">
					<label for="address" class="block text-sm font-medium text-gray-700 mb-2">
						Street Address
					</label>
					<input
						id="address"
						type="text"
						bind:value={formData.address}
						class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
						placeholder="123 Main Street"
					/>
				</div>

				<div>
					<label for="city" class="block text-sm font-medium text-gray-700 mb-2">
						City
					</label>
					<input
						id="city"
						type="text"
						bind:value={formData.city}
						class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
						placeholder="Lagos"
					/>
				</div>

				<div>
					<label for="state" class="block text-sm font-medium text-gray-700 mb-2">
						State
					</label>
					<input
						id="state"
						type="text"
						bind:value={formData.state}
						class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
						placeholder="Lagos State"
					/>
				</div>
			</div>
		</div>

		<!-- Medical Information -->
		<div>
			<h3 class="text-lg font-semibold text-gray-900 mb-4">Medical Information</h3>
			<div class="space-y-4">
				<div>
					<label for="allergies" class="block text-sm font-medium text-gray-700 mb-2">
						Allergies
					</label>
					<textarea
						id="allergies"
						bind:value={formData.allergies}
						rows="3"
						class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
						placeholder="List any known allergies..."
					></textarea>
				</div>

				<div>
					<label for="medical_history" class="block text-sm font-medium text-gray-700 mb-2">
						Medical History
					</label>
					<textarea
						id="medical_history"
						bind:value={formData.medical_history}
						rows="3"
						class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-primary-500 focus:border-transparent"
						placeholder="Brief medical history, chronic conditions, etc..."
					></textarea>
				</div>
			</div>
		</div>

		<!-- Actions -->
		<div class="flex gap-4 pt-4">
			<a
				href="/patients"
				class="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-md hover:bg-gray-300 transition-colors text-center"
			>
				Cancel
			</a>
			<button
				type="submit"
				disabled={loading}
				class="flex-1 px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
			>
				{loading ? 'Adding Patient...' : 'Add Patient'}
			</button>
		</div>
	</form>
</div>
