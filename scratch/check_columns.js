const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_ANON_KEY;
const supabase = createClient(url, key);

async function check() {
    const { data, error } = await supabase.from('branch_inventory').select('*').limit(1);
    if (error) {
        console.error(error);
    } else if (data && data.length > 0) {
        console.log(Object.keys(data[0]));
    } else {
        console.log("No data");
    }
}

check();
