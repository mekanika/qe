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

They are descriptions consumed by _Qe_-aware APIs to instruct actions, generally using a _verbs_ (actions) acting on _nouns_ (resources) approach.

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

For endpoints that predefine their actions and/or targets (`.on`), _Qe_ may simply encode relevant data, for example:

```js
{
  match: {
    or: [
      {age: {gt:10}},
      {variety: {eq:'Pinot Noir'}}
    ]
  }
}
```


## Conventions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](http://tools.ietf.org/html/rfc2119).


## Structure

> Stability: 3 - **Stable**
>
> The structure and order of _Qe_ is looking solid. Has been decently implemented in [`query`](https://github.com/mekanika/query/) and has been undergoing extensive testing against the reference Fixture adapter. **Release Candidate**

The structure of a Query envelope is **significantly ordered** and otherwise described by its _fields_ below, according to:

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


### Serialisation

All examples in this document are shown as Javascript primitives.

_Qe_ **MAY** be serialised as JSON, or any other appropriate structure.


## Qe field details

> **Important:** (a note about "index")
>  The index number refers to the Javascript-style **array index**. `0` is thus the _first_ element, `3` is the _fourth_ etc. Index `5` DOES NOT mean the fifth element, it refers to the element at **index** `5` (which, of course, is the _sixth_ element).


### **.do** - index: **`0`**

> Stability:  4 - **Final**

Type: **String**

The `do` field is a _verb_ that describes the intended process to invoke.

```js
// Create a tag {label:sweet}
{
  do: 'create',
  on: 'tags',
  body: [ {label:'sweet'} ]
}
```

The following are reserved action types. An API consuming _Qe_ **SHOULD** handle these defaults:

- **create**: make new
- **find**: locate
- **remove**: delete
- **update**: modify

These action types **SHOULD NOT** be aliased or have their intended meaning altered.

Qe **MAY** specify other (custom) action types.



### **.on** - index:**`1`**

> Stability:  4 - **Final**

Type: **String**

The `.on` field points to a unique entity type to act upon, like a table (SQL), a collection (Document stores), a resource (REST). It is almost always a unique reference to some end-point that a `.do` field will apply to.

_Qe_ **MAY** omit `.on`, as some actions might _not_ act `.on` anything. eg. `{do:'self_destruct', meta:{secret:'☃'}}`.

Example `.on` usage:

```js
// Get 25 tweets
{
  do: 'find',
  on: 'tweets',
  limit: 25
}
```



### **.ids** - index: **`2`**

> Stability:  3 - **Stable**

Type: **Array** of strings or numbers

An Array of entity IDs to which the `.action` **SHOULD** apply the `.body` or `.update`. If `.ids` are provided, the `.do` action **SHOULD** **only** apply to those ids provided.

If `.ids` are provided, `.match` conditions **MUST** apply only to that subset of ids.

Example `.ids` usage:

```js
// Remove ids ['554120', '841042']
{
  do: 'remove',
  ids: ['554120', '841042']
}
```



### **.match** - index: **`3`**

> Stability:  2 - **Unstable**

Type: match container **Object**

`.match` is used to conditionally specify entities that meet matching criteria. If `.ids` are provided, `.match` **MUST** apply only to that subset of ids.

"Match" borrows its structure from MongoDB.

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
```

#### match operators

The current reserved match operators are:

- **eq** - Equals
- **neq** - Not equals
- **in** - (array) Scalar value is in this list
- **nin** - (array) Scalar must not be in this list
- **all** - (array) All items in list must be present in the value array
- **any** - (array) Value array has at least one of the items in list
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
```

Where a field specifying a sub-property match is typed as an Array (eg. the User's `cars` field above), the match **SHOULD** apply to all elements in the Array. e.g each car is checked if its `.year` property is `< 1970`.




### **.body** - index: **`4`**

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

> Qe implementations **MAY** treat element fields set to `undefined` as an 'UNSET' command for schema-less stores. Otherwise specify an `.update` action with an `unset` operator.

A Qe `.do` action **SHOULD** apply to each element in the `.body` array.

_However_, when specifying `.ids` or other `.match` constraints, the `.body` field **MUST** be empty or contain _only one_ element, and the action **SHOULD** apply the body element to matching `.ids`. 

> Note: To perform discrete data transforms (ie. different/conditional changes on differing records), use a dedicated control message (Qe) per transform. 

```js
// Example create multiple 'guitars'
{
  do: 'create',
  on: 'guitars',
  body: [
    {label:'Fender Stratocaster', price:450.75},
    {label:'Parker Fly', price:399.00}
  ]
}
```


```js
// Example specifying a match within `ids` field
// (note ONLY one object in body)
{
  do: 'update',
  on: 'guitars',
  ids: ['12','35','17','332'],
  match: {and:[{price:{eq:260}}]},
  body: [{price: 250.00}]
}
```



### **.update** - index: **`5`**

> Stability:  2 - **Unstable**
>
> Do updates need to support 'deep updates' eg:
> `{"users.cars.reviews":{push::"Great!"}}`

Type: **Array** of update objects

The array of update objects **SHOULD** all be applied to every matching result (provided by `.ids` and/or `.match` conditions).

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
{
  do:'update',
  on:'users',
  ids:['123'],
  update: [
    { comments: {push:['13','21']} }
  ]
}

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

> Note: If `.body` is provided and is modifying _the same_ key on a record as the `.update` field, there exists sufficient knowledge to **collapse** the non-idempotent update into the idempotent write (ie. combine the update for that key into the `.body` field). 
> 
> As such if both `.update` and `.body` are acting on the same record field, the Qe **SHOULD** return an error.

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

- **unset**: remove a field entirely from the target
```js
{comments: {unset:true}}
```

These operators **SHOULD NOT** be aliased or have their intended meaning altered.

Qe **MAY** specify other update operators (that **SHOULD** be non-idempotent operators). For example:

```js
// Example of custom operator 'multiply'
{score: {multiply:3}}
```



### **.select** - index: **`6`**

> Stability:  3 - **Stable**

Type: **Array** of strings

Field selector acting _either_ as:

- a **whitelist** of fields to return `["name", "age"]`, or
- a **blacklist** of fields to exclude `["-posts"]`

To act as a blacklist, strings are prepended with a `-`.  Select **SHOULD** only act as a whitelist or a blacklist, not both.

If no `.select` is present, all fields **SHOULD** be returned.


```js
// Get artists, leave off 'name','bio'
{
  do: 'find',
  on: 'artists',
  select: [ '-name', '-bio' ]
}
```



### **.populate** index: **`7`**

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
    'tags': {query:{on:'Tgz'}}
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
```




### index: **`8`** - ".limit"

> Stability:  3 - **Stable**

Type: **Number**

Maximum number of results to return.

Assume **no** limit if none specified. Qe services **MAY** restrict results anyway.

```js
// Limit 25. Such limit.
{ limit: 25 }
```



### **.offset** - index: **`9`**

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

// As 'startAt' style:
{offset: {id: {eq:'1234'}}}
```



### **.sort** - index: **`10`**

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
```



### **.meta** - index: **`11`**

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
```


## Implementing Qe: **adapters**

> Stability: 1 - **Experimental**
>
> - `canX` flags vs. `enabled = ["$feature1", ...]`
>
> The currently proposed granularity is ugly because features often have sub-capabilities (eg. `limit: [byNumber, byMatch]`  and `match` having multiple operators and "deepMatch" etc.)

Qe consuming interfaces are referred to as **Adapters**. 

> See the **[Qe Adapter](https://github.com/mekanika/adapter)** repo for a base implementation of this specification.

Services implementing a Qe consuming interface  are strongly **RECOMMENDED** to provide a _documented_ method to return a 'features' object . Much like an HTTP `OPTIONS` request to a resource, this object describes what Qe constructs are supported by a service.

If a field is not present that **SHOULD** be interpreted as **not** supporting a feature. A blank object treats all features as `false`/not-implemented.

If returning a populated features object it **MUST** provide a `qeVersion` string:

- **qeVersion**: `"major.minor"` string of specification version eg. '1.0'

Arrays of strings for actions, updates and match operators:

- **actions**: Actions supported (`create`, `find`, `appcustom`, etc)
- **updateOps**: Update operators (`push`, `pull`, `inc`, etc)
- **matchOps**: Array of match operators (`eq`, `neq`,  etc)

Requirements and restrictions:

- **required**: fields that MUST be present
- **restricted**: fields that MUST NOT be present

Boolean flags indicating support for specific Qe features:

- **matchDot**: Can `match` on dot notation e.g. `cars.year`
- **canPopulate**: Fully support populate
- **canLimit**: Can restrict number of results returned
- **canOffsetByNumber**: Can offset results by a number (skip)
- **canOffsetById**: Can offset starting from an id (start-at)
- **canSort**: Support sorting on a key
- **canSubsort**: Support sub sorting on multiple keys
- **canInclude**: Support sparse field whitelisting
- **canExclude**: Support sparse field blacklisting

Specific descriptions for custom fields:

- **meta**:  An object hash `{$key:"$stringDesc"}` describing supported non-standard fields

An example response:

```js
{
  qeVersion: "0.6",
  required: ["do", "on"],
  restricted: ["populate"],
  actions: ["create","find","update","remove"],
  updateOps: ["pull","push","inc","unset"],
  matchOps: ["eq","neq","in","nin","lt","gt"],
  canPopulate: false,
  canLimit: true,
  canOffsetByNumber: true,
  canOffsetByMatch: true,
  canInclude: true,
  canExclude: true
  meta: {
    _authToken: "A String used for authentication"
  }
}
```


## License

> Stability: 4 - **Final**

<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/88x31.png" /></a>

<span xmlns:dct="http://purl.org/dc/terms/" href="http://purl.org/dc/dcmitype/Text" property="dct:title" rel="dct:type">**Query Envelope Specification**</span> is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons Attribution-ShareAlike 4.0 International License</a>.

Based on a work at <a xmlns:dct="http://purl.org/dc/terms/" href="https://github.com/mekanika/qe" rel="dct:source">https://github.com/mekanika/qe</a>.
