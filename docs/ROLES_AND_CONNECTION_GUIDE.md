# AI Connect Africa: Admin, Teacher and Student guide

Updated 29 October 2026. This guide describes the current Windows hub app and its
simplified School access flow. The latest app is uploaded to the
AFRICA-AI-CONNECT review branch; replacement of that repository's existing main
version is still awaiting approval.

## 1. The simple flow

**Admin sets up the school -> Teacher teaches assigned classes -> Student learns.**

The roles connect through three things:

- School records connect an Admin device to teacher/staff devices.
- Teaching assignments connect a teacher to a class and subject.
- Class sharing connects a teacher device to student devices.

On one shared device, the records are already local. Switch roles instead of
pairing that device with itself.

| Role | What they do | How they enter |
| --- | --- | --- |
| Admin | School setup, teachers, classes, subjects, teaching assignments and learner enrolment | School access -> Admin -> Admin PIN |
| Teacher | Assigned classes, lesson materials, assignments, class sharing and permitted learner registration | School access -> Teacher -> name -> personal teacher PIN |
| Student | Tutor, learning, notes, practice and assignments | School access -> Student -> name -> learner PIN, if set |

There is no shared Teachers PIN step in the simplified flow.

## 2. Before you begin

1. Install the app on each participating device.
2. Choose the device that will hold the school's Admin records.
3. For separate devices, connect them to the same Wi-Fi network or hotspot.
   Local record transfer and class sharing do not require internet access.
4. Keep the sending app and its sharing screen open while devices connect.
5. Internet pictures and explanations require internet access separately.
   Joining a class does not configure or install an AI model on a student device.

## 3. Admin: set up the school

### First setup

1. Open **School access -> Admin**. On the welcome screen, the
   **School setup or staff sign-in** shortcut also opens school access without
   requiring you to create a student first.
2. On the designated Admin device, use **Or set up the Admin**.
3. Enter the Admin's name, a **4-8 digit PIN**, and the same PIN again.
4. Select **Set up**.
5. Find the school's name card. Select **Set school**, enter the school name,
   and save. School sharing remains unavailable until the school is set.

On later visits, enter the existing Admin PIN and select **Sign in**. Do not
set up another Admin on a receiving teacher device.

### Create the teaching structure

Use the **Set up your school in order** shortcuts:

1. **Add class:** enter the class and stream, for example S2 / East.
2. **Add subject:** create the subject the school will assign to a teacher.
3. **Add teacher:** enter the teacher's name and a personal teacher PIN.
   Give that teacher their own PIN.
4. **Assign teacher:** choose the teacher, class/stream, subject and term.
   Whole year is also available.
5. Repeat assignments for every class and subject that teacher teaches.

Adding a teacher alone does not assign a class. A teacher with no teaching
assignment will have no assigned class to share with.

### Register and enrol students

The Admin can:

1. Open **Learners** in the Admin records and use its **Add** action.
2. Enter the learner's name.
3. Open that learner's menu and select **Enrol**.
4. Choose the class/stream.

Creating a learner and enrolling them are separate steps.

Alternatively, give an existing teacher permission to register students:

1. In **Class teachers**, use **Add**.
2. Choose an existing teacher and the classes/streams they may register into.
3. That teacher will see **Register learners** in their teacher workspace.

A Class Teacher is still a Teacher. It is an extra registration responsibility,
not a fourth role or another sign-in.

### Connect a separate teacher/staff device

On the Admin device:

1. Connect both devices to the same Wi-Fi/hotspot.
2. Open **Admin -> Send school records**.
3. For normal teacher setup, leave
   **Let me take over as Admin on that device** unchecked.
4. Select **Start**.
5. Read the displayed **Address** and **Code**.

On the receiving staff device:

6. Open **School access -> Admin**.
7. Under **Receive school records**, enter that Address and Code.
8. Select **Receive**.

Back on the Admin device:

9. Check the pending device request and select **Accept**.

On the receiving device:

10. Wait for **School records received**.
11. Open **School access -> Teacher**.
12. Choose the teacher's name and enter that teacher's personal PIN.

This transfers school records and teaching assignments. It does not sign the
receiver in as Admin. It is for staff provisioning; students normally join their
class instead of receiving the school's staff records.

When the Admin changes assignments or enrolments, repeat the transfer to update
separate staff devices. It is an explicit transfer, not continuous cloud sync.

## 4. Teacher: sign in and teach

### Sign in

1. Open **School access -> Teacher**.
2. Choose your name.
3. Enter your personal teacher PIN.
4. Your requested teacher tool opens; an ordinary sign-in opens the class dashboard.

You do not enter the old shared Teachers PIN. If your name is missing on a
separate device, receive the school's records first. If you have no classes,
ask the Admin to check your class-and-subject assignments.

### Prepare materials

1. Open **Lesson materials** from the teacher workspace or dashboard.
2. Choose the relevant subject.
3. Use **Upload a PDF** or add typed notes.
4. Select **Share with classes** for the material.
5. Select the assigned class/stream.

Uploading a note does not automatically share it with every student. Share it
with the intended class before starting class sync.

Teachers can also create work from the **Assignments** tools and review learner
work within their permitted teaching scope.

### Register learners, when authorised

1. Open **Register learners** in your teacher workspace.
2. Select one of the classes the Admin gave you registration permission for.
3. Enter the learner's name and select **Register**.
4. Repeat for the class.

On a separate teacher device, these new registrations reach the Admin during
the next school-record connection. The Admin's request screen identifies the
new registrations before accepting. This registration exchange concerns school
records; it is different from a student's learning-progress sync.

