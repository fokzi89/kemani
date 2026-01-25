'use client';

import React, { useState } from 'react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Search, ScanBarcode, Package } from 'lucide-react';
import { Product } from '@/lib/types/pos';
import { formatCurrency } from '@/lib/utils/formatting';
import { useProducts } from '@/hooks/use-pos';

interface ProductSelectorProps {
    onProductSelect: (product: Product) => void;
    branchId: string;
}

export function ProductSelector({ onProductSelect, branchId }: ProductSelectorProps) {
    const [query, setQuery] = useState('');
    // Use Offline-First Hook
    const { products, isLoading: loading } = useProducts(branchId, query);

    return (
        <div className="space-y-4">
            <div className="flex gap-2">
                <div className="relative flex-1">
                    <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                    <Input
                        placeholder="Search products by name or SKU..."
                        className="pl-8"
                        value={query}
                        onChange={(e) => setQuery(e.target.value)}
                    />
                </div>
                <Button variant="outline" size="icon">
                    <ScanBarcode className="h-4 w-4" />
                </Button>
            </div>

            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 h-[500px] overflow-y-auto content-start">
                {loading ? (
                    <div className="col-span-full text-center py-8">Loading products...</div>
                ) : !products || products.length === 0 ? (
                    <div className="col-span-full text-center py-8 text-muted-foreground">
                        No products found
                    </div>
                ) : (
                    products.map((product) => (
                        <button
                            key={product.id}
                            className="flex flex-col items-start p-4 rounded-lg border bg-card hover:bg-accent/50 transition-colors text-left"
                            onClick={() => onProductSelect(product)}
                        >
                            <div className="w-full aspect-square bg-muted rounded-md mb-2 flex items-center justify-center">
                                {product.image_url ? (
                                    <img src={product.image_url} alt={product.name} className="object-cover w-full h-full rounded-md" />
                                ) : (
                                    <Package className="h-8 w-8 text-muted-foreground" />
                                )}
                            </div>
                            <div className="font-medium line-clamp-1">{product.name}</div>
                            <div className="text-sm text-muted-foreground">{formatCurrency(product.unit_price)}</div>
                            <div className="text-xs text-muted-foreground mt-1">Stock: {product.stock_quantity}</div>
                        </button>
                    ))
                )}
            </div>
        </div>
    );
}
