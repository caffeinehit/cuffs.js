define ['./compiler', './context', './utils'], (compiler, context, utils) ->
    {Context} = context

    DOM_REGEX = /[^>]+>/
    BINDING_REGEX = /\s(data\-[\w\d\-]+)/gim
    BINDINGS = []

    class Template
        # A template holds all bindings that need to be rendered.
        constructor: (@node)->
            @bindings = []
            @callbacks = []

        addCallback: (callback)->
            # Callbacks that are called on each binding
            # we encounter while compiling the template
            @callbacks.push callback

        compile: ()->
            compiler.walk @node, (node, depth)=>
                {stop, bindings} = Binding.init node
                for binding in bindings
                    @push binding
                    for callback in @callbacks
                        callback node, binding, depth
                return compiler.STOP_DESCENT if stop
            this

        push: (binding)->
            @bindings.push binding
            this

        applyContext: (context)->
            if utils.typeOf(context) == "function"
                binding.applyContext context(binding) for binding in @bindings
            else
                binding.applyContext context for binding in @bindings
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
        new Template(node).compile().applyContext(new Context object)

    render: render
    Template: Template
    Binding: Binding
