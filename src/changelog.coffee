

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

first_commit = get_first_commit()

get_start = if options.start is FIRST_COMMIT
  first_commit
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

all_tags = get_all_tags()
q.all([first_commit, all_tags, get_start, get_end]).then ([first_sha, tags, from, to]) ->
  tags.unshift first_sha
  tags.push HEAD
  get_start_index = find_rev_index_for_commit(from, tags)
  get_end_index = find_rev_index_for_commit(to, tags)

  q.all([get_start_index, get_end_index]).then ([start_index, end_index]) ->
    read_commits = []
    tags_steps = []
    if end_index isnt start_index
      for i in [start_index+1..end_index]
        from_tag = tags[i-1]
        to_tag = tags[i]
        tags_steps.push to_tag

        read_commits.push read_git_log(options.grep, from_tag, to_tag)
    else
      to_tag = tags[start_index]

    unless to_tag is to
      read_commits.push read_git_log(options.grep, to_tag, to)

    q.all(read_commits).then (commits_groups) ->
      commits_per_tag = []
      for commits,i in commits_groups
        current_tag = tags_steps[i]
        # We don't really want to have HEAD considered as a tag,
        # so we'll mark it as undefined
        current_tag = undefined if current_tag is HEAD
        commits_per_tag.push [current_tag, commits]

      console.log commits_per_tag
