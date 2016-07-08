libtmsg
=======

Libtmsg is an inter-computer messaging system backed by `atuin-server`.

Terminology
===========

  * A _route_ is the part of the final HTTP URL that identifies the computer to
    comunicate with. Generally, libtmsg is used for inter-computer messaging
    with routes under the `/msg` umbrella, so routes have the form `/msg/X`
    where _X_ specifies the queue to enqueue or dequeue messages to or from.

Configuration
=============

Libtmsg is configured by the following module-global variables:

| Variable name | Type | Description |
| ------------- | ---- | ----------- |
| `DEBUG`       | `boolean` | Whether to print debugging output to the terminal. |
| `DEFAULT_PERIOD` | `number` | How long to wait between retries. |
| `CONNECTION`  | `table` | Parameters of the underlying HTTP connections. |

The default configuration is `DEBUG = false`, `DEFAULT_PERIOD = 0.1`.

### Detail of the `CONNECTION` table

The `CONNECTION` table has the following keys.

| Key name | Type | Description |
| -------- | ---- | ----------- |
| `HOST`   | `string` | The hostname to connect to. |
| `PORT`   | `number` | The port number to connect to. |
| `PREFIX` | `string` | A common prefix prepended to all requested routes. |

The default configuration is `HOST = localhost`, `PORT = 8080`, and `PREFIX = ""`.

Basic usage
===========

Libtmsg provides two basic functions upon which more advanced functionality can
be built.

### `send(id, msg, contentType, accept)`

Sends a message to the given route. Sends never block.

#### Arguments

| Argument name | Type | Required | Description |
| ------------- | ---- | -------- | ----------- |
| `id`          | `string` | Yes. | The route to send the message to. |
| `msg`         | `msg` | Yes. | The message to send. |
| `contentType` | `string` | No. (Default: `"text/plain;charset=utf-8"`) | The value to use for the `Content-Type` header. |
| `accept`      | `string` | No. (Default: `"*/*"`) | The value to use for the `Accept` header. |

#### Return value

The contents of the response body as a string.

### `recv(id, accept)`

Receive a message on the given route. This receive call does not block.

An empty response body from the server indicates that there are no messages
available on the given `id`. The return value of `recv` in that case is `nil`.

#### Arguments

| Argument name | Type | Required | Description |
| ------------- | ---- | -------- | ----------- |
| `id`          | `string` | Yes. | The route to poll for a message on. |
| `accept`      | `string` | No. (Default: `"*/*"`) | The value of the `Accept` header. |

#### Return value

If no message is available on the given route, then `nil`; else, the received response body as a string.

Advanced usage
==============

Using the two primitive functions `send` and `recv`, the following more advanced functions are implemented.

### `recvBlock(id, accept, timeout, period)`

Receive a message on the given route. This receive call will block until at
least the given timeout has elapsed since the first call.

_Remark:_ The current implementation of `recvBlock` simply calls `recv` in a
loop every `period` seconds until a non-`nil` value is returned. This may
change in the future if the backing server supports blocking receives via HTTP
long polling.

#### Arguments

| Argument name | Type | Required | Description |
| ------------- | ---- | -------- | ----------- |
| `id`          | `string` | Yes. | The route to wait for a message on. |
| `accept`      | `string` | No. (Default: `"*/*"`) | The value of the `Accept` header. |
| `timeout`     | `number` | No. (Default: `0`) | A guaranteed lower bound on the total time spent waiting. Because of the unpredictable duration of the HTTP requests and granularity of sleeps, the actual time spent waiting may be slightly longer. A value of `0` or `nil` means no timeout. |
| `period`      | `number` | No. (Default: configuration variable `DEFAULT_PERIOD`) | The amount of time in seconds to wait between polls for messages. |

#### Return value

Returns `nil` if the timeout is elapsed. Otherwise, returns the received
response body as a string.

Automatic Lua codec
-------------------

### `sendLua(id, data)`

Same as `send`, but serializes its input `data` which can be any serializable
Lua datatype.

### `recvLua(...)`

Same as `recv`, but deserializes the received string into a Lua datatype.

_Warning:_ If the inner call to `recv` returns `nil`, then so does the call to
`recvLua`. This means that sending a bare `nil` value cannot be received in
good faith.

### `recvLuaBlock(...)`

Same as `recvBlock`, but deserializes the received string into a Lua datatype.

The same caveat as in `recvLua` applies in case the timeout elaspes and `nil`
is returned from the inner call to `recvBlock`.

Automatic JSON codec
--------------------

The following integration with JSON is available only if `libjson` is available
when `libtmsg` loads.

### `sendJSON(id, data, parse)`

Same as `send`, but encodes its input `data` as JSON before sending. This can
be used to communicate with JSON APIs outside the game. The truthiness of
`parse` determines whether the response string should be decoded from JSON into
Lua data.

### `recvJSON(...)`

Same as `recv`, but decodes the received string from JSON into a Lua datatype.

The same caveat applies as in `recvLua`.

### `recvJSONBlock(...)`

Same as `recvBlock`, but decodes the received string from JSON into a Lua
datatype.

The same caveat applies as in `recvLuaBlock`.
