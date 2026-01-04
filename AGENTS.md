# AGENTS.md — nix-clawdis

Single source of truth for product direction: `README.md`.

Documentation policy:
- Keep the surface area small.
- Avoid duplicate “pointer‑only” files.
- Update `README.md` first, then adjust references.

Defaults:
- Nix‑first, no sudo.
- Declarative config only.
- Batteries‑included install is the baseline.
- Breaking changes are acceptable pre‑1.0.0 (move fast, keep docs accurate).
- NEVER send any message (iMessage, email, SMS, etc.) without explicit user confirmation:
  - Always show the full message text and ask: “I’m going to send this: <message>. Send? (y/n)”

Philosophy:

The Zen of ~~Python~~ Clawdis, ~~by~~ shamelessly stolen from Tim Peters

Beautiful is better than ugly.  
Explicit is better than implicit.  
Simple is better than complex.  
Complex is better than complicated.  
Flat is better than nested.  
Sparse is better than dense.  
Readability counts.  
Special cases aren't special enough to break the rules.  
Although practicality beats purity.  
Errors should never pass silently.  
Unless explicitly silenced.  
In the face of ambiguity, refuse the temptation to guess.  
There should be one-- and preferably only one --obvious way to do it.  
Although that way may not be obvious at first unless you're Dutch.  
Now is better than never.  
Although never is often better than *right* now.  
If the implementation is hard to explain, it's a bad idea.  
If the implementation is easy to explain, it may be a good idea.  
Namespaces are one honking great idea -- let's do more of those!

Nix file policy:
- No inline file contents in Nix code, ever.
- Always reference explicit file paths (keep docs as real files in the repo).
