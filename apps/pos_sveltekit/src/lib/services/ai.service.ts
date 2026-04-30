import { createGoogleGenerativeAI } from '@ai-sdk/google';
import { streamText, tool } from 'ai';
import { z } from 'zod';
import { supabase } from '$lib/supabase';

/**
 * AI Service for POS Admin
 * Handles business analytics, inventory tracking, and staff oversight.
 */
export class POSAIService {
    private google: any;

    constructor(apiKey: string) {
        this.google = createGoogleGenerativeAI({
            apiKey: apiKey,
        });
    }

    async chat(messages: any[], tenantId: string, branchId: string, staffId: string) {
        return streamText({
            model: this.google('gemini-1.5-flash'),
            system: `You are Kemani POS Assistant, a data-driven business consultant for the merchant.
            Your goal is to provide real-time sales analytics, inventory alerts, and growth recommendations.
            
            GUIDELINES:
            1. Be data-focused, analytical, and professional.
            2. Use 'get_sales_summary' to provide today's performance.
            3. Use 'get_low_stock_alerts' to warn about inventory issues.
            4. If the merchant asks how to grow, analyze their top categories and suggest focus areas.
            5. Current Tenant ID: ${tenantId}
            6. Current Branch ID: ${branchId}
            
            IMPORTANT: Always use tools for numbers. Do not guess sales figures.`,
            messages,
            tools: {
                get_sales_summary: tool({
                    description: 'Get today\'s sales performance for the current branch',
                    parameters: z.object({
                        date: z.string().optional().describe('Date in YYYY-MM-DD format. Defaults to today.')
                    }),
                    execute: async ({ date }) => {
                        const targetDate = date || new Date().toISOString().split('T')[0];
                        const { data, error } = await supabase.rpc('get_daily_sales_summary', {
                            p_tenant_id: tenantId,
                            p_branch_id: branchId,
                            p_date: targetDate
                        });
                        
                        if (error) return { error: error.message };
                        return data;
                    }
                }),
                get_low_stock_alerts: tool({
                    description: 'Check for products that are low or out of stock',
                    parameters: z.object({}),
                    execute: async () => {
                        const { data, error } = await supabase
                            .from('product_stock_status')
                            .select('product_name, stock_quantity, low_stock_threshold, stock_status')
                            .eq('tenant_id', tenantId)
                            .eq('branch_id', branchId)
                            .in('stock_status', ['low_stock', 'out_of_stock'])
                            .limit(10);
                        
                        if (error) return { error: error.message };
                        return data;
                    }
                }),
                get_top_products: tool({
                    description: 'Identify best-selling products for the branch',
                    parameters: z.object({
                        limit: z.number().optional().default(5)
                    }),
                    execute: async ({ limit }) => {
                        // Using a simple query on sale_items for now
                        const { data, error } = await supabase
                            .from('sale_items')
                            .select('product_name, quantity, subtotal')
                            .eq('tenant_id', tenantId)
                            .order('quantity', { ascending: false })
                            .limit(limit);
                        
                        if (error) return { error: error.message };
                        return data;
                    }
                })
            }
        });
    }
}
