class window.soundAnalyzer
  constructor: (@player) ->
    @all = 0
    @counter = 0
    @low = 1000
    @high = 4000
  playSound: (soundURL) ->
    @shouldAnalyze = true
    soundURL = soundURL or "/assets/audio/Sound.mp3"
    console.log('playing sound: ' + soundURL)
    $('body').append '<audio id="poem" autoplay="autoplay"><source src="' + soundURL + '" type="audio/mpeg" /><embed hidden="true" autostart="true" loop="false" src="' + soundURL + '" /></audio>'

    audioContext = new (window.AudioContext||window.webkitAudioContext)()

    @audioElement = document.getElementById("poem")

    @analyzer = audioContext.createAnalyser()
    @analyzer.fftSize = 64
    @frequencyData = new Uint8Array(@analyzer.frequencyBinCount)

    @audioElement.addEventListener("canplay", =>
      source = audioContext.createMediaElementSource(@audioElement)
      console.log 'can play'
      source.connect(@analyzer)
      @analyzer.connect(audioContext.destination)
    )

    @audioElement.addEventListener('ended', =>
      @shouldAnalyze = false
      log 'average level: ' + @all/@counter
      log('audio ended')
      @audioElement.removeEventListener('playing', @analyze, false)
      $('#poem').remove()
    , false)
    # audioElement.addEventListener('canplaythrough', voiceLoaded, false)
    @audioElement.addEventListener('playing', @analyze, false)

    $intensity = $("#intensity")

  analyze: =>
    @analyzer.getByteFrequencyData(@frequencyData)
    magnitude = 0
    for frequency in @frequencyData
      magnitude += frequency
    # i = 0
    # while i < @frequencyData.length
    #   magnitude += @frequencyData[i]
    #   i++

    @high = Math.max @high, magnitude
    @low = Math.min @low, magnitude
    # @all += magnitude
    # @counter++

    magnitude = (magnitude - 2000) / (@high-2000)
    window.audioIntensity = Math.max Math.min(magnitude, 1), 0

    # if @player? and @player.smoker.type?
    #   # log 'pulse it'
    #   @player.smoker.pulseMouths @player.ctx, @player.cPlayer.index, @player.smoker.type, audioIntensity

    setTimeout(@analyze, 10) if @shouldAnalyze
