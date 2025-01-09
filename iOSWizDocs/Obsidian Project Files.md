# Obsidian Project Files

## Overview
Project files in the vault are Markdown files that contain project metadata in frontmatter and tasks in a dedicated callout section. They are located in the `Category Notes/Projects` directory.

## File Structure

### Location
- Base Directory: `Category Notes/Projects`
- Files can be in subdirectories for organization
- File Extension: `.md`

### File Components
1. **Frontmatter** (Required)
   ```yaml
   ---
   projId: 1703123456  # Unix timestamp
   banner: https://example.com/banner.jpg  # Optional
   projectStatus: Progress  # Idea, Progress, or Done
   notetype: Project  # Must be "Project"
   icon: inbox.png  # Optional, filename of icon in ObsidianWizSettings/icons/
   ---
   ```

2. **Tasks Section** (Optional)
   ```markdown
   > [!task]+ Tasks
   > - [ ] Task 1 <span class="priority">Normal</span> <span class="createTime">1703123456789</span>
   > - [x] Task 2 <span class="priority">High</span> <span class="createTime">1703123456790</span>
   ```

## Project Icons

### Location
- Directory: `ObsidianWizSettings/icons/`
- Format: PNG files
- Example: `ObsidianWizSettings/icons/inbox.png`

### Icon Usage
1. **In Frontmatter**
   - Specified using the `icon` field
   - Value is the filename only (e.g., `inbox.png`)
   - No URL or path needed

2. **Loading Process**
   - App looks for icons in `ObsidianWizSettings/icons/` directory
   - Icons are cached in memory and on disk
   - Missing icons fallback to folder icon

## Metadata Fields

### Required Fields
- `projId`: Unique identifier (Unix timestamp)
- `notetype`: Must be "Project"
- `projectStatus`: Project state

### Optional Fields
- `banner`: URL to banner image
- `icon`: Filename of project icon

## Task Format

### Task Line Structure
```markdown
- [status] Task name #tags (due:: YYYY-MM-DD) <span class="priority">Priority</span> <span class="createTime">timestamp</span>
```

### Components
- `status`: Space (not started), x (completed), / (in progress)
- `Task name`: Text content
- `tags`: Optional hashtags
- `due date`: Optional due date in YYYY-MM-DD format
- `priority`: Urgent, High, Normal, or Low
- `createTime`: Unix timestamp in milliseconds

### Indentation
- Task indentation must be preserved during modifications
- Indentation level indicates parent-child relationships
- Each level is typically 2 spaces or 1 tab
- Example:
  ```markdown
  > [!task]+ Tasks
  > - [ ] Parent task <span class="priority">High</span> <span class="createTime">1703123456789</span>
  >   - [ ] Subtask 1 <span class="priority">Normal</span> <span class="createTime">1703123456790</span>
  >   - [ ] Subtask 2 <span class="priority">Normal</span> <span class="createTime">1703123456791</span>
  >     - [ ] Sub-subtask <span class="priority">Low</span> <span class="createTime">1703123456792</span>
  ```

### Task Relationships
- Indentation defines task hierarchy
- Parent tasks can have multiple subtasks
- Subtasks inherit the project context of their parent
- Modifying a task must not change its position in the hierarchy

## File Management

### Creation
- Files must be in `Category Notes/Projects` directory
- Must have `notetype: Project` in frontmatter
- Tasks must be under `[!task]+ Tasks` callout

### Modification
- Task updates preserve indentation and formatting
- Project status changes update frontmatter
- Icon changes trigger cache updates

## Example Project File
```markdown
---
projId: 1703123456
banner: https://example.com/banner.jpg
projectStatus: Progress
notetype: Project
icon: project.png
---

> [!task]+ Tasks
> - [ ] Create documentation #docs <span class="priority">High</span> <span class="createTime">1703123456789</span>
> - [x] Setup project (due:: 2023-12-20) <span class="priority">Urgent</span> <span class="createTime">1703123456790</span>
> - [/] Review code #review <span class="priority">Normal</span> <span class="createTime">1703123456791</span>
``` 