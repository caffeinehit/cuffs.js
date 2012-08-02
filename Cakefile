{spawn} = require 'child_process'

# Write out what's happening
log = (data)->
    process.stdout.write data.toString()

out = (obj)->
    obj.stdout.on 'data', log
    obj.stderr.on 'data', log

# Assuming you've got etags for CoffeeScript - https://gist.github.com/3237797
etags = (obj)->
    obj.stdout.on 'data', ->
        spawn 'etags', ['src/']


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
        spawn 'etags', ['src/']
        spawn 'r.js', ['-o', 'buildfiles/normal.js']

    spawn 'google-chrome', ['http://localhost:8888/test/test.html']


task 'compile', 'Compile coffee files', ->
    spawn 'coffee', ['-o', 'lib/', '-c', 'src/']


task 'build', 'Create files for distribution', ->
    one = spawn 'r.js', ['-o', 'buildfiles/bundled.js']
    two = spawn 'r.js', ['-o', 'buildfiles/standalone.js']
    three = spawn 'r.js', ['-o', 'buildfiles/normal.js']
    out one
    out two
    out three
