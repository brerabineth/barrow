# barrow checks

the catalog behind `barrow rules`. severities run low, med, high, crit;
the verdict bands are clean, watch, suspicious, hostile; exit codes are
0, 1, 3, 10.

## what barrow reads

a `.git` directory (given directly, as `repo/.git`, or through a work-tree
`.git` file), plus the work-tree's `.gitattributes` and `.gitmodules` when
present. loose objects are decompressed and parsed. packed history is
counted but not unpacked — the scan says so instead of pretending.

## the checks

### execution at clone / pull / checkout time

| id  | severity default | check |
|-----|------------------|-------|
| G01 | high, crit with shell-download shape | executable hooks that run without you: post-checkout, post-merge, post-rewrite, post-index-change, reference-transaction, pre-auto-gc |
| G02 | low  | any other executable hook (runs when you act) |
| G03 | med  | `core.hooksPath` pointing somewhere else |
| G04 | high, crit on shell-download | `.gitattributes` `filter=` whose smudge/clean command lives in this repo's config — code that runs the moment the clone materializes. `lfs` with a `git-lfs` command is the known-good shape |
| G05 | med  | custom merge / diff drivers that execute commands |

### configuration as an attack surface

| id  | severity default | check |
|-----|------------------|-------|
| G08 | high, crit on verbs | `core.fsmonitor` set to a command — runs on filesystem events |
| G09 | med  | `core.pager` with pipes or command substitution |
| G10 | high | credential helpers that are shell snippets or scripts |
| G11 | med, high on verbs | `alias.*` values starting with `!` |
| G12 | low / high / crit | remote urls: plain http, embedded credentials, proxy-command tunneling |
| G13 | med  | `core.sshCommand` carrying options |
| G14 | med  | `include.path` / `includeIf` pulling configs from outside |
| G15 | low  | `safe.directory = *` |

### repository internals

| id  | severity default | check |
|-----|------------------|-------|
| G06 | med / high | `.gitmodules` urls: plain http, embedded credentials, relative walks |
| G07 | med  | submodule names that walk directories |
| G16 | low / high | detached HEAD or HEAD pointing through `..` |
| G17 | med  | odd ref names, on disk or in packed-refs |
| G18 | low  | FETCH_HEAD / MERGE_HEAD / ORIG_HEAD carrying fetched state |
| G19 | high, crit over http | `objects/info/alternates` — your object store silently merges from somewhere else |
| G20 | med  | corrupt or unreadable loose objects |
| G21 | med / high / crit | sensitive file names in history: `.env`, keys, `.npmrc`, `.netrc`, authorized_keys, keystores |
| G22 | high | secrets in small blobs: aws keys, tokens, private key blocks |
| G24 | low  | shallow clone |
| G25 | low  | linked worktrees |

## notes

- benign autostarts and known-good shapes are counted, not reported, so a
  clean repo really reads clean.
- `--min-severity` filters the display only; the verdict is always computed
  from everything found.
- malformed input is a finding, not a crash: the fuzzer runs mutated
  repositories through the scanner and expects a verdict, never a stack.
