$ ->
  window.playbackCamSequence = new Sequence
      type: 'sequence'
      aspect: 16/9
      duration: 3
      src: 'CanvasPlayer'
      # onStart: ->
      #   @recordCam(3)

  camSequence.drawAnimation = (context, elapsed) ->
    @context.clearRect(0, 0,
                      @canvas.width,
                      @canvas.height)





  camSequence.ended = ->
    @callback() if @callback?
    @cleanup()
    @video.cleanup()
