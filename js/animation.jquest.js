// Generated by CoffeeScript 1.6.3
var Animation;

Animation = {
  loadChar: function(name, eight) {
    var baseTexture, directions, height, k, pointX, pointY, sprite, textures, v, width, x, y, _i, _j;
    if (eight == null) {
      eight = true;
    }
    textures = [];
    directions = ['s', 'w', 'e', 'n', 'sw', 'se', 'nw', 'ne'];
    baseTexture = game.cache.getTexture(name).baseTexture;
    sprite = new gf.Sprite();
    width = 32;
    height = 32;
    for (y = _i = 0; _i < 8; y = ++_i) {
      textures[directions[y]] = [];
      for (x = _j = 0; _j < 6; x = ++_j) {
        pointX = x * 32;
        pointY = y * 32;
        textures[directions[y]].push(new gf.Texture(baseTexture, new gf.Rectangle(pointX, pointY, width, height)));
      }
    }
    for (k in textures) {
      v = textures[k];
      sprite.addAnimation(k, v, 0.08, true);
    }
    sprite.direction = false;
    return sprite;
  }
};