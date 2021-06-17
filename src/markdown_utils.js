
function reverseArray(array) {
  let a = [];
  for (let o of Array.from(array)) { a.unshift(o); }
  return a;
}

function lowerFirstChar(s) {
  return s.replace(/^\s*[^\s]/, m => m.toLowerCase());
}

function linkToIssue(...args) {
  let [repo, issue] = Array.from(args[0]);
  if (repo != null) {
    return util.format(EXTERNAL_LINK_ISSUE, repo, issue, repo, issue);
  } else {
    return util.format(LINK_ISSUE, issue, issue);
  }
}

function indent(s) {
  let lines = s.split('\n');
  let lastLine = lines.pop();
  let output = `  ${lines.join('\n  ')}`;
  output += lastLine.length > 0 ?
    `\n  ${lastLine}`
  :
    '\n';
  return output;
}

function linkToCommit(hash) {
  return util.format(LINK_COMMIT, hash.substr(0, 8), hash);
}

function currentDate() {
  let now = new Date();
  let pad = i => (`0${i}`).substr(-2);

  return util.format("%d-%s-%s", now.getFullYear(), pad(now.getMonth() + 1), pad(now.getDate()));
}

function findFixes(line, msg) {
  let issueRe = "([^\\s/]+/[^\\s#]+)?#(\\d+)";
  let re = new RegExp(`\
(?:\
close|closes|closed|\
fix|fixes|fixed|\
resolve|resolves|resolved\
)\
\\s\
${issueRe}\
`, 'i');

  let match = re.exec(line);

  if (match != null) {
    let [_, repo, issue] = Array.from(match);
    msg.closes.push([repo, issue]);
  }

  return (match == null);
}

function curateVersions (tagsSteps, commitsGroups) {
  let commits, tag;
  let commitsPerTag = [];
  for (let i = 0; i < commitsGroups.length; i++) {
    commits = commitsGroups[i];
    let current_tag = tagsSteps[i];
    // We don't really want to have HEAD considered as a tag,
    // so we'll mark it as undefined
    if (current_tag === HEAD) { current_tag = undefined; }
    commitsPerTag.push([current_tag, commits]);
  }

  let versions = [];

  for ([tag, commits] of Array.from(reverseArray(commitsPerTag))) {
    if (commits.length === 0) { continue; }

    let version = {
      tag,
      commits: {},
      breaks: []
    };

    for (let commit of Array.from(commits)) {
      if (commit.section != null) {
        (version.commits[commit.section] || (version.commits[commit.section] = [])).push(commit);
      }

      if (commit.breaking != null) { version.breaks.push(commit); }
    }

    versions.push(version);
  }

  return versions;
}

function getSectionConfig(name) {
  for (let section of Array.from(CONFIG.sections)) { if (section.name === name) { return section; } }
  return null;
};

function getCommitBody(commit, sectionConfig) {
  if (sectionConfig.include_body && (commit.body.length > 0)) {
    return indent(`<br>${commit.body}`);
  } else {
    return '';
  }
};

function getCommitCloses(commit) {
  let closes = commit.closes.map(linkToIssue).join(', ');
  if (closes.length > 0) {
    return `, ${closes}`;
  } else {
    return '';
  }
};

function getCommitOutput(commit, sectionConfig) {
  let closes = getCommitCloses(commit);
  let commitBody = getCommitBody(commit, sectionConfig);

  return `- ${commit.subject} (${linkToCommit(commit.hash)}${closes})${commitBody}\n`;
};

function printVersion(version, date) {
  let commit;
  let tag = version.tag != null ? version.tag : options.tag;
  stream.write(util.format(HEADER_TPL, tag, tag, date != null ? date : currentDate()));
  for (let sectionConfig of Array.from(CONFIG.sections)) {
    var commitOutput;
    let sectionName = sectionConfig.name;
    let commits = version.commits[sectionName];
    if (commits == null) { continue; }

    stream.write(`\n## ${sectionName}\n\n`);

    let nonGroupedCommits = commits.filter(commit => commit.group == null);
    var groupedCommits = {};
    commits.filter(commit => commit.group != null).forEach(function(commit) {
      if (!groupedCommits[commit.group]) { groupedCommits[commit.group] = []; }
      return groupedCommits[commit.group].push(commit);
    });

    for (let group in groupedCommits) {
      commits = groupedCommits[group];
      stream.write(`- **${group}**:\n`);
      for (commit of Array.from(commits)) {
        commitOutput = getCommitOutput(commit, sectionConfig);
        stream.write(indent(commitOutput));
      }
    }

    for (commit of Array.from(nonGroupedCommits)) {
      commitOutput = getCommitOutput(commit, sectionConfig);
      stream.write(commitOutput);
    }
  }

  let breakingCommits = version.breaks;
  if (breakingCommits.length) {
    stream.write('\n## Breaking Changes\n\n');
    for (commit of Array.from(breakingCommits)) {
      stream.write(`- due to ${linkToCommit(commit.hash)},${lowerFirstChar(commit.breaking)}\n`);
    }
  }

  return stream.write('\n');
};


function printVersions(versions, dates) {
  return Array.from(versions).map((version) =>
    printVersion(version, dates[version.tag]));
}
