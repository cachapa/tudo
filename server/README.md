![tudo](tudo.svg)

an experiment in simple connected to-do lists.

This project is the server counterpart to the [tudo app](https://github.com/cachapa/tudo/tudo_client).

## Usage

The simplest way to run the program is to run main.dart:

``` shell
$ cd tudo_server
$ pub get
$ dart bin/main.dart --port 8080
Serving at http://localhost:8080
```

However, you might prefer to pre-compile the program into native code, making it much more efficient:

``` shell
$ cd tudo_server
$ pub get
$ dart2native bin/main.dart -o tudo_server
$ ./tudo_server --port 8080
Serving at http://localhost:8080
```

## Hosting

While this project can be hosted from any internet-accessible device, keep in mind:

* This project isn't suited for serverless hosting (e.g. Amazon Lambda, Google Cloud Run) since the server uses websockets for long-running sessions
* HTTPS is required as modern Android and iOS disallow apps from establishing non-encrypted connections

## How to contribute

Please file feature requests and bugs at the [issue tracker](https://github.com/cachapa/tudo/issues).
