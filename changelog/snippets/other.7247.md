- Added missing annotations to string functions (#7247).
  
- `StringJoin` now points to `table.concat`, which provides the same behavior (#7247).

- `StringStartsWith` now points to `StringStarts`; the two functions were previously duplicated due to an oversight (#7247).
