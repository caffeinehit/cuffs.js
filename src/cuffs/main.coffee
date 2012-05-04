define ['cuffs/compiler', 'cuffs/context', 'cuffs/template', 'cuffs/bindings', 'cuffs/controller', 'cuffs/application'], (compiler, context, template, bindings, controller, application) ->

    {Context} = context
    {Template, Binding} = template
    {Application} = application

    # Auto startup
    $ ->
        $('[data-app]').each ->
            new Application this

    # Register global namespace
    return this.Cuffs = {
        Application: Application
        compiler: compiler
        Template: Template
        Context: Context
        Binding: Binding
        bindings: bindings
        controller: controller
    }
