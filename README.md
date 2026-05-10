# MedAT Figuren zusammensetzen Training App

## Complete Learning System Specification

---

This app is supposed to teach users how to learn and improve the **Figuren zusammensetzen skill for the Austrian MedAT**.

It should be an app mainly for **iPad/iPhone**, using **Swift (SwiftUI + native iOS architecture)** to ensure a highly responsive, low-latency, touch-optimized spatial reasoning experience.

The user is supposed to learn in stages.

---

Below is a **fully self-contained product + learning system specification** for your MedAT “Figuren zusammensetzen” training app. It includes all rules, structures, and behavioral logic needed to implement the system without prior context.

It explicitly clarifies:

* difficulty is **dynamic within each stage**
* temporary **performance regression is expected when entering a new stage**
* no stage looping exists (but adaptive fluctuation does)
* user-specific engagement and progression thresholds are continuously adapted after initial calibration

---

# 1. Product purpose

This application is a **cognitive training system** for the MedAT exam section “Figuren zusammensetzen”.

It is designed to train users to:

> mentally decompose geometric figures, simulate rotations of fragments, and reconstruct complete shapes under time pressure without physical manipulation.

The app is not a game — it is a **structured visuospatial reasoning training environment**.

---

# 2. Core cognitive skill being trained

The system trains five interdependent abilities:

### 1. Perceptual decomposition

Breaking a whole shape into meaningful parts.

### 2. Mental rotation simulation

Imagining how a piece looks after rotation without physically manipulating it.

### 3. Edge compatibility reasoning

Determining whether pieces fit based on shape boundaries.

### 4. Hypothesis testing under uncertainty

Evaluating possible assemblies mentally before committing.

### 5. Strategy automation

Developing fast, subconscious heuristics for solving patterns.

---

# 3. System architecture overview

The system consists of three interacting layers:

---

## LAYER 1 — Learning Stages (macro progression)

A linear sequence of cognitive training modes:

> Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5

### Properties:

* Users always progress forward
* No looping between stages
* Each stage defines a **different cognitive mode**
* Transition represents a change in thinking strategy, not just difficulty

---

## LAYER 2 — Adaptive Difficulty System (micro-level dynamics)

Within each stage:

* difficulty is continuously adjusted per user performance
* difficulty is NOT fixed per stage
* difficulty fluctuates dynamically inside allowed bounds

This creates:

> stable cognitive mode + adaptive challenge tuning

---

## LAYER 3 — Personal Cognitive Model (NEW — added, fully integrated)

Each user has a continuously adapting performance model used by the system to regulate difficulty.

This layer is independent from stages and difficulty axes.

---

# 3.1 Engagement Floor (E-floor)

The minimum difficulty level required to keep the user engaged.

If performance drops below this:

* user becomes disengaged or frustrated
* system reduces difficulty immediately

---

# 3.2 Progression Threshold (P-threshold)

The minimum stable performance level required to move to the next stage.

If consistently exceeded:

* user is eligible for next stage transition

---

# 3.3 Important: these are NOT fixed values

These thresholds:

* are initially estimated in early usage (first ~10–30 puzzles)
* are continuously adapted after calibration
* evolve over time based on user behavior

---

# 3.4 User variability requirement (critical system constraint)

Different users require different thresholds:

* some users remain engaged at lower success rates (~60%)
* others require higher success rates (~85%+) to stay motivated
* learning speed and frustration tolerance differ significantly between individuals

Therefore:

> thresholds must be personalized per user and continuously updated

---

# 3.5 Signals used for adaptation

The system updates the personal model using:

### Performance signals

* accuracy (weighted recent > old)
* time-to-solve relative to difficulty
* error type distribution

### Learning signals

* improvement slope over time
* recovery speed after difficulty increase

### Engagement signals

* session length stability
* hesitation time before starting tasks
* dropout / abandonment behavior

### Behavioral signals

* reliance on hints (if available)
* adoption of correct cognitive strategy (especially Phase 3+)

---

# 3.6 Update behavior rules

### Engagement Floor (E-floor)

* reacts relatively quickly
* protects against frustration and disengagement

### Progression Threshold (P-threshold)

* updates slowly
* requires consistent evidence of mastery

---

# 3.7 Asymmetry principle

* engagement adapts fast
* progression adapts slow

Reason:

> emotional state is volatile, skill acquisition is stable and gradual

---

# 4. Puzzle difficulty model (two-axis system)

Every puzzle is defined using two independent dimensions:

---

## AXIS A — Structural complexity (piece count)

Represents how many fragments must be mentally integrated.

| Level      | Description                       |
| ---------- | --------------------------------- |
| 1–2 pieces | very low structural load          |
| 3–4 pieces | medium structural load            |
| 5–6 pieces | high (exam-level) structural load |

---

## AXIS B — Cognitive ambiguity (reasoning difficulty)

Represents how difficult it is to mentally determine correct assembly.

Includes:

* rotation ambiguity
* edge similarity
* symmetry traps
* distractor similarity

---

## Key principle:

> AXIS A ≠ AXIS B
> They are independent and must be tuned separately.

---

# 5. Dynamic difficulty behavior (IMPORTANT CLARIFICATION)

### Within each stage:

Difficulty is NOT fixed.

