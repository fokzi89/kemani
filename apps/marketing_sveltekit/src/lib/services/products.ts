import { PUBLIC_API_URL } from '$env/static/public';

// Fallback if env not set
const API_URL = PUBLIC_API_URL || 'http://localhost:3000/api';

export interface Product {
    id: string;
    name: string;
    description: string;
    price: number;
    image_url: string;
    category: string;
    branch_id?: string;
    stock_quantity: number;
    variants?: any[];
}

export async function getProducts(tenantId?: string, branchId?: string, search?: string, category?: string) {
    const params = new URLSearchParams();
    if (tenantId) params.append('tenant_id', tenantId);
    if (branchId) params.append('branch_id', branchId);
    if (search) params.append('search', search);
    if (category) params.append('category', category);

    try {
        const res = await fetch(`${API_URL}/products/storefront?${params.toString()}`);
        if (!res.ok) throw new Error('Failed to fetch products');
        return await res.json();
    } catch (error) {
        console.error(error);
        return [];
    }
}

export async function getProduct(id: string) {
    try {
        const res = await fetch(`${API_URL}/products/${id}`);
        if (!res.ok) throw new Error('Failed to fetch product');
        return await res.json();
    } catch (error) {
        console.error(error);
        return null;
    }
}
