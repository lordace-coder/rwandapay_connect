# PROJECT RULES - RwandaPay Connect Demo Build

## Non-negotiable working method: PHASE BY PHASE ONLY

You must NEVER attempt to build this entire application in one
continuous, uninterrupted pass. You must work through the phases
listed in PHASES.md one at a time, in order, and STOP after each
one for human confirmation before starting the next.

For every phase:

1. Announce which phase you are starting and what it covers,
   in plain language, before writing any code.
2. Build only what that phase covers. Do not start work that
   belongs to a later phase, even if it seems efficient to do
   so while you're "in there."
3. When the phase's code is written, run the app yourself
   (start the dev server, run any relevant tests) and verify
   it actually works - don't just assume it compiles.
4. Report back with:
   - What you built
   - Proof it works (terminal output, a description of what
     you saw when you tested it, and/or a screenshot if you
     are able to take one)
   - Any issues you ran into and how you resolved them
   - Any issues you could NOT resolve - be explicit and
     honest about this rather than papering over it
5. Then STOP. Do not proceed to the next phase. Wait for the
   human to explicitly say something like "approved, go to
   phase [X]" before continuing.

## If a phase cannot be completed

If you hit a blocker you cannot solve, do not skip ahead to
other phases and do not silently leave the phase half-done.
Instead:

- Clearly state what is blocking you
- Explain what you already tried
- Suggest one or two possible next steps
- Wait for human input before touching anything else

## General standards for every phase

- Prioritize working, reliable functionality over visual polish
  or clever extras.
- Do not invent scope that isn't in PHASES.md. If something
  seems missing or ambiguous, ask rather than guessing.
- Do not integrate any real payment processor, real bank API,
  or the real MTN MoMo API. This is a simulated demo - all
  "money" lives inside this app's own database only.
- Keep the demo account details (names, logins, account
  numbers) exactly as specified in PHASES.md. Do not change
  them without being told to.
