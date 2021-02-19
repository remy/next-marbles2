const http = require('http');
const port = process.env.PORT || 8080;

http
  .createServer((req, res) => {
    console.log(new Date().toJSON() + ' - request');
    if (req.method === 'POST') {
      const data = [];
      // const timer = setTimeout(() => {
      //   console.log('timeout');
      //   res.writeHead(400);
      //   res.end();
      // }, 2000);
      req.on('data', (chunks) => {
        data.push(...chunks);
      });
      req.on('end', () => {
        // clearTimeout(timer);
        console.log('closed @ ' + data.length + ' bytes');
        console.log(
          Array.from(data)
            .map((_) => String.fromCharCode(_))
            .join('')
        );
        // setTimeout(() => {
        //   res.statusCode = 200;
        //   return res.end();
        // }, 100);
      });

      res.statusCode = 200;
      return res.end('\n');
    }

    // get
  })
  .listen(port);
