define ['./ns', './utils'], (Cuffs, utils) ->

    class Context
        constructor: (obj)->
            @__parent__ = null
            @__children__ = []
            @__observers__ = {}
            for key, value of obj
                this[key] = value

        new: (obj)->
            # Create a new child context
            Context = ()->
            Context.prototype = this

            child = new Context

            this.__children__.push child

            child.__parent__ = this
            child.__children__ = []
            child.__observers__ = {}

            for key, value of obj
                child[key] = value

            child

        destroy: ()->
            # Destroy this context, all its links and children.
            if this.__parent__?
                this.__parent__.__children__.splice(
                    this.__parent__.__children__.indexOf(this),
                    1
                )
            this.__observers__ = {}
            this.__children__[0].destroy() while this.__children__.length > 0
            this.__parent__ = null
            this

        watch: (attr, observer)->
            # Watch a property on this context
            if this.__observers__[attr]?
                this.__observers__[attr].push observer
            else
                this.__observers__[attr] = [observer]
            this

        apply: (attr)->
            # Call all observers and propagate down to children. If
            # `attr` is specified only call observers of `attr` and
            # its child observers, eg: @apply('foo') where 'foo' is
            # {'bar': {'baz': 1}} would call all observers that
            # observe all child values of 'foo'
            if not attr?
                for own attr, observers of this.__observers__
                    value = @get attr
                    observer value for observer in observers
                for child in this.__children__
                    child.apply()
            else
                value = @get attr

                for name, observers of this.__observers__
                    if name == attr
                        observer value for observer in observers
                    else if name.indexOf(attr) == 0
                        @apply name 

                child.apply attr for child in this.__children__

                # if attr.indexOf('.') > 0

                # value = @get attr
                # for own name, observers of this.__observers__
                #     if name.indexOf(attr) == 0
                #         observer value for observer in observers 

                # # for own key, observers of this.__observers__
                # #     if key.indexOf(attr) == 0
                # #         observer value 

                # child.apply attr for child in this.__children__

                #observer value for observer in this.__observers__[attr] or []
                #child.apply attr for child in this.__children__
            this

        parent: ()->
            this.__parent__

        root: ()->
            if this.__parent__?
                return this.__parent__.root()
            return this

        get: (name, call = true)->
            # Pull the object referenced by `name` from the context. Allow
            # for dotted notation.
            # Examples:
            #
            # `name` = 'todo' => @['todo']
            # `name` = 'todo.task' => @['todo']['task']
            # `name` = 'todo.task.priority' => @['todo']['task']
            #
            # If the value is a function, it is called and its return value
            # returned if `call` is `true`, else the function is returned.

            parts = (part.trim() for part in name.split '.')

            returnFunc = (value)->
                if utils.typeOf(value) == "function" and call == true
                    return value()
                return value

            if parts.length == 1
                return returnFunc @[name]
            else
                current = this
                for part in parts
                    if not current?
                        return null
                    current = current[part]
                return returnFunc current

        hasProp: (name)->
            {}.hasOwnProperty.call this, name

        set: (name, value, doApply = true)->
            # Set the object referenced by `name` on the context. Allow
            # for dotted notation.
            #
            # Examples:
            # `name` = 'todo' => @['todo'] = value
            # `name` = 'todo.task' => @['todo']['task'] = value
            # `name` = 'todo.task.priority' => @['todo']['task']['priority'] = value
            #
            # If the nested object does not exist yet, it's created on the fly.
            #
            # If `value` is not a function, all observers will be notified.

            parts = (part.trim() for part in name.split '.')

            if parts.length == 1
                @[name] = value
            else
                current = this
                for part in parts[0..parts.length-2]
                    current = current[part] or current[part] = {}
                current[parts[parts.length-1]] = value

            # Don't notify observers. Apply calls `get()` which would run
            # the function without possibly expected arguments.
            if utils.typeOf(value) == "function"
                return

            # Don't notify observers if we've received a `doApply==false`
            if not doApply
                return

            # If the object we just set on the context is nativ to the
            # current context, call all observers.
            if @hasProp parts[0]
                return @apply name

            # If not, travel up the chain of contexts until we find
            # where the object is native and call apply there
            ctx = this
            while ctx = ctx.parent()
                continue if not ctx.hasProp parts[0]
                return ctx.apply name

    return Cuffs.Context = Context