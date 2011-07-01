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

  **
  ** Directory to publish as public files under `/pub/` URI:
  **   pubDir := `/foo/bar/`
  **   ~/foo/bar/index.css     =>  `/pub/index.css`
  **   ~/foo/bar/img/logo.png  =>  `/pub/img/logo.png`
  **
  const File? pubDir := null

  ** Invoked prior to serviceing the current request.
  virtual Void onBeforeService(Str:Str args) {}

  ** Invoked after serviceing the current request.
  virtual Void onAfterService(Str:Str args) {}

  ** Service incoming request.
  override Void onService()
  {
    try
    {
      // set mod
      req.mod = this

      // check for pub
      if (req.uri.path.first == "pub" && pubDir != null)
        { onServicePub; return }

      // match req to Route
      match := router.match(req.uri, req.method)
      if (match == null) throw DraftErr(404)

      // allow pre-service
      onBeforeService(match.args)

      // delegate to Route.handler
      h := match.route.handler
      args := h.params.isEmpty ? null : [match.args]
      h.parent.make.trap(h.name, args)

      // allow post-service
      onAfterService(match.args)

      // TODO - force flush here?
      // res.out.flush
    }
    catch (Err err)
    {
      if (err isnot DraftErr) err = DraftErr(500, err)
      onErr(err)
    }
  }

  ** Service a pub request.
  private Void onServicePub()
  {
    file := pubDir + req.uri[1..-1]
    if (!file.exists) throw DraftErr(404)
    FileWeblet(file).onService
  }

//////////////////////////////////////////////////////////////////////////
// Errs
//////////////////////////////////////////////////////////////////////////

  ** Handle an error condition during a request.
  Void onErr(DraftErr err)
  {
    // don't spam logs for favicon
    if (req.uri == `/favicon.ico`) return

    // assemble request info
    buf := StrBuf()
    buf.add("$err.msg - $req.uri\n")
    req.headers.each |v,k| { buf.add("  $k: $v\n") }
    err.traceToStr.splitLines.each |s| { buf.add("  $s\n") }

    // log error
    log.err(buf.toStr.trim)

    // send response
    res.statusCode = err.errCode
    res.headers["Content-Type"] = "text/plain"
    res.out.w(buf).flush
  }

  ** Log for DraftMod.
  private const static Log log := Log.get("draft")
}
