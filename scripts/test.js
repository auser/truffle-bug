const ganache = require("../ganache");
const { spawn } = require('child_process');

const PORT = 8545

ganache.listen(PORT, function(err, blockchain) {
  console.log('ganache listening on port', PORT)

  const truffle = spawn('truffle', ['test', '--network', 'development']);

  truffle.stderr.pipe(process.stdout)
  //truffle.stderr.pipe(process.stderr)
  var hideLines = false;
  truffle.stdout.on('data', function(buf){
  	var line = buf.toString();
  	if (line.match('Compilation warnings encountered')){ hideLines = true}
  	if (line.match('Contract:')){ hideLines = false}
  	if (!hideLines){
  		process.stdout.write(line);
  	} else {
  		process.stdout.write('X_REDACTED_X\n');
  	}

  });

  truffle.on('close', (code) => {
    console.log(`child process exited with code ${code}`);
    ganache.close()
    process.exit(code)
  });
});
