define ['./compiler', './context'], (compiler, context) ->
    {Context} = context

    DOM_REGEX = /[^>]+>/
    BINDING_REGEX = /data\-[\w\d\-]+/g
    BINDINGS = []

    class Template
        # A template holds all bindings that need to be rendered.
        constructor: (@node, @bindings = [])->
            compiler.walk @node, (node)=>
                {stop, bindings} = Binding.init node
                @push binding for binding in bindings
                return compiler.STOP_DESCENT if stop

        push: (binding)->
            @bindings.push binding
            this

        applyContext: (context)->
            if context !instanceof Context
                context = new Context context
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
            bindings = tag[0].match(BINDING_REGEX) or []
            BINDINGS[b] for b in bindings.filter (b)-> BINDINGS[b]?

        @init: (node)->
            # Given a `Template` instance, get all bindings from `node`
            # and push them into `template`.
            # Returns an object `{stop: true/false, bindings: []}`
            # where `stop` indicates if the recursion should be stopped
            stop = false
            bindings = []
            for Klass in Binding.getBindings node
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

    render: render
    Template: Template
    Binding: Binding
