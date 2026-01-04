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
  const reg = await req('POST', '/auth/register', { email: 'minio@test.com', password: 'secret123', displayName: 'MinIO' });
  const token = reg.json.tokens.accessToken;
  const pres = await req('POST', '/uploads', { filename: 'teste.txt', contentType: 'text/plain' }, token);
  console.log('PRES', pres.status, pres.json);
  const url = pres.json.uploadUrl;
  if (url.includes('stub=true')) {
    console.log('STUB_MODE');
    process.exit(0);
  }
  const put = await new Promise((resolve, reject) => {
    const u = new URL(url);
    const r = http.request({ hostname: u.hostname, port: parseInt(u.port || '80', 10), path: u.pathname + u.search, method: 'PUT', headers: { 'Content-Type': 'text/plain' } }, res => {
      let b = '';
      res.on('data', c => b += c);
      res.on('end', () => resolve({ status: res.statusCode, body: b }));
    });
    r.on('error', reject);
    r.write(Buffer.from('hello'));
    r.end();
  });
  console.log('PUT', put.status);
  process.exit(0);
})();

