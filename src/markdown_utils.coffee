reverse_array = (array) ->
  a = []
  a.unshift o for o in array
  a

link_to_issue = ([repo, issue]) ->
  if repo?
    util.format EXTERNAL_LINK_ISSUE, issue, repo, issue
  else
    util.format LINK_ISSUE, issue, issue

link_to_commit = (hash) ->
  util.format LINK_COMMIT, hash.substr(0, 8), hash

current_date = ->
  now = new Date()
  pad = (i) -> ("0" + i).substr -2

  util.format "%d-%s-%s", now.getFullYear(), pad(now.getMonth() + 1), pad(now.getDate())

find_fixes = (line, msg) ->
  issue_re = "([^\\s/]+/[^\\s#])?#(\\d+)"
  re = ///
  (?:
  close|closes|closed|
  fix|fixes|fixed|
  resolve|resolves|resolved
  )
  \s
  #{issue_re}
  ///i

  match = re.exec(line)
  if match?
    [_, repo, issue] = match
    msg.closes.push [repo, issue]

  not match?

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

curate_sections = (tags_steps) -> (commits_groups) ->
  commits_per_tag = []
  for commits,i in commits_groups
    current_tag = tags_steps[i]
    # We don't really want to have HEAD considered as a tag,
    # so we'll mark it as undefined
    current_tag = undefined if current_tag is HEAD
    commits_per_tag.push [current_tag, commits]

  sections = []

  for [tag, commits] in reverse_array(commits_per_tag)
    continue if commits.length is 0
    section = {
      tag
      commits: []
    }

    for commit in commits
      parsed_commit = parse_raw_commit(commit)
      section.commits.push parsed_commit

    sections.push section

  sections

print_section = (section) ->
  stream.write util.format(HEADER_TPL, section.tag, section.tag, current_date())

  stream.write '## Changes\n\n'
  for commit in section.commits
    closes = commit.closes.map(link_to_issue).join(', ')
    closes = ", #{closes}" if closes.length > 0
    commit_body = if commit.body.length > 0
      "<br>#{commit.body}"
    else
      ''

    l = "- #{commit.subject} (#{link_to_commit(commit.hash)}#{closes})#{commit_body}\n"
    stream.write l

  breaking_commits = section.commits.filter (c) -> c.breaking?
  if breaking_commits.length
    stream.write '## Breaking\n\n'
    for commit in breakin_commits
      stream.write commit.breaking

  stream.write '\n'


print_sections = (sections) ->
  print_section(section) for section in sections
