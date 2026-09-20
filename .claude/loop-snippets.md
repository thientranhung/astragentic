# Loop snippets

Open it, copy an entire block, and paste it into the `thomas` tab.

Interval units: `s` `m` `h` `d` (e.g. `30m`). Hard floor: 60 seconds — `15s` is rounded up to `1m`.
Omit the interval → Claude picks the cadence automatically (if enabled on the account); omit both the interval and the prompt → default `10m`.

---

## Thomas — keep the rhythm, pick up new tickets automatically

```
/loop 12m Thomas: are the agents still active? Make sure monitoring and watching remain healthy. When the tickets run out, proactively pick a new ticket and continue. Only stop when there are no tickets left to pick up AND no pane is running AND nothing is waiting to be merged. If Thomas's context is above 80%, proactively compact it.
```

For a denser cadence, change `30m` → `5m`. Below `5m`, most ticks will not produce meaningful changes but will still consume a full model pass; dead panes are already caught by `herdr-watchdog.sh` at a 300s interval.

In cron mode, Thomas cannot stop by itself — if you want it to stop for real, add this at the end:
"When the stop conditions are met, remove this cron job and send me one line."
