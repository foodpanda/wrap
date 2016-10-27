## Wrap command in tmux

Runs _command_ in detached `tmux` _session_, while capturing output to _logfile_.
This run is considered network/human safe, eg. it could be be cancelled via `Ctrl-c`.

Repeated execution of same `wrap` command, would attach you the `tmux` session (detach `C-b d`).

#### Usage

```
$ wrap <command> [<session>] [<logfile>]
```

If log filelame is not provided, it would be created automatically, using _command_ hash, eg. `wrap.$(echo -n ${command} | openssl sha1).log` to avoid time dependency.

