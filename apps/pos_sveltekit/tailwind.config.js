/** @type {import('tailwindcss').Config} */
export default {
	content: ['./src/**/*.{html,js,svelte,ts}'],
	theme: {
		extend: {
			colors: {
				primary: {
					50: '#c5eec0',
					100: '#b6eab1',
					200: '#a7e5a2',
					300: '#97e192',
					400: '#87dc83',
					500: '#75d773',
					600: '#5ec95c',
					700: '#4ab048',
					800: '#3a8a38',
					900: '#2d6a2b',
				}
			}
		}
	},
	plugins: []
};
