<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { goto } from '$app/navigation';
	import { User, Phone, MapPin, Building, FileText, Upload, Check } from 'lucide-svelte';

	let currentStage = $state(1);
	let loading = $state(false);
	let pageLoading = $state(true);
	let error = $state('');
	let currentUser = $state<any>(null);
	let userId = $state('');
	let providerId = $state('');
	let medicSubscriptionId = $state('');

	// Stage 1: Profile Basics
	let profilePicUrl = $state('');
	let profilePicFile = $state<File | null>(null);
	let phone = $state('');
	let specialization = $state('');
	let country = $state('');

	// Stage 2: Professional Details
	let clinicAddress = $state('');
	let city = $state('');
	let region = $state('');
	let bio = $state('');

	// Stage 3: Additional Settings
	let credentials = $state('');
	let yearsOfExperience = $state('');
	let licenseNumber = $state('');
	let licenseDocumentUrl = $state('');
	let licenseDocumentFile = $state<File | null>(null);
	let subSpecialty = $state('');
	let languagesSpoken = $state('');
	let consultationTypes = $state<string[]>(['chat']);

	// Auto-save form draft to localStorage
	$effect(() => {
		if (typeof window !== 'undefined' && !pageLoading && userId) {
			const draftState = {
				currentStage, phone, specialization, country, clinicAddress, city, region, bio, credentials, yearsOfExperience, licenseNumber, subSpecialty, languagesSpoken, consultationTypes
			};
			localStorage.setItem(`onboarding_draft_${userId}`, JSON.stringify(draftState));
		}
	});

	// Idle handling variables
	let idleTimer: ReturnType<typeof setTimeout>;
	const IDLE_TIMEOUT_MS = 5 * 60 * 1000;

	function resetIdleTimer() {
		if (idleTimer) clearTimeout(idleTimer);
		idleTimer = setTimeout(async () => {
			await supabase.auth.signOut();
			goto('/auth/login?reason=timeout');
		}, IDLE_TIMEOUT_MS);
	}

	function setupIdleTracking() {
		resetIdleTimer();
		const events = ['mousemove', 'keydown', 'scroll', 'touchstart', 'click'];
		events.forEach(evt => window.addEventListener(evt, resetIdleTimer));
		return () => {
			events.forEach(evt => window.removeEventListener(evt, resetIdleTimer));
			if (idleTimer) clearTimeout(idleTimer);
		};
	}

	const specializations = [
		'Aboriginal and Torres Strait Islander health worker',
		'Acupuncturist',
		'Addiction medicine specialist',
		'Anaesthetist',
		'Anaesthetist and intensive care medicine specialist',
		'Anatomic pathologist',
		'Arts therapist',
		'Audiologist',
		'Cardiologist',
		'Cardiothoracic surgeon',
		'Child and adolescent psychiatrist',
		'Chinese herbal dispenser',
		'Chinese herbal medicine practitioner',
		'Chinese medicine practitioner',
		'Chiropractor',
		'Clinical geneticist',
		'Clinical haematologist',
		'Clinical immunologist',
		'Clinical pharmacologist',
		'Clinical psychologist',
		'Community health physician',
		'Consultant gynaecology and obstetrics',
		'Cytopathologist',
		'Dental hygienist',
		'Dental prosthetist',
		'Dentist',
		'Dermatologist',
		'Diabetes educator',
		'Diagnostic radiographer',
		'Diagnostic radiologist',
		'Ear, nose and throat surgeon',
		'Educational psychologist',
		'Emergency department physician',
		'Endocrinologist',
		'Endodontist',
		'Enrolled nurse',
		'Exercise physiologist',
		'Forensic pathologist',
		'Gastroenterologist and hepatologist',
		'General pathologist',
		'General physician',
		'General practitioner',
		'General surgeon',
		'Geriatrics specialist',
		'Gynaecologic oncologist',
		'Haematologist',
		'Histopathologist',
		'Infectious disease specialist',
		'Intensive care specialist',
		'Massage Therapist',
		'Maternal-fetal medicine specialist',
		'Medical doctor',
		'Medical microbiologist',
		'Medical officer',
		'Medical oncologist',
		'Medical pathologist',
		'Medical radiation practitioner',
		'Medical radiographer',
		'Mental health nurse',
		'Music therapist',
		'Myotherapist',
		'Neonatologist',
		'Nephrologist',
		'Neurologist',
		'Neurosurgeon',
		'Nuclear medicine specialist',
		'Nuclear medicine technologist',
		'Obstetrician and gynaecologist',
		'Occupation medicine specialist',
		'Occupational and environmental physician',
		'Occupational therapist',
		'Ophthalmologist',
		'Optometrist',
		'Oral and maxillofacial radiologist',
		'Oral and maxillofacial surgeon',
		'Oral health therapist',
		'Oral medicine specialist',
		'Oral pathologist',
		'Orthodontist',
		'Orthopaedic surgeon',
		'Orthoptist',
		'Orthotist and prosthetist',
		'Osteopath',
		'Otorhinolaryngologist',
		'Paediatric cardiologist',
		'Paediatric clinical geneticist',
		'Paediatric clinical pharmacologist',
		'Paediatric dermatologist',
		'Paediatric emergency medicine specialist',
		'Paediatric endocrinologist',
		'Paediatric gastroenterologist and hepatologist',
		'Paediatric haematologist',
		'Paediatric immunology and allergy specialist',
		'Paediatric infectious disease physician',
		'Paediatric intensive care specialist',
		'Paediatric nephrologist',
		'Paediatric neurologist',
		'Paediatric nuclear medicine specialist',
		'Paediatric oncologist',
		'Paediatric palliative care physician',
		'Paediatric rehabilitation physician',
		'Paediatric respiratory and sleep specialist',
		'Paediatric rheumatologist',
		'Paediatric surgeon',
		'Paediatrician',
		'Paedodontist',
		'Pain medicine physician',
		'Palliative care physician',
		'Periodontist',
		'Pharmacist',
		'Physiotherapist',
		'Plastic surgeon',
		'Podiatric surgeon',
		'Podiatrist',
		'Practice nurse',
		'Professional counsellor',
		'Professional midwife',
		'Professional nurse',
		'Prosthodontist',
		'Psychiatrist',
		'Psychologist',
		'Psychotherapist',
		'Public health dentist',
		'Public health physician',
		'Radiation oncologist',
		'Radiation therapist',
		'Radiologist',
		'Registered midwife',
		'Registered nurse',
		'Rehabilitation physician',
		'Respiratory and sleep physician',
		'Rheumatologist',
		'Social worker',
		'Sonographer',
		'Special needs dentist',
		'Specialised physician',
		'Speech pathologist',
		'Sports physician',
		'Thoracic physician',
		'Urogynaecologist',
		'Urologist'
	];

	const countries = [
		'Afghanistan',
		'Åland Islands',
		'Albania',
		'Algeria',
		'American Samoa',
		'Andorra',
		'Angola',
		'Anguilla',
		'Antarctica',
		'Antigua and Barbuda',
		'Argentina',
		'Armenia',
		'Aruba',
		'Australia',
		'Austria',
		'Azerbaijan',
		'Bahamas',
		'Bahrain',
		'Bangladesh',
		'Belgium',
		'Belize',
		'Benin',
		'Bermuda',
		'Bhutan',
		'Bolivia',
		'Bosnia and Herzegovina',
		'Botswana',
		'Bouvet Island',
		'Brazil',
		'British Indian Ocean Territory',
		'Brunei Darussalam',
		'Bulgaria',
		'Burkina Faso',
		'Burundi',
		'Cambodia',
		'Cameroon',
		'Canada',
		'Cape Verde',
		'Cayman Islands',
		'Central African Republic',
		'Chad',
		'Chile',
		'China',
		'Christmas Island',
		'Cocos (Keeling) Islands',
		'Colombia',
		'Comoros',
		'Congo',
		'Congo, The Democratic Republic of the',
		'Cook Islands',
		'Costa Rica',
		'Cote D Ivoire',
		'Croatia',
		'Cuba',
		'Cyprus',
		'Czech Republic',
		'Denmark',
		'Djibouti',
		'Dominica',
		'Dominican Republic',
		'Ecuador',
		'Egypt',
		'El Salvador',
		'Equatorial Guinea',
		'Eritrea',
		'Estonia',
		'Ethiopia',
		'Falkland Islands (Malvinas)',
		'Faroe Islands',
		'Fiji',
		'Finland',
		'France',
		'French Guiana',
		'French Polynesia',
		'French Southern Territories',
		'Gabon',
		'Gambia',
		'Georgia',
		'Germany',
		'Ghana',
		'Gibraltar',
		'Greece',
		'Greenland',
		'Grenada',
		'Guadeloupe',
		'Guam',
		'Guatemala',
		'Guernsey',
		'Guinea',
		'Guinea-Bissau',
		'Guyana',
		'Haiti',
		'Heard Island and Mcdonald Islands',
		'Holy See (Vatican City State)',
		'Honduras',
		'Hong Kong',
		'Hungary',
		'Iceland',
		'India',
		'Indonesia',
		'Iran, Islamic Republic Of',
		'Iraq',
		'Ireland',
		'Isle of Man',
		'Israel',
		'Italy',
		'Jamaica',
		'Japan',
		'Jersey',
		'Jordan',
		'Kazakhstan',
		'Kenya',
		'Kiribati',
		'Korea, Democratic People Republic of',
		'Korea, Republic of',
		'Kuwait',
		'Kyrgyzstan',
		'Lao People Democratic Republic',
		'Latvia',
		'Lebanon',
		'Lesotho',
		'Liberia',
		'Libyan Arab Jamahiriya',
		'Liechtenstein',
		'Lithuania',
		'Luxembourg',
		'Macao',
		'Macedonia, The Former Yugoslav Republic of',
		'Madagascar',
		'Malawi',
		'Malaysia',
		'Maldives',
		'Mali',
		'Malta',
		'Marshall Islands',
		'Martinique',
		'Mauritania',
		'Mauritius',
		'Mayotte',
		'Mexico',
		'Micronesia, Federated States of',
		'Moldova, Republic of',
		'Monaco',
		'Mongolia',
		'Montserrat',
		'Morocco',
		'Mozambique',
		'Myanmar',
		'Namibia',
		'Nauru',
		'Nepal',
		'Netherlands',
		'Netherlands Antilles',
		'New Caledonia',
		'New Zealand',
		'Nicaragua',
		'Niger',
		'Nigeria',
		'Niue',
		'Norfolk Island',
		'Northern Mariana Islands',
		'Norway',
		'Oman',
		'Pakistan',
		'Palau',
		'Palestinian Territory, Occupied',
		'Panama',
		'Papua New Guinea',
		'Paraguay',
		'Peru',
		'Philippines',
		'Pitcairn',
		'Poland',
		'Portugal',
		'Puerto Rico',
		'Qatar',
		'Reunion',
		'Romania',
		'Russian Federation',
		'Rwanda',
		'Saint Helena',
		'Saint Kitts and Nevis',
		'Saint Lucia',
		'Saint Pierre and Miquelon',
		'Saint Vincent and the Grenadines',
		'Samoa',
		'San Marino',
		'Sao Tome and Principe',
		'Saudi Arabia',
		'Senegal',
		'Serbia and Montenegro',
		'Seychelles',
		'Sierra Leone',
		'Singapore',
		'Slovakia',
		'Slovenia',
		'Solomon Islands',
		'Somalia',
		'South Africa',
		'South Georgia and the South Sandwich Islands',
		'Spain',
		'Sri Lanka',
		'Sudan',
		'Suriname',
		'Svalbard and Jan Mayen',
		'Swaziland',
		'Sweden',
		'Switzerland',
		'Syrian Arab Republic',
		'Taiwan, Province of China',
		'Tajikistan',
		'Tanzania, United Republic of',
		'Thailand',
		'Timor-Leste',
		'Togo',
		'Tokelau',
		'Tonga',
		'Trinidad and Tobago',
		'Tunisia',
		'Turkey',
		'Turkmenistan',
		'Turks and Caicos Islands',
		'Tuvalu',
		'Uganda',
		'Ukraine',
		'United Arab Emirates',
		'United Kingdom',
		'United States',
		'United States Minor Outlying Islands',
		'Uruguay',
		'Uzbekistan',
		'Vanuatu',
		'Venezuela',
		'Viet Nam',
		'Virgin Islands, British',
		'Virgin Islands, U.S.',
		'Wallis and Futuna',
		'Western Sahara',
		'Yemen',
		'Zambia',
		'Zimbabwe'
	];

	onMount(async () => {
		const { data: { session } } = await supabase.auth.getSession();

		if (!session) {
			goto('/auth/login');
			return;
		}

		currentUser = session.user; // Store user globally
		userId = session.user.id;

		// Add a small delay to ensure provider profile is created
		await new Promise(resolve => setTimeout(resolve, 1000));

		const result = await supabase
			.from('healthcare_providers')
			.select('id, medic_subscription_id, phone, profile_photo_url, specialization, sub_specialty, license_number, license_document_url, preferred_languages, country, clinic_address, bio, \"offerChat\", \"offerAudio\", \"offersVideo\", \"offerOfficeVisit\"')
			.eq('user_id', userId)
			.maybeSingle();

		let existingProvider = result.data;
		let providerError = result.error;

		if (providerError) {
			console.error('Database error:', providerError);
			error = `Database error: ${providerError.message}. Please contact support.`;
			pageLoading = false;
			return;
		}

		if (!existingProvider) {
			console.log('No provider profile found. User will create one during onboarding.');
			// We will create the provider record during handleSubmit

			// Try to restore draft
			const draftStr = localStorage.getItem(`onboarding_draft_${userId}`);
			if (draftStr) {
				try {
					const draft = JSON.parse(draftStr);
					if (draft.currentStage) currentStage = draft.currentStage;
					if (draft.phone) phone = draft.phone;
					if (draft.specialization) specialization = draft.specialization;
					if (draft.country) country = draft.country;
					if (draft.clinicAddress) clinicAddress = draft.clinicAddress;
					if (draft.city) city = draft.city;
					if (draft.region) region = draft.region;
					if (draft.bio) bio = draft.bio;
					if (draft.credentials) credentials = draft.credentials;
					if (draft.yearsOfExperience) yearsOfExperience = draft.yearsOfExperience;
					if (draft.licenseNumber) licenseNumber = draft.licenseNumber;
					if (draft.subSpecialty) subSpecialty = draft.subSpecialty;
					if (draft.languagesSpoken) languagesSpoken = draft.languagesSpoken;
					if (draft.consultationTypes && Array.isArray(draft.consultationTypes)) consultationTypes = draft.consultationTypes;
				} catch (e) {
					console.error('Error parsing draft', e);
				}
			}

			pageLoading = false;
			return;
		}

		providerId = existingProvider.id;
		medicSubscriptionId = existingProvider.medic_subscription_id;

		// Pre-fill existing data
		if (existingProvider.phone) phone = existingProvider.phone;
		if (existingProvider.profile_photo_url) profilePicUrl = existingProvider.profile_photo_url;
		if (existingProvider.specialization) specialization = existingProvider.specialization;
		if (existingProvider.sub_specialty) subSpecialty = existingProvider.sub_specialty;
		if (existingProvider.license_number) licenseNumber = existingProvider.license_number;
		if (existingProvider.license_document_url) licenseDocumentUrl = existingProvider.license_document_url;
		if (existingProvider.preferred_languages && Array.isArray(existingProvider.preferred_languages)) {
			languagesSpoken = existingProvider.preferred_languages.join(', ');
		}
		if (existingProvider.country) country = existingProvider.country;
		if (existingProvider.bio) bio = existingProvider.bio;

		if (existingProvider.clinic_address) {
			const addr = existingProvider.clinic_address as any;
			if (addr.street) clinicAddress = addr.street;
			if (addr.city) city = addr.city;
		}

		if (existingProvider) {
			let existingTypes = [];
			if (existingProvider.offerChat) existingTypes.push('chat');
			if (existingProvider.offerAudio) existingTypes.push('audio');
			if (existingProvider.offersVideo) existingTypes.push('video');
			if (existingProvider.offerOfficeVisit) existingTypes.push('office_visit');
			if (existingTypes.length > 0) consultationTypes = existingTypes;
		}

		pageLoading = false;

		const cleanupIdle = setupIdleTracking();
		return () => cleanupIdle();
	});

	async function handleProfilePicUpload(e: Event) {
		const target = e.target as HTMLInputElement;
		const file = target.files?.[0];
		if (file) {
			profilePicFile = file;
			// Create preview URL
			profilePicUrl = URL.createObjectURL(file);
		}
	}

	async function uploadProfilePic(): Promise<string | null> {
		if (!profilePicFile) return profilePicUrl || null;

		try {
			const fileExt = profilePicFile.name.split('.').pop();
			const fileName = `${userId}-${Date.now()}.${fileExt}`;
			const filePath = `profile-pics/${fileName}`;

			const { error: uploadError } = await supabase.storage
				.from('healthcare-providers')
				.upload(filePath, profilePicFile);

			if (uploadError) {
				console.error('Upload error:', uploadError);
				return null;
			}

			const { data } = supabase.storage
				.from('healthcare-providers')
				.getPublicUrl(filePath);

			return data.publicUrl;
		} catch (err) {
			console.error('Profile pic upload failed:', err);
			return null;
		}
	}

	async function handleLicenseUpload(e: Event) {
		const target = e.target as HTMLInputElement;
		const file = target.files?.[0];
		if (file) {
			licenseDocumentFile = file;
			licenseDocumentUrl = URL.createObjectURL(file);
		}
	}

	async function uploadLicenseDoc(): Promise<string | null> {
		if (!licenseDocumentFile) return licenseDocumentUrl || null;

		try {
			const fileExt = licenseDocumentFile.name.split('.').pop();
			const fileName = `license-${userId}-${Date.now()}.${fileExt}`;
			const filePath = `licenses/${fileName}`;

			const { error: uploadError } = await supabase.storage
				.from('healthcare-providers')
				.upload(filePath, licenseDocumentFile);

			if (uploadError) {
				console.error('License upload error:', uploadError);
				return null;
			}

			const { data } = supabase.storage
				.from('healthcare-providers')
				.getPublicUrl(filePath);

			return data.publicUrl;
		} catch (err) {
			console.error('License upload failed:', err);
			return null;
		}
	}

	async function handleStage1Next() {
		if (!phone || !specialization || !country) {
			error = 'Please fill in all required fields';
			return;
		}

		error = '';
		currentStage = 2;
	}

	async function handleStage2Next() {
		if (!clinicAddress || !city || !bio) {
			error = 'Please fill in all required fields';
			return;
		}

		error = '';
		currentStage = 3;
	}

	async function handleSubmit() {
		loading = true;
		error = '';

		try {
			// If providerId is missing, it means we need to INSERT the record
			if (!providerId) {
				const nameForSlug = currentUser.email.split('@')[0];
				const slug = nameForSlug.toLowerCase().replace(/[^a-z0-9]+/g, '-') + '-' + Math.random().toString(36).substr(2, 6);

				const { data: newProvider, error: insertError } = await supabase
					.from('healthcare_providers')
					.insert({
						user_id: userId,
						full_name: currentUser.user_metadata?.full_name || currentUser.email.split('@')[0],
						slug,
						email: currentUser.email,
						type: specialization?.toLowerCase() === 'pharmacist' ? 'pharmacist' : 'doctor',
						specialization: specialization || 'General Practice',
						country: country || 'Nigeria',
						phone: phone,
						"offerChat": consultationTypes.includes('chat'),
						"offerAudio": consultationTypes.includes('audio'),
						"offersVideo": consultationTypes.includes('video'),
						"offerOfficeVisit": consultationTypes.includes('office_visit'),
						"chatFee": 0,
						"videoFee": 0,
						"audioFee": 0,
						"officeFee": 0,
						is_verified: false,
						is_active: true
					})
					.select()
					.single();

				if (insertError) {
					console.error('Provider creation error:', insertError);
					error = 'Failed to create provider profile: ' + insertError.message;
					loading = false;
					return;
				}
				providerId = newProvider.id;
			}

			// Upload profile pic if exists
			let uploadedPicUrl = profilePicUrl;
			if (profilePicFile) {
				const url = await uploadProfilePic();
				if (url) uploadedPicUrl = url;
			}

			// Create or update medic subscription first
			if (!medicSubscriptionId) {
				// Create a default free-tier subscription for healthcare providers
				const now = new Date();
				const billingCycleEnd = new Date(now);
				billingCycleEnd.setMonth(billingCycleEnd.getMonth() + 1);
				const trialEndsAt = new Date(now.getTime() + 60 * 24 * 60 * 60 * 1000);

				const { data: newSubscription, error: subError } = await supabase
					.from('medic_subscriptions')
					.insert({
						user_id: userId,
						provider_id: providerId,
						tier: 'free',
						monthly_fee: 0,
						billing_cycle_start: now.toISOString(),
						billing_cycle_end: billingCycleEnd.toISOString(),
						status: 'trial',
						trial_period: 60,
						trial_ends_at: trialEndsAt.toISOString(),
						features: {
							chat_consultations: true,
							video_consultations: true,
							audio_consultations: true,
							office_consultations: false, // Not available on free tier
							consultation_quota: -1, // Unlimited
							patient_management: true,
							drug_commission_enabled: false, // No commission from drug sales on free tier
							diagnostic_commission_enabled: false, // No commission from diagnostics on free tier
							custom_branding: false,
							analytics_dashboard: true,
							priority_support: false
						},
						consultation_commission_rate: 0,
						drug_commission_rate: 0,
						diagnostic_commission_rate: 0
					})
					.select()
					.single();

				if (subError) {
					console.error('Subscription creation error:', subError);
					error = 'Failed to create subscription: ' + subError.message;
					loading = false;
					return;
				}

				console.log('Medic subscription created:', newSubscription);
				medicSubscriptionId = newSubscription.id;
			}

			let uploadedLicenseUrl = licenseDocumentUrl;
			if (licenseDocumentFile) {
				const url = await uploadLicenseDoc();
				if (url) uploadedLicenseUrl = url;
			}

			const languagesArray = languagesSpoken.split(',').map(l => l.trim()).filter(l => l.length > 0);

			// Update healthcare provider with all data
			const { error: updateError } = await supabase
				.from('healthcare_providers')
				.update({
					phone,
					profile_photo_url: uploadedPicUrl,
					specialization,
					sub_specialty: subSpecialty,
					license_number: licenseNumber,
					license_document_url: uploadedLicenseUrl,
					preferred_languages: languagesArray,
					type: specialization?.toLowerCase() === 'pharmacist' ? 'pharmacist' : 'doctor',
					country,
					region,
					clinic_address: {
						street: clinicAddress,
						city,
						region,
						country
					},
					bio,
					credentials,
					years_of_experience: yearsOfExperience ? parseInt(yearsOfExperience) : 0,
					"offerChat": consultationTypes.includes('chat'),
					"offerAudio": consultationTypes.includes('audio'),
					"offersVideo": consultationTypes.includes('video'),
					"offerOfficeVisit": consultationTypes.includes('office_visit'),
					"chatFee": 0,
					"videoFee": 0,
					"audioFee": 0,
					"officeFee": 0,
					medic_subscription_id: medicSubscriptionId,
					updated_at: new Date().toISOString()
				})
				.eq('id', providerId);

			if (updateError) {
				error = 'Failed to update profile: ' + updateError.message;
				loading = false;
				return;
			}

			// Clear draft after successful completion
			localStorage.removeItem(`onboarding_draft_${userId}`);

			// Redirect to dashboard
			goto('/');
		} catch (err: any) {
			error = err.message || 'An unexpected error occurred';
			loading = false;
		}
	}

	function handleBack() {
		if (currentStage > 1) {
			currentStage--;
		}
	}

	const consultationTypeOptions = [
		{ value: 'chat', label: 'Text Chat' },
		{ value: 'audio', label: 'Audio Call' },
		{ value: 'video', label: 'Video Call' },
		{ value: 'office_visit', label: 'In-Person Visit' }
	];

	function toggleConsultationType(type: string) {
		if (consultationTypes.includes(type)) {
			consultationTypes = consultationTypes.filter(t => t !== type);
		} else {
			consultationTypes = [...consultationTypes, type];
		}
	}
