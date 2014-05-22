{exec} = require 'child_process'

module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

    coffee:
      options:
        bare: true
      glob_to_multiple:
        expand: true
        cwd: 'src'
        src: ['*.coffee']
        dest: 'bin'
        ext: ''

    coffeelint:
      options:
        no_backticks:
          level: 'ignore'
        no_empty_param_list:
          level: 'error'
        max_line_length:
          level: 'ignore'

      src: ['src/*.coffee']

    watch:
      scripts:
        files: [
          'src/**/*.coffee'
        ]
        tasks: [
          'coffee'
        ]

    chmod:
      default:
        options: ''

  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-coffeelint')
  grunt.loadNpmTasks('grunt-contrib-watch')

  grunt.registerTask('lint', ['coffeelint:src', 'coffeelint:test'])
  grunt.registerTask('default', ['coffeelint', 'coffee', 'chmod'])

  grunt.registerMultiTask 'chmod', -> exec 'chmod +x ./bin/changelog'
