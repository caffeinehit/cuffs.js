define ['cuffs/compiler', 'cuffs/context', 'cuffs/template'], (compiler, context, template)->

    {walk} = compiler
    {Context} = context
    {Template} = template

    lookup = (classpath)->
        parts = classpath.split '.'
        current = this

        for part in parts
            current = current[part]

            if not current?
                throw new Error "Not found: #{classpath}"

        current

    class Application
        @__id__: 0
        @id: -> ++ Application.__id__

        _controller_ids: {}
        _controller_context_ids: {}
        _controller_ctor: {}


        constructor: (@node)->
            @context = new Context
            @initControllers()
            @initTemplate()

        initControllers: ()->

            walk @node, (node, depth)=>
                if not classpath = node.getAttribute 'data-controller'
                    return

                id = Application.id()
                context = @getParentContext(node).new()
                Controller = lookup classpath
                controller = new Controller app: this, context: context

                @_controller_ids[id] = controller
                @_controller_context_ids[id] = context
                @_controller_ctor[Controller] = controller

                $(node).attr('data-controller-id', id)

            for own id, ctrl of @_controller_ids
                ctrl.init() if ctrl.init?

        initTemplate: ()->
            @template = new Template(@node).compile()
            @template.applyContext (binding)=>
                @getParentContext binding.node

        getParentContext: (node)->
            if id = node.getAttribute('data-controller-id')
                return @_controller_context_ids[id]
            while node = node.parentElement
                break if not node?
                if id = node.getAttribute('data-controller-id')
                    return @_controller_context_ids[id]
            return @context

        getController: (Controller)->
            # Return a controller by constructor
            @_controller_ctor[Controller]

        getControllerById: (id)->
            # Return a controller by id
            @_controller_ids[id]

        getControllerByName: (name)->
            # Return a controller by classpath
            @_controller_names[name]

    return {
        Application: Application
    }
