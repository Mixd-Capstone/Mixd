# MIXD — Requirements & design exploration (draft)

## Requirements

### What MIXD achieves

MIXD restores **intentional curation**: users assemble **segments** from songs into a **~10-minute mixtape**, preview it as **one continuous listen**, choose **public or private**, and **discover** others’ mixes in a **vertical feed**. This section describes **outcomes and experience**, not implementation.

### Features

1. Sign-in and profile; sign-out  
2. Searchable **song catalog**; short **preview**; optional **artist upload** (roadmap)  
3. **Editor**: add/remove clips, **trim** in/out, **reorder**, **play full mix**; **≤10 min** total  
4. **Save** with title, description, **public/private**  
5. **My mixes** and **shared with you**  
6. **Feed** of public mixes; **Explore** entry  
7. **Walkman-style player**: continuous playback, seek, tracklist  
8. Social signals (likes, comments, etc.) as scoped  
9. **Sharing**, **collections**, **collab**, **moderation**, **link-out web preview** — backlog epics as in your estimation sheet  

### User stories (Persona — What — Why) — 21

1. **Bedroom Creator** — Build and publish a ~10-minute mix on the phone — Show skill without pro gear  
2. **Independent Music Producer** — Others use my tracks with **attribution** — Exposure when sampled in mixes  
3. **Casual Listener** — Scroll a feed of mixes/snippets — Low-effort discovery  
4. **Local Event Promoter** — Search by genre and engagement — Book stronger vibes for events  
5. **Music Curator** — Named **collections** of mixtapes — Themed sharing  
6. **DJ (collab)** — Co-create or reuse parts of mixes — Shared audiences  
7. **Emerging Creator** — **Analytics** (likes/views) — Learn what lands  
8. **Administrator** — **Review/remove** bad text/images — Safety and compliance  
9. **Platform (auto-mod)** — **Auto-flag** explicit or abusive content — Scale trust  
10. **Nostalgic Mixtape User** — **Custom cover + notes** — Physical-tape ritual  
11. **Record Label Scout** — **Trending** mixes — Spot talent  
12. **Long-distance friend** — Curate, **note**, **send** — Emotional connection  
13. **Off-platform sharer** — **Link** + web preview, listen without account — No install barrier  
14. **New user (streaming)** — **Connect** other service — Faster personalization  
15. **Gift giver** — Mix for partner + note (optional romantic picks) — Thoughtful gesture  
16. **Music-shy listener** — **Receive** mixes from trusted people — Discovery without solo browsing  
17. **Expert curator** — Any catalog song, **title**, **cover** — Maximum meaning  
18. **Genre advocate** — Curate for a friend’s taste — Guided exploration  
19. **Music Creator** — **Upload MP3s** — Grow catalog  
20. **Moment sender** — **Event/date + story**; optional **Memories** — Anchor to life events  
21. **Social explorer** — **Friend listening** activity, save, filters — Social discovery  

### Usage scenarios

- **Publish:** Bedroom Creator searches catalog, trims and orders clips under the cap, sets public, saves → mix appears in feed with curator and metadata.  
- **Listen:** Casual Listener scrolls feed, opens a card, plays the full mix in one player, opens tracklist.  
- **Trust:** Music-shy listener opens **Shared with you**, reads curator name and note, plays without building anything.  
- **Safety:** User uploads offensive cover; system flags; Administrator removes; creator can edit and resubmit.  

### Definition of success

Measurable or binary checks per epic: auth works end-to-end; catalog search and preview succeed for valid files; editor changes **always** match playback order and trim; saved row appears under **My mixes** with correct visibility; **public** mixes visible in feed, **private** not; continuous playback across clips in test matrix; feed first paint under agreed threshold on lab Wi‑Fi; **SUS or task success** on create → save → play-from-feed; moderation paths demonstrable for scope you commit to this term.

---

## Design exploration

### Comparison of solutions

| | A — Web DAW + separate social site | B — Native iOS + Android + custom API | C — Flutter + BaaS (Supabase) |
|---|-------------------------------------|----------------------------------------|--------------------------------|
| **Idea** | Browser editor + another web app for feed | Swift/Kotlin + your servers | One UI codebase + managed auth/DB/storage |
| **Pros** | No app install for editor | Best OS hooks | Fast slices; one backlog; less ops |
| **Cons** | Two products; flaky mobile web audio | Duplicate UI; slower for 4 people | Must QA web audio edges |

**Criteria:** speed to demo, team split, cross-platform, audio risk, ops burden.  
**Choice: C** — matches Scrum slices and current stack.

### Lo-fi artifacts (in this folder)

| File | Role |
|------|------|
| `sketch_01_login.svg` … `sketch_04_feed.svg` | Four **sketches** (rough, concept) |
| `wireframe_01_home_nav.svg` … `wireframe_04_mixes_hub.svg` | Four **wireframes** (layout) |
| `system_diagram.svg` | **System diagram** |

Open SVGs in a browser or place them in Word/Google Docs for the PDF.

### Pilot studies (filled)

**Feedback patterns**

- Several peers tried to **drag trim handles** with thumbs and missed the first time; two asked how much time was **left before the 10-minute cap**.  
- Half the group assumed the **Explore** search bar on the feed was already **live search**; confusion when category tiles did not filter real data.  
- A few wanted **private as default** when saving because they feared posting by accident.  
- One person looked for **waveforms** to trim; another said waveforms would be “nice but not required” if the numbers or scrubber were clear.

**Design moves**

1. **Larger trim touch targets and clearer “selected clip” highlight on the timeline** — Reduces mis-taps and matches how people tried to interact in the pilot.  
2. **Always-visible “total / max” time (e.g., 7:32 / 10:00) in the editor header** — Answers the cap question without opening a menu.  
3. **Save dialog: one-line explanation under the public/private switch** (“Public: anyone can see in the feed”) **and default to Private** — Addresses accidental publish anxiety and matches stories about intimate sharing.  
4. **Explore: either wire real search or add a short “Categories coming soon” hint** — Closes the expectation gap between static tiles and a search-looking field.  
5. **Optional later: waveform or zoom-on-drag (already hinted in sketches)** — Only if time; pilot showed trimming is the riskiest task, so precision affordances are prioritized in backlog order.

### Inclusion, diversity, equity, accessibility

- **Listeners-first:** Feed and player stay polished so people who never edit still get value.  
- **Equity:** Relying on one sign-in provider excludes some users; plan extra providers or email when policy allows.  
- **Moderation:** Protects marginalized users from harassment in notes and art.  
- **Accessibility:** Dark theme with readable contrast; **44pt+** targets on play/save; **labels** for icon-only controls; **dynamic type** where supported; **text** for titles/notes so screen readers get context beyond raw audio.
