---
name: arch-design
description: >
  Write an architectural design as two markdown documents, in order, and open
  them as one pull request. The first names the types, the messages, and the
  handoff from one stage to the next, with no implementation. The second names
  the existing code that changes and how the first document is built. Use when
  the user runs /arch-design or asks for an architectural design in that
  two-document form.
---

# /arch-design

An architectural design is two markdown documents, written in this order. You write both documents.

Neither document contains a class body, broker configuration, or code that runs. That includes a fenced class, function, configuration file, or command.

## Subject

The user names the system and the change. If either is missing, ask and do not write yet.

One design on the branch.

Read that repository's instructions and the code the change touches. Use names that already exist there.

## Document 1

Write the interfaces document.

Title it "Interfaces, contracts, and code flow." These sections, in order:

1. **Stages.** The ordered stages. Each stage names what it owns.
2. **Types.** Each type that crosses a stage boundary, and the fields that are the contract. No methods.
3. **Messages.** Each message: name, direction, payload type, sender, receiver. When nothing is sent between two stages, say the handoff is direct and name the type. Do not add a message or a broker the flow does not have.
4. **Handoffs.** Each step from one stage to the next: what moves, which type or message carries it, and the condition that advances the work.

## Document 2

Write the implementation document only after document 1 is finished. Use document 1's names. Do not add a stage, type, or message that document 1 does not have.

Title it "Implementation." These sections, in order:

1. **Existing code.** Each existing file or symbol that changes: the path, what it does now, and what changes. A type or message that does not exist yet names the existing module it will sit beside, and the new path. No body.
2. **How document 1 is built.** Walk document 1 in stage order. For each type, message, and handoff, name the code from the section above that realizes it, and what is true when that step is done.

## Paths

Put both files in the directory that repository uses for a design. When it names none:

```text
docs/design/<slug>/01-interfaces.md
docs/design/<slug>/02-implementation.md
```

`<slug>` is a short name of this design. `01-interfaces.md` is document 1. `02-implementation.md` is document 2.

## Pull request

One pull request on the repository the design changes. It carries the two documents, and an index entry when that repository indexes designs. It does not change product code.

Branch from that repository's integration branch. Follow its instructions for the account, whether the pull request starts as a draft, and which checks to run. When those instructions do not say draft or ready, open a draft.

The body lists the two files in order and says the code that builds the design is a later pull request.

Follow `/pr-follow-through` for this pull request.

## Before the pull request

Re-read both files against the rules above. Fix the file that breaks one. Then open the pull request.
