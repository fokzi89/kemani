export interface WooCommerceProduct {
    id: number;
    name: string;
    price: string;
    regular_price: string;
    sale_price: string;
    stock_quantity: number | null;
    manage_stock: boolean;
    images: { src: string }[];
    short_description: string;
}

export class WooCommerceService {
    private baseUrl: string;
    private consumerKey: string;
    private consumerSecret: string;

    constructor(baseUrl: string, consumerKey: string, consumerSecret: string) {
        this.baseUrl = baseUrl.replace(/\/$/, ''); // Remove trailing slash
        this.consumerKey = consumerKey;
        this.consumerSecret = consumerSecret;
    }

    private getAuthHeader(): string {
        // Basic Auth Base64
        return 'Basic ' + Buffer.from(`${this.consumerKey}:${this.consumerSecret}`).toString('base64');
    }

    async testConnection(): Promise<boolean> {
        try {
            const res = await fetch(`${this.baseUrl}/wp-json/wc/v3/system_status`, {
                headers: { 'Authorization': this.getAuthHeader() }
            });
            return res.ok;
        } catch (error) {
            console.error('WooCommerce Connection Error:', error);
            return false;
        }
    }

    async getProducts(page = 1, perPage = 20): Promise<WooCommerceProduct[]> {
        try {
            const res = await fetch(`${this.baseUrl}/wp-json/wc/v3/products?page=${page}&per_page=${perPage}`, {
                headers: { 'Authorization': this.getAuthHeader() }
            });

            if (!res.ok) throw new Error(`Failed to fetch products: ${res.statusText}`);

            return await res.json();
        } catch (error) {
            console.error('WooCommerce Fetch Error:', error);
            throw error;
        }
    }
}
