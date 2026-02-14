import type { Product, StoreDetails } from '$lib/types';

// Mock store data
export const mockStores: Record<string, StoreDetails> = {
  'demo-store': {
    id: 'demo-store-id-123',
    name: 'Demo Pharmacy',
    slug: 'demo-store',
    settings: {
      storeName: 'Welcome to Demo Pharmacy',
      storeDescription: 'Your trusted neighborhood pharmacy. Browse our catalog and order online for fast delivery.',
      brandColor: '#16a34a',
      logo: undefined
    },
    created_at: '2024-01-01T00:00:00Z'
  },
  'example-tenant': {
    id: 'example-tenant-id-456',
    name: 'Example Supermarket',
    slug: 'example-tenant',
    settings: {
      storeName: 'Welcome to Example Supermarket',
      storeDescription: 'Fresh groceries, household items, and more. Shop online and get delivery to your doorstep.',
      brandColor: '#059669',
      logo: undefined
    },
    created_at: '2024-01-01T00:00:00Z'
  },
  'test-shop': {
    id: 'test-shop-id-789',
    name: 'Test Electronics Shop',
    slug: 'test-shop',
    settings: {
      storeName: 'Test Electronics - Latest Gadgets',
      storeDescription: 'Cutting-edge electronics and accessories at affordable prices. Fast shipping available.',
      brandColor: '#0891b2',
      logo: undefined
    },
    created_at: '2024-01-01T00:00:00Z'
  }
};

