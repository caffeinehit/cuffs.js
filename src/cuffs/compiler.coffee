define ->
    STOP_DESCENT = 'stop-descent-+"*' # Random string, easier == / != comparison

    walk = (tree, callback)->
        # Walk a DOM tree depth first and call a callback on
        # each node. Escape current descent if the callback returns
        # STOP_DESCENT and continue with next sibling.

        recurse = (current, depth = 1)->
            stopDescent = callback current, depth

            if stopDescent != STOP_DESCENT and current.firstElementChild?
                recurse current.firstElementChild, depth + 1

            return if not current.nextElementSibling?
            return recurse current.nextElementSibling, depth
        return recurse tree.firstElementChild if tree.firstElementChild?

    STOP_DESCENT: STOP_DESCENT
    walk: walk
