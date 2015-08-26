LibT
=====

LibT is a collection of ComputerCraft/Lua librarie for facilitating development
on ComputerCraft devices, i.e. computers and turtles.

`libt` is the most basic of these libraries, and brings basic functional
programming capabilities to Lua. It includes a custom module system for loading
any other libraries in the LibT suite.

Usage
-----

To load `libt`, simply use `loadfile`.

    local t = loadfile("libt")()

`libt` is (mostly) threadsafe, in the sense that if you try to load it twice,
it caches itself in the system global cache, so you always get the same
instance. This goes for all LibT modules.

To load other LibT modules, use the `require` function.

    local tnet = t.require("libtnet")

Cyclic imports are currently not supported. Creating one will (probably) crash
your device.

libtnet
=======

`libtnet` is an opinionated networking stack for ComputerCraft. It uses only
four channels to conduct all networking. Think of it as socket.io for Lua ;)

`libtnet` uses a client-server architecture, where a computer is designated
either as a client or as a server. (Of course, a server can in turn also be a
client sometimes, but whatever. Just don't get caught in any loops.)

Since all networking functionality in computercraft requires a modem, `libtnet`
exposes only one function, whose purpose is to augment a modem table with extra
functionality. To upgrade a ComputerCraft modem to a `libtnet` modem, use the
`initModem` function after loading `libt` and importing `libtnet`.

    local t = loadfile("libt")()
    local tnet = t.require("libtnet")
    local modem = peripheral.find("modem")
    tnet.initModem(modem)

The core idea in `libtnet` is all about "asking the network to perform an
action". In contrast with traditional computer networks, where two devices
typically communicate one-to-one, `libtnet` has all communications occur in a
one-to-many fashion. A client will send a request out into the network, and
wait. If a server is listening and can perform the request, then it will do it
and respond. On the flipside, a server is just a dictionary associating action
names to callbacks.

To create a server, simply write a number of callback functions, shove them all
into a table, and invoke `modem.listen`. An event loop will start up and listen
for requests on the _request channel_. Lua tables are seamlessly passed between
clients and servers thanks to ComputerCraft's `textutils.[un]serialize`
functions; just don't put any functions in your tables.

Here is an example of a server with one handler that appends an exclamation
mark to a string.

    local t = loadfile("libt")()
    local tnet = t.require("libtnet")
    local modem = peripheral.find("modem")
    tnet.initModem(modem)

    local handlers = {}
    function handlers.yell(data)
      return tnet.statusCode.OK, {
        value = data.value .. "!"
      }
    end

Here is a client that interacts with this server.

    local t = loadfile("libt")()
    local tnet = t.require("libtnet")
    local modem = peripheral.find("modem")
    tnet.initModem(modem)

    local status, response =
      modem.request(
        "yell", {
          value = "hello world"
        }
      )

    -- prints "hello world!"
    if status == tnet.statusCode.OK then
      print(response.value)
    end

libtput
=======

`libtput` is a simple client library to interact with
[tput-servant](http://github.com/djeik/tput-servant), or any similar trivial
file upload service.

Two functions are provided:

* `get(file)` downloads the file named _file_ from the service and saves it to
  disk as _file_.
* `put(file)` uploads the file named _file_ from disk to the service as _file_.

`libtput` comes with two scripts that use `libtput` and wrap it with nice error
messages when things go wrong.

* `tg file` is a wrapper for `get`.
* `tp file` is a wrapper for `put`.
