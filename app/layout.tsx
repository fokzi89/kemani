export const metadata = {
  title: 'Kemani API Server',
  description: 'REST API server for Kemani POS Flutter mobile application',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
