/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{html,js,svelte,ts}'],
  darkMode: ['selector', '[data-theme="dark"]'], // Enable dark mode with data-theme attribute
  theme: {
    extend: {},
  },
  plugins: [],
}
