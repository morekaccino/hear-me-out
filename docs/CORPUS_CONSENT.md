# Corpus consent and privacy sheet

**Version:** 1.0. **Status:** template for the assessment spike. Fill in the
custodian's name and contact channel before the first session.

**This is a product and operations document, not legal advice.** Have a
qualified lawyer review it before recording any participant. If a local law
requires more, follow the stricter rule.

**Adults only.** This corpus is for participants aged 18 or older. Do not record
a minor, even with a guardian's signature.

---

## 1. What this is

Hear Me Out is building a guitar sight-reading coach that listens through a
phone microphone and tells the player which notes were right, which were wrong,
and which could not be heard. Before shipping that assessment, we need a small
corpus of real guitar recordings so we can check the pitch and timing decisions
against expert labels.

You are being asked to play short phrases on your guitar while a phone, tablet,
or laptop records the audio. A session lead is present. You can stop at any
time.

The corpus is **local-only**. It is not an account, a cloud service, or a
social feature. The app itself does not upload recordings.

---

## 2. What we record

| Data | Example | Why |
|---|---|---|
| Guitar audio | WAV file of you playing 4-, 8-, and 16-note phrases | The core evidence for pitch and timing |
| Device and capture details | Device model, platform, sample rate, channels, microphone placement | To compare devices and resampling behavior |
| Guitar type | Nylon or steel | To check tone and pitch behavior across instruments |
| Self-reported playing level | 1–5, years playing, returner or near-beginner | To stratify results and check the mix |
| Take metadata | Tempo, phrase length, room condition, click/drone route | To reproduce the recording |
| Expert labels | Target notes, measured onsets, expert pass/fail | Ground truth for the analysis |

We do **not** collect:

- your name, email address, phone number, postal address, or account ID in the
  corpus;
- your contacts, location, calendar, photos, or files;
- video or hand images;
- payment or government identifiers;
- app usage analytics or advertising identifiers.

Your recording is linked to a **player ID** such as `p01`, not your name. The
name-to-ID key is stored separately by the corpus custodian, outside the corpus
folder.

**Voice:** the microphone is pointed at the guitar. We ask you not to speak
during a take. If you do speak, your voice may be captured in the WAV. It is not
transcribed and is deleted on the same schedule as the audio.

**Background sound:** other people, traffic, or a television may be audible in
the room-noise condition. We try to keep bystanders out of the room. Do not
bring anyone who has not agreed to be recorded.

---

## 3. Why we record it

We use the recordings to:

- test whether the app detects the right pitch and octave on real guitars;
- measure how note onsets compare with a click;
- see how room noise, a click, a drone, and Bluetooth audio affect detection;
- compare results across phones, tablets, and laptops;
- decide whether the assessment is accurate enough to build the phrase-scoring
  product.

We do not use the recordings to train a commercial model, to advertise, or to
evaluate you as a musician. The labels are about the app's accuracy, not your
ability.

---

## 4. Where it is stored and who can hear it

- **Where:** an encrypted external drive held by the corpus custodian at the
  location written in §11. Some sessions may use a second encrypted drive for
  backup.
- **Not in:** a cloud drive, email, chat, a public repository, a social platform,
  or the Hear Me Out app's servers. The app has no account system and no
  recording upload.
- **Who can hear it:** the session lead, the labelers, and the reviewer named in
  the session log. They are bound by the project's confidentiality rules and
  only open the files for labeling or quality checks.
- **Access log:** the custodian records who accessed the corpus drive and when.
- **No publication:** no audio excerpt, video, or identifiable clip will be
  published without a separate written consent that names the excerpt and the
  venue. This sheet does not grant publication rights.

If you are paid for the session, payment is not conditional on finishing or on
the quality of your playing.

---

## 5. How long we keep it

| Data | Default | If you opt in to keeping raw audio |
|---|---|---|
| Take WAVs and room tones | Deleted **30 days after analysis sign-off**, and no later than **180 days after recording** | Kept until you withdraw or **12 months after recording**, whichever comes first |
| Direct-input/MIDI reference WAVs | Same as take WAVs | Same as take WAVs |
| Label JSON and manifest | Kept until the spike decision plus 12 months; player IDs only | Same |
| Consent form and name-to-ID key | Kept until all participant data is deleted plus 12 months for audit; stored separately under lock | Same |
| Aggregate metrics and reports | Kept; no names, no raw audio, no reversible key | Same |

"Analysis sign-off" means the project has finished checking the labels and
frozen the corpus. If analysis takes longer than 180 days, the default raw audio
is deleted at 180 days and the labels remain.

You can choose to keep raw audio after analysis on the consent form. That is
optional. It does not make the consent permanent: you can withdraw later and
the audio will be deleted.

