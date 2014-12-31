browserify = require('browserify')
gulp = require('gulp')
less = require('gulp-less')
source = require('vinyl-source-stream')
watchify = require('watchify')

buildBrowserify = ->
  browserify({
    cache: {}
    packageCache: {}
    fullPaths: true
    entries: [
      './js/show.coffee'
    ]
    extensions: [ '.js', '.coffee', '.jade' ]
    debug: true
  })
    .transform('coffeeify')
    .transform('jadeify')

gulp.task 'browserify', ->
  buildBrowserify()
    .plugin('minifyify', map: 'show.js', output: './public/js/show.js.map')
    .bundle()
    .on('error', console.warn)
    .pipe(source('show.js'))
    .pipe(gulp.dest('./public/js'))

gulp.task 'browserify-dev', ->
  bundler = watchify(buildBrowserify(), watchify.args)

  rebundle = ->
    bundler.bundle()
      .on('error', console.warn)
      .pipe(source('show.js'))
      .pipe(gulp.dest('./public/js'))

  bundler.on('update', rebundle)
  rebundle()

gulp.task 'less', ->
  gulp.src('./css/show.less')
    .pipe(less())
    .pipe(gulp.dest('public/css'))

gulp.task 'dev', [ 'browserify-dev', 'less' ], ->
  gulp.watch('./css/**/*', [ 'less' ])

gulp.task 'dist', [ 'browserify', 'less' ]

gulp.task 'default', [ 'dev' ], ->
  # Start a web server
  require('./server')
