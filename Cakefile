{spawn} = require 'child_process'

log = (data)->
    process.stdout.write data.toString()

out = (obj)->
    obj.stdout.on 'data', log
    obj.stderr.on 'data', log

etags = (obj)->
    obj.stdout.on 'data', ->
        spawn 'etags', ['src/']

task 'develop', 'Run a dev server', ->
    httpd = spawn 'python', ['-m', 'SimpleHTTPServer', '8888']
    coffee = spawn 'coffee', ['-w', '-o', 'lib/', '-c', 'src/']
    tests = spawn 'coffee', ['-w', '-o', 'test/', '-c', 'test/']
    out httpd
    out coffee
    out tests

    coffee.stdout.on 'data', ->
        spawn 'etags', ['src/']
        invoke 'build'

    spawn 'google-chrome', ['http://localhost:8888/test/test.html']

task 'compile', 'Compile coffee files', ->
    spawn 'coffee', ['-o', 'lib/', '-c', 'src/']

task 'build', 'Create a minified files for distribution', ->
    one = spawn 'r.js', ['-o', 'build-bundled.js']
    two = spawn 'r.js', ['-o', 'build-standalone.js']
    three = spawn 'r.js', ['-o', 'build-normal.js']
    out one
    out two
    out three
