
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
all_tags_date = all_tags.then (tags) ->
  q.all(tags.map (tag)-> get_date_of_tag(tag))
  .then (tags_date) ->
    o = {}
    for date,i in tags_date
      o[tags[i]] = date
    o

q.all([first_commit, all_tags, get_start, get_end, all_tags_date]).then ([first_sha, tags, from, to, tags_date]) ->
  tags = tags.sort(natural_sort)
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

        read_commits.push read_git_log(from_tag, to_tag)
    else
      to_tag = tags[start_index]

    unless to_tag is to
      read_commits.push read_git_log(options.grep, to_tag, to)

    q.all(read_commits)
    .then(curate_versions(tags_steps))
    .then (versions) ->
      print_versions(versions, tags_date)
    .fail (reason) ->
      console.error reason
