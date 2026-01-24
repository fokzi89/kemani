'use client';

import * as React from 'react';
import { useTheme } from './theme-provider';

export function ThemeToggle() {
  const { theme, toggleTheme } = useTheme();
  const isDark = theme === 'dark';

  return (
    <button
      onClick={toggleTheme}
      className="relative inline-flex items-center justify-center w-14 h-8 rounded-full transition-all duration-300 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2"
      style={{
        background: isDark
          ? 'linear-gradient(135deg, #166534 0%, #14532d 100%)'
          : 'linear-gradient(135deg, #dcfce7 0%, #bbf7d0 100%)',
      }}
      aria-label="Toggle theme"
      title={isDark ? 'Switch to light mode' : 'Switch to dark mode'}
    >
      {/* Track border effect */}
      <span
        className={`absolute inset-0 rounded-full border-2 transition-all duration-300 ${
          isDark ? 'border-green-400 neon-border' : 'border-green-600'
        }`}
      />

      {/* Toggle circle */}
      <span
        className={`relative flex items-center justify-center w-6 h-6 rounded-full transition-all duration-300 transform ${
          isDark ? 'translate-x-3' : '-translate-x-3'
        }`}
        style={{
          background: isDark
            ? 'linear-gradient(135deg, #4ade80 0%, #22ff7a 100%)'
            : 'linear-gradient(135deg, #22c55e 0%, #16a34a 100%)',
          boxShadow: isDark
            ? '0 0 10px rgba(74, 222, 128, 0.8), 0 0 20px rgba(74, 222, 128, 0.5)'
            : '0 2px 4px rgba(22, 163, 74, 0.3)',
        }}
      >
        {/* Icon */}
        <span className="text-xs">
          {isDark ? (
            // Moon icon (dark mode)
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20"
              fill="currentColor"
              className="w-4 h-4"
              style={{ color: '#052e16' }}
            >
              <path
                fillRule="evenodd"
                d="M7.455 2.004a.75.75 0 01.26.77 7 7 0 009.958 7.967.75.75 0 011.067.853A8.5 8.5 0 116.647 1.921a.75.75 0 01.808.083z"
                clipRule="evenodd"
              />
            </svg>
          ) : (
            // Sun icon (light mode)
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20"
              fill="currentColor"
              className="w-4 h-4"
              style={{ color: '#ffffff' }}
            >
              <path d="M10 2a.75.75 0 01.75.75v1.5a.75.75 0 01-1.5 0v-1.5A.75.75 0 0110 2zM10 15a.75.75 0 01.75.75v1.5a.75.75 0 01-1.5 0v-1.5A.75.75 0 0110 15zM10 7a3 3 0 100 6 3 3 0 000-6zM15.657 5.404a.75.75 0 10-1.06-1.06l-1.061 1.06a.75.75 0 001.06 1.06l1.06-1.06zM6.464 14.596a.75.75 0 10-1.06-1.06l-1.06 1.06a.75.75 0 001.06 1.06l1.06-1.06zM18 10a.75.75 0 01-.75.75h-1.5a.75.75 0 010-1.5h1.5A.75.75 0 0118 10zM5 10a.75.75 0 01-.75.75h-1.5a.75.75 0 010-1.5h1.5A.75.75 0 015 10zM14.596 15.657a.75.75 0 001.06-1.06l-1.06-1.061a.75.75 0 10-1.06 1.06l1.06 1.06zM5.404 6.464a.75.75 0 001.06-1.06l-1.06-1.06a.75.75 0 10-1.061 1.06l1.06 1.06z" />
            </svg>
          )}
        </span>
      </span>

      {/* Background icons for visual appeal */}
      <span
        className={`absolute left-1.5 transition-opacity duration-300 ${
          isDark ? 'opacity-0' : 'opacity-100'
        }`}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 20 20"
          fill="currentColor"
          className="w-3 h-3 text-green-700"
        >
          <path d="M10 2a.75.75 0 01.75.75v1.5a.75.75 0 01-1.5 0v-1.5A.75.75 0 0110 2zM10 15a.75.75 0 01.75.75v1.5a.75.75 0 01-1.5 0v-1.5A.75.75 0 0110 15zM10 7a3 3 0 100 6 3 3 0 000-6zM15.657 5.404a.75.75 0 10-1.06-1.06l-1.061 1.06a.75.75 0 001.06 1.06l1.06-1.06zM6.464 14.596a.75.75 0 10-1.06-1.06l-1.06 1.06a.75.75 0 001.06 1.06l1.06-1.06zM18 10a.75.75 0 01-.75.75h-1.5a.75.75 0 010-1.5h1.5A.75.75 0 0118 10zM5 10a.75.75 0 01-.75.75h-1.5a.75.75 0 010-1.5h1.5A.75.75 0 015 10zM14.596 15.657a.75.75 0 001.06-1.06l-1.06-1.061a.75.75 0 10-1.06 1.06l1.06 1.06zM5.404 6.464a.75.75 0 001.06-1.06l-1.06-1.06a.75.75 0 10-1.061 1.06l1.06 1.06z" />
        </svg>
      </span>

      <span
        className={`absolute right-1.5 transition-opacity duration-300 ${
          isDark ? 'opacity-100' : 'opacity-0'
        }`}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 20 20"
          fill="currentColor"
          className="w-3 h-3"
          style={{ color: '#dcfce7' }}
        >
          <path
            fillRule="evenodd"
            d="M7.455 2.004a.75.75 0 01.26.77 7 7 0 009.958 7.967.75.75 0 011.067.853A8.5 8.5 0 116.647 1.921a.75.75 0 01.808.083z"
            clipRule="evenodd"
          />
        </svg>
      </span>
    </button>
  );
}
