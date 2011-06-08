//
// Copyright (c) 2011, Andy Frank
// Licensed under the MIT License
//
// History:
//   16 May 2011  Andy Frank  Creation
//

using util
using web
using wisp

**
** TestMod
**
internal const class TestMod : DraftMod
{
  ** Constructor.
  new make()
  {
    router = Router {
      routes = [
        Route("/foo",      "GET", #foo),
        Route("/foo/bar",  "GET", #fooBar),
        Route("/foo/{id}", "GET", #fooId),
      ]
    }
  }

  ** Foo handler
  Void foo() { dump }

  ** FooBar handler
  Void fooBar() { dump }

  ** Foo {id} handler
  Void fooId() { dump }

  Void dump()
  {
    /*
    res.headers["Content-Type"] = "text/plain"
    res.out.w(
      "=== Testing ===
        uri:     $req.uri
        pattern: $match.route.pattern
        method:  $match.route.handler
        args:    $match.args")
    res.out.flush
    */
  }
}

