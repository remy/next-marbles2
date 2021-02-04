const Net = require('net');
const port = process.env.PORT || 8080;

const server = new Net.Server();
server.listen(port, function () {
  console.log(
    `Server listening for connection requests on socket localhost:${port}`
  );
});

server.on('connection', (socket) => {
  // console.clear();
  console.log('\n\nA new connection has been established.');

  // Now that a TCP connection has been established, the server can send data to
  // the client by writing to its socket.

  // The server can also receive data from the client by reading from its socket.
  let string = '';
  const bytes = [];
  let type = null;

  const POST = 1;
  const GET = 2;

  socket.on('data', function (chunk) {
    const res = chunk.toString().trim();

    console.log('+ data: ' + res.length, res);

    if (res === 'P') {
      type = POST;
      console.log('POST!');
      return;
    } else if (res === 'G') {
      console.log('GET!');
      type = GET;
      return;
    }

    if (res === '') {
      console.log('sending close');

      const data = new Uint8Array(Uint16Array.from(bytes).buffer);
      console.log(
        'data length: %s, bytes: %s, first: %s',
        bytes.length,
        data.length
      );
      console.log(
        Array.from(data)
          .map((_) => String.fromCharCode(_))
          .join('')
      );

      setTimeout(() => {
        socket.write('ACK\r\n', 'utf-8', (err) => {
          console.log('write done', err);
          socket.end();
        });
      }, 100);
    } else {
      bytes.push(...res.split(',').map((_) => parseInt(_, 10)));
    }
  });

  // When the client requests to end the TCP connection with the server, the server
  // ends the connection.
  socket.on('end', function () {
    console.log('+end');
  });

  socket.on('close', () => {
    console.log('+close');
  });

  // Don't forget to catch error, for your own sake.
  socket.on('error', function (err) {
    console.log(`+error: ${err}`);
  });
});
