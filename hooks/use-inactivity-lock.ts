'use client';

import { useState, useEffect, useCallback, useRef } from 'react';

const INACTIVITY_TIMEOUT = 10 * 60 * 1000; // 10 minutes in milliseconds

export function useInactivityLock() {
  const [isLocked, setIsLocked] = useState(false);
  const timeoutRef = useRef<NodeJS.Timeout | null>(null);

  const resetTimer = useCallback(() => {
    // Clear existing timeout
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }

    // Set new timeout
    timeoutRef.current = setTimeout(() => {
      setIsLocked(true);
    }, INACTIVITY_TIMEOUT);
  }, []);

  const unlock = useCallback(() => {
    setIsLocked(false);
    resetTimer();
  }, [resetTimer]);

  useEffect(() => {
    // Events that indicate user activity
    const events = [
      'mousedown',
      'mousemove',
      'keypress',
      'scroll',
      'touchstart',
      'click',
    ];

    // Reset timer on any activity
    const handleActivity = () => {
      if (!isLocked) {
        resetTimer();
      }
    };

    // Add event listeners
    events.forEach((event) => {
      document.addEventListener(event, handleActivity);
    });

    // Start initial timer
    resetTimer();

    // Cleanup
    return () => {
      events.forEach((event) => {
        document.removeEventListener(event, handleActivity);
      });
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
    };
  }, [isLocked, resetTimer]);

  return { isLocked, unlock };
}
