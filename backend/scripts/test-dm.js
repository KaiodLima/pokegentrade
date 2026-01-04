const http = require('http');
const io = require('socket.io-client');
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
  const u1 = await req('POST', '/auth/register', { email: 'dm1@example.com', password: 'secret123', displayName: 'DM 1' });
  const u2 = await req('POST', '/auth/register', { email: 'dm2@example.com', password: 'secret123', displayName: 'DM 2' });
  const t1 = u1.json.tokens.accessToken;
  const t2 = u2.json.tokens.accessToken;
  const s1 = io('http://localhost:3000', { transports: ['websocket'], auth: { token: t1 } });
  const s2 = io('http://localhost:3000', { transports: ['websocket'], auth: { token: t2 } });
  const id1 = JSON.parse(Buffer.from(t1.split('.')[1], 'base64').toString()).sub;
  const id2 = JSON.parse(Buffer.from(t2.split('.')[1], 'base64').toString()).sub;
  function waitConnect(s) {
    return new Promise((resolve, reject) => {
      const to = setTimeout(() => reject(new Error('connect timeout')), 2000);
      s.once('connect', () => { clearTimeout(to); resolve(); });
      s.once('connect_error', (e) => { clearTimeout(to); reject(e); });
      s.once('error', (e) => { clearTimeout(to); reject(e); });
    });
  }
  await waitConnect(s1);
  await waitConnect(s2);
  s1.emit('dm:join', { userId: id2 });
  s2.emit('dm:join', { userId: id1 });
  s1.emit('dm:message:send', { userId: id2, content: 'Olá DM!' });
  await new Promise(res => setTimeout(res, 300));
  const inbox1 = await req('GET', '/dm/inbox', null, t1);
  const inbox2 = await req('GET', '/dm/inbox', null, t2);
  const hist1 = await req('GET', `/dm/${id2}/messages?limit=50`, null, t1);
  console.log('INBOX1', inbox1.status, Array.isArray(inbox1.json) ? inbox1.json.length : inbox1.text);
  console.log('INBOX2', inbox2.status, Array.isArray(inbox2.json) ? inbox2.json.length : inbox2.text);
  console.log('HIST1', hist1.status, Array.isArray(hist1.json) ? hist1.json.length : hist1.text);
  s1.close(); s2.close();
  process.exit(0);
})();
