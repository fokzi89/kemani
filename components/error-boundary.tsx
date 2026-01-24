'use client';

import React, { Component, ReactNode } from 'react';
import { AppError, getUserFriendlyMessage, isOperationalError } from '@/lib/utils/errors';

interface Props {
  children: ReactNode;
  fallback?: (error: Error, reset: () => void) => ReactNode;
  onError?: (error: Error, errorInfo: React.ErrorInfo) => void;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

/**
 * Error Boundary Component
 * Catches JavaScript errors anywhere in the child component tree
 */
export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    // Log error to console in development
    if (process.env.NODE_ENV === 'development') {
      console.error('ErrorBoundary caught an error:', error, errorInfo);
    }

    // Call custom error handler if provided
    if (this.props.onError) {
      this.props.onError(error, errorInfo);
    }

    // TODO: Send to error logging service (Sentry, LogRocket, etc.)
    // logErrorToService(error, errorInfo);
  }

  reset = () => {
    this.setState({ hasError: false, error: null });
  };

  render() {
    if (this.state.hasError && this.state.error) {
      // Use custom fallback if provided
      if (this.props.fallback) {
        return this.props.fallback(this.state.error, this.reset);
      }

      // Default error UI
      return <DefaultErrorFallback error={this.state.error} reset={this.reset} />;
    }

    return this.props.children;
  }
}

/**
 * Default Error Fallback UI
 */
function DefaultErrorFallback({ error, reset }: { error: Error; reset: () => void }) {
  const isOperational = isOperationalError(error);
  const userMessage = getUserFriendlyMessage(error);

  return (
    <div
      className="min-h-screen flex items-center justify-center px-4"
      style={{ background: 'var(--background)' }}
    >
      <div
        className="max-w-md w-full rounded-lg p-8 text-center glass-green"
        style={{ borderColor: 'var(--border)', border: '1px solid' }}
      >
        {/* Icon */}
        <div className="mb-6">
          <div
            className="w-16 h-16 mx-auto rounded-full flex items-center justify-center"
            style={{ background: 'var(--error)', opacity: 0.1 }}
          >
            <svg
              className="w-8 h-8"
              style={{ color: 'var(--error)' }}
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
              />
            </svg>
          </div>
        </div>

        {/* Title */}
        <h2 className="text-2xl font-bold mb-3" style={{ color: 'var(--foreground)' }}>
          {isOperational ? 'Oops!' : 'Something went wrong'}
        </h2>

        {/* Message */}
        <p className="mb-6" style={{ color: 'var(--muted-foreground)' }}>
          {userMessage}
        </p>

        {/* Error details (development only) */}
        {process.env.NODE_ENV === 'development' && (
          <details className="mb-6 text-left">
            <summary
              className="cursor-pointer text-sm font-medium mb-2"
              style={{ color: 'var(--muted-foreground)' }}
            >
              Error Details (Dev Only)
            </summary>
            <pre
              className="text-xs overflow-auto p-3 rounded"
              style={{ background: 'var(--muted)', color: 'var(--muted-foreground)' }}
            >
              {error.stack || error.message}
            </pre>
          </details>
        )}

        {/* Actions */}
        <div className="flex flex-col sm:flex-row gap-3 justify-center">
          <button
            onClick={reset}
            className="px-6 py-2 rounded-lg font-medium transition-theme"
            style={{
              background: 'var(--primary)',
              color: 'var(--primary-foreground)',
            }}
          >
            Try Again
          </button>
          <button
            onClick={() => (window.location.href = '/')}
            className="px-6 py-2 rounded-lg font-medium transition-theme"
            style={{
              background: 'var(--secondary)',
              color: 'var(--secondary-foreground)',
            }}
          >
            Go Home
          </button>
        </div>

        {/* Support link */}
        {!isOperational && (
          <p className="mt-6 text-sm" style={{ color: 'var(--muted-foreground)' }}>
            If this problem persists,{' '}
            <a href="/support" className="underline" style={{ color: 'var(--primary)' }}>
              contact support
            </a>
          </p>
        )}
      </div>
    </div>
  );
}

/**
 * Hook to handle errors in functional components
 */
export function useErrorHandler() {
  const [error, setError] = React.useState<Error | null>(null);

  React.useEffect(() => {
    if (error) {
      throw error;
    }
  }, [error]);

  return setError;
}

/**
 * Async Error Boundary Wrapper
 * Catches errors from async operations
 */
export function withErrorBoundary<P extends object>(
  Component: React.ComponentType<P>,
  fallback?: (error: Error, reset: () => void) => ReactNode
) {
  return function WithErrorBoundary(props: P) {
    return (
      <ErrorBoundary fallback={fallback}>
        <Component {...props} />
      </ErrorBoundary>
    );
  };
}
