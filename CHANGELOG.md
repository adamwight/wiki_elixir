# Change log

## 0.3.0-TODO

Distant future, won't attempt in v0.2:
* Detect Wikimedia site matrix.
* Discover APIs (and warn that this should be configured?  cache?), generate matching client.

## 0.2.0-TODO

What it should include:
* Detect server and network errors, fail fast.
* Atoms for selecting the known server-side event streams?
* ...

## 0.1.5a (TBD)

* Test everything.
* Default to `formatversion=2`.
* ...

## 0.1.4 (May 2020)

* Fix application configuration bug, nothing worked out of the box.
* Fix a continuation bug which would drop the first response.
* Removed the incomplete `Wiki.Rest` client.
* Some test coverage for `Wiki.Action`.
* Add lint jobs to git hook and GitLab CI.

## 0.1.3 (May 2020)

* (broken release)

## 0.1.2 (May 2020)

* Rename WikiAction -> `Wiki.Action`
* Rename WikiRest -> `Wiki.Rest`
* Rename WikiSSE -> `Wiki.EventStreams`
* Basic ORES client.
* Inline examples as module documentation.
* Pipe-join list values for Action API.
* Accumulate Action results.

## 0.1.1 (May 2020)

* Send User-Agent header.
* Action API and continuations.  Authentication, session cookies.
* Pipelining.
* Flexible endpoint.
* Server-side events relayed as a `Stream`.
* Simplify and package examples as scripts.
* Begin work on REST API.
* Host code on GitLab, apply the most basic CI.
* Temporarily inline the [cwc/eventsource_ex](https://github.com/cwc/eventsource_ex/)
server-side events library as a workaround.
* Switch to Tesla HTTP client.

## 0.1.0 (May 2019)

* Initial release.