</script>

{#if pageLoading}
	<div class="min-h-screen bg-[#F2FCF6] flex flex-col items-center justify-center p-6 font-sans">
		<div class="text-center">
			<div class="w-16 h-16 border-4 border-[#b8e2c9] border-t-[#1ea85b] rounded-full animate-spin mx-auto mb-4"></div>
			<p class="text-[#4a6357] text-lg">Loading your profile...</p>
		</div>
	</div>
{:else}
<div class="min-h-screen bg-[#F2FCF6] flex flex-col items-center justify-center p-6 font-sans">
	<!-- Progress Bar -->
	<div class="w-full max-w-[600px] mb-8">
		<div class="flex items-center justify-between mb-3">
			<span class="text-sm font-medium text-[#4a6357]">Setup Progress</span>
			<span class="text-sm font-medium text-[#1ea85b]">Step {currentStage} of 3</span>
		</div>
		<div class="w-full h-2 bg-[#b8e2c9] rounded-full overflow-hidden">
			<div
				class="h-full bg-[#1ea85b] transition-all duration-300"
				style="width: {(currentStage / 3) * 100}%"
			></div>
		</div>
	</div>

	<!-- Main Form Container -->
	<div class="w-full max-w-[400px] bg-white rounded-2xl shadow-lg p-8">
		<!-- Header -->
		<div class="text-center mb-8">
			<h1 class="text-3xl font-bold text-[#113022] mb-2 font-sans tracking-tight">
				{#if currentStage === 1}
					Profile Basics
				{:else if currentStage === 2}
					Professional Details
				{:else}
					Final Touches
				{/if}
			</h1>
			<p class="text-[15px] text-[#4a6357]">
				{#if currentStage === 1}
					Let's start with your basic information
				{:else if currentStage === 2}
					Tell us about your practice
				{:else}
					Just a few more details to complete your profile
				{/if}
			</p>
		</div>

		{#if error}
			<div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-xl text-sm mb-6">
				{error}
			</div>
		{/if}

		<!-- Stage 1: Profile Basics -->
		{#if currentStage === 1}
			<div class="space-y-4">
				<!-- Profile Picture -->
				<div class="flex flex-col items-center mb-6">
					<div class="relative">
						{#if profilePicUrl}
							<img src={profilePicUrl} alt="Profile" class="w-24 h-24 rounded-full object-cover border-4 border-[#b8e2c9]" />
						{:else}
							<div class="w-24 h-24 rounded-full bg-[#b8e2c9] flex items-center justify-center">
								<User size={40} class="text-[#1ea85b]" />
							</div>
						{/if}
						<label for="profile-pic" class="absolute bottom-0 right-0 bg-[#1ea85b] text-white p-2 rounded-full cursor-pointer hover:bg-[#168947] transition-colors">
							<Upload size={16} />
						</label>
						<input
							id="profile-pic"
							type="file"
							accept="image/*"
							class="hidden"
							onchange={handleProfilePicUpload}
						/>
					</div>
					<p class="text-xs text-[#4a6357] mt-2">Click to upload profile picture</p>
				</div>

				<!-- Phone -->
				<div class="relative group">
					<div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400 group-focus-within:text-[#1ea85b] transition-colors">
						<Phone size={18} />
					</div>
					<input
						type="tel"
						bind:value={phone}
						required
						placeholder="Phone Number"
						class="w-full pl-10 pr-4 py-3.5 bg-white border border-[#b8e2c9] rounded-xl focus:outline-none focus:ring-[1.5px] focus:ring-[#1ea85b] focus:border-[#1ea85b] text-gray-800 placeholder-gray-400 transition-shadow text-[15px]"
					/>
				</div>

				<!-- Specialization -->
				<div class="relative group">
					<div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400 group-focus-within:text-[#1ea85b] transition-colors z-10">
						<User size={18} />
					</div>
					<select
						bind:value={specialization}
						required
						class="w-full pl-10 pr-4 py-3.5 bg-white border border-[#b8e2c9] rounded-xl focus:outline-none focus:ring-[1.5px] focus:ring-[#1ea85b] focus:border-[#1ea85b] text-gray-800 placeholder-gray-400 transition-shadow text-[15px] appearance-none"
					>
						<option value="" disabled>Select Specialization</option>
						{#each specializations as spec}
							<option value={spec}>{spec}</option>
						{/each}
					</select>
				</div>

				<!-- Country -->
				<div class="relative group">
					<div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400 group-focus-within:text-[#1ea85b] transition-colors z-10">
						<MapPin size={18} />
					</div>
					<select
						bind:value={country}
						required
						class="w-full pl-10 pr-4 py-3.5 bg-white border border-[#b8e2c9] rounded-xl focus:outline-none focus:ring-[1.5px] focus:ring-[#1ea85b] focus:border-[#1ea85b] text-gray-800 placeholder-gray-400 transition-shadow text-[15px] appearance-none"
					>
						<option value="" disabled>Select Country</option>
						{#each countries as c}
							<option value={c}>{c}</option>
						{/each}
					</select>
				</div>

				<button
					type="button"
					onclick={handleStage1Next}
					class="w-full mt-6 bg-[#1ea85b] hover:bg-[#168947] font-semibold text-white py-3.5 px-4 rounded-xl transition-all focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1ea85b] shadow-sm text-[15px]"
				>
					Continue
				</button>
			</div>
		{/if}

		<!-- Stage 2: Professional Details -->
		{#if currentStage === 2}
			<div class="space-y-4">
				<!-- Clinic Address -->
				<div class="relative group">
					<div class="absolute top-4 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400 group-focus-within:text-[#1ea85b] transition-colors">
						<Building size={18} />
					</div>
					<input
						type="text"
						bind:value={clinicAddress}
						required
						placeholder="Clinic Street Address"
						class="w-full pl-10 pr-4 py-3.5 bg-white border border-[#b8e2c9] rounded-xl focus:outline-none focus:ring-[1.5px] focus:ring-[#1ea85b] focus:border-[#1ea85b] text-gray-800 placeholder-gray-400 transition-shadow text-[15px]"
					/>
				</div>

				<!-- City -->
				<div class="relative group">
					<div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400 group-focus-within:text-[#1ea85b] transition-colors">
						<MapPin size={18} />
					</div>
					<input
						type="text"
						bind:value={city}
						required
						placeholder="City"
						class="w-full pl-10 pr-4 py-3.5 bg-white border border-[#b8e2c9] rounded-xl focus:outline-none focus:ring-[1.5px] focus:ring-[#1ea85b] focus:border-[#1ea85b] text-gray-800 placeholder-gray-400 transition-shadow text-[15px]"
					/>
				</div>

				<!-- Region/State -->
				<div class="relative group">
					<div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400 group-focus-within:text-[#1ea85b] transition-colors">
						<MapPin size={18} />
					</div>
					<input
						type="text"
						bind:value={region}
						placeholder="State/Region (Optional)"
						class="w-full pl-10 pr-4 py-3.5 bg-white border border-[#b8e2c9] rounded-xl focus:outline-none focus:ring-[1.5px] focus:ring-[#1ea85b] focus:border-[#1ea85b] text-gray-800 placeholder-gray-400 transition-shadow text-[15px]"
					/>
				</div>

				<!-- Bio -->
				<div class="relative group">
					<div class="absolute top-4 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400 group-focus-within:text-[#1ea85b] transition-colors">
						<FileText size={18} />
					</div>
					<textarea
						bind:value={bio}
						required
						placeholder="Tell patients about yourself and your practice..."
						rows="4"
						class="w-full pl-10 pr-4 py-3.5 bg-white border border-[#b8e2c9] rounded-xl focus:outline-none focus:ring-[1.5px] focus:ring-[#1ea85b] focus:border-[#1ea85b] text-gray-800 placeholder-gray-400 transition-shadow text-[15px] resize-none"
					></textarea>
				</div>

				<div class="flex gap-3 mt-6">
					<button
						type="button"
						onclick={handleBack}
						class="flex-1 bg-white hover:bg-gray-50 border border-[#b8e2c9] text-[#113022] py-3.5 px-4 rounded-xl font-medium transition-all focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1ea85b] text-[15px]"
					>
						Back
					</button>
					<button
						type="button"
						onclick={handleStage2Next}
						class="flex-1 bg-[#1ea85b] hover:bg-[#168947] font-semibold text-white py-3.5 px-4 rounded-xl transition-all focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1ea85b] shadow-sm text-[15px]"
					>
						Continue
					</button>
				</div>
			</div>
		{/if}

		<!-- Stage 3: Additional Settings -->
		{#if currentStage === 3}
			<div class="space-y-4">
				<!-- License Number -->
				<div class="relative group">
					<input
						type="text"
						bind:value={licenseNumber}
						placeholder="License Number (e.g. MDCN/PCN)"
						class="w-full px-4 py-3.5 bg-white border border-[#b8e2c9] rounded-xl focus:outline-none focus:ring-[1.5px] focus:ring-[#1ea85b] focus:border-[#1ea85b] text-gray-800 placeholder-gray-400 transition-shadow text-[15px]"
					/>
				</div>

				<!-- License Document Upload -->
				<div class="relative group">
					<label class="block text-sm font-medium text-[#4a6357] mb-2">Upload License Document</label>
					<div class="flex items-center gap-4">
						<label class="flex-1 flex justify-center w-full px-4 py-3.5 bg-white border border-dashed border-[#b8e2c9] rounded-xl cursor-pointer hover:border-[#1ea85b] transition-colors focus-within:ring-[1.5px] focus-within:ring-[#1ea85b]">
							<span class="text-gray-500 text-[15px] truncate">
								{licenseDocumentFile ? licenseDocumentFile.name : (licenseDocumentUrl ? 'Update License Document' : 'Choose a file...')}
							</span>
							<input
								type="file"
								accept="image/*,application/pdf"
								onchange={handleLicenseUpload}
								class="sr-only"
							/>
						</label>
						{#if licenseDocumentUrl}
							<div class="flex items-center gap-2">
								<Check size={20} class="text-[#1ea85b]" />
							</div>
						{/if}
					</div>
				</div>

				<!-- Sub-Specialty -->
				<div class="relative group">
					<input
						type="text"
						bind:value={subSpecialty}
						placeholder="Sub-Specialty (Optional)"
						class="w-full px-4 py-3.5 bg-white border border-[#b8e2c9] rounded-xl focus:outline-none focus:ring-[1.5px] focus:ring-[#1ea85b] focus:border-[#1ea85b] text-gray-800 placeholder-gray-400 transition-shadow text-[15px]"
					/>
				</div>

				<!-- Languages Spoken -->
				<div class="relative group">
					<input
						type="text"
						bind:value={languagesSpoken}
						placeholder="Languages Spoken (comma-separated, e.g. English, French)"
						class="w-full px-4 py-3.5 bg-white border border-[#b8e2c9] rounded-xl focus:outline-none focus:ring-[1.5px] focus:ring-[#1ea85b] focus:border-[#1ea85b] text-gray-800 placeholder-gray-400 transition-shadow text-[15px]"
					/>
				</div>

				<!-- Credentials -->
				<div class="relative group">
					<input
						type="text"
						bind:value={credentials}
						placeholder="Credentials (e.g., MD, MBBS)"
						class="w-full px-4 py-3.5 bg-white border border-[#b8e2c9] rounded-xl focus:outline-none focus:ring-[1.5px] focus:ring-[#1ea85b] focus:border-[#1ea85b] text-gray-800 placeholder-gray-400 transition-shadow text-[15px]"
					/>
				</div>

				<!-- Years of Experience -->
				<div class="relative group">
					<input
						type="number"
						bind:value={yearsOfExperience}
						placeholder="Years of Experience"
						min="0"
						max="50"
						class="w-full px-4 py-3.5 bg-white border border-[#b8e2c9] rounded-xl focus:outline-none focus:ring-[1.5px] focus:ring-[#1ea85b] focus:border-[#1ea85b] text-gray-800 placeholder-gray-400 transition-shadow text-[15px]"
					/>
				</div>

				<!-- Consultation Types -->
				<div class="space-y-3">
					<label class="text-sm font-medium text-[#4a6357]">Consultation Types Offered</label>
					<div class="space-y-2">
						{#each consultationTypeOptions as option}
							<label class="flex items-center gap-3 p-3 bg-white border border-[#b8e2c9] rounded-xl cursor-pointer hover:border-[#1ea85b] transition-colors">
								<input
									type="checkbox"
									checked={consultationTypes.includes(option.value)}
									onchange={() => toggleConsultationType(option.value)}
									class="w-4 h-4 text-[#1ea85b] border-gray-300 rounded focus:ring-[#1ea85b]"
								/>
								<span class="text-[15px] text-gray-800">{option.label}</span>
								{#if consultationTypes.includes(option.value)}
									<Check size={16} class="ml-auto text-[#1ea85b]" />
								{/if}
							</label>
						{/each}
					</div>
				</div>

				<div class="flex gap-3 mt-6">
					<button
						type="button"
						onclick={handleBack}
						disabled={loading}
						class="flex-1 bg-white hover:bg-gray-50 border border-[#b8e2c9] text-[#113022] py-3.5 px-4 rounded-xl font-medium transition-all focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1ea85b] text-[15px] disabled:opacity-50 disabled:cursor-not-allowed"
					>
						Back
					</button>
					<button
						type="button"
						onclick={handleSubmit}
						disabled={loading}
						class="flex-1 bg-[#1ea85b] hover:bg-[#168947] font-semibold text-white py-3.5 px-4 rounded-xl transition-all focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1ea85b] shadow-sm text-[15px] disabled:opacity-70 disabled:cursor-not-allowed"
					>
						{loading ? 'Completing Setup...' : 'Complete Setup'}
					</button>
				</div>
			</div>
		{/if}
	</div>
</div>
{/if}
