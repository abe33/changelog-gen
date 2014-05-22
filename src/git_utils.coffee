child = require 'child_process'
util = require 'util'
q = require 'qq'

GIT_LOG_CMD = 'git log %s -E --format=%s %s'
GIT_TAG_CMD = 'git describe --tags --abbrev=0'

get_previous_tag = ->
  deferred = q.defer()
  child.exec GIT_TAG_CMD, (code, stdout, stderr) ->
    if code
      deferred.reject "Cannot get the previous tag."
    else
      deferred.resolve stdout.replace('\n', '')

  deferred.promise

read_git_log = (grep, from) ->
  deferred = q.defer()

  grep = if grep?
    "--grep=\"#{grep}\""
  else
    ''

  range = if from?
    "#{from}..HEAD"
  else


  child.exec util.format(GIT_LOG_CMD, grep, '%H%n%s%n%b%n==END==', range), (code, stdout, stderr) ->
    commits = []
    stdout.split('\n==END==\n').forEach (rawCommit) ->
      commit = parseRawCommit(rawCommit)
      commits.push commit  if commit

    deferred.resolve commits

  deferred.promise
