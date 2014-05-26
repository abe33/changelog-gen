
find_rev_index_for_commit = (commit, tags) ->
  deferred = q.defer()

  if commit in tags
    deferred.resolve tags.indexOf(commit)
  else
    get_tag_of_commit(commit, tags).then (tag) ->
      deferred.resolve tags.indexOf(tag) - 1

  deferred.promise

filter_commit = ({subject, breaking, closes}) ->
  return false unless subject?
  return true for {regexp} in CONFIG.sections when regexp.testSync(subject)
  return true if breaking? or closes?.length > 0
  false

get_tag_of_commit = (sha, tags) ->
  cmd = GIT_COMMIT_SEARCH + sha
  deferred = q.defer()
  child.exec cmd, (code, stdout, stderr) ->
    if code
      get_first_commit().then (commit) ->
        deferred.resolve commit
    else
      res = stdout.replace('\n', '')
      [tag, offset] = res.split('~')
      tag = 'HEAD' unless tag in tags
      deferred.resolve tag

  deferred.promise

get_all_tags = ->
  deferred = q.defer()
  child.exec GIT_TAGS_CMD, (code, stdout, stderr) ->
    if code
      deferred.resolve []
    else
      deferred.resolve stdout.split('\n').filter (s) -> s.length isnt 0

  deferred.promise

get_previous_tag = ->
  deferred = q.defer()
  child.exec GIT_LAST_TAG_CMD, (code, stdout, stderr) ->
    if code
      get_first_commit().then (commit) ->
        deferred.resolve commit
    else
      deferred.resolve stdout.replace('\n', '')

  deferred.promise

get_first_commit = ->
  deferred = q.defer()
  child.exec GIT_FIRST_COMMIT, (code, stdout, stderr) ->
    if code
      deferred.reject "Cannot get the first commit."
    else
      deferred.resolve stdout.replace('\n', '')

  deferred.promise

parse_raw_commit = (raw) ->
  return null unless raw?

  lines = raw.split('\n')
  msg = {}
  msg.hash = lines.shift()
  msg.subject = lines.shift()
  msg.closes = []

  lines = lines.filter (line) ->
    find_fixes(line, msg)

  match = raw.match(/BREAKING CHANGE:([\s\S]*)/)
  msg.breaking = match[1] if match
  msg.body = lines.join("\n")

  msg

read_git_log = (from, to='HEAD') ->
  deferred = q.defer()

  range = if from?
    "#{from}..#{to}"
  else
    ''

  cmd = util.format(GIT_LOG_CMD, '%H%n%s%n%b%n==END==', range)

  child.exec cmd, (code, stdout, stderr) ->
    commits = stdout.split('\n==END==\n')
    .map (rawCommit) ->
      rawCommit.split('\n').filter((s) -> s.length).join('\n')
    .map(parse_raw_commit)
    .filter(filter_commit)

    deferred.resolve commits

  deferred.promise
