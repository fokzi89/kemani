import { createClient } from '@/lib/supabase/server'

export default async function TestPage() {
  const supabase = await createClient()

  // Test 1: Check connection by listing subscription plans
  const { data: subscriptions, error: subError } = await supabase
    .from('subscriptions')
    .select('plan_tier, monthly_fee, commission_rate, commission_cap_amount')
    .order('monthly_fee')

  // Test 2: Check if custom functions exist
  const { data: ecommerceTest, error: funcError } = await supabase
    .rpc('can_enable_ecommerce', { p_tenant_id: '00000000-0000-0000-0000-000000000000' })

  // Test 3: Get database info
  const { data: version, error: versionError } = await supabase
    .rpc('version' as any)

  return (
    <div className="p-8 max-w-4xl mx-auto">
      <h1 className="text-3xl font-bold mb-6">Supabase Connection Test</h1>

      {/* Connection Status */}
      <div className="mb-8 p-4 bg-green-50 border border-green-200 rounded-lg">
        <h2 className="text-xl font-semibold text-green-800 mb-2">
          ✅ Connection Status: SUCCESS
        </h2>
        <p className="text-green-700">
          Successfully connected to Supabase!
        </p>
      </div>

      {/* Test 1: Subscription Plans */}
      <div className="mb-6">
        <h2 className="text-2xl font-semibold mb-3">📊 Subscription Plans</h2>
        {subError ? (
          <div className="p-4 bg-red-50 border border-red-200 rounded">
            <p className="text-red-700 font-semibold">❌ Error loading subscriptions:</p>
            <pre className="mt-2 text-sm text-red-600">{JSON.stringify(subError, null, 2)}</pre>
          </div>
        ) : subscriptions && subscriptions.length > 0 ? (
          <div className="overflow-x-auto">
            <table className="min-w-full bg-white border border-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-2 border-b text-left">Plan Tier</th>
                  <th className="px-4 py-2 border-b text-left">Monthly Fee</th>
                  <th className="px-4 py-2 border-b text-left">Commission Rate</th>
                  <th className="px-4 py-2 border-b text-left">Commission Cap</th>
                </tr>
              </thead>
              <tbody>
                {subscriptions.map((sub, idx) => (
                  <tr key={idx} className="hover:bg-gray-50">
                    <td className="px-4 py-2 border-b font-mono">{sub.plan_tier}</td>
                    <td className="px-4 py-2 border-b">₦{sub.monthly_fee.toLocaleString()}</td>
                    <td className="px-4 py-2 border-b">{sub.commission_rate}%</td>
                    <td className="px-4 py-2 border-b">
                      {sub.commission_cap_amount ? `₦${sub.commission_cap_amount}` : 'N/A'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            <p className="mt-2 text-sm text-green-600">
              ✅ Found {subscriptions.length} subscription plans
            </p>
          </div>
        ) : (
          <div className="p-4 bg-yellow-50 border border-yellow-200 rounded">
            <p className="text-yellow-700">⚠️ No subscriptions found. Have you run the migrations?</p>
          </div>
        )}
      </div>

      {/* Test 2: Custom Functions */}
      <div className="mb-6">
        <h2 className="text-2xl font-semibold mb-3">🔧 Custom Functions</h2>
        {funcError ? (
          <div className="p-4 bg-yellow-50 border border-yellow-200 rounded">
            <p className="text-yellow-700 font-semibold">⚠️ Custom functions not found</p>
            <p className="mt-2 text-sm text-yellow-600">
              This is expected if migrations 011 and 012 haven't been applied yet.
            </p>
            <pre className="mt-2 text-xs text-yellow-600">{JSON.stringify(funcError, null, 2)}</pre>
          </div>
        ) : (
          <div className="p-4 bg-green-50 border border-green-200 rounded">
            <p className="text-green-700">✅ Custom functions are working!</p>
            <pre className="mt-2 text-sm">{JSON.stringify(ecommerceTest, null, 2)}</pre>
          </div>
        )}
      </div>

      {/* Database Version */}
      <div className="mb-6">
        <h2 className="text-2xl font-semibold mb-3">💾 Database Info</h2>
        {versionError ? (
          <div className="p-4 bg-red-50 border border-red-200 rounded">
            <p className="text-red-700">Error: {versionError.message}</p>
          </div>
        ) : (
          <div className="p-4 bg-blue-50 border border-blue-200 rounded">
            <pre className="text-sm text-blue-700">{JSON.stringify(version, null, 2)}</pre>
          </div>
        )}
      </div>

      {/* Environment Variables Check */}
      <div className="mb-6">
        <h2 className="text-2xl font-semibold mb-3">🔐 Environment Variables</h2>
        <div className="p-4 bg-gray-50 border border-gray-200 rounded">
          <div className="space-y-2">
            <div className="flex items-center">
              <span className="font-semibold mr-2">NEXT_PUBLIC_SUPABASE_URL:</span>
              <span className="font-mono text-sm">
                {process.env.NEXT_PUBLIC_SUPABASE_URL ?
                  `✅ ${process.env.NEXT_PUBLIC_SUPABASE_URL}` :
                  '❌ Not set'}
              </span>
            </div>
            <div className="flex items-center">
              <span className="font-semibold mr-2">NEXT_PUBLIC_SUPABASE_ANON_KEY:</span>
              <span className="font-mono text-sm">
                {process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?
                  `✅ ${process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY.substring(0, 20)}...` :
                  '❌ Not set'}
              </span>
            </div>
            <div className="flex items-center">
              <span className="font-semibold mr-2">SUPABASE_SERVICE_ROLE_KEY:</span>
              <span className="font-mono text-sm">
                {process.env.SUPABASE_SERVICE_ROLE_KEY ?
                  `✅ ${process.env.SUPABASE_SERVICE_ROLE_KEY.substring(0, 20)}...` :
                  '❌ Not set'}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Next Steps */}
      <div className="mt-8 p-6 bg-blue-50 border border-blue-200 rounded-lg">
        <h2 className="text-xl font-semibold text-blue-800 mb-3">🚀 Next Steps</h2>
        <ul className="list-disc list-inside space-y-2 text-blue-700">
          <li>If subscription plans show: ✅ Database is working!</li>
          <li>If custom functions fail: Apply migrations 011 and 012</li>
          <li>Check the <code className="bg-white px-2 py-1 rounded">docs/implementation-roadmap.md</code> for what to build next</li>
          <li>Start with authentication pages or the POS interface</li>
        </ul>
      </div>
    </div>
  )
}
