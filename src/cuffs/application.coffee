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
        _controller_names: {}
        _controller_ctor: {}
        _controller_depths: {}

        constructor: (@node)->
            @context = new Context
            @initControllers()
            @initTemplate()

        initControllers: ()->

            walk @node, (node, depth)=>
                if not classpath = node.getAttribute 'data-controller'
                    return

                id = Application.id()
                Controller = lookup classpath
                controller = new Controller this, @context.new()
                @_controller_ids[id] = controller
                @_controller_names[classpath] = controller
                @_controller_ctor[Controller] = controller

                if @_controller_depths[depth]?
                    @_controller_depths[depth].push controller
                else
                    @_controller_depths[depth] = [controller]

                $(node).attr('data-controller-id', id)

        initTemplate: ()->
            @template = new Template @node
            @template.applyContext @context

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
