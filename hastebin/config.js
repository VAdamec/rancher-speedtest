{

  "host": "0.0.0.0",
  "port": 8080,

  "keyLength": 100,

  "staticMaxAge": 604800,

  "recompressStaticAssets": true,

  "logging": [
    {
      "level": "verbose",
      "type": "Console",
      "colorize": true
    }
  ],

  "keyGenerator": {
    "type": "random",
    "keyspace": "xxxxxxxxxxxxxxxxxxxxxx"
  },

  "storage": {
    "type": "redis",
    "host": "redis",
    "port": 6379,
    "db": 2
  },

  "documents": {
    "about": "./about.md"
  }

}
