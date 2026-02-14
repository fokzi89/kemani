export interface Product {
  id: string;
  tenant_id: string;
  name: string;
  description?: string;
  price: number;
  category?: string;
  image_url?: string;
  stock_quantity?: number;
  published: boolean;
  created_at: string;
  updated_at: string;
}

export interface StoreDetails {
  id: string;
  name: string;
  slug?: string;
  settings?: {
    storeName?: string;
    storeDescription?: string;
    brandColor?: string;
    logo?: string;
  };
  created_at: string;
}

export interface MarketplaceSettings {
  enabled: boolean;
  storeName: string;
  storeDescription: string;
  brandColor: string;
}
