
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabase = createClient(process.env.PUBLIC_SUPABASE_URL, process.env.PUBLIC_SUPABASE_ANON_KEY);

async function list() {
    const { data, error } = await supabase.from('tenants').select('id, name, subdomain, slug').limit(5);
    if (error) console.error(error);
    else console.log(JSON.stringify(data, null, 2));
}
list();
