<script lang="ts">
    import { cart } from "$lib/stores/cart";
    import { user, type UserProfile } from "$lib/stores/user";
    import { goto } from "$app/navigation";
    import { browser } from "$app/environment";
    import { continueAsGuest } from "$lib/services/auth";
    import { onMount } from "svelte";
    import Check from "lucide-svelte/icons/check";

    if (browser && $cart.items.length === 0) goto("/shop");

    let step = $state(1); // 1: Info, 2: Delivery, 3: Payment
    let loading = $state(false);

    // Form Data
    let formData = $state({
        name: $user?.name || "",
        phone: $user?.phone || "",
        address: $user?.addresses?.[0]?.street || "",
        email: $user?.email || "",
        note: "",
    });

    // Delivery Options
    const deliveryMethods = [
        {
            id: "pickup",
            name: "Self Pick Up",
            baseFee: 0,
            desc: "Collect from store",
        },
        {
            id: "bicycle",
            name: "Bicycle Delivery",
            baseFee: 500,
            desc: "Local delivery",
        },
        {
            id: "bike",
            name: "Motor Bike Delivery",
            baseFee: 1000,
            desc: "City-wide delivery",
        },
        {
            id: "platform",
            name: "Platform Delivery",
            baseFee: 2000,
            desc: "Inter-city delivery",
        },
    ];

    let selectedMethodId = $state("pickup");
    let selectedMethod = $derived(
        deliveryMethods.find((m) => m.id === selectedMethodId) ||
            deliveryMethods[0],
    );

    // Fees
    const transactionFee = 100;
    const platformFee = 50;
    const deliveryAddition = 100;

    let subtotal = $derived(
        $cart.items.reduce((acc, item) => acc + item.price * item.quantity, 0),
    );
    let deliveryFee = $derived(
        selectedMethod.baseFee +
            (selectedMethod.id === "pickup" ? 100 : deliveryAddition),
    );
    // pickup base 0 + 100 = 100. others base + 100. Correct per spec?
    // Spec: "System MUST add N100 to the calculated delivery fee for all orders (except Self Pick Up which has base fee N0 + N100 = N100)"
    // Wait, spec says "except Self Pick Up which has base fee N0 + N100 = N100". So actually ALL methods get +100.

    let total = $derived(subtotal + deliveryFee + platformFee + transactionFee);

    async function handleInfoSubmit() {
        if (!$user) {
            // Guest checkout logic
            await continueAsGuest({
                name: formData.name,
                phone: formData.phone,
                address: formData.address,
            });
        }
        step = 2;
    }

    async function handlePayment() {
        if (!$user?.email && !formData.email) {
            alert("Email is required for payment");
            return;
        }

        loading = true;

        const amountInKobo = Math.round(total * 100);
        const email = $user?.email || formData.email;
        const reference = `ORD-${Date.now()}`; // Generate unique ref

        initializePayment(
            {
                email,
                amount: amountInKobo,
                reference,
                metadata: {
                    custom_fields: [
                        {
                            display_name: "Customer Name",
                            variable_name: "customer_name",
                            value: formData.name,
                        },
                        {
                            display_name: "Phone",
                            variable_name: "phone",
                            value: formData.phone,
                        },
                    ],
                },
            },
            (response) => {
                // On Success
                loading = false;
                goto("/checkout/success");
                cart.clear();
            },
            () => {
                // On Close
                loading = false;
            },
        );
    }
</script>

