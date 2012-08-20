define (require)->
    Cuffs      = require './ns'
    {walk}     = require './compiler'
    Context    = require './context'
    {Template} = require './template'


    # Looks up objects on the global classpath, eg:
    # lookup('window.document.body')
    lookup = (classpath)->
        parts = classpath.split '.'
        current = this

        for part in parts
            current = current[part]

            if not current?
                throw new Error "Not found: #{classpath}"

        current

    class Application
        # Used for looking up controller instances by their
        # constructor
        _controller_ctor: {}

        constructor: (@node, @callback = (->))->
            @context = new Context $app: this
            @template = new Template @node
            @template.applyContext @context 
            @callback()

        getController: (Klass)->
            @_controller_ctor[Klass]

        addController: (Klass, instance)->
            @_controller_ctor[Klass] = instance


        @start: (callback)->
            # Start all applications. If a callback is provided, call
            # it after everything is done.
            Cuffs.apps = $('[data-app]').map ->
                new Application this, callback


    return Cuffs.Application =  Application
