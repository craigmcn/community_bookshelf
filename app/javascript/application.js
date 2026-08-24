// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import * as bootstrap from "bootstrap"
import Chartkick from "chartkick"
import "chartkick/chart.js"

window.Chartkick = Chartkick
