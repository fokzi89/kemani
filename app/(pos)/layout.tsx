'use client';

import { PowerSyncProvider } from "@/components/providers/PowerSyncProvider";
import { SubscriptionProvider } from "@/lib/context/SubscriptionContext";
import { LockScreen } from "@/components/auth/LockScreen";
import { useInactivityLock } from "@/hooks/use-inactivity-lock";

export default function POSLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { isLocked, unlock } = useInactivityLock();

  return (
    <PowerSyncProvider>
      <SubscriptionProvider>
        {isLocked && <LockScreen onUnlock={unlock} />}
        {children}
      </SubscriptionProvider>
    </PowerSyncProvider>
  );
}
