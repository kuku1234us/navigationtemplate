---
parent: "[[TaskMaster]]"
banner: https://www.amitree.com/wp-content/uploads/2021/08/the-pros-and-cons-of-paper-to-do-lists.jpeg
banner_y: 0.237
---
# TaskMaster Line Format Specification

## Overview

The TaskMaster line format is designed to be a unified structure for task management across Obsidian and iOS-based platforms. This specification ensures consistency, flexibility, and compatibility with markdown-based tools and synchronization systems.

## Line Format Syntax

All tasks are listed inside a **task callout** at the beginning of a Project file:

```markdown
> [!task]+ Tasks
> - [ ] Task Name (due:: YYYY-MM-DD) #tag1 #tag2 <span class="priority">PriorityLevel</span> <span class="createTime">UNIX_TIMESTAMP</span>
```

### Elements

1. **Checkbox Status (`- [x]`)**:
   - **Purpose**: Tracks task completion status
   - `[ ]` for not started tasks
   - `[/]` for in-progress tasks
   - `[x]` for completed tasks

2. **Task Name**:
   - **Description**: Core content of the task
   - **Required**: Yes
   - Example: `Write documentation for TaskMaster`

3. **Due Date**:
   - **Format**: `(due:: YYYY-MM-DD)`
   - **Required**: No
   - Example: `(due:: 2024-12-31)`

4. **Tags**:
   - **Format**: Space-separated hashtags
   - **Required**: No
   - Example: `#coding #documentation`

5. **Priority Level**:
   - **Format**: `<span class="priority">Level</span>`
   - **Required**: Yes
   - **Levels** (in descending order):
     - `Urgent`
     - `High`
     - `Normal` (default)
     - `Low`

6. **Creation Time**:
   - **Format**: `<span class="createTime">UNIX_TIMESTAMP</span>`
   - **Required**: Yes
   - **Unit**: Milliseconds since Unix epoch
   - **Purpose**: Serves as unique identifier
   - Example: `<span class="createTime">1703123456789</span>`

## Task Status

### Status Characters
```markdown
[ ] - Not Started (default)
[/] - In Progress
[x] - Completed
```

### Status Transitions
- Tasks can move between any status
- Status changes update the task in the file
- UI provides visual indicators for each status

## Priority System

### Priority Levels
1. **Urgent**
   - Highest priority
   - Color: Red (`UrgentPriorityColor`)

2. **High**
   - Second highest priority
   - Color: Orange (`HighPriorityColor`)

3. **Normal**
   - Default priority level
   - Color: Blue (`NormalPriorityColor`)

4. **Low**
   - Lowest priority
   - Color: Gray (`LowPriorityColor`)

## Example Tasks

```markdown
> [!task]+ Tasks
> - [ ] Write documentation (due:: 2024-01-15) #docs <span class="priority">High</span> <span class="createTime">1703123456789</span>
> - [x] Setup project structure #setup <span class="priority">Urgent</span> <span class="createTime">1703123456790</span>
> - [/] Review pull requests #review <span class="priority">Normal</span> <span class="createTime">1703123456791</span>
> - [ ] Update dependencies #maintenance <span class="priority">Low</span> <span class="createTime">1703123456792</span>
```

## Implementation Details

### Task Creation
- Creation time is automatically set
- Priority defaults to Normal if not specified
- Status defaults to Not Started

### Task Updates
- Preserves task ID (createTime)
- Maintains original formatting
- Updates are written back to file immediately

### Task Parsing
- Regex-based parsing for components
- Maintains whitespace and indentation
- Preserves task callout structure

## CSS Styling

```css
.priority {
    font-weight: bold;
    padding: 2px 4px;
    border-radius: 3px;
}

/* Priority Colors */
.urgent { color: var(--UrgentPriorityColor); }
.high { color: var(--HighPriorityColor); }
.normal { color: var(--NormalPriorityColor); }
.low { color: var(--LowPriorityColor); }

/* Hide createTime in UI */
.createTime {
    display: none;
}
```

## Sorting Capabilities

Tasks can be sorted by:
1. Creation Time (newest first)
2. Priority (descending)
3. Project Selection Order
4. Project Modified Time

Within each sort type, tasks are sub-sorted by:
1. Priority (if not already sorted by priority)
2. Creation Time (newest first)

## Task Structure and Hierarchy

### Indentation Rules
- Task indentation **must** be preserved during all modifications
- Each indentation level represents a parent-child relationship
- Standard indentation is 2 spaces or 1 tab per level
- Example hierarchy:
  ```markdown
  > [!task]+ Tasks
  > - [ ] Parent task <span class="priority">High</span> <span class="createTime">1703123456789</span>
  >   - [ ] Subtask 1 <span class="priority">Normal</span> <span class="createTime">1703123456790</span>
  >   - [ ] Subtask 2 <span class="priority">Normal</span> <span class="createTime">1703123456791</span>
  >     - [ ] Sub-subtask <span class="priority">Low</span> <span class="createTime">1703123456792</span>
  ```

### Task Relationships
1. **Parent Tasks**
   - Can have multiple subtasks
   - Indented at base level
   - Example: `> - [ ] Parent task`

2. **Subtasks**
   - Must be indented under their parent
   - Inherit project context from parent
   - Can have their own subtasks
   - Example: `>   - [ ] Subtask`

3. **Hierarchy Preservation**
   - Task modifications must not alter indentation
   - Moving tasks should maintain their subtask relationships
   - Editing task content preserves its position in hierarchy

### Implementation Requirements
- Parser must capture and preserve indentation
- Updates must maintain original spacing
- Task movements respect parent-child relationships
- Bulk operations preserve entire hierarchical structure

---