<div class="container mx-auto px-4 py-8 max-w-4xl">
    <div class="flex items-center justify-center mb-8">
        <!-- Steps Indicator -->
        <div class="flex items-center">
            <div
                class="flex items-center justify-center w-8 h-8 rounded-full {step >=
                1
                    ? 'bg-emerald-600 text-white'
                    : 'bg-gray-200 text-gray-500'} font-bold"
            >
                1
            </div>
            <div class="w-16 h-1 bg-gray-200 mx-2">
                <div
                    class="h-full bg-emerald-600 transition-all {step >= 2
                        ? 'w-full'
                        : 'w-0'}"
                ></div>
            </div>
            <div
                class="flex items-center justify-center w-8 h-8 rounded-full {step >=
                2
                    ? 'bg-emerald-600 text-white'
                    : 'bg-gray-200 text-gray-500'} font-bold"
            >
                2
            </div>
            <div class="w-16 h-1 bg-gray-200 mx-2">
                <div
                    class="h-full bg-emerald-600 transition-all {step >= 3
                        ? 'w-full'
                        : 'w-0'}"
                ></div>
            </div>
            <div
                class="flex items-center justify-center w-8 h-8 rounded-full {step >=
                3
                    ? 'bg-emerald-600 text-white'
                    : 'bg-gray-200 text-gray-500'} font-bold"
            >
                3
            </div>
        </div>
    </div>

    <div class="grid md:grid-cols-3 gap-8">
        <!-- Main Form -->
        <div class="md:col-span-2 space-y-6">
            {#if step === 1}
                <div
                    class="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border dark:border-gray-700"
                >
                    <h2
                        class="text-xl font-bold mb-4 text-gray-900 dark:text-white"
                    >
                        Contact & Delivery
                    </h2>
                    <form
                        class="space-y-4"
                        onsubmit={(e) => {
                            e.preventDefault();
                            handleInfoSubmit();
                        }}
                    >
                        <div class="grid md:grid-cols-2 gap-4">
                            <div>
                                <label class="block text-sm font-medium mb-1"
                                    >Name</label
                                >
                                <input
                                    type="text"
                                    bind:value={formData.name}
                                    required
                                    class="w-full px-4 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                                />
                            </div>
                            <div>
                                <label class="block text-sm font-medium mb-1"
                                    >Phone</label
                                >
                                <input
                                    type="tel"
                                    bind:value={formData.phone}
                                    required
                                    class="w-full px-4 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                                />
                            </div>
                        </div>
                        <div>
                            <label class="block text-sm font-medium mb-1"
                                >Email (Optional)</label
                            >
                            <input
                                type="email"
                                bind:value={formData.email}
                                class="w-full px-4 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                            />
                        </div>
                        <div>
                            <label class="block text-sm font-medium mb-1"
                                >Address</label
                            >
                            <textarea
                                bind:value={formData.address}
                                required
                                rows="3"
                                class="w-full px-4 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                            ></textarea>
                        </div>
                        <button
                            type="submit"
                            class="w-full bg-emerald-600 text-white font-bold py-3 rounded-lg hover:bg-emerald-700 transition"
                        >
                            Continue to Delivery
                        </button>
                    </form>
                </div>
            {:else if step === 2}
                <div
                    class="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border dark:border-gray-700"
                >
                    <h2
                        class="text-xl font-bold mb-4 text-gray-900 dark:text-white"
                    >
                        Delivery Method
                    </h2>
                    <div class="space-y-3">
                        {#each deliveryMethods as method}
                            <label
                                class="flex items-center justify-between p-4 border rounded-xl cursor-pointer transition {selectedMethodId ===
                                method.id
                                    ? 'border-emerald-600 bg-emerald-50 dark:bg-emerald-900/20'
                                    : 'hover:bg-gray-50 dark:hover:bg-gray-700'}"
                            >
                                <div class="flex items-center gap-3">
                                    <input
                                        type="radio"
                                        name="delivery"
                                        value={method.id}
                                        bind:group={selectedMethodId}
                                        class="text-emerald-600 focus:ring-emerald-500"
                                    />
                                    <div>
                                        <div
                                            class="font-medium text-gray-900 dark:text-white"
                                        >
                                            {method.name}
                                        </div>
                                        <div class="text-sm text-gray-500">
                                            {method.desc}
                                        </div>
                                    </div>
                                </div>
                                <div
                                    class="font-bold text-gray-900 dark:text-white"
                                >
                                    {#if method.baseFee === 0}
                                        Free
                                    {:else}
                                        ₦{method.baseFee.toLocaleString()}
                                    {/if}
                                </div>
                            </label>
                        {/each}
                    </div>
                    <div class="mt-6 flex gap-4">
                        <button
                            onclick={() => (step = 1)}
                            class="text-gray-500 font-medium px-4">Back</button
                        >
                        <button
                            onclick={() => (step = 3)}
                            class="flex-1 bg-emerald-600 text-white font-bold py-3 rounded-lg hover:bg-emerald-700 transition"
                        >
                            Continue to Payment
                        </button>
                    </div>
                </div>
            {:else if step === 3}
                <div
                    class="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border dark:border-gray-700"
                >
                    <h2
                        class="text-xl font-bold mb-4 text-gray-900 dark:text-white"
                    >
                        Payment
                    </h2>

                    <div
                        class="bg-gray-50 dark:bg-gray-900 p-4 rounded-lg mb-6"
                    >
                        <div class="flex justify-between mb-2">
                            <span class="text-gray-600 dark:text-gray-400"
                                >Total Amount</span
                            >
                            <span class="font-bold text-xl text-emerald-600"
                                >₦{total.toLocaleString()}</span
                            >
                        </div>
                        <p class="text-sm text-gray-500">
                            Secure payment via Paystack
                        </p>
                    </div>

                    <div class="mt-6 flex gap-4">
                        <button
                            onclick={() => (step = 2)}
                            class="text-gray-500 font-medium px-4">Back</button
                        >
                        <button
                            onclick={handlePayment}
                            disabled={loading}
                            class="flex-1 bg-emerald-600 text-white font-bold py-3 rounded-lg hover:bg-emerald-700 transition disabled:opacity-50 flex items-center justify-center"
                        >
                            {#if loading}
                                <span
                                    class="animate-spin h-5 w-5 border-2 border-white border-t-transparent rounded-full mr-2"
                                ></span>
                                Processing...
                            {:else}
                                Pay Now
                            {/if}
                        </button>
                    </div>
                </div>
            {/if}
        </div>

        <!-- Order Summary Sidebar -->
        <div class="md:col-span-1">
            <div
                class="bg-gray-50 dark:bg-gray-900 p-6 rounded-xl border dark:border-gray-800 sticky top-24"
            >
                <h3 class="font-bold mb-4 text-gray-900 dark:text-white">
                    Order Summary
                </h3>
                <div
                    class="space-y-3 text-sm mb-6 max-h-60 overflow-y-auto pr-2"
                >
                    {#each $cart.items as item}
                        <div class="flex justify-between gap-2">
                            <span class="text-gray-600 dark:text-gray-400"
                                >x{item.quantity} {item.name}</span
                            >
                            <span class="font-medium"
                                >₦{(
                                    item.price * item.quantity
                                ).toLocaleString()}</span
                            >
                        </div>
                    {/each}
                </div>

                <div
                    class="border-t dark:border-gray-700 pt-4 space-y-2 text-sm"
                >
                    <div
                        class="flex justify-between text-gray-600 dark:text-gray-400"
                    >
                        <span>Subtotal</span>
                        <span>₦{subtotal.toLocaleString()}</span>
                    </div>
                    <div
                        class="flex justify-between text-gray-600 dark:text-gray-400"
                    >
                        <span>Delivery Fee</span>
                        <span>₦{deliveryFee.toLocaleString()}</span>
                    </div>
                    <div
                        class="flex justify-between text-gray-600 dark:text-gray-400"
                    >
                        <span>Service Fees</span>
                        <span
                            >₦{(
                                platformFee + transactionFee
                            ).toLocaleString()}</span
                        >
                    </div>
                    <div
                        class="flex justify-between font-bold text-lg text-gray-900 dark:text-white pt-2 border-t dark:border-gray-700 mt-2"
                    >
                        <span>Total</span>
                        <span>₦{total.toLocaleString()}</span>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
