# changelog-gen

A command line tool to generate changelog files based on simple conventions in commits summaries.

## Installation

`npm install -g changelog-gen`

## Usage

In a git project directory that contains a `package.json` file:

`changelog_gen` - Will generates a markdown changelog from the latest available tag or from the first commit if no tags are available.

In a git project  directory that doesn't contain a `package.json` file:

`changelog_gen --repo {REPO_URL}` - Will generates a markdown changelog from the latest available tag or from the first commit if no tags are available. All the generated links to issues and commits will be constructed using the passed-in `{REPO_URL}`.

### Specifying The Commits Range

You can specify the commit range using the `--start` and `--end` options such as:

- `changelog_gen --start TAIL` - Will start with the root commit in the current commit ancestors.
- `changelog_gen --start {TAG}` - Will start with the first commit after the given `{TAG}`.
- `changelog_gen --start {SHA}` - Will start at the first commit after the last tag before the specified commit. Meaning that if the commit specified with the given `{SHA}` is positionned 3 commits after the `v0.0.1` tag, the range will spans `(v0.0.1 + 1commit)..HEAD`.
- `changelog_gen --start v0.0.1 --end v0.0.2` - Will spans only the commits between these two tags.

## Configuration

The utility works by parsing the commits summaries and testing them against the regular expressions defined in a configuration file.

The configuration file can be either a JSON or a CSON file located in the same directory as your `package.json` file and named `changelog.json` or `changelog.cson`.

You can specify another path to the configuration file using the `--config` option.

`changelog_gen --config my_config.cson`

The configuration file **MUST** contains a `sections` entry with an array of the various sections to appear in a version changelog. A section is a group of commits in the output changelog.

For instance, the default configuration is:

```coffee
sections: [
  {
    name: ':sparkles: Features'
    match: '^(Add|Implement)'
    include_body: true
  }
  {
    name: ':bug: Bug Fixes'
    match: '^(:bug:\\s+|(Fix))(.*)$'
    replace: '\\2\\3'
  }
  {
    name: ':racehorse: Performances'
    match: '^:racehorse:\\s+(.*)$'
    replace: '\\1'
  }
  {
    name: ':arrow_up: Dependencies Update'
    match: '^:arrow_up:\\s+(.*)$'
    replace: '\\1'
  }
]
```

Each `sections` entry must have at least a `name` and `match` attribute. The `name` attribute is the content of the section's title in the output, the `regexp` attribute being a string containing a JS regular expression that will be used against the commits summary.

Optionally the following additional section attributes are available:
- `replace` - A string to use as replacement for the commit summary. The capture groups from the matching regexp can be accessed using the `\x` syntax where `x` is the index of the capture group to insert.
- `include_body` - A boolean value that defines if the commits body are included in the section output or not.
- `grouping_capture` - An integer corresponding to the capture group to use to group commits together as done by the original Angular changelog script. You can now write sections such as:
  ```coffee
  {
    name: 'Features'
    match: '^feat\\((.*)\\):\\s(.*)$'
    replace: '\\2'
    grouping_capture: 1
  }
  ```
  This setup will mimic the output of the Angular changelog script by grouping the commits prefixed with `feat({component})` into a `{component}` list. The `replace` option is used here to only display the remaining content of the commit subject in the list.

### Angular Convention

A default configuration matching the convention of Angular commits messages is provided out of the box. You just have to pass the `--angular` option to the CLI to activate it.
