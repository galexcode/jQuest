var game, world;

world = game = false;

$(window).ready(function() {
  game = new gf.Game('game', {
    width: window.innerWidth,
    height: window.innerHeight,
    background: 0x000000,
    interactive: true
  });
  game.loader.on('complete', function() {
    game.loadWorld('island2');
    world = game.world;
    Map.center();
    return game.render();
  });
  game.loader.on('progress', function(e) {
    return false;
  });
  return game.loader.load([
    {
      name: 'island2',
      src: 'resources/map/island2.json'
    }
  ]);
});

window.onresize = function() {
  game.resize(window.innerWidth, window.innerHeight);
  return Map.center();
};
