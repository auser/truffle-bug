const ganache = require("../ganache");

const PORT = 8545

ganache.listen(PORT, function(err, blockchain) {
  console.log('ganache listening on port', PORT)
})
