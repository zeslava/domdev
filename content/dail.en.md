+++
title = "dail: running services in freebsd jails, docker-style"
date = 2026-10-29
description = "How I run services on FreeBSD in isolated jails with dail, a small tool of my own"

[taxonomies]
tags = ["dail", "jail", "freebsd"]
+++

I'm new to FreeBSD. Most of my experience is with Linux, but at some point the FreeBSD philosophy caught my eye:
stability, a coherent system, and the fact that many things were done there long ago — well before Linux. Jails, for example — they've been around since 2000.
So I decided to build my home server on FreeBSD.

The first question was: how do I run services in isolation? On Linux there's Docker — describe it and run it.
I wanted the same here: keep the host clean and skip the hassle.

## Why build my own

FreeBSD already has jails — isolation built right into the system. What was missing was a convenient way to use them.

I looked at the existing tools, but none of them clicked. Bastille looked decent, but like most of the others it's a set of scripts around jails.
I like the idea of a static binary: download it and run it.

And of course I wanted to build my own (what's life without reinventing the wheel).

That's how **dail** — daily jail management ([github](https://github.com/zeslava/dail)) came about.

## Sensible defaults

I carried over what I liked about Docker, with a focus on having to specify almost nothing.
If something can be reasonably guessed, dail guesses it.

For example, here's the entire file for zid, my home OIDC server:

```dockerfile
FROM 15.0-RELEASE

SERVICE zid

EXPOSE 5555

COPY target/release/zid /usr/local/bin/zid
COPY .env /usr/local/etc/zid/zid.env
```

And to run it:

```shell
doas dail run zid.dail --ip 10.100.0.4 --rebuild
```

What I didn't have to write:
- the jail name — taken from the file name
- the start command — `SERVICE zid` runs `/usr/local/bin/zid` by default
- the user, group, rc.conf — `SERVICE` handles them

An IP is assigned automatically by default, but I keep zid on a fixed one — other services depend on it.

The defaults came from practice. Most of what I run are services, so `SERVICE` was the first directive.
With it I needed to create a user inside the jail — and every time I named it after the service.
So I made that the default.

## How I use it day to day

The usual loop looks like this:

```shell
# edit the code
cargo build --release
doas dail run zid.dail --ip 10.100.0.4 --rebuild
doas dail logs zid
```

Even though the name says daily, I actually don't use dail that often.
I log in, build the service, rebuild the jail with one command — and forget about it. After that it just keeps running:

```
$ dail ls
NAME          STATUS   JID  IP              PORTS                           BASE          TYPE  UPTIME
--------------------------------------------------------------------------------------------------------
valkey        running  2    10.100.0.6/24   6379->6379/tcp                  15.0-RELEASE  thin  44d 4h
pg            running  1    10.100.0.2/24                                   15.0-RELEASE  thin  44d 4h
filest        running  6    10.100.0.5/24   8090->8090/tcp, 8090->8090/udp  15.0-RELEASE  thin  44d 4h
zid-pg        running  7    10.100.0.3/24                                   15.0-RELEASE  thin  44d 4h
cfgy-pg       running  9    10.100.0.7/24                                   15.0-RELEASE  thin  44d 4h
cfgy          running  22   10.100.0.8/24   8080->8080/tcp                  15.0-RELEASE  thin  21d 0h
aurora        running  72   inherit         4000->4000/tcp                  15.1-RELEASE  thin  9d 0h
zid           running  78   10.100.0.4/24   5555->5555/tcp                  15.0-RELEASE  thin  5d 7h
domdev        running  148  10.100.0.12/24  8300->8080/tcp                  15.0-RELEASE  thin  4d 0h
```

Some of these jails haven't been restarted in over 44 days.

I count that as a success. And it shows that same FreeBSD philosophy: set it up, start it, forget it.

## What's running

Currently living in jails:
- **zid** — identity provider (OIDC)
- **cfgy** — configuration management
- **aurora** — home media center
- **filest** — a simple REST file server
- **domdev** — this blog
- **pg**, **zid-pg**, **cfgy-pg** — a separate postgres for each service
- **valkey** — cache for the services

Each service in its own jail, the host stays clean.

## What's still missing

Not everything is perfect:
- **Autostart.** After a server reboot, all jails have to be brought up by hand.
  An autostart mode is planned — it will most likely need some kind of daemon.
- **Networking.** By default a jail gets an IP alias on `lo0`, and dail writes port forwarding rules into PF itself. But outbound access (NAT) and the bridge for VNET are still configured by hand — I'd like dail to handle that too.

## Wrapping up

dail is my way to run services on FreeBSD as easily as with Docker.
One binary, a short `.dail` file and one command to rebuild.

If you've also come to FreeBSD from the world of Linux and Docker — give it a try, feedback is welcome: [github.com/zeslava/dail](https://github.com/zeslava/dail)
