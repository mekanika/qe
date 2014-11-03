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
