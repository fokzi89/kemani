import { writable } from 'svelte/store';
import { browser } from '$app/environment';

export type Theme = 'light' | 'dark';

const getInitialTheme = (): Theme => {
	if (browser) {
		const stored = localStorage.getItem('theme') as Theme;
		if (stored === 'light' || stored === 'dark') {
			return stored;
		}
		// Check system preference
		if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
			return 'dark';
		}
	}
	return 'light';
};

function createThemeStore() {
	const { subscribe, set } = writable<Theme>(getInitialTheme());

	return {
		subscribe,
		toggle: () => {
			if (browser) {
				const current = document.documentElement.classList.contains('dark') ? 'dark' : 'light';
				const newTheme: Theme = current === 'light' ? 'dark' : 'light';

				document.documentElement.classList.remove('light', 'dark');
				document.documentElement.classList.add(newTheme);
				localStorage.setItem('theme', newTheme);

				set(newTheme);
			}
		},
		setTheme: (theme: Theme) => {
			if (browser) {
				document.documentElement.classList.remove('light', 'dark');
				document.documentElement.classList.add(theme);
				localStorage.setItem('theme', theme);
				set(theme);
			}
		}
	};
}

export const themeStore = createThemeStore();
