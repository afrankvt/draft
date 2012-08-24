# Open Bugs and Issues

Draft requires Fantom 1.0.62 or higher.

# Draft Mini Web Framework

*This project is functional, but is still under development, is missing
features, and very likely to change. See Disclaimers below.*

The core web pod defines a very useful set of APIs for building web-based
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

- Built-in runner for WebMods (no need to write your own main method)
- Auto restart web server when a pod has been modified (if enabled for
  development)
- Simple setup of a public resource directory
- Route mechanism for web reqs to method handlers
- Simple handling and customization of error messages/responses
- Rails-style Flash one-time message API
- Pre/post service hooks for wrapping request handling
- My intention here was to define what I think the standard Fantom web
  framework might look like, while keeping it as lightweight as possible to
  allow plenty of freedom in building web apps.

## Disclaimer

I started on this project earlier this summer [2011] with intentions to have
it more or less wrapped up by now. That hasn't happened - and not sure when I
will be able to complete it at the quality bar I've set.

So this code represents some of the first steps (such as proving out the
restarter proxy server and route design), but is incomplete, most certainly
contains bugs, and very likely to change as I move forward.

I believe there is a bit of useful code here though, that others might be able
to use it to jump start their own projects, or cherry-pick ideas and code. So
I've decided to put it out in the wild early. All code is released under the
MIT license - so have at it. Or just wait and watch for it to reach some
maturity.

Draft requires Fantom 1.0.62 or later. This has only been tested on OS X. I
might expect to see an issue with process killing and starting on Windows -
Java support in this area doesn't appear to be stellar. See `DevRestarter`
(`Dev.fan`) for details.

## Example

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
[sys::Env#config](http://fantom.org/doc/sys/Env.html#config) for more info):

    // configures `DraftMod.pubDir`
    pubDir=/Users/andy/proj/example/pub/
