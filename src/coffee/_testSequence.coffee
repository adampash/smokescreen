$ ->
  window.testSequence =
    new Sequence
      type: 'sequence'
      src: '/assets/videos/short.mov'
      aspect: 16/9
      duration: 5

  testSequence.drawAnimation = (context, elapsed) ->
    x = elapsed * 100
    y = elapsed * 100
    @context.clearRect(0, 0,
                      @canvas.width,
                      @canvas.height)


    @context.fillStyle = 'rgba(0, 100, 0, 0.4)'
    @context.fillOpacity = 0.1
    @context.fillRect(x, y, 400, 400)

  testSequence.ended = ->
    @callback() if @callback?
    @cleanup()
