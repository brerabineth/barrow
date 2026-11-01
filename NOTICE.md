# notice

barrow is part of a small suite of single-purpose triage tools. it reads
git repositories and reports. it never executes repository content, never
opens a network connection, and never writes outside the directory you
hand it.

the forged examples under `examples/` are synthetic. any resemblance to
real campaigns is the point: the shapes come from public incident reports —
clone-time filter abuse, autorun hooks, alternate object stores, secrets
that survived in history.

regenerate the examples at any time:

    barrow forge /tmp/ev

the `.git` pointer file inside `examples/dirty/site/` is intentionally not
committed (git refuses to track anything named `.git`); `forge` writes it.
