
import { user, type UserProfile } from '$lib/stores/user';
import { get } from 'svelte/store';
import { goto } from '$app/navigation';

export async function loginWithGoogle() {
    // In a real app, this would redirect to OAuth provider
    // For demo, we simulate a successful login
    const mockUser: UserProfile = {
        id: 'user-123',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '+2348012345678',
        addresses: [],
        isGuest: false
    };

    user.setUser(mockUser);
    goto('/account');
}

export async function loginWithApple() {
    const mockUser: UserProfile = {
        id: 'user-456',
        name: 'Jane Apple',
        email: 'jane@example.com',
        phone: '+2348087654321',
        addresses: [],
        isGuest: false
    };

    user.setUser(mockUser);
    goto('/account');
}

export async function continueAsGuest(details: { name: string; phone: string; address: string }) {
    const guestUser: UserProfile = {
        id: `guest-${Date.now()}`,
        name: details.name,
        phone: details.phone,
        addresses: [{
            street: details.address,
            isDefault: true
        }],
        isGuest: true
    };

    user.setUser(guestUser);
    // Redirect back to checkout if relevant, or shop
    // For now, assuming this is called from checkout flow mostly
    return guestUser;
}

export function logout() {
    user.clearUser();
    goto('/');
}
