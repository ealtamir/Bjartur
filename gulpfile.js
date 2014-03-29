/* global require, console, process */

var gulp  = require('gulp');
var iced  = require('gulp-iced');
var clean = require('gulp-clean');
var nodemon = require('gulp-nodemon');

var paths = {
  dist: './dist',
  scripts: ['./*.coffee', './**/*.coffee', '!./node_modules/**'],
  clean: ['./dist/**']
};

var ice = function(src, dst) {
  'use strict';

  gulp.src(src)
    .pipe(iced().on('error',
      function(err) {
        console.dir(err);
      })
    )
    .pipe(gulp.dest(dst));
};


gulp.task('clean', function() {
  'use strict';
  return gulp.src(paths.clean, {read: false})
    .pipe(clean());
});

gulp.task('coffee', function() {
  'use strict';
  ice(paths.scripts, paths.dist);
});


gulp.task('default', ['coffee']);

gulp.task('nodemon', ['coffee'], function() {
  'use strict';
  var server = nodemon({
    script: process.cwd() + '/dist/init.js',
    ext: 'coffee',
    ignore: './node_modules'
  });
  server.on('change', ['coffee'], function() {
    var a = function() {
      server.emit('restart');
    };
    setTimeout(a, 1000);
  });
  server.on('restart', function() {
    console.log('Server restarted...');
  });

});
gulp.task('watch', ['nodemon'], function() {
  'use strict';
  gulp.watch(paths.scripts, ['nodemon']);
});

