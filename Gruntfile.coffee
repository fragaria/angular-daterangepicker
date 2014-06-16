module.exports = (grunt) ->

    # Project configuration.
    grunt.initConfig
        pkg: grunt.file.readJSON("package.json")

        coffee:
            compileJoined:
                options:
                    join: true
                files:
                    'js/angular-daterangepicker.js': ['coffee/angular-daterangepicker.coffee']

        watch:
            files: ['example.html', 'coffee/*.coffee']
            tasks: ['coffee']

        uglify:
            options:
                sourceMap: true
            target:
                files:
                    'js/angular-daterangepicker.min.js': ['js/angular-daterangepicker.js']
        wiredep:
            target:
                src: [
                    './example.html'
                ]


    grunt.loadNpmTasks("grunt-contrib-coffee")
    grunt.loadNpmTasks("grunt-contrib-watch")
    grunt.loadNpmTasks('grunt-contrib-uglify')
    grunt.loadNpmTasks('grunt-wiredep')

    # Default task(s).
    grunt.registerTask "default", ["coffee"]
    grunt.registerTask "develop", ["coffee", "watch"]
    grunt.registerTask "dist", ["coffee", "uglify"]
