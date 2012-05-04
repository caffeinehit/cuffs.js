define ['./template'], ({Binding, Template})->

    class DataShow extends Binding
        # Make element visible depending if the context's attribute
        # is not falsy, eg:
        # <div data-show="todo.done"></div>

        @bind 'data-show'

        toggle: (value)->
            if value
                @node.style.display = ""
            else
                @node.style.display = "none"

        applyContext: (context)->
            context.watch @attr, (value)=> @toggle value
            @toggle context.get @attr
            this

    class DataAttr extends Binding
        # Sets an attribute on the current node, eg:
        # <img src="foo.png" data-set-attr="alt=img.desc" />
        @bind 'data-attr'
        constructor: (node)->
            super node
            [@attrName, @contextName] = @attr.split '='
        setAttr: (value)->
            $(@node).attr @attrName, value
        applyContext: (context)->
            context.watch @contextName, (val)=> @setAttr val
            @setAttr context.get @contextName


    class DataOr extends Binding
        # Picks one of two choices to set as the content of
        # a node, eg:
        # <span data-or="todo.done ? Todo is done : Todo is not done"></span>
        @bind 'data-or'
        constructor: (node)->
            super node
            [@predicate, values] = @attr.split('?')
            [@true, @false] = values.split(':')

            @predicate = @predicate.trim()

        setValue: (value)->
            if value
                @node.innerHTML = @true.trim()
            else
                @node.innerHTML = @false.trim()

        applyContext: (context)->
            context.watch @predicate, (value)=> @setValue value
            @setValue context.get @predicate


    class DataBind extends Binding
        # Create two way binding of data between elements and the
        # model. It's reasonably smart, so it handles normal content
        # and different input types, eg:
        #
        # <input type="text" data-bind="todo.name" value="" />
        # <input type="checkbox" data-bind="todo.done" />
        # <span data-bind="todo.name"></span>

        @bind 'data-bind'

        constructor: (@node)->
            @type = @node.type
            super @node

        setValue: (value)->
            if not @type?
                @node.innerHTML = value
            else if @type == 'text'
                @node.value = value
            else if @type == 'checkbox'
                $(@node).attr 'checked', value
            else
                throw new Error "Unknown type to bind to: #{@type}"
            this

        getValue: ()->
            if not @type?
                @node.html()
            else if @type == 'text'
                @node.value
            else if @type == 'checkbox'
                $(@node).is ':checked'
            else
                throw new Error "Unknown type to bind to: #{@type}"

        applyContext: (context)->
            context.watch @attr, (value)=> @setValue value
            $(@node).change ()=> context.set @attr, @getValue()
            @setValue context.get @attr
            this


    class DataClick extends Binding
        # Call a method on the context when the tag is clicked, eg:
        # <a data-click="markDone" href="#">Click Me</a>

        applyContext: (context)->
            $(@node).click => context.get(@attr)(@node)
            this

    class DataSet extends Binding
        # Sets a certain value on the model. Sometimes useful. Eg:
        # <ul data-set="active=one">...</ul>

        @bind 'data-set'
        applyContext: (context)->
            [name, value] = @attr.split '='
            context.set(name, value)

    class DataActivate extends Binding
        # Gives an element an `active` class depending on if the
        # context property matches the attribute, eg:
        # <ul><li data-activate="active==one"/></ul>

        @bind 'data-activate'
        constructor: (node)->
            super node
            [@watchName, @watchValue] = @attr.split '=='

        activate: (value)->
            if value == @watchValue
                $(@node).addClass 'active'
            else
                $(@node).removeClass 'active'

        applyContext: (context)->
            context.watch @watchName, (value)=> @activate value
            $(@node).click ()=> context.set @watchName, @watchValue
            @activate context.get @watchName


    class DataLoop extends Binding

        @bind 'data-loop'
        # Stop recursive descent on this node
        stop: true

        constructor: (node)->
            @attr = node.getAttribute @name
            @parentElement = node.parentElement
            @template = node.cloneNode true

            $(@template).removeAttr 'data-loop'

            $(node).remove()

            [@elementName, _, @iterableName] = @attr.split ' '

            @nodes = []
            @contexts = []

        renderIterable: (context, iterable)->
            iterable = iterable or []
            @nodes = []
            @contexts.shift().destroy() while @contexts.length > 0

            @parentElement.innerHTML = ''

            for element in iterable
                ctx = context.new()
                ctx[@elementName] = element
                @contexts.push ctx

                clone = @template.cloneNode true
                @nodes.push clone
                tpl = new Template clone
                # Creating a template instance does not take
                # into account bindings on the root element
                # so we have to do that manually
                {bindings} = Binding.init clone
                tpl.push binding for binding in bindings

                tpl.applyContext ctx

            @parentElement.appendChild node for node in @nodes
            this

        applyContext: (context)->
            context.watch @iterableName, (iterable)=>
                @renderIterable context, iterable
            @renderIterable context, context.get @iterableName
            this



    class DataPushState extends Binding
        @bind 'data-push-state'

        applyContext: (context)->
            $(@node).click ()->
                title = $(this).attr 'title'
                href = $(this).attr 'href'
                History.pushState {}, title, href


    return {
        DataShow: DataShow
        DataBind: DataBind
        DataClick: DataClick
        DataLoop: DataLoop
        DataSet: DataSet
        DataActivate: DataActivate
        DataAttr: DataAttr
        DataOr: DataOr
    }