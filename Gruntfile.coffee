module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    # sass:
    #   src: 'src/sass/*'
    #   build: 'public/css/styles.css'

    project:
      app: 'public'
      assets: '<%= project.app %>/assets'
      src: 'src'
      css: [
        '<%= project.src %>/sass/*'
      ]
      js: [
        '<%= project.src %>/coffee/*'
      ]

    watch:
      options:
        livereload:
          port: 35729
          key: grunt.file.read('src/server.key')
          cert: grunt.file.read('src/server.crt')
      coffeescripts:
        files: ['<%= project.js %>']
        tasks: ['coffee:dev']
        options:
          spawn: false
          livereload: true
      stylesheets:
        files: ['<%= project.css %>']
        tasks: ['sass']
        options:
          spawn: false
          livereload: true
      html:
        files: ['<%= project.app %>/*.html']
        options:
          livereload: true

      js:
        files: '<%= project.assets %>/js/test.js'
        tasks: ['jshint']

    jshint:
      all: ['<%= project.assets %>/js/test.js']

    coffee:
      dev:
        options:
          sourceMap: true
        files:
          '<%= project.assets %>/js/app.js': '<%= project.js %>'
      dist:
        files:
          '<%= project.assets %>/js/app.js': '<%= project.js %>'

    connect:
      server:
        options:
          protocol: 'https'
          port: 8000
          hostname: 'smoke.dev'
          base: 'public'
          keepalive: true

    sass:
      dev:
        options:
          style: 'expanded'
          # sourceMap: true
        files:
          '<%= project.assets %>/css/style.css': '<%= project.css %>'
      dist:
        options:
          style: 'compressed'
        files:
          '<%= project.assets %>/css/style.css': '<%= project.css %>'

  grunt.loadNpmTasks 'grunt-contrib-sass'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-jshint'
  grunt.loadNpmTasks('grunt-contrib-connect')
  grunt.loadNpmTasks('grunt-contrib-jasmine')
