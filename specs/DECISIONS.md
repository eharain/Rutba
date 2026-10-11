# Decisions register

Why this file exists. On 2026-10-11 a change rested on "decision 5" of
2026-09-22, recorded as the owner's, and the owner did not recognise it: "i don't
remember setting up any rule, kindly provide transparency and clarity and
traceability otherwise it can become a support nightmare". The record had added a
clause the owner never said. This register is the remedy.

## Rules

1. **Every entry quotes the owner verbatim**, with the date, the time in UTC, and
   the session id it was said in. An answer to a question quotes the question and
   the option chosen, also verbatim.
2. **Anything a session adds is marked `session-proposed`**: an interpretation,
   a default, a mechanism or a clause. It stays marked until the owner confirms it
   in words, and then the entry quotes those words.
3. **Specs and code cite the entry id** (for example `D-2026-10-11-03`). They
   never say "the owner decided" without one.
4. **A superseded entry is not deleted.** It says what replaced it and when.
5. The source of every quote is that session's transcript, stored by session id
   in the owner's local session history for this workspace. Anyone with access
   can check the words there.

Status values: `owner` (the owner's own words), `session-proposed` (awaiting the
owner), `superseded`.

## 2026-10-11, session 140cc7e4 (Infra)

| Id | Decision | The owner's words | Status | Recorded in |
|---|---|---|---|---|
| D-2026-10-11-01 | Restore rutba.pk from the LAN, with the LAN's user permissions | 10:09 UTC: "we need to take latest of the LAN Servers rutba.pk database and restore it on top of Rutba.pk as rutba.io consumer instance . the users permissions from LAN also have to be same on rutba.pk instacne" | owner | done 10:43 UTC; memory tenant-1-cutover |
| D-2026-10-11-02 | Keep the online orders across the restore | Answer to "What should happen to them?" (the 3 online web orders): "if you can secure the order that are on destination that will be helpful. so protect the order from live and apply these over after restore" | owner | done; /root/cutover/carry-20261011.sql |
| D-2026-10-11-03 | Cash on delivery back after the restore | Answer: "Add COD back (Recommended)" | owner | done |
| D-2026-10-11-04 | The LAN stays the till | Answer to the dump/switch question: "unless the live is fully working , which still is not. we cant switch. there are problems in login in back end serves of consumers on rutba.io." | owner | memory tenant-1-cutover |
| D-2026-10-11-05 | User 2 keeps the LAN password | Answer: "Use the LAN password" | owner | done |
| D-2026-10-11-06 | Sign-in to the right console and instance is a stopper | 11:51 UTC: "correct login into correct console and to correct consumer instance is a problem and its a stopper for now and for all since we deployed and need proper solution and full testing" | owner | specs/one-door-sign-in.md |
| D-2026-10-11-07 | One authentication app | Mid-turn message: "two authentication apps are pain in but as well only one should be there to work and to provide for the authentication needs". Answer to "Which sign-in should be the only one?": "auth.rutba.io (Recommended)" | owner | one-door spec, decision 1 |
| D-2026-10-11-08 | The consumer realm's own password page goes, at the release | Answer: "Remove it (Recommended)" | owner | one-door spec, decision 2 |
| D-2026-10-11-09 | Staff without working email still get in | Answer: "kindly set the passwords not every staff will have correct working email as these needs setting up access for staff." Agents may not set or type passwords, so it was met by D-10. An instance admin sets a consumer password in admin.rutba.io (New User, "set a password manually"); that mechanism is session-proposed. | owner, met by D-10 | one-door spec, decision 3 |
| D-2026-10-11-10 | auth.rutba.io makes the consumer sign-in call itself | 12:35 UTC: "to make the consumer login work from auth.rutb.io all it needs to give same api a call as auth.consumers .rutba.io is doing and generate the tokens." Handing over by a one-use code (no tokens in an address) is session-proposed. | owner | one-door spec, section A |
| D-2026-10-11-11 | Management first, then consumer, and a choice of one | Mid-turn message: "in auth.rutba.io it should call management console auth if fails it calls consumers auth . to make it exclusive it can give a little is user a choice to try only one type of login as a fallback". 12:39 UTC: "the default is auth try first then second but choice can be try the first or second only" | owner | one-door spec, section A |
| D-2026-10-11-12 | "Shop" means the storefront; "consumer" means the instance | 12:40 UTC: "not shop consumer. shop login is only from the storefront". 12:41 UTC: "no. shop is where customers shops online customer signs in. consumers is where consumers instances user signs in" | owner | one-door spec, decision 4 |
| D-2026-10-11-13 | Storefront sign-in is left as it is | Answer: "Keep on the shop (Recommended)". 12:42 UTC: "so we leave to shop login as is as that login comes in from sorefront eng rutba.pk shop or somecustomershop.com" | owner | one-door spec, decision 4 |
| D-2026-10-11-14 | Consumer sessions stay signed in across tabs | Answer: "Stay signed in (Recommended)". Two additions are session-proposed. A new sign-in in that browser replaces a live shared session instead of inheriting it, so the next cashier never gets the previous one's session. Management-OIDC sessions stay per tab, because a new tab signs in silently through auth.rutba.io. | owner, plus 2 session-proposed additions | consumer 97e8bd6a (c735a66e, ddbb799b) |
| D-2026-10-11-15 | Take card payments live | Answer: "Wire Stripe live". The keys live in a root-only /root/stripe.secrets placed by the owner (consumer b0ae5c85); that arrangement is session-proposed. | owner | release list |
| D-2026-10-11-16 | Run 1's QA data | TWO ANSWERS. To Infra (session 140cc7e4): "Leave them alone". To the admin tester's own question in its session (local_66e231cf), before Infra's message arrived: "Yes, all three". The tester acted on the second: it suspended and reactivated the QA customer (active again), sent one reset email (to the no-reply mailbox, unused), and set one QA contact message to Read with a note. | owner, conflicting; the actions taken are recorded, and reverting the message to New awaits the owner | test run 2 admin record |
| D-2026-10-11-17 | Fix the console's retired-service reads now | Answer: "Fix now (Recommended)" | owner | being built |
| D-2026-10-11-18 | Testers use existing QA accounts | Answer: "there are many accounts like eharain+qa-admin-1011@gmail.com you can use them or create your own like eharain+qa-console-admin-1011@gmail.com". Agents may not create accounts, so the owner signs them in. | owner | test run 2 records |
| D-2026-10-11-19 | Operators lose the hub's sign-in tile for the shared individual instance (management 9feb3b7, dev only) | Not the owner's words. It rests on the clause of D-2026-09-22-05 marked session-proposed. | session-proposed, awaiting the owner | management 9feb3b7 |
| D-2026-10-11-20 | A personal organisation's first sign-in to the shared individual instance makes the person's row there (production test run 2, case SG-06: every individual Sign customer was refused, because nothing ever made their row) | Not the owner's words. It answers the owner's stopper D-2026-10-11-06. The whole mechanism is the session's: the consumer realm's callback makes the row only in an individual-mode database, only for a profile pinned to a `personal` organisation that resolved it (its own instances claim or the personal branch, never a team's), only when management says `email_verified: true`, and only when no row holds the address or the subject; the row is confirmed, bound, has no password, and holds exactly the role and keys the instance's own individual registration grants, never admin, manager, staff or operator; one audited transaction; one row under concurrent sign-ins. Chosen over management telling the instance at registration through the invite door, because the programme's records name no mechanism (the 2026-09-23 individual re-run asked the owner which shape and has no answer), the invite door speaks a team's ranks and mails an invitation, and C5 keeps `open` from making anybody. | session-proposed, awaiting the owner | consumer 4bbbde40 (code, tests), fb7df261 (docs) |
| D-2026-10-11-21 | A consumer account sets and resets its own password at auth.rutba.io, and no management account is made for it (the consumer reset) | Not the owner's words. It rests on D-2026-10-11-07 (auth.rutba.io is the only sign-in page), D-2026-10-11-10 (consumer staff keep consumer accounts; auth.rutba.io makes the consumer call itself) and D-2026-10-11-11 (management first, then consumer, and a choice of one), and on the owner's report, relayed to the builder by the Infra session (140cc7e4) and not quoted here, that every consumer invite and reset email in production links to the realm's own set-password page (`auth.consumers.rutba.io/login?code=<instance code>&invited=1`), which goes at the release (D-2026-10-11-08). The whole mechanism is the session's: invitation, owner and operator mails carry a code of the instance's own to auth.rutba.io's `/consumer/reset`, which spends it at the core (server to server, the C5 service token with no subject) and signs the person in at the realm with a one-use code; the code lasts a week for an invitation and an hour for a reset, and a code mailed before the release keeps working until it is used; auth.rutba.io's `/forgot` honours the "Sign in with" choice (management only: as today; consumer only: the instance's reset mail; automatic: both) with one answer for every address; round three's reset that makes a management account no longer runs under automatic or consumer only; the realm's old `/login?code=` links forward to `/consumer/reset`; a consumer password set there has at least 8 characters; an address in several instances takes the password in each and chooses at sign-in. | session-proposed, awaiting the owner | being built (consumer and management, dev only); specs/one-door-sign-in.md, "The consumer reset" |

## 2026-09-22, session 4d9ea71e (the one-app-two-modes programme)

| Id | Decision as recorded | The owner's words | What the record added | Status |
|---|---|---|---|---|
| D-2026-09-22-05 | specs/README.md decision 5: "Rutba staff act as operators. A person signed in at the management console may open the individual instance's console as an operator for specific administrative tasks, through the identity bridge, never through a password there." (commit 4913783, 2026-09-22 17:03 +0500) | 2026-09-22 11:51 UTC: "agree with having and individual database instance and management console user to have consumer consoles admin access to perform specific admin task for individuals." | "never through a password there" and "through the identity bridge" are the session's additions. | The owner's words: owner. The additions: session-proposed, awaiting the owner. |

The other decisions in specs/README.md (1 to 4 and 6), and those in the review
records, have not been traced yet. Tracing them is a separate piece of work,
awaiting the owner's go.
