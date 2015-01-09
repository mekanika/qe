# **Qe** - Query envelopes

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

_Qe_ are resource oriented **control messages** for APIs.

_Qe_ do not _do_ anything - they are descriptions consumed by _Qe_-aware APIs to instruct actions, using a _verbs_ (actions) acting on _nouns_ (resources) approach.

Query envelopes _(Qe)_ seek to:

- provide a _standardised_ description for arbitrary requests
- act as _control messages_ for _Qe_-aware API
- abstract API 'calls' into discrete state/transform objects
- describe the "what", leaving the "how" to implementation

Useful reference projects:

  - **[Query](https://github.com/mekanika/query)** - library to **generate** valid _Qe_
  - **[Adapter](https://github.com/mekanika/adapter)** - base class for **parsing and consuming** _Qe_.

An example _Qe_:

```js
/* Update all users outside of California who have 100
or more followers to 'platinum' status, add 25 credits
to their balance, and return only their ids. */

// Qe - ordered list in JSON:
["update","users",null,{"and":[{"followers":{"gte":100}},{"state":{"nin":["CA"]}}]},[{"status":"platinum"}],[{"credits":{"inc":25}}],["id"]]

// And exploded in an object hash format:
{
  do: 'update',
  on: 'users',
  match: {
    'and': [
      {followers: {gte:100}},
      {state: {nin:['CA']}}
      ]
  },
  body: [
    {status: 'platinum'}
  ],
  update: [
    {credits: {'inc':25}}
  ],
  select: [ 'id' ]
}
```


## Conventions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](http://tools.ietf.org/html/rfc2119).


## Structure

> Stability: 3 - **Stable**
>
> Active questions regarding **encoding** (either as object hash, ordered list or sparse object. [Discussion ongoing.](https://github.com/mekanika/qe/issues/5)
>
> _Key point_: The **structure** and order of _Qe_ is looking solid. Has been decently implemented in [`query`](https://github.com/mekanika/query/) and is undergoing integration tests against the Fixture adapter.

The structure of a Query envelope is described below, according to:

`position`: **field** - _type_ description

The core action "do _verb_ on _noun_" block:

  - `0`: **do** - _String_ `create`, `find`, `update`, `remove`
  - `1`: **on** - _String_ resource target

Matching resources:

  - `2`: **ids** - _Array_ of String or Number `ids`
  - `3`: **match** - _Object_ match container of match object conditions

Data block:

  - `4`: **body** - _Array_ of data elements
  - `5`: **update** - _Array_ of update objects

Return controls:

  - `6`: **select** - _Array_ of String fields to return or exclude
  - `7`: **populate** - _Array_ of populate objects

Results display:

  - `8`: **limit** - _Number_ of results to return
  - `9`: **offset** - _Number_ OR match _Object_ index to start results
  - `10`: **sort** - _Array_ of String keys to sort against

And custom data:

  - `11`: **meta** - _Object_ : arbitrary data hash

A _Qe_ **SHOULD NOT** have any other fields.

The simplest possible _Qe_ is an empty envelope (no-op).

### Encoding

> Stability: 1 - **Experimental**
>
> The `Query` library stores an **object hash** and can convert to an **ordered list** (currently recommended below). The `Adapter` integration tests end up serialising against the object hash. More tests are required for real use cases.

Query envelopes are significantly ordered lists of fields with a maximum length of 12. Each position is described by a field in the 'Structure' section of this document.

_Qe_ in this spec are explained by being shown in a deserialised 'object hash' format for ease of comprehension. Object hashes _ARE NOT_ Query envelopes, but may be collapsed to _Qe_.

An empty list:

    [] // no-op
    [,,,,] // no-op
    [,,,,,,,,,,,] // no-op
    [,,,,,,,,,,,,] // ERROR - 13 fields. Invalid Qe.

Empty fields are treated as being 'unset'.

    ['find','jam',,,,,['title']]

Trailing empty fields are **RECOMMENDED** to be omitted, however _Qe_ **MAY** pass all fields (even if empty):

    ['find','jam',,,,,['title'],,,,,]



### Serialisation

All examples in this document are shown as Javascript primitives.

_Qe_ **MAY** be serialised as JSON.


## Qe field details

> **Important:** (a note about "index")
>  The index number refers to the Javascript-style **array index**. `0` is thus the _first_ element, `3` is the _fourth_ etc. Index `5` DOES NOT mean the fifth element, it refers to the element at **index** `5` (which, of course, is the _sixth_ element).


### index: **`0`** - ".do"

> Stability:  4 - **Final**

Type: **String**

The `do` field is a _verb_ that describes the intended process to invoke.

```js
// Object hash:
{
  do: 'create',
  on: 'tags',
  body: [ {label:'sweet'} ]
}

// Qe:
['create','tags',,,[{label:'sweet'}]]
```

The following are reserved action types. An API consuming _Qe_ **SHOULD** handle these defaults:

- **create**: make new
- **find**: locate
- **remove**: delete
- **update**: modify

These action types **SHOULD NOT** be aliased or have their intended meaning altered.

Qe **MAY** specify other (custom) action types.



### index:**`1`** - ".on"

> Stability:  4 - **Final**

Type: **String**

The `.on` field points to a unique entity type to act upon, like a table (SQL), a collection (Document stores), a resource (REST). It is almost always a unique reference to some end-point that a `.do` field will apply to.

_Qe_ **MAY** omit `.on`, as some actions might _not_ act `.on` anything. eg. `{do:'self_destruct', meta:{secret:'☃'}}`.

Example `.on` usage:

```js
// Object hash:
{
  do: 'find',
  on: 'tweets',
  limit: 25
}

// Qe:
['find','tweets',,,,,,,25]
```



### index: **`2`** - ".ids"

> Stability:  3 - **Stable**

Type: **Array** of strings or numbers

An Array of entity IDs to which the `.action` **SHOULD** apply the `.body` or `.update`. If `.ids` are provided, the `.do` action **SHOULD** **only** apply to those ids provided.

If `.ids` are provided, `.match` conditions **MUST** apply only to that subset of ids.

Example `.ids` usage:

```js
// Object hash:
{
  do: 'remove',
  ids: ['554120', '841042']
}

// Qe:
['remove',,['554120','841042']]
```



### index: **`3`** - ".match"

> Stability:  2 - **Unstable**

Type: match container **Object**

`.match` is used to conditionally specify entities that meet matching criteria. If `.ids` are provided, `.match` **MUST** apply only to that subset of ids.

A match _container_ object (`mc`) is defined as:

```js
{ '$boolOp': [ mo|mc...  ] }
```

Where:

- `$boolOp` is a boolean operator eg. `and`, `or`, etc
- `mo` is a match object (defined below)
- `mc` is a match container (defined here)

An `mc` **MUST** contain only one `$boolOp`.  `mc` **MAY** contain match objects as well as nested `mc` (for nesting matches).

Match objects take the form:

```js
{ $field: {'$op':$value} }
```

Where:

- `$field` is the name of the field to match on
- `$op` is a match operator (see below)
- `$value` is a value of type expected by the operator

Example:

```js
// Match people in CA and NY over 21 or anyone in WA
// Object hash:
{
  match: {
    'or': [
      {'and': [
       {age: {gt:21}},
       {state: {in:['CA', 'NY']}}
      ]},
      {state: {eq:'WA'}}
    ]
  }
}

// Qe:
[,,,{'or':[{'and':[{age:{gt:21}},{state: {in:['CA', 'NY']}}]},{state: {eq:'WA'}}]}]
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

These operators **SHOULD NOT** be aliased or have their intended meaning altered.

Qe **MAY** specify alternative custom operators, eg:

```js
// Custom 'within' operator
{match: {
  'or': [
    {location:{'within':['circle', 2100,3000,20]}
    ]
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
// Object hash:
{
  do: 'find',
  on: 'users',
  match: {
    or: [
      { 'address.state': {in:['CA']} },
      { 'cars.year': {lt:1970} }
    ]
  }
}

// Qe:
['find','users',,{or:[{'address.state':{in:['CA']}},{ 'cars.year':{lt:1970}}]}]
```

Where a field specifying a sub-property match is typed as an Array (eg. the User's `cars` field above), the match **SHOULD** apply to all elements in the Array. e.g each car is checked if its `.year` property is `< 1970`.




### index: **`4`** - ".body"

> Stability:  3 - **Stable**

Type: **Array** of data elements

`.body`is an array containing one or more elements (usually Objects of arbitrary structure). `.body` **MUST always** be an Array, even when your data payload is only one object.

Elements in `.body` **SHOULD** be treated as sparse objects, and only apply the keys supplied. 

```js
// Example update all guitars:
// - set `onSale` field to `true`
// - set `secretKey` to `undefined` (unset)
{
  do: 'update',
  on: 'guitars',
  body: [{onSale: true, secret:undefined}]
}
```

> Qe implementations **MAY** treat element fields set to `undefined` as an 'UNSET' command for schema-less stores.

A Qe `.do` action **SHOULD** apply to each element in the `.body` array.

_However_, when specifying `.ids` or other `.match` constraints, the `.body` field **MUST** be empty or contain _only one_ element, and the action **SHOULD** apply the data element to `.ids`

```js
// Example create multiple 'guitars'
// Object hash:
{
  do: 'create',
  on: 'guitars',
  body: [
    {label:'Fender Stratocaster', price:450.75},
    {label:'Parker Fly', price:399.00}
  ]
}

// Qe:
['create','guitars',,,[{label:'Fender Stratocaster', price:450.75},{label:'Parker Fly', price:399.00}]]
```

```js
// Example specifying `ids` field
// (note ONLY one object in body)
// Object hash:
{
  do: 'update',
  on: 'guitars',
  ids: ['12','35'],
  body: [{price: 250.00}]
}

// Qe:
['update','guitars',['12','35'],,[{price:250.00}]]
```



### index: **`5`** - ".update"

> Stability:  2 - **Unstable**
>
> Do updates need to support 'deep updates' eg:
> `{"users.cars.reviews":{push::"Great!"}}`

Type: **Array** of update objects

Update object format:

```js
{ '$field': {'$op': $val} }
```

Where:

- `$field` is the name of the field to update
- `$op` is a update operator (see below)
- `$value` is a value of type expected by the field

> **Note**: Update objects have the same format as match objects

Updates are explicit instructions that inform **non-idempotent** changes to specific _fields_ in an existing resource. If `.update` is present, the _Qe_ `do` action **MUST** be `'update'`.

> Note: For idempotent `set`/`unset`style operations, simply pass those fields in the `.body` field of the Qe

An example query with an `.update` field:

```js
// Clearly describes an append/"add to" operation
// Object hash
{
  do:'update',
  on:'users',
  ids:['123'],
  update: [
    { comments: {push:['13','21']} }
  ]
}

// Qe:
['update','users',['123'],,,[{comments: {push:['13','21']}}]]

// In HTTP parlance:
// PATCH /users/123
// Content-Type: application/json-patch+json
//
// [
//   {"op":"add","path":"/comments","value":["13","21"]}
// ]

// In Mongo parlance:
// db.users.update(
//   {_id:'123'},
//   {$push:
//     { "comments": {$each: ["13","21"]} }
//   });
```

Reserved update operators are:

- **inc** : modify a scalar Number `field` by the `value` (+ve or -ve).
```js
{price: {inc:-5}}
```

- **push**: array/list operator appends each `value` to the field.
```js
{comment_id: {push:['21','45']}}
```

- **pull**: array/list operator that removes the `value` from the field.
```js
{comment_ids: {pull:['3','17']}}
```

These operators **SHOULD NOT** be aliased or have their intended meaning altered.

Qe **MAY** specify other update operators (that **SHOULD** be non-idempotent operators). For example:

```js
// Example of custom operator 'multiply'
{score: {multiply:3}}
```



### index: **`6`** -  ".select"

> Stability:  3 - **Stable**

Type: **Array** of strings

Field selector acting _either_ as:

- a **whitelist** of fields to return `["name", "age"]`, or
- a **blacklist** of fields to exclude `["-posts"]`

To act as a blacklist, strings are prepended with a `-`.  Select **SHOULD** only act as a whitelist or a blacklist, not both.

If no `.select` is present, all fields **SHOULD** be returned.


```js
// Object hash:
{
  do: 'find',
  on: 'artists',
  select: [ '-name', '-bio' ]
}

// Qe:
['find','artists',,,,,,['-name','-bio']]
```



### index: **`7`** - ".populate"

> Stability: 2 - **Unstable**

Type: **Object** - a hash of keys populate objects

Populates fields that refer to other resources.

The structure of the `.populate` field:

```js
{ $field: { [key:'$key'] [, query:$subqe] } }
```

Where:

- `$field` is the field to populate
- `$key` **optional** "foreign key" to associate (usually `id`)
- `$subqe` **optional** Qe conditions

Populate objects **MUST** be unique by `$field`. For example:

```js
{
  populate: {
    'posts':{},
    'tags': {query:{resource:'Tgz'}}
  }
}
```

Populate object `$subqe` **MAY** be a blank _Qe_ `[]`,  and **SHOULD** be a "find-style" _Qe_ with the following considerations:

- `.do` action **MUST** be interpreted as "find" if not provided
- Other action types **SHOULD** be treated as an error
- Non-"find" type fields, such as `.update` and `.body` **SHOULD** be ignored and **MAY** be treated as an error

Populate `$subqe` **MAY** nest other `.populate` requests.

Example _Qe_ with populate:

```js
// Find all users, and:
// Populate 'entries' field with no more than 5 posts
// with higher 3 rating, exclude `post.comments`, and
// sub-populate the `post.sites` field
// Object hash:
{
  do: 'find',
  on: 'users',
  populate: {
    entries: {
      query: {
        on: 'posts',
        match: { or: [ {rating:{gt:3}} ] },
        select: ['-comments'],
        limit: 5,
        populate: {
          sites:{}
        }
      }
    }
  }
}

// Qe:
["find","users",,,,,,{entries:{query:{on:"posts",match:{or:[{rating:{gt:3}}]},select:["-comments"],limit:5,populate:{sites:{}}}}}]
```




### index: **`8`** - ".limit"

> Stability:  3 - **Stable**

Type: **Number**

Maximum number of results to return.

Assume **no** limit if none specified. Qe services **MAY** restrict results anyway.

```js
// Object hash:
{ limit: 25 }

// Qe:
[,,,,,,,,25]
```



### index: **`9`** - ".offset"

> Stability:  2 - **Unstable**

Type: **Number** or match object **Object**

`.offset` enables two methods of modifying the index at which results are returned. When set as a:

- **Number** - acts as "skip" (ie. jump over the first 'x' results)
-  **match Object** - acts as a "start at" index using the format `{field: {op:value}}`. The operator **SHOULD** be `eq` and the 'field' is recommended to be `id`.

Offset **SHOULD** be used in combination with a "find" style `.do` action.

Assume **no** offset if none present.

```js
// For a set of possible records:
['a','b','c']

{offset:0}
// -> ['a','b','c']

{offset:1}
// -> ['b','c']

// Qe:
['find',,,,,,,,,1]

// As 'startAt' style:
{offset: {id: {eq:'1234'}}}
// Qe:
[,,,,,,,,,{id:{eq:'1234'}}]
```



### index: **`10`** - ".sort"

> Stability:  2 - **Unstable**

Type: **Array** of strings

Ordering strings take the form: `"[-][$field]"` where the first character **MAY** be a `"-"` to indicate reverse sorting, and the `"$field"` **MAY** be a text string to sort on.

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
// Descending `age`, and ascending `name` for same age
{
  sort: [
    "-age", "name"
  ]
}

// Qe:
[,,,,,,,,,,["-age","name"]]
```



### index: **`11`** - ".meta"

> Stability: 1 - **Experimental**

Type: **Object** of arbitrary data

Meta data store acts as a catch-all for context specific meta information that may need to be attached to a query object message. Think of it like a 'Header' block in an HTTP request. **MAY** contain arbitrary data.

```js
// Object hash:
{
  do: 'update',
  on: 'guitars',
  ids: ['11523'],
  body: [ {price:50} ],
  meta: {
    _authToken: 'xyzqwerty098'
  }
}

// Qe:
['update','guitars',['11523'],,[],,,,,,,{_authToken:'xyzqwerty098'}]
```



## License

> Stability: 4 - **Final**

<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/88x31.png" /></a>

<span xmlns:dct="http://purl.org/dc/terms/" href="http://purl.org/dc/dcmitype/Text" property="dct:title" rel="dct:type">**Query Envelope Specification**</span> is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons Attribution-ShareAlike 4.0 International License</a>.

Based on a work at <a xmlns:dct="http://purl.org/dc/terms/" href="https://github.com/mekanika/qe" rel="dct:source">https://github.com/mekanika/qe</a>.
