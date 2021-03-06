# Changelog

### Version 1.6 (working)

### Version 1.5 (18-Jun-2020)
* Cache matching `RouteMatch` in `WebReq.stash["draft.route"]`

### Version 1.4.1 (7-Mar-2019)
* Fix to not log DraftErr redirects

### Version 1.4 (7-Mar-2019)
* Add DraftErr.makeRedirect to allow redirects using `throw`

### Version 1.3 (21-Aug-2018)
* Update DraftMod to service `subMods` before `pub` and `pod`

### Version 1.2 (26-Jun-2018)
* Fix Router to match literal routes before parameterized routes

### Version 1.1 (4-Jun-2018)
* Simplify version to `<major>.<minor>.<patch>`
* Move from BitBucket -> GitHub
* Fix to suppress socket I/O errs in `DraftMod.onService`
* Add support for maintaining web sessions through reboots

### Version 1.0.6 (20-Feb-2017)
* Fix onServicePod to ignore query string

### Version 1.0.5 (18-Sep-2015)
* Fix to use immutable for session state (http://fantom.org/forum/topic/2428)
* Fix for WispService port -> httpPort

### Version 1.0.4 (25-Sep-2014)
* Do not log 404 errs to stdout
* Fix LogMod to append after request has been processed
* Fix for WebClient gzip change

### Version 1.0.3 (10-Jul-2013)
* Expose LogMod.fields
* Make DraftMod.onErr virtual

### Version 1.0.2 (16-Jan-2013)
* New RouteGroups
* Beef up vararg support
* Allow onBeforeService to complete req before handler runs
* Workaround for Safari not creating session key w/ proxy server
* Nodoc submods for now

### Version 1.0.1 (11-Jan-2013)
* Support for `*` varargs in Route patterns

### Version 1.0
* Initial public version