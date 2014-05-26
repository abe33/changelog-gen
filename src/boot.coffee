q = require 'qq'
path = require 'path'
child = require 'child_process'
util = require 'util'
natural_sort = require 'javascript-natural-sort'

LAST_TAG = 'last-tag'
FIRST_COMMIT = 'TAIL'
HEAD = 'HEAD'
NONE = 'none'

GIT_LOG_CMD = 'git log -E --format=%s %s | cat'
GIT_LAST_TAG_CMD = 'git describe --tags --abbrev=0'
GIT_TAGS_CMD = 'git tag'
GIT_FIRST_COMMIT = 'git rev-list HEAD | tail -n 1'
GIT_COMMIT_SEARCH = 'git name-rev --name-only '

options =
  start: LAST_TAG
  end: HEAD

warn = ->
  console.log "WARNING:", util.format.apply(null, arguments)

error = ->
  console.log "ERROR:", util.format.apply(null, arguments)
  process.exit()

string_or_url = (field) ->
  if typeof field is 'string'
    field
  else
    field?.url

PACKAGE_JSON = require path.resolve('.', 'package.json')

GITHUB_URL = 'https://github.com/'
REPO_URL = string_or_url(PACKAGE_JSON.repository)
ISSUE_URL = string_or_url(PACKAGE_JSON.bugs)
COMMIT_URL = string_or_url(PACKAGE_JSON.commits)

unless ISSUE_URL?
  if REPO_URL? and REPO_URL.indexOf('http') is 0
    ISSUE_URL = REPO_URL + '/issues'
  else
    return error("Can't locate the `bugs` field in package.json")

unless COMMIT_URL?
  warn("Can't locate the `commits` field in package.json, building it using bugs url")
  COMMIT_URL = ISSUE_URL.replace('issues', 'commit')

HEADER_TPL = "<a name=\"%s\"></a>\n# %s (%s)\n\n"
LINK_ISSUE = "[#%s](#{ISSUE_URL}/%s)"
EXTERNAL_LINK_ISSUE = "[#%s](#{GITHUB_URL}/%s/%s)"
LINK_COMMIT = "[%s](#{COMMIT_URL}/%s)"

stream = process.stdout
