define (require)->
    Cuffs = require './ns'
    {Binding, Template, optionize, substitute} = require './template'
    utils = require './utils'


    class DataShow extends Binding
        # Make element visible depending if the context's attribute
        # is not falsy, eg:
        # <div data-show="todo.done"></div>
        # <div data-show="todo.done==0"></div>
        # <div data-show="todo.done!=0"></div>
        #
        # Handles simple type coercion such as `true` and `false`:
        #
        # <div data-show="todo.done==true"></div>

        @bind 'data-show'

        constructor: (@node)->
            super node
            notEqual = /.*!=.*/
            equal = /.*==.*/
            lesser  = /.*<.*/
            greater = /.*>.*/

            booleanWrapper = (attrValue)=>
                if attrValue == "false"
                    return false
                if attrValue == "true"
                    return true
                
                return attrValue

            if notEqual.test @attr
                [@attrName, @attrValue] = @attr.split("!=")
                @test = (value)=>
                    # We don't want strict comparison - coercion is
                    # fine - hence the backticks.
                    return `booleanWrapper(this.attrValue) != value`
            else if equal.test @attr
                [@attrName, @attrValue] = @attr.split("==")
                @test = (value)=>
                    # We don't want strict comparison - coercion is
                    # fine - hence the backticks.
                    return `booleanWrapper(this.attrValue) == value`
            else if lesser.test @attr
                [@attrName, @attrValue] = @attr.split("<")
                @test = (value)=>
                    return `value < booleanWrapper(this.attrValue)`
            else if greater.test @attr
                [@attrName, @attrValue] = @attr.split(">")
                @test = (value)=>
                    return `value > booleanWrapper(this.attrValue)`
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
            context.watch @attrName, (value)=>
                @toggle value
            value = context.get @attrName
            @toggle value
            this


    class DataAttr extends Binding
        # Sets an attribute on the current node, eg:
        # <img src="foo.png" data-attr="alt=img.desc" />
        @bind 'data-attr'
        constructor: (node)->
            super node
            @values = optionize @attr
        setAttr: (name, value)=>
            $(@node).attr name, value
        applyContext: (context)->
            for own key, val of @values
                context.watch val, =>
                    @setAttr key, substitute val, context
            for own key, val of @values
                @setAttr key, substitute val, context 


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

    class DataSubmit extends Binding
        # Calls a function on the context when a form is submitted,
        # eg:
        #
        # <form data-submit="onSubmit"></form>
        @bind 'data-submit'

        applyContext: (context)->
            [fnName, args] = @attr.split(':')
            argNames = args?.split(',') or []

            $(@node).bind 'submit', (e)=>
                fn = context.get fnName, false
                fn.apply @node, [e].concat (context.get(argName) for argName in argNames)


    class DataBind extends Binding
        # Create two way binding of data between elements and the
        # model. It's reasonably smart, so it handles normal content
        # and different input types, eg:
        #
        # <input type="text" data-bind="todo.name" value="" />
        # <input type="checkbox" data-bind="todo.done" />
        # <span data-bind="todo.name"></span>

        @bind 'data-bind'

        textTypes: ['text','hidden', 'email']
        constructor: (@node)->
            @type = @node.type
            super @node

        setValue: (value)->
            if @node.tagName == "TEXTAREA"
                $(@node).val(value)
            else if not @type or @type == ""?
                if value?
                    @node.innerHTML = value
            else if @type in @textTypes
                @node.value = value
            else if @type == 'password'
                @node.value = value or ''
            else if @type == 'checkbox'
                $(@node).attr 'checked', value
            this

        getValue: ()->
            if @node.tagName == "TEXTAREA"
                $(@node).val()
            else if not @type or @type == ""?
                $(@node).html()
            else if @type in @textTypes
                @node.value
            else if @type == 'password'
                @node.value
            else if @type == 'checkbox'
                $(@node).is ':checked'
            else
                throw new Error "Unknown type to bind to: #{@type}"

        applyContext: (context)->
            context.watch @attr, (value)=>
                @setValue value if value?

            $(@node).change ()=>                
                try
                    context.get(@attr, false)(@getValue())
                catch err
                    context.set @attr, @getValue()
            val = context.get @attr
            @setValue val if val?
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
            $(@node).bind 'click', (e)=>
                args = [e].concat (context.get(arg) for arg in @funcArgs.split ',' when arg.trim())
                fn = context.get @funcName, false
                if not fn?
                    throw new Error "Couldn't find click handler '#{@funcName}' in context"
                fn.apply @node, args

            this

    class DataHover extends Binding
        # Call a method on the context when we hover over an
        # element, eg:
        # <a data-hover="highlight:todo" href="#">Click Me</a>
        # If the mouse enters, the first argument will be `true`,
        # if the mouse leaves, the first argument will be `false`.
        @bind 'data-hover'
        constructor: (node)->
            super node
            [@funcName, @funcArgs] = @attr.split(':')
            @funcArgs or= ''

        applyContext: (context)->
            getArgs = =>
                (context.get(arg) for arg in @funcArgs.split ',' when arg.trim())
            fn = context.get @funcName, false
            $(@node).bind 'mouseenter', (e)=>
                fn.apply this, [e, true].concat getArgs()
            $(@node).bind 'mouseleave', (e)=>
                fn.apply this, [e, false].concat getArgs()

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
        # <ul><li data-activate="active==one,active==two"/></ul>

        @bind 'data-activate'
        constructor: (node)->
            super node
            @values = (att.split('==') for att in @attr.split(','))

        activate: (value)->
            if value in (v[1] for v in @values)
                $(@node).addClass 'active'
            else
                $(@node).removeClass 'active'

        applyContext: (context)->
            for v in @values
                context.watch v[0], (value)=> @activate value

            $(@node).bind 'click', =>
                context.set @values[0][0], @values[0][1]

            @activate context.get @values[0][0]

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
                if not objects?
                    @setValue name, raw
                    continue
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
            context.root().set @templateName, this

        render: (context)->
            clone = @template.cloneNode true
            tpl = new Template(clone)
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
            console.log "renderIterable"
            iterable = iterable or []

            $(@nodes).remove()
            @nodes = []
            @templates = []
            @contexts.shift().destroy() while @contexts.length > 0

            for element in iterable
                ctx = context.new()
                ctx[@elementName] = element
                @contexts.push ctx

                clone = @template.cloneNode true
                @nodes.push clone
                tpl = new Template(clone)
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
            context.watch @iterableName, (iterable)=>
                @renderIterable context, iterable
            @renderIterable context, context.get @iterableName
            this


    return Cuffs.Template.DefaultBindings = {
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