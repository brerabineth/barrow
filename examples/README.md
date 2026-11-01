# examples

forged repositories, byte-deterministic and inert. regenerate with:

    barrow forge DIR

`examples/clean/repo.git` scans clean. `examples/dirty/` plants the
classics: an autorun hook, a clone-time filter, fsmonitor, a credential
helper as a shell snippet, an alternate object store, secrets in history.
the `.git` pointer file in `site/` is written by the forge (git does not
track files named `.git`).
