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
  const a = await req('POST', '/auth/register', { email: 'unreadA@example.com', password: 'secret123', displayName: 'A' });
  const b = await req('POST', '/auth/register', { email: 'unreadB@example.com', password: 'secret123', displayName: 'B' });
  const tA = a.json.tokens.accessToken;
  const tB = b.json.tokens.accessToken;
  const idA = JSON.parse(Buffer.from(tA.split('.')[1],'base64').toString()).sub;
  const idB = JSON.parse(Buffer.from(tB.split('.')[1],'base64').toString()).sub;
  await req('POST', '/dm/'+idB+'/messages/send', { content: 'Olá 1' }, tA).catch(()=>{});
  await req('POST', '/dm/'+idB+'/messages/send', { content: 'Olá 2' }, tA).catch(()=>{});
  const unreadB1 = await req('GET', '/dm/unread', null, tB);
  console.log('UNREAD_B1', unreadB1.status, unreadB1.json);
  await req('POST', '/dm/'+idA+'/read', null, tB);
  const unreadB2 = await req('GET', '/dm/unread', null, tB);
  console.log('UNREAD_B2', unreadB2.status, unreadB2.json);
  process.exit(0);
})();

