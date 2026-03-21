# Modal Forms to Add

## Instructions
Add these 5 modals at the END of the settings page template, just before the final closing `</div>` tag.
Find the line with `</div>` that closes the main container (around line 1200+) and add these modals before it.

---

## Modal 1: Profile Edit Modal

```svelte
<!-- Profile Edit Modal -->
<Modal bind:open={showProfileModal} title="Edit Profile" onClose={() => (showProfileModal = false)}>
	{#snippet children()}
		<form onsubmit={(e) => { e.preventDefault(); saveProfile(); }} class="space-y-4">
			<!-- Profile Picture Upload -->
			<FileUpload
				label="Profile Picture"
				accept="image/*"
				maxSize={2097152}
				bind:file={profilePicFile}
				bind:previewUrl={profilePicPreview}
				onFileSelect={(file) => (profilePicFile = file)}
			/>

			<!-- Full Name -->
			<div>
				<label for="full_name" class="block text-sm font-medium text-gray-700 mb-2">
					Full Name *
				</label>
				<input
					id="full_name"
					type="text"
					bind:value={profileForm.full_name}
					required
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Email -->
			<div>
				<label for="email" class="block text-sm font-medium text-gray-700 mb-2">
					Email *
				</label>
				<input
					id="email"
					type="email"
					bind:value={profileForm.email}
					required
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Phone -->
			<div>
				<label for="phone" class="block text-sm font-medium text-gray-700 mb-2">
					Phone *
				</label>
				<input
					id="phone"
					type="tel"
					bind:value={profileForm.phone}
					required
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Specialization -->
			<div>
				<label for="specialization" class="block text-sm font-medium text-gray-700 mb-2">
					Specialization *
				</label>
				<input
					id="specialization"
					type="text"
					bind:value={profileForm.specialization}
					required
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Sub-specialty -->
			<div>
				<label for="sub_specialty" class="block text-sm font-medium text-gray-700 mb-2">
					Sub-specialty
				</label>
				<input
					id="sub_specialty"
					type="text"
					bind:value={profileForm.sub_specialty}
					placeholder="e.g., Pediatric Cardiology"
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Preferred Languages -->
			<div>
				<label for="languages" class="block text-sm font-medium text-gray-700 mb-2">
					Preferred Languages
				</label>
				<input
					id="languages"
					type="text"
					bind:value={profileForm.preferred_languages}
					placeholder="e.g., English, Yoruba, Hausa"
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
				<p class="text-xs text-gray-500 mt-1">Separate multiple languages with commas</p>
			</div>

			<!-- Actions -->
			<div class="flex gap-4 pt-4">
				<button
					type="button"
					onclick={() => (showProfileModal = false)}
					class="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
				>
					Cancel
				</button>
				<button
					type="submit"
					disabled={savingProfile}
					class="flex-1 px-4 py-2 bg-gray-900 text-white rounded-lg hover:bg-black transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
				>
					{savingProfile ? 'Saving...' : 'Save Changes'}
				</button>
			</div>
		</form>
	{/snippet}
</Modal>
```

---

## Modal 2: Address Edit Modal

```svelte
<!-- Address Edit Modal -->
<Modal bind:open={showAddressModal} title="Edit Address" onClose={() => (showAddressModal = false)}>
	{#snippet children()}
		<form onsubmit={(e) => { e.preventDefault(); saveAddress(); }} class="space-y-4">
			<!-- Country -->
			<div>
				<label for="country" class="block text-sm font-medium text-gray-700 mb-2">
					Country *
				</label>
				<input
					id="country"
					type="text"
					bind:value={addressForm.country}
					required
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Region/State -->
			<div>
				<label for="region" class="block text-sm font-medium text-gray-700 mb-2">
					State/Region *
				</label>
				<input
					id="region"
					type="text"
					bind:value={addressForm.region}
					required
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- City -->
			<div>
				<label for="city" class="block text-sm font-medium text-gray-700 mb-2">
					City *
				</label>
				<input
					id="city"
					type="text"
					bind:value={addressForm.city}
					required
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Street -->
			<div>
				<label for="street" class="block text-sm font-medium text-gray-700 mb-2">
					Street Address *
				</label>
				<textarea
					id="street"
					bind:value={addressForm.street}
					required
					rows="2"
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				></textarea>
			</div>

			<!-- Actions -->
			<div class="flex gap-4 pt-4">
				<button
					type="button"
					onclick={() => (showAddressModal = false)}
					class="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
				>
					Cancel
				</button>
				<button
					type="submit"
					disabled={savingAddress}
					class="flex-1 px-4 py-2 bg-gray-900 text-white rounded-lg hover:bg-black transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
				>
					{savingAddress ? 'Saving...' : 'Save Address'}
				</button>
			</div>
		</form>
	{/snippet}
</Modal>
```

