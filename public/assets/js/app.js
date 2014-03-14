(function() {
  $(function() {
    return window.devlog = function(args) {
      if (true) {
        return console.log(arguments);
      }
    };
  });

}).call(this);

(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  $(function() {
    return window.Player = (function() {
      function Player(tracks) {
        this.tracks = tracks;
        this.removeVideoListeners = __bind(this.removeVideoListeners, this);
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
        devlog('play');
        if (this.currentTrack < this.tracks.length) {
          return this.queue(this.tracks[this.currentTrack]);
        }
      };

      Player.prototype.nextTrack = function() {
        this.removeVideoListeners();
        this.currentTrack++;
        return this.play();
      };

      Player.prototype.queue = function(track) {
        devlog('queue', track);
        if (track.type === 'video') {
          return this.playVideo(track);
        } else if (track.type === 'sequence') {
          return this.playSequence(track);
        }
      };

      Player.prototype.playVideo = function(track) {
        devlog('playVideo');
        this.video = document.createElement('video');
        this.video.src = track.src;
        this.setupVideoListeners(this.video);
        this.videoPlaying = true;
        this.video.play();
        return this.drawVideo(track);
      };

      Player.prototype.playSequence = function(track) {
        devlog('playSequence');
        this.sequenceStart = new Date();
        if (track.src != null) {
          this.playVideo(track);
        }
        return this.drawSequence(track);
      };

      Player.prototype.drawSequence = function(track) {
        var elapsed;
        track.callback.call(this, this.aniContext);
        elapsed = (new Date() - this.sequenceStart) / 1000;
        if (elapsed < track.duration) {
          return requestAnimationFrame((function(_this) {
            return function() {
              return _this.drawSequence(track);
            };
          })(this));
        } else {
          devlog('end sequence');
          this.aniContext.clearRect(0, 0, this.aniCanvas.width, this.aniCanvas.height);
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

      Player.prototype.setupVideoListeners = function(video) {
        return video.addEventListener('ended', (function(_this) {
          return function() {
            devlog('ended');
            _this.videoPlaying = false;
            return _this.nextTrack();
          };
        })(this));
      };

      Player.prototype.removeVideoListeners = function(video) {
        return this.video.removeEventListener('ended');
      };

      return Player;

    })();
  });

}).call(this);

(function() {
  $(function() {
    window.player = new Player([
      {
        type: 'video',
        src: '/assets/videos/short.mov',
        aspect: 16 / 9
      }, {
        type: 'sequence',
        src: '/assets/videos/short.mov',
        callback: Sequences.green.play,
        duration: Sequences.green.duration
      }, {
        type: 'video',
        src: '/assets/videos/ocean.mp4'
      }
    ]);
    return $(window).resize(function() {
      return player.setDimensions();
    });
  });

}).call(this);

(function() {
  console.log('cart');

}).call(this);

(function() {
  window.Sequences = {
    green: {
      duration: 4,
      play: function(context) {
        context.clearRect(0, 0, this.aniCanvas.width, this.aniCanvas.height);
        context.fillStyle = 'rgba(0, 100, 0, 0.4)';
        context.fillOpacity = 0.1;
        return context.fillRect(0, 0, 400, 400);
      }
    }
  };

}).call(this);
