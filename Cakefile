{spawn} = require 'child_process'

# Write out what's happening
log = (data)->
    process.stdout.write data.toString()

out = (obj)->
    obj.stdout.on 'data', log
    obj.stderr.on 'data', log


task 'watch', 'Watch and compile', ->
    coffee = spawn 'coffee', ['-w', '-o', 'lib/', '-c', 'src/']
    coffee.stdout.on 'data', ->
        console.log 'Building normal.js'
        spawn 'r.js', ['-o', 'buildfiles/normal.js']
    out coffee


task 'develop', 'Run a dev server', ->
    httpd = spawn 'python', ['-m', 'SimpleHTTPServer', '8888']
    coffee = spawn 'coffee', ['-w', '-o', 'lib/', '-c', 'src/']
    tests = spawn 'coffee', ['-w', '-o', 'test/', '-c', 'test/']

    out httpd
    out coffee
    out tests

    coffee.stdout.on 'data', ->
        spawn 'r.js', ['-o', 'buildfiles/normal.js']

    spawn 'xdg-open', ['http://localhost:8888/test/test.html']


compile = ->
    spawn 'coffee', ['-o', 'lib/', '-c', 'src/']

task 'compile', 'Compile coffee files', ->
    compile()

task 'build', 'Create files for distribution', ->
    compile()
    out spawn 'r.js', ['-o', 'buildfiles/normal.js']
    out spawn 'r.js', ['-o', 'buildfiles/minified.js']


