// Script to check existing tables in Supabase
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://ykbpznoqebhopyqpoqaf.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrYnB6bm9xZWJob3B5cXBvcWFmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2ODc2MTE0NywiZXhwIjoyMDg0MzM3MTQ3fQ.cVblxwWFAppPBqFiXhpIwTWKtGDITr4moL7t8SU5iUo';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkTables() {
  try {
    // Query to get all tables in the public schema
    const { data, error } = await supabase.rpc('execute_sql', {
      query: `
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_type = 'BASE TABLE'
        ORDER BY table_name;
      `
    });

    if (error) {
      // Try alternative method using pg_catalog
      const { data: altData, error: altError } = await supabase
        .from('pg_tables')
        .select('tablename')
        .eq('schemaname', 'public')
        .order('tablename');

      if (altError) {
        console.error('Error querying tables:', altError);

        // Try direct SQL query
        const { data: sqlData, error: sqlError } = await supabase.rpc('exec_sql', {
          sql: `SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE' ORDER BY table_name;`
        });

        if (sqlError) {
          console.error('Alternative query failed:', sqlError);
          process.exit(1);
        }

        console.log('Tables found in Supabase:');
        console.log(JSON.stringify(sqlData, null, 2));
        return;
      }

      console.log('Tables found in Supabase:');
      console.log(JSON.stringify(altData, null, 2));
      return;
    }

    console.log('Tables found in Supabase:');
    console.log(JSON.stringify(data, null, 2));
  } catch (err) {
    console.error('Unexpected error:', err);
    process.exit(1);
  }
}

checkTables();
