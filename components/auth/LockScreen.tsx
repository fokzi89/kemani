'use client';

import { useState, useEffect, useRef } from 'react';
import { Fingerprint, Lock } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';

interface LockScreenProps {
  onUnlock: () => void;
}

export function LockScreen({ onUnlock }: LockScreenProps) {
  const [passcode, setPasscode] = useState(['', '', '', '', '', '']);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [biometricAvailable, setBiometricAvailable] = useState(false);
  const [userInfo, setUserInfo] = useState<{ name: string; email: string } | null>(null);

  const inputRefs = useRef<(HTMLInputElement | null)[]>([]);

  useEffect(() => {
    // Check if biometric is available (WebAuthn)
    const checkBiometric = async () => {
      if (window.PublicKeyCredential) {
        const available = await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();
        setBiometricAvailable(available);
      }
    };
    checkBiometric();

    // Get current user info
    const getUserInfo = async () => {
      const supabase = createClient();
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        setUserInfo({
          name: user.user_metadata?.full_name || 'User',
          email: user.email || '',
        });
      }
    };
    getUserInfo();

    // Focus first input
    inputRefs.current[0]?.focus();
  }, []);

  const handleChange = (index: number, value: string) => {
    if (value.length > 1) {
      value = value[0];
    }

    // Only allow digits
    if (value && !/^\d$/.test(value)) {
      return;
    }

    const newPasscode = [...passcode];
    newPasscode[index] = value;
    setPasscode(newPasscode);

    // Auto-focus next input
    if (value && index < 5) {
      inputRefs.current[index + 1]?.focus();
    }

    // Auto-verify when all filled
    if (newPasscode.every(digit => digit) && index === 5) {
      verifyPasscode(newPasscode.join(''));
    }
  };

  const handleKeyDown = (index: number, e: React.KeyboardEvent) => {
    if (e.key === 'Backspace' && !passcode[index] && index > 0) {
      inputRefs.current[index - 1]?.focus();
    }
  };

  const verifyPasscode = async (code: string) => {
    setError('');
    setLoading(true);

    try {
      const response = await fetch('/api/auth/verify-passcode', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passcode: code }),
      });

      const data = await response.json();

      if (!response.ok) {
        setError(data.error || 'Invalid passcode');
        setPasscode(['', '', '', '', '', '']);
        inputRefs.current[0]?.focus();
        setLoading(false);
        return;
      }

      // Success - unlock
      onUnlock();
    } catch (err) {
      setError('Something went wrong');
      setPasscode(['', '', '', '', '', '']);
      inputRefs.current[0]?.focus();
      setLoading(false);
    }
  };

  const handleBiometricAuth = async () => {
    try {
      setError('');
      setLoading(true);

      // Request biometric authentication
      const credential = await navigator.credentials.get({
        publicKey: {
          challenge: new Uint8Array(32), // In production, get from server
          timeout: 60000,
          userVerification: 'required',
        } as any,
      });

      if (credential) {
        // Verify with backend
        const response = await fetch('/api/auth/verify-biometric', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ credential }),
        });

        if (response.ok) {
          onUnlock();
        } else {
          setError('Biometric authentication failed');
        }
      }
    } catch (err) {
      console.error('Biometric auth error:', err);
      setError('Biometric authentication failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-gradient-to-b from-emerald-950 via-green-900 to-gray-900 flex items-center justify-center z-50">
      <div className="w-full max-w-md px-4">
        {/* Logo */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-20 h-20 bg-emerald-500/20 rounded-full mb-4">
            <Lock className="h-10 w-10 text-emerald-400" />
          </div>
          <h2 className="text-2xl font-bold text-emerald-400 mb-2">
            Screen Locked
          </h2>
          {userInfo && (
            <div className="text-emerald-100/70">
              <p className="font-medium">{userInfo.name}</p>
              <p className="text-sm text-emerald-100/50">{userInfo.email}</p>
            </div>
          )}
          <p className="mt-3 text-sm text-emerald-100/60">
            Enter your 6-digit passcode{biometricAvailable && ' or use fingerprint'}
          </p>
        </div>

        {/* Lock Card */}
        <div className="bg-white/5 backdrop-blur-md rounded-2xl p-8 border border-emerald-500/20">
          {/* Passcode Input */}
          <div className="flex gap-2 justify-center mb-6">
            {passcode.map((digit, index) => (
              <input
                key={index}
                ref={(el) => { inputRefs.current[index] = el; }}
                type="password"
                inputMode="numeric"
                maxLength={1}
                value={digit}
                onChange={(e) => handleChange(index, e.target.value)}
                onKeyDown={(e) => handleKeyDown(index, e)}
                disabled={loading}
                className="w-12 h-14 text-center text-2xl font-bold bg-white/10 border border-emerald-500/30 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent disabled:opacity-50"
              />
            ))}
          </div>

          {/* Error Message */}
          {error && (
            <div className="mb-4 p-3 bg-red-500/20 border border-red-500/50 rounded-lg text-red-200 text-sm text-center">
              {error}
            </div>
          )}

          {/* Biometric Button */}
          {biometricAvailable && (
            <>
              <div className="flex items-center gap-3 my-6">
                <div className="flex-1 border-t border-emerald-500/20"></div>
                <span className="text-sm text-emerald-100/50">or</span>
                <div className="flex-1 border-t border-emerald-500/20"></div>
              </div>

              <button
                onClick={handleBiometricAuth}
                disabled={loading}
                className="w-full flex items-center justify-center gap-2 px-6 py-3 bg-emerald-600/20 border border-emerald-500/30 text-emerald-100 font-semibold rounded-lg hover:bg-emerald-600/30 transition disabled:opacity-50"
              >
                <Fingerprint className="h-5 w-5" />
                Use Fingerprint
              </button>
            </>
          )}
        </div>

        {/* Info */}
        <p className="mt-6 text-center text-xs text-emerald-100/40">
          Locked after 10 minutes of inactivity for security
        </p>
      </div>
    </div>
  );
}
