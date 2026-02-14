<script lang="ts">
    import { loginWithGoogle, loginWithApple } from "$lib/services/auth";
    // Use simple HTML buttons or icons if available
</script>

<div class="min-h-[80vh] flex items-center justify-center p-4">
    <div
        class="bg-white dark:bg-gray-800 rounded-2xl shadow-xl p-8 w-full max-w-md border dark:border-gray-700"
    >
        <div class="text-center mb-8">
            <h1
                class="text-3xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-emerald-600 to-green-500 mb-2"
            >
                Welcome Back
            </h1>
            <p class="text-gray-500 dark:text-gray-400">
                Sign in to manage your orders
            </p>
        </div>

        <div class="space-y-4">
            <button
                onclick={loginWithGoogle}
                class="w-full flex items-center justify-center gap-3 px-6 py-3 border-2 border-gray-200 dark:border-gray-700 rounded-xl hover:bg-gray-50 dark:hover:bg-gray-700 transition font-medium text-gray-700 dark:text-gray-200"
            >
                <svg class="w-5 h-5" viewBox="0 0 24 24"
                    ><path
                        d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                        fill="#4285F4"
                    /><path
                        d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                        fill="#34A853"
                    /><path
                        d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                        fill="#FBBC05"
                    /><path
                        d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                        fill="#EA4335"
                    /></svg
                >
                Sign in with Google
            </button>

            <button
                onclick={loginWithApple}
                class="w-full flex items-center justify-center gap-3 px-6 py-3 bg-black text-white rounded-xl hover:bg-gray-900 transition font-medium"
            >
                <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor"
                    ><path
                        d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.74 1.18 0 2.21-.89 3.66-.76.75.06 2.86.3 3.97 1.95-3.17 1.81-2.58 5.76.62 7.02-.65 1.66-1.54 3.3-2.33 4.02zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"
                    /></svg
                >
                Sign in with Apple
            </button>
        </div>

        <div class="mt-8 text-center text-sm text-gray-500">
            <p>By signing in, you agree to our Terms and Privacy Policy.</p>
        </div>
    </div>
</div>
