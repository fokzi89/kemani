import { createGoogleGenerativeAI } from '@ai-sdk/google';
import { streamText, tool } from 'ai';
import { z } from 'zod';
import { supabase } from '$lib/supabase';

/**
 * AI Service for Storefront
 * Handles product discovery, order tracking, and shopping assistance.
 */
export class StorefrontAIService {
    private google: any;

    constructor(apiKey: string) {
        this.google = createGoogleGenerativeAI({
            apiKey: apiKey,
        });
    }

    async chat(messages: any[], tenantId: string, customerId?: string) {
        return streamText({
            model: this.google('gemini-1.5-flash'),
            system: `You are Kemani AI, the shopping assistant for this store.
            Your goal is to help customers find products, explain product details, check their orders, and suggest items they might like.
            
            GUIDELINES:
            1. Be helpful, professional, and slightly enthusiastic.
            2. If searching for products, always use the 'search_products' tool.
            3. If a customer asks about their previous purchases, use 'get_my_orders'.
            4. If they want to buy something, guide them to add it to their bag or use the checkout.
            5. Current Tenant ID: ${tenantId}
            6. Current Customer ID: ${customerId || 'Anonymous'}
            
            IMPORTANT: Do not make up product prices or availability. Always use the data from tools.`,
            messages,
            tools: {
                search_products: tool({
                    description: 'Search for products available in the store',
                    parameters: z.object({
                        query: z.string().describe('The search term (name, category, brand)'),
                        limit: z.number().optional().default(5)
                    }),
                    execute: async ({ query, limit }) => {
                        const { data, error } = await supabase
                            .from('ecommerce_products')
                            .select('id, name, description, selling_price, image_url, category, branch_name')
                            .eq('tenant_id', tenantId)
                            .ilike('name', `%${query}%`)
                            .gt('total_stock', 0)
                            .limit(limit);
                        
                        if (error) return { error: error.message };
                        return data;
                    }
                }),
                get_my_orders: tool({
                    description: 'Retrieve the recent order history of the logged-in customer',
                    parameters: z.object({
                        limit: z.number().optional().default(3)
                    }),
                    execute: async ({ limit }) => {
                        if (!customerId) return { error: "Customer not logged in" };
                        
                        const { data, error } = await supabase
                            .from('orders')
                            .select('id, order_number, total_amount, status, created_at, order_items(product_id, quantity, unit_price)')
                            .eq('customer_id', customerId)
                            .order('created_at', { ascending: false })
                            .limit(limit);
                        
                        if (error) return { error: error.message };
                        return data;
                    }
                }),
                get_recommendations: tool({
                    description: 'Suggest products based on a category or general interest',
                    parameters: z.object({
                        category: z.string().optional().describe('Filter by category name if known'),
                        interest: z.string().optional().describe('A topic or interest to match')
                    }),
                    execute: async ({ category, interest }) => {
                        let queryBuilder = supabase
                            .from('ecommerce_products')
                            .select('id, name, selling_price, image_url')
                            .eq('tenant_id', tenantId)
                            .gt('total_stock', 0)
                            .limit(4);
                        
                        if (category) {
                            queryBuilder = queryBuilder.eq('category', category);
                        } else if (interest) {
                            queryBuilder = queryBuilder.ilike('description', `%${interest}%`);
                        }
                        
                        const { data, error } = await queryBuilder;
                        if (error) return { error: error.message };
                        return data;
                    }
                })
            }
        });
    }
}
