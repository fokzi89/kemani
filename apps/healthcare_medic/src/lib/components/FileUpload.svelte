<script lang="ts">
	import { Upload, X, FileText, Image as ImageIcon } from 'lucide-svelte';

	interface Props {
		accept?: string;
		maxSize?: number; // in bytes
		preview?: boolean;
		file?: File | null;
		previewUrl?: string;
		onFileSelect: (file: File | null) => void;
		label?: string;
		error?: string;
	}

	let {
		accept = 'image/*',
		maxSize = 2097152, // 2MB default
		preview = true,
		file = $bindable(null),
		previewUrl = $bindable(''),
		onFileSelect,
		label = 'Upload File',
		error = ''
	}: Props = $props();

	let fileInput: HTMLInputElement;
	let localError = $state('');

	function handleFileSelect(e: Event) {
		const target = e.target as HTMLInputElement;
		const selectedFile = target.files?.[0];

		if (!selectedFile) return;

		// Validate file size
		if (selectedFile.size > maxSize) {
			localError = `File size exceeds ${(maxSize / 1024 / 1024).toFixed(1)}MB`;
			return;
		}

		localError = '';
		file = selectedFile;

		// Create preview URL for images
		if (preview && selectedFile.type.startsWith('image/')) {
			previewUrl = URL.createObjectURL(selectedFile);
		}

		onFileSelect(selectedFile);
	}

	function removeFile() {
		file = null;
		previewUrl = '';
		localError = '';
		if (fileInput) fileInput.value = '';
		onFileSelect(null);
	}
</script>

<div class="space-y-2">
	<label class="block text-sm font-medium text-gray-700">{label}</label>

	{#if !file}
		<div
			class="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-primary-500 transition-colors cursor-pointer"
			onclick={() => fileInput?.click()}
			role="button"
			tabindex="0"
		>
			<Upload class="h-8 w-8 text-gray-400 mx-auto mb-2" />
			<p class="text-sm text-gray-600">Click to upload or drag and drop</p>
			<p class="text-xs text-gray-500 mt-1">
				Max size: {(maxSize / 1024 / 1024).toFixed(1)}MB
			</p>
		</div>
		<input bind:this={fileInput} type="file" {accept} onchange={handleFileSelect} class="hidden" />
	{:else}
		<div class="border border-gray-200 rounded-lg p-4 flex items-center gap-4">
			{#if previewUrl}
				<img src={previewUrl} alt="Preview" class="h-16 w-16 object-cover rounded" />
			{:else if file.type === 'application/pdf'}
				<FileText class="h-16 w-16 text-red-500" />
			{:else}
				<ImageIcon class="h-16 w-16 text-gray-400" />
			{/if}

			<div class="flex-1">
				<p class="text-sm font-medium text-gray-900">{file.name}</p>
				<p class="text-xs text-gray-500">{(file.size / 1024).toFixed(1)} KB</p>
			</div>

			<button
				onclick={removeFile}
				class="p-2 hover:bg-red-50 rounded-lg transition-colors"
				type="button"
			>
				<X class="h-5 w-5 text-red-600" />
			</button>
		</div>
	{/if}

	{#if localError || error}
		<p class="text-sm text-red-600">{localError || error}</p>
	{/if}
</div>
