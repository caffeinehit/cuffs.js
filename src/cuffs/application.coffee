define ['cuffs/compiler', 'cuffs/context', 'cuffs/template'], (compiler, context, template)->

    {walk} = compiler
    {Context} = context
    {Template} = template


    class Application
        @__id__: 0
        @id: -> ++ Application.__id__
        constructor: (@node)->
            @context = new Context
            @initControllers()
            @initTemplate()

        initControllers: ()->
            @controllers = {}
            walk @node, (node)->
                if not ctrl = node.getAttribute 'data-controller'
                    return

                id = Application.id()
                context = @context.new()
                Controller = lookup node.getAttribute 'data-controller'

                controller = new Controller context
                @controllers[id] = id
                $(node).attr('data-controller-id', id)



        initTemplate: ()->
            @template = new Template @node
            @template.applyContext @context

    return {
        Application: Application
    }
