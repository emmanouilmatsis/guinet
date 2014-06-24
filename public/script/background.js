var Background = (function() {

  // Background
  function Background() {
    this.step = 0;
    this.gradientSpeed = 0.002;
    this.indices = [0,1,2,3];
    this.colors = new Array(
        [62,35,255],
        [60,255,60],
        [255,35,98],
        [45,175,230],
        [255,0,255],
        [255,128,0]);

    setInterval(this.update.bind(this),10);
  }

  Background.prototype.update = function()
  {
    var c0_0 = this.colors[this.indices[0]];
    var c0_1 = this.colors[this.indices[1]];
    var c1_0 = this.colors[this.indices[2]];
    var c1_1 = this.colors[this.indices[3]];

    var istep = 1 - this.step;

    var r1 = Math.round(istep * c0_0[0] + this.step * c0_1[0]);
    var g1 = Math.round(istep * c0_0[1] + this.step * c0_1[1]);
    var b1 = Math.round(istep * c0_0[2] + this.step * c0_1[2]);
    var color1 = "#"+((r1 << 16) | (g1 << 8) | b1).toString(16);

    var r2 = Math.round(istep * c1_0[0] + this.step * c1_1[0]);
    var g2 = Math.round(istep * c1_0[1] + this.step * c1_1[1]);
    var b2 = Math.round(istep * c1_0[2] + this.step * c1_1[2]);
    var color2 = "#"+((r2 << 16) | (g2 << 8) | b2).toString(16);

    $('body')
      .css({
        background: "-webkit-gradient(linear, left top, right top, from("+color1+"), to("+color2+"))"})
      .css({
        background: "-moz-linear-gradient(left, "+color1+" 0%, "+color2+" 100%)"});

    this.step += this.gradientSpeed;
    if (this.step >= 1)
    {
      this.step %= 1;
      this.indices[0] = this.indices[1];
      this.indices[2] = this.indices[3];

      this.indices[1] = (this.indices[1] + Math.floor( 1 + Math.random() * (this.colors.length - 1))) % this.colors.length;
      this.indices[3] = (this.indices[3] + Math.floor( 1 + Math.random() * (this.colors.length - 1))) % this.colors.length;

    }
  }


  // Home Module Initialization
  var init = function()
  {
    var background = new Background();
  };

  return {
    init: init
  };

})().init();
