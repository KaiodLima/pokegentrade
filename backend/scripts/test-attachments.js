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
  const reg = await req('POST', '/auth/register', { email: 'att1@example.com', password: 'secret123', displayName: 'Att 1' });
  const token = reg.json.tokens.accessToken;
  const ad = await req('POST', '/marketplace/ads', { type: 'venda', title: 'Teste', description: 'Desc', price: 5.0 }, token);
  const up = await req('POST', '/uploads', { filename: 'arquivo.txt', contentType: 'text/plain' }, token);
  const attach = await req('POST', `/marketplace/ads/${ad.json.id}/attachments`, { url: up.json.uploadUrl.split('?')[0], type: 'text/plain' }, token);
  const list = await req('GET', '/marketplace/ads');
  console.log('AD', ad.status, ad.json.id);
  console.log('UP', up.status);
  console.log('ATT', attach.status, attach.json.id || attach.text);
  console.log('LIST', list.status, Array.isArray(list.json) ? list.json[0]?.attachments?.length : list.text);
  process.exit(0);
})();

