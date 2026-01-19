/**
 * Database TypeScript types
 *
 * This file will be auto-generated from Supabase schema using:
 * npx supabase gen types typescript --linked > types/database.types.ts
 *
 * For now, this is a placeholder to prevent TypeScript errors.
 */

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {}
    Views: {}
    Functions: {}
    Enums: {}
    CompositeTypes: {}
  }
}
