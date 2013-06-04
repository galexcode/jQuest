class window.Map
  @settings: {
    fileExtension: 'json'
    mapDirectory: ''
  }
  
  @mapElement: false
  
  @mapData: false
  
  @renderedTiles: []
  
  @tileProperties: []
  
  @playerTile: false
  
  @showBlocked: false
  
  @showPaths: false
  
  @playerLayer: 0
  
  @isMoving: false
  
  @loadMap: (targetElem, mapSource, callback) ->
    @mapElement = targetElem
    if typeof mapSource == 'object'
      @mapData = mapSource
      window.Map.doLoad(callback)
    else if typeof mapSource == 'string'
      $.getJSON @settings.mapDirectory+mapSource+'.'+@settings.fileExtension, (json) ->
        window.Map.mapData = json
        window.Map.doLoad(callback)
  
  @doLoad: (callback) ->
    m = window.Map.mapElement
    $(m).hide()
    window.Map.drawMap(m)
    if typeof window.Map.playerTile == 'object'
      window.Map.playerTile = window.Map.tileIdConvert(window.Map.playerTile)
    window.Character.loadSprite(window.Character.settings.playerSprite, window.Character.loadPlayer)
    $(m).fadeIn('slow')
    if callback
        callback()
  
  @unloadMap: (callback) ->
    $(@mapElement).fadeOut 'slow', ->
        $(window.Map.mapElement).html('').css({left:'',top:''})
        if callback
            callback()
    @mapData = false
    @renderedTiles = []
    @tileProperties = []
    
  
  @drawMap: (targetElem) ->
    for layer,index in @mapData.layers
      if layer.type == "tilelayer"
        $(targetElem).append("<div class=\"layer\" id=\"layer#{index}\" />")
        
        currentLayer = $("#layer#{index}")
        for tile, i in layer.data
          $(currentLayer).append("<div id=\"tile#{index}-#{i}\" class=\"tile\" />")
          @drawTile(index, tile, i)
        $(currentLayer).css('width',@mapData.tilewidth * @mapData.width + 'px').css('height',@mapData.tileheight * @mapData.height + 'px')
        $('.tile').width(@mapData.tilewidth).height(@mapData.tileheight)
        $('.layer:last').find('.tile').mousedown(@tileClick)
        $('#maploading').remove()
      else if layer.type == "objectgroup"
        if layer.name == "Player"
          @playerLayer = index
        $(targetElem).append("<div class=\"layer\" id=\"layer#{index}\" />")
        
  @drawTile: (layer, srcTile, targetTile) ->
    target = $("#tile#{layer}-#{targetTile}")
      
    setData = false
    for tileset,index in @mapData.tilesets
      if srcTile >= tileset.firstgid
        setData = tileset
      else
        return false
    
    setWidth = Math.floor(setData.imagewidth / setData.tilewidth)-1
    setHeight = Math.floor(setData.imageheight / setData.tileheight)-1
    
    heightCount = 0
    widthCount = 0
    for i in [1...srcTile] by 1
      if widthCount < setWidth
        widthCount++
      else
        widthCount = 0
        heightCount++
    
    offset = {
      x: (widthCount * setData.tilewidth) + (setData.spacing * widthCount) + setData.margin,
      y: (heightCount * setData.tileheight) + (setData.spacing * heightCount) + setData.margin
    }
    
    if setData.image
      @renderedTiles[srcTile] = "#tile#{layer}-#{targetTile}"
      properties = @tileProperty(srcTile)
      if properties
        @tileProperties[targetTile] = properties
      $(target).css('background-image',"url(#{setData.image})")
      $(target).css('background-position',"-#{offset.x}px -#{offset.y}px")

  @setFocus: (tileId, duration) ->
    loc = @tileIdConvert(tileId)
    curloc = $('.layer:first').position()
    maxwidth = (Map.mapData.width*32) - $('.viewport').width()
    maxheight = (Map.mapData.height*32) - $('.viewport').height()
    loc[0] = (loc[0]*32) - ($('.viewport').width()/2)
    loc[1] = (loc[1]*32) - ($('.viewport').height()/2)
    
    # Set view limits
    if loc[1] < 0
      loc[1]=0
    if loc[0] < 0
      loc[0]=0
    if loc[1] > maxheight
      loc[1]=maxheight
    if loc[0] > maxwidth
      loc[0]=maxwidth
    
    @isMoving = true
    
    $('.layer-container').stop()
    $('.layer-container').animate({
      top: "-"+loc[1]+"px",
      left: "-"+loc[0]+"px"
    }, duration, ->
      @isMoving = false
    )
    
  @tileIdConvert: (tileInput) ->
    if typeof tileInput == 'object'
      tileId = parseInt(tileInput[1]) * @mapData.width-1
      tileId += parseInt(tileInput[0])
      return tileId
    else
      y = 0
      x = 0
      width = @mapData.width-1
      
      for i in [0...tileInput] by 1
        if x < width
          x++
        else
          x = 0
          y++
      return [x, y]
    
  @tileIdPosition: (tileInput) ->
    if typeof tileInput != 'object'
      tileInput = @tileIdConvert(tileInput)
      
    return [(tileInput[0]-1)*@mapData.tilewidth,tileInput[1]*@mapData.tileheight]
  
  @tileProperty: (tileId) ->
    tileId = tileId - 1
    for data, index in @mapData.tilesets
      if data.tileproperties and data.tileproperties[tileId]
        properties = data.tileproperties[tileId]
    return properties
  
  @tilePropertyLogic: (prop) ->
    switch prop.property
        when "door"
            @unloadMap -> 
                window.Map.playerTile = prop.loc.split(',')
                window.Map.loadMap window.Map.mapElement, prop.map
                return
            return
            
  
  @tileClick: (e) ->
    e.preventDefault()
    tileId = $(this).attr('id')
    tileId = tileId.substr(tileId.lastIndexOf('-')+1)
    tileId++
    if e.button == 2
      prop = 'none'
      if prop2 = window.Map.tileProperty(tileId+1)
        prop = prop2.property
      alert(window.Map.tileIdConvert(tileId+1) + '-' + prop)
    else
      paths = window.Map.makePath(tileId)
      if paths.length
        window.Character.playerMove(paths)
        if window.Map.showPaths
          $("#layer#{Map.playerLayer} div").css('background-color','transparent')
          for path, index in paths
            tileId = window.Map.tileIdConvert([path.x,path.y])
            $("#tile#{Map.playerLayer}-#{tileId}").css('background','red')
        window.Map.setFocus(tileId, (paths.length * 500))
        window.Map.playerTile = tileId
        window.Map.showDestination("#tile#{window.Map.mapData.layers.length-1}-#{tileId-1}")
        
  @showDestination: (elem) ->
    $('.destination').remove()
    $(elem).append('<img class="destination" src="../resources/destination.png" />')
    
  @makePath: (toTileId) ->
    totalMapSize = @mapData.width * @mapData.height
    toTileLoc = @tileIdConvert(toTileId)
    fromTileLoc = @tileIdConvert(@playerTile)
    board = []
    
    for y in [0..(Map.mapData.height-1)] by 1
      board[y] = []
      for x in [0..(Map.mapData.width-1)] by 1
        tile = @tileIdConvert([x,y])
        if prop = @tileProperties[tile]
          prop = prop.property
          if prop == 'block'
            board[y][x] = 1
            if @showBlocked
              tileidc = this.tileIdConvert([x,y])
              $("#tile0-#{tileidc}").css('background','red')
        else
          board[y][x] = 0
    return AStar(board, fromTileLoc, toTileLoc, 'Diagonal')