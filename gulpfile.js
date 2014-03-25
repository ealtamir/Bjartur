/* global require, console */

var gulp = require("gulp");
var iced = require("gulp-iced");

var paths = {
  scripts: ["./*.coffee", "./**/*.coffee", "!./node_modules/**"],
};

gulp.task("default", function() {
  "use strict";

  gulp.src(paths.scripts)
    .pipe(iced().on("error", function(err) {
      console.dir(err);
    }))
    .pipe(gulp.dest("./dist"));
});
