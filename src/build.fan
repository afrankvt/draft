#! /usr/bin/env fan
//
// Copyright (c) 2011, Andy Frank
// Licensed under the MIT License
//
// History:
//   14 May 2011  Andy Frank  Creation
//

using build

**
** Build: draft
**
class Build : BuildPod
{
  new make()
  {
    podName = "draft"
    summary = "Draft Web Framework"
    version = Version("1.6")
    meta = ["vcs.uri" : "https://github.com/afrankvt/draft", "license.name":"MIT"]
    depends = ["sys 1.0", "util 1.0", "concurrent 1.0", "web 1.0", "webmod 1.0", "wisp 1.0"]
    srcDirs = [`fan/`, `test/`]
    docSrc = true
  }
}