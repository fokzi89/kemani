<script lang="ts">
    import { createEventDispatcher } from "svelte";

    const dispatch = createEventDispatcher();

    export let name = "";
    export let phone = "";
    export let address = "";
    export let instructions = "";
    export let disabled = false;

    $: isValid =
        name.trim().length > 0 &&
        phone.trim().length >= 10 &&
        address.trim().length > 0;

    function handleSubmit() {
        if (!isValid) return;
        dispatch("submit", { name, phone, address, instructions });
    }
</script>

<form on:submit|preventDefault={handleSubmit} class="space-y-4">
    <div class="space-y-2">
        <label for="delivery-name" class="text-sm font-medium leading-none"
            >Full Name *</label
        >
        <input
            id="delivery-name"
            type="text"
            bind:value={name}
            placeholder="Enter your full name"
            required
            {disabled}
            class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
        />
    </div>

    <div class="space-y-2">
        <label for="delivery-phone" class="text-sm font-medium leading-none"
            >Phone Number *</label
        >
        <input
            id="delivery-phone"
            type="tel"
            bind:value={phone}
            placeholder="+234 800 000 0000"
            required
            {disabled}
            class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
        />
    </div>

    <div class="space-y-2">
        <label for="delivery-address" class="text-sm font-medium leading-none"
            >Delivery Address *</label
        >
        <textarea
            id="delivery-address"
            bind:value={address}
            placeholder="Enter delivery address"
            rows="3"
            required
            {disabled}
            class="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
        ></textarea>
    </div>

    <div class="space-y-2">
        <label
            for="delivery-instructions"
            class="text-sm font-medium leading-none"
            >Delivery Instructions (optional)</label
        >
        <textarea
            id="delivery-instructions"
            bind:value={instructions}
            placeholder="E.g. Ring the bell, leave at gate..."
            rows="2"
            {disabled}
            class="flex min-h-[60px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
        ></textarea>
    </div>

    <slot name="actions" {isValid} />
</form>
