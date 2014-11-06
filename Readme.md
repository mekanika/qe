# **Qo** - Query objects

---

> **Status**: This is a _DRAFT_ specification and work in progress.
>
> Each section (and some subsections) are marked with a _Stability_ code explained below:
>
> - 1 - **Experimental**: Recently introduced. Likely to change or be removed.
> - 2 - **Unstable**: Settling but not stable. May change or be removed.
> - 3 - **Stable**: Tested and stable. Only minor changes if any.
> - 4 - **Final**: Unlikely to ever change.

---

_Qo_ are resource oriented **control messages** for APIs.

They do not _do_ anything - they are descriptions consumed by _Qo_-aware APIs to instruct actions, using a _verbs_ (actions) acting on _nouns_ (resources) approach.

Query objects _(Qo)_ seek to:

- provide a _standardised_ description for arbitrary requests
- abstract API 'calls' into discrete transform objects
- act as _control messages_ for your _Qo_-aware API
- describe the 'what', leaving the 'how' to you

An example _Qo_:

```js
{
  action: 'update',
  resource: 'users',
  updates: [
    {field:'credits', op:'inc', value:25}
  ],
  match: [
    {field:'followers', op:'gte', value:100},
    {field:'state', op:'nin', value:['CA']}
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


## Structure

Query objects **MAY** include the following fields:

  - **action** - _String_ `create`, `find`, `update`, `remove`
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
  - **populate** - _Array_ of populate-objects
  - **meta** - _Object_ : arbitrary data hash

A _Qo_ **SHOULD NOT** have any other fields.

The simplest possible _Qo_ is a no-op, represented as an empty object:

    {}


### Serialisation

All examples in this document are shown as Javascript Objects. _Qo_ **MAY** be serialised as JSON.


## Field Details

### .action

> Stability:  3 - **Stable**

Type: **String**

The `action` is a _verb_ that describes the intended process to invoke.

```js
{
  action: 'create',
  resource: 'tags',
  body: [ {label:'sweet'} ]
}
```

The following are reserved action types. An API consuming _Qo_ **SHOULD** handle these defaults:

- **create**: make new
- **find**: locate
- **remove**: delete
- **update**: modify

These action types **SHOULD NOT** be aliased or have their intended meaning altered.

Qo **MAY** specify other (custom) action types.


###.resource

> Stability:  3 - **Stable**

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

> Stability:  3 - **Stable**

Type: **Array** of strings or numbers

An Array of entity IDs to which the `.action` **SHOULD** apply the `.body` or `.updates`. If `ids` are provided, the `.action` **SHOULD** **only** apply to those ids provided.

If `.ids` are provided, `.match` conditions **MUST** apply only to that subset of ids.

Example `.ids` usage:

```js
{
  action: 'remove',
  ids: ['554120', '841042']
}
```


### .body

> Stability:  2 - **Unstable**

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


### .select

> Stability:  1 - **Experimental**
>
> Replacement for `exclude` and `include`

Type: **Array** of strings

Field selector acting _either_ as:

- a **whitelist** of fields to return `["name", "age"]`, or
- a **blacklist** of fields to exclude `["-posts"]`

To act as a blacklist, strings are prepended with a `-`.  Select **SHOULD** only act as a whitelist or a blacklist, not both.

If no `.select` is present, all fields **SHOULD** be returned.


```js
{
  action: 'find',
  resource: 'artists',
  select: [ '-name', '-bio' ]
}
```



### .updates

> Stability:  2 - **Unstable**
>
> **TODO**: Check that update object structure works in real world tests
> Do updates need to support 'deep updates' eg:
> `{field:"users.cars.reviews", op:'push', value:"Great!"}`

Type: **Array** of update objects

Update object format:

```js
{ field:'$field', op:'$op', value: $val }
```

Where:

- `$field` is the name of the field to update
- `$op` is a update operator (see below)
- `$value` is a value of type expected by the field

> **Note**: Update objects have the same format as match objects

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
    {field:'comments', op:'push', value:['13','21']}
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

Reserved update operators are:

- **inc** : modify a scalar Number `field` by the `value` (+ve or -ve).
```js
{field:'price', op:'inc', value:-5}
```

- **push**: array/list operator appends each `value` to the field.
```js
{field:'comment_ids', op:'push', value:['21','45']}
```

- **pull**: array/list operator that removes the `value` from the field.
```js
{field:'comment_ids', op:'pull', value:['3','17']}
```

Qo **MAY** specify other update operators (that **SHOULD** be non-idempotent operators). For example:

```js
// Example of custom operator 'multiply'
{field:'score', op:'multiply', value:3}
```


### .limit

> Stability:  3 - **Stable**

Type: **Number**

Maximum number of results to return.

Assume **no** limit if no present. Qo services **MAY** restrict results anyway.

```js
{ limit: 25 }
```



### .offset

> Stability:  1 - **Experimental**
>
> **TODO**: consider offset vs skip. Are we passing a "Starting at" value or a "skip x" value. Are these different fields? How to represent the difference?

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

> Stability:  2 - **Unstable**

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

> Stability:  2 - **Unstable**
>
> **TODO**: Ensure parsing of new match object structure works well, and test out other types of match operators in object structure constraints.

Type: **Array** of match objects

Used to specify entities that meet matching criteria.

If `.ids` are provided, `.match` conditions **MUST** apply only to that subset of ids.

Match objects take the form:

```js
{ field:'$field', op:'$op', value:$value }
```

Where:

- `$field` is the name of the field to match on
- `$op` is a match operator (see below)
- `$value` is a value of type expected by the operator

Example:

```js
{
  match: [
    {field:'age', op:'gte', value:21},
    {field:'state', op:'in', value:['CA', 'NY']}
  ]
}
```

#### match operators

The current reserved match operators are:

- **eq** - Equals
- **neq** - Not equals
- **in** - In, or, contains (array)
- **nin** - Not in, or, does not contain (array)
- **all** - has all the values (array)
- **lt** - Less than `<`
- **lte** - Less than or equal to `<=`
- **gt** - Greater than `>`
- **gte** - Greater than or equal to `>=`

Qo **MAY** specify alternative custom operators, eg:
```js
// Custom 'within' operator
{match: [
  {
    field:'location',
    op:'within',
    value:['circle', 2100,3000,20]
  }
]}
```

#### Deep matches

> Stability:  1 - **Experimental**
>
> **TODO**: Requires testing in real world use cases

`$field` **MAY** present a dot notation property (eg. `dob.year`) to match on _complex properties_. In this case the match **SHOULD** apply to the sub-property. For example:

```js
// Match users who:
//  - have address.state in 'CA'
//  - and a car in the array of `cars` < 1970
{
  action: 'find',
  resource: 'users',
  match: [
    { field:'address.state', op:'in', value:['CA'] },
    { field:'cars.year', op:'lt', value:1970 }
  ]
}
```

Where a field specifying a sub-property match is typed as an Array (eg. the User's `cars` field above), the match **SHOULD** apply to all elements in the Array. e.g each car is checked if its `.year` property is `< 1970`.


### .populate

> Stability: 1 - **Experimental**

Type: **Array** of populate objects

"Populates" fields that refer to other resources.

The structure of a populate object:

```js
{ field:'$field' [, key:'$key'] [, query: $subqo] }
```

Where:

- `$field` is the field to populate
- `$key` **optional** "foreign key" to associate (usually `id`)
- `$subqo` **optional** Qo conditions

Populate objects **MUST** be unique by `$field`. For example:

```js
{
  populate: [
    {field:'posts'},
    {field:'tags', query:{resource:'Tgz'}}
  ]
}
```

Populate object `$subqo` **MAY** be a blank _Qo_ `{}`,  and **SHOULD** be a "find-style" _Qo_ with the following considerations:

- `.action` **MUST** be interpreted as "find" if not provided
- Other action types **SHOULD** be treated as an error
- Non-"find" type fields, such as `.updates` and `.body` **SHOULD** be ignored and **MAY** be treated as an error

Populate `$subqo` **MAY** nest other `.populate` requests.

Example _Qo_ with populate:

```js
// Find all users, and:
// Populate 'entries' field with no more than 5 posts
// with higher 3 rating, exclude `post.comments`, and
// sub-populate the `post.sites` field
{
  action: 'find',
  resource: 'users',
  populate: [
    {
      field: 'entries',
      query: {
        resource: 'posts',
        match: [{field:'rating', op:'gt', value:3}],
        exclude: ['comments'],
        limit: 5,
        populate: [
        {field: 'sites'}
        ]
      }
    }
  ]
}
```



### .meta

> Stability: 1 - **Experimental**

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

> Stability: 3 - **Stable**

GNU Lesser General Public License, either version 3 of the License, or (at your option) any later version ([LGPL-3.0+](https://www.gnu.org/licenses/lgpl.html)).
