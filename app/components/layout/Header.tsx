'use client';

import React from 'react';
import { Menu, Sun, Moon, Bell } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useTheme } from '@/components/theme-provider';

interface HeaderProps {
    onMenuClick: () => void;
}

export function Header({ onMenuClick }: HeaderProps) {
    const { theme, toggleTheme } = useTheme();

    return (
        <header className="sticky top-0 z-30 h-16 w-full bg-background/80 backdrop-blur-md border-b border-border">
            <div className="flex h-full items-center justify-between px-4 sm:px-6">
                <div className="flex items-center gap-4">
                    <Button
                        variant="ghost"
                        size="icon"
                        className="md:hidden"
                        onClick={onMenuClick}
                    >
                        <Menu className="h-5 w-5" />
                        <span className="sr-only">Toggle Menu</span>
                    </Button>

                    <h1 className="text-lg font-semibold md:hidden theme-heading">Kemani POS</h1>
                </div>

                <div className="flex items-center gap-2">
                    <Button variant="ghost" size="icon">
                        <Bell className="h-5 w-5 text-muted-foreground" />
                    </Button>

                    <Button
                        variant="ghost"
                        size="icon"
                        onClick={toggleTheme}
                        className="text-muted-foreground"
                    >
                        {theme === 'dark' ? (
                            <Sun className="h-5 w-5" />
                        ) : (
                            <Moon className="h-5 w-5" />
                        )}
                        <span className="sr-only">Toggle Theme</span>
                    </Button>

                    <div className="ml-2 h-8 w-8 rounded-full bg-primary/20 flex items-center justify-center border border-primary/30">
                        <span className="text-sm font-medium text-primary">JD</span>
                    </div>
                </div>
            </div>
        </header>
    );
}
