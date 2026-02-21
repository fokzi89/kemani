<script lang="ts">
    import { formatCurrency } from "$lib/storefront/pricing";
    import { createEventDispatcher } from "svelte";
    import type { DeliveryMethodEnum } from "$lib/types/database";

    const dispatch = createEventDispatcher();

    type Method = {
        id: string;
        label: string;
        description: string;
        baseFee: number;
        icon: string;
    };

    const METHODS: Method[] = [
        {
            id: "self_pickup",
            label: "Self Pickup",
            description: "Pick up from the store — no delivery fee",
            baseFee: 0,
            icon: "🏪",
        },
        {
            id: "bicycle",
            label: "Bicycle Delivery",
            description: "Eco-friendly delivery within 3km",
            baseFee: 300,
            icon: "🚲",
        },
        {
            id: "motorbike",
            label: "Motorbike Delivery",
            description: "Fast delivery within 10km",
            baseFee: 500,
            icon: "🏍️",
        },
        {
            id: "platform",
            label: "Platform Delivery",
            description: "Standard platform logistics",
            baseFee: 800,
            icon: "🚚",
        },
    ];

    export let selected: string = "self_pickup";
    export let disabled = false;

    $: selectedMethod = METHODS.find((m) => m.id === selected) ?? METHODS[0];
    $: baseFee = selectedMethod.baseFee;

    $: dispatch("change", { method: selected, baseFee });

    function select(id: string) {
        if (disabled) return;
        selected = id;
    }
</script>

<div class="space-y-3">
    <h3 class="text-sm font-medium leading-none">Delivery Method</h3>
    <div class="grid gap-3 sm:grid-cols-2">
        {#each METHODS as method}
            <button
                type="button"
                on:click={() => select(method.id)}
                {disabled}
                class="flex flex-col items-start gap-1 rounded-lg border-2 p-4 text-left transition-all hover:bg-accent/50 {selected ===
                method.id
                    ? 'border-primary bg-primary/5'
                    : 'border-input'}"
            >
                <div class="flex w-full items-center justify-between">
                    <span class="text-lg">{method.icon}</span>
                    <span class="text-sm font-semibold text-primary">
                        {method.baseFee === 0
                            ? "Free"
                            : formatCurrency(method.baseFee)}
                    </span>
                </div>
                <span class="text-sm font-medium">{method.label}</span>
                <span class="text-xs text-muted-foreground"
                    >{method.description}</span
                >
            </button>
        {/each}
    </div>
</div>
