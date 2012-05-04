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
        constructor: (@node)->
            @context = new Context
            @initControllers()
            @initTemplate()

        initControllers: ()->
            @controllers = {}
            walk @node, (node)=>
                if not ctrl = node.getAttribute 'data-controller'
                    return

                id = Application.id()
                Controller = lookup node.getAttribute 'data-controller'
                controller = new Controller @context
                @controllers[id] = controller
                $(node).attr('data-controller-id', id)



        initTemplate: ()->
            @template = new Template @node
            @template.applyContext @context

    return {
        Application: Application
    }
