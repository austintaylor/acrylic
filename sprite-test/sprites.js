var Sprite = Class.create({
  initialize: function(img) {
    this.img = $(img);
    this.image = this.img.getAttribute('src');
    this.options = SpriteMetadata[this.image];
    this.img.src = 'dummy.png';
    this.img.setStyle({background: 'url(' + this.image + ') no-repeat', width: this.options.width + 'px', height: this.options.height + 'px'});
    this.start();
  },
  start: function() {
    if (this.timer) return;
    this.time = new Date().getTime();
    this.frame = 0;
    this.timer = setInterval(this.step.bind(this), Math.round(1000/this.options.fps));
  },
  step: function(){
    this.frame += 1;
    if (this.frame >= this.options.frames) this.frame = 0;
    this.img.setStyle({backgroundPositionX: (this.frame * -this.options.width) + 'px'});
  }
})

var SpriteMetadata = {
  'sprite_frames.png': {width: 30, height: 30, frames: 30, fps: 50} 
}

Event.observe(window, 'load', function() {
  $$('img.sprite').each(function(img) {
    new Sprite(img);
  })
})