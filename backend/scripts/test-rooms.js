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
  const reg = await req('POST', '/auth/register', { email: 'rooms@example.com', password: 'secret123', displayName: 'RoomsUser' });
  const token = reg.json.tokens.accessToken;
  const rooms = await req('GET', '/rooms');
  const roomId = Array.isArray(rooms.json) && rooms.json.length ? rooms.json[0].id : null;
  if (!roomId) { console.log('NO_ROOMS'); process.exit(1); }
  const send = await req('POST', `/rooms/${roomId}/messages`, { roomId, content: 'hello db' }, token);
  const list = await req('GET', `/rooms/${roomId}/messages?limit=5`);
  console.log('ROOM_SEND', send.status, send.json?.id ? 'ok' : send.json?.status);
  console.log('ROOM_LIST', list.status, Array.isArray(list.json) ? list.json.length : list.text);
  process.exit(0);
})();
