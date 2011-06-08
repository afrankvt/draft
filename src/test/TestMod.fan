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
  Void foo() {}

  ** FooBar handler
  Void fooBar() {}

  ** Foo {id} handler
  Void fooId() {}
}

