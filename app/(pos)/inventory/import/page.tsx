'use client';

import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Upload, FileDown, CheckCircle, AlertTriangle } from 'lucide-react';
import { toast } from 'sonner';

export default function ImportInventoryPage() {
    const [file, setFile] = useState<File | null>(null);
    const [uploading, setUploading] = useState(false);
    const [result, setResult] = useState<{ count?: number; error?: string } | null>(null);

    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        if (e.target.files && e.target.files[0]) {
            setFile(e.target.files[0]);
            setResult(null);
        }
    };

    const handleUpload = async () => {
        if (!file) return;

        setUploading(true);
        const formData = new FormData();
        formData.append('file', file);
        formData.append('branchId', 'branch-123'); // TODO: Get from context

        try {
            const res = await fetch('/api/products/import', {
                method: 'POST',
                body: formData,
            });

            const data = await res.json();
            if (res.ok) {
                setResult({ count: data.count });
                toast.success(`Successfully imported ${data.count} products`);
            } else {
                setResult({ error: data.error });
                toast.error('Import failed');
            }
        } catch (error) {
            setResult({ error: 'Network error occurred' });
        } finally {
            setUploading(false);
        }
    };

    return (
        <div className="p-6 max-w-2xl mx-auto space-y-6">
            <h1 className="text-2xl font-bold">Import Inventory</h1>

            <Card>
                <CardHeader>
                    <CardTitle>Bulk Upload Products</CardTitle>
                    <CardDescription>Upload a CSV file to add or update products in bulk.</CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                    <div className="border-2 border-dashed border-muted-foreground/25 rounded-lg p-10 flex flex-col items-center justify-center text-center transition-colors hover:bg-muted/50">
                        <Upload className="h-10 w-10 text-muted-foreground mb-4" />
                        <Label htmlFor="file-upload" className="cursor-pointer">
                            <span className="text-primary font-medium hover:underline">Click to upload</span> or drag and drop
                            <Input
                                id="file-upload"
                                type="file"
                                accept=".csv"
                                className="hidden"
                                onChange={handleFileChange}
                            />
                        </Label>
                        <p className="text-sm text-muted-foreground mt-2">CSV files only (max 5MB)</p>
                    </div>

                    {file && (
                        <div className="flex items-center justify-between p-3 bg-muted/30 rounded-md">
                            <span className="text-sm font-medium">{file.name}</span>
                            <Button size="sm" onClick={handleUpload} disabled={uploading}>
                                {uploading ? 'Uploading...' : 'Import Now'}
                            </Button>
                        </div>
                    )}

                    {result?.count !== undefined && (
                        <div className="bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-300 p-4 rounded-md flex items-center gap-2">
                            <CheckCircle className="h-5 w-5" />
                            <span>Successfully imported {result.count} products.</span>
                        </div>
                    )}

                    {result?.error && (
                        <div className="bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-300 p-4 rounded-md flex items-center gap-2">
                            <AlertTriangle className="h-5 w-5" />
                            <span>Error: {result.error}</span>
                        </div>
                    )}

                    <div className="bg-muted p-4 rounded-md">
                        <h4 className="font-medium mb-2 flex items-center gap-2">
                            <FileDown className="h-4 w-4" />
                            CSV Template Format
                        </h4>
                        <code className="text-xs block bg-background p-2 rounded border">
                            Name, Unit Price, Stock Quantity, SKU, Category<br />
                            "Coca Cola 50cl", 250, 100, "BEV-001", "Beverages"<br />
                            "Panadol Extra", 50, 500, "MED-002", "Medicine"
                        </code>
                    </div>
                </CardContent>
            </Card>
        </div>
    );
}
