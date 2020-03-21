libtput
=======

`libtput` is a simple client library to interact with
[tput-servant](http://github.com/djeik/tput-servant), or any similar trivial
file upload service.

Three functions are provided:

* `get(file)` downloads the file named _file_ from the service and saves it to
  disk as _file_.
* `put(file)` uploads the file named _file_ from disk to the service as _file_.
* `list()` produces a listing of all available files on the upload service with
  one entry per line.

`libtput` comes with three scripts that use `libtput` and wrap it with nice
error messages when things go wrong.

* `tg file` is a wrapper for `get`.
* `tp file` is a wrapper for `put`.
* `tls` is a wrapper for `list`.
