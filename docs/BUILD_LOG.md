# AI Connect Africa v3 — Build Log

Complete documentation of AI Connect Africa v3, rebuilt from v2 with curriculum-first architecture.

---

## 1. Origin

Cloned from `EccentricIvan/otic-studio-v2` into `EccentricIvan/otic-studio-v3`.
v2 relied on Gemma AI for all teaching — but the 1B model lacked depth for real education.
v3 shifts to a **curriculum-first** approach: structured content teaches, AI assists.

**Repo:** `https://github.com/EccentricIvan/otic-studio-v3`

---

## 2. Architecture (v3)

### Core Philosophy
- **Curriculum teaches** — 300 lessons with accurate, structured content displayed directly
- **AI assists** — Gemma handles follow-up Q&A, teach scoring, and general chat
- **Fully offline** — everything works without internet
- **Dual platform** — Android (on-device Gemma) + Windows (Ollama)

### Tech Stack
| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.44+ / Dart |
| State management | Riverpod |
| Routing | go_router with ShellRoute |
| Database | SQLite via Drift |
| AI (Android) | flutter_gemma 1.0.3 (Gemma 3 / LiteRT) |
| AI (Windows) | Ollama (localhost HTTP) |
| Curriculum | Bundled JSON assets |
| Theme | Material 3 with light + dark mode |
| Font | Plus Jakarta Sans (bundled) |
| Certificates | PDF generation (offline) |

### Key Directories
```
lib/
  ai_core/           AI inference, model manager, tutor pipeline
  curriculum/         Curriculum loader, models, progress tracking
  core/theme/         AppColors, AppTheme (light + dark), ThemeProvider
  core/router/        GoRouter with ShellRoute
  db/                 Drift tables, DAOs, providers
  features/
    curriculum_browser/  Subject → Unit → Lesson → Quiz screens
    web_dev_lab/         HTML/CSS/JS code editor + live preview
    python_lab/          Python code editor + output
    app_dev_lab/         App development guided lessons
    home/                Home screen with mode cards
    practice/            Quiz questions from curriculum
    teach/               Explain topics for scoring
    settings/            Theme toggle, profile, model status
    ...
  shared/widgets/     AppShell, cards, section headers
  gamification/       Badge definitions and service
  certificates/       PDF certificate generator
assets/
  curriculum/         15 JSON files (300 lessons, 1,500 questions)
  branding/           Logo
  fonts/              Plus Jakarta Sans
```

---

## 3. Curriculum System

### Overview
- **15 subjects**, each with **4 units × 5 lessons = 20 lessons**
- **Total: 300 lessons, 1,500 quiz questions, 22 diagrams**
- **Total size: ~712 KB** (smaller than one phone photo)
- Bundled in APK as JSON assets — no download needed

### Subjects
| Subject | Lessons | Key Topics |
|---------|---------|-----------|
| Mathematics | 20 | Numbers, Algebra, Geometry, Statistics, Pythagoras, Transformations |
| Physics | 20 | Forces, Energy, Waves, Electricity, Nuclear, Pressure |
| Biology | 20 | Cells, Body Systems, Ecology, Genetics, Enzymes, Disease |
| Chemistry | 20 | Atoms, Reactions, States, Acids, Electrolysis, Moles |
| Programming | 20 | Variables, Control Flow, Functions, OOP, Testing, APIs |
| Web Development | 20 | HTML, CSS, JavaScript, DOM, Frameworks, Deployment |
| App Development | 20 | UI/UX, Widgets, State, APIs, Testing, Publishing |
| AI & Data Science | 20 | ML, Neural Networks, LLMs, Ethics, Python ML |
| Entrepreneurship | 20 | Ideas, Planning, Marketing, Scaling, Funding, Impact |
| Agriculture | 20 | Soil, Crops, Livestock, Irrigation, Climate-Smart, Business |
| History | 20 | Ancient, Medieval, Modern, Colonial, Cold War, Contemporary |
| Geography | 20 | Physical, Human, Resources, Climate, Maps, GIS |
| English Writing | 20 | Grammar, Paragraphs, Essays, Creative, Persuasive, Poetry |
| Economics | 20 | Supply/Demand, Markets, Macro, Money, Trade, Behavioral |
| Arts | 20 | Elements, Techniques, History, Digital, Photography, Careers |

