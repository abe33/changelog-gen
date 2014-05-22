q = require 'qq'
path = require 'path'

LAST_TAG = 'last-tag'
FIRST_COMMIT = 'first-commit'
HEAD = 'HEAD'
NONE = 'none'

options =
  grep: '^Add|^Fix|^Remove|^:bug:|Breaking'
  start: LAST_TAG
  end: HEAD

[node, binPath, args...] = process.argv

while args.length
  option = args.shift()

  switch option
    # Commands
    when '--grep'
      grep = args.shift()
      if grep is NONE
        options.grep = null
      else
        options.grep = grep

    when '--start'
      options.start = args.shift()
    when '--end'
      options.end = args.shift()

get_start = if options.start is FIRST_COMMIT
  get_first_commit()
else if options.start is LAST_TAG
  get_previous_tag()
else
  d = q.defer()
  d.resolve options.start
  d.promise

get_end = if options.end is LAST_TAG
  get_previous_tag()
else
  d = q.defer()
  d.resolve options.end
  d.promise

get_start.then (from) ->
  get_end.then (to) ->
    read_git_log(options.grep, from, to).then (commits) ->
      console.log commits
