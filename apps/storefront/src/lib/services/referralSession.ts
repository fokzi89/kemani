// Referral Session Service
// Feature: 004-tenant-referral-commissions
// Handles session-based referral attribution

import { supabase } from '$lib/supabase';
import type { ReferralSession } from '$lib/types/commission';

/**
 * Generate a unique session token
 * Format: randomUUID to ensure uniqueness
 */
function generateSessionToken(): string {
  return crypto.randomUUID();
}

/**
 * ReferralSessionService
 * Manages referral session tracking for commission attribution
 */
export class ReferralSessionService {
  /**
   * Create a new referral session
   * @param referringTenantId - UUID of the tenant being browsed
   * @param customerId - UUID of the customer (optional, null for anonymous)
   * @returns Session token and session data
   */
  static async createSession(
    referringTenantId: string,
    customerId: string | null = null
  ): Promise<{ token: string; session: ReferralSession } | null> {
    try {
      const sessionToken = generateSessionToken();
      const expiresAt = new Date();
      expiresAt.setHours(expiresAt.getHours() + 24); // 24-hour expiry

      const { data, error } = await supabase
        .from('referral_sessions')
        .insert({
          session_token: sessionToken,
          customer_id: customerId,
          referring_tenant_id: referringTenantId,
          active: true,
          expires_at: expiresAt.toISOString(),
          last_activity_at: new Date().toISOString()
        })
        .select()
        .single();

      if (error) {
        console.error('Error creating referral session:', error);
        return null;
      }

      return {
        token: sessionToken,
        session: data as ReferralSession
      };
    } catch (err) {
      console.error('Exception creating referral session:', err);
      return null;
    }
  }

  /**
   * Get session by token
   * @param sessionToken - The session token from cookie
   * @returns Session data if active and not expired, null otherwise
   */
  static async getSessionByToken(
    sessionToken: string
  ): Promise<ReferralSession | null> {
    try {
      const { data, error } = await supabase
        .from('referral_sessions')
        .select('*')
        .eq('session_token', sessionToken)
        .eq('active', true)
        .gt('expires_at', new Date().toISOString())
        .single();

      if (error || !data) {
        return null;
      }

      return data as ReferralSession;
    } catch (err) {
      console.error('Exception getting referral session:', err);
      return null;
    }
  }

  /**
   * Refresh session activity timestamp
   * Extends session lifetime by updating last_activity_at
   * @param sessionToken - The session token to refresh
   * @returns Updated session or null
   */
  static async refreshSession(
    sessionToken: string
  ): Promise<ReferralSession | null> {
    try {
      const { data, error } = await supabase
        .from('referral_sessions')
        .update({
          last_activity_at: new Date().toISOString()
        })
        .eq('session_token', sessionToken)
        .eq('active', true)
        .gt('expires_at', new Date().toISOString())
        .select()
        .single();

      if (error || !data) {
        return null;
      }

      return data as ReferralSession;
    } catch (err) {
      console.error('Exception refreshing referral session:', err);
      return null;
    }
  }

  /**
   * Get active session for customer
   * @param customerId - UUID of the customer
   * @returns Active session or null
   */
  static async getActiveSessionForCustomer(
    customerId: string
  ): Promise<ReferralSession | null> {
    try {
      const { data, error } = await supabase
        .from('referral_sessions')
        .select('*')
        .eq('customer_id', customerId)
        .eq('active', true)
        .gt('expires_at', new Date().toISOString())
        .order('last_activity_at', { ascending: false })
        .limit(1)
        .single();

      if (error || !data) {
        return null;
      }

      return data as ReferralSession;
    } catch (err) {
      console.error('Exception getting active session for customer:', err);
      return null;
    }
  }

  /**
   * Deactivate a session
   * @param sessionToken - The session token to deactivate
   * @returns Success boolean
   */
  static async deactivateSession(sessionToken: string): Promise<boolean> {
    try {
      const { error } = await supabase
        .from('referral_sessions')
        .update({ active: false })
        .eq('session_token', sessionToken);

      return !error;
    } catch (err) {
      console.error('Exception deactivating session:', err);
      return false;
    }
  }

  /**
   * Cleanup expired sessions (utility function)
   * Deactivates sessions past their expiry time
   * Should be run periodically via cron
   */
  static async cleanupExpiredSessions(): Promise<number> {
    try {
      const { data, error } = await supabase
        .from('referral_sessions')
        .update({ active: false })
        .eq('active', true)
        .lt('expires_at', new Date().toISOString())
        .select('id');

      if (error) {
        console.error('Error cleaning up expired sessions:', error);
        return 0;
      }

      return data?.length || 0;
    } catch (err) {
      console.error('Exception cleaning up expired sessions:', err);
      return 0;
    }
  }
}
