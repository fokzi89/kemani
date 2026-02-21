import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import type { Product, Variant } from '$lib/types/database';

export const load: PageServerLoad = async ({ params, locals: { supabase } }) => {
    const { slug } = params;

    // Use inner join with global_product_catalog filtering by slug
    const { data: product, error: fetchError } = await supabase
        .from('storefront_products')
        .select(`
			*,
			global_product_catalog!inner (
				id,
				name,
				description,
				primary_image,
				images,
				category,
				slug
			),
			product_variants (
				id,
				variant_name,
				options,
				price_adjustment,
				stock_quantity,
				image_url,
				is_available
			)
		`)
        .eq('global_product_catalog.slug', slug)
        .eq('is_available', true)
        .limit(1)
        .maybeSingle();

    if (fetchError) {
        console.error('Error fetching product:', fetchError);
        throw error(500, 'Error loading product details');
    }

    if (!product) {
        throw error(404, 'Product not found');
    }

    return {
        product: product as unknown as (Product & {
            global_product_catalog: {
                id: string;
                name: string;
                description: string;
                primary_image: string;
                images: string[];
                category: string;
                slug: string;
            };
            product_variants: Variant[];
        })
    };
};
