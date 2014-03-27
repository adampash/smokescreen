$ ->
  duration = 1
  window.camSequence = new Sequence
      type: 'sequence'
      src: 'webcam'
      aspect: 16/9
      duration: duration
      onStart: ->
        @recordCam(duration)

  camSequence.drawAnimation = (context, elapsed) ->
    x = elapsed * 100
    y = elapsed * 100
    @context.clearRect(0, 0,
                      @canvas.width,
                      @canvas.height)


    @context.fillStyle = 'rgba(0, 100, 0, 0.4)'
    @context.fillOpacity = 0.1
    @context.fillRect(x, y, 400, 400)

  camSequence.ended = ->
    @callback() if @callback?
    @cleanup()
    @video.cleanup()

  camSequence.recordCam = (seconds) ->
    window.recorder = @record(@video.canvas, seconds)
    window.littleRecorder = @record(@video.littleCanvas, seconds, true)

  camSequence.record = (canvas, seconds, convert) ->
    recorder = new Recorder canvas

    if convert
      complete = =>
        log 'recording complete'
        window.converter = new Converter recorder.canvas,
                            recorder.capturedFrames,
                            recorder.fps,
                            null,
                            converted: ->
                              log 'converted'
        converter.convertAndUpload()
    else
      complete = null

    recorder.record seconds, 40,
      complete: complete

    recorder



# window.CamSequence =
#   type: 'sequence'
#   src: 'webcam'
#   aspect: 16/9
#   duration: 5
#   videoEffect: ->
#     backContext.drawImage(webcam,0,0)
# 
#     # Grab the pixel data from the backing canvas
#     idata = backContext.getImageData(0,0,canvas.width,canvas.height)
#     data = idata.data
# 
#     # Loop through the pixels
#     i = 0
#     while i < data.length
#        r = data[i]
#        g = data[i+1]
#        b = data[i+2]
#        i += 4
#   play: (context, elapsed) ->
#     x = elapsed * 100
#     y = elapsed * 100
#     context.clearRect(0, 0,
#                       @aniCanvas.width,
#                       @aniCanvas.height)
# 
# 
#     context.fillStyle = 'rgba(0, 100, 0, 0.4)'
#     context.fillOpacity = 0.1
#     context.fillRect(x, y, 400, 400)
# 
#   ended: (context, canvas) ->
#     context.clearRect(0, 0,
#              canvas.width,
#              canvas.height)
# 
