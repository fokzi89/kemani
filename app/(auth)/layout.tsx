import { SubscriptionProvider } from "@/lib/context/SubscriptionContext";

export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <SubscriptionProvider>
      {children}
    </SubscriptionProvider>
  );
}
