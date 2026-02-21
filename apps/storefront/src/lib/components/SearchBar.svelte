<script lang="ts">
    import { createEventDispatcher } from "svelte";

    const dispatch = createEventDispatcher();

    export let value = "";
    export let placeholder = "Search products...";
    export let disabled = false;

    let debounceTimer: ReturnType<typeof setTimeout>;

    function handleInput() {
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(() => {
            dispatch("search", { query: value.trim() });
        }, 300);
    }

    function handleClear() {
        value = "";
        dispatch("search", { query: "" });
    }

    function handleKeydown(e: KeyboardEvent) {
        if (e.key === "Escape") handleClear();
        if (e.key === "Enter") {
            clearTimeout(debounceTimer);
            dispatch("search", { query: value.trim() });
        }
    }
</script>

<div class="relative w-full">
    <svg
        xmlns="http://www.w3.org/2000/svg"
        width="16"
        height="16"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
        class="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground"
    >
        <circle cx="11" cy="11" r="8" />
        <path d="m21 21-4.3-4.3" />
    </svg>

    <input
        type="search"
        bind:value
        on:input={handleInput}
        on:keydown={handleKeydown}
        {placeholder}
        {disabled}
        class="flex h-10 w-full rounded-md border border-input bg-background pl-9 pr-9 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
    />

    {#if value}
        <button
            type="button"
            on:click={handleClear}
            class="absolute right-2 top-1/2 -translate-y-1/2 rounded-sm p-1 text-muted-foreground hover:text-foreground"
            aria-label="Clear search"
        >
            <svg
                xmlns="http://www.w3.org/2000/svg"
                width="14"
                height="14"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                ><path d="M18 6 6 18" /><path d="m6 6 12 12" /></svg
            >
        </button>
    {/if}
</div>
