librmi
======

Librmi is a remote method invocation layer built on top of
[libtmsg](https://github.com/tsani/libt/blob/master/doc/libtmsg.markdown).

Librmi works in conjunction with
[rmid](https://github.com/tsani/libt/blob/master/rmid), the RMI daemon to run
in order to turn a computer into a zombie.

Terminology
===========

  * A librmi _server_ is a computer running `rmid`.
  * A librmi _client_ is a computer or program that uses `librmi`.
  * An _RMI_ is a specific kind of payload sent to to a computer running
    `rmid`.
  * A _program template_ is a a Lua program stored in the `/rmi` directory on
    the librmi client's filesystem.
  * A _proxy object_ is a Lua table on which invoking methods sends an RMI to
    the proxy object's associated machine.

_Remark:_ `rmid` is quite general, and can be used without librmi. Librmi
merely provides a request-response layer on top of `rmid` that makes
interacting with it quite easy.

Quickstart
==========

### Infrastructure

On the machine you would like to send RMIs to, install `rmid`. `rmid` depends
on libtmsg. On the machine that will be sending RMIs, install librmi. Librmi
depends on libreply (and thus indirectly on libtmsg) and on libtput.

Run `rmid X` on a computer where `X` is a unique name associated with that
machine. It is common practice to set the computer label to something unique
and then use the following as the machine's `startup` program.

```lua
shell.run("rmid", os.getComputerLabel())
```

### Create a program template

Write a program template under the `/rmi` directory on the client computer.

Here is a program template taking two arguments that sets the redstone output
on the given side of the computer. We will save this template under
`/rmi/setRedstoneOutput`.

```lua
local SIDE, STATE = ...
redstone.setOutput(SIDE, STATE)
```

_Remark:_ In this case, it would have been possible to simply write
`redstone.setOutput(...)`.

### Create a proxy object

Proxy objects are a convenient interface to the `request` function, which is
slightly more general. Create a proxy object by using the `bind` function of
`librmi`.

```lua
local t = loadfile("libt")() or error("failed to load libt")
local rmi = t.requireStrict("librmi")
local machine = rmi.bind("X")
```
where _X_ is the name provided on the command-line to `rmid` on the server.

### Send RMIs using the proxy object

Indexing into the proxy object constructs a function that will send the RMI,
wait for the response, perform all necessary Lua object encoding and decoding,
and reraise any exceptions thrown by the program template on the remote
machine. Consequently, we have the illusion of running code locally when in
reality we are performing actions remotely.

```lua
machine.setRedstoneOutput("bottom", true)
sleep(5)
machine.setRedstoneOutput("bottom", false)
```

Reference
=========

### `loadTemplate(name, tg)`

Loads a program template. Uses a module-global cache so that repeated uses of
the same template do not require filesystem access. Provides integration with
libtput in order to dynamically fetch program templates from the tput server if
they cannot be loaded from disk.

This function is only necessary for advanced usage of librmi, outside the use
of the `request` or proxy object patterns

#### Arguments

| Argument name | Type | Required | Description |
| ------------- | ---- | -------- | ----------- |
| `name`        | `string` | Yes. | The name of the file under `/rmi` to load. |
| `tg`          | `boolean` | No. (Default: `false`) | Whether to load a missing template from a tput server. |

#### Return value

Returns the program template as a string.

### `request(route, templateName, ...)`

Sends an RMI on a given route and waits for a response.

#### Arguments

| Argument name | Type | Required | Description |
| ------------- | ---- | -------- | ----------- |
| `route`       | `string` | Yes. | The libtmsg route, without a `/msg` prefix, to send the RMI to. |
| `templateName` | `string` | Yes. | The name of the program template to send. |

All subsequent arguments are supplied to the program template by `rmid` on the
server-side.

#### Return value

Returns two values. The first is a boolean indicating success. If is false if
and only if the program template raised an unhandled exception. If it is true,
then the second return value is the value returned by the program template,
which can be of any type. If it is false, then the second return value is the
value passed to the call to `error` that went unhandled. Typically, this is an
exception string.

### `bind(route)`

Constructs a proxy object associated with a given route.

#### Arguments

| Argument name | Type | Required | Description |
| ------------- | ---- | -------- | ----------- |
| `route`       | `string` | Yes. | The route to associate the proxy object to. |

#### Return value

The return value is an empty Lua table whose metatable is such that indexing
produces a function whose signature is identical to that of the underlying
program template and whereupon being called will send an RMI to the proxy
object's associated route.

For example if `p` is a proxy object associated with the route `test-route`,
then `p.foo(bar)` is equivalent to `rmi.request("test-route", "foo", bar)`,
along with some handling of the return pair to reraise exceptions if any.
