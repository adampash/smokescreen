$ ->
  window.playbackCamSequence = new Sequence
      type: 'sequence'
      aspect: 16/9
      duration: 3
      src: 'CanvasPlayer'
      # onStart: ->
      #   @recordCam(3)

  # playbackCamSequence.drawAnimation = (context, elapsed) ->
  #   @context.clearRect(0, 0,
  #                     @canvas.width,
  #                     @canvas.height)





  playbackCamSequence.ended = ->
    @callback() if @callback?
    @cleanup()
    @video.cleanup()
