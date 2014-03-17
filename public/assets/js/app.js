(function() {
  var constraints, errorCallback, successCallback,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  $(function() {
    window.dev = true;
    window.log = function(args) {
      if (dev) {
        return console.log.apply(console, arguments);
      }
    };
    if (dev) {
      return $('body').append($('<script src="//localhost:35729/livereload.js"></script>'));
    }
  });

  $(function() {
    return window.Player = (function() {
      function Player(tracks) {
        this.tracks = tracks;
        this.setupVideoListeners = __bind(this.setupVideoListeners, this);
        this.drawVideo = __bind(this.drawVideo, this);
        this.drawSequence = __bind(this.drawSequence, this);
        this.currentTrack = 0;
        this.videoPlaying = false;
        this.videoCanvas = this.createCanvas();
        this.videoContext = this.createContext(this.videoCanvas);
        this.aniCanvas = this.createCanvas();
        this.aniContext = this.createContext(this.aniCanvas);
        this.setDimensions();
        $('body').html(this.videoCanvas);
        $('body').append(this.aniCanvas);
      }

      Player.prototype.createCanvas = function() {
        var canvas;
        canvas = document.createElement('canvas');
        return canvas;
      };

      Player.prototype.createContext = function(canvas) {
        var context;
        return context = canvas.getContext('2d');
      };

      Player.prototype.setDimensions = function(canvas) {
        this.displayWidth = $(document).width();
        this.displayHeight = $(document).height();
        this.videoCanvas.width = this.displayWidth;
        this.videoCanvas.height = this.displayHeight;
        this.aniCanvas.width = this.displayWidth;
        return this.aniCanvas.height = this.displayHeight;
      };

      Player.prototype.play = function() {
        log('play');
        if (this.currentTrack < this.tracks.length) {
          return this.queue(this.tracks[this.currentTrack]);
        }
      };

      Player.prototype.nextTrack = function() {
        this.currentTrack++;
        return this.play();
      };

      Player.prototype.queue = function(track) {
        log('queue', track);
        if (track.type === 'video') {
          return this.playVideo(track);
        } else if (track.type === 'sequence') {
          return this.playSequence(track);
        }
      };

      Player.prototype.playVideo = function(track) {
        log('playVideo');
        this.video = document.createElement('video');
        this.video.src = track.src;
        this.setupVideoListeners(this.video, track);
        this.videoPlaying = true;
        this.video.play();
        return this.drawVideo(track);
      };

      Player.prototype.playSequence = function(track) {
        log('playSequence');
        this.sequenceStart = new Date();
        if (track.src != null) {
          if (track.src === 'webcam') {
            log('get webcam');
            track.src = webcam.src;
            return this.playVideo(track);
          } else {
            return this.playVideo(track);
          }
        } else {
          return this.drawSequence(track);
        }
      };

      Player.prototype.drawSequence = function(track) {
        var elapsed;
        elapsed = (new Date() - this.sequenceStart) / 1000;
        track.play.call(this, this.aniContext, elapsed);
        if (elapsed < track.duration) {
          return requestAnimationFrame((function(_this) {
            return function() {
              return _this.drawSequence(track);
            };
          })(this));
        } else {
          log('end sequence');
          track.ended.call(this, this.aniContext, this.aniCanvas);
          return this.nextTrack();
        }
      };

      Player.prototype.drawVideo = function(track) {
        var height, spacer;
        height = this.displayWidth / track.aspect;
        spacer = (this.displayHeight - height) / 2;
        this.videoContext.drawImage(this.video, 0, spacer, this.displayWidth, height);
        if (this.videoPlaying) {
          return requestAnimationFrame((function(_this) {
            return function() {
              return _this.drawVideo(track);
            };
          })(this));
        }
      };

      Player.prototype.setupVideoListeners = function(video, track) {
        video.addEventListener('ended', (function(_this) {
          return function(event) {
            if (_this.video === event.srcElement) {
              return _this.videoEnded();
            }
          };
        })(this));
        if (track.type === 'sequence') {
          return video.addEventListener('playing', (function(_this) {
            return function() {
              return _this.drawSequence(track);
            };
          })(this));
        }
      };

      Player.prototype.videoEnded = function() {
        log('ended');
        this.videoPlaying = false;
        return this.nextTrack();
      };

      return Player;

    })();
  });

  window.CamSequence = {
    type: 'sequence',
    src: 'webcam',
    aspect: 16 / 9,
    duration: 5,
    videoEffect: function() {
      var b, data, g, i, idata, r, _results;
      backContext.drawImage(webcam, 0, 0);
      idata = backContext.getImageData(0, 0, canvas.width, canvas.height);
      data = idata.data;
      i = 0;
      _results = [];
      while (i < data.length) {
        r = data[i];
        g = data[i + 1];
        b = data[i + 2];
        _results.push(i += 4);
      }
      return _results;
    },
    play: function(context, elapsed) {
      var x, y;
      x = elapsed * 100;
      y = elapsed * 100;
      context.clearRect(0, 0, this.aniCanvas.width, this.aniCanvas.height);
      context.fillStyle = 'rgba(0, 100, 0, 0.4)';
      context.fillOpacity = 0.1;
      return context.fillRect(x, y, 400, 400);
    },
    ended: function(context, canvas) {
      return context.clearRect(0, 0, canvas.width, canvas.height);
    }
  };

  navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia;

  constraints = {
    audio: false,
    video: {
      mandatory: {
        minWidth: 1280,
        minHeight: 720
      }
    }
  };

  successCallback = function(stream) {
    window.webcam = stream;
    if (window.URL) {
      return webcam.src = window.URL.createObjectURL(stream);
    } else {
      return webcam.src = stream;
    }
  };

  errorCallback = function(error) {
    return log("navigator.getUserMedia error: ", error);
  };

  navigator.getUserMedia(constraints, successCallback, errorCallback);

  $(function() {
    window.player = new Player([
      {
        type: 'video',
        src: '/assets/videos/short.mov',
        aspect: 16 / 9
      }, TestSequence, CamSequence, {
        type: 'video',
        src: '/assets/videos/ocean.mp4',
        aspect: 16 / 9
      }
    ]);
    $(window).resize(function() {
      return player.setDimensions();
    });
    return player.play();
  });

  window.TestSequence = {
    type: 'sequence',
    src: '/assets/videos/short.mov',
    aspect: 16 / 9,
    duration: 2,
    play: function(context, elapsed) {
      var x, y;
      x = elapsed * 100;
      y = elapsed * 100;
      context.clearRect(0, 0, this.aniCanvas.width, this.aniCanvas.height);
      context.fillStyle = 'rgba(0, 100, 0, 0.4)';
      context.fillOpacity = 0.1;
      return context.fillRect(x, y, 400, 400);
    },
    ended: function(context, canvas) {
      return context.clearRect(0, 0, canvas.width, canvas.height);
    }
  };

}).call(this);

//# sourceMappingURL=app.js.map
