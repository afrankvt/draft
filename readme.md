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

Draft requires Fantom 1.0.60 or later. This has only been tested on OS X. I
might expect to see an issue with process killing and starting on Windows -
Java support in this area doesn't appear to be stellar. See `DevRestarter`
(`Dev.fan`) for details.

## Example

    const class MyMod : DraftMod
    {
      ** Constructor.
      new make()
      {
        pubDir = `/Users/andy/proj/example/pub/`.toFile
        router = Router {
          routes = [
            Route("/", "GET", #index),
            Route("/echo/{name}/{age}", "GET", #echo),
          ]
        }
      }

      ** Display index page.
      Void index()
      {
        res.headers["Content-Type"] = "text/plain"
        res.out.printLine("Hi there!")
      }

      ** Echo URL args.
      Void echo(Str:Str args)
      {
        name := args["name"]
        age  := args["age"].toInt
        res.headers["Content-Type"] = "text/plain"
        res.out.printLine("Hi $name, you are $age years old!")
      }
    }

## Running

    $ fan draft myPod::MyMod

## Production

While the `draft::DevMod` greatly improves development efficiency, running a
proxy server in front of your site probably isn't what you want to do in
production :) There is a new utility added to Wisp for Fantom 1.0.60 to run a
WebMod directly. For production sites, this should be used to run your site
most efficiently:

    $ fan wisp myPod::MyMod