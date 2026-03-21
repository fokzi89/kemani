<script lang="ts">
	import { X } from 'lucide-svelte';

	interface Props {
		open?: boolean;
		title: string;
		onClose: () => void;
		children?: any;
	}

	let { open = $bindable(false), title, onClose, children }: Props = $props();

	function handleBackdropClick(e: MouseEvent) {
		if (e.target === e.currentTarget) {
			onClose();
		}
	}

	function handleEscapeKey(e: KeyboardEvent) {
		if (e.key === 'Escape' && open) {
			onClose();
		}
	}
</script>

<svelte:window onkeydown={handleEscapeKey} />

{#if open}
	<!-- Backdrop -->
	<div
		class="fixed inset-0 bg-black/50 z-40 transition-opacity"
		onclick={handleBackdropClick}
		role="button"
		tabindex="-1"
	></div>

	<!-- Modal -->
	<div class="fixed inset-0 z-50 flex items-center justify-center p-4 pointer-events-none">
		<div
			class="bg-white rounded-lg shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-hidden pointer-events-auto"
		>
			<!-- Header -->
			<div class="flex items-center justify-between p-6 border-b border-gray-200">
				<h2 class="text-2xl font-bold text-gray-900">{title}</h2>
				<button
					onclick={onClose}
					class="p-2 hover:bg-gray-100 rounded-lg transition-colors"
					aria-label="Close modal"
				>
					<X class="h-5 w-5 text-gray-600" />
				</button>
			</div>

			<!-- Content -->
			<div class="p-6 overflow-y-auto max-h-[calc(90vh-140px)]">
				{@render children?.()}
			</div>
		</div>
	</div>
{/if}
