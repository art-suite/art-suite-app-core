Foundation = require 'art-foundation'

{merge, Promise, parseQuery, log, ConfigRegistry, isPlainObject} = Foundation
{Meta, Link} = Foundation.Browser.DomElementFactories
{getDomReadyPromise} = Foundation.Browser
{FontLoader} = require 'art-canvas'
{rgbColor} = require 'art-atomic'

module.exports = class FullScreenApp

  @_domReady: ->
    Engine = require 'art-engine'
    query = parseQuery()
    log """
      Art.Engine.FullScreenApp options:
        ?dev=true
          show DomConsole
        ?perfGraphs=true
          show performance graphs
      """

    if query.dev == "true" || query.perfGraphs == "true"

      ###
      TODO:
      1) I'd like a way to easily build production vs dev code.
      2) DomConsole should only be included in dev code.
      ANSWER:
        1. make DomConsole its own NPM
        2. let webpack rewrite the following require into a noop for production.
      ###
      require 'art-foundation/dev_tools/dom_console'
      {DomConsole} = Neptune.Art.Foundation.DevTools

      DomConsole.enable()
      Engine.DevTools.GlobalEpochStats.enable() if query.perfGraphs == "true"

    log "Art.Engine.FullScreenApp: app ready"

  @_setBodyStyles: ({backgroundColor})->
    if global.document
      {body, documentElement} = global.document
      body.style.padding = "0px"
      body.style.margin = "0px"
      # body.style.backgroundColor = "#{rgbColor backgroundColor || "#eee"}"
      body.style.overflow = "hidden"
      body.style.fontSize = "0px"
      body.style.height = "100%"
      documentElement.style.height = "100%"

  ###
  IN:
    config:
      fonts: # SEE ArtCanvas.FontLoader for the most up-to-date-doc

    title: document.title
    styleSheets: array of style-sheet URLS to load
    scripts: array of script URLs to load

    meta: key-value map for meta-tags in the form:
      name: content

    link: add link tags to add in the form:
      rel: tag-body-text

    manifest: manifest file URL

  ###
  @init: (config = {})=>
    ConfigRegistry.configure config
    {fonts} = config

    @writeDom config
    Promise.all [
      Promise.resolve fonts && FontLoader.loadFonts fonts
      getDomReadyPromise()
      .then =>
        @_domReady()
        @_setBodyStyles config
    ]

  @writeDom: ({title, styleSheets, scripts, meta, link, manifest, backgroundColor})->

    document.title = title || "Art App"
    scripts ||= []
    styleSheets ||= []

    scriptLinks = for scriptUrl in scripts when scriptUrl
      "<script type='text/javascript' src='#{scriptUrl}'></script>"

    newLine = "\n    "

    nameContentMetas = merge
      "viewport": "user-scalable=no, width=device-width, initial-scale=1.0"
      "mobile-web-app-capable": "yes"
      "apple-touch-fullscreen": "yes"
      "apple-mobile-web-app-capable": "yes"
      "apple-mobile-web-app-status-bar-style": "black" #"black-translucent"
      "format-detection": "telephone=no"
      meta

    document.head.appendChild Meta charset: "utf-8"
    document.head.appendChild Meta "http-equiv": "X-UA-Compatible", content: "IE=edge,chrome=1"
    for name, content of nameContentMetas
      document.head.appendChild Meta name: name, content: content

    for sheetUrl in styleSheets
      document.head.appendChild Link
        rel: 'stylesheet'
        href: sheetUrl

    for rel, info of link || {}
      document.head.appendChild Link
        rel: rel
        info

    document.write """
      <html #{if manifest then "manifest='#{manifest}'" else ""}>

        <style>
          html {
            height: 100%;
          }
          body {
            padding: 0px;
            margin: 0px;
            background-color: #{rgbColor backgroundColor || "#eee"};
            overflow: hidden;
            font-size: 0px;
            height: 100%;
          }
        </style>

        <body>
          #{scriptLinks.join newLine}
        </body>
      </html>
    """
