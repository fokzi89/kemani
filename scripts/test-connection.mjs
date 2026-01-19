import { createClient } from '@supabase/supabase-js'
import dotenv from 'dotenv'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

// Load .env.local
dotenv.config({ path: join(__dirname, '..', '.env.local') })

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

console.log('\n🔍 Testing Supabase Connection...\n')

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Missing credentials in .env.local')
  console.error('   NEXT_PUBLIC_SUPABASE_URL:', supabaseUrl ? '✅' : '❌')
  console.error('   NEXT_PUBLIC_SUPABASE_ANON_KEY:', supabaseKey ? '✅' : '❌')
  process.exit(1)
}

console.log('✅ Environment variables loaded')
console.log('   URL:', supabaseUrl)
console.log('   Key:', supabaseKey.substring(0, 20) + '...\n')

const supabase = createClient(supabaseUrl, supabaseKey)

console.log('🔌 Connecting to Supabase...\n')

try {
  // Test connection by querying subscriptions
  const { data, error } = await supabase
    .from('subscriptions')
    .select('plan_tier, monthly_fee, commission_rate, commission_cap_amount')
    .order('monthly_fee')

  if (error) {
    console.error('❌ Connection failed!')
    console.error('   Error:', error.message)
    console.error('\n💡 This usually means:')
    console.error('   - Migrations haven\'t been applied yet')
    console.error('   - Wrong credentials in .env.local')
    console.error('   - Supabase project is paused\n')
    process.exit(1)
  }

  console.log('✅ Connection successful!\n')

  if (data && data.length > 0) {
    console.log('📊 Found', data.length, 'subscription plans:\n')
    console.log('┌─────────────────────┬──────────────┬────────────┬──────────────┐')
    console.log('│ Plan Tier           │ Monthly Fee  │ Commission │ Cap          │')
    console.log('├─────────────────────┼──────────────┼────────────┼──────────────┤')
    data.forEach(sub => {
      const tier = sub.plan_tier.padEnd(19)
      const fee = `₦${sub.monthly_fee.toLocaleString()}`.padEnd(12)
      const rate = `${sub.commission_rate}%`.padEnd(10)
      const cap = sub.commission_cap_amount ? `₦${sub.commission_cap_amount}`.padEnd(12) : 'N/A'.padEnd(12)
      console.log(`│ ${tier} │ ${fee} │ ${rate} │ ${cap} │`)
    })
    console.log('└─────────────────────┴──────────────┴────────────┴──────────────┘\n')

    console.log('🎉 Everything is working perfectly!')
    console.log('   ✅ Credentials are correct')
    console.log('   ✅ Database migrations applied')
    console.log('   ✅ Ready to start building!\n')
  } else {
    console.log('⚠️  Connection works but no data found')
    console.log('   You need to apply the database migrations\n')
  }

} catch (err) {
  console.error('❌ Unexpected error:', err.message)
  process.exit(1)
}