### Lesson Structure (JSON)
Each lesson contains:
- `title` — lesson name
- `content` — 2-3 paragraphs of teaching material
- `examples` — 3 real-world examples
- `keyTerms` — 3-5 vocabulary definitions
- `quiz` — 5 multiple-choice questions with explanations
- `diagram` — (optional) ASCII art diagram

### Diagrams (22 total)
ASCII diagrams in key lessons: cell structure, photosynthesis, food chains, circulatory system, atomic structure, chemical bonding, pH scale, Newton's laws, electric circuits, speed graphs, fractions, angles, area formulas, Pythagoras, water cycle, plate tectonics, supply/demand, flowcharts, loop diagrams, sentence types, essay structure, business model canvas.

---

## 4. Screens and Features

### Learn (Curriculum Browser)
- **Subject grid** — 15 subjects as cards with icons and lesson counts
- **Units screen** — 4 units per subject with lesson list
- **Lesson screen** — full content, examples, key terms, diagram, interactive quiz
- **Quiz** — instant feedback, explanations, score, completion tracking
- **"Ask AI"** button — opens AI chat about the current lesson topic
- **Prev/Next** navigation between lessons

### Practice (Curriculum Quizzes)
- Pick a subject from dropdown
- 10 random questions from that subject's curriculum
- Progress bar, score tracking, explanations
- Results screen with percentage and retry option
- **No AI dependency** — uses 1,500 pre-built questions

### Create (Dev Labs)
Three cards linking to:
- **Web Dev Lab** — 8 guided HTML/CSS/JS tutorials with live WebView preview
- **Python Lab** — 8 guided Python tutorials with output display
- **App Dev Lab** — guided mobile app development lessons from curriculum

### Web Dev Lab
- 8 step-by-step lessons: HTML basics → CSS → Links → Cards → JavaScript → Forms → Flexbox → Full website
- Dark-themed code editor (monospace)
- Live preview via WebView
- RUN button to render code instantly
- Hints and challenges per lesson
- Lesson picker for navigation

### Python Lab
- 8 step-by-step lessons: Hello World → Variables → Math → If/Else → Loops → Functions → Lists → Quiz Game
- Dark-themed code editor
- Output display (offline — no internet needed)
- Starter code shows expected output
- Modified code: basic print() parser extracts output

### App Dev Lab
- Guided learning path from curriculum
- 4 units with 20 lessons covering app concepts, UI/UX, data, publishing
- Each lesson links to full lesson viewer with quiz

### AI Chat
- General Q&A with Gemma model
- Accessible from sidebar and "Ask AI" buttons on lessons
- Tutor pipeline with curriculum context injection
- Emotional safety engine for crisis detection

### Teach
- Student picks a topic and writes an explanation
- Gemma scores it out of 100
- Feedback: strengths, improvements, overall
- Badge awarded for scores ≥ 80

### Achievements
- Badge system with 10 badges
- Earned through: completing lessons, quiz scores, teaching, streaks
- Points system tied to badges
- Visual grid of earned vs locked badges

### Certificates
- PDF certificate generation for completed subjects
- Offline — saved to device storage
- Professional layout with student name, subject, date

### Settings
- **Theme toggle** — Light / Dark / System (persisted with SharedPreferences)
- Student profile display
- AI model status (installed/not installed)
- Streak and points display
- Admin dashboard access
- Data reset option

---

## 5. Theme System

### Dual Theme Support
All screens use `Theme.of(context)` instead of hardcoded colors — both light and dark themes work correctly.

| Element | Light | Dark |
|---------|-------|------|
| Background | #F8FAFC | #0F172A |
| Surface | #FFFFFF | #1E293B |
| Border | #E2E8F0 | #334155 |
| Primary text | #0F172A | #F1F5F9 |
| Secondary text | #64748B | #94A3B8 |

