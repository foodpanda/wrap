## Run command smart in tmux - WRAP

[![Build Status](https://travis-ci.org/jaymecd/wrap.svg?branch=master)](https://travis-ci.org/jaymecd/wrap)

WRAP runs _command_ in detached `tmux` _session_, while capturing output to _logfile_.

Timestamps in logs are written in `UTC` timezone.

This execution is considered network/human fail safe, to some degree of course.

### Motivation

During my last vacation at "The middle of nowhere" village, I was struggling to run commands on remote host and keep logs over smartphone tethering.

### Usage

```
$ wrap <command> [<session>] [<logfile>]
```

If log filename is not provided, it would be created automatically.
To guarantee filename on repeated calls, it's generated by SHA1 of _command_, eg. `wrap.3b8ec645afd0203f086445d6a7aeccd98e5659ca.log`.

Repeated execution of same WRAP command, would attach existing `tmux` session, if one is still running.

**Note!** Creating new window or pane within a session may affect standard workflow.

### Demo time

First run, `Ctrl-c` in the middle of execution.

```
$ T=v1.2.3 E=prod; wrap "./deployment.sh --env $E --tag $T --debug" deploy ~/"logs/deploy-${E}-${T}.log"
--> ./deployment.sh --env prod --tag v1.2.3 --debug <--
Ready to wrap this command? [y/N] y
> 2016-10-27 20:19:10 Tailing logs from '/home/jaymecd/logs/deploy-prod-v1.2.3.log' file ...
> 2016-10-27 20:19:10 Running: ./deployment.sh --env prod --tag v1.2.3 --debug
+ ./deployment.sh --env prod --tag v1.2.3 --debug
...
... (content clipped)
...
^C
Log still could be accessible via:
    $ tail -f /home/jaymecd/logs/deploy-prod-v1.2.3.log
    $ less /home/jaymecd/logs/deploy-prod-v1.2.3.log
```

Repeated run (while _command_ is still running), press `C-b d` to detach `tmux` session.

```
$ T=v1.2.3 E=prod; wrap "./deployment.sh --env $E --tag $T --debug" deploy ~/"logs/deploy-${E}-${T}.log"
> press "C-b d" to detach <
[detached (from session deploy)]
+ ./deployment.sh --env prod --tag v1.2.3 --debug
...
... (content clipped)
...

real 2m32.002s
user 0m0.035s
sys  0m0.001s

> 2016-10-27 20:21:42 Finished (exit 0)
^C
Log still could be accessible via:
    $ tail -f /home/jaymecd/logs/deploy-prod-v1.2.3.log
    $ less /home/jaymecd/logs/deploy-prod-v1.2.3.log
```
