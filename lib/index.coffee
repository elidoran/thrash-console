pad = require 'pad'
format = require 'comma-number'
spaces = '                                                                             '
dashes = '-----------------------------------------------------------------------------'

# control color enabled based on CLI options... or `options`
chalk = new (require('chalk')).constructor

module.exports = (options, runner) ->

  # setup some reused strings padded to the correct width
  strings =
    empty       : spaces[0...options.width]
    valid       : pad options.width, 'valid'
    invalid     : pad options.width, 'invalid'
    optimizable : pad options.width, 'optimizable'
    slowmo      : pad options.width, 'slowmo'
    changeFactor: pad(options.width, '(change factor)')
    baseline    : pad(options.width, '(baseline)')


  # control coloring
  if options.color is false then chalk.enabled = false

  else # when enabled, enhance the strings with color
    strings.valid = chalk.green strings.valid
    strings.invalid = chalk.red strings.invalid
    strings.optimizable = chalk.green strings.optimizable
    strings.slowmo = chalk.red strings.slowmo
    strings.changeFactor = chalk.dim strings.changeFactor
    strings.baseline = chalk.dim strings.baseline
    # strings. = chalk.green strings.
    # strings. = chalk.red strings.

  # it's possible to provide the headers via the options
  # otherwise, use 'inputs' and the labels of the thrashers
  headers = options.headers ? [label:'inputs']
  # when we only have 'inputs' as made right above here...
  if headers.length < 2
    # if there is an array of thrashers (using @thrash/compare)
    if runner.thrashers?.length > 0
      # then get their labels to be the headers
      headers.push label:thrasher.label for thrasher in runner.thrashers

    # otherwise, there's only one, use its label
    else headers.push label:runner.label

  # premake our line separator (dashes) based on the specified `width` and
  # 2 extra chars for the space before the separator and then the separator
  # itself. (hmm, for multi-character separator i'd need to use its length)
  # then, multiply times the number of headers we have.
  lineSeparator = dashes.substr 0, (options.width + 2) * headers.length

  #
  # now, let's add our listeners
  #

  # this event writes out the table's headers
  runner.on 'started', (thrasher) ->
    console.log 'started',thrasher.label
    console.log()

    # print out the headers
    line = ''
    for header in headers
      # plus 1 because right-aligned values will have an extra space before the separator
      diff = (options.width + 1) - header.label.length
      if diff < 0
        line += header.label[0...options.width] + options.separator
      else
        left = spaces.substr 0, Math.floor diff / 2
        right = spaces.substr 0, Math.ceil diff / 2
        line += left + header.label + right + options.separator

    console.log line[0...-1]
    console.log lineSeparator # later stuff will output a separator line...

  block = []

  # this event will start the input block storing the input
  runner.on 'input:start', (thrasher, input) ->

    # either they provided a label, or, use first input param
    if input[3]? then label = input[3]

    # NOTE: the input's second element, index 1, is the input params array
    #       so, this is trying to get the first input param
    else if input?[1]?[0]?
      # wrap input strings with single quotes so they look like a string
      label = input[1][0]
      if typeof label is 'string' then label = '\'' + label + '\''

    # okay, no good, no input params, and no label ...
    else label = '?????'

    # put new input in first cell of first row of block
    block.push [ pad(options.width, label) ]


  # this event outputs the block of data for the input, a line separator,
  # and then resets the block to an empty array.
  runner.on 'input:end', (thrasher, input) ->
    console.log line.join(' ' + options.separator) for line in block
    console.log lineSeparator
    block = []


  # this event adds the validation result to the block
  runner.on 'validated', (thrasher, result, input) ->
    # validation info goes in the first row after the input, always.
    block[0].push if result then strings.valid else strings.invalid


  # this event adds the optimization results to the block.
  # if validation was disabled then this takes its place,
  # otherwise, it goes on the next line.
  runner.on 'optimized', (thrasher, result) ->

    # normally we go into block[1], but, if `validated` is disabled then we
    # instead go into block[0]
    if runner.options.validate is false then line = block[0]

    # if we've already created a block[1] then use it
    else if block[1]? then line = block[1]

    # have to make block[1]
    else block.push line = [strings.empty]

    # add our result to the block's line
    line.push if result.optimized then strings.optimizable else strings.slowmo


  # this event adds the performance results lines to the block.
  # if validation or optimization were disabled then this moves up, possibly
  # all the way to the top line.
  runner.on 'thrashed', (thrasher, result) ->

    # normally we go into block[2]
    index = 2

    # if either of these are disabled then we move up a line (decrement index)
    if runner.options.validate is false then index--
    if runner.options.optimize is false then index--

    # if that block already exists then we use it to add our data to
    if block[index]?
      # we're going to put the 'seconds' (part) it took to run it.
      secondsLine = block[index]

      # we're going to put the 'nanoseconds' (part) it took to run it
      # if both 'validate' and 'optimize' are false then we don't have the
      # next block already created...
      # so, try to get it
      nanosLine = block[index + 1]

      # if it's not there, then create it
      unless nanosLine? then block.push nanosLine = [strings.empty]

    # even the first block we need doesn't exist, so, create them both
    else
      # put an empty "cell" first
      block.push secondsLine = [strings.empty]
      block.push nanosLine   = [strings.empty]

    # if we've already created a line for the comparison info then use it
    if block[index + 2]? then compareLine = block[index + 2]

    # else, create it *only* if there are multiple thrashers
    else if runner?.thrashers?.length > 1
      block.push compareLine = [ strings.changeFactor, strings.baseline ]

    # add the data to each line.
    # these get their own lines because they can be long.
    # also, format the numbers with comma's
    secondsLine.push pad(options.width, format(result.overall.seconds) + ' s ')
    nanosLine.push   pad(options.width, format(result.overall.nanos) + ' ns')

    # TODO:
    #  this is for @thrash/compare to do the work...
    #  must somehow have that accept this event and track the comparison info.
    #  then, it can emit the comparison data via a new event.
    #  this module can then listen for that event as well and put it last in the
    #  block.
    # if we have a line for the comparison info...
    if compareLine?

      # if we've already stored one to be the 'baseline'
      if compareLine.firstOverall?

        # make a comparison
        # always compare to the first one?? or compare to previous one??
        # need both overall values as a number to do a difference...
        # or, at least, get the number parts... strip off 'ns' and split on seconds
        ns1 = (compareLine.firstOverall.seconds * 1e9) + compareLine.firstOverall.nanos
        ns2 = (result.overall.seconds * 1e9) + result.overall.nanos
        factor = ns1 / ns2
        better = factor > 1
        factor = pad(options.width, factor.toFixed(2) + 'x')
        factor = if better then chalk.green factor else chalk.red factor
        compareLine.push factor

      # else, this is the first one, so, store its `overall` as the baseline
      else compareLine.firstOverall = result.overall

  # so far, this just confirms we've finished working with the thrasher provided.
  runner.on 'finished', (thrasher) ->
    console.log 'finished',thrasher.label
