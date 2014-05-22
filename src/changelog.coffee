`#!/usr/bin/env node`

# TODO(vojta): pre-commit hook for validating messages
# TODO(vojta): report errors, currently Q silence everything which really sucks
child = require("child_process")
fs = require("fs")
util = require("util")
q = require("qq")
GIT_LOG_CMD = "git log --grep=\"%s\" -E --format=%s %s..HEAD"
GIT_TAG_CMD = "git describe --tags --abbrev=0"
HEADER_TPL = "<a name=\"%s\"></a>\n# %s (%s)\n\n"
LINK_ISSUE = "[#%s](https://github.com/angular/angular.js/issues/%s)"
LINK_COMMIT = "[%s](https://github.com/angular/angular.js/commit/%s)"
EMPTY_COMPONENT = "$$"

warn = ->
  console.log "WARNING:", util.format.apply(null, arguments_)
  return

parseRawCommit = (raw) ->
  return null  unless raw
  lines = raw.split("\n")
  msg = {}
  match = undefined
  msg.hash = lines.shift()
  msg.subject = lines.shift()
  msg.closes = []
  msg.breaks = []
  lines.forEach (line) ->
    match = line.match(/(?:Closes|Fixes)\s#(\d+)/)
    msg.closes.push parseInt(match[1])  if match
    return

  match = raw.match(/BREAKING CHANGE:([\s\S]*)/)
  msg.breaking = match[1]  if match
  msg.body = lines.join("\n")
  match = msg.subject.match(/^(.*)\((.*)\)\:\s(.*)$/)
  if not match or not match[1] or not match[3]
    warn "Incorrect message: %s %s", msg.hash, msg.subject
    return null
  msg.type = match[1]
  msg.component = match[2]
  msg.subject = match[3]
  msg

linkToIssue = (issue) ->
  util.format LINK_ISSUE, issue, issue

linkToCommit = (hash) ->
  util.format LINK_COMMIT, hash.substr(0, 8), hash

currentDate = ->
  now = new Date()
  pad = (i) ->
    ("0" + i).substr -2

  util.format "%d-%s-%s", now.getFullYear(), pad(now.getMonth() + 1), pad(now.getDate())

printSection = (stream, title, section, printCommitLinks) ->
  printCommitLinks = (if printCommitLinks is `undefined` then true else printCommitLinks)
  components = Object.getOwnPropertyNames(section).sort()
  return  unless components.length
  stream.write util.format("\n## %s\n\n", title)
  components.forEach (name) ->
    prefix = "-"
    nested = section[name].length > 1
    if name isnt EMPTY_COMPONENT
      if nested
        stream.write util.format("- **%s:**\n", name)
        prefix = "  -"
      else
        prefix = util.format("- **%s:**", name)
    section[name].forEach (commit) ->
      if printCommitLinks
        stream.write util.format("%s %s\n  (%s", prefix, commit.subject, linkToCommit(commit.hash))
        stream.write ",\n   " + commit.closes.map(linkToIssue).join(", ")  if commit.closes.length
        stream.write ")\n"
      else
        stream.write util.format("%s %s", prefix, commit.subject)
      return

    return

  stream.write "\n"
  return

readGitLog = (grep, from) ->
  deferred = q.defer()

  # TODO(vojta): if it's slow, use spawn and stream it instead
  child.exec util.format(GIT_LOG_CMD, grep, "%H%n%s%n%b%n==END==", from), (code, stdout, stderr) ->
    commits = []
    stdout.split("\n==END==\n").forEach (rawCommit) ->
      commit = parseRawCommit(rawCommit)
      commits.push commit  if commit
      return

    deferred.resolve commits
    return

  deferred.promise

writeChangelog = (stream, commits, version) ->
  sections =
    fix: {}
    feat: {}
    perf: {}
    breaks: {}

  sections.breaks[EMPTY_COMPONENT] = []
  commits.forEach (commit) ->
    section = sections[commit.type]
    component = commit.component or EMPTY_COMPONENT
    if section
      section[component] = section[component] or []
      section[component].push commit
    if commit.breaking
      sections.breaks[component] = sections.breaks[component] or []
      sections.breaks[component].push
        subject: util.format("due to %s,\n %s", linkToCommit(commit.hash), commit.breaking)
        hash: commit.hash
        closes: []

    return

  stream.write util.format(HEADER_TPL, version, version, currentDate())
  printSection stream, "Bug Fixes", sections.fix
  printSection stream, "Features", sections.feat
  printSection stream, "Performance Improvements", sections.perf
  printSection stream, "Breaking Changes", sections.breaks, false
  return

getPreviousTag = ->
  deferred = q.defer()
  child.exec GIT_TAG_CMD, (code, stdout, stderr) ->
    if code
      deferred.reject "Cannot get the previous tag."
    else
      deferred.resolve stdout.replace("\n", "")
    return

  deferred.promise

generate = (version, file) ->
  getPreviousTag().then (tag) ->
    console.log "Reading git log since", tag
    readGitLog("^fix|^feat|^perf|BREAKING", tag).then (commits) ->
      console.log "Parsed", commits.length, "commits"
      console.log "Generating changelog to", file or "stdout", "(", version, ")"
      writeChangelog (if file then fs.createWriteStream(file) else process.stdout), commits, version
      return

    return

  return


# publish for testing
exports.parseRawCommit = parseRawCommit

# hacky start if not run by jasmine :-D
generate process.argv[2], process.argv[3]  if process.argv.join("").indexOf("jasmine-node") is -1
