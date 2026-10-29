# School access

Use **School access** in the sidebar or the onboarding staff shortcut.

1. **Admin:** set up the school once with an Admin PIN. Add classes and subjects,
   add teachers with personal PINs, then assign each teacher a class and subject.
   The setup shortcuts show this order. Class-teacher registration rights remain
   an optional permission assigned by the Admin.
2. **Teacher:** choose your name and enter your personal PIN once. Open the
   requested tool directly. There is no second, shared Teachers PIN prompt.
   Tools, including School cloud, require a signed-in teacher.
3. **Student:** choose your name and enter your learner PIN if one is set.
   Returning to the currently selected learner also checks their PIN.

Staff sessions survive ordinary navigation and end on explicit student handover,
session expiry (60 minutes), or app restart. **Return to student** clears both
staff sessions and the legacy unlock state before opening the learner picker.
Switching the learner still clears the previous learner's tutor context.

Existing school records, individual PINs, assignments and learner profiles are
preserved. Old shared-PIN settings are retained for compatibility but are no
longer part of teacher sign-in. School content policy is enabled by Admin setup,
received school records or teacher profiles, independently of that old PIN.

The router refreshes when staff sessions change, so protected teacher pages
return to sign-in on expiry/sign-out. A teacher sign-in retains the original
requested tool and accepts only local teacher destinations.

Regression checks cover personal sign-in despite an existing shared PIN, wrong
PIN rejection, protected subroutes, safe destinations, role-derived notes access,
student handover, current-student PIN checks, and phone-sized layout.

Validation: the full Flutter suite passes (911 tests). The new role screen was
rendered at desktop size and checked at phone size. Live Windows UI automation
was unavailable because its Node runtime could not start; role interactions
were verified through widget tests instead.

For the full operational walkthrough, see [Admin, Teacher and Student guide](ROLES_AND_CONNECTION_GUIDE.md). My notes now keeps a permanent Sync class notes toolbar button for first joins and later syncs.
