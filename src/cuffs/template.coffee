define ['./ns', './compiler', './context', './utils'], (Cuffs, compiler, Context, utils) ->

    DOM_REGEX = /[^>]+>/
    BINDING_REGEX = /\s(data\-[\w\d\-]+)/gim
    SUBSTITUTION_REGEX = /#\{(.*?)\}/g
    BINDINGS = []

    class Template
        # A template holds all bindings that need to be rendered. It's
        # also interpolating all strings in attributes.
        elementAttrs: ['title', 'style', 'class', 'alt', 'id']
        constructor: (@node)->
            @bindings = []
            @callbacks = []
            @attrs = []
            @text = []
            @compile()

        compileTextNode: (node)->
            return if not (node.nodeType == Node.TEXT_NODE)
            vars = getVars node.textContent
            if vars.length > 0
                @text.push
                    node: node
                    text: node.textContent
                    vars: vars
                    
        compileElementAttrs: (node)->
            return if not (node.nodeType == Node.ELEMENT_NODE)
            for attr in @elementAttrs
                continue if not node.attributes[attr]?
                vars = getVars node.attributes[attr].value 
                @attrs.push
                    attr: attr
                    value: node.attributes[attr].value
                    vars: vars
                    node: node

        compileElementNode: (node)->
            return if not (node.nodeType == Node.ELEMENT_NODE)
            {stop, bindings} = Binding.init node
            @bindings = @bindings.concat bindings
            return stop 
            

        compile: ()->
            compiler.walk @node, (node, depth)=>
                @compileTextNode node
                @compileElementAttrs node
                return compiler.STOP_DESCENT if @compileElementNode node 
            this

        push: (binding)->
            @bindings.push binding

        applyContext: (context)->
            for binding in @bindings
                binding.applyContext context
            return 
            if utils.typeOf(context) == "function"
                for binding in @bindings
                    binding.applyContext context(binding.node)
                    
                for {node, text, vars} in @text
                    ctx = context node
                    
                    node.textContent = substitute text, context node
                    for pair in vars
                        console.log "watching", pair.name
                        context(node).watch pair.name, ->
                            node.textContent = substitute text, context(node)
                for {attrName, attrValue, vars, node} in @interpolations
                    node.attributes[attrName].value = substitute attrValue, context node
                    for pair in vars
                        context(node).watch pair.name, ->
                            node.attributes[attrName].value = substitute attrValue, context(node)
                            
            else
                for binding in @bindings
                    binding.applyContext context
                for {node, text, vars} in @text
                    node.textContent = substitute text, context
                    for pair in vars
                        console.log "watching 2", pair.name
                        context.watch pair.name, ->
                            console.log "watching 2 running on", pair.name
                            node.textContent = substitute text, context 
                for {attrName, attrValue, vars, node} in @interpolations
                    node.attributes[attrName].value = substitute attrValue, context
                    for pair in vars
                        context.watch pair.name, ->
                            node.attributes[attrName].value = substitute attrValue, context
            this

    class Binding
        # A binding maps a certain functionality to a `data-` attribute
        # on a HTML tag. When creating a binding, call `@bind` with
        # its name. Eg, to define a binding that alerts something from
        # its context, do this:
        #
        # 	class AlertBinding extends Binding
        # 		@bind 'data-alert'
        # 		applyContext: (context)->
        # 			alert context.get @attr
        #
        # 	<span data-alert="alert.message" />
        #
        #   new AlertBinding(node).applyContext(
        # 		new Context({alert: {message: "Hello, World" }}))
        #

        @bind: (name)->
            # Create a global registry of bindings by name
            BINDINGS[name] = this
            this::name = name
            this

        @getBindings: (node)->
            # Convenience function that returns all the node's binding
            # classes
            tag = node.outerHTML.match DOM_REGEX
            bindings = (b.trim() for b in (tag[0].match(BINDING_REGEX) or []))
            BINDINGS[b] for b in bindings.filter (b)-> BINDINGS[b]?

        @init: (node)->
            # Returns an object `{stop: true/false, bindings: []}`
            # where `stop` indicates if the recursion should be stopped
            stop = false
            bindings = []
            for Klass in Binding.getBindings node
                # We don't want to initialize further bindings if the
                # previous one ordered us to stop. Consider this:
                #
                # <li data-loop="a in b" data-show="a.visible"></li>
                #
                # `data-show` should initialize inside `data-loop`s
                # context because `a` is undefined in the current
                # context.
                break if stop

                b = new Klass node
                stop = true if b.stop
                bindings.push b

            return stop: stop, bindings: bindings

        # Don't stop recursive descent on this node
        stop: false

        constructor: (@node)->
            @attr = @node.getAttribute @name

        applyContext: (context)->
            return this

    render = (node, object)->
        # Convenience function
        new Template(node).applyContext(new Context object)

    getVars = (str)->
        results = []
        while ref = SUBSTITUTION_REGEX.exec(str)
            [raw, name] = ref
            results.push raw: raw, name: name
        results 

    substitute = (str, context)->
        # Do substitution of values from a context in a string, eg
        # "foo: #{bar}" replaces `#{bar}` with `context.get('bar')`

        vars = getVars str

        for {raw, name} in vars
            value = context.get name
            if value?
                str = str.replace raw, value
            else
                str = str.replace raw, ''

        str 


    optionize = (str, separator = ',')->
        obj = {}
        pairs = str.split separator

        for pair in pairs
            continue if not pair
            [key, val] = pair.split('=')
            obj[key] = val
        obj

    return Cuffs.Template = {
        getVars    : getVars
        optionize  : optionize
        substitute : substitute
        render     : render
        Binding    : Binding
        Template   : Template
    }