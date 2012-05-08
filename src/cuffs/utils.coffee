# Utility functions

define ->
    return class Utils
        @extend: (target, source)->
            target[key] = value for own key, value of source

        @serialize: (object)->
            if object and object.serialize?
                return object.serialize()

            if Utils.typeOf(object) == "array"
                return Utils.map object, (item)-> Utils.serialize item

            object

        @map: (iter, fn)->
            fn elem for elem in iter

        @typeOf: (()->
            classToType = {}
            types = "Boolean Number String Function Array Date RegExp Undefined Null".split " "

            for name in types
                classToType["[object #{name}]"] = name.toLowerCase()

            (object)->
                classToType[Object::toString.call(object)] or "object")()