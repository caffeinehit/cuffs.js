define ["cuffs/compiler"], (compiler)->
    walking_the_dom_tree = document.getElementById 'walking_the_dom_tree'
    describe 'Compiler', ->
        describe 'walking the dom tree', ->
            it 'should call a callback function on each node', ->
                num = 0
                compiler.walk walking_the_dom_tree, (node, depth)->
                    if node.nodeType == Node.ELEMENT_NODE
                        console.log depth, node
                        num += 1
                expect(num).to.be 8

            it 'should stop descending if we return `STOP_DESCENT` from the callback', ->
                num = 0
                compiler.walk walking_the_dom_tree, (node, depth)->
                    if node.nodeType == Node.ELEMENT_NODE
                        return compiler.STOP_DESCENT if depth == 2
                        num += 1
                expect(num).to.be 2
