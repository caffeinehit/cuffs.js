define ['./template', './utils'], ({Binding, Template}, utils)->

    class DataShow extends Binding
        # Make element visible depending if the context's attribute
        # is not falsy, eg:
        # <div data-show="todo.done"></div>
        # <div data-show="todo.done==0"></div>
        # <div data-show="todo.done!=0"></div>

        @bind 'data-show'

        constructor: (@node)->
            super node
            notEqual = /.*!=.*/
            equal = /.*==.*/

            if notEqual.test @attr
                [@attrName, @attrValue] = @attr.split("!=")
                @test = (value)=>
                    return @attrValue != value
            else if equal.test @attr
                [@attrName, @attrValue] = @attr.split("==")
                @test = (value)=>
                    return @attrValue == value
            else
                @attrName = @attr
                @test = (value)->
                    return value? and value

        toggle: (value)->
            if @test value
                @node.style.display = ""
            else
                @node.style.display = "none"

        applyContext: (context)->
            context.watch @attrName, (value)=> @toggle value
            @toggle context.get @attrName
            this


    class DataAttr extends Binding
        # Sets an attribute on the current node, eg:
        # <img src="foo.png" data-attr="alt=img.desc" />
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
            if not @type or @type == ""?
                if value?
                    @node.innerHTML = value
            else if @type == 'text'
                @node.value = value
            else if @type == 'checkbox'
                $(@node).attr 'checked', value
            this

        getValue: ()->
            if not @type or @type == ""?
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
        # <a data-click="markDone:todo.id" href="#">Click Me</a>
        @bind 'data-click'

        constructor: (node)->
            super node
            [@funcName, @funcArgs] = @attr.split(':')
            @funcArgs or= ''

        applyContext: (context)->
            $(@node).click =>
                args = (context.get(arg) for arg in @funcArgs.split ',' when arg.trim())
                context.get(@funcName, false).apply(this, args)
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
            $(@node).click ()=>
                context.set @watchName, @watchValue
            @activate context.get @watchName

    class DataStyle extends Binding
        # Adds inline styling to a node, eg:
        # <a data-style="background:#{todo.color};font-size:#{todo.priority}em;"

        @bind 'data-style'
        regexp: /#\{(.*?)\}/g
        constructor: (node)->
            super node
            @styles = {}

            styles = @attr.split(";")

            for style in styles
                continue if not style.trim()
                [name, raw] = style.split(":")
                objects = raw.match @regexp
                @styles[name] = raw: raw, objects: objects

        setValue: (name, value)->
            $(@node).css(name.trim(), value.trim())

        doStyle: (context, name, raw, objects)->
            for object in objects
                raw = raw.replace object, context.get(object.replace(@regexp, '$1'))
            @setValue name, raw

        applyContext: (context)->
            for own name, {raw, objects} of @styles
                for object in objects
                    object = object.replace(@regexp, '$1')
                    context.watch object, (value)=>
                        @doStyle context, name, raw, objects
                @doStyle context, name, raw, objects

    class DataTemplate extends Binding
        # Creates a reusable template and stores it in the context
        # under it's attribute value, eg:
        #
        # <div data-template="template1"></div>
        #
        # To render the template, you can query the context and call
        # `render` which returns a new DOM node with the given context
        # applied to it:
        #
        # $(body).append(context.get('template1').render(tplcontext))

        @bind 'data-template'
        stop: true
        constructor: (node)->
            @attr = @templateName = node.getAttribute @name
            @node = node.parentElement
            @template = node.cloneNode true
            $(@template).removeAttr 'data-template'
            $(node).remove()

        applyContext: (context)->
            context.set @templateName, this

        render: (context)->
            clone = @template.cloneNode true
            tpl = new Template(clone).compile()
            {bindings} = Binding.init clone
            tpl.push b for b in bindings
            tpl.applyContext context
            return clone


    class DataLoop extends Binding

        @bind 'data-loop'
        # Stop recursive descent on this node
        stop: true

        constructor: (node)->
            @attr = node.getAttribute @name
            @node = @parentElement = node.parentElement
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

            $(@parentElement).empty()
            @templates = []

            for element in iterable
                ctx = context.new()
                ctx[@elementName] = element
                @contexts.push ctx

                clone = @template.cloneNode true
                @nodes.push clone
                tpl = new Template(clone).compile()
                @templates.push tpl
                # Creating a template instance does not take
                # into account bindings on the root element
                # so we have to do that manually
                {bindings} = Binding.init clone
                tpl.push binding for binding in bindings

                tpl.applyContext ctx

            @parentElement.appendChild node for node in @nodes
            this

        applyContext: (context)->
            console.log @iterableName
            context.watch @iterableName, (iterable)=>
                @renderIterable context, iterable
            @renderIterable context, context.get @iterableName
            this




    return {
        DataShow: DataShow
        DataBind: DataBind
        DataClick: DataClick
        DataLoop: DataLoop
        DataSet: DataSet
        DataActivate: DataActivate
        DataStyle: DataStyle
        DataAttr: DataAttr
        DataOr: DataOr
        DataTemplate: DataTemplate
    }