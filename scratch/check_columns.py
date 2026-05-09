import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

try:
    res = supabase.table('products').select('*').limit(1).execute()
    if res.data:
        print(res.data[0].keys())
    else:
        print("No data in products table")
except Exception as e:
    print(e)
