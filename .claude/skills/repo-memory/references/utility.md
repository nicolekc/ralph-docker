# Utility commands

## `/repo-memory`

Display the available subcommands with memory counts:

```
list (3)
audit
```

## `/repo-memory list`

List each memory in `REPO_MEM_DIR` in this format:

```
<name>
  age:      <relative mtime>
  location: <path>

  <contents — full body if 5 lines or fewer, a one-sentence summary otherwise>
```

Group by type (from frontmatter).