---

## Modal 3: Work Experience Modal

```svelte
<!-- Work Experience Modal -->
<Modal bind:open={showWorkExperienceModal} title="Add Work Experience" onClose={() => (showWorkExperienceModal = false)}>
	{#snippet children()}
		<form onsubmit={(e) => { e.preventDefault(); saveWorkExperience(); }} class="space-y-4">
			<!-- Position -->
			<div>
				<label for="position" class="block text-sm font-medium text-gray-700 mb-2">
					Position/Role *
				</label>
				<input
					id="position"
					type="text"
					bind:value={workExpForm.position}
					required
					placeholder="e.g., General Practitioner"
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Organization -->
			<div>
				<label for="organization" class="block text-sm font-medium text-gray-700 mb-2">
					Organization *
				</label>
				<input
					id="organization"
					type="text"
					bind:value={workExpForm.organization}
					required
					placeholder="e.g., Lagos University Teaching Hospital"
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Location -->
			<div>
				<label for="location" class="block text-sm font-medium text-gray-700 mb-2">
					Location
				</label>
				<input
					id="location"
					type="text"
					bind:value={workExpForm.location}
					placeholder="e.g., Lagos, Nigeria"
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Start Date -->
			<div>
				<label for="start_date" class="block text-sm font-medium text-gray-700 mb-2">
					Start Date *
				</label>
				<input
					id="start_date"
					type="date"
					bind:value={workExpForm.start_date}
					required
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Current Position Checkbox -->
			<div class="flex items-center gap-2">
				<input
					id="is_current"
					type="checkbox"
					bind:checked={workExpForm.is_current}
					class="w-4 h-4 text-primary-600 border-gray-300 rounded focus:ring-primary-500"
				/>
				<label for="is_current" class="text-sm text-gray-700">
					I currently work here
				</label>
			</div>

			<!-- End Date -->
			{#if !workExpForm.is_current}
				<div>
					<label for="end_date" class="block text-sm font-medium text-gray-700 mb-2">
						End Date *
					</label>
					<input
						id="end_date"
						type="date"
						bind:value={workExpForm.end_date}
						required={!workExpForm.is_current}
						class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
					/>
				</div>
			{/if}

			<!-- Description -->
			<div>
				<label for="description" class="block text-sm font-medium text-gray-700 mb-2">
					Description
				</label>
				<textarea
					id="description"
					bind:value={workExpForm.description}
					rows="3"
					placeholder="Describe your responsibilities and achievements..."
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				></textarea>
			</div>

			<!-- Actions -->
			<div class="flex gap-4 pt-4">
				<button
					type="button"
					onclick={() => (showWorkExperienceModal = false)}
					class="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
				>
					Cancel
				</button>
				<button
					type="submit"
					disabled={savingWorkExp}
					class="flex-1 px-4 py-2 bg-gray-900 text-white rounded-lg hover:bg-black transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
				>
					{savingWorkExp ? 'Saving...' : 'Add Experience'}
				</button>
			</div>
		</form>
	{/snippet}
</Modal>
```

---

## Modal 4: Certificate Modal

```svelte
<!-- Certificate Modal -->
<Modal bind:open={showCertificateModal} title="Add Certificate" onClose={() => (showCertificateModal = false)}>
	{#snippet children()}
		<form onsubmit={(e) => { e.preventDefault(); saveCertificate(); }} class="space-y-4">
			<!-- Certificate Name -->
			<div>
				<label for="cert_name" class="block text-sm font-medium text-gray-700 mb-2">
					Certificate Name *
				</label>
				<input
					id="cert_name"
					type="text"
					bind:value={certForm.certificate_name}
					required
					placeholder="e.g., Advanced Cardiac Life Support (ACLS)"
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Issuing Organization -->
			<div>
				<label for="cert_org" class="block text-sm font-medium text-gray-700 mb-2">
					Issuing Organization *
				</label>
				<input
					id="cert_org"
					type="text"
					bind:value={certForm.issuing_organization}
					required
					placeholder="e.g., American Heart Association"
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Issue Date -->
			<div>
				<label for="cert_issue_date" class="block text-sm font-medium text-gray-700 mb-2">
					Issue Date *
				</label>
				<input
					id="cert_issue_date"
					type="date"
					bind:value={certForm.issue_date}
					required
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Expiry Date -->
			<div>
				<label for="cert_expiry" class="block text-sm font-medium text-gray-700 mb-2">
					Expiry Date (Optional)
				</label>
				<input
					id="cert_expiry"
					type="date"
					bind:value={certForm.expiry_date}
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Certificate Number -->
			<div>
				<label for="cert_number" class="block text-sm font-medium text-gray-700 mb-2">
					Certificate Number
				</label>
				<input
					id="cert_number"
					type="text"
					bind:value={certForm.certificate_number}
					placeholder="e.g., CERT-2024-12345"
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- File Upload -->
			<FileUpload
				label="Certificate File (PDF or Image) *"
				accept="application/pdf,image/*"
				maxSize={5242880}
				preview={false}
				bind:file={certFile}
				bind:previewUrl={certFilePreview}
				onFileSelect={(file) => (certFile = file)}
			/>

			<!-- Actions -->
			<div class="flex gap-4 pt-4">
				<button
					type="button"
					onclick={() => (showCertificateModal = false)}
					class="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
				>
					Cancel
				</button>
				<button
					type="submit"
					disabled={savingCertificate}
					class="flex-1 px-4 py-2 bg-gray-900 text-white rounded-lg hover:bg-black transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
				>
					{savingCertificate ? 'Uploading...' : 'Add Certificate'}
				</button>
			</div>
		</form>
	{/snippet}
</Modal>
```

