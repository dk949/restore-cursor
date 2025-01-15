# restore.nvim


Simple plugin to restore cursor position after opening a file without using
`mkview`.



## Quick start

To enable the plugin with the default configuration, add this to your
`init.lua`.

```lua
require "restore-cursor" {}.installHandler()
```

## Configuration

By default the plugin does not restore the cursor in buffers used for `git
commit`, `git rebase -i` and `xxd`.

You can configure the plugin to restore or not restore the cursor based on the
file name and type.

> [!NOTE]
> All patterns are treated as regular expressions.


### Ignore

```lua
require "restore-cursor" {
    ignore = {
        filetype_patterns = { "^markdown$" },
        filename_patterns = { [[.*\.txt$]] },
    }
}.installHandler()
```

Supply a list of file type or file name patterns which will be ignored _in
addition_ to the ones ignored by default.

Buffers matched by any pattern in those two lists will not have their cursor
restored.

This example will restore the cursors position in all files except `xxd`, `git
rebase`, `git commit`,  and `markdown` files, and any file ending in `.txt`.

### Override ignore

```lua
require "restore-cursor" {
    override_ignore = {
        filetype_patterns = { "^markdown$" },
        filename_patterns = { [[^.*\.txt$]] },
    }
}.installHandler()
```

These patterns will be ignored and _override_ the ones provided by default.

This example will restore the cursors position in all files except `markdown`
files, and any file ending in `.txt`.

### Only

```lua
require "restore-cursor" {
    only = {
        filetype_patterns = { "^markdown$" },
        filename_patterns = { [[^.*\.txt$]] },
    }
}.installHandler()
```

This example will restore the cursors position in `markdown` files, and any file
ending in `.txt`.


> [!WARNING]
> Use at most one of `ignore`, `override_ignore` or `only`!
