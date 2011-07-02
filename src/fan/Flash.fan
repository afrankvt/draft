//
// Copyright (c) 2011, Andy Frank
// Licensed under the MIT License
//
// History:
//   1 Jul 2011  Andy Frank  Creation
//

using web

**
** Flash manages short-term messaging between requests.
**
class Flash
{
  ** Values from previous request.
  Str:Str req { private set }

  ** Map used to build flash for the next request.
  Str:Str res := Str:Str[:] { private set }

  ** Internal ctor.
  internal new make(Str:Str req)
  {
    this.req = req.ro
  }
}
