# Draft Mini Web Framework

The core Fantom web pod defines a very useful set of APIs for building web-based
apps. In particular the [WebMod API](http://fantom.org/doc/web/pod-doc.html#overview)
provides a simple yet powerful mechanism to compose multiple apps into a
single site.

WebMod is intentionally left as simple as possible in order to not impose any
particular design pattern on the world. However there does happen to be a
small amount of boilerplate code developers end up having to write to get
going.

Draft is intended to notch in right above WebMod. It does just enough to cut
out the boiler plate, plus provide what I believe is most useful for simple to
moderately complicated web apps:

- Auto restart web server when a pod has been modified for rapid development
- Route mechanism for mapping web reqs to method handlers
- Simple handling and customization of error messages/responses
- Rails-style Flash one-time message API
- Pre/post service hooks for wrapping request handling
- Simple setup of a public resource directory
- Optional support for maintaining web sessions through a restart/reboot

## Installing

    fanr install -r http://eggbox.fantomfactory.org/fanr/ draft

API Documentation:

[http://eggbox.fantomfactory.org/pods/draft/api/](http://eggbox.fantomfactory.org/pods/draft/api/)

## Using

    :::fantom
    const class MyMod : DraftMod
    {
      ** Constructor.
      new make()
      {
        pubDir = `/Users/andy/proj/example/pub/`.toFile
        logDir = `/Users/andy/proj/example/log/`.toFile
        router = Router {
          routes = [
            Route("/", "GET", #index),
            Route("/echo/{name}/{age}", "GET", #print),
          ]
        }
      }

      ** Display index page.
      Void index()
      {
        res.headers["Content-Type"] = "text/plain"
        res.out.printLine("Hi there!")
      }

      ** Print URL args.
      Void print(Str:Str args)
      {
        name := args["name"]
        age  := args["age"].toInt
        res.headers["Content-Type"] = "text/plain"
        res.out.printLine("Hi $name, you are $age years old!")
      }
    }

## Running

Simplest way to run Draft is to just pass in the pod containing your
`DraftMod` subclass:

    $ fan draft mypod

When running Draft this way, a proxy server is spun up ahead of your website.
This proxy monitors pod changes and will automatically restart your server
when a pod becomes out of date.  So no need to restart your server during
development.

Type `fan draft` to see list of options:

    $ fan draft
    usage: fan draft [options] <pod | pod::Type>
      -prod          run in production mode
      -port  <port>  port to run HTTP server on (defaults to 8080)

## Production

While the `draft::DevMod` greatly improves development efficiency, running a
proxy server in front of your site probably isn't what you want to do in
production :) To run your DraftMod directly for production environments, use
the `-prod` flag when launching:

    $ fan draft -prod mypod

## etc/draft/config.props

Some parameters can be defined in `etc/draft/config.props` (see
[docLang::Env](http://fantom.org/doc/docLang/Env.html) and
[sys::Env.config](http://fantom.org/doc/sys/Env.html#config) for more info):

    // configures `DraftMod.pubDir`
    pubDir=/Users/andy/proj/example/pub/

## Persistent Web Sessions

The default session store in Wisp will not maintain sessions through a restart
of the Fantom process.  If you wish to persist sessions for things such as
logged in users, configure Wisp to use [DraftSessionStore](http://eggbox.fantomfactory.org/pods/draft/api/DraftSessionStore):

    :::fantom
    wisp := WispService
    {
      ...
      it.sessionStore = DraftSessionStore(it)
      {
        it.expires  = 3hr
        it.storeDir = `/some/dir/`
      }
    }

## Dependancies

Draft requires Fantom 1.0.70 or higher.  For best results always use
the latest Fantom version available.
