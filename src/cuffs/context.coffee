define ->

    class Context
        __parent__: null
        __children__: []
        __observers__: {}

        constructor: (obj)->
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
            # Call all observers and propagate down to children. If `attr`
            # is specified only call observers of `attr`.
            if not attr?
                for attr, observers of this.__observers__
                    value = @get attr
                    observer value for observer in observers
                for child in this.__children__
                    child.apply()
            else
                value = @get attr
                observer value for observer in this.__observers__[attr] or []
                child.apply attr for child in this.__children__
            this

        get: (name)->
            # Pull the object referenced by `name` from the context. Allow
            # for dotted notation.
            # Examples:
            #
            # `name` = 'todo' => @['todo']
            # `name` = 'todo.task' => @['todo']['task']
            # `name` = 'todo.task.priority' => @['todo']['task']

            parts = name.split '.'

            if parts.length == 1
                return @[name]
            else
                current = this
                for part in parts
                    if not current?
                        return null
                    current = current[part]
                return current

        set: (name, value)->
            # Set the object referenced by `name` on the context. Allow
            # for dotted notation.
            # Examples:
            # `name` = 'todo' => @['todo'] = value
            # `name` = 'todo.task' => @['todo']['task'] = value
            # `name` = 'todo.task.priority' => @['todo']['task']['priority'] = value
            parts = name.split '.'

            if parts.length == 1
                @[name] = value
            else
                current = this
                for part in parts[0..parts.length-2]
                    current = current[part]
                current[parts[parts.length-1]] = value
            @apply name

    return {
        Context: Context
    }