import { PowerSyncProvider } from "@/components/providers/PowerSyncProvider";
import { SubscriptionProvider } from "@/lib/context/SubscriptionContext";

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <PowerSyncProvider>
      <SubscriptionProvider>
        {children}
      </SubscriptionProvider>
    </PowerSyncProvider>
  );
}
