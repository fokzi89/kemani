'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cn } from '@/lib/utils';
import {
    LayoutDashboard,
    ShoppingCart,
    Users,
    Package,
    Settings,
    LogOut,
    Store,
    ChevronLeft,
    Menu
} from 'lucide-react';
import { Button } from '@/components/ui/button';

interface SidebarProps {
    className?: string;
    isOpen: boolean;
    onClose?: () => void;
}

const NAV_ITEMS = [
    {
        title: 'Dashboard',
        href: '/dashboard',
        icon: LayoutDashboard,
    },
    {
        title: 'POS',
        href: '/pos',
        icon: ShoppingCart,
    },
    {
        title: 'Orders',
        href: '/orders',
        icon: Package,
    },
    {
        title: 'Customers',
        href: '/customers',
        icon: Users,
    },
    {
        title: 'Inventory',
        href: '/inventory',
        icon: Store,
    },
    {
        title: 'Settings',
        href: '/settings',
        icon: Settings,
    },
];

export function Sidebar({ className, isOpen, onClose }: SidebarProps) {
    const pathname = usePathname();

    return (
        <>
            {/* Mobile Overlay */}
            <div
                className={cn(
                    "fixed inset-0 z-40 bg-black/50 backdrop-blur-sm transition-opacity md:hidden",
                    isOpen ? "opacity-100" : "opacity-0 pointer-events-none"
                )}
                onClick={onClose}
            />

            {/* Sidebar Container */}
            <aside
                className={cn(
                    "fixed top-0 left-0 z-40 h-screen w-64 bg-background border-r border-border transition-transform duration-300 md:translate-x-0",
                    isOpen ? "translate-x-0" : "-translate-x-full",
                    className
                )}
            >
                <div className="flex flex-col h-full">
                    {/* Logo Area */}
                    <div className="h-16 flex items-center px-6 border-b border-border">
                        <Link href="/dashboard" className="flex items-center gap-2 font-bold text-xl theme-logo">
                            <Store className="h-6 w-6" />
                            <span>Kemani POS</span>
                        </Link>
                    </div>

                    {/* Navigation */}
                    <div className="flex-1 py-4 overflow-y-auto">
                        <nav className="space-y-1 px-3">
                            {NAV_ITEMS.map((item) => (
                                <Link
                                    key={item.href}
                                    href={item.href}
                                    className={cn(
                                        "flex items-center gap-3 px-3 py-2.5 rounded-md text-sm font-medium transition-colors",
                                        pathname.startsWith(item.href)
                                            ? "bg-primary/10 text-primary"
                                            : "text-muted-foreground hover:bg-muted hover:text-foreground"
                                    )}
                                    onClick={() => onClose?.()}
                                >
                                    <item.icon className="h-5 w-5" />
                                    {item.title}
                                </Link>
                            ))}
                        </nav>
                    </div>

                    {/* Footer Area */}
                    <div className="p-4 border-t border-border">
                        <Button variant="ghost" className="w-full justify-start gap-3 text-red-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-950/20">
                            <LogOut className="h-5 w-5" />
                            Sign Out
                        </Button>
                    </div>
                </div>
            </aside>
        </>
    );
}
