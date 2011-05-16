//
// Copyright (c) 2011, Andy Frank
// Licensed under the MIT License
//
// History:
//   14 May 2011  Andy Frank  Creation
//

using web

**
** DraftMod
**
abstract const class DraftMod : WebMod
{
  ** Constructor.
  new make()
  {
    router = Router { routes=[,] }
  }

  ** Router model.
  const Router router

  ** Service incoming request.
  override Void onService()
  {
    try
    {
      match := router.match(req.uri, req.method)
      if (match == null) throw DraftErr(404)

      res.headers["Content-Type"] = "text/plain"
      res.out.w(
        "uri:     $req.uri
         pattern: $match.route.pattern
         args:    $match.args")
      res.out.flush
    }
    catch (Err err)
    {
      if (err isnot DraftErr) err = DraftErr(501, err)
      onErr(err)
    }
  }

  ** Handle an error condition during a request.
  Void onErr(DraftErr err)
  {
    buf := StrBuf()
    buf.add("$err.msg - $req.uri\n")
    req.headers.each |v,k| { buf.add("  $k: $v\n") }
    err.traceToStr.splitLines.each |s| { buf.add("  $s\n") }

    // dump to stdout
    echo(buf)

    // send response
    res.statusCode = err.errCode
    res.headers["Content-Type"] = "text/plain"
    res.out.w(buf).flush

  }
}
