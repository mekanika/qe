0.8.0 - 23 March 2015
=====

Removed: 

- MAJOR: "List" style encoding is now ONLY significantly ordered keyed hashes

Added:

- `any` match operator
- `unset` update operator

Changed:

- `.meta` stability flag and description



0.7.0 - 9 January 2015
=====

Changed:

- Update license to CC-BY-SA (final license)
- Relaxed requirement for additional fields in Qe to 'SHOULD'
- "Falsey" values treated as unset

Added:

- Support for batch updates (multiple ids with multiple body elements)
- Add error if .body and .update act on same field
- Experimental 'Implementing Qe' adapter support clause



0.6.0 - 7 November 2014
=====

Major BREAKING change to significant ordered list.

Changed:

- "field" objects removed descriptors. ie. are now `{$field, $op, $value}`
- `.match` is now an object "match container" `{$bool: [mo|mc...]}`
- Populate objects are now `{$field: {[key:$key] [, query:$qe]}}`
- Offset accepts number or match object (skip + startAt support)
- `action` to `do`
- `resource` to `on`
- `updates` to `update`

Added:

- List/Array structure with significant ordering
- `.match` supports nested conditions

Removed:

- Object hash encoding (no longer an object)



0.5.0 - 6 November 2014
=====

Changed:

- Rename Query objects to: Query envelopes (Qe)
- BREAKING: Revert `match` object to `{field:$f, op:$op, value:$val}`
- BREAKING: Change `update` object to `{field:$f, op:$op, value:$val}`
- BREAKING: Change `populate` object to `{field:$f [,$key] [,$subqo]}`
- Populate subquery objects should be 'find-style' Qo
- BREAKING: `push` and `pull` update operators only work on arrays/list

Added:

- `select` field to replace 'include' and 'exclude'

Removed:

- 'save' reserved `action` type
- `include` and `exclude`



0.4.0 - 4 November 2014
=====

Changed:

- BREAKING: Match object structure changed to `{$field:{$op:$value}}`
- Require 0|1 body element when specifying 1+ `ids` or `match` conditions
- If `ids` are provided, `match` conditions apply only to that subset of ids

Added:

- `populate` field definition
- Stability level for each feature (draft spec helpers)
- Non-idempotent update operators: `push` and `pull`
- Option to extend update types with custom non-idempotent operators
- Match objects may use custom operators
- Match object fields may use "deep matching" through dot notaion: `car.age`

Removed:

- BREAKING: Requirement for Qo to have an `action`
- BREAKING: Idempotent update operators: `set` and `unset`



0.3.0 - 3 November 2014
=====

Major release aimed to simplify the spec. Significant breaking changes.

Added:

- RFC2119 style SHOULD, MUST, etc type definitions

Changed:

- `content` to `body`
- `identifiers` to `ids`
- `display` object flattened out to `limit` and `offset` at root level
- `fields` to `include`
- `excludeFields` to `exclude`
- `modifiers` to `update`
- `constraints` to `match`
- `order` to `sort`
- Sorting is done by strings (not objects) eg. "-age name"

Removed:

- `idField` descriptor
- `rename` modifier/update type



0.2.0 - 16 July 2014
=====

Added:

- `.meta` object field for arbitrary data hash
- _Standard_ actions defined for Qo implementors



0.1.0 - 12 December 2013
=====

Initial release
