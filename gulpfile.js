/* global require, console, process */

var gulp  = require('gulp');
var iced  = require('gulp-iced');
var clean = require('gulp-clean');
var spawn  = require("child_process").spawn;

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

var bjartur = (function() {
  'use strict';

  var server  = null;
  var obj     = {};

  obj.start = function() {
    if (server !== null) {
      console.log('Server already started...');
      return null;
    }

    console.log('Starting server...');

    var path = process.cwd() + '/dist/init.js';

    server = spawn('node', [path]);

    server.stdout.on('data', function(data) {
      console.log(data.toString());
    });
  };

  obj.stop = function() {
    if (server !== null) {
      console.log('Stopping server...');
      server.kill();
      server = null;
    }
  };

  obj.restart = function() {
    this.stop();
    this.start();
  };

  return obj;
}());

gulp.task('clean', function() {
  'use strict';

  return gulp.src(paths.clean, {read: false})
    .pipe(clean());
});

gulp.task('coffee', ['clean'], function() {
  'use strict';
  ice(paths.scripts, paths.dist);
});


gulp.task('default', ['coffee', 'clean']);

gulp.task('restart', ['default'], function() {
  'use strict';
  bjartur.restart();
});

gulp.task('watch', ['default', 'restart'], function() {
  'use strict';


  gulp.watch(paths.scripts, function(event) {
    if (event.type !== "changed") {
      return null;
    } else if (event.path.slice(-('.coffee'.length)) !== ".coffee") {
      return null;
    }

    console.log('Modified: ' + event.path);

    var re = /^(?:\/.*)\/bjartur(\/.*\/)+.*\.coffee$/;
    var newPath = event.path.match(re);
    if (newPath !== null) {
      ice(event.path, paths.dist + newPath);
    } else {
      ice(event.path, paths.dist);
    }


    bjartur.restart();
  });
});
