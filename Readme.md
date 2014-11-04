# **Qo** - Query objects

Query objects _(Qo)_ seek to:

- provide a _standardised_ description for arbitrary requests
- abstract API 'calls' into discrete transform objects
- act as _control messages_ for your _Qo_-aware API
- describe the 'what', leaving the 'how' to you

_Qo_ are drivers for APIs. They do not _do_ anything - they are consumed by _Qo_-aware APIs and used to instruct actions.

An example _Qo_:

```js
{
  action: 'update',
  resource: 'users',
  updates: [
    {inc: 'credits', value: 25}
  ],
  match: [
    {field:'followers', operator:'gte', condition:100},
    {field:'state', operator:'nin', condition:['CA']}
  ],
  body: [
    {status: 'platinum'}
  ],
  include: [ 'id' ]
}
/* Update all users outside of California who have 100
or more followers to 'platinum' status, add 25 credits
to their balance, and return only their ids. */
```


## Conventions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](http://tools.ietf.org/html/rfc2119).


### Fields

Query objects **MAY** include the following fields:

  - **action** - _String_ `create`, `find`, `update`, `remove`, `save`
  - **resource** - _String_ query target
  - **ids** - _Array_ of String `ids`
  - **body** - _Array_ of data elements
  - **include** - _Array_ of String whitelist fields to return
  - **exclude** - _Array_ of String blacklist fields to exclude
  - **updates** - _Array_ of specific update objects
  - **limit** - _Number_ of results to return
  - **offset** - _Number_ "start at" index value of results to return
  - **sort** - _Array_ of String keys to sort against
  - **match** - _Array_ of `where` style conditions
  - **meta** - _Object_ : arbitrary data hash

A _Qo_ **SHOULD NOT** have any other fields.

The simplest possible _Qo_ is a no-op, represented as an empty object:

    {}


### Serialisation

All examples in this document are shown as Javascript Objects. _Qo_ **MAY** be serialised as JSON.


## Fields

### .action

Type: **String**

The `action` usually maps to the method that is invoked, but generally describes what "to do".

```js
{
  action: 'create',
  resource: 'tags',
  body: [ {label:'sweet'} ]
}
```

The following are **standard** actions. An API consuming _Qo_ **SHOULD** handle these actions sensibly:

- **create**: make new
- **find**: locate. Similar to `read` (a very simple find).
- **remove**: delete
- **update**: partial save. Only passes fields that have changed.
- **save**: idempotent save of entire data structure

These actions **SHOULD NOT** be aliased or have their intended meaning altered.

The action taxonomy **MAY** be extended arbitrarily to provide for alternate functions.


###.resource

Type: **String**

A `resource` points to a unique entity type to act upon, like a table (SQL), a collection (Document stores), a resource (REST). It is almost always a unique reference to some end-point that an `action` will apply to.

Some actions might _not_ use a resource, most do.

```js
{
  resource: 'tweets',
  action: 'find',
  limit: 25
}
```


###.ids

Type: **Array** of strings or numbers

A simple array of entity IDs to which the `.action` **SHOULD** apply the `.body` or `.updates`. If `ids` are provided, the `.action` **SHOULD** **only** apply to those ids provided.

If `ids` are provided then any `match` conditions **MUST** be ignored.

```js
{
  action: 'remove',
  ids: ['554120', '841042']
}
```


### .body

Type: **Array** of data elements

`.body`is an array containing one or more elements, (usually Objects of arbitrary structure). `.body` **MUST always** be an Array, even when your data payload is only one object.

A Qo `action` **SHOULD** apply to each element in the `.body` array.

_However_, when specifying `.ids` or other `.match` constraints, the `.body` field **MUST** be empty or contain _only one_ element, and the action **SHOULD** apply the data element to `.ids`

```js
// Example create multiple 'guitars'
{
  action: 'create',
  resource: 'guitars',
  body: [
    {label:'Fender Stratocaster', price:450.75},
    {label:'Parker Fly', price:399.00}
  ]
}
```

```js
// Example specifying `ids` field
// (note ONLY one object in body)
{
  action: 'update',
  resource: 'guitars',
  ids: ['12','35'],
  body: [{price: 250.00}]
}
```


### .include

Type: **Array** of strings

Whitelist. Selects the fields from the `.resource` **to return** with the result (rather than returning the entire resource schema). If no `.include` is present, all fields **SHOULD** be returned unless excluded by `.exclude`.

```js
{
  action: 'find',
  resource: 'artists',
  include: [ 'name', 'bio' ]
}
```


### .exclude

Type: **Array** of strings

Blacklist. List of fields that **SHOULD NOT** be returned.

