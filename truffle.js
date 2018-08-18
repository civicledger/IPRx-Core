// Importing babel to be able to use ES6 imports
require("babel-register")({
  presets: [
    ["env", {
      "targets" : {
        "node" : "8.0"
      }
    }]
  ],
  retainLines: true,
});
require("babel-polyfill");

module.exports = {
  networks: {
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '*', // Match any network id
      gas: 8000000,
    },
    integration: {
      host: 'localhost',
      port: 8545,
      network_id: '*', // Match any network id
      gas: 8000000,
    }
  }
};
