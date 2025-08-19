# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Problem Solving and User Approval Rules

### User Approval at Critical Decision Points
- When encountering a problem or after a failed attempt, ALWAYS ask for user approval before switching to an alternative solution
- If there are multiple paths to achieve the main goal, present all options to the user and ask for their preference before choosing the easier path
- Specifically require approval in these situations:
  - When deciding to simplify or remove a feature
  - When switching to a different library or approach
  - When implementing workarounds for debugging
  - When compromising on performance or security requirements

### Behavior When Facing Problems
- When the first attempt fails:
  1. Explain the problem and its cause
  2. Present at least 2-3 alternative solutions
  3. List pros and cons for each
  4. Ask "How would you like me to proceed?"
  5. WAIT for user response

### Prohibited Behaviors
- ❌ DO NOT say "This doesn't work, let's do this instead" and switch directly to an alternative
- ❌ DO NOT simplify user's requested feature by calling it "complex"
- ❌ DO NOT automatically try a different approach after receiving an error
- ❌ DO NOT deviate from the original request by saying "There's an easier way"

### Approval Request Format
When encountering a problem, request approval in this format:
"""
🔔 APPROVAL REQUIRED:
Problem: [Description of the issue encountered]
Options:
1. [First solution] - Difficulty: X/5
2. [Second solution] - Difficulty: Y/5  
3. [Third solution] - Difficulty: Z/5

Which approach would you prefer? (1/2/3 or another suggestion)
"""

### Persistence and Commitment
- Remain committed to the original goal unless explicitly told otherwise
- If the harder path aligns better with the original requirements, recommend it
- Don't assume the user wants the quickest solution - they may prefer the most robust one

## ⚠️ CRITICAL: DATABASE WARNING ⚠️

**NEVER CREATE A NEW DATABASE** - The database `personax_app` already exists with production data!
- Database name: `personax_app` (NOT `relate_coach` or any other name)
- Contains 832 assessment items across 4 forms (S1_self, S2R_*, S3_self, S4_*)
- Migration already completed - DO NOT re-run unless specifically needed
- Use PM2 for process management (already configured)

### Known Issue That Caused Data Loss
On 17 Aug 2025, wrong CSV file (`testbank.csv`) was imported instead of the correct split files:
- **WRONG**: `testbank.csv` (only 123 items, missing Validity section)
- **CORRECT**: Use these files in order:
  1. `s1_self.csv` (60 items including Validity section)
  2. `s2_relation_forms.csv` (680 items)
  3. `s3_type_check.csv` (12 items)
  4. `s4_values_boundaries.csv` (80 items)

## Project Overview

This is a **Relate Coach** global multi-language platform combining:
- **Backend**: Node.js/Express + PostgreSQL + OpenAI integration
- **Frontend**: Expo (React Native) for iOS/Android/Web single codebase
- **AI Features**: Personality analysis with self/other/dyad/coach modes
- **Multi-Language Support**: 15+ languages for global audience
- **Language Safety**: Automatic language detection with GPT-5-mini, 2x retry mechanism

## 🚀 FIRST COMMAND TO RUN (Session Start)


**When returning to this project, ALWAYS run this health check first:**
```bash
# This command checks system status without making changes
cd /var/www/personax.app && \
echo "=== System Health Check ===" && \
pm2 status && \
echo -e "\n=== Database Check ===" && \
export PGPASSWORD=postgres && \
psql -h localhost -U postgres -d personax_app -c "SELECT COUNT(*) as total_items, form FROM items GROUP BY form ORDER BY form;" && \
echo -e "\n=== Services Check ===" && \
curl -s http://localhost:8080/health && echo " - Backend API ✓" && \
curl -s http://localhost:8081 > /dev/null && echo "Frontend Expo ✓" || echo "Frontend needs restart" && \
echo -e "\n=== Website Status ===" && \
curl -sI https://personax.app | head -1
```

If any service is down, use: `pm2 restart all`

## Commands

### Backend Development
```bash
# Server setup and database
cd server
npm install
npm run migrate                                    # Initialize PostgreSQL schema
npm run seed:items ../data/testbank.csv           # Import assessment items
npm run dev                                        # Start dev server (port 8080)
npm run build                                      # Build TypeScript to dist/

# Quick setup (migration + seed)
npm run setup:dev
```

### Frontend Development
```bash
# Expo app
cd apps/expo
npm install
npm run web                                        # Web development
npm run ios                                        # iOS simulator
npm run android                                    # Android emulator
```

