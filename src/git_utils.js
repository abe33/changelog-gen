async function exec(cmd, errMsg='') {
  return new Promise((resolve, reject) => {
    child.exec(cmd, (code, stdout, stderr) => {
      if (code) {
        reject(errMsg);
      } else {
        resolve(stdout);
      }
    });
  });
}

async function findRevIndexForCommit(commit, tags) {
  if (Array.from(tags).includes(commit)) {
    return tags.indexOf(commit);
  } else {
    const tag = await getTagOfCommit(commit, tags);
    return tags.indexOf(tag) - 1;
  }
}

function filterCommit(commit) {
  if (commit == null) { return false; }
  const {subject, breaking, closes} = commit;
  if (subject == null) { return false; }

  for (let section of Array.from(CONFIG.sections)) {
    const {regexp, name} = section;
    var match = regexp.exec(subject);
    if (match != null) {
      commit.section = name;
      if (section.replace != null) {
        commit.subject = section.replace.replace(/\\(\d)/g, (m,i) => match[i] != null ? match[i] : '');
      }

      if (section.grouping_capture != null) {
        commit.group = match[section.grouping_capture];
      }

      return true;
    }
  }

  if (breaking != null) { return true; }

  return false;
}

async function getCommitOfTag(tag) {
  const cmd = util.format(GIT_TAG_COMMIT, tag);
  const stdout = await exec(cmd, `Can't find the commit for tag ${tag}`);
  return stdout.replace('\n', '');
}

async function getDateOfCommit(commit) {
  const cmd = GIT_COMMIT_DATE(commit);
  const stdout = await exec(cmd, `Can't find the commit ${commit}`);
  return stdout.split('\n').slice(-2)[0].split(' ')[0];
}

async function getDateOfTag(tag) {
  const commit = await getCommitOfTag(tag);
  return getDateOfCommit(commit);
}

async function getTagOfCommit(sha, tags) {
  const cmd = GIT_COMMIT_SEARCH + sha;
  try {
    const stdout = await exec(cmd);
    const res = stdout.replace('\n', '');
    const [tag, offset] = Array.from(res.split('~'));
    if (!Array.from(tags).includes(tag)) { tag = 'HEAD'; }
    return tag;
  } catch(e) {
    return getFirstCommit();
  }
}

async function getAllTags() {
  try {
    const stdout = await exec(GIT_TAGS_CMD);
    return stdout.split('\n').filter(s => s.length !== 0);
  } catch(e) {
    return [];
  }
}

async function getPreviousTag() {
  try {
    const stdout = await exec(GIT_LAST_TAG_CMD);
    return stdout.replace('\n', '');
  } catch {
    return getFirstCommit()
  }
}

async function getFirstCommit() {
  const stdout = await exec(GIT_FIRST_COMMIT, 'Cannot get the first commit.');
  return stdout.replace('\n', '');
}

function parseRawCommit(raw) {
  if (raw == null) { return null; }

  let lines = raw.split('\n');
  const msg = {};
  msg.hash = lines.shift();
  msg.subject = lines.shift();
  msg.closes = [];

  lines = lines.filter(line => findFixes(line, msg));

  msg.body = lines.join("\n");
  const breakingRe = /(?:BREAKING CHANGE|:warning):([\s\S]*)/;
  const match = msg.body.match(breakingRe);
  if (match) {
    msg.breaking = match[1];
    msg.body = msg.body.replace(breakingRe, '');
  }

  return msg;
}

async function readGitLog(from, to) {
  if (to == null) { to = 'HEAD'; }

  const range = from != null ? `${from}..${to}` : '';
  const cmd = util.format(GIT_LOG_CMD, '%H%n%s%n%b%n==END==', range);
  const stdout = await exec(cmd, 'Unable to retrieve git logs');

  return stdout
    .split('\n==END==\n')
    .map(rawCommit =>
      rawCommit
        .split('\n')
        .filter(s => s.length)
        .join('\n'))
    .map(parseRawCommit)
    .filter(filterCommit);
}
