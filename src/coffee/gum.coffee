# GET USER MEDIA
navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia

constraints =
  audio: false
  video:
    mandatory:
      minWidth: 1280
      minHeight: 720

successCallback = (stream) ->
  window.webcam = stream # stream available to console
  if (window.URL)
    webcam.src = window.URL.createObjectURL(stream)
  else
    webcam.src = stream


  # window.webcam = new VideoTrack
  #   src: webcam.src
  #   aspect: @aspect
  #   littleCanvas: true
  #   shouldDraw: false
  # @video.play(@player, null,
  #   onplaystart: =>
  #     @onStart() if @onStart?
  # )
  # setTimeout ->
  #   $(window).trigger 'click'
  # , 1000

errorCallback = (error) ->
  log("navigator.getUserMedia error: ", error)

navigator.getUserMedia(constraints, successCallback, errorCallback)
