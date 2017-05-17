LibT
=====

LibT is a collection of ComputerCraft/Lua libraries for facilitating
development on ComputerCraft devices, i.e. computers and turtles.

`libt` is the most basic of these libraries, and brings basic functional
programming capabilities to Lua. It includes a custom module system for loading
any other libraries in the LibT suite.

To load `libt`, simply use `loadfile`.

    local t = loadfile("libt")()

`libt` is (mostly) threadsafe, in the sense that if you try to load it twice,
it caches itself in the system global cache, so you always get the same
instance. This goes for all LibT modules.

To load other LibT modules, use the `require` function.

    local tnet = t.require("libtnet")

If `require` fails it has nil. To handle the extremely common case or erroring
on nil, LibT core provides `requireStrict`.

Cyclic imports should be fine, since modules are cached, to avoid unnecessarily
reloading them. If the same module is loaded twice (for example, libttext is
requested independently by two dependencies of your program) then the same Lua
table is returned by each call to require.

It can be useful to clear the module cache. This is accomplished with the
`clearModuleCache` function. This function can be invoked from the command line
by executing libt directly with a truthy argument, e.g. `libt reload`.

libtput
-------

`libtput` is a simple client library to interact with
[tput-servant](http://github.com/djeik/tput-servant), or any similar trivial
file upload service.

Three functions are provided:

* `get(file)` downloads the file named _file_ from the service and saves it to
  disk as _file_; returns nil if the download fails.
* `put(file)` uploads the file named _file_ from disk to the service as _file_.
* `list()` produces a listing of all available files on the upload service with
  one entry per line.

`libtput` comes with three scripts that use `libtput` and wrap it with nice
error messages when things go wrong.

* `tg file` is a wrapper for `get`.
* `tp file` is a wrapper for `put`.
* `tls` is a wrapper for `list`.

Libtput provides additional helper functions for common workflows.

* `getStrict(file)` will error if `get(file)` would return nil.
* `loadfile(file)` will call `getStrict(file)` and the use Lua's stock
  `loadfile`. This is useful for loading functions over the network.

libtmsg
-------

tput-servant was augmented with a simple messaging system, whereby sending a
POST request to `/msg/:id` enqueues a message in the queue named `:id` and a
GET request to `/msg/:id` dequeues a message from the named queue.
This functionality is exposed by libtmsg. Hence, libtmsg is an alternative to
libtnet that is more robust, works across any distance, and costs no ingame
resources!

### Basic API

* `send(id, msg, [contentType], [accept])` sends the given message to the queue
  named `id`. `contentType` and `accept` are used for the values of the
  `Content-Type` and `Accept` HTTP headers. By default, these are utf-8 plain
  text and `*`, as required by tput-servant.
* `recv(id, [accept])` dequeues a message from the queue named `id`. The value
  of `accept` is used for the HTTP `Accept` header, and defaults to `*`.
  Returns nil if the GET fails, or if the queue is empty.
* `clearMessages(id)` clears the queue named `id`. This call cannot fail.

### Advanced API

* `recvBlock(id, [accept], [timeout], [period], [strict])` calls `recv`
  repeatedly until a message is received. Hence, this is a polling
  implementation that blocks until a message is received.
  `period` controls how long to wait between polls, and defaults to 100ms.
  `timeout` is how long to wait in total because giving up and returning nil.
  `strict` is an optional flag that causes `error` to be used if a timeout
  occurs.
* `recvLua` - same as `recv` but deserializes the response with `t.read`.
* `recvLuaBlock` - same as `recv` but deserializes the response with `t.read`.
* `sendLua` - same as `send` but serializes the request with `t.show`.
* `recvJSON`
* `recvJSONBlock`
* `sendJSON`

librmi
------

Librmi is a remote method invocation library for executing code on other
computers. It leverages libtmsg and libreply.

### Example

To run a script on another computer, first place the script in the `/rmi`
directory. This is where librmi looks for scripts to run remotely.
Then, use the `bind` function to construct a proxy object for the remote
machine. The remote machine must be running `rmid('battery')` in this case.

    -- /localscript
    local t = loadfile("libt")()
    local rmi = t.requireStrictTg("librmi")
    local battery = rmi.bind("battery")
    print(t.show(battery.getBatteryInfo()))

    -- /rmi/getBatteryInfo
    -- actually implement logic for wrapping a battery as a peripheral and
    -- extracting its info into a nice table.

Librmi caches RMI scripts with module scope. To clear the cache use
`rmi.clearScriptCache`.
