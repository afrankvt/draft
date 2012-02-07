//
// Copyright (c) 2011, Andy Frank
// Licensed under the MIT License
//
// History:
//   7 Jun 2011  Andy Frank  Creation
//

using concurrent
using util
using web
using wisp


**
** Main entry-point for Draft CLI tools.
**
class Main
{
  ** True for production mode.
  Bool prod := false

  ** HTTP port to run Wisp on.
  Int port := 8080

  ** Props file to pass to `DraftMod.props`.
  File? props := null

  ** Entry-point.
  Int main()
  {
    // check args
    args := Env.cur.args
    if (checkArgs(args) != 0) return -1

    // find and verify webmod
    pod  := Pod.find(args.last, false)
    type := pod==null ? Type.find(args.last, false) : pod.types.find |t| { t.fits(DraftMod#) }
    if (type == null) return err("$args.first not found")
    if (!type.fits(DraftMod#)) return err("$type does not extend DraftMod")

    // check for production mode
    if (prod)
    {
      setupDraftEnv
      runServices([WispService
      {
        it.port = this.port
        it.root = type.make
      }])
      return 0
    }

    // start restarter actor
    pool := ActorPool()
    restarter := DevRestarter(pool)
    {
      it.type  = type
      it.port  = this.port + 1
      it.props = this.props
    }

    // start proxy server
    mod := DevMod(restarter)
    runServices([WispService { it.port=this.port; it.root=mod }])
    return 0
  }

  ** Setup DraftEnv.
  private Void setupDraftEnv()
  {
    Actor.locals["draft.env"] = DraftEnv
    {
      if (this.props != null)
      {
        it.props = this.props.readProps
        log.info("props file read ($this.props.osPath)")
      }
    }
  }

  ** Check arguments.
  private Int checkArgs(Str[] args)
  {
    if (args.size < 1) return help
    for (i:=0; i<args.size-1; i++)
    {
      arg := args[i]
      switch (arg)
      {
        case "-prod":
          this.prod = true

        case "-port":
          p := args[i+1].toInt(10, false)
          if (p == null || p < 0) return err("Invalid port ${args[i+1]}")
          this.port = p

        case "-props":
          p := args[i+1]
          f := File.os(p)
          if (!f.exists) f = p.toUri.toFile
          if (!f.exists) return err("File not found $p")
          this.props = f
      }
    }
    return 0
  }

  ** Run services.
  private Void runServices(Service[] services)
  {
    Env.cur.addShutdownHook |->| { shutdownServices }
    services.each |Service s| { s.install }
    services.each |Service s| { s.start }
    Actor.sleep(Duration.maxVal)
  }

  ** Cleanup services on exit.
  private static Void shutdownServices()
  {
    Service.list.each |Service s| { s.stop }
    Service.list.each |Service s| { s.uninstall }
  }

  ** Print usage.
  private Int help()
  {
    echo("usage: fan draft [options] <pod | pod::Type>
            -prod          run in production mode
            -port  <port>  port to run HTTP server on (defaults to 8080)
            -props <file>  pass in props file for DraftMod.props")
    return -1
  }

  ** Print error message.
  private Int err(Str msg)
  {
    echo("ERR: $msg")
    return -1
  }

  ** Log file.
  private const Log log := Log.get("draft")
}
