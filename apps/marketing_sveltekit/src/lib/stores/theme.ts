import { writable } from 'svelte/store';
import { browser } from '$app/environment';

// Get initial theme from localStorage or default to light
function getInitialTheme(): 'light' | 'dark' {
	if (!browser) return 'light';

	const stored = localStorage.getItem('theme');
	if (stored === 'light' || stored === 'dark') {
		return stored;
	}

	return 'light'; // default to light mode
}

export const theme = writable<'light' | 'dark'>(getInitialTheme());

// Update localStorage and document class when theme changes
// CSS variables in app.css will handle all color changes automatically
theme.subscribe((value) => {
	if (browser) {
		localStorage.setItem('theme', value);

		// Remove both classes first, then add the correct one
		document.documentElement.classList.remove('light', 'dark');
		document.documentElement.classList.add(value);

		console.log('✅ Theme changed to:', value);
		console.log('📱 HTML class:', document.documentElement.className);
		console.log('🎨 CSS variables will update automatically');
	}
});

export function toggleTheme() {
	theme.update((current) => {
		const newTheme = current === 'dark' ? 'light' : 'dark';
		console.log('🔄 Toggling theme from', current, 'to', newTheme);
		return newTheme;
	});
}