// Mock products
export const mockProducts: Product[] = [
  // Pharmacy products
  {
    id: 'prod-1',
    tenant_id: 'demo-store-id-123',
    name: 'Paracetamol 500mg',
    description: 'Fast relief for pain and fever. Pack of 20 tablets.',
    price: 500,
    category: 'Medicine',
    image_url: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=300&h=300&fit=crop',
    stock_quantity: 150,
    published: true,
    created_at: '2024-01-15T00:00:00Z',
    updated_at: '2024-01-15T00:00:00Z'
  },
  {
    id: 'prod-2',
    tenant_id: 'demo-store-id-123',
    name: 'Vitamin C 1000mg',
    description: 'Immune system support. Effervescent tablets, orange flavor.',
    price: 1500,
    category: 'Supplements',
    image_url: 'https://images.unsplash.com/photo-1550572017-4870bbf3c392?w=300&h=300&fit=crop',
    stock_quantity: 80,
    published: true,
    created_at: '2024-01-16T00:00:00Z',
    updated_at: '2024-01-16T00:00:00Z'
  },
  {
    id: 'prod-3',
    tenant_id: 'demo-store-id-123',
    name: 'Hand Sanitizer 500ml',
    description: '70% alcohol-based sanitizer. Kills 99.9% of germs.',
    price: 800,
    category: 'Personal Care',
    image_url: 'https://images.unsplash.com/photo-1585435557343-3b092031a831?w=300&h=300&fit=crop',
    stock_quantity: 200,
    published: true,
    created_at: '2024-01-17T00:00:00Z',
    updated_at: '2024-01-17T00:00:00Z'
  },
  {
    id: 'prod-4',
    tenant_id: 'demo-store-id-123',
    name: 'Digital Thermometer',
    description: 'Fast and accurate temperature reading. LCD display.',
    price: 2500,
    category: 'Medical Devices',
    image_url: 'https://images.unsplash.com/photo-1584515933487-779824d29309?w=300&h=300&fit=crop',
    stock_quantity: 35,
    published: true,
    created_at: '2024-01-18T00:00:00Z',
    updated_at: '2024-01-18T00:00:00Z'
  },
  {
    id: 'prod-5',
    tenant_id: 'demo-store-id-123',
    name: 'Multivitamin Complex',
    description: 'Complete daily nutrition. 30 tablets per bottle.',
    price: 3500,
    category: 'Supplements',
    image_url: 'https://images.unsplash.com/photo-1607619056574-7b8d3ee536b2?w=300&h=300&fit=crop',
    stock_quantity: 60,
    published: true,
    created_at: '2024-01-19T00:00:00Z',
    updated_at: '2024-01-19T00:00:00Z'
  },
  {
    id: 'prod-6',
    tenant_id: 'demo-store-id-123',
    name: 'Blood Pressure Monitor',
    description: 'Automatic digital BP monitor with memory function.',
    price: 12000,
    category: 'Medical Devices',
    image_url: 'https://images.unsplash.com/photo-1615486511484-92e172cc4fe0?w=300&h=300&fit=crop',
    stock_quantity: 15,
    published: true,
    created_at: '2024-01-20T00:00:00Z',
    updated_at: '2024-01-20T00:00:00Z'
  },
  {
    id: 'prod-7',
    tenant_id: 'demo-store-id-123',
    name: 'First Aid Kit',
    description: 'Complete first aid kit for home and travel. 50 pieces.',
    price: 4500,
    category: 'Medical Supplies',
    image_url: 'https://images.unsplash.com/photo-1603398938378-e54eab446dde?w=300&h=300&fit=crop',
    stock_quantity: 45,
    published: true,
    created_at: '2024-01-21T00:00:00Z',
    updated_at: '2024-01-21T00:00:00Z'
  },
  {
    id: 'prod-8',
    tenant_id: 'demo-store-id-123',
    name: 'Face Masks (Box of 50)',
    description: '3-ply disposable face masks. Medical grade.',
    price: 2000,
    category: 'Personal Care',
    image_url: 'https://images.unsplash.com/photo-1584634731339-252c581abfc5?w=300&h=300&fit=crop',
    stock_quantity: 120,
    published: true,
    created_at: '2024-01-22T00:00:00Z',
    updated_at: '2024-01-22T00:00:00Z'
  },

  // Supermarket products
  {
    id: 'prod-9',
    tenant_id: 'example-tenant-id-456',
    name: 'Rice 5kg Bag',
    description: 'Premium long grain rice. Perfect for jollof!',
    price: 4500,
    category: 'Food',
    image_url: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=300&h=300&fit=crop',
    stock_quantity: 200,
    published: true,
    created_at: '2024-01-15T00:00:00Z',
    updated_at: '2024-01-15T00:00:00Z'
  },
  {
    id: 'prod-10',
    tenant_id: 'example-tenant-id-456',
    name: 'Vegetable Oil 3L',
    description: 'Pure vegetable cooking oil. Cholesterol free.',
    price: 3200,
    category: 'Food',
    image_url: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=300&h=300&fit=crop',
    stock_quantity: 85,
    published: true,
    created_at: '2024-01-16T00:00:00Z',
    updated_at: '2024-01-16T00:00:00Z'
  },
  {
    id: 'prod-11',
    tenant_id: 'example-tenant-id-456',
    name: 'Tomato Paste 70g x 12',
    description: 'Concentrated tomato paste. Carton of 12 tins.',
    price: 1800,
    category: 'Food',
    image_url: 'https://images.unsplash.com/photo-1592838064575-70ed626d3a0e?w=300&h=300&fit=crop',
    stock_quantity: 150,
    published: true,
    created_at: '2024-01-17T00:00:00Z',
    updated_at: '2024-01-17T00:00:00Z'
  },
  {
    id: 'prod-12',
    tenant_id: 'example-tenant-id-456',
    name: 'Indomie Noodles Carton',
    description: 'Instant noodles. Carton of 40 packs. Various flavors.',
    price: 5500,
    category: 'Food',
    image_url: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=300&h=300&fit=crop',
    stock_quantity: 95,
    published: true,
    created_at: '2024-01-18T00:00:00Z',
    updated_at: '2024-01-18T00:00:00Z'
  },
  {
    id: 'prod-13',
    tenant_id: 'example-tenant-id-456',
    name: 'Fresh Eggs (Crate)',
    description: 'Farm fresh eggs. 30 eggs per crate.',
    price: 2800,
    category: 'Fresh Produce',
    image_url: 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=300&h=300&fit=crop',
    stock_quantity: 40,
    published: true,
    created_at: '2024-01-19T00:00:00Z',
    updated_at: '2024-01-19T00:00:00Z'
  },
  {
    id: 'prod-14',
    tenant_id: 'example-tenant-id-456',
    name: 'Bottled Water 75cl x 12',
    description: 'Pure bottled water. Carton of 12 bottles.',
    price: 1200,
    category: 'Drinks',
    image_url: 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=300&h=300&fit=crop',
    stock_quantity: 180,
    published: true,
    created_at: '2024-01-20T00:00:00Z',
    updated_at: '2024-01-20T00:00:00Z'
  },

  // Electronics products
  {
    id: 'prod-15',
    tenant_id: 'test-shop-id-789',
    name: 'Wireless Earbuds',
    description: 'Bluetooth 5.0 earbuds with charging case. 20hr battery.',
    price: 8500,
    category: 'Audio',
    image_url: 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=300&h=300&fit=crop',
    stock_quantity: 45,
    published: true,
    created_at: '2024-01-15T00:00:00Z',
    updated_at: '2024-01-15T00:00:00Z'
  },
  {
    id: 'prod-16',
    tenant_id: 'test-shop-id-789',
    name: 'Phone Case',
    description: 'Shockproof protective case. Multiple colors available.',
    price: 1500,
    category: 'Accessories',
    image_url: 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=300&h=300&fit=crop',
    stock_quantity: 120,
    published: true,
    created_at: '2024-01-16T00:00:00Z',
    updated_at: '2024-01-16T00:00:00Z'
  },
  {
    id: 'prod-17',
    tenant_id: 'test-shop-id-789',
    name: 'Power Bank 20000mAh',
    description: 'Fast charging power bank. USB-C and USB-A ports.',
    price: 12000,
    category: 'Accessories',
    image_url: 'https://images.unsplash.com/photo-1609091839311-d5365f9ff1c5?w=300&h=300&fit=crop',
    stock_quantity: 35,
    published: true,
    created_at: '2024-01-17T00:00:00Z',
    updated_at: '2024-01-17T00:00:00Z'
  },
  {
    id: 'prod-18',
    tenant_id: 'test-shop-id-789',
    name: 'USB Cable 2m',
    description: 'Durable braided USB-C cable. Fast charging supported.',
    price: 800,
    category: 'Accessories',
    image_url: 'https://images.unsplash.com/photo-1583863788434-e58a36330cf0?w=300&h=300&fit=crop',
    stock_quantity: 200,
    published: true,
    created_at: '2024-01-18T00:00:00Z',
    updated_at: '2024-01-18T00:00:00Z'
  }
];

// Get products for a specific tenant
export function getMockProducts(tenantId: string, category?: string | null): Product[] {
  let products = mockProducts.filter(p => p.tenant_id === tenantId);

  if (category) {
    products = products.filter(p => p.category === category);
  }

  return products;
}

// Get categories for a tenant
export function getMockCategories(tenantId: string): string[] {
  const products = mockProducts.filter(p => p.tenant_id === tenantId);
  const categories = [...new Set(products.map(p => p.category).filter(Boolean))];
  return categories as string[];
}

// Get store by ID or slug
export function getMockStore(idOrSlug: string): StoreDetails | null {
  // Try to find by slug first
  const storeBySlug = Object.values(mockStores).find(s => s.slug === idOrSlug);
  if (storeBySlug) return storeBySlug;

  // Try to find by ID
  const storeById = Object.values(mockStores).find(s => s.id === idOrSlug);
  if (storeById) return storeById;

  // Return first store as default
  return mockStores['demo-store'];
}
