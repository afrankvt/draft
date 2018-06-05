//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   4 Jun 2018  Andy Frank  Creation
//

using concurrent
using web
using wisp

**
** DraftSessionStore is an in-memory WispSessionStore with optional support
** for serializing store to disk to maintatin session through reboots.
**
const class DraftSessionStore : Actor, WispSessionStore
{
  ** It-block constructor.
  new make(WispService service, |This|? f := null)
    : super(ActorPool { it.name="WispServiceSessions" })
  {
    this.service = service
    this.log = service->log
    if (f != null) f(this)
  }

  ** Parent WispService instance.
  override const WispService service

  ** Optional directory to persist session stage between restarts, or
  ** do not persist if 'null'.
  const File? storeDir

  ** Duration of sessions to live before they are automatically removed.
  const Duration expires := 24hr

  ** Callback when WispService is started.
  override Void onStart()
  {
    if (storeDir != null) send(SessionMsg("load-store")).get
    sendLater(hkFreq, hkMsg)
  }

  ** Callback when WispService is stopped.
  override Void onStop()
  {
    if (storeDir != null) send(SessionMsg("save-store")).get
    pool.stop
  }

  ** Load the session map for the given id, or create a new one if not found.
  override Str:Obj? load(Str id) { send(SessionMsg("load", id)).get(15sec) }

  ** Save the given session map by session id.
  override Void save(Str id, Str:Obj? data) { send(SessionMsg("save", id, data)) }

  ** Delete any resources used by the given session id.
  override Void delete(Str id) { send(SessionMsg("del", id)) }

  override Obj? receive(Obj? obj)
  {
    try
    {
      m := (SessionMsg)obj

      // init or lookup map of sessions
      smap := Actor.locals["wisp.sessions"] as Str:DraftSession
      if (smap == null) Actor.locals["wisp.sessions"] = smap = Str:DraftSession[:]

      // dispatch msg to handler method
      switch(m.op)
      {
        case "hk":   return _onHouseKeeping(smap)
        case "load": return _onLoad(smap, m.id)
        case "save": return _onSave(smap, m.id, m.data)
        case "del":  return _onDelete(smap, m.id)
        case "load-store": return _onLoadStore(smap)
        case "save-store": return _onSaveStore(smap)
      }

      Env.cur.err.printLine("Unknown op: '$m.op'")
    }
    catch (Err e) e.trace
    return null
  }

  private Obj? _onHouseKeeping(Str:DraftSession smap)
  {
    try
    {
      // clean-up old sessions after expiration period
      now := Duration.nowTicks
      expired := Str[,]
      smap.each |session|
      {
        if (now - session.lastAccess > expires.ticks)
          expired.add(session.id)
      }
      expired.each |id| { smap.remove(id) }
    }
    finally { sendLater(hkFreq, hkMsg) }
    return null
  }

  private Map _onLoad(Str:DraftSession smap, Str id)
  {
    smap[id]?.data ?: emptyData
  }

  private Obj? _onSave(Str:DraftSession smap, Str id, Str:Obj data)
  {
    s := smap[id]
    if (s == null) smap[id] = s = DraftSession(id)
    s.data = data
    s.lastAccess = Duration.nowTicks
    return null
  }

  private Obj? _onDelete(Str:DraftSession smap, Str id)
  {
    smap.remove(id)
    return null
  }

  private Obj? _onLoadStore(Str:DraftSession smap)
  {
    if (!storeDir.exists) return null
    storeDir.listFiles.each |f|
    {
      try
      {
        id   := f.name
        data := f.readObj.toImmutable
        s := DraftSession(id)
        s.data = data
        s.lastAccess = Duration.nowTicks
        smap[id] = s
      }
      catch (Err err) err.trace
    }
    log.info("loaded $smap.size sessions")
    return null
  }

  private Obj? _onSaveStore(Str:DraftSession smap)
  {
    smap.each |session, id|
    {
      try
      {
        f := storeDir + `$id`
        f.out.writeObj(session.data).flush.sync.close
      }
      catch (Err err) err.trace
    }
    log.info("saved $smap.size sessions")
    return null
  }

  private const Log log
  private const SessionMsg hkMsg   := SessionMsg("hk")
  private const Duration hkFreq    := 1min
  private const Str:Obj? emptyData := [:]
}

//////////////////////////////////////////////////////////////////////////
// SessionMsg
//////////////////////////////////////////////////////////////////////////

internal const class SessionMsg
{
  new make(Str o, Str? i := null, Map? d := null) { op=o; id=i; data=d }
  const Str op
  const Str? id
  const Map? data
}

**************************************************************************
** DraftSession
**************************************************************************

internal class DraftSession
{
  new make(Str id) { this.id = id }
  const Str id     // unique session id
  Map? data        // session data
  Int lastAccess   // last access time in ticks
}