Where both exclude and include are present in a Qo, only `include` is honoured (ie. `exclude` is discarded and ignored).


```js
{
  action: 'find',
  resource: 'guitars',
  exclude: ['price']
}
```


###.updates

Type: **Array** of update objects

Update object format: `{ $type: $field [, value: $val ] }`

Updates are explicit instructions that inform non-idempotent changes to specific _fields_ in an existing resource. If `.updates` are present, the _Qo_ `action` **MUST** be `update`.

Updates **SHOULD** be used for actions that are _NOT idempotent_ (i.e. when identical queries may return different results and/or leave the service in differing states).

These operations would roughly correspond to HTTP `PATCH` requests on resources.

> Note: For `set`/`unset` style operations, simply pass those fields in the `.body` field of the Qo

An example query with an `updates` field:

```js
// Clearly describes an append/"add to" operation
{
  action:'update',
  resource:'users',
  ids:['123'],
  update: [
    {add:'comments', value:['13','21']}
  ]
}
// In HTTP parlance:
// PATCH /users/123
// Content-Type: application/json-patch+json
//
// [
//   {"op":"add","path":"/comments","value":["13","21"]}
// ]

// In default Mongo parlance:
// db.users.update(
//   {_id:'123'},
//   {$push:
//     { "comments": {$each: ["13","21"]} }
//   });
```

Default update types are:

- **inc** : modify a Number `field` by the `value` (+ve or -ve).
```js
{inc:'price', value:-5}
```

- **push**: appends each `value` to the field. Where `field` is:
  - Number: sum the values
  - String: append the value
  - Array: push the values to the end of the array
  - Object: set the field to the value
```js
{push:'comment_ids', value:['21','45']}
```

- **pull**: removes the `value` from the field. Where `field` is:
  - Number: subtract the value
  - String: _Error_
  - Array: remove the values from the array
  - Object: _Error_
```js
{pull:'comment_ids', value:['3','17']}
```

Qo **MAY** specify other update types (that **SHOULD** be non-idempotent operators). For example:

```js
{multiply:'score', value:3}
```


### .limit

Type: **Number**

Maximum number of results to return.

Assume **no** limit if no present. Adapter **MAY** restrict results anyway.



### .offset

Type: **Number**

Number of results to skip (ie. start from the `offset`)

Assume **no** offset if none present.

```js
// For a set of possible records:
['a','b','c']

{offset:0}
// -> ['a','b','c']

{offset:1}
// -> ['b','c']
```



### .sort

Type: **Array** of strings

Ordering strings take the form: `"[-][$field]"` where the first character **MAY** optionally be a `"-"` to indicate reverse sorting, and the `"$field"` **MAY** be a text string to sort on.

The empty string `""` indicates a default sort (usually an ascending list sorted by the default key, usually 'id'). A `"-"` string would indicate a descending list sorted on the default key.

As such, the following are valid:

```js
// Only specify a direction to sort results on
{ sort: ["-"] }

// Only specify an index to sort on
{ sort: [ "country" ] }
```

Sub sorting is provided by adding parameters to order against. These parameters **SHOULD** be unique.

```js
{
  sort: [
    "-age", "name"
  ]
}
// Descending `age`, and ascending `name` for same age
```



### .match

> **Warning:** this section is under review and may introduce breaking changes in future versions

Type: **Array** of match objects

Matching conditions take the form: `{ field: $, operator: $, condition: $ }`

```js
{
  resource: 'users',
  match: [
    { field: 'cars.age', operator: 'lt', condition: 48 },
    { field: 'state', operator: 'in', condition: ['CA','NY','WA'] }
  ]
}
```

The condition operators are:

- **eq** - Equals
- **neq** - Not equals
- **in** - In, or, contains (array)
- **nin** - Not in, or, does not contain (array)
- **all** - has all the values (array)
- **lt** - Less than `<`
- **lte** - Less than or equal to `<=`
- **gt** - Greater than `>`
- **gte** - Greater than or equal to `>=`

> Note: `match` conditions are _ignored_ if `ids` are provided



### .meta

Type: **Object** of arbitrary data

Meta data store acts as a catch-all for context specific meta information that may need to be attached to a query object message. Think of it like a 'Header' block in an HTTP request. **MAY** contain arbitrary data.

```js
{
  action: 'update',
  resource: 'guitars',
  ids: ['11523'],
  body: [ {price:50} ],
  meta: {
    _authToken: 'xyzqwerty098'
  }
}
```



## License

GNU Lesser General Public License, either version 3 of the License, or (at your option) any later version ([LGPL3+](https://www.gnu.org/licenses/lgpl.html)).
