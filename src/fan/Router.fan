//
// Copyright (c) 2011, Andy Frank
// Licensed under the MIT License
//
// History:
//   14 May 2011  Andy Frank  Creation
//

using web

**************************************************************************
** Router
**************************************************************************

**
** Router handles routing URIs to method handlers.
**
const class Router
{
  ** Constructor.
  new make(|This| f) { f(this) }

  ** Route configuration.
  const Route[] routes

  ** Match a request arguments to first Route in 'routes'.  If no matches
  ** are found, returns 'null'.
  RouteMatch? match(Uri uri, Str method)
  {
    for (i:=0; i<routes.size; i++)
    {
      r := routes[i]
      m := r.match(uri, method)
      if (m != null) return RouteMatch(r, m)
    }
    return null
  }
}

**************************************************************************
** Route
**************************************************************************

**
** Route models how a URI pattern gets routed to a method handler.
** Example patterns:
**
**   Pattern         Uri           Args
**   --------------  ------------  ----------
**   "/"             `/`           [:]
**   "/foo/{bar}"    `/foo/12`     ["bar":"12"]
**   "/foo/*"        `/foo/x/y/z`  [:]
**   "/foo/{bar}/*"  `/foo/x/y/z`  ["bar":"x"]
**
const class Route
{
  ** Constructor.
  new make(Str pattern, Str method, Method handler)
  {
    this.pattern = pattern
    this.method  = method
    this.handler = handler

    try
    {
      this.tokens = pattern == "/"
        ? RouteToken#.emptyList
        : pattern[1..-1].split('/').map |v| { RouteToken(v) }

      varIndex := tokens.findIndex |t| { t.type == RouteToken.vararg }
      if (varIndex != null && varIndex != tokens.size-1) throw Err()

    }
    catch (Err err) throw ArgErr("Invalid pattern $pattern.toCode", err)
  }

  ** URI pattern for this route.
  const Str pattern

// TODO FIXIT: confusing b/w HTTP method and Method Handler
  ** HTTP method used for this route.
  const Str method

  ** Method handler for this route.  If this method is an instance
  ** method, a new intance of the parent type is created before
  ** invoking the method.
  const Method handler

  ** Match this route against the request arguments.  If route can
  ** be be matched, return the pattern arguments, or return 'null'
  ** for no match.
  [Str:Str]? match(Uri uri, Str method)
  {
    // if methods not equal, no match
    if (method != this.method) return null

    // if size unequal, we know there is no match
    path := uri.path
    if (tokens.last?.type == RouteToken.vararg)
    {
      if (path.size < tokens.size) return null
    }
    else if (tokens.size != path.size) return null

    // iterate tokens looking for matches
    map := Str:Str[:]
    for (i:=0; i<path.size; i++)
    {
      p := path[i]
      t := tokens[i]
      switch (t.type)
      {
        case RouteToken.literal: if (t.val != p) return null
        case RouteToken.arg:     map[t.val] = p
        case RouteToken.vararg:  break
      }
    }

    return map
  }

  ** Parsed tokens.
  private const RouteToken[] tokens
}

**************************************************************************
** RouteToken
**************************************************************************

**
** RouteToken models each path token in a URI pattern.
**
internal const class RouteToken
{
  ** Constructor.
  new make(Str val)
  {
    if (val[0] == '*')
    {
      this.val = val
      this.type = vararg
    }
    else if (val[0] == '{' && val[-1] == '}')
    {
      this.val  = val[1..-2]
      this.type = arg
    }
    else
    {
      this.val  = val
      this.type = literal
    }
  }

  ** Token type.
  const Int type

  ** Token value.
  const Str val

  ** Str value is "$type:$val".
  override Str toStr() { "$type:$val" }

  ** Type id for a literal token.
  static const Int literal := 0

  ** Type id for an argument token.
  static const Int arg := 1

  ** Type id for vararg token.
  static const Int vararg := 2
}

**************************************************************************
** RouteMatch
**************************************************************************

**
** RouteMatch models a matched Route instance.
**
const class RouteMatch
{
  ** Constructor
  new make(Route route, Str:Str args)
  {
    this.route = route
    this.args  = args
  }

  ** Matched route instance.
  const Route route

  ** Arguments for matched Route.
  const Str:Str args
}


