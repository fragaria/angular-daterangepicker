module.exports = (grunt) ->

    # Project configuration.
    grunt.initConfig
        pkg: grunt.file.readJSON("package.json")

        coffee:
            compileJoined:
                options:
                    join: true
                files:
                    'js/daterangepicker.js': ['coffee/daterangepicker.coffee']

        watch:
            files: ['index.html', 'coffee/*.coffee']
            tasks: ['coffee']

        uglify:
            options:
                sourceMap: true
            target:
                files:
                    'js/daterangepicker.min.js': ['js/daterangepicker.js']


    grunt.loadNpmTasks("grunt-contrib-coffee")
    grunt.loadNpmTasks("grunt-contrib-watch")
    grunt.loadNpmTasks('grunt-contrib-uglify');

    # Default task(s).
    grunt.registerTask "default", ["coffee"]
    grunt.registerTask "develop", ["coffee", "watch"]
    grunt.registerTask "dist", ["coffee", "uglify"]