---

## 6. Your choices

Participation is voluntary.

- You can decline any take, skip a phrase, or stop the session at any time.
- You can withdraw from the corpus after the session.
- You do not have to give a reason.
- Stopping or withdrawing does not affect any payment for time already spent.
- You can ask questions before, during, or after the session.

If you withdraw, we delete your audio, labels, reference files, and manifest
entries, and remove your row from the key file. We keep a deletion log with your
player ID and dates, but no audio and no name. Aggregate numbers that were
already published without identifiers may not be reversible.

---

## 7. Deletion requests

The corpus custodian is named in §11. Contact that person by the channel on the
session sheet.

1. **Acknowledge:** within **2 business days**.
2. **Delete:** audio, labels, reference files, manifest entries, and backups;
   remove the key-file row.
3. **Confirm:** in writing within **14 days**. If a backup cannot be purged
   immediately, the confirmation gives the date, no later than **30 days** after
   the request.
4. **Log:** player ID, request date, completion date, and scope. No audio and no
   name in the log.

You do not need to use a special form. A written or verbal request is enough;
the custodian writes it down and reads it back to you.

---

## 8. Risks and benefits

**Risks.** The main risk is a privacy one: a recording of your guitar could be
recognizable to someone who knows your playing, even without your name. The
corpus is kept on an encrypted drive with a small access list, but no system is
perfect. There is no financial, legal, or employment risk created by taking
part, and no sensitive category of data is collected. You may feel tired or
frustrated while repeating phrases; take breaks and stop when you want.

**Benefits.** There is no direct payment or musical benefit promised. You help
the project decide whether its pitch and timing assessment is honest enough to
ship. If you want a summary of the aggregate result, ask the custodian and one
will be sent after the analysis is signed off.

---

## 9. No accounts, no cloud, no publication

- The app does not create an account for this corpus.
- The corpus is not stored in a cloud service.
- No audio is published, streamed, or shared with a third party.
- No advertising or analytics identifier is collected.
- No model training or commercial resale is part of this corpus.
- If the project later wants to publish an excerpt or use the audio for a
  different purpose, it must ask you separately in writing. This sheet is not
  that consent.

---

## 10. Participant agreement and choices

I have read this sheet, or it was read to me. I had a chance to ask questions. I
understand that I can stop at any time and can request deletion.

**Player ID:** `p______`  **Date:** `____________________`

**Printed name (kept only with this form, not in the corpus):**
`________________________________________________`

**Signature or initials:** `__________________________`

Please initial each choice:

- [ ] **Required — audio capture.** I agree to have my guitar playing recorded
      and analyzed for the assessment corpus.
- [ ] **Optional — keep raw audio.** I agree that the raw WAV files may be kept
      after analysis, for up to 12 months after recording, instead of being
      deleted 30 days after analysis sign-off.
- [ ] **Optional — anonymized metrics.** I agree that anonymized measurements
      and labels from my takes may be included in internal project reports.

If you do not initial the optional raw-audio choice, the default deletion rule
applies. If you do not initial the metrics choice, your takes are excluded from
aggregate reports.

---

## 11. Custodian and contact

Fill this in before recruiting. The participant keeps a copy of this page.

**Corpus custodian:** `______________________________________________`

**Contact channel (email or phone):**
`______________________________________________`

**Corpus drive location:**
`______________________________________________`

**Backup location, if any:**
`______________________________________________`

---

## 12. Session lead attestation

I confirm that:

- I checked the participant's age (18+) and ability to consent.
- I answered the participant's questions and gave them a copy of this sheet.
- I recorded the participant's choices on this form before the first take.
- I explained that participation is voluntary and that deletion is available.
- I stored this form and the name-to-ID key separately from the corpus.
- I will follow the retention and deletion rules in
  [`CORPUS_PROTOCOL.md`](CORPUS_PROTOCOL.md) §10.

**Session lead name:** `____________________________________`

**Signature:** `__________________________________________`

**Date:** `____________________`

---

## 13. Withdrawal or deletion request

The participant may fill this in, or the custodian may fill it in from a verbal
request.

**Player ID:** `p______`

**Request date:** `____________________`

**Scope requested:**

- [ ] Delete all audio (takes, room tone, DI/MIDI reference).
- [ ] Delete labels and manifest entries.
- [ ] Remove my row from the key file.
- [ ] All of the above.

**Participant signature or initials:** `__________________________`

**Custodian acknowledgement (within 2 business days):**

`____________________________________________________________`

**Deletion completed (within 14 days; backups within 30 days):**

`____________________________________________________________`

**Custodian signature:** `________________________________`

**Date:** `____________________`

---

*This document is a product/operations template, not legal advice. The project
must obtain legal review before recording participants.*
