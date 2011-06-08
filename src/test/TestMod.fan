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
** TestMain.
**
internal class TestMain : AbstractMain
{
  @Opt { help = "HTTP port" }
  Int port := 8080

  override Int run()
  {
    runServices([
      WispService
      {
        it.port = this.port
        it.root = TestMod()
      },
    ])
  }
}

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