### Testing & Validation
```bash
# Server health check
curl http://localhost:8080/health

# Test endpoints with proper headers
curl -X POST http://localhost:8080/v1/analyze/self \
  -H "Content-Type: application/json" \
  -H "x-user-lang: tr" \
  -H "x-user-id: test-user"
```

## Architecture

### Server Structure (`/server/src/`)
- **`/ai/`**: OpenAI integration and analysis pipeline
  - `pipeline.ts`: Main orchestration for all analysis types
  - `providers/openai.ts`: OpenAI API client wrapper
- **`/prompts/`**: AI prompt templates (self.md, other.md, dyad.md, coach.md)
- **`/db/`**: Database layer
  - `pool.ts`: PostgreSQL connection pool
  - `migrations/001_init.sql`: Database schema
  - `seed/import-items.ts`: CSV import for assessment items
- **`/routes/`**: Express API endpoints
  - POST `/v1/analyze/self` - Self personality analysis
  - POST `/v1/analyze/other` - Other person analysis
  - POST `/v1/analyze/dyad` - Relationship dynamics
  - POST `/v1/coach` - Coaching advice
  - GET `/v1/admin/language-incidents` - Language safety logs
- **`/config/`**: Environment configuration

### Database Schema
- **`assessment_items`**: Personality assessment questions
- **`language_incidents`**: Failed language detection logs
- **`analysis_logs`**: User analysis history tracking

### AI Pipeline Flow
1. Request arrives with user language header (`x-user-lang`)
2. Analysis runs with appropriate prompt template
3. Language validation with GPT-5-mini (2 retry attempts)
4. On language mismatch: log incident, return error
5. On success: return analysis in requested language

### Frontend Structure (`/apps/expo/`)
- **Single codebase** for iOS, Android, and Web using Expo
- React Native components with platform-specific optimizations
- API integration with backend endpoints

## Environment Setup

Required `.env` file (see `.env.example`):
```
NODE_ENV=development
PORT=8080
DATABASE_URL=postgres://USER:PASSWORD@HOST:5432/relate_coach
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxx
DEFAULT_LOCALE=en
SUPPORTED_LOCALES=en,es,fr,de,it,pt,nl,ru,zh,zh-TW,ja,ko,ar,tr,hi
```

## Key Development Patterns

### Multi-Language Protocol
- Support for 15+ languages globally
- All responses validated against requested language
- Automatic detection using GPT-5-mini
- 2x retry on language mismatch
- Incident logging for admin review
- Fallback to English if requested language unavailable

### API Headers
- `x-user-lang`: User's preferred language (default: 'en')
  - Supported: en, es, fr, de, it, pt, nl, ru, zh, zh-TW, ja, ko, ar, tr, hi
- `x-user-id`: User identifier (default: 'anon')
- `Content-Type: application/json` for all POST requests

### Error Handling
- Language mismatches return specific error codes
- All database operations use connection pooling
- Express middleware for JSON parsing with 2MB limit

## AI Agent Systems (Two Separate Systems)

### 1. Claude-Flow Agents (Generic Development)
Used for general development tasks via MCP tools:
- `npx claude-flow sparc tdd` - TDD workflows
- `mcp__claude-flow__swarm_init` - Swarm coordination
- Generic agents: coder, tester, planner, researcher

### 2. Relate Coach Custom Agents (`/agents/`)
Project-specific agents with "rc-" prefix to avoid conflicts:

1. **rc-orchestrator.md** - Master coordinator for Relate Coach tasks
2. **rc-backend-architect.md** - Node.js/Express API design
3. **rc-typescript-specialist.md** - Advanced TypeScript patterns
4. **rc-react-native-expert.md** - Cross-platform mobile/web with Expo
5. **rc-database-specialist.md** - PostgreSQL multi-language optimization
6. **rc-ai-integration-expert.md** - OpenAI API and prompt engineering
7. **rc-code-reviewer.md** - Security and performance review
8. **rc-test-engineer.md** - Test automation strategies

### When to Use Which System

**Use Claude-Flow for:**
- Generic coding tasks
- SPARC methodology
- General testing
- Basic planning

**Use RC Custom Agents for:**
- Multi-language features
- Personality assessment logic
- Database schema design
- OpenAI integration
- React Native UI
- Project-specific architecture

### Usage Examples
```bash
# Generic task (Claude-Flow)
npx claude-flow sparc tdd "authentication"

# Relate Coach specific (Custom Agent)
Task("rc-database-specialist: Design 15-language schema")
Task("rc-ai-integration-expert: Optimize personality prompts")
```

