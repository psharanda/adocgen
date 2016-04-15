Goodies
=======

GRMustache ships with a library of built-in goodies available for your templates.

- [NSFormatter](#nsformatter)
- [HTMLEscape](#htmlescape)
- [javascriptEscape](#javascriptescape)
- [URLEscape](#urlescape)
- [each](#each)
- [zip](#zip)
- [Localizer](#localizer)
- [Logger](#logger)


### NSFormatter

GRMustache provides built-in support for NSFormatter and its subclasses such as NSNumberFormatter and NSDateFormatter.

#### Formatting a value

```swift
let percentFormatter = NSNumberFormatter()
percentFormatter.numberStyle = .PercentStyle

let template = try! Template(string: "{{ percent(x) }}")
template.registerInBaseContext("percent", Box(percentFormatter))

// Rendering: 50%
let data = ["x": 0.5]
let rendering = try! template.render(Box(data))
```

#### Formatting all values in a section

NSFormatters are able to *format all variable tags* inside the section:

`Document.mustache`:

    {{# percent }}
    hourly: {{ hourly }}
    daily: {{ daily }}
    weekly: {{ weekly }}
    {{/ percent }}

Rendering code:

```swift
let percentFormatter = NSNumberFormatter()
percentFormatter.numberStyle = .PercentStyle

let template = try! Template(named: "Document")
template.registerInBaseContext("percent", Box(percentFormatter))

// Rendering:
//
//   hourly: 10%
//   daily: 150%
//   weekly: 400%

id data = [
    "hourly": 0.1,
    "daily": 1.5,
    "weekly": 4,
};
let rendering = try! template.render(Box(data))
```

Variable tags buried inside inner sections are escaped as well, so that you can render loop and conditional sections. However, values that can't be formatted are left untouched:

`Document.mustache`:

    {{# percent }}
      {{# ingredients }}
      - {{ name }}: {{ proportion }}  {{! name is intact, proportion is formatted. }}
      {{/ ingredients }}
    {{/ percent }}

Would render:

    - bread: 50%
    - ham: 22%
    - butter: 43%

Precisely speaking, "values that can't be formatted" are the ones that have the `stringForObjectValue:` method return nil, as stated by [NSFormatter documentation](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSFormatter_Class/index.html#//apple_ref/occ/instm/NSFormatter/stringForObjectValue:).

Typically, NSNumberFormatter only formats numbers, and NSDateFormatter, dates: you can safely mix various data types in a section controlled by those well-behaved formatters.

Support for NSFormatter is written using public APIs. You can check the [source](../../Mustache/Goodies/NSFormatter.swift) for inspiration.


### HTMLEscape

Usage:

```swift
let template = ...
template.registerInBaseContext("HTMLEscape", Box(StandardLibrary.HTMLEscape))
```

As a filter, `HTMLEscape` returns its argument, HTML-escaped.

```html
<pre>
   {{ HTMLEscape(content) }}
</pre>
```

When used in a section, `HTMLEscape` escapes all inner variable tags in a section:

    {{# HTMLEscape }}
      {{ firstName }}
      {{ lastName }}
    {{/ HTMLEscape }}

Variable tags buried inside inner sections are escaped as well, so that you can render loop and conditional sections:

    {{# HTMLEscape }}
      {{# items }}
        {{ name }}
      {{/}}
    {{/ HTMLEscape }}

StandardLibrary.HTMLEscape is written using public APIs. You can check the [source](../../Mustache/Goodies/HTMLEscape.swift) for inspiration.

See also [javascriptEscape](#javascriptescape), [URLEscape](#urlescape)


### javascriptEscape

Usage:

```swift
let template = ...
template.registerInBaseContext("javascriptEscape", Box(StandardLibrary.javascriptEscape))
```

As a filter, `javascriptEscape` outputs a Javascript and JSON-savvy string:

```html
<script type="text/javascript">
  var name = "{{ javascriptEscape(name) }}";
</script>
```

When used in a section, `javascriptEscape` escapes all inner variable tags in a section:

```html
<script type="text/javascript">
  {{# javascriptEscape }}
    var firstName = "{{ firstName }}";
    var lastName = "{{ lastName }}";
  {{/ javascriptEscape }}
</script>
```

Variable tags buried inside inner sections are escaped as well, so that you can render loop and conditional sections:

```html
<script type="text/javascript">
  {{# javascriptEscape }}
    var firstName = {{# firstName }}"{{ firstName }}"{{^}}null{{/}};
    var lastName = {{# lastName }}"{{ lastName }}"{{^}}null{{/}};
  {{/ javascriptEscape }}
</script>
```

StandardLibrary.javascriptEscape is written using public APIs. You can check the [source](../../Mustache/Goodies/JavascriptEscape.swift) for inspiration.

See also [HTMLEscape](#htmlescape), [URLEscape](#urlescape)


### URLEscape

Usage:

```swift
let template = ...
template.registerInBaseContext("URLEscape", Box(StandardLibrary.URLEscape))
```

As a filter, `URLEscape` returns its argument, percent-escaped.

```html
<a href="http://google.com?q={{ URLEscape(query) }}">...</a>
```

When used in a section, `URLEscape` escapes all inner variable tags in a section:

```html
{{# URLEscape }}
  <a href="http://google.com?q={{query}}&amp;hl={{language}}">...</a>
{{/ URLEscape }}
```

Variable tags buried inside inner sections are escaped as well, so that you can render loop and conditional sections:

```html
{{# URLEscape }}
  <a href="http://google.com?q={{query}}{{#language}}&amp;hl={{language}}{{/language}}">...</a>
{{/ URLEscape }}
```

StandardLibrary.URLEscape is written using public APIs. You can check the [source](../../Mustache/Goodies/URLEscape.swift) for inspiration.

See also [HTMLEscape](#htmlescape), [javascriptEscape](#javascriptescape)


### each

Usage:

```swift
let template = ...
template.registerInBaseContext("each", Box(StandardLibrary.each))
```

Iteration is natural to Mustache templates: `{{# users }}{{ name }}, {{/ users }}` renders "Alice, Bob, etc." when the `users` key is given a list of users.

The `each` filter is there to give you some extra keys:

- `@index` contains the 0-based index of the item (0, 1, 2, etc.)
- `@indexPlusOne` contains the 1-based index of the item (1, 2, 3, etc.)
- `@indexIsEven` is true if the 0-based index is even.
- `@first` is true for the first item only.
- `@last` is true for the last item only.

```
One line per user:
{{# each(users) }}
- {{ @index }}: {{ name }}
{{/}}

Comma-separated user names:
{{# each(users) }}{{ name }}{{^ @last }}, {{/}}{{/}}.
```

```
One line per user:
- 0: Alice
- 1: Bob
- 2: Craig

Comma-separated user names: Alice, Bob, Craig.
```

When provided with a dictionary, `each` iterates each key/value pair of the dictionary, stores the key in `@key`, and sets the value as the current context:

```
{{# each(dictionary) }}
- {{ @key }}: {{.}}
{{/}}
```

```
- name: Alice
- score: 200
- level: 5
```

The other positional keys `@index`, `@first`, etc. are still available when iterating dictionaries.

The `each` filter is written using public APIs. You can check the [source](../../Mustache/Goodies/EachFilter.swift) for inspiration.


### zip

Usage:

```swift
let template = ...
template.registerInBaseContext("zip", Box(StandardLibrary.zip))
```

The zip filter iterates several lists all at once. On each step, one object from each input list enters the rendering context, and makes its own keys available for rendering.

`Document.mustache`:

```mustache
{{# zip(users, teams, scores) }}
- {{ name }} ({{ team }}): {{ score }} points
{{/}}
```

Data:

```swift
[
  "users": [
    [ "name": "Alice" ],
    [ "name": "Bob" ],
  ],
  "teams": [
    [ "team": "iOS" ],
    [ "team": "Android" ],
  ],
  "scores": [
    [ "score": 100 ],
    [ "score": 200 ],
  ]
]
```

Rendering:

```
- Alice (iOS): 100 points
- Bob (Android): 200 points
```

In the example above, the first step has consumed (Alice, iOS and 100), and the second one (Bob, Android and 200).

The zip filter renders a section as many times as there are elements in the longest of its argument: exhausted lists simply do not add anything to the rendering context.

The `zip` filter is written using public APIs. You can check the [source](../../Mustache/Goodies/ZipFilter.swift) for inspiration.


### Localizer

Usage:

```swift
let template = ...

let localizer = StandardLibrary.Localizer(bundle: nil, table: nil)
template.registerInBaseContext("localize", Box(localizer))
```

#### Localizing a value

As a filter, `localize` outputs a localized string:

    {{ localize(greeting) }}

This would render `Bonjour`, given `Hello` as a greeting, and a French localization for `Hello`.

#### Localizing template content

When used in a section, `localize` outputs the localization of a full section:

    {{# localize }}Hello{{/ localize }}

This would render `Bonjour`, given a French localization for `Hello`.

#### Localizing template content with embedded variables

When looking for the localized string, GRMustache replaces all variable tags with "%@":

    {{# localize }}Hello {{name}}{{/ localize }}

This would render `Bonjour Arthur`, given a French localization for `Hello %@`. `String(format:)` is used for the final interpolation.

#### Localizing template content with embedded variables and conditions

You can embed conditional sections inside:

    {{# localize }}Hello {{#name}}{{name}}{{^}}you{{/}}{{/ localize }}

Depending on the name, this would render `Bonjour Arthur` or `Bonjour toi`, given French localizations for both `Hello %@` and `Hello you`.

StandardLibrary.Localizer filter is written using public APIs. You can check the [source](../../Mustache/Goodies/Localizer.swift) for inspiration.


### Logger

Usage:

```swift
let template = ...

let logger = StandardLibrary.Logger()
template.extendBaseContext(Box(logger))
```

`Logger` is a tool intended for debugging templates.

It logs the rendering of variable and section tags such as `{{name}}` and
`{{#name}}...{{/name}}`.

To activate logging, add a Logger to the base context of a template:

```swift
let template = try! Template(string: "{{name}} died at {{age}}.")

// Logs all tag renderings with NSLog():
let logger = StandardLibrary.Logger()
template.extendBaseContext(Box(logger))

// Render
let data = ["name": "Freddy Mercury", "age": 45]
let rendering = try! template.render(Box(data))
```

In the log:

    {{name}} at line 1 did render "Freddy Mercury" as "Freddy Mercury"
    {{age}} at line 1 did render 45 as "45"
