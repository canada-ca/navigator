# Navigator - GitHub Copilot Instructions

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

Navigator is a real-time collaborative threat modeling tool built with Elixir/Phoenix LiveView that combines human expertise with generative AI to streamline the security design process.

## Working Effectively

### Prerequisites and Environment Setup
- **CRITICAL**: This project requires Elixir 1.18.4 and Erlang/OTP 27.0.1 (specified in mix.exs)
- **CRITICAL**: Node.js 22.x is required for asset compilation
- **CRITICAL**: PostgreSQL 13+ is required for the database
- Use Docker Compose for development - it handles all dependencies correctly

### Bootstrap and Build Process
**NEVER CANCEL builds or long-running commands. Set timeouts to 60+ minutes.**

#### Native Development Setup
**NOTE**: Requires exact Elixir 1.18.4 and Erlang/OTP 27.0.1. Ubuntu packages provide older versions that cause compatibility issues.

```bash
# Install dependencies and setup database  
make setup
# NEVER CANCEL: Takes 10-25 minutes for initial setup. Set timeout to 45+ minutes.
# Runs: mix deps.get && mix ecto.create && mix ecto.migrate && mix run priv/repo/seeds.exs && cd assets && npm install

# Start development server
make dev  
# Runs: cd valentine && MIX_ENV=dev mix phx.server
# Starts server on http://0.0.0.0:4000
```

**CURRENT LIMITATION**: The system Elixir version (1.14.0) is incompatible with project requirements (1.18.4). Use version managers like asdf or rely on Docker development.

### Testing and Quality Assurance
```bash
# Run the test suite
make test
# NEVER CANCEL: Test suite takes 5-15 minutes. Set timeout to 30+ minutes.
# Runs: cd valentine && mix test

# Run test suite with coverage
make cover  
# NEVER CANCEL: Takes 10-20 minutes. Set timeout to 45+ minutes.
# Runs: cd valentine && mix test --cover

# Format code (ALWAYS run before committing)
make fmt
# Runs: cd valentine && mix format
# Takes < 1 minute

# Install dependencies only
make install
# Runs: cd valentine && mix deps.get
# Takes 2-5 minutes
```

### GitHub Actions CI Requirements
- CI runs: `mix test && mix format --check-formatted`
- **ALWAYS** run `make fmt` before committing or CI will fail
- **ALWAYS** run `make test` to validate changes before pushing
- CI uses PostgreSQL service and sets `DATABASE_URL` and `MIX_ENV=test`

## Manual Validation Scenarios

After making changes, **ALWAYS** perform these validation steps:

### Basic Application Validation
1. Start the application with `make dev`
2. Navigate to `http://0.0.0.0:4000`
3. Verify the main navigation works (Workspaces, Architecture, Data flow, etc.)
4. Create a new workspace to test basic functionality
5. Test the threat modeling features (create threats, assumptions, mitigations)

### Critical User Workflows to Test
1. **Workspace Creation**: Create a new workspace and verify it appears in the list
2. **Data Flow Diagram**: Create and edit a data flow diagram with entities and boundaries (see screenshot example with Lambda, DynamoDB, KMS components)
3. **Architecture Documentation**: Add architecture content using the markdown editor
4. **Threat Analysis**: Generate threat statements using the AI assistant (if OpenAI key provided)
5. **Properties Panel**: Edit component properties, descriptions, and associated threat statements
6. **AI Assistant Integration**: Test the "Ask AI Assistant" functionality for threat analysis
7. **Workspace Dashboard**: Verify threat model analytics display correctly (threat counts, prioritization charts, STRIDE distribution)
8. **Export Functionality**: Test CSV/Excel export features from workspace dashboard

### Expected Application Interface
The application provides a modern web interface with:
- Left sidebar navigation (Workspaces, Architecture, Data flow, Assumptions, Threats, Mitigations, etc.)
- Main content area with interactive diagram editing or dashboard analytics
- Properties panel for selected components
- AI Assistant integration panel on the right
- Toolbar with save, entity, boundary, and view options
- Dashboard with threat statistics, prioritization charts, and STRIDE analysis