### Agent Configuration
- All RC agents use `opus` model
- Prefixed with "rc-" to prevent conflicts
- Full tool access for their domain
- Multi-language awareness built-in

## Common Tasks

### Adding New Analysis Types
1. Create prompt template in `/server/src/prompts/`
2. Add pipeline function in `/server/src/ai/pipeline.ts`
3. Create route handler in `/server/src/routes/index.ts`
4. Update frontend to call new endpoint

### Modifying Assessment Items
1. Update CSV file in `/data/`
2. Re-run seed command: `npm run seed:items ../data/file.csv`
3. Verify in database: `psql $DATABASE_URL -c "SELECT * FROM assessment_items LIMIT 5;"`

### Debugging Language Issues
1. Check incidents: `GET /v1/admin/language-incidents`
2. Review `language_incidents` table for patterns
3. Adjust prompt templates if needed

## 📁 Critical Project Files & Structure

### Database Data Files (DO NOT DELETE OR OVERWRITE)
```
/var/www/personax.app/data/
├── s1_self.csv          # 60 items - Self assessment with Validity section
├── s2_relation_forms.csv # 680 items - Relationship assessments
├── s3_type_check.csv     # 12 items - Type check questions
├── s4_values_boundaries.csv # 80 items - Values/boundaries
└── testbank.csv         # OLD FILE - DO NOT USE (missing Validity)
```

### Process Management
```
/var/www/personax.app/
├── ecosystem.config.js   # PM2 configuration - DO NOT DELETE
├── monitor.sh           # Health check script (runs every 5 min via cron)
└── logs/               # Application logs directory
```

## 🎨 UI/UX Stil Kuralları

### Genel Stil Kuralları
- **Border Radius:** TÜM elementlerde `borderRadius: 3` kullanılmalı
- **Ana Renkler:**
  - Primary Blue: `rgb(66, 153, 225)` - Seçili butonlar ve vurgular
  - Section Header Dark: `rgb(45, 55, 72)` - Section başlıkları arka planı
  - Background Gray: `rgb(244, 244, 244)` - Input arka planları
  - Text Black: `rgb(0, 0, 0)` - Ana metin rengi
  - White: `#FFFFFF` - Seçili buton metinleri ve section başlık yazıları

### Component Stilleri
```javascript
// Section Başlıkları
sectionDivider: {
  backgroundColor: 'rgb(45, 55, 72)',
  paddingVertical: 8,
  paddingHorizontal: 16,
  marginBottom: 16,
  marginTop: 8,
  borderRadius: 3,
}

sectionDividerText: {
  color: '#FFFFFF',
  fontSize: 14,
  fontWeight: '600',
}

// Seçim Butonları
choiceButton: {
  paddingHorizontal: 16,
  paddingVertical: 10,
  borderWidth: 1,
  borderColor: '#E5E7EB',
  borderRadius: 3,
  backgroundColor: '#FFFFFF',
  flexShrink: 1,  // Mobilde taşmayı önler
  minWidth: 0,     // Mobilde taşmayı önler
}

choiceButtonSelected: {
  backgroundColor: 'rgb(66, 153, 225)',
  borderColor: 'rgb(66, 153, 225)',
}

// Input Alanları
textInput: {
  borderWidth: 1,
  borderColor: '#E5E7EB',
  borderRadius: 3,
  padding: 12,
  fontSize: 14,
  backgroundColor: 'rgb(244, 244, 244)',
  color: 'rgb(0, 0, 0)',
}

// Likert Ölçeği
likertOption: {
  flex: 1,
  paddingVertical: 10,
  borderWidth: 1,
  borderColor: '#E5E7EB',
  borderRadius: 3,
  alignItems: 'center',
  backgroundColor: '#FFFFFF',
}

likertOptionSelected: {
  backgroundColor: 'rgb(66, 153, 225)',
  borderColor: 'rgb(66, 153, 225)',
}
```

### Mobil Uyumluluk
- Uzun metinler için `flexWrap: 'wrap'` ve `flexShrink: 1` kullan
- Minimum genişliği `minWidth: 0` olarak ayarla
- Text elementlerinde `textAlign: 'center'` kullan

### Current System State
- **Database**: `personax_app` with 832 items total
- **Backend**: Running on port 8080 (managed by PM2)
- **Frontend**: Running on port 8081 (managed by PM2)
- **Process Manager**: PM2 with auto-restart on crash/memory limit
- **Monitoring**: Cron job every 5 minutes checking health
- **Form Names**: S1_self, S2R_{relation}, S3_self, S4_{domain}