const http = require('http');

function post(path, data) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify(data);
    const req = http.request(
      {
        hostname: 'localhost',
        port: 3000,
        path,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(payload),
        },
      },
      (res) => {
        let body = '';
        res.on('data', (chunk) => (body += chunk));
        res.on('end', () => {
          try {
            resolve({ status: res.statusCode, json: JSON.parse(body) });
          } catch (e) {
            resolve({ status: res.statusCode, text: body });
          }
        });
      }
    );
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

(async () => {
  const reg = await post('/auth/register', {
    email: 'user1@example.com',
    password: 'secret123',
    displayName: 'User 1',
  });
  console.log('REGISTER', reg);
  const login = await post('/auth/login', {
    email: 'user1@example.com',
    password: 'secret123',
  });
  console.log('LOGIN', login);
  process.exit(0);
})();

