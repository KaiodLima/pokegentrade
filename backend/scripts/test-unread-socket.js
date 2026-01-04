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
  const a = await req('POST', '/auth/register', { email: 'unreadSA@example.com', password: 'secret123', displayName: 'A' });
  const b = await req('POST', '/auth/register', { email: 'unreadSB@example.com', password: 'secret123', displayName: 'B' });
  const tA = a.json.tokens.accessToken;
  const tB = b.json.tokens.accessToken;
  const idA = JSON.parse(Buffer.from(tA.split('.')[1],'base64').toString()).sub;
  const idB = JSON.parse(Buffer.from(tB.split('.')[1],'base64').toString()).sub;
  const sA = io('http://localhost:3000', { transports: ['websocket'], auth: { token: tA } });
  const sB = io('http://localhost:3000', { transports: ['websocket'], auth: { token: tB } });
  await new Promise((res, rej) => { let done = 0; const ok = () => { if (++done === 2) res(); }; sA.once('connect', ok); sB.once('connect', ok); sA.once('connect_error', rej); sB.once('connect_error', rej); });
  sA.emit('dm:join', { userId: idB });
  sB.emit('dm:join', { userId: idA });
  sA.emit('dm:message:send', { userId: idB, content: 'Olá 1' });
  sA.emit('dm:message:send', { userId: idB, content: 'Olá 2' });
  await new Promise(r => setTimeout(r, 300));
  const unreadB1 = await req('GET', '/dm/unread', null, tB);
  console.log('UNREAD_B1', unreadB1.status, unreadB1.json);
  await req('POST', '/dm/'+idA+'/read', null, tB);
  const unreadB2 = await req('GET', '/dm/unread', null, tB);
  console.log('UNREAD_B2', unreadB2.status, unreadB2.json);
  sA.close(); sB.close();
  process.exit(0);
})();

