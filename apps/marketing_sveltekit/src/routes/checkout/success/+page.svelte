<script lang="ts">
    import CheckCircle from "lucide-svelte/icons/check-circle";
    import ShoppingBag from "lucide-svelte/icons/shopping-bag";

    // In a real app, retrieve order details from ID in URL or state
    const orderId = `ORD-${Math.floor(Math.random() * 1000000)}`;
    const date = new Date().toLocaleDateString();
</script>

<div class="container mx-auto px-4 py-16 text-center max-w-lg">
    <div
        class="inline-flex items-center justify-center w-20 h-20 bg-emerald-100 dark:bg-emerald-900/30 rounded-full mb-6"
    >
        <CheckCircle class="h-10 w-10 text-emerald-600 dark:text-emerald-400" />
    </div>

    <h1 class="text-3xl font-bold text-gray-900 dark:text-white mb-4">
        Order Confirmed!
    </h1>
    <p class="text-gray-600 dark:text-gray-400 mb-8">
        Thank you for your purchase. We have received your order and are
        processing it.
    </p>

    <div
        class="bg-gray-50 dark:bg-gray-900 p-6 rounded-xl border dark:border-gray-800 text-left mb-8"
    >
        <div
            class="flex justify-between mb-4 border-b dark:border-gray-800 pb-4"
        >
            <span class="text-gray-500">Order Number</span>
            <span class="font-medium text-gray-900 dark:text-white"
                >{orderId}</span
            >
        </div>
        <div
            class="flex justify-between mb-4 border-b dark:border-gray-800 pb-4"
        >
            <span class="text-gray-500">Date</span>
            <span class="font-medium text-gray-900 dark:text-white">{date}</span
            >
        </div>
        <div class="flex justify-between">
            <span class="text-gray-500">Payment Status</span>
            <span class="font-medium text-emerald-600">Paid</span>
        </div>
    </div>

    <div class="flex flex-col sm:flex-row gap-4 justify-center">
        <a
            href="/shop"
            class="inline-flex items-center justify-center px-6 py-3 bg-emerald-600 text-white font-bold rounded-lg hover:bg-emerald-700 transition"
        >
            <ShoppingBag class="h-4 w-4 mr-2" />
            Continue Shopping
        </a>
        <a
            href="/account"
            class="inline-flex items-center justify-center px-6 py-3 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-200 font-medium rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition"
        >
            View Order
        </a>
    </div>
</div>