### Build Validation
- Application starts without errors
- Database migrations run successfully  
- Static assets compile and load correctly
- LiveView connections establish properly
- No console errors in browser developer tools

## Important Code Locations

### Key Directories
- `valentine/` - Main Elixir application directory
- `valentine/lib/valentine_web/` - Phoenix web interface (controllers, live views)
- `valentine/lib/valentine/` - Business logic and database schemas
- `valentine/assets/` - Frontend assets (CSS, JS, package.json)
- `valentine/test/` - Test suite
- `valentine/priv/repo/` - Database migrations and seeds
- `valentine/config/` - Application configuration

### Common Development Files
- `valentine/mix.exs` - Project dependencies and configuration
- `Makefile` - Build automation commands
- `docker-compose.yml` - Docker development environment
- `.github/workflows/ci_code.yml` - CI pipeline definition
- `valentine/config/dev.exs` - Development configuration
- `valentine/config/test.exs` - Test configuration

### Database Configuration
- Development: `DATABASE_URL=ecto://postgres:postgres@localhost/valentine_dev`
- Test: `DATABASE_URL=ecto://postgres:postgres@localhost/valentine_test`
- Docker: Uses built-in PostgreSQL service

## Troubleshooting Common Issues

### Current Environment Limitations  
- **Dockerfile Build Issues**: Network connectivity problems prevent full Docker builds
- **Elixir Version Mismatch**: System Elixir 1.14.0 vs required 1.18.4 causes compatibility errors
- **Recommended Approach**: Use GitHub Codespaces or setup proper Elixir version management

### Build Issues
- **Elixir version mismatch**: Use Docker Compose, GitHub Codespaces, or install Elixir 1.18.4 with asdf/kiex
- **Docker build failures**: Fix network connectivity issues in Dockerfile or use Codespaces  
- **Database connection errors**: Ensure PostgreSQL is running and accessible
- **Asset compilation failures**: Verify Node.js 22.x is installed
- **Hex/Rebar installation issues**: Run `mix local.hex --force && mix local.rebar --force`

### Runtime Issues  
- **Port 4000 already in use**: Kill existing processes or use different port
- **Database migration errors**: Run `mix ecto.reset` to rebuild database
- **LiveView connection issues**: Check browser console for WebSocket errors

### CI Failures
- **Format check failures**: Run `make fmt` locally before committing
- **Test failures**: Run `make test` locally to debug
- **Build timeouts**: CI may fail if dependencies take too long to download

## Time Expectations and Timeouts

**CRITICAL**: Always use generous timeouts for all build and test commands.

- **Initial Docker build**: 15-45 minutes (set timeout: 60+ minutes)
- **make setup**: 10-25 minutes (set timeout: 45+ minutes)  
- **make test**: 5-15 minutes (set timeout: 30+ minutes)
- **make cover**: 10-20 minutes (set timeout: 45+ minutes)
- **mix deps.get**: 2-5 minutes (set timeout: 15+ minutes)
- **npm install** (assets): < 1 minute (VALIDATED: 0.5 seconds)
- **PostgreSQL startup**: 10-30 seconds (VALIDATED: via Docker)
- **make fmt**: < 1 minute (set timeout: 5+ minutes)
- **Application startup**: 30-90 seconds (set timeout: 5+ minutes)

## Development Workflow

1. **Before making changes**: Run `make test` to ensure baseline functionality
2. **During development**: Use `make dev` for live reloading
3. **Before committing**: Run `make fmt && make test` 
4. **For major changes**: Test end-to-end user scenarios manually
5. **For database changes**: Test migrations with `mix ecto.migrate` and `mix ecto.rollback`

Always validate changes work in both Docker and native environments when possible.