# HOWTO

## Intended Audience

People interesting in programming Fractalide applications.

## Purpose

To provide a step-by-step indepth example with links to source code on how to program Fractalide applications.
We'll be building a simple backend for a Todo app.

## Prerequisites

The reader should have read these documents:

1. [Nodes](./nodes/README.md)
2. [Edges](./edges/README.md)
3. [Fractals](./fractals/README.md)
4. [Services](./services/README.md)

## Steps

### Fractalide installation

#### Virtualbox guest installation

* Complete the [Installing Virtualbox Guest](http://nixos.org/nixos/manual/index.html#sec-instaling-virtualbox-guest) section of the NixOS Manual.

#### Building the `Fractalide Virtual Machine (FVM)``

Once logged into your virtualbox guest issue these commands:

* `$ git clone https://github.com/fractalide/fractalide.git`
* `$ cd fractalide`
* `$ nix-build`

Let us inspect the content of the newly created symlink called `result`.

```
$ readlink result
/nix/store/ymfqavzrgmj3q3aljgwvh769fq9dszp2-fvm
```
```
$ tree result
result
└── bin
    └── fvm
```
```
$ file result/bin/fvm
result/bin/fvm: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, interpreter /nix/store/8lbpq1vmajrbnc96xhv84r87fa4wvfds-glibc-2.24/lib/ld-linux-x86-64.so.2, for GNU/Linux 2.6.32, not stripped
```

#### Peek under the hood

You shouldn't need to care too much about this during your everyday programming, but it's pleasant deviation from most normal workflows and thus should be explained.

Let's build a `subgraph` that runs a contrived `maths_boolean_nand` `agent`.

* `$ nix-build --argstr node test_nand`

This replaces the `result` symlink with a new symlink pointing to a generated file.
```
$ readlink result
/nix/store/zld4d7zc80wh38qhn00jqgc6lybd2cdi-test_nand
```
Let's investigate the contents of this executable file.
```
$ cat result
/nix/store/ymfqavzrgmj3q3aljgwvh769fq9dszp2-fvm/bin/fvm /nix/store/jk5ibldrvi6cai5aj1j00p8rgi3zw4l7-test_nand
```
Notice that we're passing the path of the actual `test_nand` `subgraph` into the `fvm`.

What does the contents of the actual `/nix/store/jk5ibldrvi6cai5aj1j00p8rgi3zw4l7-test_nand` file look like (the argument to `fvm`)?
```
$ cat /nix/store/jk5ibldrvi6cai5aj1j00p8rgi3zw4l7-test_nand/lib/lib.subgraph
'/nix/store/ynm9ipggdvxhzi5l2kkz9cgiqgvq2g87-prim_bool:(bool=true)' -> a nand(/nix/store/y919fp98qw33w0cs2wn5wzwgwpwgbchs-maths_boolean_nand) output -> input io_print(/nix/store/4fnk9dmky6jni4f4sbrzl1xsj50m3mb0-maths_boolean_print)
'/nix/store/ynm9ipggdvxhzi5l2kkz9cgiqgvq2g87-prim_bool:(bool=true)' -> b nand()
```
```
$ file /nix/store/jk5ibldrvi6cai5aj1j00p8rgi3zw4l7-test_nand/lib/lib.subgraph
/nix/store/jk5ibldrvi6cai5aj1j00p8rgi3zw4l7-test_nand/lib/lib.subgraph: ASCII text
```

The `--argstr node xxx` are arguments passed into the `nix-build` executable. Specifically

```
$ man nix-build
...
       --argstr name value
           This option is like --arg, only the value is not a Nix expression but a string. So instead
           of --arg system \"i686-linux\" (the outer quotes are to keep the shell happy) you can say
           --argstr system i686-linux.
...
```

The name `node` refers to the top level `graph` to be executed by the `fvm`. `nix` compiles each of the `agents` and inserts their paths into `subgraphs`. The `fvm` knows how how to recursively load the entire hierarchy of `subgraphs` which contain fully qualified paths to their composed `agents`.

#### Quick feel of the system

##### A = (Graph setup + tear down):

```
$ nix-build --argstr node bench_load
/nix/store/ij8jri0z1k5n447f9s0x5yfx5p9iqnnf-bench_load

$ sudo nice -n -20 perf stat -r 10 -d ./result
...
       3.684139058 seconds time elapsed                                          ( +-  0.56% )
```

##### B = (Graph setup + tear down + message pass + increment):

```

$ nix-build --argstr node bench
/nix/store/mfl206ccv86wvyi2ra5296l8n1bks24x-bench

$ sudo nice -n -20 perf stat -r 10 -d ./result

 Performance counter stats for './result' (10 runs):

       6638.755996      task-clock (msec)         #    1.443 CPUs utilized            ( +-  0.57% )
           268,864      context-switches          #    0.040 M/sec                    ( +-  0.47% )
             3,047      cpu-migrations            #    0.459 K/sec                    ( +- 10.08% )
            82,417      page-faults               #    0.012 M/sec                    ( +-  0.03% )
    18,012,749,608      cycles                    #    2.713 GHz                      ( +-  0.66% )  (50.10%)
   <not supported>      stalled-cycles-frontend
   <not supported>      stalled-cycles-backend
    18,396,303,772      instructions              #    1.02  insns per cycle          ( +-  0.10% )  (62.48%)
     3,008,536,908      branches                  #  453.178 M/sec                    ( +-  0.06% )  (73.97%)
        13,396,472      branch-misses             #    0.45% of all branches          ( +-  1.01% )  (74.08%)
     6,955,828,023      L1-dcache-loads           # 1047.761 M/sec                    ( +-  0.50% )  (63.04%)
       184,998,022      L1-dcache-load-misses     #    2.66% of all L1-dcache hits    ( +-  0.81% )  (29.73%)
        49,018,759      LLC-loads                 #    7.384 M/sec                    ( +-  0.99% )  (26.13%)
         3,032,354      LLC-load-misses           #    6.19% of all LL-cache hits     ( +-  1.56% )  (37.74%)

       4.601455409 seconds time elapsed                                          ( +-  0.66% )


```
##### (Message Passing + Increment) = B - A:

```
>>> 4.601455409 - 3.684139058
0.9173163509999998
```

This just gives you a *feel* for the system:
* `3.7 secs` to setup `10,000` [rust agents](./nodes/bench/inc/lib.rs) + teardown `10,000` agents.
* `4.6 sces` to setup `10,000` agents + message pass `10,000` times + increment `10,000` times + teardown `10,000` `agents`.
* `0.9 sec` to message pass `10,000` times + increment `10,000` times.


#### A Todo backend

We will design an http server backend that'll host a set of `todos`. It will provide the following HTTP features : GET, POST, PATCH/PUT, DELETE. The actual `todos` will be saved in a `sqlite` database. The client will use `json` to communicate with the server.

A `todo` had the following fields :
* `id` : a unique integer id, that is used to retrieve, delete and patch the todos.
* `title` : a string, that represents the goal of the todo and will be displayed.
* `completed` : a boolean, to remember if the todo has been completed or not.
* `order` : a positive integer, used to display the todos in a certain order.

The http server responds to these requests:
* GET
The request looks like `GET http://localhost:8000/todos/1`. The server, after it receives a "GET" request along with a numeric id, will respond with the corresponding todo in the database, otherwise it will return a 404.
* POST
The request looks like `POST http://localhost:8000/todos`. The content of the request must be `json` that correspond to a `todo`. The `id` field is ignored. e.g. : `{ "title": "Create a todo http server", "order": 1 }`
* PATCH or PUT
The request looks like `PUT http://localhost:8000/todos/1`. The content of the request is the fields to update. ex : `{ "completed": true }`
* Delete
The request looks like `DELETE http://localhost:8000/todos/1`. This will delete the todo with the `id` 1.

#### The Big Picture

![the big picture](./doc/images/global_http.png)

The centre of gravity revolves around the `http` `agent`. It receives requests from users and dispatches them to four other `subgraphs`, one `subgraph` for each HTTP feature. Each `subgraph` processes the request and provide a response. Before we approach the HTTP feature `subgraphs` let's take a look at the `http` `agent`.

##### The HTTP Agent

The implementation code can be found [here](https://github.com/fractalide/fractal_net_http/tree/master/nodes/http).

![The `http agent`](./doc/images/request_response.png)

The `http agent` has one [array output port](https://github.com/fractalide/fractal_net_http/blob/master/nodes/http/lib.rs#L57-L65) for each [HTTP method](https://docs.rs/tiny_http/0.5.5/tiny_http/enum.Method.html), and the `elements` of each array output ports is actually a fast [rust regex](https://doc.rust-lang.org/regex/regex/index.html).

For example, `http() GET[^/news/?$]` will match the request with method GET and url `http://.../news` or `http://../news/`.

A `Msg` is sent on the output port of `http` with the schema [net_http_request](https://github.com/fractalide/fractal_net_http/blob/master/edges/net/http/request/default.nix). We will just use the fields `id`, `url`, `content`. The `id` is the unique id for the request. It must be provided in the response corresponding to this request. The `url` is the url given by the user. The `content` is the content of the request, or the data given by the user.

The `http` `agent` expects a `Msg` with the schema [net_http_response](https://github.com/fractalide/fractal_net_http/blob/master/edges/net/http/response/default.nix). A `response` has an `id`, which corresponds to the `request id`. It also has a `status_code`, which is the response code of the request. By default, it's 200 (OK). The `content` is the data that is sent back to the user.

The `http` `agent` must be started with an `iMsg` of type [net_http_address](https://github.com/fractalide/fractal_net_http/blob/master/edges/net/http/address/default.nix). It specifies the address and port on which the server listens:

![http listen](./doc/images/connect.png)

##### The GET Subgraph

![get](./doc/images/get.png)

``` nix
{ subgraph, nodes, edges }:

subgraph {
  src = ./.;
  flowscript = with nodes; with edges; ''
    db_path => db_path get_sql()
    input => input id(${todo_get_id}) id -> get get_sql(${sqlite_local_get})
    get_sql() id -> id todo_build_json(${todo_build_json})
    get_sql() response -> todo todo_build_json()
    id() req_id -> id todo_add_req_id(${todo_add_req_id})
    todo_build_json() json -> playload build_resp(${todo_build_response})
    get_sql() error -> error build_resp()
    build_resp() response -> response todo_add_req_id() response => response
   '';
}
```
[source for the get implemenation](https://github.com/fractalide/fractal_app_todo/blob/master/nodes/todo/get/default.nix)

A request follows this path:
* Enters the `subgraph` via the virtual port `request`
* Then enters the `agent` `get_id`. This `agent` has two output ports : `req_id` and `id`. The `req_id` is the id of the http request, given by the `http` `agent`. The `id` is `todo id` retrieved from the url (ie: given the url http://.../todos/2, the number 2 will be sent over the `id` port).
* The url `id` enters the `sql_get` `agent`, that retrieve a `Msg` from a database corresponding to the `id`.
* If the `id` exists, a `Msg` is send to `build_json` that contains the json of the todo.
* If the `id` doesn't exist in the database, a `Msg` is send on the error port.
* The `build_request` will receive `Msg` on one of its two input ports (`error` or `playload`). If there is an error, it will send a `404` response, or otherwise, it will send a `200` repsonse with the json as data.
* This new response now goes into the `add_req_id` `agent`, which retrieves the `req_id` from the request, and sets it in the new `response`.
* The response now leaves the `subgraph`.

Now we can connect the `http` `agent` to the `get` `subgraph`, to retrieve all the `GET` http request.

![http_get](./doc/images/http_get.png)

    http() GET[^/todos/.+$] -> request get()
    get() response -> response http()

Please understand how the code maps to the above diagram, as these particular diagrams shall not be repeated.


##### The POST Subgraph

![post](./doc/images/post.png)

``` nix
{ subgraph, nodes, edges }:

subgraph {
  src = ./.;
  flowscript = with nodes; with edges; ''
    db_path => db_path insert_todo()
    input => input todo_get_todo(${todo_get_todo}) todo -> input cl_todo(${msg_clone})
    cl_todo() clone[0] -> insert insert_todo(${sqlite_local_insert})
    cl_todo() clone[1] -> todo todo_build_json(${todo_build_json})
    insert_todo() response -> id todo_build_json()
    todo_get_todo() req_id -> id todo_add_req_id(${todo_add_req_id})
    todo_build_json() json -> playload todo_build_response(${todo_build_response})
    todo_build_response() response -> response todo_add_req_id() response => response
   '';
}
```

[source for the post implementation](https://github.com/fractalide/fractal_app_todo/blob/master/nodes/todo/post/default.nix)


A request will follow this path :
* Enters the `subgraph` by the virtual port `request`
* Enters the `agent``get_todo`. `get_todo` sends `req_id` and the content, which is converted from `json` into a new schema [app_todo](https://github.com/fractalide/fractal_app_todo/blob/master/edges/app/todo/default.nix).
* The `todo` schema is then cloned and sent to two `agents`.
* One clone goes to `sql_insert`, which sends out the url `id` of the todo found in the database. This id is send in `build_json`.
* The `build_json` receives the database id and the todo, and merges them together in `json` format.
* This approach allows the building of a response with json as the content.
* `add_req_id` then add the `req_id` in the reponse
* The response is sent out

The post `subgraph` is then connected to the `http` output port :

    http() POST[/todos/?$] -> request post()
    post() response -> response http()

##### The DELETE Subgraph

![delete](./doc/images/delete.png)

``` nix
{ subgraph, nodes, edges }:

subgraph {
  src = ./.;
  flowscript = with nodes; with edges; ''
    input => input id(${todo_get_id})
    db_path => db_path delete_sql()
    id() id -> delete delete_sql(${sqlite_local_delete})
    delete_sql() response -> playload build_resp(${todo_build_response})
    id() req_id -> id todo_add_req_id(${todo_add_req_id})
    build_resp() response -> response todo_add_req_id() response => response
   '';
}
```
[source for the delete implementation](https://github.com/fractalide/fractal_app_todo/blob/master/nodes/todo/delete/default.nix),

This `subgraph` is easier than the two before, hence nearly self-explainatory.

* The `req_id` and the `id` are obtained in `get_id`.
* The `id` is send to `sql_delete`, which returns the `id` to `build_response`.
* `build_response` simply fill the http response with the `id`
* `add_req_id` add the http `id`

The delete `subgraph` is connect to the `http` output port :

    http() DELETE[/todos/.+] -> request delete()
    delete() response -> response http()


##### The PATCH Subgraph

![path](./doc/images/patch.png)

The patch `subgraph` is a little more complicated, because of the `synch` `agent`. Let first see what happend without it :

![patch_without_sync](./doc/images/patch_without_sync.png)

The idea of the stream is this:
* Get the new "todos" values in the request
* In parallel, retrieve the old value of the todo from the database.
* Then, send the old and the new values to a `merge` `agent`, which builds the resulting `todo`

Now this graph has a problem; if there the todo is new then an old todo cannot be found in the database. In this case, the `new` edge between `get_todo` and `merge` and the `error` edge between `sql_get` and `build_respone` are completely concurrent, thus an issue will arise if a `Msg` is sent over the `error` edge when `sql_get` cannot find a `todo` in the database. At the same time `get_todo` will have recognized that it's a new `todo` and will have sent a `Msg` over the `new` edge. This will insert 2 `Msgs` into the `old` input port, where the first `Msg` is incorrect.
A solution is to add a `synch` `agent` which has outgoing edges `old`/`new` and `error`. If an error is received, it's immediately communicated to `build_respone` and discards the `old/new` `Msg`. If it receives a `new` `Msg`, it forwards the `new` and `old` `Msgs` to `merge`. This ensures all `Msgs` are well taken care of.

To simplify the graph a little, we've not mentioned the edge from `synch` to `patch_sql`. A `Msg` is send from the former with the todo `id`, whichs need to be updated. But all the logic, with synch, is exactly the same. The complete figure is:

![patch_final](./doc/images/patch_final.png)

``` nix
{ subgraph, nodes, edges }:

subgraph {
  src = ./.;
  flowscript = with nodes; with edges; ''
    input => input todo_get_todo(${todo_get_todo})
    db_path => db_path patch_sql()
    todo_get_todo() id -> get get_sql(${sqlite_local_get})
    synch(${todo_patch_synch})
    get_sql() response -> todo synch() todo -> old merge(${todo_patch_json})
    todo_get_todo() raw_todo -> raw_todo synch() raw_todo -> new merge()
    get_sql() id -> id synch() id -> id patch_sql(${sqlite_local_patch})
    merge() todo -> msg patch_sql()
    patch_sql() response -> playload build_resp(${todo_build_response})
    get_sql() error -> error synch() error -> error build_resp()
    todo_get_todo() req_id -> id todo_add_req_id(${todo_add_req_id})
    build_resp() response -> response todo_add_req_id() response => response
   '';
}
```

[source for the patch implementation](https://github.com/fractalide/fractal_app_todo/blob/master/nodes/todo/patch/default.nix)

#### Executing the graph

`$ nix-build --argstr node workbench_test`
`$ ./result`

Now's the time to test the graph. Please follow these steps:

* Open `firefox`:
* Install and open the `resteasy` firefox plugin
* Post : `http://localhost:8000/todos/`
* Open `"data"`
* Select `"custom"`
* Keep `Mime type` empty
* Put `{ "title": "A new title" }` in the textbox.
* Click `send`
* Notice the `200` response.

You can also fiddle with

* `GET http://localhost:8000/todos/ID`
* `DELETE http://localhost:8000/todos/ID`
* `PUT http://localhost:8000/todos/ID`

#### Install into your environement via Configuration.nix

Insert this into your `Configuration.nix`

``` nix
{ config, pkgs, ... }:

let
  fractalide = import /path/to/your/cloned/fractalide {};
in
{
  require = fractalide.services;
  services.workbench = {
    enable = true;
    bindAddress = "127.0.0.1";
    port = 8003;
  };
...
}

```
`$ sudo nixos-rebuild switch -I fractalide=/path/to/your/cloned/fractalide`

## Tokio-*

We're waiting patiently for the much anticipated https://github.com/tokio-rs/ code to land. That's when we'll get services talking to other services and http clients via tokio.

## Extension

Further reading in depth topics are:

* [The Rust Book](https://doc.rust-lang.org/stable/book/)
* [The Flow-Based Programming Book](https://www.amazon.com/Flow-Based-Programming-2nd-Application-Development/dp/1451542321)
* [The Nix Manual](http://nixos.org/nix/manual/)
* [The NixOS Manual](http://nixos.org/nixos/manual/)
* [The Hydra Manual](http://nixos.org/hydra/manual/)
* [The Nixops Manual](http://nixos.org/nixops/manual/)
* [The Cap'n Proto Schema Language](https://capnproto.org/language.html)

## Summary
