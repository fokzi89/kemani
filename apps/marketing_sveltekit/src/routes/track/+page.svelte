<script lang="ts">
    import MapPin from "lucide-svelte/icons/map-pin";
    import Package from "lucide-svelte/icons/package";
    import Truck from "lucide-svelte/icons/truck";
    import CheckCircle from "lucide-svelte/icons/check-circle";

    let orderId = $state("");
    let trackingResult: any = $state(null);
    let loading = $state(false);

    async function trackOrder() {
        if (!orderId) return;
        loading = true;

        // Simulate API call
        setTimeout(() => {
            trackingResult = {
                id: orderId,
                status: "Out for Delivery",
                estimatedDelivery: "Today, 2:00 PM - 4:00 PM",
                steps: [
                    {
                        status: "Order Placed",
                        date: "Feb 12, 10:00 AM",
                        completed: true,
                    },
                    {
                        status: "Processing",
                        date: "Feb 12, 10:30 AM",
                        completed: true,
                    },
                    {
                        status: "Out for Delivery",
                        date: "Feb 12, 1:00 PM",
                        completed: true,
                    },
                    { status: "Delivered", date: "-", completed: false },
                ],
            };
            loading = false;
        }, 1000);
    }
</script>

<div class="container mx-auto px-4 py-12 max-w-2xl">
    <h1
        class="text-3xl font-bold text-center mb-8 text-gray-900 dark:text-white"
    >
        Track Your Order
    </h1>

    <div
        class="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border dark:border-gray-700 mb-8"
    >
        <div class="flex gap-4">
            <input
                type="text"
                bind:value={orderId}
                placeholder="Enter Order ID (e.g., ORD-12345)"
                class="flex-1 px-4 py-3 border rounded-lg dark:bg-gray-700 dark:border-gray-600 focus:ring-2 focus:ring-emerald-500"
            />
            <button
                onclick={trackOrder}
                disabled={loading}
                class="bg-emerald-600 text-white font-bold px-6 py-3 rounded-lg hover:bg-emerald-700 transition disabled:opacity-50"
            >
                {loading ? "Tracking..." : "Track"}
            </button>
        </div>
    </div>

    {#if trackingResult}
        <div
            class="bg-white dark:bg-gray-800 p-8 rounded-xl shadow-sm border dark:border-gray-700 animate-in fade-in slide-in-from-bottom-4 duration-500"
        >
            <div class="flex items-center justify-between mb-6">
                <div>
                    <h2 class="text-xl font-bold text-gray-900 dark:text-white">
                        Order #{trackingResult.id}
                    </h2>
                    <p class="text-emerald-600 font-medium">
                        {trackingResult.status}
                    </p>
                </div>
                <div class="text-right">
                    <p class="text-xs text-gray-500 uppercase font-bold">
                        Estimated Delivery
                    </p>
                    <p class="font-medium text-gray-900 dark:text-white mt-1">
                        {trackingResult.estimatedDelivery}
                    </p>
                </div>
            </div>

            <div
                class="relative pl-8 border-l-2 border-gray-200 dark:border-gray-700 space-y-8"
            >
                {#each trackingResult.steps as step, i}
                    <div class="relative">
                        <div
                            class="absolute -left-[41px] bg-white dark:bg-gray-800 p-1"
                        >
                            <div
                                class="w-6 h-6 rounded-full flex items-center justify-center {step.completed
                                    ? 'bg-emerald-600 text-white'
                                    : 'bg-gray-200 dark:bg-gray-700 text-gray-400'}"
                            >
                                {#if step.status.includes("Placed")}
                                    <Package class="h-3 w-3" />
                                {:else if step.status.includes("Delivery")}
                                    <Truck class="h-3 w-3" />
                                {:else if step.status.includes("Delivered")}
                                    <CheckCircle class="h-3 w-3" />
                                {:else}
                                    <div
                                        class="w-2 h-2 rounded-full bg-current"
                                    ></div>
                                {/if}
                            </div>
                        </div>
                        <div>
                            <h3
                                class="font-bold text-gray-900 dark:text-white {step.completed
                                    ? ''
                                    : 'text-gray-400'}"
                            >
                                {step.status}
                            </h3>
                            <p class="text-sm text-gray-500">{step.date}</p>
                        </div>
                    </div>
                {/each}
            </div>
        </div>
    {/if}
</div>
