define ['cuffs/compiler', 'cuffs/context', 'cuffs/template', 'cuffs/bindings', 'cuffs/controller', 'cuffs/application', 'cuffs/utils'], (compiler, context, template, bindings, controller, application, utils) ->

    {Context} = context
    {Template, Binding} = template
    {Application} = application

    return this.Cuffs = {
        Application: Application
        compiler: compiler
        Template: Template
        Context: Context
        Binding: Binding
        utils: utils
        bindings: bindings
        controller: controller
        apps: []
    }
