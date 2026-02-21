import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals: { supabase } }) => {
    const { data: products, error } = await supabase
        .from('storefront_products')
        .select(`
			*,
			global_product_catalog (
				id,
				name,
				primary_image,
				description,
				slug,
				category
			)
		`)
        .eq('is_available', true)
        .order('created_at', { ascending: false })
        .limit(20);

    if (error) {
        console.error('Error loading products:', error);
        return { products: [] };
    }

    return {
        products: products ?? []
    };
};
