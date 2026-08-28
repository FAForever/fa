- Added missing annotations to string functions (#7247).
  
- `StringJoin` now points to `table.concat`. Since that's exactly what it did (#7247).

- `StringStartsWith` points directly to `StringStarts` since one of them is duplicate due oversight of existing function by someone in the past (#7247).
