const http = require('http');
const io = require('socket.io-client');
function get(path) {
  return new Promise((resolve, reject) => {
    const r = http.request({ hostname: 'localhost', port: 3000, path, method: 'GET' }, out => {
      let b = '';
      out.on('data', c => b += c);
      out.on('end', () => resolve({ status: out.statusCode, text: b }));
    });
    r.on('error', reject);
    r.end();
  });
}
(async () => {
  const token = process.env.TEST_TOKEN || '';
  if (!token) {
    console.log('Provide TEST_TOKEN=... for socket auth');
    process.exit(0);
  }
  const socket = io('http://localhost:3000', { transports: ['websocket'], auth: { token } });
  await new Promise(resolve => socket.on('connect', resolve));
  socket.emit('rooms:join', { roomId: 'general' });
  socket.emit('rooms:message:send', { roomId: 'general', content: 'hello metrics' });
  await new Promise(r => setTimeout(r, 500));
  const m = await get('/metrics');
  console.log('METRICS HEAD', m.status, m.text.split('\n').filter(l => l.includes('poketibia_socket_messages_total')).slice(0,3).join('\n'));
  socket.disconnect();
  process.exit(0);
})();

