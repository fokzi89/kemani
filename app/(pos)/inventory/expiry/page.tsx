'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { AlertTriangle, Calendar } from 'lucide-react';
import { formatDate } from '@/lib/utils/formatting';
import { Product } from '@/lib/types/pos';
import { Button } from '@/components/ui/button';

export default function ExpiryAlertsPage() {
    const [expiringProducts, setExpiringProducts] = useState<Product[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        // Mock fetch for now, replace with actual API call
        // /api/inventory/expiry or filter on client for MVP
        const mockData: any[] = []; // Empty for now as no data
        setExpiringProducts(mockData);
        setLoading(false);
    }, []);

    return (
        <div className="p-6 space-y-6">
            <h1 className="text-2xl font-bold flex items-center gap-2">
                <AlertTriangle className="text-orange-500" />
                Expiry Alerts
            </h1>

            <div className="grid md:grid-cols-2 gap-6">
                <Card className="border-orange-200 bg-orange-50 dark:bg-orange-950/20">
                    <CardHeader>
                        <CardTitle className="text-orange-700 dark:text-orange-400">Expiring Soon (30 Days)</CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="text-4xl font-bold text-orange-700 dark:text-orange-400">
                            {expiringProducts.length}
                        </div>
                        <p className="text-sm text-muted-foreground">Products need attention</p>
                    </CardContent>
                </Card>

                <Card className="border-red-200 bg-red-50 dark:bg-red-950/20">
                    <CardHeader>
                        <CardTitle className="text-red-700 dark:text-red-400">Expired Stock</CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="text-4xl font-bold text-red-700 dark:text-red-400">
                            0
                        </div>
                        <p className="text-sm text-muted-foreground">Products to remove</p>
                    </CardContent>
                </Card>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle>Detailed List</CardTitle>
                </CardHeader>
                <CardContent>
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead>Product Name</TableHead>
                                <TableHead>Batch/SKU</TableHead>
                                <TableHead>Expiry Date</TableHead>
                                <TableHead>Days Left</TableHead>
                                <TableHead>Action</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {loading ? (
                                <TableRow><TableCell colSpan={5} className="text-center">Loading...</TableCell></TableRow>
                            ) : expiringProducts.length === 0 ? (
                                <TableRow><TableCell colSpan={5} className="text-center text-muted-foreground">No expiring products found.</TableCell></TableRow>
                            ) : (
                                expiringProducts.map(p => (
                                    <TableRow key={p.id}>
                                        <TableCell>{p.name}</TableCell>
                                        <TableCell>{p.sku}</TableCell>
                                        <TableCell>{formatDate(new Date())}</TableCell>
                                        <TableCell>15 days</TableCell>
                                        <TableCell><Button variant="outline" size="sm">Dispose</Button></TableCell>
                                    </TableRow>
                                ))
                            )}
                        </TableBody>
                    </Table>
                </CardContent>
            </Card>
        </div>
    );
}
