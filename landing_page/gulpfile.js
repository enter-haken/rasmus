var gulp = require('gulp');
var sass = require('gulp-sass');
var header = require('gulp-header');
var cleanCSS = require('gulp-clean-css');
var rename = require("gulp-rename");
var pkg = require('./package.json');

// Copy third party libraries from /node_modules into /vendor
gulp.task('vendor', function() {

  // Bootstrap
  gulp.src([
    './node_modules/bootstrap/dist/**/*.min.*',
    '!./node_modules/bootstrap/dist/**/*.map',
    '!./node_modules/bootstrap/dist/css/bootstrap-grid*',
    '!./node_modules/bootstrap/dist/css/bootstrap-reboot*'
  ]).pipe(gulp.dest('./dist/vendor/bootstrap'))

  // Font Awesome
  gulp.src([
    './node_modules/font-awesome/**/*.min.*',
    './node_modules/font-awesome/fonts/*',
    '!./node_modules/font-awesome/**/*.map',
    '!./node_modules/font-awesome/{less,less/*}',
    '!./node_modules/font-awesome/{scss,scss/*}',
    '!./node_modules/font-awesome/.*',
    '!./node_modules/font-awesome/*.{txt,json,md}'
  ]).pipe(gulp.dest('./dist/vendor/font-awesome'))

  // jQuery
  gulp.src([
    './node_modules/jquery/dist/*.min*',
    '!./node_modules/jquery/dist/*.map',
    '!./node_modules/jquery/dist/core.js'
  ]).pipe(gulp.dest('./dist/vendor/jquery'))

 
  // site images
  gulp.src(['./img/*']).pipe(gulp.dest('./dist/img'))

});

gulp.task('index', function() {
  gulp.src('./index.html')
    .pipe(gulp.dest('./dist'))
});

gulp.task('images', function() {
  gulp.src('./img/*')
  .pipe(gulp.dest('./dist/img'))
});


// Compile SCSS
gulp.task('css:compile', function() {
  return gulp.src('./scss/**/*.scss')
    .pipe(sass.sync({
      outputStyle: 'expanded'
    }).on('error', sass.logError))
    .pipe(gulp.dest('./dist/css'))
});

// Minify CSS
gulp.task('css:minify', ['css:compile'], function() {
  return gulp.src([
      './dist/css/*.css',
      '!./dist/css/*.min.css'
  ])
    .pipe(cleanCSS())
    .pipe(rename({
      suffix: '.min'
    }))
    .pipe(gulp.dest('./dist/css'))
});

// CSS
gulp.task('css', ['css:compile', 'css:minify']);

// Default task
gulp.task('default', ['index', 'images', 'css', 'vendor']);

gulp.task('deploy', function() {
    gulp.src('./dist/**')
    .pipe(gulp.dest('../docs'))
});
