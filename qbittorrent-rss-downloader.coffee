FeedParser 	= require 'feedparser'
request 	  = require 'request'
qBittorrent = require('qbittorrent-client').API3
expisodeParser = require 'episode-parser'

client = new qBittorrent    
    username: process.env.QBITTORRENT_USERNAME
    password: process.env.QBITTORRENT_PASSWORD
    host: process.env.QBITTORRENT_HOST
    port: process.env.QBITTORRENT_PORT or 8080

req = request process.env.FEED_URL

feedparser = new FeedParser()

req.on 'error', (error) ->
  console.log error

req.on 'response', (res) ->
  stream = this
  if res.statusCode != 200
    return @emit('error', new Error('Bad status code'))
  stream.pipe feedparser

feedparser.on 'error', (error) ->
  console.log error

feedparser.on 'readable', ->
  stream = this
  while item = stream.read()
    episodeInfo = expisodeParser item.title
    if item.link?
      console.log "Adding #{episodeInfo.show} S#{episodeInfo.season}E#{episodeInfo.episode} to '/downloads/tv_shows/#{episodeInfo.show}/Season #{episodeInfo.season}/"
      options =
        urls: item.link
        savepath: "#{process.env.PATH_TO_TV_SHOWS}/#{episodeInfo.show}/Season #{episodeInfo.season}/"
      
      client.addTorrentFromURL options, (err, res)->
        console.log err if err
        console.log res if res
