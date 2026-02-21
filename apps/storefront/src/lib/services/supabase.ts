import { createBrowserClient, isBrowser, parse } from '@supabase/ssr';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '$lib/types/supabase.js';

export const createSupabase = (fetch: any, data: any): SupabaseClient<Database> => {
    return createBrowserClient<Database>(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY, {
        global: {
            fetch,
        },
        cookies: {
            get(key) {
                if (!isBrowser()) {
                    return JSON.stringify(data.session);
                }

                const cookie = document.cookie
                    .split('; ')
                    .find((row) => row.startsWith(`${key}=`));

                return cookie ? cookie.split('=')[1] : undefined;
            },
            set(key, value, options) {
                if (!isBrowser()) return;
                document.cookie = `${key}=${value}; max-age=${options.maxAge}; path=${options.path ?? '/'}; SameSite=${options.sameSite ?? 'Lax'}; ${options.secure ? 'Secure' : ''}`;
            },
            remove(key, options) {
                if (!isBrowser()) return;
                document.cookie = `${key}=; path=${options.path ?? '/'}; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
            },
        },
    });
};
