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
  const a = await req('POST', '/auth/register', { email: 'dmA@example.com', password: 'secret123', displayName: 'A' });
  const b = await req('POST', '/auth/register', { email: 'dmB@example.com', password: 'secret123', displayName: 'B' });
  const tokA = a.json.tokens.accessToken;
  const tokB = b.json.tokens.accessToken;
  const payloadB = JSON.parse(Buffer.from(tokB.split('.')[1], 'base64url').toString('utf8'));
  const idB = payloadB.sub;
  // Send from A to B via rooms endpoint does not exist; DM is Socket for send.
  // For DB check, mark/unread should work if DM records are created elsewhere; simulate inbox/unread calls.
  const inboxA = await req('GET', '/dm/inbox', null, tokA);
  const unreadA = await req('GET', '/dm/unread', null, tokA);
  console.log('DM_INBOX_A', inboxA.status, Array.isArray(inboxA.json) ? inboxA.json.length : inboxA.text);
  console.log('DM_UNREAD_A', unreadA.status, Array.isArray(unreadA.json) ? unreadA.json.length : unreadA.text);
  process.exit(0);
})();
