const fs = require('fs');
const path = require('path');
const util = require('util');
const CSON = require('cson');
const child = require('child_process');
const naturalSort = require('javascript-natural-sort');

const LAST_TAG = 'last-tag';
const FIRST_COMMIT = 'TAIL';
const HEAD = 'HEAD';
const NONE = 'none';

const GIT_LOG_CMD = 'git log -E --format=%s %s | cat';
const GIT_LAST_TAG_CMD = 'git describe --tags --abbrev=0';
const GIT_TAGS_CMD = 'git tag';
const GIT_FIRST_COMMIT = 'git rev-list HEAD | tail -n 1';
const GIT_COMMIT_SEARCH = 'git name-rev --name-only ';
const GIT_TAG_COMMIT = 'git rev-parse %s';
const GIT_COMMIT_DATE = s => `git show -s --format=%ci ${s}`;

const DEFAULT_CONFIG = path.resolve(__dirname,  '..', 'config', 'default.cson');

const options = {
  start: LAST_TAG,
  end: HEAD
};

function firstToExist(...files) {
  for (let file of Array.from(files)) {
    if (fs.existsSync(file)) { return file; }
  }
};

function warn() {
  return console.error("WARNING:", util.format.apply(null, arguments));
};

function error(e) {
  if (e.stack != null) {
    console.error(e.stack);
  } else {
    console.error("Error:", util.format.apply(null, [e]));
  }
  return process.exit();
};

function stringOrURL(field) {
  return typeof field === 'string'
    ? field
    : (field != null ? field.url : undefined);
};

let [node, binPath, ...args] = Array.from(process.argv);

while (args.length) {
  let option = args.shift();

  switch (option) {
    // Commands
    case '--repo': case '-r':
      options.repo = args.shift();
      break;
    case '--config': case '-c':
      options.config = args.shift();
      break;
    case '--start': case '-s':
      options.start = args.shift();
      break;
    case '--end': case '-e':
      options.end = args.shift();
      break;
    case '--angular': case '-a':
      options.config = path.resolve(__dirname,  '..', 'config', 'angular.cson');
      break;
    default:
      options.tag = option;
  }
}

const PACKAGE_JSON_PATH = path.resolve('.', 'package.json');
const PACKAGE_JSON = fs.existsSync(PACKAGE_JSON_PATH)
  ? require(PACKAGE_JSON_PATH)
  : (options.repo == null
      ? error("Can't locate a package.json in the current directory. Please at least specify the --repo option")
      : { repository: options.repo });

const GITHUB_URL = 'https://github.com/';
const REPO_URL = stringOrURL(PACKAGE_JSON.repository);
let ISSUE_URL = stringOrURL(PACKAGE_JSON.bugs);
let COMMIT_URL = stringOrURL(PACKAGE_JSON.commits);

if (ISSUE_URL == null) {
  if ((REPO_URL != null) && (REPO_URL.indexOf('http') === 0)) {
    ISSUE_URL = REPO_URL + '/issues';
  } else {
    error("Can't locate the `bugs` field in package.json");
  }
}

if (COMMIT_URL == null) {
  warn("Can't locate the `commits` field in package.json, building it using bugs url");
  COMMIT_URL = ISSUE_URL.replace('issues', 'commit');
}

const HEADER_TPL = "\n<a name=\"%s\"></a>\n# %s (%s)\n";
const LINK_ISSUE = `[#%s](${ISSUE_URL}/%s)`;
const EXTERNAL_LINK_ISSUE = `[%s#%s](${GITHUB_URL}%s/issues/%s)`;
const LINK_COMMIT = `[%s](${COMMIT_URL}/%s)`;

const stream = process.stdout;

let configFilePaths = [
  DEFAULT_CONFIG
];

if (options.config != null) {
  configFilePaths.unshift(options.config);
} else {
  configFilePaths.unshift(path.resolve('.', 'changelog.cson'));
  configFilePaths.unshift(path.resolve('.', 'changelog.json'));
}

let configFile = firstToExist(...Array.from(configFilePaths || []));

const CONFIG = /\.cson$/.test(configFile)
  ? CSON.parse(fs.readFileSync(configFile).toString())
  : require(configFile);

if (CONFIG.sections == null) { error(`Can't locate the \`sections\` field in ${configFile}`); }

for (let i = 0; i < CONFIG.sections.length; i++) {
  const section = CONFIG.sections[i];
  section.regexp = new RegExp(section.match);
}
