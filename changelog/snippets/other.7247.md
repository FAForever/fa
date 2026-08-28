- Add missing annotations to string functions (#7247).
  
- Point `StringJoin` at `table.concat`, which provides the same behavior (#7247).

- Point `StringStartsWith` at `StringStarts`; the two functions were previously duplicated due to an oversight (#7247).
