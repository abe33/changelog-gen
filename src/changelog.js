async function main() {
  const firstCommit = await getFirstCommit();

  let from;
  let to;

  if (options.start === FIRST_COMMIT) {
    from = await firstCommit;
  } else if (options.start === LAST_TAG) {
    from = await getPreviousTag();
  } else {
    from = options.start;
  }

  if (options.end === LAST_TAG) {
    to = await getPreviousTag();
  } else {
    to = options.end;
  }
  try {

    let tags = await getAllTags();
    const allTagsDate = await Promise.all(tags.map(tag => getDateOfTag(tag)))
    const tagsDates = {};
    for (let i = 0; i < allTagsDate.length; i++) {
      let date = allTagsDate[i];
      tagsDates[tags[i]] = date;
    }

    tags = tags.sort(naturalSort);
    tags.unshift(firstCommit);
    tags.push(HEAD);

    const startIndex = await findRevIndexForCommit(from, tags);
    const endIndex = await findRevIndexForCommit(to, tags);

    let toTag;
    const readCommits = [];
    const tagsSteps = [];
    if (endIndex !== startIndex) {
      for (let start = startIndex+1, i = start, end = endIndex, asc = start <= end; asc ? i <= end : i >= end; asc ? i++ : i--) {
        let from_tag = tags[i-1];
        toTag = tags[i];
        tagsSteps.push(toTag);

        readCommits.push(readGitLog(from_tag, toTag));
      }
    } else {
      toTag = tags[startIndex];
    }

    if (toTag !== to) {
      readCommits.push(readGitLog(options.grep, toTag, to));
    }

    const commitsGroups = await Promise.all(readCommits);
    const versions =  curateVersions(tagsSteps, commitsGroups);

    printVersions(versions, tagsDates);
  } catch(reason) {
    error(reason);
  }

}

main();
