'use client';

import { useEffect, useState } from 'react';
import { User } from '@supabase/supabase-js';
import { useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';

interface AuthState {
    user: User | null;
    loading: boolean;
    error: string | null;
}

export function useAuth() {
    const [state, setState] = useState<AuthState>({
        user: null,
        loading: true,
        error: null,
    });

    const router = useRouter();
    const supabase = createClient();

    useEffect(() => {
        // Get initial session
        supabase.auth.getSession().then(({ data: { session } }) => {
            setState({
                user: session?.user ?? null,
                loading: false,
                error: null,
            });
        });

        // Listen for auth changes
        const {
            data: { subscription },
        } = supabase.auth.onAuthStateChange((_event, session) => {
            setState({
                user: session?.user ?? null,
                loading: false,
                error: null,
            });

            // Refresh the page to update server components
            router.refresh();
        });

        return () => subscription.unsubscribe();
    }, [supabase, router]);

    const signOut = async () => {
        setState(prev => ({ ...prev, loading: true }));

        const { error } = await supabase.auth.signOut();

        if (error) {
            setState(prev => ({ ...prev, error: error.message, loading: false }));
        } else {
            setState({ user: null, loading: false, error: null });
            router.push('/login');
        }
    };

    return {
        user: state.user,
        loading: state.loading,
        error: state.error,
        signOut,
        isAuthenticated: !!state.user,
    };
}