Each stage defines a **difficulty range (envelope)** for:

* AXIS A
* AXIS B

### Inside these ranges:

System continuously adapts difficulty based on:

* user performance
* personal cognitive model (Layer 3 constraints)

---

## Adaptive behavior rules:

* If user performs well:

  * increase AXIS B first (ambiguity)
  * then AXIS A (pieces)

* If user struggles:

  * decrease AXIS B first
  * decrease AXIS A only if necessary

---

## Target learning zone:

> 70–85% success rate

This is the optimal cognitive strain range for learning.

---

# 6. Learning progression stages (full specification — unchanged structure)

Each stage defines:

* cognitive mode (how the user thinks)
* allowed difficulty range (dynamic envelope)
* interaction rules
* learning objective

---

# PHASE 1 — Perceptual onboarding

### Purpose:

Teach basic part-to-whole perception.

### Cognitive mode:

External visual understanding (no mental simulation required yet)

### Dynamic difficulty range:

* AXIS A: 1–2 pieces
* AXIS B: very low ambiguity

### Interaction rules:

* full drag & drop interaction
* rotation allowed
* snapping assistance enabled
* edge highlighting enabled
* immediate feedback on correctness

### Learning objective:

User understands how fragments form a complete shape visually.

---

# PHASE 2 — Structured decomposition

### Purpose:

Introduce structural reasoning without heavy assistance.

### Cognitive mode:

guided structural reasoning

### Dynamic difficulty range:

* AXIS A: 2–4 pieces
* AXIS B: low → medium-low ambiguity

### Interaction rules:

* rotation allowed
* reduced snapping assistance
* reduced or removed edge highlighting
* feedback after completion

### Learning objective:

User begins recognizing structural relationships without heavy UI guidance.

---

# PHASE 3 — Mental prediction training (core transition stage)

### Purpose:

Train internal simulation before interaction.

### Cognitive mode:

mental rotation + pre-action prediction

### Dynamic difficulty range:

* AXIS A: 3–5 pieces
* AXIS B: medium ambiguity

### Interaction rules:

* user must first **predict orientation and placement mentally**
* system requires explicit prediction step before interaction:

  * “Which orientation fits?”
  * “Where does this piece belong?”
* user confirms prediction
* only then interaction is allowed for verification
* no edge highlighting or visual hints

### Learning objective:

User learns to simulate transformations mentally before acting physically.

---

# PHASE 4 — Exam simulation mode

### Purpose:

Replicate MedAT exam conditions.

### Cognitive mode:

fully internal problem solving under time pressure

### Dynamic difficulty range:

* AXIS A: 5–6 pieces
* AXIS B: medium → high ambiguity

### Interaction rules:

* no hints or scaffolding
* strict time limits
* no prediction prompts
* interaction only for final answer submission

### Learning objective:

User can solve problems mentally under real exam constraints.

---

# PHASE 5 — Mastery / automation phase

### Purpose:

Achieve automatic spatial reasoning performance.

### Cognitive mode:

fast, near-automatic visuospatial processing

### Dynamic difficulty range:

* AXIS A: 5–6 pieces
* AXIS B: high → extreme ambiguity

### Interaction rules:

* no assistance
* no hints
* accelerated timed tasks
* high symmetry traps and distractor density

### Learning objective:

User solves problems quickly with minimal conscious effort.

---

# 7. CRITICAL BEHAVIOR: Stage transition and regression effects

## 7.1 Stage transition rule

Users move forward ONLY when:

* they achieve stable performance within current stage range
* they consistently apply the required cognitive strategy of that stage
* they meet success criteria (typically ~75–85% accuracy under current constraints)

---

## 7.2 Expected performance regression (IMPORTANT)

When users enter a new stage:

### It is expected that:

* accuracy temporarily drops
* users struggle even with easier puzzles
* performance may be worse than previous stage baseline

### Reason:

This is caused by a **change in cognitive strategy requirement**, not increased difficulty.

---

## 7.3 Regression behavior is NOT a failure

This temporary drop is:

* expected
* necessary for learning
* a sign of successful transition to a new cognitive mode

---

## 7.4 Important restriction

Despite regression effects:

* stages do NOT loop backward
* users do NOT cycle between stages
* regression only occurs within early part of a new stage

---

# 8. SYSTEM SUMMARY (complete mental model)

---

## 1. Linear cognitive stage progression

Perception → Structure → Mental simulation → Exam → Automation

---

## 2. Adaptive difficulty inside each stage

Each stage has a dynamic difficulty envelope.

---

## 3. Two-axis puzzle model

* AXIS A: structural load
* AXIS B: cognitive ambiguity

---

## 4. Personal cognitive model (NEW integrated layer)

* engagement floor (E-floor)
* progression threshold (P-threshold)
* continuously adapted per user

---

## 5. Key behavioral principle

> Stages define HOW the user thinks
> Difficulty defines HOW HARD thinking is
> Personal model defines HOW the system adapts to the user

---

# FINAL TAKEAWAY

This system is a:

> **progressive cognitive transformation engine that converts external visuospatial manipulation skills into internal mental simulation ability required for MedAT performance, while continuously adapting difficulty and engagement thresholds to each individual user through a closed-loop feedback system**
