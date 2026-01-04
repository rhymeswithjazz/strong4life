# Project Context

This directory contains project-specific context that should be loaded when working on Strong4Life features.

## Files

- `business-requirements.md` - Business goals, user stories, and constraints
- `architecture.md` - Technical architecture details and design decisions
- `api-documentation.md` - API specifications and endpoint documentation (if applicable)
- `database-schema.md` - Database structure, relationships, and migration notes
- `deployment.md` - Deployment procedures, environments, and infrastructure

## When to Update

- When requirements change
- When architecture evolves
- After major features are added
- During retrospectives or post-mortems
- When deployment procedures change

## Usage

Files in this directory provide **activity-specific context** that should be loaded on-demand when working on related features. For example:

- Load `business-requirements.md` when implementing new features
- Load `database-schema.md` when creating migrations or new schemas
- Load `deployment.md` when setting up CI/CD or deploying

## Creating New Context Files

When creating a new context file:
1. Use clear, descriptive filenames (e.g., `workout-tracking-logic.md`)
2. Keep files focused on a specific aspect of the project
3. Update this README with a description of the new file
4. Use markdown formatting for readability
5. Include creation date and last updated date

---

**Created**: 2026-01-03
**Last Updated**: 2026-01-03
