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
  const reg = await req('POST', '/auth/register', { email: 'seller@example.com', password: 'secret123', displayName: 'Seller' });
  const token = reg.json.tokens.accessToken;
  const ad = await req('POST', '/marketplace/ads', { type: 'venda', title: 'Item raro', description: 'Descrição', price: 100.0 }, token);
  const list = await req('GET', '/marketplace/ads');
  console.log('AD_CREATE', ad.status, ad.json.status || 'pendente');
  console.log('AD_LIST', list.status, Array.isArray(list.json) ? list.json.length : list.text);
  process.exit(0);
})();

