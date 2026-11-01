# barrow

the barrow holds what the dead were buried with.

a git repository is not just code. it is a machine-readable archive of
everything a project has ever been: hooks that fire when you clone,
filters that rewrite files as they land, submodule sources, credential
helpers, config includes. the 2026 supply-chain wave proved the point —
tens of thousands of repos poisoned, maintainers' accounts turned into
distribution channels, clones executing payloads before anyone reads a
file.

barrow reads the grave goods before you touch the body. offline autopsy of
git repositories: the `.git` directory treated as an attack surface. no
clone needed, no execution, nothing leaves the machine.

## why

secret scanners answer "does this repo contain keys". they stay silent
about `post-checkout` hooks that curl a payload the moment you switch
branches, about `.gitattributes` filters that rewrite files during the
clone itself, about `core.fsmonitor` commands, about alternate object
stores merging someone else's history into yours. barrow answers the
other question: what will this repository do to me if i use it.

## what it reads

- a bare gitdir (`repo.git`), a work tree (finds `.git` itself), or a
  linked work tree through its `.git` pointer file
- loose objects: commits, trees, blobs — decompressed and inspected
- config, hooks, `.gitattributes`, `.gitmodules`, refs, alternates,
  fetch state, shallow markers

packed history is counted and named, not unpacked: the scan says exactly
how far it looked.

## the checks

twenty-five checks across four families. the short version:

- **execution at clone time** — autorun hooks, redirected hook paths,
  external filters and merge drivers with their smudge/clean commands
- **configuration** — fsmonitor commands, shell aliases, credential
  helpers, remote urls with embedded credentials or proxy tunnels,
  config includes, ssh command options
- **repository internals** — submodule urls, odd refs, fetch state,
  alternate object sources, corrupt objects
- **history** — sensitive file names (`.env`, keys, keystores) and
  secret patterns in blobs, found without checking anything out

the full catalog with severities lives in [share/rules.md](share/rules.md).

## usage

    barrow scan <path>...       autopsy repos and gitdirs
    barrow tree <path>          inventory history from loose objects
    barrow hooks <path>         print every hook the repo ships
    barrow forge <dir>          generate clean/dirty example repos
    barrow selftest             26 built-in assertions
    barrow rules                list the checks

flags: `--json`, `--no-color` (NO_COLOR honored), `--quiet`,
`--min-severity`, `--max-blob`.

exit codes a pipeline can gate on: 0 clean, 1 watch, 3 suspicious, 10
hostile, 2 error.

## try it in one line

    barrow forge /tmp/ev && barrow scan /tmp/ev/dirty/site

the forge writes two synthetic repositories — one clean, one planted with
the classics: a post-checkout hook that curls a payload, a smudge filter
that runs at clone time, fsmonitor pointing at a script, credential
helper as a shell snippet, an alternate object store, an aws key that
survived in history, and a `.env` nobody remembered committing. the clean
repo stays quiet, so you can see what silence looks like.

committed examples live under `examples/`; `forge` regenerates them
deterministically.

## requires

any erlang/otp install with `escript` and the `crypto` app (every stock
build has both). one file. zero dependencies. no build step.

    escript barrow selftest

## layout

    barrow               the whole tool: reader, rules, forge, selftest
    test/run.escript     test runner: selftest plus end-to-end through the cli
    share/rules.md       the check catalog, with severities and reasoning
    examples/            forged clean and dirty repositories (inert)
    NOTICE.md            scope and provenance notes

## notes

- malformed input is a finding, not a crash: truncated objects, corrupted
  cells and random bytes are reported and survived. the fuzzer feeds
  mutated repositories to the scanner and expects a verdict, never a
  stack trace.
- secret detection is deliberately shallow and pattern-based. it is a
  first-hour tripwire, not a gitleaks replacement — use both.
- nothing is executed, ever. evidence in, verdict out.

mit license.