### Accent Colors (same in both themes)
| Role | Hex |
|------|-----|
| Primary / Action | #4F46E5 (Indigo) |
| Success | #10B981 (Emerald) |
| Error | #EF4444 (Red) |
| Learn icon | #4F46E5 |
| Practice icon | #0EA5E9 |
| Create icon | #F59E0B |
| Teach icon | #10B981 |

---

## 6. AI Integration

### Gemma 3 (Android)
- `flutter_gemma` 1.0.3 with `flutter_gemma_mediapipe` 1.0.0
- Supports both `.bin` (Gemma 2) and `.task` (Gemma 3) model files
- Initialized in `main.dart` only on Android
- Model installed via file picker from USB transfer

### Ollama (Windows/Linux)
- OllamaEngine connects to `localhost:11434`
- Default model: `gemma3:1b`
- Auto-detected: if Ollama is running, it's used; otherwise MockEngine fallback

### Tutor Pipeline
- Curriculum search on every message (word-by-word scoring)
- Topic detection for all 15 subjects (keyword matching)
- Lesson context trimmed to ~500 chars for small model compatibility
- Concise prompt: friendly tutor + lesson context + stage instruction
- Stages: answer → clarify → practice → apply → create → reflect

### Where Gemma is Used
| Feature | Uses Gemma |
|---------|-----------|
| AI Chat (/chat) | Yes — general Q&A |
| Ask AI (lesson button) | Yes — follow-up about lesson |
| Teach mode | Yes — scores explanations |
| Learn (curriculum) | No — content displayed directly |
| Practice (quizzes) | No — curriculum questions |
| Dev Labs | No — code editors |

---

## 7. Navigation

### Bottom Bar (5 tabs)
Home, Learn, Practice, Create, Projects

### Sidebar/Drawer (accessible from every screen via menu button)
- My Paths (with progress)
- Home, Learn, Practice, Create, Projects
- Web Dev Lab, Python Lab, App Dev Lab
- AI Chat
- Achievements, Certificates
- Teacher, Settings

### Global Menu Button
Floating menu button (top-right) appears on every screen via AppShell — opens the drawer without each screen needing its own button.

---

## 8. Onboarding

Simplified to **2 steps**:
1. **Name** — "What's your name?"
2. **Interests** — pick topics from a grid of 15 subjects

Removed: age/grade screen and learning style screen.

---

## 9. Progress Tracking

### Lesson Completion
- Tracked via SharedPreferences
- Lesson marked complete when quiz score ≥ 60%
- Completion checkmark and banner shown

### Badges
| Badge | Trigger | Points |
|-------|---------|--------|
| First Step | Complete first lesson | 50 |
| Path Master | Complete all lessons in a path | 200 |
| Quiz Taker | Attempt first practice exercise | 30 |
| Sharp Mind | Get 5 practice questions correct | 100 |
| Scenario Solver | Complete 5 Apply scenarios | 100 |
| The Teacher | Score 80+ in Teach mode | 150 |
| Creator | Save first project | 80 |
| Consistent Learner | 7-day streak | 150 |
| Polymath | Start 3 different topic paths | 120 |
| Century | Earn 100 total points | 0 |

### Streaks
- Updated daily on first interaction
- Consecutive days increment streak
- Missing a day resets to 1

---

## 10. CI/CD

- **Repo:** `https://github.com/EccentricIvan/otic-studio-v3`
- **Workflow:** `.github/workflows/build-release-artifacts.yml`
- **Triggers:** Push to `main`, manual dispatch
- **Jobs:**
  1. Build Android APK (ubuntu-latest, Flutter 3.44.x)
  2. Build Windows EXE (windows-latest)
  3. Publish to rolling `latest-build` release

### Download Links
- **APK:** `https://github.com/EccentricIvan/otic-studio-v3/releases/download/latest-build/ai-connect-africa-latest.apk`
- **Windows:** `https://github.com/EccentricIvan/otic-studio-v3/releases/download/latest-build/ai-connect-africa-windows-latest.zip`

---

## 11. Dependencies

