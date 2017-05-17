libtnet
-------

`libtnet` is an opinionated networking stack for ComputerCraft. It uses only
four channels to conduct all networking. Think of it as socket.io for Lua ;)

`libtnet` uses a client-server architecture, where a computer is designated
either as a client or as a server. (Of course, a server can in turn also be a
client sometimes, but whatever. Just don't get caught in any loops.)

Data is transferred between the client and the server with serialized Lua
tables.

### Example

Since all networking functionality in computercraft requires a modem, `libtnet`
exposes only one function, whose purpose is to augment a modem table with extra
functionality. To upgrade a ComputerCraft modem to a `libtnet` modem, use the
`init` function after loading `libt` and importing `libtnet`.

    local t = loadfile("libt")()
    local tnet = t.require("libtnet")
    local modem = peripheral.find("modem")
    tnet.init(modem)

The core idea in `libtnet` is all about "asking the network to perform an
action". In contrast with traditional computer networks, where two devices
typically communicate one-to-one, `libtnet` has all communications occur in a
one-to-many fashion. A client will send a request out into the network, and
wait. If a server is listening and can perform the request, then it will do it
and respond. On the flipside, a server is just a dictionary associating action
names to callbacks.

To create a server, simply write callback functions, shove them all into a
table, and invoke `modem.listen`. An event loop will start up and listen for
requests on the _request channel_. Lua tables are seamlessly passed between
clients and servers thanks to ComputerCraft's `textutils.[un]serialize`
functions; just don't put any functions in your tables.

Here is an example of a server with one handler that appends an exclamation
mark to a string.

    local t = loadfile("libt")()
    local tnet = t.require("libtnet")
    local modem = peripheral.find("modem")
    tnet.init(modem)

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
    tnet.init(modem)

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

### Catch-all handlers

As you might have noticed in the example client/server interaction above, the
action name was the name of the function in the handlers table. This is no
coincidence. This is how actions get their names and can be discovered on the
network.

You can register a catch-all action with the name `*`. This is not a valid Lua
identifier, so you have to jump through some hoops.

    local handlers = {}
    handlers["*"] = function(data)
      return {
        message = "Hello from the catch-all!"
      }
    end
    modem.listen(handlers)

Catch-alls are nasty, please don't use them. Action names SHOULD be unique
within a network, meaning that only one device can listen for the catch-all
action. If more than one device listens to same action (including the
catch-all!), you get network races!

### Status codes

Every request handler must return a status code and value depending on the
status code. Some status codes are not directly transmitted to the client, but
instance have implications within the response handling framework.

In any case where the response table is optional, an empty table is sent to the
client.

The following describes the status codes that a handler can return.

*   `OK` indicates success. The response table is optional.

    The response table can contain arbitrary data that is
    returned to the client.

*   `FOUND` indicates that the request should be repeated with a different
    action. Future requests SHOULD be sent to the original action, however. The
    response table is required.

    The response table MUST include the entry `action` which identifies the
    action to resend the request for. Future request SHOULD be sent with the
    original action, however.

*   `MOVED` indicates that the request should be repeated with a different
    action. Future requests MUST be sent to the new action. The response table
    is required.

    The response table is the same as for `FOUND`.

    By default, the `libtnet` client library will automatically save the
    association from old action to the new action, so requests sent to the old
    action will transparently be translated into requests to the new action.

*   `BAD` indicates a client failure. The response table is optional.

    The response table MAY include an entry `message` which contains a
    human-readable description of the error. If the error cannot be recovered
    by the client application, the client application SHOULD relay this message
    to the user.

    The response table MAY include an entry `errors` which is an array of table
    paths that identify the erroneous components of the request table. A table
    path is itself an array of strings or integers with which to index the
    request table to reach the erroneous component. If the `errors` entry is
    left empty, then the request table SHOULD be considered malformed in a
    general way.

*   `REPEAT` indicates a server failure that can be recovered by waiting and
    resending the request. This status SHOULD be used when concurrency concerns
    arise in server application code.

    The response table is the same as for `FOUND`, but with one addition.

    The response table MUST include an entry `timeout`, which is the time in
    seconds to wait before resending the request.

    By default, the `libtnet` client library automatically handles `REPEAT`
    responses, so client application code never has to deal with it.

*   `FAIL` indicates a server failure. The response table is optional.

    By default, the `libtnet` framework SHALL automatically issue these
    responses if unhandled exceptions arise in a handler. This status SHOULD
    only arise if exceptional situations outside the control of the
    application; handlers SHOULD NOT return these status codes themselves. The
    response table generated by the `libtnet` framework SHALL include the entry
    `message` with the error message of the exception that resulted in the
    error. The generated response table SHALL NOT include any other entries.

    If a response table is present and includes a `message` entry, then the
    message SHOULD be relayed to the user.

*   `WAIT` indicates that the processing time on the server will likely exceed
    the timeout set by the client, and that the client library SHOULD wait
    longer before issuing a `TIMEOUT` status to the application code. The
    response table is required.

    The response table MUST include an entry `timeout` which indicates the
    number of seconds that the client SHOULD wait for, at least, before issuing
    a `TIMEOUT` status.

    By default, the `libtnet` client library automatically handles `WAIT`
    responses, so client application code never interacts with `WAIT` responses
    itself.

*   `ABORT` indicates a severe failure to the `libtnet` framework. The
    `libtnet` event loop will forcefully quit and any pending requests will be
    left in the event queue.

    No response is sent to the client.
