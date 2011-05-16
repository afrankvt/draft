//
// Copyright (c) 2011, Andy Frank
// Licensed under the MIT License
//
// History:
//   14 May 2011  Andy Frank  Creation
//

using web

**
** DraftErr is thrown while servicing a request from DraftMod.
**
const class DraftErr : Err
{
  ** Constructor.
  new make(Int errCode, Err? cause := null)
    : super("$errCode " + WebRes.statusMsg[errCode], cause)
  {
    this.errCode = errCode
  }

  ** HTTP error code for this error.
  const Int errCode
}
