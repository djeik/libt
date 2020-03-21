LibT
=====

LibT is a collection of ComputerCraft/Lua libraries for facilitating development
on ComputerCraft devices.

`libt` is the most basic of these libraries, and brings basic functional
programming capabilities to Lua. It includes a module system for loading
any other libraries in the LibT.

All LibT libraries live in the `/lib` directory. Configuration files live in
the `/etc` directory.

To load `libt`, simply use `loadfile`.

    local t = loadfile("libt")()

Modules
-------

LibT includes a module system.

Use `t.require(LIB)` to load the library `LIB` (a string) by traversing a list
of search paths that includes the `/lib` directory. Modules are cached globally
in each computer, so module state persists among programs that are
executed. Loading the same module twice returns the same instance.

The LibT module cache can be flushed by running `libt` as a program and giving
it any argument, e.g. `libt flush`. This can be necessary when a module enters
an invalid state due to a programming error.

An example LibT module `isEven` is defined like this:

```lua
local isEven = {
  VERSION = { 0, 0, 1, 0 }
}

function isEven.check(n)
  return n % 2 == 0
end
>>>>>>> readme; move module-specific docs to the doc subdirectory

return isEven
```

Key observations:
* The module is a Lua table. It must include a `VERSION` key that is an array of
  4 numbers.
* Define the contents of your module -- functions, constants, etc. -- as entries
  in the table.
* Return the table at the end of the file.

The module's table is essentially its export list. Private functions can be
defined with `local function foo () ... end`.

Documentation
-------------

Module-specific documentation is in the `doc/` subdirectory.
Here is a brief overview of some of the most sophisticated libraries.

### libtmsg

tput-servant was augmented with a simple messaging system, whereby sending a
POST request to `/msg/:id` enqueues a message in the queue named `:id` and a
GET request to `/msg/:id` dequeues a message from the named queue.
This functionality is exposed by libtmsg. Hence, libtmsg is an alternative to
libtnet that is more robust, works across any distance, and costs no ingame
resources!

#### Basic API

* `send(id, msg, [contentType], [accept])` sends the given message to the queue
  named `id`. `contentType` and `accept` are used for the values of the
  `Content-Type` and `Accept` HTTP headers. By default, these are utf-8 plain
  text and `*`, as required by tput-servant.
* `recv(id, [accept])` dequeues a message from the queue named `id`. The value
  of `accept` is used for the HTTP `Accept` header, and defaults to `*`.
  Returns nil if the GET fails, or if the queue is empty.
* `clearMessages(id)` clears the queue named `id`. This call cannot fail.

#### Advanced API

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

### librmi

Librmi is a remote method invocation library for executing code on other
computers. It leverages libtmsg and libreply.

#### Example

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
