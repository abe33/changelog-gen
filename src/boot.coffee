q = require 'qq'
path = require 'path'
child = require 'child_process'
util = require 'util'

LAST_TAG = 'last-tag'
FIRST_COMMIT = 'first-commit'
HEAD = 'HEAD'
NONE = 'none'

GIT_LOG_CMD = 'git log %s -E --format=%s %s | cat'
GIT_LAST_TAG_CMD = 'git describe --tags --abbrev=0'
GIT_TAGS_CMD = 'git tag'
GIT_FIRST_COMMIT = 'git rev-list HEAD | tail -n 1'
GIT_COMMIT_SEARCH = 'git name-rev --name-only '

options =
  grep: '^Add|^Fix|^Remove|^:bug:|Breaking'
  start: LAST_TAG
  end: HEAD

warn = -> console.log "WARNING:", util.format.apply(null, arguments_)
error = ->
  console.log "ERROR:", util.format.apply(null, arguments_)
  process.exit()

string_or_url = (field) ->
  if typeof field is 'string'
    field
  else
    field.url

PACKAGE_JSON = require path.resolve('.', 'package.json')

ISSUE_URL = string_or_url(PACKAGE_JSON.bugs)
COMMIT_URL = string_or_url(PACKAGE_JSON.commits)

return error("Can't locate the `bugs` field in package.json") unless ISSUE_URL?

unless COMMIT_URL?
  warn("Can't locate the `commits` field in package.json, building it using bugs url")
  COMMIT_URL = ISSUE_URL.replace('issues', 'commit')

HEADER_TPL = "<a name=\"%s\"></a>\n# %s (%s)\n\n"
LINK_ISSUE = "[#%s](#{ISSUE_URL}/%s)"
LINK_COMMIT = "[%s](#{COMMIT_URL}/%s)"
