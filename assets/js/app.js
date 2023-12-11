import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import { GameContext } from "./context";
import { bgLoadTextures } from "./canvas";

bgLoadTextures();

const hooks = {};
let gameContext;

hooks.GameCanvas = {
  mounted() {
    this.handleEvent("game-loaded", data => {
      // console.log("game loaded", data);
      gameContext = new GameContext(data.game, this.el, this.pushEvent.bind(this))
    });

    this.handleEvent("game-started", data => {
      // console.log("game started", data);
      gameContext.onGameStart(data.game);
    });

    this.handleEvent("round-started", data => {
      // console.log("round started", data);
      gameContext.onRoundStart(data.game);
    });

    this.handleEvent("game-event", data => {
      // console.log("game event", data);
      gameContext.onGameEvent(data.game, data.event);
    });

    this.handleEvent("round-over", _ => {
      // console.log("round over");
      gameContext.onRoundOver();
    });

    this.handleEvent("game-over", _ => {
      // console.log("game over");
      gameContext.onGameOver();
    });

    this.handleEvent("resize-canvas", _ => {
      gameContext.resize();
    });
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {hooks, params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// liveSocket.enableDebug()
// liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// liveSocket.disableLatencySim()
window.liveSocket = liveSocket

const copyables = document.querySelectorAll(".copyable");

copyables.forEach(elem => {
  elem.addEventListener("click", event => {
    const content = event.target.textContent;
    navigator.clipboard.writeText(content);
  });
});

window.addEventListener("phx:clear-chat-input", _ => {
  const inputEl = document.querySelector("#chat-form-input");
  inputEl.value = "";
});

// const infoToggleEl = document.querySelector("#info-toggle");

// if (infoToggleEl) {
//   infoToggleEl.addEventListener("click", _ => {
//     console.log("before", gameContext.parentEl);
//     const infoEl = document.querySelector("#game-info");

//     infoEl.style.display = infoEl.style.display === "none"
//       ? "block"
//       : "none";

//     gameContext.resize();
//     console.log("after", gameContext.parentEl);
//   });
// }
