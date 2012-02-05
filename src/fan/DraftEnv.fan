//
// Copyright (c) 2012, Andy Frank
// Licensed under the MIT License
//
// History:
//   5 Feb 2012  Andy Frank  Creation
//

using concurrent
using web

**
** DraftEnv
**
internal const class DraftEnv
{
  ** Get singleton instance.
  static DraftEnv cur() { Actor.locals["draft.env"] }

  ** Internal ctor.
  internal new make(|This| f) { f(this) }

  ** General purpose props map.  If a 'pubDir' value exists in
  ** this map, it will be used to configure `pubDir` field.
  const Str:Str props := [:]
}
