# changelog-gen

A command line tool to generates changelog files based on simple conventions in commits summaries.

## Installation

`npm install -g changelog-gen`

## Usage

In a git project directory that contains a `package.json` file:

`changelog` - Will generates a markedown changelog from the latest available tag or from the first commit if no tags are available.

In a git project  directory that doesn't contain a `package.json` file:

`changelog --repo {REPO_URL}` - Will generates a markedown changelog from the latest available tag or from the first commit if no tags are available. All the generated links to issues and commits will be constructed using the passed-in `{REPO_URL}`.

### Specifying The Commits Range

You can specify the commit range using the `--start` and `--end` options such as:

- `changelog --start TAIL` - Will start with the root commit in the current commit ancestors.
- `changelog --start {TAG}` - Will start with the first commit after the given `{TAG}`.
- `changelog --start {SHA}` - Will start at the first commit after the last tag before the specified commit. Meaning that if the commit specified with the given `{SHA}` is positionned 3 commits after the `v0.0.1` tag, the range will spans `(v0.0.1 + 1commit)..HEAD`.
- `changelog --start v0.0.1 --end v0.0.2` - Will spans only the commits between these two tags.

## Configuration

The utility works by parsing the commits summaries and test them against the regular expressions defined in the configuration file.

The default configuration being:

```coffee
sections: [
  {
    name: ':sparkles: Features'
    match: '^(Add|Implement)'
    include_body: true
  }
  {
    name: ':bug: Bug Fixes'
    match: '^:bug:\\s+(.*)$'
    replace: '\\1'
  }
  {
    name: ':racehorse: Performances'
    match: '^:racehorse:\\s+(.*)$'
    replace: '\\1'
  }
]
```

The configuration file can be either a JSON or a CSON file located in the same directory as your `package.json` file and named `changelog.json` or `changelog.cson`.

You can specify another path to the configuration file using the `--config` option.

`changelog --config my_config.cson`

Each `sections` entry must have at least a `name` and `match` attribute. The `name` attribute is the content of the section's title, the `regexp` attribute being a string containing an [oniguruma regular expression](http://www.geocities.jp/kosako3/oniguruma/doc/RE.txt).

Optionally the following section attributes are available:
- `replace` - A string use as replacement for the commit subject. The capture groups from the matching regexp can be accessed using the `\x` syntax where `x` is the index of the capture group to insert.
- `include_body` - A boolean value that defines if the commits body are included in the section output or not.
- `grouping_capture` - An integer corresponding to the capture group to use to group commits together as done by the original Angular changelog script. You can now write sections such as:
  ```coffee
  {
    name: 'Features'
    match: '^feat\\(([^\\)]+)\\):\\s(.*)$'
    replace: '\\2'
    grouping_capture: 1
  }
  ```
  This setup will mimic the output of the Angular changelog script by grouping the commits prefixed with `feat({component})` into a `{component}` list. The `replace` option is used here to only display the remaining content of the commit subject in the list.
