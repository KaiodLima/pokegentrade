const http = require('http');
(async () => {
  const res = await new Promise((resolve, reject) => {
    const r = http.request({ hostname: 'localhost', port: 3000, path: '/metrics', method: 'GET' }, out => {
      let b = '';
      out.on('data', c => b += c);
      out.on('end', () => resolve({ status: out.statusCode, text: b }));
    });
    r.on('error', reject);
    r.end();
  });
  console.log('METRICS', res.status, res.text.split('\n').slice(0,10).join('\n'));
  process.exit(0);
})();

