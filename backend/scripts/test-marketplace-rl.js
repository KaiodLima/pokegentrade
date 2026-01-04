const http = require('http');
function req(method, path, data, token) {
  return new Promise((resolve, reject) => {
    const payload = data ? JSON.stringify(data) : '';
    const headers = { 'Content-Type': 'application/json' };
    if (payload) headers['Content-Length'] = Buffer.byteLength(payload);
    if (token) headers['Authorization'] = 'Bearer ' + token;
    const r = http.request({ hostname: 'localhost', port: 3000, path, method, headers }, res => {
      let b = '';
      res.on('data', c => b += c);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, json: JSON.parse(b) }); } catch { resolve({ status: res.statusCode, text: b }); }
      });
    });
    r.on('error', reject);
    if (payload) r.write(payload);
    r.end();
  });
}
(async () => {
  const reg = await req('POST', '/auth/register', { email: 'mktRL@example.com', password: 'secret123', displayName: 'MKT RL' });
  const token = reg.json.tokens.accessToken;
  const payload = { type: 'venda', title: 'Teste RL', description: 'Desc', price: 10.0 };
  const c1 = await req('POST', '/marketplace/ads', payload, token);
  console.log('CREATE1', c1.status, c1.json.status || c1.json.id);
  const c2 = await req('POST', '/marketplace/ads', payload, token);
  console.log('CREATE2', c2.status, c2.json.status, c2.json.remainingMs);
  process.exit(0);
})();

