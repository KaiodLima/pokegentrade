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
      res.on('end', () => { try { resolve({ status: res.statusCode, json: JSON.parse(b) }); } catch { resolve({ status: res.statusCode, text: b }); } });
    });
    r.on('error', reject);
    if (payload) r.write(payload);
    r.end();
  });
}
(async () => {
  // Login admin (seed defaults)
  const adminLogin = await req('POST', '/auth/login', { email: 'admin@poketibia.local', password: 'ChangeMe!123' });
  const adminTok = adminLogin.json?.tokens?.accessToken;
  if (!adminTok) { console.log('ADMIN_LOGIN_FAILED', adminLogin.status, adminLogin.text || adminLogin.json); process.exit(1); }
  // Register seller and create ad
  const sellerReg = await req('POST', '/auth/register', { email: 'seller2@example.com', password: 'secret123', displayName: 'Seller2' });
  const sellerTok = sellerReg.json?.tokens?.accessToken;
  const ad = await req('POST', '/marketplace/ads', { type: 'venda', title: 'Item raro 2', description: 'Desc', price: 50.0 }, sellerTok);
  const adId = ad.json?.id;
  // Approve by admin
  const approve = await req('PATCH', `/marketplace/ads/${adId}/approve`, null, adminTok);
  console.log('ADMIN_APPROVE', approve.status, approve.json?.status || approve.text);
  // Complete by admin
  const complete = await req('PATCH', `/marketplace/ads/${adId}/complete`, null, adminTok);
  console.log('ADMIN_COMPLETE', complete.status, complete.json?.status || complete.text);
  process.exit(0);
})();
