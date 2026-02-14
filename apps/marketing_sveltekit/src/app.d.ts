// See https://kit.svelte.dev/docs/types#app
// for information about these interfaces
declare global {
    namespace App {
        // interface Error {}
        interface Locals {
            tenant: string | null;
            user: import('$lib/stores/user').UserProfile | null;
        }
        // interface PageData {}
        // interface PageState {}
        // interface Platform {}
    }
}

export { };
