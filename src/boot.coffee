q = require 'qq'
path = require 'path'
child = require 'child_process'
util = require 'util'

LAST_TAG = 'last-tag'
FIRST_COMMIT = 'first-commit'
HEAD = 'HEAD'
NONE = 'none'

GIT_LOG_CMD = 'git log %s -E --format=%s %s | cat'
GIT_LAST_TAG_CMD = 'git describe --tags --abbrev=0'
GIT_TAGS_CMD = 'git tag'
GIT_FIRST_COMMIT = 'git rev-list HEAD | tail -n 1'
GIT_COMMIT_SEARCH = 'git name-rev --name-only '

options =
  grep: '^Add|^Fix|^Remove|^:bug:|Breaking'
  start: LAST_TAG
  end: HEAD
