reverse_array = (array) ->
  a = []
  a.unshift o for o in array
  a

lower_first_char = (s) -> s.replace /^\s*[^\s]/, (m) -> m.toLowerCase()

link_to_issue = ([repo, issue]) ->
  if repo?
    util.format EXTERNAL_LINK_ISSUE, repo, issue, repo, issue
  else
    util.format LINK_ISSUE, issue, issue

indent = (s) ->
  lines = s.split('\n')
  last_line = lines.pop()
  output = '  ' + lines.join('\n  ')
  output += if last_line.length > 0
    '\n  ' + last_line
  else
    '\n'
  output

link_to_commit = (hash) ->
  util.format LINK_COMMIT, hash.substr(0, 8), hash

current_date = ->
  now = new Date()
  pad = (i) -> ("0" + i).substr -2

  util.format "%d-%s-%s", now.getFullYear(), pad(now.getMonth() + 1), pad(now.getDate())

find_fixes = (line, msg) ->
  issue_re = "([^\\s/]+/[^\\s#]+)?#(\\d+)"
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

curate_versions = (tags_steps) -> (commits_groups) ->
  commits_per_tag = []
  for commits,i in commits_groups
    current_tag = tags_steps[i]
    # We don't really want to have HEAD considered as a tag,
    # so we'll mark it as undefined
    current_tag = undefined if current_tag is HEAD
    commits_per_tag.push [current_tag, commits]

  versions = []

  for [tag, commits] in reverse_array(commits_per_tag)
    continue if commits.length is 0

    version = {
      tag
      commits: {}
      breaks: []
    }

    for commit in commits
      if commit.section?
        (version.commits[commit.section] ||= []).push commit

      version.breaks.push commit if commit.breaking?

    versions.push version

  versions

get_section_config = (name) ->
  return section for section in CONFIG.sections when section.name is name
  null

get_commit_body = (commit, section_config) ->
  if section_config.include_body and commit.body.length > 0
    indent("<br>#{commit.body}")
  else
    ''

get_commit_closes = (commit) ->
  closes = commit.closes.map(link_to_issue).join(', ')
  if closes.length > 0
    ", #{closes}"
  else
    ''

get_commit_output = (commit, section_config) ->
  closes = get_commit_closes(commit)
  commit_body = get_commit_body(commit, section_config)

  "- #{commit.subject} (#{link_to_commit(commit.hash)}#{closes})#{commit_body}\n"

print_version = (version, date) ->
  tag = version.tag ? options.tag
  stream.write util.format(HEADER_TPL, tag, tag, date ? current_date())
  for section_config in CONFIG.sections
    section_name = section_config.name
    commits = version.commits[section_name]
    continue unless commits?

    stream.write "\n## #{section_name}\n\n"

    non_grouped_commits = commits.filter (commit) -> not commit.group?
    grouped_commits = {}
    commits.filter((commit) -> commit.group?).forEach (commit) ->
      grouped_commits[commit.group] ||= []
      grouped_commits[commit.group].push commit

    for group, commits of grouped_commits
      stream.write "- **#{group}**:\n"
      for commit in commits
        commit_output = get_commit_output(commit, section_config)
        stream.write indent(commit_output)

    for commit in non_grouped_commits
      commit_output = get_commit_output(commit, section_config)
      stream.write commit_output

  breaking_commits = version.breaks
  if breaking_commits.length
    stream.write '\n## Breaking Changes\n\n'
    for commit in breaking_commits
      stream.write "- due to #{link_to_commit(commit.hash)},#{lower_first_char commit.breaking}\n"

  stream.write '\n'


print_versions = (versions, dates) ->
  print_version(version, dates[version.tag]) for version in versions
