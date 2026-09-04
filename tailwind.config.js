/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './index.html',
    './src/**/*.{vue,js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          100: '#FFF6F9',
          200: '#FDECF2',
          300: '#F7DDE6',
          400: '#EFC2D1',
          500: '#E3A3B8',
        },
        secondary: {
          100: '#F5F3F7',
          200: '#E9E4EE',
          300: '#D6CCDF',
          400: '#B8A8C7',
          500: '#9882AA',
        },
        accent: {
          100: '#F2F8F5',
          200: '#DDECE4',
          300: '#BEDACB',
          400: '#98C2AD',
          500: '#70A78B',
        },
      },
      fontFamily: {
        sans: ['"Noto Sans TC"', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
