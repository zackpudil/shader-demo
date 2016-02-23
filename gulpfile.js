var gulp = require("gulp");
var browserify = require("browserify");
var source = require("vinyl-source-stream");

gulp.task("build", function () {
	var b = browserify("./src/main.js", { debug: true })
		.transform("babelify", { presets: ['es2015'] })
		.transform("glslify");

	return b.bundle()
		.pipe(source("app.js"))
		.pipe(gulp.dest("./"));
});

gulp.task("default", ["build"], function () {
	gulp.watch(["src/**/*.js", "shaders/**/*.glsl"], ['build']);
});
