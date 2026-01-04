(async () => {
  const token = process.env.TEST_TOKEN || '';
  const endpoint = 'http://localhost:3000';
  const pres = await fetch(`${endpoint}/uploads`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify({ filename: 'post-test.txt', contentType: 'text/plain' }),
  });
  const pj = await pres.json();
  if (pj.method === 'POST') {
    const fd = new FormData();
    Object.entries(pj.fields).forEach(([k, v]) => fd.append(k, String(v)));
    fd.append('file', new Blob([Buffer.from('hello post')]), 'post-test.txt');
    const resp = await fetch(pj.postUrl, { method: 'POST', body: fd });
    console.log('POST upload status', resp.status);
  } else {
    console.log('PUT mode', pj.uploadUrl ? 'ok' : 'missing');
  }
  process.exit(0);
})();

