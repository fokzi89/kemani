import { SupabaseClient, Session } from '@supabase/supabase-js';
declare global {
  namespace App {
    interface Locals {
      supabase: SupabaseClient;
      session: Session | null;
      referringTenantId: string | null;
      referringHcpId: string | null;
      subdomain: string | null;
      hostname: string;
    }
  }
}
export {};
