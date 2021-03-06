//
// Copyright (c) 2011, Andy Frank
// Licensed under the MIT License
//
// History:
//   14 May 2011  Andy Frank  Creation
//

using web

**
** Test code for Router class.
**
internal class RouterTest : Test
{
  Void testRoutes()
  {
// TODO FIXIT - {index} arguments

    r := Route("/foo/bar", "GET", #foo)
    verifyEq(r.match(`/foo/bar`,  "GET"),  Str:Str[:])
    verifyEq(r.match(`/foo/bar`,  "POST"), null)
    verifyEq(r.match(`/foo/bar`,  "HEAD"), null)
    verifyEq(r.match(`/yo`,       "GET"),  null)
    verifyEq(r.match(`/foo`,      "GET"),  null)
    verifyEq(r.match(`/foo/`,     "GET"),  null)
    verifyEq(r.match(`/foo/ba`,   "GET"),  null)
// TODO: should this match?
//    verifyEq(r.match(`/foo/bar/`, "GET"),  null)

    r = Route("/foo/{arg}", "GET", #foo)
    verifyEq(r.match(`/foo/123`, "GET"), Str:Str["arg":"123"])
    verifyEq(r.match(`/foo/abc`, "GET"), Str:Str["arg":"abc"])
    verifyEq(r.match(`/foo/ax9`, "GET"), Str:Str["arg":"ax9"])
    verifyEq(r.match(`/foo/_4b`, "GET"), Str:Str["arg":"_4b"])

    r = Route("/foo/{a}/bar/{b}/list", "GET", #foo)
    verifyEq(r.match(`/foo/123/bar/abc/list`, "GET"), Str:Str["a":"123", "b":"abc"])
    verifyEq(r.match(`/foo/123/bax/abc/list`, "GET"), null)

    // vararg matches
    r = Route("/foo/*", "GET", #foo)
    verifyEq(r.match(`/foo/x/y/z`, "GET"), Str:Str[:])
    verifyEq(r.match(`/fox/x/y/z`, "GET"), null)

    r = Route("/foo/{bar}/*", "GET", #foo)
    verifyEq(r.match(`/foo/x/y/z`, "GET"), Str:Str["bar":"x"])
    verifyEq(r.match(`/fox/x/y/z`, "GET"), null)

    r = Route("/x/y/z/*", "GET", #foo)
    verifyEq(r.match(`/x`,         "GET"), null)
    verifyEq(r.match(`/x/y`,       "GET"), null)
    verifyEq(r.match(`/x/y/z`,     "GET"), null)
    verifyEq(r.match(`/x/y/z/foo`, "GET"), Str:Str[:])
    verifyEq(r.match(`/x/y/z/foo/a/b/c`, "GET"), Str:Str[:])

    // errs
// should err?
//    verifyErr(ArgErr#) { x := Route("foo",      "GET", #foo) }
    verifyErr(ArgErr#) { x := Route("/foo/*/*", "GET", #foo) }
    verifyErr(ArgErr#) { x := Route("/*/foo",   "GET", #foo) }
// allowed?
//    verifyErr(ArgErr#) { x := Route("/bar/",    "GET", #foo) }
  }

  Void testRouter()
  {
    test := Router {
      routes = [
        Route("/",          "GET", #index),
        Route("/foo",       "GET", #foo),
        Route("/foo/{arg}", "GET", #fooArg),
        Route("/foo/bar",   "GET", #bar),    // literal after {arg} to check Route.sort
      ]
    }

    verifyRouter(test, `/foo`,     #foo,      Str:Str[:])
// TODO FIXIT: this needs to work
// maybe this is illegal - can't end in / - expect for "/"
//    verifyRouter(test, `/foo/`,    #fooIndex, Str:Str[:])
    verifyRouter(test, `/foo/bar`, #bar,      Str:Str[:])
    verifyRouter(test, `/foo/xyz`, #fooArg,   Str:Str["arg":"xyz"])
  }

  private Void verifyRouter(Router r, Uri uri, Method? handler, [Str:Str]? args)
  {
    m := r.match(uri, "GET")
    verifyEq(m?.route?.handler, handler)
    verifyEq(m?.args, args)
  }

  // dummy handlers
  private Void index() {}
  private Void foo() {}
  private Void bar() {}
//  private Void fooIndex() {}
  private Void fooArg() {}
}
