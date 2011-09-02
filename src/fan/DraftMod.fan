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
  ** Directory to publish as public files under '/pub/' URI:
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

      // access session here before response is commited so
      // session cookie has a chance to be added to res header
      dummay := flash

      // allow pre-service
      onBeforeService(match.args)

      // delegate to Route.handler
      h := match.route.handler
      args := h.params.isEmpty ? null : [match.args]
      h.parent.make.trap(h.name, args)

      // allow post-service
      onAfterService(match.args)

      // store flash for next req
      req.session["draft.flash"] = flash.res.ro

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
// Flash
//////////////////////////////////////////////////////////////////////////

  ** Get flash instance for this request.
  Flash flash()
  {
    flash := req.stash["draft.flash"]
    if (flash == null)
    {
      map := req.session["draft.flash"] ?: Str:Str[:]
      req.stash["draft.flash"] = flash = Flash(map)
    }
    return flash
  }

//////////////////////////////////////////////////////////////////////////
// Errs
//////////////////////////////////////////////////////////////////////////

  ** Handle an error condition during a request.
  Void onErr(DraftErr err)
  {
    // don't spam logs for favicon
    if (req.uri == `/favicon.ico`) return

    // log error
    logErr(err)

    // pick best err msg
    msg := err.errCode == 500 && err.cause != null ? err.cause.msg : err.msg

    // setup response if not already commited
    if (!res.isCommitted)
    {
      res.statusCode = err.errCode
      res.headers["Content-Type"] = "text/html; charset=UTF-8"
      res.headers["Draft-Err-Msg"] = msg
    }

    // send HTML response
    out := res.out
    out.docType
    out.html
    out.head
      .title.esc(err.msg).titleEnd
      .style.w("pre,td { font-family:monospace; }
                td:first-child { color:#888; padding-right:1em; }").styleEnd
      .headEnd
    out.body
      // msg
      out.h1.esc(err.msg).h1End
      if (err.msg != msg) out.h2.esc(msg).h2End
      out.hr
      // req headers
      out.table
      req.headers.each |v,k| { out.tr.td.w(k).tdEnd.td.w(v).tdEnd.trEnd }
      out.tableEnd
      out.hr
      // stack trace
      out.pre.w(err.traceToStr).preEnd
    out.bodyEnd
    out.htmlEnd
  }

  ** Log error.
  private Void logErr(DraftErr err)
  {
    buf := StrBuf()
    buf.add("$err.msg - $req.uri\n")
    req.headers.each |v,k| { buf.add("  $k: $v\n") }
    err.traceToStr.splitLines.each |s| { buf.add("  $s\n") }
    log.err(buf.toStr.trim)
  }

  ** Log for DraftMod.
  private const static Log log := Log.get("draft")
}