### Connect students to your class

On the teacher device:

1. Open **Sync**.
2. Choose **Class to share with**.
3. Select **Sync to class**.
4. Read the displayed **Join code** to the students.
5. Leave this screen open while students join and sync.
6. Check each pending join request and select **Accept** for the correct student.

Class join codes last **15 minutes**. Use **New code** if the code expires or
locks after wrong attempts. A new code is for joining; already joined students
normally use **Sync now** rather than rejoining each time.

Only materials shared with that class are offered. A **No shared notes** message
means you should check the material's **Share with classes** selection.

## 5. Student: enter your learning space

### On a shared school device

1. The staff member selects **Return to student**, or opens
   **School access -> Student**.
2. Staff sessions close and **Who's learning?** opens.
3. Choose your name.
4. Enter your learner PIN if one is set.
5. Use Home for the tutor, Learn for learning activities, My notes for notes,
   and Assignments for your work.

Selecting the currently marked student also checks their PIN if one is set.
If your name is missing, ask the Admin or an authorised Class Teacher to register
you. Staff do not give students their Admin or teacher PINs.

### On your own device: join the teacher's class

1. Open the app and create/select your learner profile.
2. Connect to the same Wi-Fi/hotspot as the teacher.
3. Open **My notes** and select the **Sync class notes** button in the toolbar.
   If no notes are visible, **Join a class** also opens this screen.
4. Enter the teacher's class **Join code**.
5. Select **Join class**.
6. Wait for the teacher to select **Accept** on their device.
7. Confirm that the screen shows **My class** with the correct class.
8. Select **Sync now** to receive the shared class notes.
9. Return to **My notes** to open the downloaded material.

A class join code is not a teacher PIN or an Admin school-record transfer code.

### Daily learning and later updates

1. Choose your own learner profile.
2. Study the downloaded notes and use the learning tools.
3. Complete and submit your assignments as directed.
4. When the teacher is sharing again, reconnect to the same Wi-Fi/hotspot.
5. Open **My notes -> Sync class notes -> Sync now**.
6. Check the sync result before disconnecting.

The teacher's sharing screen must be running for a fresh sync. Downloaded
material remains usable offline, subject to the content available on that device.
Supported progress reports and assignment exchanges travel at sync; do not assume
the teacher sees new work instantly while the devices are disconnected.

## 6. Use the right PIN or code

| Credential | Used for | Where it comes from |
| --- | --- | --- |
| Admin PIN | Opening Admin records | Created during Admin setup |
| Personal teacher PIN | Signing in as one teacher | Created/reset by the Admin |
| Learner PIN, if set | Opening a learner profile | Managed for that learner |
| School-record Address + Code | Provisioning/updating a separate staff device | Admin -> Send school records |
| Class Join code | Joining a teacher's class | Teacher -> Sync -> Sync to class |

Admin takeover is an advanced migration option using an additional passphrase.
It is not needed for an ordinary teacher or student connection.

## 7. Example: one class from setup to learning

1. The Admin sets the school name.
2. The Admin creates **S2 East** and **Biology**.
3. The Admin adds **Teacher Amina** and gives her a personal PIN.
4. The Admin assigns Amina to Biology in S2 East.
5. The Admin adds/enrols learners, or grants Amina registration permission.
6. If Amina uses another device, the Admin sends it the school records.
7. Amina signs in, uploads a Biology PDF and shares it with S2 East.
8. Amina opens Sync and selects Sync to class.
9. A student selects their profile and enters Amina's class Join code.
10. Amina accepts the student, and the student selects Sync now.
11. The student opens Biology in My notes and learns.
12. The student syncs again later for new materials and supported work/progress
    exchange.

For a shared device, skip the network-pairing steps and switch from the staff
workspace to the learner profile.

## 8. If something does not connect

| Problem | What to check |
| --- | --- |
| Teacher name missing | Admin has added the teacher; the separate device received the latest school records |
| Teacher has no classes | Admin assigned both a class/stream and a subject |
| Register learners missing | Admin granted Class Teacher registration permission |
| School not set | Admin selected Set school and saved the school name |
| Student waits for approval | Teacher sharing screen is open; teacher accepted the request |
| No teacher found | Same Wi-Fi/hotspot, teacher selected Sync to class, and local device-to-device traffic is allowed |
| Wrong/expired class code | Teacher generates New code; student enters the class Join code rather than another PIN/code |
| Joined but notes missing | Teacher shared the notes with that exact class; student selected Sync now; check My subjects where shown |
| School records did not arrive | Correct Admin Address and Code; sender selected Start and accepted the receiver |
| Teacher cannot see recent work | Student synced with the teacher device after doing/submitting the work |

For local sharing, a hotspot can work without an internet data connection.
Networks that isolate connected devices can prevent discovery and sharing even
when both devices show the same Wi-Fi name.

## 9. Signing out and using the presentation build

- Use **Return to student** whenever handing a staff device to a learner.
- Staff sessions otherwise survive ordinary navigation and expire after
  60 minutes or when the app closes.
- Picking another learner clears the previous learner's tutor context.
- The permanent My notes Sync shortcut accompanies this guide.
- The installed hub package is on the computer's internal drive. Keep its
  backend/model services running when demonstrating the local hub tutor.
- The local app and the uploaded review branch contain the simplified role flow.
  The different app on AFRICA-AI-CONNECT's existing main branch has not yet been
  replaced; do not assume its screens match this guide.