---

## Modal 5: License Modal

```svelte
<!-- License Modal -->
<Modal bind:open={showLicenseModal} title="Add Professional License" onClose={() => (showLicenseModal = false)}>
	{#snippet children()}
		<form onsubmit={(e) => { e.preventDefault(); saveLicense(); }} class="space-y-4">
			<!-- License Type -->
			<div>
				<label for="license_type" class="block text-sm font-medium text-gray-700 mb-2">
					License Type *
				</label>
				<input
					id="license_type"
					type="text"
					bind:value={licenseForm.license_type}
					required
					placeholder="e.g., Medical Practitioner License"
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- License Number -->
			<div>
				<label for="license_number" class="block text-sm font-medium text-gray-700 mb-2">
					License Number *
				</label>
				<input
					id="license_number"
					type="text"
					bind:value={licenseForm.license_number}
					required
					placeholder="e.g., MDCN/2024/12345"
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Issuing Authority -->
			<div>
				<label for="issuing_authority" class="block text-sm font-medium text-gray-700 mb-2">
					Issuing Authority *
				</label>
				<input
					id="issuing_authority"
					type="text"
					bind:value={licenseForm.issuing_authority}
					required
					placeholder="e.g., Medical and Dental Council of Nigeria"
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Country -->
			<div>
				<label for="license_country" class="block text-sm font-medium text-gray-700 mb-2">
					Country *
				</label>
				<input
					id="license_country"
					type="text"
					bind:value={licenseForm.country}
					required
					placeholder="e.g., Nigeria"
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- State/Region -->
			<div>
				<label for="license_state" class="block text-sm font-medium text-gray-700 mb-2">
					State/Region
				</label>
				<input
					id="license_state"
					type="text"
					bind:value={licenseForm.state_region}
					placeholder="e.g., Lagos"
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Issue Date -->
			<div>
				<label for="license_issue_date" class="block text-sm font-medium text-gray-700 mb-2">
					Issue Date *
				</label>
				<input
					id="license_issue_date"
					type="date"
					bind:value={licenseForm.issue_date}
					required
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- Expiry Date -->
			<div>
				<label for="license_expiry_date" class="block text-sm font-medium text-gray-700 mb-2">
					Expiry Date *
				</label>
				<input
					id="license_expiry_date"
					type="date"
					bind:value={licenseForm.expiry_date}
					required
					class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
				/>
			</div>

			<!-- File Upload -->
			<FileUpload
				label="License File (PDF or Image) *"
				accept="application/pdf,image/*"
				maxSize={5242880}
				preview={false}
				bind:file={licenseFile}
				bind:previewUrl={licenseFilePreview}
				onFileSelect={(file) => (licenseFile = file)}
			/>

			<!-- Actions -->
			<div class="flex gap-4 pt-4">
				<button
					type="button"
					onclick={() => (showLicenseModal = false)}
					class="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
				>
					Cancel
				</button>
				<button
					type="submit"
					disabled={savingLicense}
					class="flex-1 px-4 py-2 bg-gray-900 text-white rounded-lg hover:bg-black transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
				>
					{savingLicense ? 'Uploading...' : 'Add License'}
				</button>
			</div>
		</form>
	{/snippet}
</Modal>
```

---

**Location to Add:** Find the closing `</div>` tag before the very end of the file (after all other sections like Work Schedule, Time Slot Settings, Notifications, Security) and add all 5 modals just before it.
