# EARS Patterns Reference

## The Five EARS Patterns

### 1. Ubiquitous (No keyword)
Requirements always active throughout system operation.

**Syntax:** `The <system name> shall <system response>`

**Examples:**
```
The web application shall support concurrent access by 10,000 users.
The API shall use HTTPS for all communications.
The database shall encrypt all stored passwords using SHA-256.
```

### 2. State-Driven (While)
Requirements active while a specified state remains true.

**Syntax:** `While <pre-condition(s)>, the <system name> shall <system response>`

**Examples:**
```
While the user is logged in, the application shall display the user's dashboard.
While a file upload is in progress, the application shall display a progress bar.
While in maintenance mode, the system shall reject new user requests.
```

**Key:** State = condition that persists over time (NOT a discrete event)

### 3. Event-Driven (When)
Requirements triggered by a specific discrete event.

**Syntax:** `When <trigger>, the <system name> shall <system response>`

**Examples:**
```
When the user clicks "Submit", the form shall be validated.
When a new email arrives, the system shall display a notification badge.
When the user logs out, the system shall clear all session data.
When the download completes, the application shall display a confirmation within 1 second.
```

**Key:** Use for normal operations triggered by discrete events

### 4. Optional Feature (Where)
Requirements that apply only when a specific feature is present.

**Syntax:** `Where <feature is included>, the <system name> shall <system response>`

**Examples:**
```
Where two-factor authentication is enabled, the system shall require a verification code.
Where the premium subscription is active, the application shall provide advanced analytics.
Where the API rate limiting module is installed, the system shall enforce 1000 requests per hour.
```

**Key:** Feature must be binary (present/absent), NOT user permissions or runtime states

### 5. Unwanted Behavior (If...Then)
Requirements for error conditions, faults, or exceptions.

**Syntax:** `If <trigger>, then the <system name> shall <system response>`

**Examples:**
```
If an invalid email format is entered, then the system shall display "Invalid email format".
If the password is entered incorrectly three times, then the system shall lock the account for 15 minutes.
If the database connection fails, then the application shall retry every 30 seconds for up to 5 minutes.
If network connection is lost, then the system shall save all unsaved data locally.
```

**Key:** Use for error/fault handling (NOT normal operations)

### 6. Complex (Combined patterns)
Multiple EARS patterns combined for sophisticated scenarios.

**Syntax:** `While <pre-condition(s)>, when <trigger>, the <system name> shall <system response>`

**Examples:**
```
While the user is logged in, when the session exceeds 30 minutes of inactivity, the system shall log out the user.
While connected to external power, when the battery reaches 100%, the system shall switch to trickle charge.
While in edit mode, when the save button is clicked, the application shall commit changes within 2 seconds.
```

---

## Pattern Selection Decision Tree

```
Is the requirement always active?
  → YES → UBIQUITOUS (no keyword)

Does it depend on a continuous state?
  → YES → STATE-DRIVEN (While)

Is it triggered by a discrete event?
  → Normal operation? → EVENT-DRIVEN (When)
  → Error/fault? → UNWANTED BEHAVIOR (If...Then)

Does it only apply to optional features?
  → YES → OPTIONAL FEATURE (Where)

Multiple conditions needed?
  → YES → COMPLEX (combine patterns)
```

---

## Quality Checklist

### Structure
- [ ] Correct EARS pattern used
- [ ] Keywords used properly (While/When/Where/If-Then)
- [ ] Temporal ordering followed (precondition → trigger → system → response)
- [ ] System name is explicit
- [ ] One requirement per statement (one "shall")

### Content
- [ ] Requirement is verifiable/testable
- [ ] All conditions clearly stated
- [ ] Triggers are specific
- [ ] Responses are measurable
- [ ] Units specified for numerical values
- [ ] No vague terms (fast, efficient, user-friendly, appropriate)
- [ ] No escape clauses (if possible, where appropriate)

### Language
- [ ] Active voice used
- [ ] Consistent terminology
- [ ] Grammatically correct

---

## Common Mistakes

| Avoid | Use Instead |
|-------|-------------|
| quickly, fast | within X seconds |
| user-friendly | requiring no more than X clicks |
| efficient | using less than X MB memory |
| The system shall X and Y | Split into two requirements |
| When temperature is high | While temperature exceeds 80°C |
| Data shall be validated | The system shall validate data |
| if possible, where appropriate | Remove escape clause |

---

## Vague Terms to Replace

| Vague | Measurable |
|-------|------------|
| quickly | within 2 seconds |
| efficiently | using less than 50MB RAM |
| user-friendly | requiring no more than 3 clicks |
| reliable | with 99.9% uptime |
| secure | encrypted with AES-256 |
| responsive | responding within 500ms |
