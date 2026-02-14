export default function APIServerHome() {
  return (
    <main style={{
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      minHeight: '100vh',
      fontFamily: 'system-ui, sans-serif',
      backgroundColor: '#fafafa',
      padding: '20px'
    }}>
      <div style={{
        maxWidth: '500px',
        textAlign: 'center',
        backgroundColor: 'white',
        padding: '48px',
        borderRadius: '12px',
        boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
        border: '2px solid #10b981'
      }}>
        <div style={{
          width: '64px',
          height: '64px',
          margin: '0 auto 24px',
          borderRadius: '12px',
          background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: '32px',
          fontWeight: 'bold',
          color: 'white'
        }}>
          K
        </div>

        <h1 style={{
          fontSize: '28px',
          fontWeight: 'bold',
          marginBottom: '12px',
          background: 'linear-gradient(135deg, #059669 0%, #10b981 100%)',
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent',
          backgroundClip: 'text'
        }}>
          Kemani API Server
        </h1>

        <div style={{
          display: 'inline-block',
          padding: '8px 16px',
          borderRadius: '20px',
          backgroundColor: 'rgba(16, 185, 129, 0.1)',
          border: '1px solid rgba(16, 185, 129, 0.3)',
          marginBottom: '24px',
          fontSize: '14px',
          fontWeight: '600',
          color: '#059669'
        }}>
          ✓ Server Running
        </div>

        <p style={{
          fontSize: '16px',
          color: '#666',
          marginBottom: '32px',
          lineHeight: '1.6'
        }}>
          REST API server for Kemani POS Flutter mobile application
        </p>

        <div style={{
          padding: '20px',
          backgroundColor: '#f0fdf4',
          border: '1px solid #86efac',
          borderRadius: '8px',
          marginBottom: '24px'
        }}>
          <div style={{
            fontSize: '32px',
            fontWeight: 'bold',
            color: '#059669',
            marginBottom: '4px'
          }}>
            57
          </div>
          <div style={{ fontSize: '14px', color: '#15803d' }}>
            API Endpoints Available
          </div>
        </div>

        <div style={{
          fontSize: '14px',
          color: '#888',
          paddingTop: '24px',
          borderTop: '1px solid #e5e5e5'
        }}>
          <p style={{ marginBottom: '8px' }}>
            <strong>Clients:</strong> Flutter Mobile, SvelteKit Marketing, SvelteKit Storefront
          </p>
          <p>
            <code style={{
              backgroundColor: '#f3f4f6',
              padding: '2px 6px',
              borderRadius: '3px',
              fontSize: '13px'
            }}>
              /api/*
            </code>
          </p>
        </div>
      </div>
    </main>
  );
}
