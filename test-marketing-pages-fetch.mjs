import fs from 'fs';

const routes = [
  '/',
  '/about',
  '/blog',
  '/contact',
  '/cookies',
  '/features',
  '/help',
  '/medic',
  '/pos-admin',
  '/pricing',
  '/privacy',
  '/terms',
  '/use-cases'
];

async function run() {
  let results = [];
  
  for (const route of routes) {
    try {
      const response = await fetch(`http://127.0.0.1:5173${route}`);
      const status = response.status;
      const html = await response.text();
      
      const titleMatch = html.match(/<title[^>]*>([\s\S]*?)<\/title>/i);
      const title = titleMatch ? titleMatch[1].trim() : 'No Title';
      
      let error = '';
      if (status !== 200) {
         error = `(Status not 200)`;
      } else if (html.includes('Error 500') || html.includes('Internal Server Error')) {
         error = `(500 Error in HTML)`;
      } else if (!html.includes('<script type="module"')) {
         error = `(No SvelteKit script found)`;
      }
      
      const mark = (status === 200 && !error) ? '✅' : '❌';
      results.push(`${mark} ${route.padEnd(12)} - Status: ${String(status).padEnd(3)} - Title: ${title} ${error}`);
    } catch (e) {
      results.push(`❌ ${route.padEnd(12)} - Error: ${e.message}`);
    }
  }
  
  console.log('\n--- FULL RESULTS ---');
  console.log(results.join('\n'));
}

run().catch(console.error);
