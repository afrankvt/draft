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

    // init pod modified times
    map := Pod:DateTime[:]
    Pod.list.each |p| { map[p] = podFile(p).modified }
    startupModified = map

    // TODO FIXIT: log
  }

  ** Router model.
  const Router router

  ** Service incoming request.
  override Void onService()
  {
    try
    {
      if (podsModified)
      {
        log.info("Signal for restart")
        Env.cur.exit(4)
      }

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
      if (err isnot DraftErr) err = DraftErr(500, err)
      onErr(err)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Errs
//////////////////////////////////////////////////////////////////////////

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

//////////////////////////////////////////////////////////////////////////
// Pods
//////////////////////////////////////////////////////////////////////////

  ** Map of pods to modified times at startup.
  const Pod:DateTime startupModified

  ** Return pod file for this Pod.
  File podFile(Pod pod)
  {
    Env? env := Env.cur
    file := env.workDir + `_doesnotexist_`

    // walk envs looking for pod file
    while (!file.exists && env != null)
    {
      file = env.workDir + `lib/fan/${pod.name}.pod`
      env = env.parent
    }

    // verify exists and return
    if (!file.exists) throw Err("Pod file not found $pod.name")
    return file
  }

  ** Return true if any pods have been modified since startup.
  Bool podsModified()
  {
    true == Pod.list.eachWhile |p|
    {
      if (podFile(p).modified > startupModified[p])
      {
        log.info("$p.name pod has been modified")
        return true
      }
      return null
    }
  }

  ** Log for DraftMod.
  private const static Log log := Log.get("draft")
}
