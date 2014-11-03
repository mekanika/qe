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
  resource: 'users',
  action: 'update',
  updates: [
    {set: 'status', value: 'platinum'},
    {inc: 'credits', value: 25}
  ],
  match: [
    {field:'followers', operator:'gte', condition:100},
    {field:'state', operator:'nin', condition:['CA']}
  ],
  include: [ 'id' ]
}
/* Update all users outside of California who have 100
or more followers to 'platinum' status, add 25 credits
to their balance, and return only their ids. */
```


## Structure

The only required parameter in a query is the `action`. As such the simplest _Qo_ would be:

```js
{ action: 'special' }
```

All other parameters are optional and should be handled as such.

### Serialisation

All examples in this document are shown as Javascript Objects. Serialising _Qo_ as JSON is acceptable.

### Parameters

Query objects comprise:

  - **.action** - _String_ (required): `create`, `find`, `update`, `remove`, `save`
  - **.resource** - _String_ : model `key` to query
  - **.body** - _Array_: Data to process
  - **.ids** - _Array_: `ids`
  - **.include** - _Array_: whitelist fields to return
  - **.exclude** - _Array_: blacklist fields to exclude
  - **.updates** - _Array_: specific updates
  - **.match** - _Array_: `where` style query conditions
  - **.limit** - _Number_: number of results to return
  - **.offset** - _Number_ "start at" index value of results to return
  - **.sort** - _Array_ of strings: order on keys
  - **.meta** - _Object_ : arbitrary data hash


## Properties

### .action

**Required** - An action MUST be provided.

Type: **String**

The `action` usually maps to the method that is invoked, but generally describes what "to do".

```js
{
  action: 'create',
  resource: 'tags',
  data: [ {label:'sweet'} ]
}
```

The following are **standard** actions:

- **create**: make new
- **find**: locate. Similar to `read` (a very simple find).
- **remove**: delete
- **update**: partial save. Only passes fields that have changed.
- **save**: idempotent save of entire data structure

These actions should not be aliased or have their intended meaning altered.

The action taxonomy may be extended arbitrarily to provide for alternate and varied functions.


###.resource

Type: **String**

A `resource` points to a unique entity type to act upon, like a table (SQL), a collection (Document stores), a resource (REST). It is almost always a unique reference to some end-point that an `action` will apply to.

Some actions may not use a resource, most do.

```js
{
  resource: 'tweets',
  action: 'find',
  limit: 25
}
```


###.ids

Type: **Array** of strings or numbers

A simple array of entity IDs to which the `.action` should apply the `.data` or `.updates`. If `ids` are provided, the `.action` should **only** apply to those ids provided.

```js
{
  action: 'remove',
  ids: ['554120', '841042']
}
```


### .include

Type: **Array** of strings

Whitelist. Selects the fields from the `.resource` **to return** with the result (rather than returning the entire resource schema). If no `.include` is present, return all fields unless excluded by `.exclude`.

```js
{
  action: 'find',
  resource: 'artists',
  include: [ 'name', 'bio' ]
}
```


### .exclude

Type: **Array** of strings

Blacklist. List of fields NOT to return.

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

Updates are explicit instructions that inform changes to specific _fields_ in an existing resource. If `.updates` are present, the _Qo_ `action` should be `update`.

Example:
```js
{
  action: 'update',
  resource: 'wine',
  ids: ['4jn6014jmns058sa41'],
  updates: [
    {set:'age', value:21},
    {unset:'status'},
    {inc:'price', value:-5}
  ]
}
```

Update types are:

- **set** : set `field` to `value`
```js
{set:'name', value:'Slash'}
```

- **unset** : remove any value from `field` (similar to `set` to `undefined`, but may be implemented differently by various _Qo_-aware APIs)
```js
{unset:'secret'}
```

- **inc** : modify the `field` by the `value` (+ve or -ve)
```js
{inc:'price', value:-5}
```


### .limit

Type: **Number**

Maximum number of results to return.

Assume **no** limit if no present. Adapter may restrict results anyway.



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

Ordering strings take the form: `"[-][$field]"` where the first character may optionally be a `"-"` to indicate reverse sorting, and the `"$field"` may be a text string to sort on.

The empty string `""` indicates a default sort (usually an ascending list sorted by the default key, usually 'id'). A `"-"` string would indicate a descending list sorted on the default key.

As such, the following are valid:

```js
// Only specify a direction to sort results on
{ sort: ["-"] }

// Only specify an index to sort on
{ sort: [ "country" ] }
```

Sub sorting is provided by adding unique parameters to order against:

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


### .body

Type: **Array** of data payloads

Data payloads are usually Objects of arbitrary structure.

`.body` is **always** an Array, even when your payload is only one object. Usually requires applying the action to each object in the array.

```js
{
  action: 'create',
  resource: 'guitars',
  body: [
    {label:'Fender Stratocaster', price:450.75},
    {label:'Parker Fly', price:399.00}
  ]
}
```


### .meta

Type: **Object** of arbitrary data

Meta data store acts as a catch-all for context specific meta information that may need to be attached to a query object message. Think of it like a 'Header' block in an HTTP request.

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
