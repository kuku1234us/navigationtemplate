---
parent: "[[TaskMaster]]"
banner: https://www.amitree.com/wp-content/uploads/2021/08/the-pros-and-cons-of-paper-to-do-lists.jpeg
banner_y: 0.237
---
## Overview

The TaskMaster line format is designed to be a unified structure for task management across Obsidian and iOS-based platforms. This specification ensures consistency, flexibility, and compatibility with markdown-based tools and synchronization systems.

---

## Line Format Syntax

All tasks are listed inside a **task callout** at the beginning of a Project file:

```markdown
> [!task]+ Tasks
> - [ ] Task Name (due:: YYYY-MM-DD) #tag1 #tag2 <span class="priority">PriorityLevel</span><span class="createTime">UNIX_TIMESTAMP</span>
```

### Elements

1. **Checkbox (****`- [ ]`****)**:

   - **Purpose**: Tracks task completion status.
   - `[ ]` for incomplete tasks.
   - `[x]` for completed tasks.

2. **Task Name**:

   - **Description**: Core content of the task.
   - Example: `Write a blog post on TaskMaster format.`

3. **(due:: YYYY-MM-DD)**:

   - **Purpose**: Optional due date field for deadlines.
   - Example: `(due:: 2024-12-31)`.

4. ** #tag1 #tag2**:

   - **Purpose**: Custom tags for classification.
   - Examples: `#computers`, `#review`.

5. **PriorityLevel**:

   - **Purpose**: Indicates task priority.
   - Levels: `urgent`, `high`, `normal`, `low`.
   - Example: `<span class="priority">High</span>`.

6. **createTime**:

   - **Purpose**: Record of the time the task is created. Also serves as an unique identifier for the task.
   - **Implementation**: The Unix timestamp of the task's creation time will serve as the unique ID, hidden with CSS when needed.

---

## Example Tasks

```markdown
> [!task]+ Tasks
> - [ ] Write a blog post on TaskMaster format (due:: 2024-12-20) #tag1 #tag2 <span class="priority">High</span><span class="createTime">1703376000</span>
> - [x] Finalize task management system format (due:: 2024-12-15) #design <span class="priority">Normal</span><span class="createTime">1702944000</span>
> - [ ] Review user feedback (due:: 2024-12-22) #review <span class="priority">Low</span><span class="createTime">1703894400</span>
```

---

## Usage Guidelines

1. **Field Order**:

   - Follow the specified order for compatibility with parsers.

2. **Mandatory Fields**:

   - Include at least the checkbox and task name.

3. **Optional Fields**:

   - Use due dates, tags, priority, and task IDs as needed for additional details.

---

## CSS Snippet for Customization

### Priority Levels

```css
.priority {
  font-weight: bold;
  padding: 2px 4px;
  border-radius: 3px;
}
.priority::before {
  content: "Priority: ";
}
.priority[style*="urgent"] {
  background-color: red;
  color: #f5624c;
}
.priority[style*="high"] {
  background-color: orange;
  color: #ffb238;
}
.priority[style*="normal"] {
  background-color: yellow;
  color: #3e92cc;
}
.priority[style*="low"] {
  background-color: green;
  color: #596873;
}

.createTime {
  display: none;
}
```

---

## Future Enhancements

1. **Subtasks**:
   - Introduce nested task support.
2. **Task Relationships**:
   - Enable parent-child task dependencies.
3. **Advanced Scheduling**:
   - Add recurring task syntax or reminders.

---

