
find_rev_index_for_commit = (commit, tags) ->
  deferred = q.defer()

  if commit in tags
    deferred.resolve tags.indexOf(commit)
  else
    get_tag_of_commit(commit, tags).then (tag) ->
      deferred.resolve tags.indexOf(tag) - 1

  deferred.promise

filter_commit = (commit) ->
  return false unless commit?
  {subject, breaking, closes} = commit
  return false unless subject?

  for section in CONFIG.sections
    {regexp, name} = section
    match = regexp.searchSync(subject)
    if match?
      commit.section = name
      if section.replace?
        commit.subject = section.replace.replace /\\(\d)/g, (m,i) ->
          match[i].match

      if section.grouping_capture?
        commit.group = match[section.grouping_capture].match

      return true

  return true if breaking?

  false

get_commit_of_tag = (tag) ->
  deferred = q.defer()
  cmd = util.format(GIT_TAG_COMMIT, tag)
  child.exec cmd, (code, stdout, stderr) ->
    if code
      deferred.reject("Can't find the commit for tag #{tag}")
    else
      deferred.resolve(stdout.replace('\n', ''))

  deferred.promise

get_date_of_commit = (commit) ->
  deferred = q.defer()
  cmd = util.format(GIT_COMMIT_DATE, commit)
  child.exec cmd, (code, stdout, stderr) ->
    if code
      deferred.reject("Can't find the commit #{commit}")
    else

      deferred.resolve(stdout.split('\n')[-2..-1][0].split(' ')[0])

  deferred.promise

get_date_of_tag =  (tag) ->
  get_commit_of_tag(tag)
  .then (commit) ->
    get_date_of_commit(commit)


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

  msg.body = lines.join("\n")
  breaking_regexp = /(?:BREAKING CHANGE|:warning):([\s\S]*)/
  match = msg.body.match(breaking_regexp)
  if match
    msg.breaking = match[1]
    msg.body = msg.body.replace(breaking_regexp, '')

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
