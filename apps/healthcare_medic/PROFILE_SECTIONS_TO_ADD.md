# New Profile Section UI Code

## Instructions
Replace the Profile Section in `apps/healthcare_medic/src/routes/settings/+page.svelte` (around line 750-776) with this enhanced version, then add the new sections after it.

## 1. Enhanced Profile Section (REPLACE existing Profile Section)

```svelte
<!-- Profile Section -->
<div class="bg-white rounded-lg shadow p-6">
	<div class="flex items-center justify-between mb-4">
		<div class="flex items-center gap-3">
			<div class="p-2 bg-primary-100 rounded-lg">
				<User class="h-5 w-5 text-primary-600" />
			</div>
			<h2 class="text-xl font-semibold text-gray-900">Profile Information</h2>
		</div>
		<button
			onclick={() => (showProfileModal = true)}
			class="flex items-center gap-2 px-4 py-2 bg-gray-900 hover:bg-black text-white rounded-lg text-sm font-medium transition-colors shadow-sm"
		>
			<Edit class="h-4 w-4" />
			Edit Profile
		</button>
	</div>

	<!-- Profile Picture -->
	{#if provider?.profile_photo_url}
		<div class="flex items-center gap-4 mb-6 pb-6 border-b">
			<img
				src={provider.profile_photo_url}
				alt={provider.full_name}
				class="h-20 w-20 rounded-full object-cover border-2 border-gray-200"
			/>
			<div>
				<p class="text-sm font-medium text-gray-700">Profile Picture</p>
				<p class="text-xs text-gray-500">Click "Edit Profile" to change</p>
			</div>
		</div>
	{/if}

	<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
		<div>
			<label class="text-sm font-medium text-gray-700">Full Name</label>
			<p class="text-gray-900 mt-1">{provider?.full_name || 'N/A'}</p>
		</div>
		<div>
			<label class="text-sm font-medium text-gray-700">Email</label>
			<p class="text-gray-900 mt-1">{provider?.email || 'N/A'}</p>
		</div>
		<div>
			<label class="text-sm font-medium text-gray-700">Specialization</label>
			<p class="text-gray-900 mt-1">{provider?.specialization || 'N/A'}</p>
		</div>
		<div>
			<label class="text-sm font-medium text-gray-700">Sub-specialty</label>
			<p class="text-gray-900 mt-1">{provider?.sub_specialty || 'Not specified'}</p>
		</div>
		<div>
			<label class="text-sm font-medium text-gray-700">Phone</label>
			<p class="text-gray-900 mt-1">{provider?.phone || 'N/A'}</p>
		</div>
		<div>
			<label class="text-sm font-medium text-gray-700">Languages</label>
			<p class="text-gray-900 mt-1">
				{provider?.preferred_languages?.join(', ') || 'Not specified'}
			</p>
		</div>
	</div>
</div>

## 2. NEW Address Section (ADD after Profile Section, before Subscription)

```svelte
<!-- Address Section -->
<div class="bg-white rounded-lg shadow p-6">
	<div class="flex items-center justify-between mb-4">
		<div class="flex items-center gap-3">
			<div class="p-2 bg-primary-100 rounded-lg">
				<MapPin class="h-5 w-5 text-primary-600" />
			</div>
			<h2 class="text-xl font-semibold text-gray-900">Location & Address</h2>
		</div>
		<button
			onclick={() => (showAddressModal = true)}
			class="flex items-center gap-2 px-4 py-2 bg-gray-900 hover:bg-black text-white rounded-lg text-sm font-medium transition-colors shadow-sm"
		>
			<Edit class="h-4 w-4" />
			Edit Address
		</button>
	</div>

	<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
		<div>
			<label class="text-sm font-medium text-gray-700">Country</label>
			<p class="text-gray-900 mt-1">{provider?.country || 'Not specified'}</p>
		</div>
		<div>
			<label class="text-sm font-medium text-gray-700">State/Region</label>
			<p class="text-gray-900 mt-1">{provider?.region || 'Not specified'}</p>
		</div>
		{#if provider?.clinic_address}
			<div>
				<label class="text-sm font-medium text-gray-700">City</label>
				<p class="text-gray-900 mt-1">{provider.clinic_address.city || 'Not specified'}</p>
			</div>
			<div>
				<label class="text-sm font-medium text-gray-700">Street Address</label>
				<p class="text-gray-900 mt-1">{provider.clinic_address.street || 'Not specified'}</p>
			</div>
		{/if}
	</div>
</div>

## 3. NEW Work Experience Section

```svelte
<!-- Work Experience Section -->
<div class="bg-white rounded-lg shadow p-6">
	<div class="flex items-center justify-between mb-4">
		<div class="flex items-center gap-3">
			<div class="p-2 bg-primary-100 rounded-lg">
				<Briefcase class="h-5 w-5 text-primary-600" />
			</div>
			<h2 class="text-xl font-semibold text-gray-900">Work Experience</h2>
		</div>
		<button
			onclick={() => (showWorkExperienceModal = true)}
			class="flex items-center gap-2 px-4 py-2 bg-gray-900 hover:bg-black text-white rounded-lg text-sm font-medium transition-colors shadow-sm"
		>
			<Plus class="h-4 w-4" />
			Add Experience
		</button>
	</div>

	{#if workExperiences.length > 0}
		<div class="space-y-4">
			{#each workExperiences as exp}
				<div class="border border-gray-200 rounded-lg p-4">
					<div class="flex items-start justify-between">
						<div class="flex-1">
							<h3 class="font-semibold text-gray-900">{exp.position}</h3>
							<p class="text-sm text-gray-700">{exp.organization}</p>
							{#if exp.location}
								<p class="text-sm text-gray-600">{exp.location}</p>
							{/if}
							<p class="text-xs text-gray-500 mt-1">
								{new Date(exp.start_date).toLocaleDateString()} -
								{exp.is_current ? 'Present' : new Date(exp.end_date).toLocaleDateString()}
							</p>
							{#if exp.description}
								<p class="text-sm text-gray-600 mt-2">{exp.description}</p>
							{/if}
						</div>
						<button
							onclick={() => deleteWorkExperience(exp.id)}
							class="p-2 hover:bg-red-50 rounded-lg transition-colors"
							type="button"
						>
							<Trash2 class="h-4 w-4 text-red-600" />
						</button>
					</div>
				</div>
			{/each}
		</div>
	{:else}
		<p class="text-gray-600">No work experience added yet</p>
	{/if}
</div>

## 4. NEW Certificates Section

```svelte
<!-- Certificates Section -->
<div class="bg-white rounded-lg shadow p-6">
	<div class="flex items-center justify-between mb-4">
		<div class="flex items-center gap-3">
			<div class="p-2 bg-primary-100 rounded-lg">
				<Award class="h-5 w-5 text-primary-600" />
			</div>
			<h2 class="text-xl font-semibold text-gray-900">Certificates</h2>
		</div>
		<button
			onclick={() => (showCertificateModal = true)}
			class="flex items-center gap-2 px-4 py-2 bg-gray-900 hover:bg-black text-white rounded-lg text-sm font-medium transition-colors shadow-sm"
		>
			<Plus class="h-4 w-4" />
			Add Certificate
		</button>
	</div>

	{#if certificates.length > 0}
		<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
			{#each certificates as cert}
				<div class="border border-gray-200 rounded-lg p-4">
					<div class="flex items-start justify-between mb-2">
						<h3 class="font-semibold text-gray-900 flex-1">{cert.certificate_name}</h3>
						<button
							onclick={() => deleteCertificate(cert.id, cert.file_url)}
							class="p-1 hover:bg-red-50 rounded transition-colors"
							type="button"
						>
							<Trash2 class="h-4 w-4 text-red-600" />
						</button>
					</div>
					<p class="text-sm text-gray-700">{cert.issuing_organization}</p>
					<p class="text-xs text-gray-500 mt-1">
						Issued: {new Date(cert.issue_date).toLocaleDateString()}
					</p>
					{#if cert.expiry_date}
						<p class="text-xs text-gray-500">
							Expires: {new Date(cert.expiry_date).toLocaleDateString()}
						</p>
					{/if}
					<a
						href={cert.file_url}
						target="_blank"
						class="text-xs text-primary-600 hover:underline mt-2 inline-block"
					>
						View Certificate
					</a>
				</div>
			{/each}
		</div>
	{:else}
		<p class="text-gray-600">No certificates added yet</p>
	{/if}
</div>

## 5. NEW Licenses Section

```svelte
<!-- Licenses Section -->
<div class="bg-white rounded-lg shadow p-6">
	<div class="flex items-center justify-between mb-4">
		<div class="flex items-center gap-3">
			<div class="p-2 bg-primary-100 rounded-lg">
				<FileCheck class="h-5 w-5 text-primary-600" />
			</div>
			<h2 class="text-xl font-semibold text-gray-900">Professional Licenses</h2>
		</div>
		<button
			onclick={() => (showLicenseModal = true)}
			class="flex items-center gap-2 px-4 py-2 bg-gray-900 hover:bg-black text-white rounded-lg text-sm font-medium transition-colors shadow-sm"
		>
			<Plus class="h-4 w-4" />
			Add License
		</button>
	</div>

	{#if licenses.length > 0}
		<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
			{#each licenses as license}
				<div class="border border-gray-200 rounded-lg p-4">
					<div class="flex items-start justify-between mb-2">
						<div class="flex-1">
							<h3 class="font-semibold text-gray-900">{license.license_type}</h3>
							<p class="text-sm text-gray-700">{license.license_number}</p>
						</div>
						<button
							onclick={() => deleteLicense(license.id, license.file_url)}
							class="p-1 hover:bg-red-50 rounded transition-colors"
							type="button"
						>
							<Trash2 class="h-4 w-4 text-red-600" />
						</button>
					</div>
					<p class="text-sm text-gray-600">{license.issuing_authority}</p>
					<p class="text-sm text-gray-600">{license.country}</p>
					<p class="text-xs text-gray-500 mt-1">
						Valid: {new Date(license.issue_date).toLocaleDateString()} - {new Date(license.expiry_date).toLocaleDateString()}
					</p>
					<div class="flex items-center gap-2 mt-2">
						<span
							class="px-2 py-1 text-xs rounded-full {license.status === 'active'
								? 'bg-green-100 text-green-800'
								: 'bg-red-100 text-red-800'}"
						>
							{license.status}
						</span>
						<a
							href={license.file_url}
							target="_blank"
							class="text-xs text-primary-600 hover:underline"
						>
							View License
						</a>
					</div>
				</div>
			{/each}
		</div>
	{:else}
		<p class="text-gray-600">No licenses added yet</p>
	{/if}
</div>
```

---

**Next Step:** Add the 5 modal forms at the end of the template (before the closing `</div>` of the main container). See `MODAL_FORMS_TO_ADD.md` for the modal code.
