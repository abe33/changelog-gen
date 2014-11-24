q = require 'qq'
fs = require 'fs'
path = require 'path'
child = require 'child_process'
util = require 'util'
CSON = require 'cson'
natural_sort = require 'javascript-natural-sort'
{OnigRegExp} = require 'oniguruma'

LAST_TAG = 'last-tag'
FIRST_COMMIT = 'TAIL'
HEAD = 'HEAD'
NONE = 'none'

GIT_LOG_CMD = 'git log -E --format=%s %s | cat'
GIT_LAST_TAG_CMD = 'git describe --tags --abbrev=0'
GIT_TAGS_CMD = 'git tag'
GIT_FIRST_COMMIT = 'git rev-list HEAD | tail -n 1'
GIT_COMMIT_SEARCH = 'git name-rev --name-only '
GIT_TAG_COMMIT = 'git rev-parse %s'
GIT_COMMIT_DATE = 'git show -s --format=%ci %s'

DEFAULT_CONFIG = path.resolve __dirname,  '..', 'config', 'default.cson'

options =
  start: LAST_TAG
  end: HEAD

first_to_exists = (files...) ->
  return file for file in files when fs.existsSync(file)

warn = ->
  console.error "WARNING:", util.format.apply(null, arguments)

error = ->
  console.error "ERROR:", util.format.apply(null, arguments)
  process.exit()

string_or_url = (field) ->
  if typeof field is 'string'
    field
  else
    field?.url

[node, binPath, args...] = process.argv

while args.length
  option = args.shift()

  switch option
    # Commands
    when '--repo', '-r'
      options.repo = args.shift()
    when '--config', '-c'
      options.config = args.shift()
    when '--start', '-s'
      options.start = args.shift()
    when '--end', '-e'
      options.end = args.shift()
    when '--angular', '-a'
      options.config = path.resolve __dirname,  '..', 'config', 'angular.cson'
    else
      options.tag = option

package_json_path = path.resolve('.', 'package.json')
PACKAGE_JSON = if fs.existsSync(package_json_path)
  require package_json_path
else unless options.repo?
  error("Can't locate a package.json in the current directory. Please at last specify the --repo option")
else
  { repository: options.repo }

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

HEADER_TPL = "\n<a name=\"%s\"></a>\n# %s (%s)\n"
LINK_ISSUE = "[#%s](#{ISSUE_URL}/%s)"
EXTERNAL_LINK_ISSUE = "[%s#%s](#{GITHUB_URL}%s/issues/%s)"
LINK_COMMIT = "[%s](#{COMMIT_URL}/%s)"

stream = process.stdout

config_file_paths = [
  DEFAULT_CONFIG
]

if options.config?
  config_file_paths.unshift options.config
else
  config_file_paths.unshift path.resolve('.', 'changelog.cson')
  config_file_paths.unshift path.resolve('.', 'changelog.json')

config_file = first_to_exists(config_file_paths...)

CONFIG = if /\.cson$/.test config_file
  CSON.parseFileSync(config_file)
else
  require(config_file)

error("Can't locate the `sections` field in #{config_file}") unless CONFIG.sections?

for section,i in CONFIG.sections
  section.regexp = new OnigRegExp(section.match)
