//
// Copyright (c) 2011, Andy Frank
// Licensed under the MIT License
//
// History:
//   14 May 2011  Andy Frank  Creation
//

using concurrent
using util
using web
using webmod

**
** DraftMod
**
abstract const class DraftMod : WebMod
{
  ** Constructor.
  new make()
  {
    router = Router { routes=[,] }

    // check for pubDir prop
    dir := typeof.pod.config("pubDir")
    if (dir != null) pubDir = dir.toUri.toFile
  }

  ** Router model.
  const Router router

  **
  ** Directory to publish as public files under '/pub/' URI:
  **   pubDir := `/foo/bar/`
  **   /foo/bar/index.css     =>  `/pub/index.css`
  **   /foo/bar/img/logo.png  =>  `/pub/img/logo.png`
  **
  ** The pubDir may also be defined as a [config]`sys::Env#config`
  ** property in 'etc/draft/config.props`
  **
  const File? pubDir := null

  **
  ** Directory to write log files to.  If left null, no logging
  ** will be performed.
  **
  const File? logDir := null

  **
  ** Format of the web log records as a string of names.
  ** See [webmod]`webmod::pod-doc#log`
  **
  const Str logFields := "date time c-ip cs(X-Real-IP) cs-method " +
                         "cs-uri-stem cs-uri-query sc-status time-taken " +
                         "cs(User-Agent) cs(Referer) cs(Cookie)"

  **
  ** Map of URI path names to sub-WebMods. Sub mods are checked
  ** for matching routes before we process our own routes.
  **
  // TODO: not sure how this works yet
  @NoDoc
  const Str:WebMod subMods := Str:WebMod[:]

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

      // check for pod
      if (req.uri.path.first == "pod")
        { onServicePod; return }

      // check for sub mod
      sub := subMods[req.modRel.path.first ?: ""]
      if (sub != null)
      {
        req.mod = sub
        req.modBase = req.modBase + `$req.modRel.path.first/`
        sub.onService
        return
      }

      // match req to Route
      match := router.match(req.modRel, req.method)
      if (match == null) throw DraftErr(404)
      req.stash["draft.route.meta"] = match.meta

      // access session here before response is commited so
      // session cookie has a chance to be added to res header
      dummy := flash

      // allow pre-service
      onBeforeService(match.args)
      if (res.isDone) return

      // delegate to Route.handler
      h := match.route.handler
      args := h.params.isEmpty ? null : [match.args]
      weblet := h.parent == typeof ? this : h.parent.make
      weblet.trap(h.name, args)

      // allow post-service
      onAfterService(match.args)

      // store flash for next req
      req.session["draft.flash"] = flash.res.ro.toImmutable

      // TODO - force flush here?
      // res.out.flush
    }
    catch (Err err)
    {
      // do not spam logs with broken pipe errs
      if (err.msg.contains("java.net.SocketException: Broken pipe")) return

      // wrap in DraftErr and log
      if (err isnot DraftErr) err = DraftErr(500, err)
      logErr(err)
      onErr(err)
    }
    finally
    {
      // log requst
      logMod?.onService
    }
  }

  ** Service a pub request.
  private Void onServicePub()
  {
    file := pubDir + req.uri[1..-1]
    if (!file.exists) throw DraftErr(404)
    FileWeblet(file).onService
  }

  ** Service a pod request.
  private Void onServicePod()
  {
    // must have at least 3 path segments
    path := req.uri.path
    if (path.size < 2) throw DraftErr(404)

    // lookup pod
    pod := Pod.find(path[1], false)
    if (pod == null) throw DraftErr(404)

    // lookup file
    file := pod.file(`/` + req.uri[2..-1].pathOnly, false)
    if (file == null) throw DraftErr(404)
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
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  ** Handle startup tasks.
  override Void onStart()
  {
    if (logDir != null)
    {
      // start LogMod
      logMod := LogMod { dir=logDir; filename="web-{YYYY-MM}.log"; fields=logFields }
      this.logModRef.val = logMod
      logMod.onStart
    }
  }

  private LogMod? logMod() { logModRef.val }
  private const AtomicRef logModRef := AtomicRef(null)

//////////////////////////////////////////////////////////////////////////
// Errs
//////////////////////////////////////////////////////////////////////////

  ** Handle an error condition during a request.
  virtual Void onErr(DraftErr err)
  {
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
      if (!err.errCode.toStr.startsWith("4"))
      {
        out.hr
        // req headers
        out.table
        req.headers.each |v,k| { out.tr.td.w(k).tdEnd.td.w(v).tdEnd.trEnd }
        out.tableEnd
        out.hr
        // stack trace
        out.pre.w(err.traceToStr).preEnd
      }
    out.bodyEnd
    out.htmlEnd
  }

  ** Log error.
  private Void logErr(DraftErr err)
  {
    // don't spam logs for favicon/robots.txt or 404
    if (req.uri == `/favicon.ico`) return
    if (req.uri == `/robots.txt`) return
    if (err.errCode == 404) return

    buf := StrBuf()
    buf.add("$err.msg - $req.uri\n")
    req.headers.each |v,k| { buf.add("  $k: $v\n") }
    err.traceToStr.splitLines.each |s| { buf.add("  $s\n") }
    log.err(buf.toStr.trim)
  }

  ** Log for DraftMod.
  private const static Log log := Log.get("draft")
}