```yaml
# Navigation + UI
go_router: ^14.0.0
flutter_riverpod: ^2.5.1

# AI inference
http: ^1.2.0
flutter_gemma: ^1.0.3
flutter_gemma_mediapipe: ^1.0.0
ffi: ^2.1.0

# Local storage
drift: ^2.20.0
drift_flutter: ^0.2.1
sqlite3_flutter_libs: ^0.5.0
path_provider: ^2.1.4
path: ^1.9.0

# User preferences
shared_preferences: ^2.2.3

# File picker (model install)
file_picker: 8.3.7

# Web Dev Lab
webview_flutter: ^4.10.0

# Certificates
pdf: ^3.10.8
```

---

## 12. Model Setup (for AI features)

### Android — Gemma 3
1. Download **gemma3-1B-it-int4** from Kaggle (LiteRT tab, ~541 MB)
2. Transfer `.task` file to phone via USB
3. Open app → AI Chat → "Install from file" → pick the file
4. Wait for progress bar → AI is live

### Windows — Ollama
1. Install Ollama from `ollama.com`
2. Open terminal: `ollama pull gemma3:1b`
3. Run: `ollama serve`
4. Open AI Connect Africa → AI Chat works automatically

---

## 13. Site Builder

### Conversational Chat Builder
- Student chats with a bot to build a website step by step
- Bot asks "What type of site?" → student picks from 10 templates
- Bot asks each field one by one with default suggestions
- Student types answers or skips for defaults
- Bot builds the site and shows a live preview card
- Feels like chatting with AI but is 100% reliable — no model needed

### 10 Website Templates
| # | Template | Theme/Style |
|---|----------|-------------|
| 1 | Bakery / Restaurant | Warm brown, menu cards |
| 2 | Hotel / Lodge | Black & gold luxury |
| 3 | Gym / Fitness | Dark red/black, bold |
| 4 | Salon / Spa | Pink elegant |
| 5 | Church / Ministry | Purple, verse section |
| 6 | Real Estate | Green, property listings |
| 7 | Tech Startup | Dark gradient indigo |
| 8 | NGO / Charity | Teal, impact stats |
| 9 | Personal Portfolio | Dark indigo, projects |
| 10 | School Website | Blue, programs & stats |

### Template System
- Templates stored as HTML files in `assets/templates/`
- Placeholder variables: `{{business_name}}`, `{{phone}}`, etc.
- Student input replaces placeholders at build time
- Live preview rendered via WebView
- Total template size: ~50 KB (all 10 combined)

---

## 14. Known State (v3 final)

### Working
- ✅ 15 subjects with 300 lessons, 1,500 quiz questions
- ✅ Curriculum browser: subject → unit → lesson → quiz
- ✅ Practice mode with curriculum-based quizzes
- ✅ Web Dev Lab (8 guided HTML/CSS/JS tutorials)
- ✅ Python Lab (8 guided Python tutorials, offline output)
- ✅ App Dev Lab (guided learning path)
- ✅ Site Builder with 10 templates via conversational chat
- ✅ AI Chat with curriculum context (Gemma)
- ✅ Ask AI button on every lesson
- ✅ Teach mode with scoring (Gemma)
- ✅ Dual theme (light/dark) with toggle in Settings
- ✅ Lesson completion tracking (60%+ quiz score)
- ✅ Badge and achievement system (10 badges)
- ✅ Certificate PDF generation
- ✅ Global menu button on every screen (via AppShell)
- ✅ Onboarding (2 steps: Name → Interests)
- ✅ Collaborate removed (half-built LAN feature)
- ✅ Android APK + Windows EXE builds via CI
- ✅ Fully offline — no internet required

### Future Improvements
- Deepen curriculum content (more lessons per subject, up to 1,000+)
- Add country-specific curricula (Uganda, Kenya, Nigeria, etc.)
- Upgrade to Gemma 3 4B for better AI responses (needs 8GB+ RAM)
- Add Bluetooth device-to-device sharing
- Show lesson completion checkmarks on units/subjects screens
- Add image diagrams (SVG/PNG) to lessons
- Difficulty levels (beginner/intermediate/advanced)
- More website templates
- Certificate wiring to subject completion
