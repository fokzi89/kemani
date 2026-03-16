import { SupabaseClient, Session } from '@supabase/supabase-js';

declare global {
	namespace App {
		interface Locals {
			supabase: SupabaseClient;
			session: Session | null;
			referringTenantId: string | null;
		}
		interface PageData {
			session: Session | null;
			referringTenantId?: string | null;
		}
		// interface Error {}
		// interface Platform {}
	}
}

export {};
