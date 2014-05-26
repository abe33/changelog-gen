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
      commits: {}
      breaks: []
    }

    for commit in commits
      if commit.section?
        (section.commits[commit.section] ||= []).push commit

      section.breaks.push commit if commit.breaking?

    sections.push section

  sections

print_section = (section) ->
  stream.write util.format(HEADER_TPL, section.tag, section.tag, current_date())

  for section_name, commits of section.commits
    stream.write "## #{section_name}\n\n"
    for commit in commits
      closes = commit.closes.map(link_to_issue).join(', ')
      closes = ", #{closes}" if closes.length > 0
      commit_body = if commit.body.length > 0
        "<br>#{commit.body}"
      else
        ''

      l = "- #{commit.subject} (#{link_to_commit(commit.hash)}#{closes})#{commit_body}\n"
      stream.write l

  breaking_commits = section.breaks
  if breaking_commits.length
    stream.write '## Breaking Changes\n\n'
    for commit in breaking_commits
      stream.write commit.breaking

  stream.write '\n'


print_sections = (sections) ->
  print_section(section) for section in sections
