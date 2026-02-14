<script module>
    import Plus from "lucide-svelte/icons/plus";
</script>

<script lang="ts">
    import { user } from "$lib/stores/user";
    import { goto } from "$app/navigation";
    import { onMount } from "svelte";
    import Package from "lucide-svelte/icons/package";
    import MapPin from "lucide-svelte/icons/map-pin";
    import LogOut from "lucide-svelte/icons/log-out";
    import { logout } from "$lib/services/auth";

    onMount(() => {
        if (!$user) {
            goto("/login");
        }
    });

    let activeTab = $state("orders"); // orders | settings

    // Mock Orders
    const orders = [
        {
            id: "ORD-1739395200",
            date: "Feb 12, 2026",
            total: 15500,
            status: "Processing",
            items: 3,
        },
        {
            id: "ORD-1738876800",
            date: "Feb 06, 2026",
            total: 8200,
            status: "Delivered",
            items: 1,
        },
    ];
</script>

<div class="container mx-auto px-4 py-8 max-w-5xl">
    <div class="flex flex-col md:flex-row gap-8">
        <!-- Sidebar -->
        <div class="w-full md:w-64 space-y-2">
            <div
                class="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border dark:border-gray-700 mb-6 text-center"
            >
                <div
                    class="w-20 h-20 bg-emerald-100 dark:bg-emerald-900/30 rounded-full mx-auto mb-4 flex items-center justify-center text-2xl font-bold text-emerald-600"
                >
                    {$user?.name?.charAt(0) || "U"}
                </div>
                <h2 class="font-bold text-gray-900 dark:text-white truncate">
                    {$user?.name}
                </h2>
                <p class="text-sm text-gray-500 truncate">{$user?.email}</p>
            </div>

            <button
                onclick={() => (activeTab = "orders")}
                class="w-full text-left px-6 py-3 rounded-xl transition flex items-center gap-3 {activeTab ===
                'orders'
                    ? 'bg-emerald-600 text-white shadow-lg'
                    : 'bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-200'}"
            >
                <Package class="h-5 w-5" />
                Orders
            </button>

            <button
                onclick={() => (activeTab = "settings")}
                class="w-full text-left px-6 py-3 rounded-xl transition flex items-center gap-3 {activeTab ===
                'settings'
                    ? 'bg-emerald-600 text-white shadow-lg'
                    : 'bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-200'}"
            >
                <MapPin class="h-5 w-5" />
                Settings
            </button>

            <button
                onclick={logout}
                class="w-full text-left px-6 py-3 rounded-xl transition flex items-center gap-3 bg-red-50 text-red-600 hover:bg-red-100 dark:bg-red-900/20 dark:hover:bg-red-900/30 font-medium mt-8"
            >
                <LogOut class="h-5 w-5" />
                Sign Out
            </button>
        </div>

        <!-- Content -->
        <div class="flex-1">
            {#if activeTab === "orders"}
                <h2
                    class="text-2xl font-bold mb-6 text-gray-900 dark:text-white"
                >
                    Order History
                </h2>

                <div class="space-y-4">
                    {#each orders as order}
                        <div
                            class="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border dark:border-gray-700 hover:shadow-md transition"
                        >
                            <div
                                class="flex flex-col sm:flex-row justify-between sm:items-center gap-4 mb-4"
                            >
                                <div>
                                    <div class="text-sm text-gray-500">
                                        Order <span
                                            class="font-medium text-gray-900 dark:text-white"
                                            >#{order.id}</span
                                        >
                                    </div>
                                    <div class="text-xs text-gray-400">
                                        {order.date}
                                    </div>
                                </div>
                                <div class="flex items-center gap-3">
                                    <span
                                        class="px-3 py-1 rounded-full text-xs font-medium {order.status ===
                                        'Delivered'
                                            ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                                            : 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400'}"
                                    >
                                        {order.status}
                                    </span>
                                    <span
                                        class="font-bold text-gray-900 dark:text-white"
                                        >₦{order.total.toLocaleString()}</span
                                    >
                                </div>
                            </div>
                            <div
                                class="flex justify-between items-center pt-4 border-t dark:border-gray-700"
                            >
                                <span class="text-sm text-gray-500"
                                    >{order.items} items</span
                                >
                                <button
                                    class="text-emerald-600 font-medium text-sm hover:underline"
                                    >View Details</button
                                >
                            </div>
                        </div>
                    {/each}
                </div>
            {:else if activeTab === "settings"}
                <h2
                    class="text-2xl font-bold mb-6 text-gray-900 dark:text-white"
                >
                    Account Settings
                </h2>

                <div
                    class="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border dark:border-gray-700"
                >
                    <h3 class="font-bold text-lg mb-4">Saved Address</h3>

                    <div
                        class="p-4 border border-emerald-500 bg-emerald-50 dark:bg-emerald-900/20 dark:border-emerald-800 rounded-lg relative"
                    >
                        <div
                            class="absolute top-4 right-4 text-emerald-600 text-xs font-bold uppercase tracking-wider"
                        >
                            Default
                        </div>
                        <p class="font-medium text-gray-900 dark:text-white">
                            {$user?.name}
                        </p>
                        <p class="text-gray-600 dark:text-gray-300 mt-1">
                            {$user?.addresses?.[0]?.street ||
                                "No address saved."}
                        </p>
                        <p class="text-gray-600 dark:text-gray-300 mt-1">
                            {$user?.phone}
                        </p>

                        <div class="mt-4 flex gap-4">
                            <button
                                class="text-sm text-emerald-600 font-medium hover:underline"
                                >Edit</button
                            >
                            <button
                                class="text-sm text-red-500 font-medium hover:underline"
                                >Delete</button
                            >
                        </div>
                    </div>

                    <button
                        class="mt-6 flex items-center justify-center w-full sm:w-auto px-6 py-2 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg text-gray-500 hover:border-emerald-500 hover:text-emerald-600 transition"
                    >
                        <Plus class="h-4 w-4 mr-2" />
                        Add New Address
                    </button>
                </div>
            {/if}
        </div>
    </div>
</div>
