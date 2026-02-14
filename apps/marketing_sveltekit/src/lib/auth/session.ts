import { createClient } from '@/lib/supabase/server';
import { redirect } from 'next/navigation';
import { cache } from 'react';

export const getSession = cache(async () => {
    const supabase = await createClient();
    try {
        const {
            data: { session },
        } = await supabase.auth.getSession();
        return session;
    } catch (error) {
        console.error('Error:', error);
        return null;
    }
});

export const getUser = cache(async () => {
    const session = await getSession();
    return session?.user ?? null;
});

export const requireUser = async () => {
    const session = await getSession();
    if (!session) {
        redirect('/login');
    }
    return session.user;
};

export const requireRole = async (allowedRoles: string[]) => {
    const user = await requireUser();
    // In a real app, you'd fetch the user's role from the 'users' table or metadata
    // For now, we assume the role is in user_metadata or we fetch the profile
    const supabase = await createClient();
    const { data: profile } = await supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .single();

    if (!profile || !allowedRoles.includes(profile.role)) {
        redirect('/unauthorized');
    }
    return user;
};
