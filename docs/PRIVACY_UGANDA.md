# Privacy obligations (Uganda) — for legal review

**This is not legal advice.** It lists the obligations the engineering
team believes apply, so that a qualified Ugandan lawyer or privacy
professional can confirm, correct and complete them before schools'
data goes to any cloud.

## Laws to review

- **Data Protection and Privacy Act, 2019** and the **Data Protection
  and Privacy Regulations, 2021**.
- The **Personal Data Protection Office (PDPO)**, under NITA-U:
  registration of data collectors and processors.
- **The Children Act (Cap. 59, as amended 2016)**: the best interests of
  the child.
- Ministry of Education and Sports guidance on learner records and EMIS.

## What the app collects

| Data | Where | Purpose |
|---|---|---|
| Learner name, optional age, class/stream, subjects | device; school cloud if enabled | teaching, records |
| Progress summaries, quiz results, mastery, achievements | device; teacher device; cloud if enabled | teaching, feedback |
| Assignment answers and grades | device; teacher device; cloud if enabled | assessment |
| "Tutor used" marks (times only) | device; teacher device | assessment context |
| Chat recall (compressed, per session) | device only | resuming a chat |

Not collected: audio (speech is turned into text and the audio is
discarded), chat transcripts, location, contacts, advertising ids. No
data goes to any AI provider: the models run on the device.

## Questions for the reviewer

1. **Lawful basis and consent.** Section 8 of the Act: collecting a
   child's data needs the consent of a parent or guardian (or another
   listed basis). Does the school's enrolment consent cover the app, or
   is separate consent needed, and in what form?
2. **Registration.** Must each school, and the platform operator, register
   with the PDPO as collector/processor?
3. **Cross-border transfer.** Section 19: if the cloud is hosted outside
   Uganda (e.g. Rwanda), which safeguards are required?
4. **Retention.** How long may answers, grades and progress be kept after
   a learner leaves? The app keeps them until a teacher deletes the
   learner (Teachers → learner → Delete, which wipes every row and file
   for them on that device).
5. **Rights of access, correction and deletion.** The app supports
   deletion per device; the cloud must support deleting a learner's
   records on request — who may ask, and how is identity checked?
6. **Breach notification.** Timelines and who notifies whom.
7. **Processor contracts** between the school, the platform operator and
   any cloud host.

## Engineering commitments

- Data minimisation: summaries, not transcripts.
- One database per school in the cloud; no school can read another's.
- No data used for advertising or model training.
- Audit events never contain answers, PINs, codes or tokens.
